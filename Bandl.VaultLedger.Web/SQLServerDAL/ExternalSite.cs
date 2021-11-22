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
    /// External site data access object
    /// </summary>
    public class ExternalSite : SQLServer, IExternalSite
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public ExternalSite() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public ExternalSite(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public ExternalSite(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Get an external site from the data source based on the unique name
        /// </summary>
        /// <param name="name">Unique identifier for an external site</param>
        /// <returns>External site information</returns>
        public ExternalSiteDetails GetExternalSite(string name)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] siteParms = new SqlParameter[1];
                    siteParms[0] = BuildParameter("@siteName", name);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "externalSiteLocation$getByName", siteParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new ExternalSiteDetails(r));
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
        /// Get an external site from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for an external site</param>
        /// <returns>External site information</returns>
        public ExternalSiteDetails GetExternalSite(int id)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] siteParms = new SqlParameter[1];
                    siteParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "externalSiteLocation$getById", siteParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new ExternalSiteDetails(r));
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
        /// Returns all external sites known to the system
        /// </summary>
        /// <returns>Returns a collection of all external sites</returns>
        public ExternalSiteCollection GetExternalSites()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "externalSiteLocation$getTable"))
                    {
                        return(new ExternalSiteCollection(r));
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
        /// Inserts a new external site into the system
        /// </summary>
        /// <param name="site">External site details to insert</param>
        public void Insert(ExternalSiteDetails site)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert external site reference");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[4];
                    p[0] = BuildParameter("@siteName", site.Name);
                    p[1] = BuildParameter("@location", (byte) site.Location);
                    p[2] = BuildParameter("@accountName", site.Account);
                    p[3] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the new external site
                    ExecuteNonQuery(CommandType.StoredProcedure, "externalSiteLocation$ins", p);
                    int newId = Convert.ToInt32(p[3].Value);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    // Issue exception
                    if (e.Message.IndexOf("akExternalSiteLocation$SiteName") != -1)
                    {
                        site.RowError = "A site map with the name '" + site.Name + "' already exists.";
                        throw new DatabaseException(site.RowError, e);
                    }
                    else
                    {
                        PublishException(e);
                        site.RowError = StripErrorMsg(e.Message);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Updates an existing external site
        /// </summary>
        /// <param name="site">External site details to update</param>
        public void Update(ExternalSiteDetails site)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update external site reference");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[5];
                    p[0] = BuildParameter("@id", site.Id);
                    p[1] = BuildParameter("@siteName", site.Name);
                    p[2] = BuildParameter("@location", (byte) site.Location);
                    p[3] = BuildParameter("@account", site.Account);
                    p[4] = BuildParameter("@rowVersion", site.RowVersion);
                    // Insert the new account
                    ExecuteNonQuery(CommandType.StoredProcedure, "externalSiteLocation$upd", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    site.RowError = StripErrorMsg(e.Message);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Deletes an existing external site
        /// </summary>
        /// <param name="site">External site to delete</param>
        public void Delete(ExternalSiteDetails site)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete external site reference");
                    // Build parameters
                    SqlParameter[] siteParms = new SqlParameter[2];
                    siteParms[0] = BuildParameter("@id", site.Id);
                    siteParms[1] = BuildParameter("@rowVersion", site.RowVersion);
                    // Delete the account
                    ExecuteNonQuery(CommandType.StoredProcedure, "externalSiteLocation$del", siteParms);
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
