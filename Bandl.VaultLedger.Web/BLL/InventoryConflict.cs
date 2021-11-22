using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// Summary for the InventoryConflict class
    /// </summary>
    public class InventoryConflict
    {
        /// <summary>
        /// Get a Conflict from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for a conflict</param>
        /// <returns>Inventory conflict information</returns>
        public static InventoryConflictDetails GetConflict(int id)
        {
            return InventoryConflictFactory.Create().GetConflict(id);
        }
        /// <summary>
        /// Instructs the system to ignore existing inventory conflicts
        /// </summary>
        /// <param name="inventoryConflicts">
        /// Collection of conflicts to ignore
        /// </param>
        public static void IgnoreConflicts(ref InventoryConflictCollection inventoryConflicts)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (inventoryConflicts == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an inventory conflict collection object.");
            }
            else if (inventoryConflicts.Count == 0)
            {
                throw new ArgumentException("Inventory conflict collection must contain at least one inventory conflict object.");
            }
            // Reset the error flag
            inventoryConflicts.HasErrors = false;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IInventoryConflict dal = InventoryConflictFactory.Create(c);
                // Remove each item from the list
                foreach(InventoryConflictDetails i in inventoryConflicts)
                {
                    try
                    {
                        dal.IgnoreConflict(i);
                        i.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        i.RowError = e.Message;
                        inventoryConflicts.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (inventoryConflicts.HasErrors == false)
                {
                    c.CommitTran();
                }
                else
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(inventoryConflicts);
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
        /// <param name="type">
        /// Type of conflict to retrieve
        /// </param>
        /// <param name="sort">
        /// Column on which to sort
        /// </param>
        /// <param name="total">
        /// Total number of coniflicts in the system
        /// </param>
        /// <returns>
        /// Collection of inventory conflicts that fit the given filter in the given sort order
        /// </returns>
        public static InventoryConflictCollection GetConflictPage(int pageNo, int pageSize, String accounts, InventoryConflictTypes type, InventoryConflictSorts sort, out int total)
        {
            if (pageNo <= 0)
            {
                throw new ArgumentException("Page number must be greater than zero.");
            }
            else if (pageSize <= 0)
            {
                throw new ArgumentException("Page size must be greater than zero.");
            }
            else
            {
                return InventoryConflictFactory.Create().GetConflictPage(pageNo, pageSize, accounts, type, sort, out total);
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
        /// <param name="sortColumn">
        /// Column on which to sort
        /// </param>
        /// <param name="total">
        /// Total number of inventory conflicts in the system
        /// </param>
        /// <returns>
        /// Collection of inventory conflicts that fit the given filter in the given sort order
        /// </returns>
        public static InventoryConflictCollection GetConflictPage(int pageNo, int pageSize, String accounts, InventoryConflictSorts sort, out int total)
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
