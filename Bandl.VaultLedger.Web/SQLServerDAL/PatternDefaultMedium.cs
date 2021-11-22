using System;
using System.Data;
using System.Text;
using System.Threading;
using System.Collections;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// External site data access object
    /// </summary>
    public class PatternDefaultMedium : SQLServer, IPatternDefaultMedium
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public PatternDefaultMedium() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public PatternDefaultMedium(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public PatternDefaultMedium(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns a collection of all the pattern defaults
        /// </summary>
        /// <param name="literals">
        /// Gets the literals if true, does not if false
        /// </param>
        /// <returns>
        /// Collection pattern defaults
        /// </returns>
        public PatternDefaultMediumCollection GetPatternDefaults()
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "barCodePattern$getTable"))
                    {
                        return(new PatternDefaultMediumCollection(r));
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
        /// Returns the final pattern; should be the catch-all
        /// </summary>
        /// <returns>
        /// Final pattern in the table
        /// </returns>
        public PatternDefaultMediumDetails GetFinalPattern()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "barCodePattern$getFinal"))
                    {
                        if (!r.HasRows)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new PatternDefaultMediumDetails(r);
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
        /// Gets the default medium type and account for a medium serial number
        /// </summary>
        /// <param name="serialNo">
        /// Serial number for which to retrieve defaults
        /// </param>
        /// <param name="mediumType">
        /// Default medium type
        /// </param>
        /// <param name="accountName">
        /// Default account name
        /// </param>
        public void GetMediumDefaults(string serialNo, out string mediumType, out string accountName)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[3];
                    sqlParms[0] = BuildParameter("@serialNo", serialNo);
                    sqlParms[1] = BuildParameter("@typeName", SqlDbType.NVarChar, ParameterDirection.Output, 256);
                    sqlParms[2] = BuildParameter("@accountName", SqlDbType.NVarChar, ParameterDirection.Output, 256);
                    ExecuteNonQuery(CommandType.StoredProcedure, "barCodePattern$getDefaults", sqlParms);
                    mediumType = Convert.ToString(sqlParms[1].Value);
                    accountName = Convert.ToString(sqlParms[2].Value);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    mediumType = String.Empty;
                    accountName = String.Empty;
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Updates all the pattern defaults known to the system
        /// </summary>
        /// <param name="patterns">
        /// Collection of pattern defaults to update
        /// </param>
        /// <param name="blockSync">
        /// Block while synchronizing media to updated patterns
        /// </param>
        public void Update(PatternDefaultMediumCollection patternCollection)
        {
			bool b1;
			int i = 1;
            string tranString = "update bar code formats";
            // Delete the bar code formats, then add the new ones
            using(IConnection c = dataBase.Open())
            {
                // Check to see if the formats are currently being updated
                if ((int)ExecuteScalar(CommandType.Text, "IF EXISTS (SELECT 1 FROM SpidLogin WHERE TagInfo = '" + tranString + "') SELECT 1 ELSE SELECT 0") == 1)
                {
                    throw new ApplicationException("Bar code formats are currently being updated by another session.  Please try again in a few minutes.");
                }
                else
                {
                    try
                    {
                        // Begin the transaction
                        c.BeginTran(tranString);
                        // Delete the bar code formats
                        this.ExecuteNonQuery(CommandType.StoredProcedure, "barCodePattern$del");
                        // Insert each of the formats
                        foreach (PatternDefaultMediumDetails d in patternCollection)
                        {
							if (d.Pattern == ".*")
							{
								b1 = (0 == (int)ExecuteScalar(CommandType.Text, "SELECT count(*) FROM BarCodePattern x1 JOIN Account x2 ON x2.AccountId = x1.AccountId WHERE x1.Pattern = '.*' AND x2.AccountName = '" + d.Account + "'"));
							}
							else
							{
								b1 = true;
							}
							// Insert it?
							if (b1 == true)
							{
								SqlParameter[] p = new SqlParameter[4];
								p[0] = BuildParameter("@pattern", d.Pattern);
								p[1] = BuildParameter("@position", i++);
								p[2] = BuildParameter("@mediumType", d.MediumType);
								p[3] = BuildParameter("@accountName", d.Account);
								ExecuteNonQuery(CommandType.StoredProcedure, "barCodePattern$ins", p);
								// If we have notes, insert them
								if (d.Notes.Length != 0)
								{
									p = new SqlParameter[2];
									p[0] = BuildParameter("@pattern", d.Pattern);
									p[1] = BuildParameter("@notes", d.Notes);
									ExecuteNonQuery(CommandType.StoredProcedure, "barCodePattern$updNotes", p);
								}
							}
                        }
                        // Commit the transaction
                        c.CommitTran();
                    }
                    catch(SqlException e)
                    {
                        c.RollbackTran();
                        PublishException(e);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

//        /// <summary>
//        /// Inserts the default medium pattern
//        /// </summary>
//        public void InsertDefault()
//        {
//            MediumTypeDetails md = null;
//            AccountCollection ac = new Account().GetAccounts();
//            MediumTypeCollection mc = new MediumType().GetMediumTypes();
//            
//            foreach(MediumTypeDetails m in mc)
//            {
//                if (m.Container == false)
//                {
//                    md = m;
//                    break;
//                }
//            }
//
//            // If there is at least one container medium type and one account, insert it
//            if (md != null && ac.Count > 0)
//            {
//                using (IConnection dbc = dataBase.Open())
//                {
//                    try
//                    {
//                        dbc.BeginTran("insert medium bar code pattern default");
//                        // Build parameters
//                        SqlParameter[] patternParms = new SqlParameter[1];
//                        patternParms[0] = BuildParameter("@patternString", String.Format(".*;{0};{1}", md.Id, ac[0].Id));
//                        // Insert the new pattern
//                        ExecuteNonQuery(CommandType.StoredProcedure, "barCodePattern$ins", patternParms);
//                        // Commit
//                        dbc.CommitTran();
//                    }
//                    catch(SqlException e)
//                    {
//                        dbc.RollbackTran();
//                        if (e.Message.IndexOf("akBarCodePattern$Pattern") == -1)
//                            throw new DatabaseException(StripErrorMsg(e.Message), e);
//                    }
//                }
//            }
//        }
    }
}
