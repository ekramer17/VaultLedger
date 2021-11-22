using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the DisasterCode List DAL
    /// </summary>
    public interface IDisasterCodeList
    {
        /// <summary>
        /// Gets the employed disaster list statuses from the database
        /// </summary>
        /// <returns>
        /// Disaster list statuses used
        /// </returns>
        DLStatus GetStatuses();

        /// <summary>
        /// Updates the statuses used for disaster code lists
        /// </summary>
        void UpdateStatuses(DLStatus statuses);

        /// <summary>
        /// Returns the information for a specific disaster code list
        /// </summary>
        /// <param name="id">
        /// Unique identifier for a disaster code list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the disaster code list</returns>
        DisasterCodeListDetails GetDisasterCodeList(int id, bool getItems);

        /// <summary>
        /// Returns the information for a specific disaster code list
        /// </summary>
        /// <param name="listName">
        /// Unique name of a disaster code list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the disaster code list</returns>
        DisasterCodeListDetails GetDisasterCodeList(string listName, bool getItems);

        /// <summary>
        /// Gets the disaster code lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve disaster code lists</param>
        /// <returns>Collection of disaster code lists created on the given date</returns>
        DisasterCodeListCollection GetListsByDate(DateTime date);

        /// <summary>
        /// Gets the disaster code lists created before a particular date that
        /// have been cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of disaster code lists</returns>
        DisasterCodeListCollection GetCleared(DateTime date);

        /// <summary>
        /// Returns a page of the contents of the DisasterCodeList table
        /// </summary>
        /// <returns>Returns a collection of disaster code lists in the given sort order</returns>
        DisasterCodeListCollection GetDisasterCodeListPage(int pageNo, int pageSize, DLSorts sortColumn, out int totalLists);

        /// <summary>
        /// Gets the number of entries on the disaster code list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        int GetDisasterCodeListItemCount(int listId);

        /// <summary>
        /// Gets the number of entries on the disaster code list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <param name="status">
        /// The status of the entries being counted toward the total
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        int GetDisasterCodeListItemCount(int listId, DLIStatus status);

        /// <summary>
        /// Returns the information for a specific disaster code list item
        /// </summary>
        /// <param name="itemId">
        /// Id number of the disaster code list item
        /// </param>
        /// <returns>
        /// Disaster code list item
        /// </returns>
        DisasterCodeListItemDetails GetDisasterCodeListItem(int itemId);

        /// <summary>
        /// Returns a page of the items of a disaster code list
        /// </summary>
        /// <returns>Returns a collection of disaster code items in the given sort order</returns>
        DisasterCodeListItemCollection GetDisasterCodeListItemPage(int listId, int pageNo, int pageSize, DLISorts sortColumn, out int totalItems);

        /// <summary>
        /// Returns a page of the items of a disaster code list
        /// </summary>
        /// <param name="listId">
        /// Id of the list whose items to retrieve
        /// </param>
        /// <param name="pageNo">
        /// Number of page to retrieve
        /// </param>
        /// <param name="pageSize">
        /// Number of records to be displayed on each page
        /// </param>
        /// <param name="sortColumn">
        /// Attribute on which to sort
        /// </param>
        /// <param name="itemStatus">
        /// Status that an item must have to be returned in the result set
        /// </param>
        /// <param name="totalItems">
        /// Number of items on the given list with the given item status
        /// </param>
        /// <returns>
        /// Returns a collection of list items in the given sort order
        /// </returns>
        DisasterCodeListItemCollection GetDisasterCodeListItemPage(int listId, int pageNo, int pageSize, DLIStatus itemStatus, DLISorts sortColumn, out int totalItems);

        /// <summary>
        /// Creates a new disaster code list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>Send list details object containing the created disaster code list</returns>
        DisasterCodeListDetails Create(DisasterCodeListItemCollection items);

        /// <summary>
        /// Merges a collection of disaster code lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        DisasterCodeListDetails Merge(DisasterCodeListCollection listCollection);

        /// <summary>
        /// Extracts a disaster code list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        void Extract(DisasterCodeListDetails compositeList, DisasterCodeListDetails discreteList);

        /// <summary>
        /// Dissolves a receive list from composite.  In other words, extracts all
        /// discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        void Dissolve(DisasterCodeListDetails compositeList);

        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        void Transmit(DisasterCodeListDetails list);

        /// <summary>
        /// Clears a disaster code list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        void Clear(DisasterCodeListDetails list);

        /// <summary>
        /// Deletes a disaster code list
        /// </summary>
        /// <param name="list">Send list to delete</param>
        void Delete(DisasterCodeListDetails list);

        /// <summary>
        /// Removes a disaster code list item.
        /// </summary>
        /// <param name="item">
        /// A disaster code list item to remove
        /// </param>
        void RemoveItem(DisasterCodeListItemDetails item);

        /// <summary>
        /// Updates a set disaster code list item.
        /// </summary>
        /// <param name="item">
        /// A disaster code list item to remove
        /// </param>
        void UpdateItem(DisasterCodeListItemDetails item);

        /// <summary>
        /// Adds an item to a given list
        /// </summary>
        /// <param name="listId">
        /// Id of the list to which the item should be added
        /// </param>
        /// <param name="item">
        /// Disaster code list item to add
        /// </param>
        void AddItem(String name, DisasterCodeListItemDetails item);

        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="dl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        EmailGroupCollection GetEmailGroups(DLStatus dl);

        /// <summary>
        /// Attaches an email group to a list status
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        /// <param name="dl">
        /// List status for which to get email groups
        /// </param>
        void AttachEmailGroup(EmailGroupDetails e, DLStatus dl);

        /// <summary>
        /// Detaches an email group from a list status
        /// </summary>
        /// <param name="e">
        /// Email group to detach
        /// </param>
        /// <param name="dl">
        /// List status for which to get email groups
        /// </param>
        void DetachEmailGroup(EmailGroupDetails e, DLStatus dl);

        /// <summary>
        /// Gets the email groups associated with a particular list alert profile
        /// </summary>
        /// <returns>
        /// Email group collection
        /// </returns>
        EmailGroupCollection GetEmailGroups();

        /// <summary>
        /// Attaches an email group to a list alert profile
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        void AttachEmailGroup(EmailGroupDetails e);

        /// <summary>
        /// Detaches an email group from a list alert profile
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        void DetachEmailGroup(EmailGroupDetails e);

        /// <summary>
        /// Gets the list alert days for shipping lists
        /// </summary>
        /// <returns></returns>
        int GetListAlertDays();

        /// <summary>
        /// Gets the time of the last list alert
        /// </summary>
        /// <returns></returns>
        DateTime GetListAlertTime();
            
        /// <summary>
        /// Updates the alert days
        /// </summary>
        /// <param name="listTypes">
        /// Type of list
        /// </param>
        /// <param name="days">
        /// Days for alert
        /// </param>
        void UpdateAlertDays(int days);
    
        /// Updates the alert time
        /// </summary>
        /// <param name="d">
        /// Time to update
        /// </param>
        void UpdateAlertTime(DateTime d);
    }
}
