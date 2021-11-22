using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Summary description for IInventory
    /// </summary>
    public interface IInventory
    {
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
        byte[] GetLatestFileHash(string account, Locations inventoryLocation);
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
        void InsertInventory(string account, Locations location, byte[] fileHash, InventoryItemDetails[] items);
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
        void CompareInventories(string accounts, bool makeMedia, bool doResolve);
    }
}
