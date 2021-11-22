using System;
using System.Text;
using System.Data;
using System.Collections;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for AuditTrail.
	/// </summary>
	public class AuditTrail : SQLServer, IAuditTrail
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public AuditTrail() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public AuditTrail(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public AuditTrail(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns a collection of audit trail records.  Implements paging.
        /// </summary>
        /// <param name="pageNo">
        /// Page number to retrieve
        /// </param>
        /// <param name="pageSize">
        /// Size of (i.e., number of records on) each page
        /// </param>
        /// <param name="auditTypes">
        /// Types of audit records to retrieve
        /// </param>
        /// <param name="totalRecords">
        /// Returns the total number of records that would be retrieved without page restrictions
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        public AuditTrailCollection GetAuditTrailPage(int pageNo, int pageSize, AuditTypes auditTypes, out int totalRecords)
        {
            return GetAuditTrailPage(pageNo, pageSize, auditTypes, new DateTime(1900,1,2), new DateTime(2999,1,1), String.Empty, String.Empty, out totalRecords);
        }

        /// <summary>
        /// Returns a collection of audit trail records.  Implements paging.
        /// </summary>
        /// <param name="pageNo">
        /// Page number to retrieve
        /// </param>
        /// <param name="pageSize">
        /// Size of (i.e., number of records on) each page
        /// </param>
        /// <param name="auditTypes">
        /// Types of audit records to retrieve
        /// </param>
        /// <param name="startDate">
        /// Start date of range for audit records to qualify
        /// </param>
        /// <param name="endDate">
        /// End date of range for audit records to qualify
        /// </param>
        /// <param name="totalRecords">
        /// Returns the total number of records that would be retrieved without page restrictions
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        public AuditTrailCollection GetAuditTrailPage(int pageNo, int pageSize, AuditTypes auditTypes, DateTime startDate, DateTime endDate, String obj, String login, out int totalRecords)
        {
            using (IConnection dbc = dataBase.Open())
            {
                String w1 = String.Empty;

                try
                {
                    SqlParameter[] auditParms = new SqlParameter[7];
                    auditParms[0] = BuildParameter("@pageNo", pageNo);
                    auditParms[1] = BuildParameter("@pageSize", pageSize);
                    auditParms[2] = BuildParameter("@auditTypes", (int)auditTypes);
                    auditParms[3] = BuildParameter("@startDate", startDate.Year > 1950 ? startDate : SqlDateTime.Null);
                    auditParms[4] = BuildParameter("@endDate", endDate.Year < 2500 ? endDate : SqlDateTime.Null);
                    auditParms[5] = BuildParameter("@object", obj);
                    auditParms[6] = BuildParameter("@login", login);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "auditTrail$getPage", auditParms))
                    {
                        AuditTrailCollection auditTrail = new AuditTrailCollection(r);
                        r.NextResult();
                        r.Read();
                        totalRecords = r.GetInt32(r.GetOrdinal("RecordCount"));
                        return(auditTrail);
                    }
                }
                catch(SqlException e)
                {
                    totalRecords = 0;
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns a collection of audit trail records for a particular medium.
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of tape
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        public AuditTrailCollection GetMediumTrail(string serialNo)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@serialNo", serialNo);
                    p[1] = BuildParameter("@startDate", DateTime.UtcNow.AddYears(-1));
                    p[2] = BuildParameter("@endDate", DateTime.UtcNow.AddDays(1));
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "auditTrail$getMedium", p))
                    {
                        return(new AuditTrailCollection(r));
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
        /// Cleans the audit trails
        /// </summary>
        public void CleanAuditTrail(AuditTypes auditType, DateTime cleanDate)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] auditParms = new SqlParameter[2];
                    auditParms[0] = BuildParameter("@auditType", (int)auditType);
                    auditParms[1] = BuildParameter("@cleanDate", cleanDate);
                    ExecuteNonQuery(CommandType.StoredProcedure, "auditTrail$clean", auditParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the set of audit expirations from the database
        /// </summary>
        /// <returns>
        /// Collection of AuditExpirationDetails objects
        /// </returns>
        public AuditExpirationCollection GetExpirations()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    AuditExpirationCollection returnCollection = new AuditExpirationCollection();
                    foreach(int i in Enum.GetValues(typeof(AuditTypes)))
                    {
                        if (i != (int)AuditTypes.AllValues)
                        {
                            SqlParameter[] auditParms = new SqlParameter[1];
                            auditParms[0] = BuildParameter("@auditType", i);
                            using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "auditTrail$getExpiration", auditParms))
                            {
                                while (r.Read())
                                {
                                    returnCollection.Add(new AuditExpirationDetails(r));
                                }
                            }
                        }
                    }
                    // Return the collection
                    return returnCollection;
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Updates the audit trail expirations in the database
        /// </summary>
        /// <param name="c">
        /// Collection of audit expirations
        /// </param>
        public void UpdateExpiration(AuditExpirationDetails auditExpiration)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update audit trail expiration");
                    // Update the expiration
                    SqlParameter[] auditParms = new SqlParameter[4];
                    auditParms[0] = BuildParameter("@auditType", (int)auditExpiration.AuditType);
                    auditParms[1] = BuildParameter("@archive", auditExpiration.Archive);
                    auditParms[2] = BuildParameter("@days", auditExpiration.Days);
                    auditParms[3] = BuildParameter("@rowVersion", auditExpiration.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "auditTrail$updateExpiration", auditParms);
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
