using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// Operator data access object
    /// </summary>
    public class Preference : SQLServer, IPreference
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Preference() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public Preference(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public Preference(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets a preference from the database
        /// </summary>
        /// <param name="key">Key value of the preference to retrieve</param>
        /// <returns>Preference on success, null if not found</returns>
        public PreferenceDetails GetPreference(PreferenceKeys key)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[1];
                    sqlParms[0] = BuildParameter("@keyNo", (int)key);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "preference$get", sqlParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false)
                        {
                            return PreferenceDetails.CreateDefault(key);
                        }
                        else
                        {
                            r.Read(); 
                            return(new PreferenceDetails(r));
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
        /// Gets all preferences from the database
        /// </summary>
        /// <returns>
        /// Collection of all preferences in the database
        /// </returns>
        public PreferenceCollection GetPreferences()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "preference$getTable"))
                    {
                        PreferenceCollection p = new PreferenceCollection(r);
                        // Make sure we have all the preferences in the collection
                        for (int i = 1; ; i++)
                        {
                            if (!Enum.IsDefined(typeof(PreferenceKeys), i))
                            {
                                break;
                            }
                            else if (null == p.Find((PreferenceKeys)Enum.ToObject(typeof(PreferenceKeys), i)))
                            {
                                p.Add(PreferenceDetails.CreateDefault((PreferenceKeys)Enum.ToObject(typeof(PreferenceKeys), i)));
                            }
                        }
                        // Return the collection
                        return p;
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
        /// Updates a preference in the database
        /// </summary>
        /// <param name="p">Preference to update</param>
        public void Update(PreferenceDetails p)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update preference");
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@keyNo", (int)p.Key);
                    sqlParms[1] = BuildParameter("@value", p.Value);
                    ExecuteNonQuery(CommandType.StoredProcedure, "preference$upd", sqlParms);
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
