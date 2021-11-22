using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Gateway.Bandl;
using Bandl.Library.VaultLedger.Gateway.Recall;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage accounts
    /// The Bandl.Library.VaultLedger.Model.AccountDetails is used in most 
    /// methods and is used to store serializable information about an account
    /// </summary>
    public class Account
    {
        /// <summary>
        /// Delegate for the RetrieveAccounts method.  Retrieves the accounts
        /// in an ansynchronous manner.
        /// </summary>
        private delegate AccountCollection RetrieveDelegate();

        /// <summary>
        /// Gets the number of accounts in the database
        /// </summary>
        /// <returns>
        /// Number of accounts in the database
        /// </returns>
        public static int GetAccountCount()
        {
            return AccountFactory.Create().GetAccountCount();
        }

        /// <summary>
        /// Returns the account information for a specific account
        /// </summary>
        /// <param name="name">
        /// Unique identifier (name) for an account
        /// </param>
        /// <returns>
        /// Account details
        /// </returns>
        public static AccountDetails GetAccount(string name) 
        {
            if(name == null)
            {
                throw new ArgumentNullException("Name of account may not be null.");
            }
            else if (name == String.Empty)
            {
                throw new ArgumentException("Name of account may not be an empty string.");
            }
            else
            {
                return AccountFactory.Create().GetAccount(name);
            }
        }

        /// <summary>
        /// Returns the account information for a specific account
        /// </summary>
        /// <param name="id">
        /// Unique identifier (id) for an account
        /// </param>
        /// <returns>
        /// Account details
        /// </returns>
        public static AccountDetails GetAccount(int id) 
        {
            if (id <= 0)
            {
                throw new ArgumentException("Account id must be greater than zero.");
            }
            else
            {
                return AccountFactory.Create().GetAccount(id);
            }
        }

		/// <summary>
		/// Returns the contents of the Account table
		/// </summary>
		/// <returns>
		/// Collection of account detail objects
		/// </returns>
		public static AccountCollection GetAccounts() 
		{
			return AccountFactory.Create().GetAccounts(true);
		}
		
		/// <summary>
        /// Returns the contents of the Account table
        /// </summary>
        /// <returns>
        /// Collection of account detail objects
        /// </returns>
        public static AccountCollection GetAccounts(bool filter) 
        {
            return AccountFactory.Create().GetAccounts(filter);
        }

		/// <summary>
		/// A method to insert a new account
		/// </summary>
		/// <param name="account">
		/// An account to add to the database
		/// </param>
		public static void Insert(ref AccountDetails account) 
		{
			// Must have administrator privileges
			CustomPermission.Demand(Role.Administrator);
			// Make sure that the data is new
			if(account == null)
			{
				throw new ArgumentNullException("site", "Reference must be set to an instance of an account object.");
			}
			else if(account.ObjState != ObjectStates.New)
			{
				throw new ObjectStateException("Only an account marked as new may be inserted.");
			}
            // Reset the error flag
            account.RowError = String.Empty;
            // Insert the site
			try
			{
				AccountFactory.Create().Insert(account);
				account = GetAccount(account.Name);
			}
			catch (Exception e)
			{
				account.RowError = e.Message;
				throw;
			}
		}

        /// <summary>
        /// Updates an existing account
        /// </summary>
        /// <param name="account">
        /// Details of account to be updated.  Returned by reference.
        /// </param>
        public static void Update(ref AccountDetails account) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is modified
            if(account == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an account object.");
            }
            else if(account.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only an account marked as modified may be updated.");
            }
            // Reset the error flag
            account.RowError = String.Empty;
            // Update the account
            try
            {
                AccountFactory.Create().Update(account);
                account = Account.GetAccount(account.Id);
            }
            catch (Exception e)
            {
                account.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Compares the accounts in the database with accounts fetched from
        /// the remote (vault) web service.
        /// </summary>
        public static void SynchronizeAccounts(bool doSync)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Retrieve and compare asynchronously if we already have accounts
            // in the database.  Otherwise compare synchronously.
            if (!doSync && GetAccountCount() != 0)
            {
                BeginRetrieveAccounts();
            }
            else
            {
                CompareAccounts((new RecallGateway()).RetrieveAccounts());
            }
        }

        /// <summary>
        /// Creates a delegate and invokes the RetrieveAccounts() method of 
        /// the remote (vault) web service gateway asynchronously.
        /// </summary>
        private static void BeginRetrieveAccounts()
        {
            RetrieveDelegate rd = new RetrieveDelegate((new RecallGateway()).RetrieveAccounts);
            rd.BeginInvoke(new AsyncCallback(EndRetrieveAccounts), rd);
        }

        /// <summary>
        /// Callback method that takes the results of the asynchronous call to 
        /// RetrieveAccounts() in the remote (vault) web service and passes
        /// to the method that compares local to remote accounts.
        /// </summary>
        private static void EndRetrieveAccounts(IAsyncResult ar)
        {
            CompareAccounts(((RetrieveDelegate)ar.AsyncState).EndInvoke(ar));
        }

        /// <summary>
        /// Compares the accounts in the database with accounts fetched from
        /// the web service.
        /// </summary>
        /// <param name="remoteAccounts">
        /// Collection of accounts retrieved from the remot (vault) web service
        /// </param>
        private static void CompareAccounts(AccountCollection remoteAccounts)
        {
            AccountDetails r = null;
            string errorText = String.Empty;
            AccountCollection localAccounts = Account.GetAccounts(false);
            AccountCollection deleteAccounts = new AccountCollection();
            AccountCollection insertAccounts = new AccountCollection();
            AccountCollection updateAccounts = new AccountCollection();
            // Add each remote type that does not exist in the collection 
            // of local types.
            foreach(AccountDetails a in remoteAccounts)
                if (null == localAccounts.Find(a.Name))
                    insertAccounts.Add(a);
            // Go through the local accounts.  Delete each one not present in 
            // the list of remote accounts.  Update each one present if necessary.
            foreach(AccountDetails l in localAccounts)
            {
                if ((r = remoteAccounts.Find(l.Name)) == null)
                {
                    deleteAccounts.Add(l);	// Add to collection; delete later
                }
                else
                {
                    if (l.Primary != r.Primary) l.Primary = r.Primary;
                    if (l.Address1 != r.Address1) l.Address1 = r.Address1;
                    if (l.Address2 != r.Address2) l.Address2 = r.Address2;
                    if (l.City != r.City) l.City = r.City;
                    if (l.State != r.State) l.State = r.State;
                    if (l.Country != r.Country) l.Country = r.Country;
                    if (l.ZipCode != r.ZipCode) l.ZipCode = r.ZipCode;
                    if (l.Contact != r.Contact) l.Contact = r.Contact;
                    if (l.PhoneNo != r.PhoneNo) l.PhoneNo = r.PhoneNo;
                    if (l.Email != r.Email) l.Email = r.Email;
                    if (l.Notes != r.Notes) l.Notes = r.Notes;
                    // Update if modified
                    if (l.ObjState == ObjectStates.Modified) 
                        updateAccounts.Add(l);
                }
            }

            // Create an account data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran("update accounts");
                    IAccount dal = AccountFactory.Create(c);
                    // Do the updates
                    foreach (AccountDetails d in updateAccounts)
                        dal.Update(d);
                    // Do the inserts
                    foreach (AccountDetails d in insertAccounts)
                        dal.Insert(d);
                    // Commit to this point
                    c.CommitTran();
                    c.BeginTran("delete account");
                    // Delete any accounts in the delete collection
                    if (deleteAccounts.Count != 0)
                    {
                        bool doReplace = false;
                        string replaceName = null;
                        // Find an account not being deleted
                        foreach (AccountDetails d in GetAccounts(false))
                            if (deleteAccounts.Find(d.Name) == null)
                                replaceName = d.Name;
                        // Replace all barcode formats with the replacement account
                        PatternDefaultMediumCollection pmc = PatternDefaultMedium.GetPatternDefaults();
                        for (int i = 0; i < pmc.Count; i++)
                        {
                            foreach (AccountDetails d in deleteAccounts)
                            {
                                if (pmc[i].Account == d.Name)
                                {
                                    pmc[i].Account = replaceName;
                                    doReplace = true;
                                    break;
                                }
                            }
                        }
                        // If we have to do a replace, do so here
                        if (doReplace == true)
                            PatternDefaultMediumFactory.Create(c).Update(pmc);
                        // Delete the accounts
                        foreach (AccountDetails d in deleteAccounts)
                            dal.Delete(d);
                    }
                    // Commit the transaction
                    c.CommitTran();
                }
                catch (Exception ex)
                {
                    c.RollbackTran();
                    new BandlGateway().PublishException(ex);
                    throw new ApplicationException(ex.Message);
                }
            }
        }
		/// <summary>
		/// Deletes an existing account
		/// </summary>
		/// <param name="accountCollection">
		/// Accounts to be deleted
		/// </param>
		public static void Delete(AccountCollection accountCollection) 
		{
			// Must have administrator privileges
			CustomPermission.Demand(Role.Administrator);
			// Make sure that the data is unmodified and that this is not the Recall product
			if(accountCollection == null)
			{
				throw new ArgumentNullException("Reference must be set to an instance of an account collection object.");
			}
			else if (Configurator.ProductType == "RECALL")
			{
				throw new ApplicationException("Recall implementation cannot conventionally delete accounts.");
			}
            // Test object status
			foreach (AccountDetails account in accountCollection)
				if(account.ObjState != ObjectStates.Unmodified)
					throw new ObjectStateException("Only an account marked as unmodified may be deleted.");
            // Create the account object
            IAccount dal = AccountFactory.Create();
            // Delete the accounts
            foreach (AccountDetails a in accountCollection)
            {
                try
                {
                    dal.Delete(a);
                }
                catch (Exception ex)
                {
                    a.RowError = ex.Message;
                    accountCollection.HasErrors = true;
                }
            }
            // If there were errors then throw a collection error exception
            if (accountCollection.HasErrors)
                throw new CollectionErrorException(accountCollection);
		}
	}
}
