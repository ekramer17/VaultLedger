using System;
using System.Web;
using System.Data;
using System.Text;
using System.Threading;
using System.Collections;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Router;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for connection.
	/// </summary>
	public sealed class DataLink : IConnection
	{
        #region PersistedConnection class
        public class PersistedConnection
        {
            string tagName;
            DataLink dataLink;
            DateTime createTime;

            public string TagName { get { return tagName; } }
            public DataLink Connection { get { return dataLink; } }
            public bool Expired { get { return (createTime.AddMinutes(20) < DateTime.UtcNow); } }

            public static string CreateTagName()
            {
                if (HttpContext.Current == null || HttpContext.Current.Session == null)
                {
                    return String.Empty;
                }
                else if (Thread.CurrentThread.Name == null && Thread.CurrentThread.Name == String.Empty)
                {
                    return String.Empty;
                }
                else
                {
                    return String.Format("{0}|{1}",HttpContext.Current.Session.SessionID,Thread.CurrentThread.Name);
                }
            }

            public PersistedConnection(DataLink _dataLink)
            {
                dataLink = _dataLink;
                createTime = DateTime.UtcNow;
                tagName = PersistedConnection.CreateTagName();
            }
        }
        #endregion

        private bool isDisposed = false;
        private SqlConnection sqlConn;
        private int connectionSemaphore;
        private SqlTransaction sqlTran;
        private int transactionSemaphore;
        private string lastIdentity = String.Empty;
        private string connectionString = String.Empty;
        // Static member holds persisted connections
		private static object persistedLock = new object();
        private static ArrayList PersistedConnections = new ArrayList();

        public int NestingLevel
        {
            get {return transactionSemaphore;}
        }

        public IDbTransaction Transaction
        {
            get {return sqlTran;}
        }

        public IDbConnection Connection
        {
            get {return sqlConn;}
        }

        // Constructor
        public DataLink() {}

        ~DataLink()
        {
            Dispose(false);
        }

        #region IDisposable Members

        public void Dispose()
        {
            Dispose(true);
            if (isDisposed) GC.SuppressFinalize(this);
        }

        #endregion

        public void Close()
        {
            Dispose();
        }

        private void Dispose(bool disposing)
        {
            // Don't try to dispose of object twice
            if (!isDisposed) 
            {
                // Determine if the consumer code or the garbage collector is
                // calling.  Avoid referencing other managed objects during
                // finalization.
                if (disposing) 
                {
                    // Method called by consumer code.
                    connectionSemaphore -= 1;
                }
                else
                {
                    // Method called by finalizer
                    connectionSemaphore = 0;
                }
                // If semaphore is zero, destroy the connection
                if (connectionSemaphore == 0) 
                {
					if (sqlConn != null) 
					{
						// Delete the spid
						SqlCommand c1 = sqlConn.CreateCommand();
						c1.CommandType = CommandType.StoredProcedure;
						c1.CommandText = "spidlogin$del";
						c1.Parameters.AddWithValue("@allTags", 1);
						c1.ExecuteNonQuery();
						// Close
						sqlConn.Close();
					}

                    sqlConn = null;
                    isDisposed = true;
                    connectionString = String.Empty;
                }
            }
        }

        private string GetConnectionString(bool dbOwner)
        {
            string originalVector = String.Empty;
            string originalString = String.Empty;
            // Check for hosted application
            if (Configurator.Router)
            {
                string loginName = Thread.CurrentPrincipal.Identity.Name;
                return RouterDb.GetConnectString(loginName, dbOwner);
            }
            else
            {
                originalVector = Configurator.ConnectionVector;
                originalString = Configurator.ConnectionString;
            }
            // If there is no string, throw an exception.  If there is no vector,
            // return the connection string as is
            if (originalString == null || originalString == String.Empty)
                throw new ApplicationException("Connection string not found");
            else if (originalVector == null || originalVector == String.Empty)
                return originalString;
            // If the connection string contains a character not found in a
            // base64 string, return it as is
            if (new Regex(@"^[a-zA-Z0-9+/=\s]*$").IsMatch(originalString) == false)
                return originalString;
            // If we find the string "Database =" or "Database=" or 
            // "Initial Catalog =" or "Initial Catalog=" in the string, 
            // we can assume that the string is not encrypted
            if (new Regex(@"Database\s*=",RegexOptions.IgnoreCase).IsMatch(originalString) == true)
                return originalString;
            else if (new Regex(@"Initial Catalog\s*=",RegexOptions.IgnoreCase).IsMatch(originalString) == true)
                return originalString;
            // The string is encrypted and in base64 format.  Convert the 
            // strings back from base64.
            byte[] connectionBytes = Convert.FromBase64String(originalString);
            byte[] vectorBytes = Convert.FromBase64String(originalVector);
            // Decrypt and return the connection string
            return Crypto.Decrypt(connectionBytes, vectorBytes);
        }

        public string Server
        {
            get
            {
                bool nextServer = false;
                // Separate on equals signs and semicolons
                string[] s = GetConnectionString(false).Split(new char[]{'=',';'});
                // Loop through the array until we find 'server'
                for (int i = 0; i < s.Length; i++)
                {
                    if (nextServer == true && s[i].Trim() != String.Empty)
                        return s[i];
                    else if (s[i].ToLower() == "server")
                        nextServer = true;
                }
                // Not found
                return String.Empty;
            }
        }

        public string Catalog
        {
            get
            {
                bool nextDatabase = false;
                // Separate on equals signs and semicolons
                string[] s = GetConnectionString(false).Split(new char[]{'=',';'});
                // Loop through the array until we find 'database' or 'initial catalog'
                for (int i = 0; i < s.Length; i++)
                {
                    if (nextDatabase == true && s[i].Trim() != String.Empty)
                        return s[i];
                    else if (s[i].ToLower() == "database" || s[i].ToLower() == "initial catalog")
                        nextDatabase = true;
                }
                // Not found
                return String.Empty;
            }
        }

        private void Connect(string connString)
        {
            if (connectionSemaphore != 0)
            {
                if (connectionString != connString)
                {
                    throw new ApplicationException("Nested connections may not have different connection strings");
                }
            }
            else
            {
                // Create connection
                sqlConn = new SqlConnection(connString);
                // Open it
                try
                {
                    sqlConn.Open();
                    connectionString = connString;
					// Insert spid
					SqlCommand c1 = sqlConn.CreateCommand();
					c1.CommandType = CommandType.StoredProcedure;
					c1.CommandText = "spidLogin$ins";
					c1.Parameters.AddWithValue("@login", Thread.CurrentPrincipal.Identity.Name);
					c1.Parameters.AddWithValue("@newTag", String.Empty);
					c1.ExecuteNonQuery();
				}
                catch(SqlException e)
                {
					throw new DatabaseException(e.Message, e);
                }
            }
            // Increment the sempahore
            connectionSemaphore += 1;
        }

        public IConnection Open(string userId, string password)
        {
            // Create a string builder to create the modified connection string
            StringBuilder modConnect = new StringBuilder();
            // Get the connection string and split on the semicolons
            string[] fields = GetConnectionString(false).Split(new char[] {';'});
            // Replace appropriate fields with user id and password
            foreach(string s in fields)
            {
                int equalsIndex = s.IndexOf("=");
                if (equalsIndex == -1)
                    modConnect.Append(s);
                else
                {
                    switch(s.Substring(0, equalsIndex).Trim().ToLower())
                    {
                        case "user id":
                        case "pooling":
                        case "password":
                        case "integrated security":
                            break;
                        default:
                            modConnect.AppendFormat("{0};", s);
                            break;
                    }
                }
            }
            // User id
            modConnect.AppendFormat("user id={0};", userId);
            // Password
            if (password != null && password.Length != 0)
                modConnect.AppendFormat("password={0};", password);
            // No pooling with custom connection string
            modConnect.Append("pooling=false");
            // Connect
            Connect(modConnect.ToString());
            // Return
            return this;
        }

        public IConnection Open()
        {
            // If we already have a connection, use the recorded connection
            // string.  Otherwise, get the connection string from the 
            // configuration file.
            if (connectionSemaphore != 0)
                Connect(connectionString);
            else
                Connect(GetConnectionString(false));
            // Return
            return this;
        }

        #region Transaction Management Methods

        public void BeginTran()
        {
            BeginTran(String.Empty);
        }

        public void BeginTran(string auditMsg)
        {
            BeginTran(auditMsg, null);
        }

        public void BeginTran(string auditMsg, string identity)
        {
            if (0 == transactionSemaphore) 
            {
                sqlTran = sqlConn.BeginTransaction();
                // Persist the connection for this thread
                DataLink.Persist(this);
            }
            // Add the audit message
            if (identity == null) identity = Thread.CurrentPrincipal.Identity.Name;
            if (auditMsg == null) auditMsg = String.Empty;
            BeginAudit(auditMsg, identity);
            lastIdentity = identity;
            // Increment the semaphore
            transactionSemaphore += 1;
        }

        public void CommitTran()
        {
            CompleteTransaction(true);
        }

        public void RollbackTran()
        {
            CompleteTransaction(false);
        }

        private void CompleteTransaction (bool doCommit)
        {
            if (transactionSemaphore > 0)
            {
                // End the audit
                CompleteAudit();
                // End the transaction
                if (1 == transactionSemaphore)
                {
                    // Commit or rollback
                    if (doCommit)
                        sqlTran.Commit();
                    else
                        sqlTran.Rollback();
                    // Set the transaction object to null
                    sqlTran = null;
                    // De-persist the connection
                    DataLink.Desist(this);
                }
                // Decrement the semaphore
                transactionSemaphore -= 1;
            }
        }

        #endregion

        #region Connection Persistance Methods
        /// <summary>
        /// Places the connection object in the cache so that other objects operating on
        /// this thread will use the same object.   (The cache key for connection 
        /// persistance uses the name of the current thread.)
        /// </summary>
        private static void Persist(DataLink dataLink)
        {
            PersistedConnection newLink = new PersistedConnection(dataLink);
            // Make sure the tagName is valid.  If it ends with a pipe, it's invalid
            if (newLink.TagName.Length == 0) return;
            // Run through the array list of persisted connections, and if the tagName is
            // already present, then return.  We must lock the type due to prevent
            // simultaneous access to the static collection.
            lock(persistedLock)
            {
                foreach (PersistedConnection persistedLink in DataLink.PersistedConnections)
                {
                    if (newLink.TagName == persistedLink.TagName)
                    {
                        return;
                    }
                }
                // Tag was not found.  Add it to the collection.
                DataLink.PersistedConnections.Add(newLink);
            }
        }
        /// <summary>
        /// Removes this connection object from the collection of those being
        /// persisted, if it exists within.
        /// </summary>
        private static void Desist(DataLink dataLink)
        {
            PersistedConnection newLink = new PersistedConnection(dataLink);
            PersistedConnection persistedLink = null;
            // Make sure the tagName is valid.  If it isn't, then no point in searching.
            if (newLink.TagName.Length == 0) return;
            // Run through the array list of persisted connections, and if the tagName is
            // present, remove it.  Check all objects for expiration and remove if expired.
            // We must lock the type due to prevent simultaneous access to the static 
            // persistent connection collection.
            lock(persistedLock)
            {
                for (int i = DataLink.PersistedConnections.Count - 1; i > -1; i -= 1)
                {
                    persistedLink = (PersistedConnection)DataLink.PersistedConnections[i];
                    if (newLink.TagName == persistedLink.TagName || persistedLink.Expired == true)
                    {
                        DataLink.PersistedConnections.Remove(persistedLink);
                    }
                }
            }
        }
        /// <summary>
        /// Gets a persisted connection if it exists for this session and thread
        /// </summary>
        /// <returns>
        /// Connection if it exists, otherwise null
        /// </returns>
        public static DataLink GetPersistedConnection()
        {
            string tagName = PersistedConnection.CreateTagName();
            // If we have a non-empty tag name, run through the persisted
            // connection collection, looking for a persisted connection with
            // the identical tag name.  If found, return it.  We must lock the 
            // type due to prevent simultaneous access to the static collection.
            if (tagName.Length != 0)
            {
                lock (persistedLock)
                {
                    foreach (PersistedConnection persistedLink in DataLink.PersistedConnections)
                    {
                        if (tagName == persistedLink.TagName)
                        {
                            return persistedLink.Connection;
                        }
                    }
                }
            }
            // Link not found in persisted connection collection.  Return null.
            return null;
        }
        #endregion

        #region Auditing Methods
        // Commence audit functions insert auditing information into the
        // database.  If information already existed for this connection
        // and login, the tag is returned so that it may be replaced later.
        private void BeginAudit(string tagMsg, string identity)
        {
            // Create command
            SqlCommand cmd = sqlConn.CreateCommand();
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = "spidLogin$ins";
            // Build parameters
            cmd.Parameters.AddWithValue("@login", identity);
            cmd.Parameters.AddWithValue("@newTag", tagMsg);
            // Execute the query
            cmd.Transaction = sqlTran;
            cmd.ExecuteNonQuery();
        }

        // Replace the old tag
        private void CompleteAudit()
        {
            // Delete only if no semaphore depleted
            if (transactionSemaphore <= 1)
            {
                // Create command
                SqlCommand cmd = sqlConn.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "spidLogin$del";
                cmd.Parameters.AddWithValue("@allTags", 0);
                // Execute the query
                cmd.Transaction = sqlTran;
                cmd.ExecuteNonQuery();
            }
        }
        #endregion

    }
}
