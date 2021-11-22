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
    public class MediumType : SQLServer, IMediumType
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public MediumType() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public MediumType(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public MediumType(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the number of medium types in the database
        /// </summary>
        /// <param name="container">
        /// Whether to get count for container types (true) or non-container 
        /// types (false)
        /// </param>
        /// <returns>
        /// Number of types in the database
        /// </returns>
        public int GetMediumTypeCount(bool container)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParm = new SqlParameter[1];
                    sqlParm[0] = BuildParameter("@container", container);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "mediumType$getCount",sqlParm);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Get a medium type from the data source based on the unique name
        /// </summary>
        /// <param name="name">Unique identifier for a medium type</param>
        /// <returns>MediumType information</returns>
        public MediumTypeDetails GetMediumType(string name)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] typeParms = new SqlParameter[1];
                    typeParms[0] = BuildParameter("@name", name);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "mediumType$getByName", typeParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new MediumTypeDetails(r));
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
        /// Get a medium type from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for a medium type</param>
        /// <returns>MediumType information</returns>
        public MediumTypeDetails GetMediumType(int id)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] typeParms = new SqlParameter[1];
                    typeParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "mediumType$getById", typeParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new MediumTypeDetails(r));
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
        /// Returns all medium types known to the system
        /// </summary>
        /// <returns>Returns a collection of all medium types</returns>
        public MediumTypeCollection GetMediumTypes()
        {
            SqlParameter[] vaultType = new SqlParameter[1];

            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    switch (Configurator.ProductType)
                    {
                        case "RECALL":
                            vaultType[0] = BuildParameter("@vaultCode", 1);
                            break;
                        case "B&L":
                        case "BANDL":
                        case "IMATION":
                            vaultType[0] = BuildParameter("@vaultCode", 0);
                            break;
                    }

                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "mediumType$getTable", vaultType))
                    {
                        return(new MediumTypeCollection(r));
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
        /// Returns the contents of the MediumType table, containers or non-containers only
        /// </summary>
        /// <param name="containerTypes">
        /// Returns container types if true, non-container types if false
        /// </param>
        /// <returns>
        /// Returns all of the appropriate medium types known to the system
        /// </returns>
        public MediumTypeCollection GetMediumTypes(bool containerTypes)
        {
            MediumTypeCollection returnCollection = new MediumTypeCollection();
            // Loop through all medium types, adding only those of the 
            // requested container status.
            foreach(MediumTypeDetails typeDetails in GetMediumTypes())
            {
                if (containerTypes == typeDetails.Container)
                {
                    returnCollection.Add(typeDetails);
                }
            }
            // Return the collection
            return returnCollection;
        }

        /// <summary>
        /// Inserts a new medium type into the system
        /// </summary>
        /// <param name="mediumType">MediumType details to insert</param>
        public void Insert(MediumTypeDetails mediumType)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Begin the transaction and impersonate the system
                    if (Configurator.ProductType == "RECALL")
                    {
                        dbc.BeginTran("insert medium type", this.SystemName);
                    }
                    else
                    {
                        dbc.BeginTran("insert medium type");
                    }
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[5];
                    p[0] = BuildParameter("@name", mediumType.Name);
                    p[1] = BuildParameter("@twoSided", mediumType.TwoSided);
                    p[2] = BuildParameter("@container", mediumType.Container);
                    p[3] = BuildParameter("@typeCode", mediumType.RecallCode);
                    p[4] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the new medium type
                    ExecuteNonQuery(CommandType.StoredProcedure, "mediumType$ins", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    // Issue exception
                    if (e.Message.IndexOf("akMediumType$TypeName") != -1)
                    {
                        mediumType.RowError = "A medium type with the name '" + mediumType.Name + "' already exists.";
                        throw new DatabaseException(mediumType.RowError, e);
                    }
                    else
                    {
                        PublishException(e);
                        mediumType.RowError = StripErrorMsg(e.Message);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Updates an existing medium type
        /// </summary>
        /// <param name="mediumType">Medium type details to update</param>
        public void Update(MediumTypeDetails mediumType)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Begin the transaction and impersonate the system
                    if (Configurator.ProductType == "RECALL")
                    {
                        dbc.BeginTran("update medium type", this.SystemName);
                    }
                    else
                    {
                        dbc.BeginTran("update medium type");
                    }
                    // Build parameters
                    SqlParameter[] typeParms = new SqlParameter[5];
                    typeParms[0] = BuildParameter("@id", mediumType.Id);
                    typeParms[1] = BuildParameter("@name", mediumType.Name);
                    typeParms[2] = BuildParameter("@twoSided", mediumType.TwoSided);
                    typeParms[3] = BuildParameter("@container", mediumType.Container);
                    typeParms[4] = BuildParameter("@rowVersion", mediumType.RowVersion);
                    // Insert the new account
                    ExecuteNonQuery(CommandType.StoredProcedure, "mediumType$upd", typeParms);
                    // Build parameters to insert the Recall code
                    SqlParameter[] codeParms = new SqlParameter[2];
                    codeParms[0] = BuildParameter("@code", mediumType.RecallCode);
                    codeParms[1] = BuildParameter("@typeId", mediumType.Id);
                    // Insert the Recall code
                    ExecuteNonQuery(CommandType.StoredProcedure, "recallCode$upd", codeParms);
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
        /// Deletes an existing medium type
        /// </summary>
        /// <param name="mediumType">Medium type to delete</param>
        public void Delete(MediumTypeDetails mediumType)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Begin the transaction and impersonate the system
                    if (Configurator.ProductType == "RECALL")
                    {
                        dbc.BeginTran("delete medium type", this.SystemName);
                    }
                    else
                    {
                        dbc.BeginTran("delete medium type");
                    }
                    // Build parameters
                    SqlParameter[] typeParms = new SqlParameter[2];
                    typeParms[0] = BuildParameter("@id", mediumType.Id);
                    typeParms[1] = BuildParameter("@rowVersion", mediumType.RowVersion);
                    // Delete the account
                    ExecuteNonQuery(CommandType.StoredProcedure, "mediumType$del", typeParms);
                    // No need to delete the Recall code, as this is done by a
                    // cascading foreign key.
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
