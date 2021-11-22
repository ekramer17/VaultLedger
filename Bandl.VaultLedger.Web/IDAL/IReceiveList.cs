using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Receive List DAL
    /// </summary>
    public interface IReceiveList
    {
        /// <summary>
        /// Gets the employed receive list statuses from the database
        /// </summary>
        /// <returns>
        /// Receive list statuses used
        /// </returns>
        RLStatus GetStatuses();
            
        /// <summary>
        /// Updates the statuses used for receive lists
        /// </summary>
        void UpdateStatuses(RLStatus statuses);

        /// <summary>
        /// Returns the information for a specific receive list
        /// </summary>
        /// <param name="id">
        /// Unique identifier for a receive list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the receive list</returns>
        ReceiveListDetails GetReceiveList(int id, bool getItems);

        /// <summary>
        /// Returns the information for a specific receive list
        /// </summary>
        /// <param name="listName">
        /// Unique name of a receive list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the receive list</returns>
        ReceiveListDetails GetReceiveList(string listName, bool getItems);

        /// <summary>
        /// Returns the complete receive list on which the given item appears
        /// </summary>
        /// <param name="ItemId">
        /// Item id number
        /// </param>
        /// <returns>
        /// Returns the complete receive list (with items), null if the 
        /// item does not appear on any lists.
        /// </returns>
        ReceiveListDetails GetReceiveListByItem(int itemId, bool getItems);
        
        /// <summary>
        /// Returns the complete receive list on which the given medium
        /// appears as active.
        /// </summary>
        /// <param name="serialNo">
        /// Medium serial number
        /// </param>
        /// <returns>
        /// Returns the complete receive list (with items), null if the 
        /// medium does not actively appear on any lists
        /// </returns>
        ReceiveListDetails GetReceiveListByMedium(string serialNo, bool getItems);
            
        /// <summary>
        /// Gets the receive lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve receive lists</param>
        /// <returns>Collection of receive lists created on the given date</returns>
        ReceiveListCollection GetListsByDate(DateTime date);

		/// <summary>
		/// Gets the receive lists for particular status(es) and date
		/// </summary>
		/// <param name="status">Status(es) to retrieve receive lists</param>
		/// <param name="date">Date for which to retrieve receive lists</param>
		/// <returns>Collection of receive lists created on the given date in the status(es)</returns>
		ReceiveListCollection GetListsByStatusAndDate(RLStatus status, DateTime date);

        /// <summary>
        /// Gets the receive lists created before a particular date that have been
        /// cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of receive lists</returns>
        ReceiveListCollection GetCleared(DateTime date);

        /// <summary>
        /// Gets the histotry of the given list
        /// </summary>
        AuditTrailCollection GetHistory(string listname);

        /// <summary>
        /// Returns a page of the contents of the ReceiveList table
        /// </summary>
        /// <returns>Returns a collection of receive lists in the given sort order</returns>
        ReceiveListCollection GetReceiveListPage(int pageNo, int pageSize, RLSorts sortColumn, out int totalLists);

		/// <summary>
		/// Returns a page of the contents of the ReceiveList table
		/// </summary>
		/// <returns>Returns a collection of receive lists in the given sort order</returns>
		ReceiveListCollection GetReceiveListPage(int pageNo, int pageSize, RLSorts sortColumn, string filter, out int totalLists);

        /// <summary>
        /// Creates a new receive list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>Send list details object containing the created receive list</returns>
        ReceiveListDetails Create(ReceiveListItemCollection items);

        /// <summary>
        /// Creates a new receive list using the given date as a return date
        /// </summary>
        /// <param name="receiveDate">
        /// Return date to use as cutoff point.  System will get all media at
        /// the vault, not currently on another list, with a return date 
        /// earlier or equal to the given date.
        /// </param>
        /// <param name="accounts">
        /// Comma-delimited list of account id numbers
        /// </param>
        /// <returns>
        /// Receive list details object containing the created receive list
        /// </returns>
        ReceiveListDetails Create(DateTime receiveDate, String accounts);

        /// <summary>
        /// Returns the information for a specific receive list item
        /// </summary>
        /// <param name="itemId">
        /// Id number of the receive list item
        /// </param>
        /// <returns>
        /// Receive list item
        /// </returns>
        ReceiveListItemDetails GetReceiveListItem(int itemId);
            
        /// <summary>
        /// Returns the information for a specific receive list item
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of a medium on the receive list
        /// </param>
        /// <returns>
        /// Receive list item
        /// </returns>
        ReceiveListItemDetails GetReceiveListItem(string serialNo);

        /// <summary>
        /// Gets the number of entries on the receive list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        int GetReceiveListItemCount(int listId);

        /// <summary>
        /// Gets the number of entries on the receive list with the given id
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
        int GetReceiveListItemCount(int listId, RLIStatus status);

        /// <summary>
        /// Returns a page of the items of a receive list
        /// </summary>
        /// <returns>
        /// Returns a collection of receive list items in the given sort order
        /// </returns>
        ReceiveListItemCollection GetReceiveListItemPage(int listId, int pageNo, int pageSize, RLISorts sortColumn, out int totalItems);
            
        /// <summary>
        /// Returns a page of the items of a receive list
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
        /// Returns a collection of receive list items in the given sort order
        /// </returns>
        ReceiveListItemCollection GetReceiveListItemPage(int listId, int pageNo, int pageSize, RLIStatus itemStatus, RLISorts sortColumn, out int totalItems);
            
        /// <summary>
        /// Merges a collection of receive lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        ReceiveListDetails Merge(ReceiveListCollection listCollection);

        /// <summary>
        /// Extracts a receive list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        void Extract(ReceiveListDetails compositeList, ReceiveListDetails discreteList);

        /// <summary>
        /// Dissolves a receive list from composite.  In other words, extracts all
        /// discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        void Dissolve(ReceiveListDetails compositeList);

        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        void Transmit(ReceiveListDetails list);

        /// <summary>
        /// Transmits a receive list collection
        /// </summary>
        /// <param name="listCollection">Receive list collection to transmit</param>
        void Transmit(ReceiveListCollection listCollection);

        /// <summary>
        /// Marks a list as in transit
        /// </summary>
        /// <param name="rl">
        /// Receive list
        /// </param>
        void MarkTransit(ReceiveListDetails rl);
            
        /// <summary>
        /// Marks a list as arrived
        /// </summary>
        /// <param name="rl">
        /// Receive list
        /// </param>
        void MarkArrived(ReceiveListDetails rl);

        /// <summary>
        /// Clears a receive list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        void Clear(ReceiveListDetails list);

        /// <summary>
        /// Clears all fully verified receive lists, with the exception that
        /// if a discrete belongs to a composite, then it will not be cleared
        /// until all the other discretes in the composite are also cleared
        /// </summary>
        void ClearVerified();

        /// <summary>
        /// Deletes a receive list
        /// </summary>
        /// <param name="list">Send list to delete</param>
        void Delete(ReceiveListDetails list);

        /// <summary>
        /// Verifies a receive list item
        /// </summary>
        /// <param name="item">
        /// A receive list item to remove
        /// </param>
        void VerifyItem(ReceiveListItemDetails item);

        /// <summary>
        /// Removes a receive list item
        /// </summary>
        /// <param name="item">
        /// A receive list item to remove
        /// </param>
        void RemoveItem(ReceiveListItemDetails item);

        /// <summary>
        /// Updates a receive list item
        /// </summary>
        /// <param name="item">
        /// A receive list item to update
        /// </param>
        void UpdateItem(ReceiveListItemDetails item);

        /// <summary>
        /// Adds a receive list item
        /// </summary>
        /// <param name="item">
        /// A receive list item to add
        /// </param>
        void AddItem(ReceiveListDetails list, ReceiveListItemDetails item);

        /// <summary>
        /// Returns the information for a specific receive list scan
        /// </summary>
        /// <param name="id">Unique identifier for a receive list scan</param>
        /// <returns>Returns the information for the receive list scan</returns>
        ReceiveListScanDetails GetScan(int id);

        /// <summary>
        /// Returns the information for a specific receive list scan
        /// </summary>
        /// <param name="name">Unique identifier for a receive list scan</param>
        /// <returns>Returns the information for the receive list scan</returns>
        ReceiveListScanDetails GetScan(string name);

        /// <summary>
        /// Returns the information for a specific receive list scan item
        /// </summary>
        /// <param name="id">
        /// Id of the item
        /// </param>
        /// <returns>
        /// Receive list scan item object
        /// </returns>
        ReceiveListScanItemDetails GetScanItem(int id);

        /// <summary>
        /// Gets the scans for a specified receive list
        /// </summary>
        /// <param name="listName">
        /// Name of the list
        /// </param>
        /// <returns>
        /// Collection of scans
        /// </returns>
        ReceiveListScanCollection GetScansForList(string listName, int stage);
            
        /// <summary>
        /// Creates a receive list scan
        /// </summary>
        /// <param name="listName">
        /// List to which to attach the scan
        /// </param>
        /// <param name="scanName">
        /// Name to assign to the scan
        /// </param>
        /// <param name="items">
        /// Items to place in the scan
        /// </param>
        /// <returns>
        /// Created receive list scan
        /// </returns>
        ReceiveListScanDetails CreateScan(string listName, string scanName, ReceiveListScanItemDetails item);

        /// <summary>
        /// Deletes a set of receive list scan
        /// </summary>
        void DeleteScan(ReceiveListScanDetails scan);

        /// <summary>
        /// Adds an item to a scan
        /// </summary>
        void AddScanItem(int scanId, ReceiveListScanItemDetails item);

        /// <summary>
        /// Deletes a scan item
        /// </summary>
        void DeleteScanItem(int itemId);

        /// <summary>
        /// Compares a list against one or more scans
        /// </summary>
        /// <param name="listName">
        /// Name of the list against which to compare
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        ListCompareResult CompareListToScans(string listName);

        /// <summary>
        /// Returns true if a medium in the given case, besides the given medium,
        /// has been initially verified on an active receive list.  Useful in
        /// determining whether or not a medium marked as missing should be 
        /// removed from its case.
        /// </summary>
        /// <param name="caseName">
        /// Name of sealed case
        /// </param>
        /// <param name="serialNo">
        /// Serial number of medium to be ignored
        /// </param>
        bool SealedCaseVerified(string caseName, string serialNo) ;

        /// <summary>
        /// Removes a sealed case from the list
        /// </summary>
        /// <param name="rl">
        /// List detail object
        /// </param>
        /// <param name="caseName">
        /// Case to remove from list
        /// </param>
        void RemoveSealedCase(ReceiveListDetails rl, string caseName);

        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        EmailGroupCollection GetEmailGroups(RLStatus rl);

        /// <summary>
        /// Attaches an email group to a list status
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        void AttachEmailGroup(EmailGroupDetails e, RLStatus rl);

        /// <summary>
        /// Detaches an email group from a list status
        /// </summary>
        /// <param name="e">
        /// Email group to detach
        /// </param>
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        void DetachEmailGroup(EmailGroupDetails e, RLStatus rl);


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
        /// Gets the list alert days
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
