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
    /// Medium type data access object
    /// </summary>
    public class EmailServer : SQLServer, IEmailServer
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public EmailServer() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public EmailServer(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public EmailServer(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the email groups in the database
        /// </summary>
        /// <returns>
        /// Email groups
        /// </returns>
        public void GetServer(ref string serverName, ref string fromAddress)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "emailServer$get"))
                    {
                        if (r.HasRows == false)
                        {
                            serverName = String.Empty;
                            fromAddress = String.Empty;
                        }
                        else
                        {
                            r.Read();
                            serverName = r.GetString(0);
                            fromAddress = r.GetString(1);
                        }
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
        /// Updates the email server
        /// </summary>
        /// <param name="serverName">
        /// Name of the email server
        /// </param>
        /// <param name="fromAddress">
        /// Address from which to send email
        /// </param>
        public void Update(string serverName, string fromAddress)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update email server");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@serverName", serverName);
                    p[1] = BuildParameter("@fromAddress", fromAddress);
                    // Delete the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "emailServer$upd", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException ex)
                {
                    dbc.RollbackTran();
                    PublishException(ex);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

    }
}