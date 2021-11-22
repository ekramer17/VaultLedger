using System;
using System.Text;
using System.Data;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// Medium data access object
    /// </summary>
    public class SealedCase : SQLServer, ISealedCase
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public SealedCase() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public SealedCase(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public SealedCase(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Returns the profile information for a specific case
        /// </summary>
        public SealedCaseDetails GetSealedCase(string caseName)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] caseParms = new SqlParameter[1];
                    caseParms[0] = BuildParameter("@serialNo", caseName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sealedCase$getByName", caseParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new SealedCaseDetails(r));
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
        /// Inserts an empty sealed case
        /// </summary>
        /// <param name="d">
        /// Sealed case details to insert
        /// </param>
        public int Insert(SealedCaseDetails d)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    c.BeginTran("insert sealed case");
                    // Create the parameters
                    SqlParameter[] p = new SqlParameter[5];
                    p[0] = BuildParameter("@serialNo", d.CaseName);
                    p[1] = BuildParameter("@typeId", -100); // Database will get default
                    p[2] = BuildParameter("@returnDate", d.ReturnDate.Length != 0 ? DateTime.Parse(d.ReturnDate) : SqlDateTime.Null);
                    p[3] = BuildParameter("@notes", d.Notes);
                    p[4] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Update the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "sealedCase$ins", p);
                    // Commit the transaction
                    c.CommitTran();
                    // Return
                    return (Int32)p[4].Value;
                }
                catch(SqlException e)
                {
                    c.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Inserts a medium into a sealed case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case into which to insert the medium
        /// </param>
        /// <param name="serialNo">
        /// Serial number of the medium to place in the case
        /// </param>
        public void InsertMedium(string caseName, string serialNo)
        {
            Int32 i1 = -100;
            SealedCaseDetails caseObj = this.GetSealedCase(caseName);
            MediumDetails mediumObj = new Medium().GetMedium(serialNo);

            if (mediumObj == null)
                throw new DatabaseException("Medium not found.");

            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert medium into case");
                    // Case id?
                    if (caseObj != null)
                        i1 = caseObj.Id;
                    else
                        i1 = this.Insert(new SealedCaseDetails(caseName, "", "", ""));
                    // Build parameters
                    SqlParameter[] insParms = new SqlParameter[2];
                    insParms[0] = BuildParameter("@caseId", i1);
                    insParms[1] = BuildParameter("@mediumId", mediumObj.Id);
                    // Update the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "mediumSealedCase$ins", insParms);
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
        /// Removes a medium from its sealed case
        /// </summary>
        /// <param name="m">
        /// Medium to remove from its sealed case
        /// </param>
        public void RemoveMedium(MediumDetails m)
        {
            SealedCaseDetails caseObj = this.GetSealedCase(m.CaseName);
            if (caseObj == null)
            {
                throw new DatabaseException("Case not found.");
            }

            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("remove medium from sealed case");
                    // Build parameters
                    SqlParameter[] delParms = new SqlParameter[2];
                    delParms[0] = BuildParameter("@caseId", caseObj.Id);
                    delParms[1] = BuildParameter("@mediumId", m.Id);
                    // Update the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "mediumSealedCase$del", delParms);
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
        /// Gets the recall codes for a list of case names.  Used
        /// when creating list objects for the web service.
        /// </summary>
        /// <param name="caseNames">
        /// Array of caseNames
        /// </param>
        /// <returns>
        /// Array of same length as given array, containing the 
        /// corresponding recall code at each index
        /// </returns>
        public string[] GetRecallCodes(string[] caseNames)
        {
            string[] recallCodes = new string[caseNames.Length];
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    for(int i = 0; i < caseNames.Length; i++)
                    {
                        SqlParameter[] caseParms = new SqlParameter[1];
                        caseParms[0] = BuildParameter("@serialNo", caseNames[i]);
                        recallCodes[i] = (string)ExecuteScalar(CommandType.StoredProcedure, "sealedCase$getRecallCode", caseParms);
                        if (recallCodes[i] == null || recallCodes[i] == String.Empty)
                            throw new ApplicationException(String.Format("Recall code not found for case: {0}", caseNames[i]));
                    }
                    // return the string array
                    return recallCodes;
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets all of the media in a case
        /// </summary>
        /// <param name="caseName">
        /// Name of the sealed case
        /// </param>
        /// <returns>
        /// Collection of the media in the case
        /// </returns>
        public MediumCollection GetResidentMedia(string caseName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Build parameters
                    SqlParameter[] sqlParms = new SqlParameter[1];
                    sqlParms[0] = BuildParameter("@caseName", caseName);
                    // Get the verified media
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sealedCase$getMedia", sqlParms))
                    {
                        return new MediumCollection(r);
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
        /// Gets the media in the case that are verified on an active
        /// receive list.
        /// </summary>
        /// <param name="caseName">
        /// Name of the sealed case
        /// </param>
        /// <returns>
        /// Collection of the verified media
        /// </returns>
        public MediumCollection GetVerifiedMedia(string caseName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Build parameters
                    SqlParameter[] sqlParms = new SqlParameter[1];
                    sqlParms[0] = BuildParameter("@caseName", caseName);
                    // Get the verified media
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sealedCase$getVerified", sqlParms))
                    {
                        return new MediumCollection(r);
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
        /// Gets the sealed cases for the browse page
        /// </summary>
        /// <returns>
        /// A sealed case collection
        /// </returns>
        public SealedCaseCollection GetSealedCases()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sealedCase$browse"))
                    {
                        return new SealedCaseCollection(r);
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
        /// Updates a sealed case
        /// </summary>
        public void Update(SealedCaseDetails d)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update sealed case");
                    // Update the items
                    SqlParameter[] p = new SqlParameter[6];
                    p[0] = BuildParameter("@id", d.Id);
                    p[1] = BuildParameter("@serialNo", d.CaseName);
                    if (d.ReturnDate.Trim().Length != 0)
                        p[2] = BuildParameter("@returnDate", d.ReturnDate);
                    else
                        p[2] = BuildParameter("@returnDate", DBNull.Value);
                    p[3] = BuildParameter("@hotStatus", d.HotSite);
                    p[4] = BuildParameter("@notes", d.Notes);
                    p[5] = BuildParameter("@rowVersion", d.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sealedCase$upd", p);
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

        ///<summary>
        /// Deletes a sealed case
        /// </summary>
        public void Delete(SealedCaseDetails d)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update sealed case");
                    // Update the items
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@id", d.Id);
                    p[1] = BuildParameter("@rowVersion", d.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sealedCase$del", p);
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
