using System;
using System.Data;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Summary description for IConnection.
	/// </summary>
	public interface IConnection : IDisposable
	{
        /// <summary>
        /// Returns the current transaction nest level, 0 if no transaction active
        /// </summary>
        int NestingLevel {get;}

        /// <summary>
        /// Returns the connection object
        /// </summary>
        IDbConnection Connection {get;}

        /// <summary>
        /// Returns the transaction object
        /// </summary>
        IDbTransaction Transaction {get;}

        /// <summary>
        /// Opens a connection
        /// </summary>
        /// <returns>
        /// The connection object just opened
        /// </returns>
        IConnection Open(string userId, string password);

        /// <summary>
        /// Opens a connection
        /// </summary>
        /// <returns>
        /// The connection object just opened
        /// </returns>
        IConnection Open();

        /// <summary>
        /// Closes a connection
        /// </summary>
        void Close();

        /// <summary>
        /// Begins a transaction
        /// </summary>
        void BeginTran();

        /// <summary>
        /// Begin a transaction with a description of the task for auditing 
        /// purposes.
        /// </summary>
        /// <param name="auditMsg">
        /// Task being performed during transaction - used for auditing purposes
        /// </param>
        void BeginTran(string auditMsg);

        /// <summary>
        /// Begin a transaction with a description of the task for auditing 
        /// purposes, and the identity under which to write the audits.
        /// </summary>
        /// <param name="auditMsg">
        /// Task being performed during transaction - used for auditing purposes
        /// </param>
        /// <param name="identity">
        /// Identity under which to write audits
        /// </param>
        void BeginTran(string auditMsg, string identity);

        /// <summary>
        /// Rolls a transaction back
        /// </summary>
        void RollbackTran();

        /// <summary>
        /// Commits a transaction
        /// </summary>
        void CommitTran();
    }
}
