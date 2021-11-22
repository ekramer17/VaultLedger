using System;
using System.IO;
using System.Web;
using System.Data;
using System.Text;
using System.Threading;
using System.Web.Caching;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Router
{
    /// <summary>
    /// This class represents the hosting database, which contains login 
    /// and connection information for hosted implementations of VaultLedger.
    /// The hosting database must be a SQL Server 2000 database.
    /// </summary>
    public class RouterDb
    {
        private static string RouterString
        {
            get
            {
                string vectorConfig = Configurator.ConnectionVector;
                string connectionConfig = Configurator.ConnectionString;
                // If there is no string, throw an exception.  If there is no vector,
                // return the connection string as is
                if (connectionConfig == null || connectionConfig == String.Empty)
                    throw new ApplicationException("Connection string not found");
                else if (vectorConfig == null || vectorConfig == String.Empty)
                    return connectionConfig;
                // If the connection string contains a character not found in a
                // base64 string, return it as is
                if (new Regex(@"^[a-zA-Z0-9+/=\s]*$").IsMatch(connectionConfig) == false)
                    return connectionConfig;
                // If we find the string "Database =" or "Database=" or 
                // "Initial Catalog =" or "Initial Catalog=" in the string, 
                // we can assume that the string is not encrypted
                if (new Regex(@"Database\s*=",RegexOptions.IgnoreCase).IsMatch(connectionConfig) == true)
                    return connectionConfig;
                else if (new Regex(@"Initial Catalog\s*=",RegexOptions.IgnoreCase).IsMatch(connectionConfig) == true)
                    return connectionConfig;
                // The string is encrypted and in base64 format.  Convert the 
                // strings back from base64.
                byte[] connectionBytes = Convert.FromBase64String(connectionConfig);
                byte[] vectorBytes = Convert.FromBase64String(vectorConfig);
                // Decrypt and return the connection string
                return Crypto.Decrypt(connectionBytes, vectorBytes);
            }
        }

        /// <summary>
        /// Inserts a new login into the hosting database
        /// </summary>
        /// <param name="login">
        /// Login to insert
        /// </param>
        /// <param name="catalog">
        /// VaultLedger catalog (database) for this login
        /// </param>
        public static void InsertLogin(string login)
        {
            if (Configurator.Router)
            {
                using (SqlConnection c = new SqlConnection(RouterString))
                {
                    c.Open();

                    try
                    {
                        // Get the catalog id using the catalog name
                        // from the connection string

                        SqlCommand cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "catalog$getByLogin";
                        cmd.Parameters.AddWithValue("@loginName", Thread.CurrentPrincipal.Identity.Name);
                        object catalogId = cmd.ExecuteScalar();
                        if (catalogId == null)
                        {
                            throw new RouterException("Catalog not found in router.");
                        }
                        else
                        {
                            // Insert the login
                            cmd = c.CreateCommand();
                            cmd.CommandType = CommandType.StoredProcedure;
                            cmd.CommandText = "login$ins";
                            cmd.Parameters.AddWithValue("@loginName", login);
                            cmd.Parameters.AddWithValue("@catalogId", (int)catalogId);
                            cmd.Parameters.AddWithValue("@newId", SqlDbType.Int);
                            cmd.Parameters["@newId"].Direction = ParameterDirection.Output;
                            cmd.ExecuteNonQuery();
                        }
                    }
                    catch (SqlException e)
                    {
                        throw new DatabaseException(e.Message, e);
                    }
                }
            }
        }
        /// <summary>
        /// Updates a login in the hosting database
        /// </summary>
        /// <param name="oldLogin">
        /// Old login
        /// </param>
        /// <param name="newLogin">
        /// New login
        /// </param>
        public static void UpdateLogin(string oldLogin, string newLogin)
        {
            if (Configurator.Router)
            {
                using (SqlConnection c = new SqlConnection(RouterString))
                {
                    c.Open();

                    try
                    {
                        int loginId;
                        string catalogName;
                        // Get it
                        SqlCommand cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "login$getByName";
                        cmd.Parameters.AddWithValue("@loginName", oldLogin);
                        using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                        {
                            r.Read();
                            loginId = r.GetInt32(0);
                            catalogName = r.GetString(2);
                        }
                        // Update it
                        cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "login$upd";
                        cmd.Parameters.AddWithValue("@loginId", loginId);
                        cmd.Parameters.AddWithValue("@loginName", newLogin);
                        cmd.Parameters.AddWithValue("@catalogName", catalogName);
                        cmd.ExecuteNonQuery();
                    }
                    catch (SqlException e)
                    {
                        throw new DatabaseException(e.Message, e);
                    }
                }
            }
        }
        /// <summary>
        /// Deletes a login from the hosting database
        /// </summary>
        /// <param name="login">
        /// Login to delete
        /// </param>
        public static void DeleteLogin(string login)
        {
            if (Configurator.Router)
            {
                using (SqlConnection c = new SqlConnection(RouterString))
                {
                    c.Open();

                    try
                    {
                        // Get it
                        SqlCommand cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "login$getByName";
                        cmd.Parameters.AddWithValue("@loginName", login);
                        object loginId = cmd.ExecuteScalar();
                        if (loginId == null) return;  // No need for error
                        // Delete it
                        cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "login$del";
                        cmd.Parameters.AddWithValue("@loginId", (int)loginId);
                        cmd.ExecuteNonQuery();
                    }
                    catch (SqlException e)
                    {
                        throw new DatabaseException(e.Message, e);
                    }
                }
            }
        }
        /// <summary>
        /// Assembles the connection string that connects directly
        /// to the client database from a SqlDataReader that contains
        /// information on a server database object.
        /// </summary>
        /// <param name="r">
        /// SqlDataReader containing information on a server
        /// </param>
        /// <returns>
        /// Direct connection string
        /// </returns>
        private static string AssembleDirectConnection(SqlDataReader r, bool dbo, string catalogName)
        {
            
            string serverName = r.GetString(1);
            string userId = r.GetString(dbo ? 6 : 2);
            bool trustedConnection = (r.GetInt32(dbo ? 7 : 3) == 0);
            string password = r.GetString(dbo ? 8 : 4);
            string pwdVector = r.GetString(dbo ? 9 : 5);
            int portNo = r.FieldCount > 10 ? r.GetInt32(10) : 0;
            // Put together the connection string
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("Server={0}{1}", serverName, portNo != 0 ? String.Format(",{0}", portNo) : String.Empty);
            sb.AppendFormat(";Initial Catalog={0}", catalogName);
            if (trustedConnection == true)
            {
                sb.Append(";Integrated Security=SSPI");
            }
            else
            {
                sb.AppendFormat(";User Id={0}", userId);
                byte[] vectorBytes = Convert.FromBase64String(pwdVector);
                byte[] passwordBytes = Convert.FromBase64String(password);
                password = Crypto.Decrypt(passwordBytes, vectorBytes);
                if (password.Length != 0)
                {
                    sb.AppendFormat(";Password={0}", password);
                }
            }
            // Return
            return sb.ToString();
        }
        /// <summary>
        /// Gets the connection string for a given login
        /// </summary>
        /// <param name="login">
        /// Login for which to retrieve connection string
        /// </param>
        /// <param name="dbOwner">
        /// Whether to use the db_owner connection or the normal connection
        /// </param>
        public static string GetConnectString(string login, bool dbo)
        {
            string cacheKey;
            // Get the correct cache key
            if (dbo == true)
            {
                cacheKey = CacheKeys.ConnectOwner;
            }
            else
            {
                cacheKey = CacheKeys.ConnectOperator;
            }
            // If it's in the cache, return it
            try
            {
                string cacheValue = (string)HttpRuntime.Cache[cacheKey];
                if (cacheValue.Length != 0) return cacheValue;
            }
            catch
            {
                ;
            }
            // It wasn't in the cache, so get it from the database
            using (SqlConnection c = new SqlConnection(RouterString))
            {
                c.Open();

                try
                {
                    string catalogName;
                    // Get the catalog name
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "login$getByName";
                    cmd.Parameters.AddWithValue("@loginName", login);
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (r.HasRows == false)
                        {
                            throw new RouterException("Login not found in router.");
                        }
                        else
                        {
                            r.Read();
                            catalogName = r.GetString(2);
                        }
                    }
                    // Get the connection parameters
                    cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "server$getByLogin";
                    cmd.Parameters.AddWithValue("@loginName", login);
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        r.Read();
                        // Assemble the direct connection string
                        string directConnect = AssembleDirectConnection(r, dbo, catalogName);
                        // Attempt to cache the string if we have a cache
                        try
                        {
                            CacheKeys.Insert(cacheKey, directConnect, TimeSpan.FromMinutes(3));
                        }
                        catch
                        {
                            ;
                        }
                        // Return
                        return directConnect;
                    }
                }
                catch (SqlException e)
                {
                    throw new DatabaseException(e.Message, e);
                }
            }
        }
        /// <summary>
        /// Gets the connection string for a given account
        /// </summary>
        /// <param name="accountType">
        /// Type of account
        /// </param>
        /// <param name="accountNo">
        /// Number of account
        /// </param>
        public static string GetConnectString(int accountType, string accountNo)
        {
            try
            {
                // If it's in the cache, return it
                string cacheValue = (string)HttpRuntime.Cache[CacheKeys.ConnectOperator];
                if (cacheValue.Length != 0) return cacheValue;
            }
            catch
            {
                ;
            }
            // It wasn't in the cache, so get it from the database
            using (SqlConnection c = new SqlConnection(RouterString))
            {
                c.Open();

                try
                {
                    string serverName;
                    string catalogName;
                    // Get the owner id
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "owner$getByAccount";
                    cmd.Parameters.AddWithValue("@accountType", accountType);
                    cmd.Parameters.AddWithValue("@accountNo", accountNo);
                    object returnObject = cmd.ExecuteScalar();  // Returns owner id number
                    if (returnObject == null)
                    {
                        throw new RouterException("Unable to find catalog owner by account.");
                    }
                    // Get the server from the owner id
                    cmd = c.CreateCommand();
                    cmd.CommandText = "catalog$getByOwner";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@ownerId", (int)returnObject);
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (r.HasRows == false)
                        {
                            throw new RouterException("Unable to find catalog by owner.");
                        }
                        else
                        {
                            r.Read();
                            serverName = r.GetString(3);
                            catalogName = r.GetString(1);
                        }
                    }
                    // Get the connection parameters
                    cmd = c.CreateCommand();
                    cmd.CommandText = "server$getByName";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@serverName", serverName);
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        r.Read();
                        // Assemble the direct connection string
                        string directConnect = AssembleDirectConnection(r, false, catalogName);
                        // Attempt to cache the string if we have a cache
                        try
                        {
                            CacheKeys.Insert(CacheKeys.ConnectOperator, directConnect);
                        }
                        catch
                        {
                            ;
                        }
                        // Return
                        return directConnect;
                    }
                }
                catch (SqlException e)
                {
                    throw new DatabaseException(e.Message, e);
                }
            }
        }
        /// <summary>
        /// Gets the global Recall account for a given login
        /// </summary>
        /// <param name="login">
        /// Login for which to retrieve global account
        /// </param>
        public static void GetAccount(string login, out string accountNo, out int accountType)
        {
            try
            {
                // If they're in the cache, return them
                if (HttpRuntime.Cache[CacheKeys.AccountNo] != null)
                {
                    if (((string)(accountNo = (string)HttpRuntime.Cache[CacheKeys.AccountNo])).Length != 0)
                    {
                        if (HttpRuntime.Cache[CacheKeys.AccountType] != null)
                        {
                            accountType = (int)HttpRuntime.Cache[CacheKeys.AccountType];
                            return;
                        }
                    }
                }
            }
            catch
            {
                ;
            }
            // Not in the cache, so get it from the database
            using (SqlConnection c = new SqlConnection(RouterString))
            {
                c.Open();

                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "owner$getByLogin";
                    cmd.Parameters.AddWithValue("@loginName", login);
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (r.HasRows == false)
                        {
                            throw new RouterException("Login not found in router.");
                        }
                        else
                        {
                            r.Read();
                            accountNo = r.GetString(11);
                            accountType = r.GetInt32(12);
                        }
                    }
                    // Attempt to cache the data
                    try
                    {
                        CacheKeys.Insert(CacheKeys.AccountNo, accountNo, TimeSpan.FromMinutes(2));
                        CacheKeys.Insert(CacheKeys.AccountType, accountType, TimeSpan.FromMinutes(2));
                    }
                    catch
                    {
                        ;
                    }
                }
                catch (SqlException e)
                {
                    throw new DatabaseException(e.Message, e);
                }
            }
        }

        #region Email Server
        /// <summary>
        /// Gets the email groups in the database
        /// </summary>
        /// <returns>
        /// Email groups
        /// </returns>
        public static void GetEmail(ref string serverName, ref string fromAddress)
        {
            // Initialize
            serverName = String.Empty;
            fromAddress = String.Empty;
            // Get parameters
            using (SqlConnection c1 = new SqlConnection(RouterString))
            {
                c1.Open();

                try
                {
                    SqlCommand c2 = c1.CreateCommand();
                    c2.CommandType = CommandType.StoredProcedure;
                    c2.CommandText = "email$get";
                    using (SqlDataReader r1 = c2.ExecuteReader())
                    {
                        if (r1.Read())
                        {
                            serverName = r1.GetString(0);
                            fromAddress = r1.GetString(1);
                        }
                    }
                }
                catch (SqlException e1)
                {
                    throw new DatabaseException(e1.Message, e1);
                }
            }
        }

        /// <summary>
        /// Updates the email server
        /// </summary>
        /// <param name="serverName">
        /// Name of the email server
        /// </param>
        /// <param name="fromAddress">
        /// Address from which to send email
        /// </param>
        public static void UpdateEmail(string serverName, string fromAddress)
        {
            // Delete the operator
            using (SqlConnection c1 = new SqlConnection(RouterString))
            {
                c1.Open();
                SqlCommand c2 = c1.CreateCommand();
                SqlTransaction t1 = c1.BeginTransaction();

                try
                {
                    c2.Transaction = t1;
                    c2.CommandText = "email$upd";
                    c2.CommandType = CommandType.StoredProcedure;
                    c2.Parameters.AddWithValue("@serverName", serverName);
                    c2.Parameters.AddWithValue("@fromAddress", fromAddress);
                    // Update
                    c2.ExecuteNonQuery();
                    // Commit
                    t1.Commit();
                }
                catch(SqlException e1)
                {
                    t1.Rollback();
                    throw new DatabaseException(e1.Message, e1);
                }
            }
        }
        #endregion
    }
}
