using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Operator DAL
    /// </summary>
    public interface IOperator
	{
        /// <summary>
        /// Get an operator from the data source based on the unique login
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <returns>Operator information</returns>
        OperatorDetails GetOperator(string login);

        /// <summary>
        /// Get an operator from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for an operator</param>
        /// <returns>Operator information</returns>
        OperatorDetails GetOperator(int id);

        /// <summary>
        /// Returns the contents of the operator table
        /// </summary>
        /// <returns>Returns information on all operators</returns>
        OperatorCollection GetOperators();

        /// <summary>
        /// Gets the number of operators in the database
        /// </summary>
        /// <returns>
        /// Number of operators in the database
        /// </returns>
        int GetOperatorCount();

		/// <summary>
		/// Returns the the accounts for the given operator
		/// </summary>
		/// <returns>Returns the account information</returns>
		AccountCollection GetAccounts(int id);
			
		/// <summary>
		/// Sets the account permissions for a given user
		/// </summary>
		void SetAccounts(Int32 id, String accounts);

		/// <summary>
        /// Inserts a new operator into the system
        /// </summary>
        /// <param name="o">Operator details to insert</param>
        void Insert(OperatorDetails o);

        /// <summary>
        /// Updates an existing operator
        /// </summary>
        /// <param name="o">Operator details to update</param>
        void Update(OperatorDetails o);

        /// <summary>
        /// Deletes an existing operator
        /// </summary>
        /// <param name="o">Operator to delete</param>
        void Delete(OperatorDetails o);

        /// <summary>
        /// Gets a Recall service ticket associated with an operator
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <returns>Recall service authentication ticket</returns>
        Guid GetRecallTicket(string login);

        /// <summary>
        /// Inserts a new Recall service ticket
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <param name="ticket">Recall authentication ticket</param>
        void InsertRecallTicket(string login, Guid ticket);

        /// <summary>
        /// Deletes a Recall service ticket
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        void DeleteRecallTicket(string login);
    }
}
