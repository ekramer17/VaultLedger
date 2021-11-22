using System;
using System.Data;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Summary description for IDatabase.
	/// </summary>
	public interface IDatabase
	{
        /// <summary>
        /// Returns the database version information
        /// </summary>
        /// <returns>
        /// Database version
        /// </returns>
        DatabaseVersionDetails GetVersion();

        /// A method to update the datbase version number
        /// </summary>
        /// <param name="version">
        /// New database version number
        /// </param>
        void UpdateVersion(DatabaseVersionDetails version);

        /// <summary>
        /// Executes a command against the database with the given uid and pwd
        /// </summary>
        /// <param name="uid">
        /// User id with which to login to the database
        /// </param>
        /// <param name="pwd">
        /// Password with which to login to the database
        /// </param>
        /// <param name="commandText">
        /// Command to execute against the database
        /// </param>
        void ExecuteCommand(string uid, string pwd, string commandText);

        /// <summary>
        /// Executes a query against the database with the given uid and pwd
        /// </summary>
        /// <param name="uid">
        /// User id with which to login to the database
        /// </param>
        /// <param name="pwd">
        /// Password with which to login to the database
        /// </param>
        /// <param name="queryText">
        /// Query to run against the database
        /// </param>
        IDataReader ExecuteQuery(string uid, string pwd, string queryText);
    }
}
