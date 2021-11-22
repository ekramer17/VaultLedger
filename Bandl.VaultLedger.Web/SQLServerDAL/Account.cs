using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// Account data access object
    /// </summary>
    public class Account : SQLServer, IAccount
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Account() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public Account(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public Account(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the number of accounts in the database
        /// </summary>
        /// <returns>
        /// Number of accounts in the database
        /// </returns>
        public int GetAccountCount()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "account$getCount");
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Get an account from the data source based on the unique name
        /// </summary>
        /// <param name="name">Unique identifier for an account</param>
        /// <returns>Account information</returns>
        public AccountDetails GetAccount(string name)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] accountParms = new SqlParameter[1];
                    accountParms[0] = BuildParameter("@name", name);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "account$getByName", accountParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new AccountDetails(r));
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Get an account from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for an account</param>
        /// <returns>Account information</returns>
        public AccountDetails GetAccount(int id)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] accountParms = new SqlParameter[1];
                    accountParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "account$getById", accountParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new AccountDetails(r));
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

		/// <summary>
		/// Returns the contents of the account table
		/// </summary>
		/// <returns>Returns the account information for the account</returns>
		public AccountCollection GetAccounts()
		{
			return this.GetAccounts(true);
		}
			
		/// <summary>
        /// Returns the contents of the account table
        /// </summary>
        /// <returns>Returns the account information for the account</returns>
        public AccountCollection GetAccounts(bool filter)
        {
			SqlDataReader r1 = null;
			string c1 = "SELECT count(*) FROM INFORMATION_SCHEMA.PARAMETERS WHERE SPECIFIC_NAME = 'account$getTable'";
			
			using (IConnection dbc = dataBase.Open())
            {
				try
				{
					switch ((Int32)ExecuteScalar(CommandType.Text, c1))
					{
						case 0:
							r1 = ExecuteReader(CommandType.StoredProcedure, "account$getTable");
							break;
						case 1:
							r1 = ExecuteReader(CommandType.StoredProcedure, "account$getTable", new SqlParameter[] {BuildParameter("@filter", filter)});
							break;
					}

					if (r1 == null)
					{
						return new AccountCollection();
					}
					else
					{
						return new AccountCollection(r1);
					}
				}
				catch(SqlException e) 
				{
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
				finally
				{
					if (r1 != null) r1.Close();
				}
            }
        }

        /// <summary>
        /// Inserts a new account into the system.  This action should be performed
        /// by the system only.
        /// </summary>
        /// <param name="account">Account details to insert</param>
        public void Insert(AccountDetails account)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    if (Configurator.ProductType == "RECALL")
                    {
                        dbc.BeginTran("insert account", this.SystemName);
                    }
                    else
                    {
                        dbc.BeginTran("insert account");
                    }
                    // Build parameters
                    SqlParameter[] accountParms = new SqlParameter[13];
                    accountParms[0] = BuildParameter("@name", account.Name);
                    accountParms[1] = BuildParameter("@global", account.Primary);
                    accountParms[2] = BuildParameter("@address1", account.Address1);
                    accountParms[3] = BuildParameter("@address2", account.Address2);
                    accountParms[4] = BuildParameter("@city", account.City);
                    accountParms[5] = BuildParameter("@state", account.State);
                    accountParms[6] = BuildParameter("@zipCode", account.ZipCode);
                    accountParms[7] = BuildParameter("@country", account.Country);
                    accountParms[8] = BuildParameter("@contact", account.Contact);
                    accountParms[9] = BuildParameter("@phoneNo", account.PhoneNo);
                    accountParms[10] = BuildParameter("@email", account.Email);
                    accountParms[11] = BuildParameter("@notes", account.Notes);
                    accountParms[12] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the new account
                    ExecuteNonQuery(CommandType.StoredProcedure, "account$ins", accountParms);
                    int newId = Convert.ToInt32(accountParms[12].Value);
                    // Insert the FTP profile
                    UpdateFtpProfile(newId, account.FtpProfile);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    // Issue exception
                    if (e.Message.IndexOf("akAccount$AccountName") != -1)
                    {
                        account.RowError = "An account with the name '" + account.Name + "' already exists.";
                        throw new DatabaseException(account.RowError, e);
                    }
                    else
                    {
                        PublishException(e);
                        account.RowError = StripErrorMsg(e.Message);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Updates an existing account
        /// </summary>
        /// <param name="account">Account details to update</param>
        public void Update(AccountDetails account)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    if (Configurator.ProductType == "RECALL")
                    {
                        dbc.BeginTran("update account", this.SystemName);
                    }
                    else
                    {
                        dbc.BeginTran("update account");
                    }
                    // Build parameters
                    SqlParameter[] accountParms = new SqlParameter[14];
                    accountParms[0] = BuildParameter("@id", account.Id);
                    accountParms[1] = BuildParameter("@name", account.Name);
                    accountParms[2] = BuildParameter("@global", account.Primary);
                    accountParms[3] = BuildParameter("@address1", account.Address1);
                    accountParms[4] = BuildParameter("@address2", account.Address2);
                    accountParms[5] = BuildParameter("@city", account.City);
                    accountParms[6] = BuildParameter("@state", account.State);
                    accountParms[7] = BuildParameter("@zipCode", account.ZipCode);
                    accountParms[8] = BuildParameter("@country", account.Country);
                    accountParms[9] = BuildParameter("@contact", account.Contact);
                    accountParms[10] = BuildParameter("@phoneNo", account.PhoneNo);
                    accountParms[11] = BuildParameter("@email", account.Email);
                    accountParms[12] = BuildParameter("@notes", account.Notes);
                    accountParms[13] = BuildParameter("@rowVersion", account.RowVersion);
                    // Update the account
                    ExecuteNonQuery(CommandType.StoredProcedure, "account$upd", accountParms);
                    // If there is a FTP profile, update it.  Otherwise delete it.
                    if (account.FtpProfile.Length != 0)
                    {
                        UpdateFtpProfile(account.Id, account.FtpProfile);
                    }
                    else
                    {
                        DeleteFtpProfile(account.Id);
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }


        /// <summary>
        /// Deletes an existing account
        /// </summary>
        /// <param name="account">
        /// Account to delete
        /// </param>
        public void Delete(AccountDetails account)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    if (Configurator.ProductType == "RECALL")
                    {
                        dbc.BeginTran("delete account", this.SystemName);
                    }
                    else
                    {
                        dbc.BeginTran("delete account");
                    }
                    // Build parameters
                    SqlParameter[] accountParms = new SqlParameter[2];
                    accountParms[0] = BuildParameter("@id", account.Id);
                    accountParms[1] = BuildParameter("@rowVersion", account.RowVersion);
                    // Delete the account
                    ExecuteNonQuery(CommandType.StoredProcedure, "account$del", accountParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Updates the FTP profile of an account
        /// </summary>
        /// <param name="accountId">
        /// Id of account for which to update profile
        /// </param>
        /// <param name="profileName">
        /// Name of the profile with which to update account
        /// </param>
        private void UpdateFtpProfile(int accountId, string profileName)
        {
            if (profileName.Length != 0)
            {
                SqlParameter[] ftpParms = new SqlParameter[2];
                ftpParms[0] = BuildParameter("@accountId", accountId);
                ftpParms[1] = BuildParameter("@profileName", profileName);
                ExecuteNonQuery(CommandType.StoredProcedure, "ftpAccount$upd", ftpParms);
            }
        }

        /// <summary>
        /// Removes the FTP profile from an account
        /// </summary>
        /// <param name="accountId">
        /// Id of account for which to remove profile
        /// </param>
        private void DeleteFtpProfile(int accountId)
        {
            SqlParameter[] ftpParms = new SqlParameter[1];
            ftpParms[0] = BuildParameter("@accountId", accountId);
            ExecuteNonQuery(CommandType.StoredProcedure, "ftpAccount$del", ftpParms);
        }
    }
}
