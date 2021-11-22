using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for Subscription.
	/// </summary>
	public class Subscription : SQLServer, ISubscription
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Subscription() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public Subscription(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public Subscription(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns the subscription number from the database
        /// </summary>
        /// <returns>
        /// Subscription number
        /// </returns>
        public string GetSubscription()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    return (string)ExecuteScalar(CommandType.StoredProcedure, "subscription$get");
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Inserts a subscription number in the database
        /// </summary>
        /// <param name="subscriptionNo">
        /// Subscription to insert into the database
        /// </param>
        public void Insert(string subscriptionNo)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert subscription", "System");
                    // Build parameters
                    SqlParameter[] sqlParm = new SqlParameter[1];
                    sqlParm[0] = BuildParameter("@number", subscriptionNo);
                    // Insert the subscription
                    ExecuteNonQuery(CommandType.StoredProcedure, "subscription$ins", sqlParm);
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
