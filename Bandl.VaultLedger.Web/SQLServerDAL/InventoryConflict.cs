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
    /// Summary description for VaultDiscrepancy.
    /// </summary>
    public class InventoryConflict : SQLServer, IInventoryConflict
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public InventoryConflict() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public InventoryConflict(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public InventoryConflict(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Get a conflict from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for a conflict</param>
        /// <returns>Vault conflict information</returns>
        public InventoryConflictDetails GetConflict(int id)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "inventoryConflict$getById", p))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new InventoryConflictDetails(r));
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
        /// Instructs the system to ignore an existing inventory conflict
        /// </summary>
        /// <param name="d">Discrepancy to ignore</param>
        public void IgnoreConflict(InventoryConflictDetails c)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("ignore inventory conflict");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@Id", c.Id);
                    // Ignore the discrepancy
                    ExecuteNonQuery(CommandType.StoredProcedure, "inventoryConflict$ignore", p);
                    // Commit transaction
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
        /// Returns a page of inventory conflicts
        /// </summary>
        /// <param name="pageNo">
        /// Number of the page to return
        /// </param>
        /// <param name="pageSize">
        /// Size of the page
        /// </param>
        /// <param name="accounts">
        /// Comma-delimited list of account id numbers
        /// </param>
        /// <param name="sortColumn">
        /// Column on which to sort
        /// </param>
        /// <param name="total">
        /// Total number of conflicts in the system
        /// </param>
        /// <returns>
        /// Collection of inventory conflicts that fit the given filter in the given sort order
        /// </returns>
        public InventoryConflictCollection GetConflictPage(int pageNo, int pageSize, String accounts, InventoryConflictTypes type, InventoryConflictSorts sort, out int total)
        {
            String s1 = String.Empty;
            // Get the conflict types
            foreach(int x1 in Enum.GetValues(typeof(InventoryConflictTypes)))
            {
                if (((Int32)type & x1) != 0)
                {
                    s1 += "," + x1.ToString();
                }
            }
            // Get the discrepancies
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[5];
                    p[0] = BuildParameter("@pageNo", pageNo);
                    p[1] = BuildParameter("@pageSize", pageSize);
                    p[2] = BuildParameter("@accounts", accounts);
                    p[3] = BuildParameter("@filter", String.Format("ConflictType IN ({0})", s1.Substring(1)));
                    p[4] = BuildParameter("@sort", (short)sort);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "inventoryConflict$getPage", p))
                    {
                        InventoryConflictCollection c = new InventoryConflictCollection(r);
                        r.NextResult();
                        r.Read();
                        total = r.GetInt32(0);
                        return(c);
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
        /// Returns a page of inventory conflicts
        /// </summary>
        /// <param name="pageNo">
        /// Number of the page to return
        /// </param>
        /// <param name="pageSize">
        /// Size of the page
        /// </param>
        /// <param name="accounts">
        /// Comma-delimited list of account id numbers
        /// </param>
        /// <param name="sortColumn">
        /// Column on which to sort
        /// </param>
        /// <param name="total">
        /// Total number of conflicts in the system
        /// </param>
        /// <returns>
        /// Collection of inventory conflicts that fit the given filter in the given sort order
        /// </returns>
        public InventoryConflictCollection GetConflictPage(int pageNo, int pageSize, String accounts, InventoryConflictSorts sort, out int total)
        {
            InventoryConflictTypes t1;
            t1  = InventoryConflictTypes.Account;
            t1 |= InventoryConflictTypes.Location;
            t1 |= InventoryConflictTypes.ObjectType;
            t1 |= InventoryConflictTypes.UnknownSerial;
            return GetConflictPage(pageNo, pageSize, accounts, t1, sort, out total);
        }
    }
}
