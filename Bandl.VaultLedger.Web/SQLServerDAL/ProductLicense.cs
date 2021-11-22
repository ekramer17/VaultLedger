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
	/// Summary description for ProductLicense.
	/// </summary>
	public class ProductLicense : SQLServer, IProductLicense
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public ProductLicense() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public ProductLicense(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public ProductLicense(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets a license from the database
        /// </summary>
        /// <param name="licenseType">Type of license to retrieve</param>
        /// <returns>Product license detail object on success, null if not found</returns>
        public ProductLicenseDetails GetProductLicense(LicenseTypes licenseType)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] licenseParms = new SqlParameter[1];
                    licenseParms[0] = BuildParameter("@id", (int)licenseType);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "productLicense$getById", licenseParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new ProductLicenseDetails(r));
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
        /// Gets all licenses from the database
        /// </summary>
        /// <returns>Product license collection</returns>
        public ProductLicenseCollection GetProductLicenses()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "productLicense$getTable"))
                    {
                        return new ProductLicenseCollection(r);
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
        /// Inserts a license into the database
        /// </summary>
        /// <param name="license">Product license detail object</param>
        public void Insert(ProductLicenseDetails license)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Begin the transaction and impersonate the system
                    dbc.BeginTran("insert product license", this.SystemName);
                    // Build parameters
                    SqlParameter[] licenseParms = new SqlParameter[4];
                    licenseParms[0] = BuildParameter("@id", (int)license.LicenseType);
                    licenseParms[1] = BuildParameter("@value", license.Value64);
                    licenseParms[2] = BuildParameter("@issued", license.IssueDate);
                    licenseParms[3] = BuildParameter("@rayval", license.Ray64);
                    ExecuteNonQuery(CommandType.StoredProcedure, "productLicense$ins", licenseParms);
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
        /// Updates a license in the database
        /// </summary>
        /// <param name="license">
        /// Product license detail object
        /// </param>
        public void Update(ProductLicenseDetails license)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Begin the transaction and impersonate the system
                    dbc.BeginTran("update product license", this.SystemName);
                    // Build parameter
                    SqlParameter[] licenseParms = new SqlParameter[4];
                    licenseParms[0] = BuildParameter("@id", (int)license.LicenseType);
                    licenseParms[1] = BuildParameter("@value", license.Value64);
                    licenseParms[2] = BuildParameter("@issued", license.IssueDate);
                    licenseParms[3] = BuildParameter("@rayval", license.Ray64);
                    ExecuteNonQuery(CommandType.StoredProcedure, "productLicense$upd", licenseParms);
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
        /// Deletes a license in the database
        /// </summary>
        /// <param name="license">
        /// Product license detail object
        /// </param>
        public void Delete(LicenseTypes licenseType)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Begin the transaction and impersonate the system
                    dbc.BeginTran("delete product license", this.SystemName);
                    // Build parameter
                    SqlParameter[] licenseParms = new SqlParameter[1];
                    licenseParms[0] = BuildParameter("@id", (int)licenseType);
                    ExecuteNonQuery(CommandType.StoredProcedure, "productLicense$del", licenseParms);
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
