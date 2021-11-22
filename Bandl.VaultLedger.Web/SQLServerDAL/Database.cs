using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for Database.
	/// </summary>
    public class Database : SQLServer, IDatabase
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Database() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public Database(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public Database(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns the database version information
        /// </summary>
        /// <returns>Database version</returns>
        public DatabaseVersionDetails GetVersion()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "databaseVersion$get"))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new DatabaseVersionDetails(r));
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// A method to update the datbase version number
        /// </summary>
        /// <param name="version">
        /// New database version number
        /// </param>
        public void UpdateVersion(DatabaseVersionDetails version)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update database version", "AutoUpdate");
                    // Build parameters
                    SqlParameter[] versionParms = new SqlParameter[3];
                    versionParms[0] = BuildParameter("@major", version.Major);
                    versionParms[1] = BuildParameter("@minor", version.Minor);
                    versionParms[2] = BuildParameter("@revision", version.Revision);
                    // Update the database version
                    ExecuteNonQuery(CommandType.StoredProcedure, "databaseVersion$upd", versionParms);
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
        public void ExecuteCommand(string uid, string pwd, string commandText)
        {
            using (IConnection dbc = dataBase.Open(uid, pwd))
            {
                try
                {
                    // Begin the transaction
                    dbc.BeginTran("update database", "AutoUpdate");
                    // Command timeout
                    this.CommandTimeout = 600;
                    // Execute the command
                    SqlCommand cmd = (SqlCommand)dbc.Connection.CreateCommand();
                    cmd.Transaction = (SqlTransaction)dbc.Transaction;
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = commandText;
                    cmd.ExecuteNonQuery();
                    // Commit
                    dbc.CommitTran();
                }
                catch (Exception e) 
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

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
        public IDataReader ExecuteQuery(string uid, string pwd, string queryText)
        {
            using (IConnection dbc = dataBase.Open(uid, pwd))
            {
                try
                {
                    // Command timeout
                    this.CommandTimeout = 600;
                    // Execute the command
                    SqlCommand cmd = (SqlCommand)dbc.Connection.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = queryText;
                    SqlDataReader r = cmd.ExecuteReader();
                    // Return opened data reader or null if no rows
                    if (r.HasRows == false)
                    {
                        return null;
                    }
                    else
                    {
                        r.Read();
                        return r;
                    }
                }
                catch (Exception e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
    }
}
