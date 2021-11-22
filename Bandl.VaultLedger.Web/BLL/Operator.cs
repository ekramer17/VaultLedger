using System;
using System.Threading;
using System.Security;
using System.Security.Principal;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Router;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage operators
    /// The Bandl.Library.VaultLedger.Model.OperatorDetails is used in most 
    /// methods and is used to store serializable information about an operator
    /// </summary>
    public class Operator
	{
        public static int GetOperatorCount()
        {
            return OperatorFactory.Create().GetOperatorCount();
        }

        /// <summary>
        /// Method to login into the system.  The operator must supply a 
        /// username and password.
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <param name="password">Password for an operator</param>
        /// <param name="role">Returns the role to which the user belongs</param>
        /// <returns>Returns the true if the operator was authenticated, otherwise false.</returns>
        public static bool Authenticate(string login, string password, out string role) 
        {
            // Initialize role
            role = "";
            // Verify input
            if(login == null || login == String.Empty)
            {
                throw new ArgumentException("Login not supplied.");
            }
            else if (password == null || password == String.Empty)
            {
                throw new ArgumentException("Password not supplied.");
            }
            // Get the operator that corresponds to this login
            OperatorDetails o = OperatorFactory.Create().GetOperator(login);
            if (o == null) return false;
            // Get the password hash of the salt value and supplied password
            string s = PwordHasher.HashPasswordAndSalt(password, o.Salt);
            // If the passwords match, set the role and return true
            if (s.Equals(o.Password) == false) 
            {
                return false;
            }
            else
            {
                role = o.Role;
                return true;
            }
        }

        /// <summary>
        /// Returns the operator information for a specific operator
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <returns>Returns the operator information for the operator</returns>
        public static OperatorDetails GetOperator(string login) 
        {
            if(login == null)
            {
                throw new ArgumentNullException("Login may not be null.");
            }
            else if (login == String.Empty)
            {
                throw new ArgumentException("Login may not be an empty string.");
            }
            else
            {
                return OperatorFactory.Create().GetOperator(login);
            }
        }

        /// <summary>
        /// Returns the operator information for a specific operator
        /// </summary>
        /// <param name="id">Unique identifier for an operator</param>
        /// <returns>Returns the operator information for the operator</returns>
        public static OperatorDetails GetOperator(int id) 
        {
            if (id <= 0)
            {
                throw new ArgumentException("Operator id must be greater than zero.");
            }
            else
            {
                return OperatorFactory.Create().GetOperator(id);
            }
        }

        /// <summary>
        /// Returns the contents of the Operator table
        /// </summary>
        /// <returns>Returns the operator information for the operator</returns>
        public static OperatorCollection GetOperators() 
        {
            return OperatorFactory.Create().GetOperators();
        }

		/// <summary>
		/// Returns the the accounts for the given operator
		/// </summary>
		/// <returns>Returns the account information</returns>
		public static AccountCollection GetAccounts(int id)
		{
			return OperatorFactory.Create().GetAccounts(id);
		}
			
		/// <summary>
        /// A method to insert a new operator
        /// </summary>
        /// <param name="o">An operator entity with information about the new operator</param>
        public static void Insert(ref OperatorDetails o) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is new
            if(o == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an operator object.");
            }
            else if(o.ObjState != ObjectStates.New)
            {
                throw new ObjectStateException("Only an operator marked as new may be inserted.");
            }
            // Reset the error flag
            o.RowError = String.Empty;
            // Get the number of operators in the system and compare to license
            int operatorLicenses = ProductLicense.GetProductLicense(LicenseTypes.Operators).Units;
            if (operatorLicenses != ProductLicenseDetails.Unlimited && GetOperatorCount() >= operatorLicenses)
            {
                throw new LicenseLimitException("Operator limit has been reached.  Additional licenses needed.");
            }
            // Insert the operator
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran("update operator");
                    OperatorFactory.Create(c).Insert(o);
                    // Insert into the hosting database
                    RouterDb.InsertLogin(o.Login);  // No harm if not hosted
                    // Commit the transaction
                    c.CommitTran();
                }
                catch (Exception e)
                {
                    o.RowError = e.Message;
                    c.RollbackTran();
                    throw;
                }
            }
            // Refetch the operator
            o = GetOperator(o.Login);
        }

        /// <summary>
        /// A method to update an existing operator
        /// </summary>
        /// <param name="o">An operator entity with information about the operator to be updated</param>
        public static void Update(ref OperatorDetails o) 
        {
            // Make sure that the data is modified
            if(o == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an operator object.");
            }
            else if(o.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only an operator marked as modified may be updated.");
            }
            // Reset the error flag
            o.RowError = String.Empty;
            // If user is not an administrator, he may only update his own password.
            VerifyUpdatePermission(o);
            // Get an instance of the operator DAL using the DALFactory
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran("update operator");
                    IOperator dal = OperatorFactory.Create(c);
                    // Get the current login
                    string oldLogin = dal.GetOperator(o.Id).Login;
                    // Update in the application database
                    dal.Update(o);
                    // Update in the hosting database
                    RouterDb.UpdateLogin(oldLogin, o.Login);  // No harm if not hoste
                    // Commit the transactionf
                    c.CommitTran();
                }
                catch (Exception e)
                {
                    o.RowError = e.Message;
                    c.RollbackTran();
                    throw;
                }
            }
            // Refetch the operator
            o = GetOperator(o.Id);
        }

        /// <summary>
        /// Deletes an existing operator
        /// </summary>
        /// <param name="o">Operator to delete</param>
        public static void Delete(ref OperatorDetails o)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is not new
            if(o == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an operator object.");
            }
            else if(o.ObjState != ObjectStates.Unmodified)
            {
                throw new ObjectStateException("Only an operator marked as unmodified may be deleted.");
            }
            // Reset the error flag
            o.RowError = String.Empty;
            // Delete the operator from the system database                
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran("delete operator");
                    OperatorFactory.Create(c).Delete(o);
                    // Delete from the hosting database
                    RouterDb.DeleteLogin(o.Login);  // No harm if not hosted
                    // Adjust object state
                    o.ObjState = ObjectStates.Deleted;
                    // Commit transaction
                    o.RowError = String.Empty;
                    c.CommitTran();
                }
                catch (Exception e)
                {
                    // Rollback
                    c.RollbackTran();
                    // Record the error
                    o.RowError = e.Message;
                    // Rethrow the exception
                    throw;
                }
            }
        }

        /// <summary>
        /// Gets a recall ticket associated with an operator
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <returns>Recall service authentication ticket</returns>
        public static Guid GetRecallTicket(string login)
        {
            if (login == null)
            {
                throw new ArgumentNullException("Login may not be null.");
            }
            else if (login == String.Empty)
            {
                throw new ArgumentException("Login may not be an empty string.");
            }
            else
            {
                return OperatorFactory.Create().GetRecallTicket(login);
            }
        }

        /// <summary>
        /// Inserts a new recall ticket
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <param name="ticket">Recall authentication ticket</param>
        public static void InsertRecallTicket(string login, Guid ticket)
        {
            if (login == null)
            {
                throw new ArgumentNullException("Login may not be null.");
            }
            else if (login == String.Empty)
            {
                throw new ArgumentException("Login may not be an empty string.");
            }
            else if (ticket == Guid.Empty)
            {
                throw new ArgumentNullException("Recall authentication ticket may not be empty.");
            }
            else
            {
                OperatorFactory.Create().InsertRecallTicket(login, ticket);
            }
        }

        /// <summary>
        /// Deletes a Recall service ticket
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        public static void DeleteRecallTicket(string login)
        {
            if (login == null)
            {
                throw new ArgumentNullException("Login may not be null.");
            }
            else if (login == String.Empty)
            {
                throw new ArgumentException("Login may not be an empty string.");
            }
            else
            {
                OperatorFactory.Create().DeleteRecallTicket(login);
            }
        }

        /// <summary>
        /// Checks whether or not to allow an operator update.
        /// </summary>
        /// <param name="newOperator">
        /// Operator details structure passed to update function
        /// </param>
        private static void VerifyUpdatePermission(OperatorDetails newOperator)
        {
            if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
            {
                OperatorDetails oldOperator = GetOperator(newOperator.Id);
                // If no operator, then return true.  This will fail later.
                if (oldOperator == null)
                {
                    throw new ObjectNotFoundException("Operator not found.");
                }
                // Verify that this user is the user currently logged in
                // on this session.
                if (oldOperator.Login != Thread.CurrentPrincipal.Identity.Name) 
                {
                    throw new SecurityException("Only the operator currently logged in to this session may be updated.");
                }
                // Compare the two.  If anything besides the password has
                // changed, disallow update.
                if (oldOperator.Role != newOperator.Role ||
                    oldOperator.Name != newOperator.Name ||
                    oldOperator.Email != newOperator.Email ||
                    oldOperator.Notes != newOperator.Notes ||
                    oldOperator.Login != newOperator.Login ||
                    oldOperator.PhoneNo != newOperator.PhoneNo) 
                {
                    throw new SecurityException("Only the password may be updated.");
                }
            }
        }

		public static void SetAccounts(Int32 id, String accounts)
		{
			OperatorFactory.Create().SetAccounts(id, accounts);
		}
	}
}