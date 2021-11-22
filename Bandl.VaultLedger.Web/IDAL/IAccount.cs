using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Account DAL
    /// </summary>
    public interface IAccount
	{
        /// <summary>
        /// Gets the number of accounts in the database
        /// </summary>
        /// <returns>
        /// Number of accounts in the database
        /// </returns>
        int GetAccountCount();
            
        /// <summary>
        /// Get an account from the data source based on the unique name
        /// </summary>
        /// <param name="name">Unique identifier for an account</param>
        /// <returns>Account information</returns>
        AccountDetails GetAccount(string name);

        /// <summary>
        /// Get an account from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for an account</param>
        /// <returns>Account information</returns>
        AccountDetails GetAccount(int id);

		/// <summary>
		/// Returns a collection of all the accounts
		/// </summary>
		/// <returns>Collection of all the accounts</returns>
		AccountCollection GetAccounts();
		
		/// <summary>
        /// Returns a collection of all the accounts
        /// </summary>
        /// <returns>Collection of all the accounts</returns>
        AccountCollection GetAccounts(bool filter);

        /// <summary>
        /// Inserts a new account
        /// </summary>
        /// <param name="account">
        /// Account to insert
        /// </param>
        void Insert(AccountDetails account);

        /// <summary>
        /// Updates an existing account
        /// </summary>
        /// <param name="type">
        /// Account to update
        /// </param>
        void Update(AccountDetails account);

        /// <summary>
        /// Deletes an account
        /// </summary>
        /// <param name="type">
        /// Account to delete
        /// </param>
        void Delete(AccountDetails account);
    }
}
