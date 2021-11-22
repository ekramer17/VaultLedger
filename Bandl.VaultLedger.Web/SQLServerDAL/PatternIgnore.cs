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
	/// Summary description for PatternIgnore.
	/// </summary>
	public class PatternIgnore : SQLServer, IPatternIgnore
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public PatternIgnore() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public PatternIgnore(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public PatternIgnore(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns the detail information for a specific ignored 
        /// bar code pattern
        /// </summary>
        /// <param name="pattern">Unique identifier for an ignored pattern</param>
        /// <returns>Returns the information for the ignored pattern</returns>
        public PatternIgnoreDetails GetIgnoredPattern(string pattern)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] patternParms = new SqlParameter[1];
                    patternParms[0] = BuildParameter("@pattern", pattern);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ignoredBarCodePattern$getByPattern", patternParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new PatternIgnoreDetails(r));
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
        /// Returns the detail information for a specific ignored
        /// bar code pattern
        /// </summary>
        /// <param name="id">Unique identifier for an ignored pattern</param>
        /// <returns>Returns the detail information for the ignored pattern</returns>
        public PatternIgnoreDetails GetIgnoredPattern(int id)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] patternParms = new SqlParameter[1];
                    patternParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ignoredBarCodePattern$getById", patternParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new PatternIgnoreDetails(r));
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
        /// Returns all the ignored patterns known to the system in a collection
        /// </summary>
        /// <returns>Returns all the ignored patterns known to the system</returns>
        public PatternIgnoreCollection GetIgnoredPatterns()
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ignoredBarCodePattern$getTable"))
                    {
                        return(new PatternIgnoreCollection(r));
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
        /// A method to insert a ignored pattern
        /// </summary>
        /// <param name="pattern">An entity with information about the new pattern</param>
        public void Insert(PatternIgnoreDetails pattern)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert ignore pattern");
                    // Build parameters
                    SqlParameter[] patternParms = new SqlParameter[4];
                    patternParms[0] = BuildParameter("@pattern", pattern.Pattern);
                    patternParms[1] = BuildParameter("@systems", BitConverter.GetBytes(Convert.ToInt64(pattern.ExternalSystems)));
                    patternParms[2] = BuildParameter("@notes", pattern.Notes);
                    patternParms[3] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the new pattern
                    ExecuteNonQuery(CommandType.StoredProcedure, "ignoredBarCodePattern$ins", patternParms);
                    int newId = Convert.ToInt32(patternParms[3].Value);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    // Issue exception
                    if (e.Message.IndexOf("akIgnoredBarCodePattern$String") != -1)
                    {
                        pattern.RowError = "Bar code pattern '" + pattern.Pattern + "' already exists.";
                        throw new DatabaseException(pattern.RowError, e);
                    }
                    else
                    {
                        PublishException(e);
                        pattern.RowError = StripErrorMsg(e.Message);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// A method to update an existing ignored pattern
        /// </summary>
        /// <param name="patterb">
        /// An entity with information about the ignored pattern to be updated
        /// </param>
        public void Update(PatternIgnoreDetails pattern)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update ignore pattern");
                    // Build parameters
                    SqlParameter[] patternParms = new SqlParameter[5];
                    patternParms[0] = BuildParameter("@id", pattern.Id);
                    patternParms[1] = BuildParameter("@pattern", pattern.Pattern);
                    patternParms[2] = BuildParameter("@systems", BitConverter.GetBytes(Convert.ToInt64(pattern.ExternalSystems)));
                    patternParms[3] = BuildParameter("@notes", pattern.Notes);
                    patternParms[4] = BuildParameter("@rowVersion", pattern.RowVersion);
                    // Update the pattern
                    ExecuteNonQuery(CommandType.StoredProcedure, "ignoredBarCodePattern$upd", patternParms);
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
        /// Deletes an existing ignored pattern
        /// </summary>
        /// <param name="pattern">Ignored pattern to delete</param>
        public void Delete(PatternIgnoreDetails pattern)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete ignore pattern");
                    // Build parameters
                    SqlParameter[] patternParms = new SqlParameter[2];
                    patternParms[0] = BuildParameter("@id", pattern.Id);
                    patternParms[1] = BuildParameter("@rowVersion", pattern.RowVersion);
                    // Delete the pattern
                    ExecuteNonQuery(CommandType.StoredProcedure, "ignoredBarCodePattern$del", patternParms);
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
