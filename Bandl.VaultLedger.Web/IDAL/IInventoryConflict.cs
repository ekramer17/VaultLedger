using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Summary description for IInventoryConflict
    /// </summary>
    public interface IInventoryConflict
    {
        /// <summary>
        /// Get a conflict from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for a conflict</param>
        /// <returns>Vault conflict information</returns>
        InventoryConflictDetails GetConflict(int id);
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
        InventoryConflictCollection GetConflictPage(int pageNo, int pageSize, String accounts, InventoryConflictTypes type, InventoryConflictSorts sort, out int total);
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
        InventoryConflictCollection GetConflictPage(int pageNo, int pageSize, String accounts, InventoryConflictSorts sort, out int total);
        /// <summary>
        /// Instructs the system to ignore an existing inventory conflict
        /// </summary>
        /// <param name="d">Discrepancy to ignore</param>
        void IgnoreConflict(InventoryConflictDetails c);
    }
}
