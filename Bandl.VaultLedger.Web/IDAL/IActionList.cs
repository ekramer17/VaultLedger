using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Summary description for IActionList.
    /// </summary>
    public interface IActionList
    {
        /// <summary>
        /// Purges lists created before the given date
        /// </summary>
        /// <param name="listTypes">
        /// Types of lists to purge
        /// </param>
        /// <param name="cleanDate">
        /// Create date prior to which to purge lists
        /// </param>
        void PurgeLists(ListTypes listTypes, DateTime cleanDate);

        /// <summary>
        /// Gets the set of list purge parameters from the database
        /// </summary>
        /// <returns>
        /// Collection of ListPurgeDetails objects
        /// </returns>
        ListPurgeCollection GetPurgeParameters();

        /// <summary>
        /// Gets the list purge parameters from the database for a particular type of list
        /// </summary>
        /// <returns>
        /// ListPurgeDetails object
        /// </returns>
        ListPurgeDetails GetPurgeParameters(ListTypes listType);

        /// <summary>
        /// Updates list purge parameters
        /// </summary>
        void UpdatePurgeParameters(ListPurgeDetails listPurge);

        /// <summary>
        /// Updates a list file character
        /// </summary>
        string GetListFileChar(ListTypes listType, Vendors vendor);

        /// <summary>
        /// Updates a list file character
        /// </summary>
        void UpdateListFileChar(ListTypes listType, Vendors vendor, char ch);

        Int32 GetListFileNumber(Vendors vendor);

        void SetListFileNumber(Vendors vendor, Int32 i1);
    }
}
