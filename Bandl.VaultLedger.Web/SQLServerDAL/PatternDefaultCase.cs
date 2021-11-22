using System;
using System.Data;
using System.Text;
using System.Threading;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// External site data access object
    /// </summary>
    public class PatternDefaultCase : SQLServer, IPatternDefaultCase
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public PatternDefaultCase() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public PatternDefaultCase(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public PatternDefaultCase(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns a collection of all the pattern defaults
        /// </summary>
        /// <returns>Collection of all the pattern defaults</returns>
        public PatternDefaultCaseCollection GetPatternDefaults()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "barCodePatternCase$getTable"))
                    {
                        return(new PatternDefaultCaseCollection(r));
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
        public PatternDefaultCaseDetails GetFinalPattern()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "barCodePatternCase$getFinal"))
                    {
                        if (!r.HasRows)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new PatternDefaultCaseDetails(r);
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
        /// Updates all the pattern defaults known to the system
        /// </summary>
        /// <param name="patterns">
        /// Collection of pattern defaults to update
        /// </param>
		/// <param name="blockSync">
		/// Block while synchronizing media to updated patterns
		/// </param>
		public void Update(PatternDefaultCaseCollection patternCollection)
        {
            int i = 1;
            string tranString = "update case formats";
            // Delete the bar code formats, then add the new ones
            using(IConnection c = dataBase.Open())
            {
                // Check to see if the formats are currently being updated
                if ((int)ExecuteScalar(CommandType.Text, "IF EXISTS (SELECT 1 FROM SpidLogin WHERE TagInfo = '" + tranString + "') SELECT 1 ELSE SELECT 0") == 1)
                {
                    throw new ApplicationException("Case formats are currently being updated by another session.  Please try again in a few minutes.");
                }
                else
                {
                    try
                    {
                        // Begin the transaction
                        c.BeginTran(tranString);
                        // Delete the bar code formats
                        this.ExecuteNonQuery(CommandType.StoredProcedure, "barCodePatternCase$del");
                        // Insert each of the formats
                        foreach (PatternDefaultCaseDetails d in patternCollection)
                        {
                            SqlParameter[] p = new SqlParameter[3];
                            p[0] = BuildParameter("@pattern", d.Pattern);
                            p[1] = BuildParameter("@position", i++);
                            p[2] = BuildParameter("@caseType", d.CaseType);
                            ExecuteNonQuery(CommandType.StoredProcedure, "barCodePatternCase$ins", p);
                            // If we have notes, insert them
                            if (d.Notes.Length != 0)
                            {
                                p = new SqlParameter[2];
                                p[0] = BuildParameter("@pattern", d.Pattern);
                                p[1] = BuildParameter("@notes", d.Notes);
                                ExecuteNonQuery(CommandType.StoredProcedure, "barCodePatternCase$updNotes", p);
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

        /// <summary>
        /// Inserts the default case pattern
        /// </summary>
        public void InsertDefault()
        {
            MediumTypeDetails md = null;
            MediumTypeCollection mc = new MediumType().GetMediumTypes();
            
            foreach(MediumTypeDetails m in mc)
            {
                if (m.Container == true)
                {
                    md = m;
                    break;
                }
            }

            // If we found a container type, insert it
            if (md != null)
            {
                using (IConnection dbc = dataBase.Open())
                {
                    try
                    {
                        dbc.BeginTran("insert medium bar code pattern default");
                        // Build parameters
                        SqlParameter[] patternParms = new SqlParameter[1];
                        patternParms[0] = BuildParameter("@patternString", String.Format(".*;{0}", md.Id));
                        // Insert the new pattern
                        ExecuteNonQuery(CommandType.StoredProcedure, "barCodePatternCase$ins", patternParms);
                        // Commit
                        dbc.CommitTran();
                    }
                    catch(SqlException e)
                    {
                        dbc.RollbackTran();
                        if (e.Message.IndexOf("akBarCodePatternCase$Pattern") == -1)
                            throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }
    }
}
