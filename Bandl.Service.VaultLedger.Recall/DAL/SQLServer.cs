using System;
using System.Data;
using System.Text;
using System.Configuration;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Bandl.Service.VaultLedger.Recall.Model;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Service.VaultLedger.Recall.Exceptions;
using Bandl.Service.VaultLedger.Recall.Collections;

namespace Bandl.Service.VaultLedger.Recall.DAL
{
	/// <summary>
	/// Contains all the calls for the SQL Server database
	/// </summary>
	public class SQLServer
	{
        private static string GetConnectionString()
        {
            // Get the strings from the configuration file
            string vectorConfig = ConfigurationSettings.AppSettings["ConnVector"];
            string connectionConfig = ConfigurationSettings.AppSettings["ConnString"];
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
            return Balance.Exhume(connectionBytes, vectorBytes);
        }

        /// <summary>
        /// Open a connection to the SQL Server database
        /// </summary>
        /// <returns>
        /// Connection object
        /// </returns>
        private static SqlConnection OpenConnection()
        {
            try
            {
                // Create connection
                SqlConnection sqlConn = new SqlConnection(GetConnectionString());
                // Open and return
                sqlConn.Open();
                return sqlConn;
            }
            catch(SqlException e)
            {
                throw new DatabaseException(e.Message);
            }
        }

        /// <summary>
        /// Strips the error tag from the SqlException raised by the database
        /// if it exists.  All errors raised by us have this tag.
        /// </summary>
        /// <param name="errorString">
        /// 
        /// </param>
        /// <returns></returns>
        private static string StripErrorTag(string error)
        {
            if (error.EndsWith(">") && error.IndexOf("<") != -1)
                return error.Substring(0,error.IndexOf("<"));
            else
                return error;
        }

        /// <summary>
        /// Gets the password for a particular global account
        /// </summary>
        /// <param name="account">
        /// Name of the global account we would like to retrieve
        /// </param>
        /// <returns>
        /// Account object if it was found, else null
        /// </returns>
        public static LocalAccountDetails RetrieveGlobalAccount(string account)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "globalAccount$retrieve";
                    cmd.Parameters.Add("@accountName",account);
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (false == r.HasRows) 
                            return null;
                        else
                        {
                            r.Read();
                            return new LocalAccountDetails(r);
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Retrieves all the global accounts in the global accounts table
        /// </summary>
        /// <returns>
        /// Collection of global account objects
        /// </returns>
        public static LocalAccountCollection RetrieveGlobalAccounts()
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "globalAccount$getTable";
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (false == r.HasRows)
                        {
                            return new LocalAccountCollection();
                        }
                        else
                        {
                            return new LocalAccountCollection(r);
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Changes the attributes for a given account
        /// </summary>
        /// <param name="lad">
        /// Account to modify
        /// </param>
        public static void UpdateGlobalAccount(LocalAccountDetails lad)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command to get the id of the account
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "globalAccount$modify";
                    cmd.Parameters.Add("@accountId",lad.Id);
                    cmd.Parameters.Add("@accountName",lad.Name);
                    cmd.Parameters.Add("@password",lad.Password);
                    cmd.Parameters.Add("@salt",lad.Salt);
                    cmd.Parameters.Add("@allowDynamic",lad.AllowDynamic);
                    cmd.Parameters.Add("@filePath",lad.FilePath);
                    // Execute
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Creates a new authentication ticket 
        /// </summary>
        /// <param name="account">
        /// Account requesting the ticket
        /// </param>
        /// <returns>
        /// Newly created authentication ticket
        /// </returns>
        public static Guid CreateTicket(string account)
        {
            // Make sure that the sliding expiration minutes value is present and valid
            int slidingMinutes = Convert.ToInt32(ConfigurationSettings.AppSettings["TicketIdle"]);
            if (slidingMinutes <= 0 || slidingMinutes > 480)
                throw new ApplicationException("Configuration setting value invalid (TicketIdle).");
            // Open connection
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Create the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandText = "ticket$create";
                    cmd.CommandType = CommandType.StoredProcedure;
                    // Build the parameters
                    cmd.Parameters.Add("@accountName",account);
                    cmd.Parameters.Add("@slidingMinutes",slidingMinutes);
                    cmd.Parameters.Add("@ticket",SqlDbType.UniqueIdentifier);
                    cmd.Parameters["@ticket"].Direction = ParameterDirection.Output;
                    // Execute the procedure
                    cmd.ExecuteNonQuery();
                    // Get the ticket
                    Guid ticket = (Guid)cmd.Parameters["@ticket"].Value;
                    // Return true
                    return ticket;
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }   // End CreateTicket

        /// <summary>
        /// Authenticates a given ticket.  Throws exception if ticket is 
        /// not authentic.
        /// </summary>
        /// <param name="account">
        /// Account that owns the ticket
        /// </param>
        /// <param name="ticket">
        /// Authentication ticket
        /// </param>
        public static void AuthenticateTicket(string account, Guid ticket)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "ticket$check";
                    cmd.Parameters.Add("@ticket",ticket);
                    cmd.Parameters.Add("@accountName",account);
                    cmd.Parameters.Add("returnValue", SqlDbType.Int);
                    cmd.Parameters["returnValue"].Direction = ParameterDirection.ReturnValue;
                    // Execute
                    cmd.ExecuteNonQuery();
                    // If return value is not 0 then the ticket was not authenticated
                    if (Convert.ToInt32(cmd.Parameters["returnValue"].Value) != 0)
                        throw new AuthenticationException("Invalid authentication ticket");
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Create a new global account
        /// </summary>
        /// <param name="lad">
        /// Local account details
        /// </param>
        public static void CreateGlobalAccount(LocalAccountDetails lad)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "globalAccount$create";
                    cmd.Parameters.Add("@accountName", lad.Name);
                    cmd.Parameters.Add("@password", lad.Password);
                    cmd.Parameters.Add("@salt", lad.Salt);
                    cmd.Parameters.Add("@filePath", lad.FilePath);
                    // Execute
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Delete a global account
        /// </summary>
        /// <param name="lad">
        /// Local account details
        /// </param>
        public static void DeleteGlobalAccount(LocalAccountDetails lad)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "globalAccount$delete";
                    cmd.Parameters.Add("@accountId", lad.Id);
                    // Execute
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }


        /// <summary>
        /// Create a new secondary account
        /// </summary>
        /// <param name="secondaryAccount">
        /// Name of secondary account
        /// </param>
        /// <param name="globalAccount">
        /// Name of global account
        /// </param>
        public static void UpdateSecondaryAccounts(string global, string[] accountNames)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                SqlTransaction sqlTran = sqlConn.BeginTransaction();

                try
                {
                    // Delete all of the secondaries for this global
                    SqlCommand cmdDelete = sqlConn.CreateCommand();
                    cmdDelete.CommandType = CommandType.StoredProcedure;
                    cmdDelete.CommandText = "globalAccount$deleteSecondaries";
                    cmdDelete.Parameters.Add("@accountName", global);
                    cmdDelete.Transaction = sqlTran;
                    cmdDelete.ExecuteNonQuery();
                    // Add each secondary
                    foreach(string accountName in accountNames)
                    {
                        // Build the command
                        SqlCommand cmd = sqlConn.CreateCommand();
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "secondaryAccount$create";
                        cmd.Parameters.Add("@accountName", accountName);
                        cmd.Parameters.Add("@globalName", global);
                        // Execute
                        cmd.Transaction = sqlTran;
                        cmd.ExecuteNonQuery();
                    }
                    // Commit
                    sqlTran.Commit();
                }
                catch(SqlException e)
                {
                    sqlTran.Rollback();
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Verifies that a given secondary accout rolls up into a given global
        /// </summary>
        /// <param name="secondaryAccount">
        /// Name of secondary account
        /// </param>
        /// <param name="globalAccount">
        /// Name of global account
        /// </param>
        /// <returns>
        /// True if secondary account verified against global, else false
        /// </returns>
        public static bool VerifyServiceAccount(string secondaryAccount, string globalAccount)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "secondaryAccount$global";
                    cmd.Parameters.Add("@accountName", secondaryAccount);
                    cmd.Parameters.Add("@globalName", globalAccount);
                    cmd.Parameters.Add("@returnValue", SqlDbType.Int);
                    cmd.Parameters["@returnValue"].Direction = ParameterDirection.ReturnValue;
                    // Execute
                    cmd.ExecuteNonQuery();
                    // Evaluate result
                    switch (Convert.ToInt32(cmd.Parameters["@returnValue"].Value))
                    {
                        case 1:
                            return true;
                        default:
                            return false;
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

        /// <summary>
        /// Gets the file path for a given account
        /// </summary>
        /// <param name="account">
        /// Name of account for which to retrieve file path
        /// </param>
        /// <returns>
        /// File path on success, else empty string
        /// </returns>
        public static string RetrieveFilePath(string account)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "filePath$get";
                    cmd.Parameters.Add("@accountName", account);
                    // Execute
                    string returnValue = (string)cmd.ExecuteScalar();
                    // Evaluate result
                    return returnValue != null ? returnValue : String.Empty;

                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorTag(e.Message));
                }
            }
        }

	}
}
