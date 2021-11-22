using System;
using System.Data;
using System.Collections;
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
    public class Inventory : SQLServer, IInventory
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Inventory() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public Inventory(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public Inventory(bool demandCreate) : base(demandCreate) {}

        #endregion
        
        /// <summary>
        /// Gets the latest inventory file hash from the database
        /// </summary>
        /// <param name="account">
        /// Account for which to retrieve results
        /// </param>
        /// <param name="inventoryLocation">
        /// Location at which inventory was taken
        /// </param>
        /// <returns>
        /// Byte array representing file hash
        /// </returns>
        public byte[] GetLatestFileHash(string account, Locations inventoryLocation)
        {   
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@account", account);
                    p[1] = BuildParameter("@location", inventoryLocation == Locations.Enterprise);
                    p[2] = BuildParameter("@fileHash", SqlDbType.Binary, ParameterDirection.Output);
                    p[2].Size = 32;
                    ExecuteNonQuery(CommandType.StoredProcedure, "inventory$getLatestHash", p);
                    if (Convert.IsDBNull(p[2].Value))
                        return null;
                    else
                        return (byte[])p[2].Value;
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        /// <summary>
        /// Inserts a new inventory into the database
        /// </summary>
        /// <param name="account">
        /// Account to which inventory corresponds
        /// </param>
        /// <param name="byteCount">
        /// Size of inventory file on server
        /// </param>
        /// <param name="lastWriteTime">
        /// Last write time of inventory file on server
        /// </param>
        /// <param name="items">
        /// Items in inventory
        /// </param>
        public void InsertInventory(string account, Locations location, byte[] fileHash, InventoryItemDetails[] items)
        {   
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert inventory");
                    // Insert the inventory
                    SqlParameter[] p = new SqlParameter[5];
                    p[0] = BuildParameter("@account", account);
                    p[1] = BuildParameter("@location", location == Locations.Enterprise);
                    p[2] = BuildParameter("@fileHash", fileHash);
                    p[3] = BuildParameter("@downloadTime", DateTime.UtcNow);
                    p[4] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    ExecuteNonQuery(CommandType.StoredProcedure, "inventory$ins", p);
                    int newId = Convert.ToInt32(p[4].Value);
                    // Insert each item
                    for (int i = 0; i < items.Length; i++)
                    {
                        p = new SqlParameter[6];
                        p[0] = BuildParameter("@inventoryId", newId);
                        p[1] = BuildParameter("@serialNo", items[i].SerialNo);
                        p[2] = BuildParameter("@typeName", items[i].TypeName);
                        p[3] = BuildParameter("@hotStatus", items[i].HotStatus);
                        p[4] = BuildParameter("@returnDate", items[i].ReturnDate);
                        p[5] = BuildParameter("@notes", items[i].Notes);
                        ExecuteNonQuery(CommandType.StoredProcedure, "inventoryItem$ins", p);
                    }
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
        /// Compares the last downloaded/uploaded inventories with the local system
        /// </summary>
        /// <param name="accounts">
        /// Comma-delimited list of account id numbers
        /// </param>
        /// <param name="makeMedia">
        /// Create media for unknown serial numbers
        /// </param>
        /// <param name="doResolve">
        /// Resolve conflicts automatically as possible
        /// </param>
        public void CompareInventories(string accounts, bool makeMedia, bool doResolve)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("compare inventory");
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@accounts", accounts);
                    p[1] = BuildParameter("@insertMedia", makeMedia);
                    p[2] = BuildParameter("@doResolve", doResolve);
                    // This might take a bit, so use a command timeout of 20 minutes
                    this.CommandTimeout = 1200;
                    // Execute the command
                    ExecuteNonQuery(CommandType.StoredProcedure, "inventory$compare", p);
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
