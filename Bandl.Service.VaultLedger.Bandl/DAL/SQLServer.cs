using System;
using System.Data;
using System.Collections;
using System.Configuration;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Bandl.Service.VaultLedger.Bandl.Model;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Service.VaultLedger.Bandl.Exceptions;

namespace Bandl.Service.VaultLedger.Bandl.DAL
{
    /// <summary>
    /// Contains all the calls for the SQL Server database
    /// </summary>
    public class SQLServer
    {
        /// <summary>
        /// Strips the error tag from the SqlException raised by the database
        /// if it exists.  All errors raised by us have this tag.
        /// </summary>
        /// <param name="errorMsg">
        /// Error message from the database
        /// </param>
        /// <returns></returns>
        private static string StripErrorMsg(string errorMsg)
        {
            if (errorMsg.EndsWith(">") && errorMsg.IndexOf("<") != -1)
                return errorMsg.Substring(0,errorMsg.IndexOf("<"));
            else
                return errorMsg;
        }

        private static string ConnectionString
        {
            get
            {
                string originalString = ConfigurationSettings.AppSettings["ConnString"];
                string originalVector = ConfigurationSettings.AppSettings["ConnVector"];
                // If there is no string, throw an exception.  If there is no vector,
                // return the connection string as is
                if (originalString == null || originalString == String.Empty)
                {
                    throw new ApplicationException("Connection string not found");
                }
                else if (originalVector == null || originalVector == String.Empty)
                {
                    return originalString;
                }
                // If the connection string contains a character not found in a
                // base64 string, return it as is
                if (new Regex(@"^[a-zA-Z0-9+/=\s]*$").IsMatch(originalString) == false)
                {
                    return originalString;
                }
                // If we find the string "Database =" or "Database=" or 
                // "Initial Catalog =" or "Initial Catalog=" in the string, 
                // we can assume that the string is not encrypted
                if (new Regex(@"Database\s*=",RegexOptions.IgnoreCase).IsMatch(originalString) == true)
                {
                    return originalString;
                }
                else if (new Regex(@"Initial Catalog\s*=",RegexOptions.IgnoreCase).IsMatch(originalString) == true)
                {
                    return originalString;
                }
                // The string is encrypted and in base64 format.  Convert the 
                // strings back from base64.
                byte[] connectionBytes = Convert.FromBase64String(originalString);
                byte[] vectorBytes = Convert.FromBase64String(originalVector);
                // Decrypt and return the connection string
                return Balance.Exhume(connectionBytes, vectorBytes);
            }
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
                SqlConnection sqlConn = new SqlConnection(ConnectionString);
                sqlConn.Open();
                return sqlConn;
            }
            catch(SqlException e)
            {
                throw new DatabaseException(e.Message);
            }
        }

        /// <summary>
        /// Retrieves a Recall account
        /// </summary>
        /// <param name="account">
        /// Name of the account
        /// </param>
        /// <returns>
        /// Account details object containing retrieved account
        /// </returns>
        public static AccountDetails GetAccount(int accountType, string accountNo)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    switch (accountType)
                    {
                        case 1:
                            cmd.CommandText = "client$getByAccount";
                            cmd.Parameters.Add("@accountType",accountType);
                            cmd.Parameters.Add("@accountNo",accountNo);
                            break;
                        default:
                            cmd.CommandText = "client$getBySubscription";
                            cmd.Parameters.Add("@subscription",accountNo);
                            break;
                    }
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (false == r.HasRows) 
                            return null;
                        else
                        {
                            r.Read();
                            return(new AccountDetails(r));
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Retrieves a client account based on client id
        /// </summary>
        /// <param name="clientId">
        /// Id for the client
        /// </param>
        /// <returns>
        /// Account details object containing retrieved client
        /// </returns>
        public static AccountDetails GetAccount(int clientId)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "client$getById";
                    cmd.Parameters.Add("@clientId",clientId);
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (false == r.HasRows) 
                            return null;
                        else
                        {
                            r.Read();
                            return(new AccountDetails(r));
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Retrieves a client account based on subscription
        /// </summary>
        /// <param name="subscriptionId">
        /// Subscription for the client
        /// </param>
        /// <returns>
        /// Account details object containing retrieved client
        /// </returns>
        public static AccountDetails GetAccount(string subscriptionId)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "client$getBySubscription";
                    cmd.Parameters.Add("@subscription",subscriptionId);
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (false == r.HasRows) 
                            return null;
                        else
                        {
                            r.Read();
                            return(new AccountDetails(r));
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Inserts a new account
        /// </summary>
        /// <param name="ad">
        /// Account to insert
        /// </param>
        public static int InsertAccount(AccountDetails ad)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command to get the id of the account
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "client$ins";
                    cmd.Parameters.Add("@company",ad.Company);
                    cmd.Parameters.Add("@contact",ad.Contact);
                    cmd.Parameters.Add("@phoneNo",ad.PhoneNo);
                    cmd.Parameters.Add("@email",ad.Email);
                    cmd.Parameters.Add("@accountNo",ad.AccountNo);
                    cmd.Parameters.Add("@accountType",(int)ad.AccountType);
                    cmd.Parameters.Add("@newId", SqlDbType.Int);
                    cmd.Parameters["@newId"].Direction = ParameterDirection.Output;
                    // Execute
                    cmd.ExecuteNonQuery();
                    // Return the new id
                    return Convert.ToInt32(cmd.Parameters["@newId"].Value);
                }
                catch(SqlException e)
                {
                    if (e.Message.IndexOf("akClient$Account") != -1)
                    {
                        throw new DatabaseException("Account already exists");
                    }
                    else
                    {
                        throw new DatabaseException(StripErrorMsg(e.Message));
                    }
                }
            }
        }

        /// <summary>
        /// Changes the attributes for a given account
        /// </summary>
        /// <param name="ad">
        /// Account to modify
        /// </param>
        public static void UpdateAccount(AccountDetails ad)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command to get the id of the account
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "client$upd";
                    cmd.Parameters.Add("@clientId",ad.Id);
                    cmd.Parameters.Add("@company",ad.Company);
                    cmd.Parameters.Add("@contact",ad.Contact);
                    cmd.Parameters.Add("@phoneNo",ad.PhoneNo);
                    cmd.Parameters.Add("@email",ad.Email);
                    cmd.Parameters.Add("@password",ad.Password);
                    cmd.Parameters.Add("@salt",ad.Salt);
                    cmd.Parameters.Add("@accountNo",ad.AccountNo);
                    cmd.Parameters.Add("@accountType",(int)ad.AccountType);
                    cmd.Parameters.Add("@allowDynamic",ad.AllowDynamic);
                    cmd.Parameters.Add("@lastContact",ad.LastContact);
                    // Execute
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Deletes a client account
        /// </summary>
        /// <param name="ad">
        /// Account to delete
        /// </param>
        public static void DeleteAccount(AccountDetails ad)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "client$del";
                    cmd.Parameters.Add("@clientId",ad.Id);
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Inserts a new license
        /// </summary>
        /// <param name="account">
        /// Account to which to attach license
        /// </param>
        /// <param name="newLicense">
        /// Details of license to add
        /// </param>
		public static void InsertLicense(AccountDetails clientAccount, ProductLicenseDetails newLicense)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
				try
				{
					// Build the command to get the id of the account
					SqlCommand cmd = sqlConn.CreateCommand();
					cmd.CommandType = CommandType.StoredProcedure;
					cmd.CommandText = "productLicense$ins";
					cmd.Parameters.Add("@clientId",clientAccount.Id);
					cmd.Parameters.Add("@typeId",newLicense.LicenseType);
					cmd.Parameters.Add("@units",newLicense.Units);
					cmd.Parameters.Add("@issueDate",newLicense.IssueDate);
					cmd.Parameters.Add("@expireDate",newLicense.ExpireDate);
					// Execute
					cmd.ExecuteNonQuery();
				}
				catch (SqlException e)
				{
					if (e.Message.IndexOf("akProductLicense$ClientLicense") != -1)
					{
						throw new DatabaseException("License already exists");
					}
					else
					{
						throw new DatabaseException(StripErrorMsg(e.Message));
					}
				}
            }
        }
            
        /// <summary>
        /// Retireves the licenses for a given client
        /// </summary>
        /// <param name="clientId">
        /// Id of the client for which we will retrieve licenses
        /// </param>
        /// <returns>
        /// Array of product license objects
        /// </returns>
        public static ProductLicenseDetails[] RetrieveLicenses(int clientId)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    ArrayList productLicenses = new ArrayList();
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "productLicense$getByClient";
                    cmd.Parameters.Add("@clientId",clientId);
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (false == r.HasRows)
                        {
                            return null;
                        }
                        else
                        {
                            while(r.Read() != false)
                            {
                                productLicenses.Add(new ProductLicenseDetails(r));
                            }
                            // Return array of product licenses
                            return (ProductLicenseDetails[])productLicenses.ToArray(typeof(ProductLicenseDetails));
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Deletes a license
        /// </summary>
        /// <param name="account">
        /// Account to which to attach license
        /// </param>
        /// <param name="newLicense">
        /// Details of license to add
        /// </param>
        public static void DeleteLicense(AccountDetails clientAccount, int licenseType)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command to get the id of the account
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "productLicense$del";
                    cmd.Parameters.Add("@clientId",clientAccount.Id);
                    cmd.Parameters.Add("@typeId",licenseType);
                    // Execute
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Gets the minimum and maximum web application version range that is compatible
        /// with the given database version
        /// </summary>
        public static void GetWebVersionRange(string db, out string minWeb, out string maxWeb)
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "version$getByDb";
                    cmd.Parameters.Add("@dbVersion", db);
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (false == r.HasRows)
                        {
                            minWeb = "0.0.0.0";
                            maxWeb = "999.999.999.999";
                        }
                        else
                        {
                            r.Read();
                            minWeb = r.GetString(2);
                            maxWeb = r.GetString(3);
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Gets the medium types from the database
        /// </summary>
        /// <returns>
        /// Array of medium type objects
        /// </returns>
        public static MediumTypeDetails[] GetMediumTypes()
        {
            using (SqlConnection sqlConn = OpenConnection())
            {
                try
                {
                    ArrayList mediumTypes = new ArrayList();
                    // Build the command
                    SqlCommand cmd = sqlConn.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "mediumType$getTable";
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (false == r.HasRows)
                        {
                            return null;
                        }
                        else
                        {
                            while(r.Read() != false)
                            {
                                mediumTypes.Add(new MediumTypeDetails(r));
                            }
                            // Return array of product licenses
                            return (MediumTypeDetails[])mediumTypes.ToArray(typeof(MediumTypeDetails));
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Gets the subaccounts for a particular global account
        /// </summary>
        /// <returns>
        /// Array of subaccount objects
        /// </returns>
        public static SubaccountDetails[] GetSubaccounts(int globalId)
        {
            using (SqlConnection c = OpenConnection())
            {
                try
                {
                    ArrayList x = new ArrayList();
                    // Build the command
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "subaccount$getByGlobal";
                    // Parameter
                    cmd.Parameters.Add("@globalId", globalId);
                    // Execute reader
                    using(SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (false == r.HasRows)
                        {
                            return null;
                        }
                        else
                        {
                            while(r.Read() != false)
                            {
                                x.Add(new SubaccountDetails(r));
                            }
                            // Return array of subaccounts
                            return (SubaccountDetails[])x.ToArray(typeof(SubaccountDetails));
                        }
                    }
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Inserts a new subaccount
        /// </summary>
        /// <param name="accountId">
        /// Id of the account for which to introduce a subaccount
        /// </param>
        /// <param name="subaccountNo">
        /// Name of the subaccount
        /// </param>
        public static void InsertSubaccount(int globalId, string subaccountNo)
        {
            using (SqlConnection c = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "subaccount$ins";
                    // Parmeters
                    cmd.Parameters.Add("@globalId", globalId);
                    cmd.Parameters.Add("@accountNo", subaccountNo);
                    // Execute reader
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }

        /// <summary>
        /// Deletes a subaccount
        /// </summary>
        /// <param name="id">
        /// Id of the subaccount to delete
        /// </param>
        public static void DeleteSubaccount(int id)
        {
            using (SqlConnection c = OpenConnection())
            {
                try
                {
                    // Build the command
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "subaccount$del";
                    // Parmeters
                    cmd.Parameters.Add("@accountId", id);
                    // Execute reader
                    cmd.ExecuteNonQuery();
                }
                catch(SqlException e)
                {
                    throw new DatabaseException(StripErrorMsg(e.Message));
                }
            }
        }
    }
}
