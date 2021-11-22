using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for TabPageDefault.
	/// </summary>
	public class TabPageDefault : SQLServer, ITabPageDefault
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public TabPageDefault() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public TabPageDefault(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public TabPageDefault(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets a tab page default
        /// </summary>
        /// <param name="id">Tab default to retrieve</param>
        /// <param name="login">Login for which to get tab page default</param>
        /// <returns>Integer indicating page to display</returns>
        public int GetDefault(TabPageDefaults id, string login)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@id", (int)id);
                    p[1] = BuildParameter("@login", login);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "tabPageDefault$get", p);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        /// <summary>
        /// Updates a tab page default
        /// </summary>
        /// <param name="id">Tab default to retrieve</param>
        /// <param name="login">Login for which to get tab page default</param>
        /// <param name="tabPage">Number of default tab page</param>
        public void Update(TabPageDefaults id, string login, int tabPage)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update tab page default");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@id", (int)id);
                    p[1] = BuildParameter("@login", login);
                    p[2] = BuildParameter("@tabPage", tabPage);
                    // Insert the new account
                    ExecuteNonQuery(CommandType.StoredProcedure, "tabPageDefault$upd", p);
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
    }
}
