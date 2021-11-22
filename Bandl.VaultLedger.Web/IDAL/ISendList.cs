using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Inteface for the Send List DAL
	/// </summary>
	public interface ISendList
	{
        /// <summary>
        /// Gets the employed send list statuses from the database
        /// </summary>
        /// <returns>
        /// Send list statuses used
        /// </returns>
        SLStatus GetStatuses();

        /// <summary>
        /// Updates the statuses used for send lists
        /// </summary>
        void UpdateStatuses(SLStatus statuses);

        /// <summary>
        /// Returns the information for a specific send list
        /// </summary>
        /// <param name="id">Unique identifier for a send list</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        SendListDetails GetSendList(int id, bool getItems);

        /// <summary>
        /// Returns the information for a specific send list
        /// </summary>
        /// <param name="name">Unique identifier for a send list</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        SendListDetails GetSendList(string listName, bool getItems);

        /// <summary>
        /// Returns the information for a specific send list on which the given item resides
        /// </summary>
        /// <param name="itemId">Id number for the given item</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        SendListDetails GetSendListByItem(int itemId, bool getItems);
            
        /// <summary>
        /// Returns the information for a specific send list on which the given item resides
        /// </summary>
        /// <param name="itemId">Unique identifier for a send list</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        SendListDetails GetSendListByMedium(string serialNo, bool getItems);
        
        /// <summary>
        /// Gets the send lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve send lists</param>
        /// <returns>Collection of send lists created on the given date</returns>
        SendListCollection GetListsByDate(DateTime date);

		/// <summary>
		/// Gets the send lists in the status(es)
		/// </summary>
		/// <param name="status">Status(es) to retrieve send lists</param>
		/// <param name="date">Date for which to retrieve send lists</param>
		/// <returns>Collection of send lists in the eligible status(es)</returns>
		SendListCollection GetListsByStatusAndDate (SLStatus status, DateTime date);

        /// <summary>
        /// Gets the send lists created before a particular date that have been
        /// cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of send lists</returns>
        SendListCollection GetCleared(DateTime date);

        /// <summary>
        /// Gets the histotry of the given list
        /// </summary>
        AuditTrailCollection GetHistory(string listname);

        /// <summary>
        /// Returns a page of the contents of the SendList table
        /// </summary>
        /// <returns>Returns a collection of send lists in the given sort order</returns>
        SendListCollection GetSendListPage(int pageNo, int pageSize, SLSorts sortColumn, out int totalLists);

		/// <summary>
		/// Returns a page of the contents of the SendList table
		/// </summary>
		/// <returns>Returns a collection of send lists in the given sort order</returns>
		SendListCollection GetSendListPage(int pageNo, int pageSize, SLSorts sortColumn, string filter, out int totalLists);

        /// <summary>
        /// Gets the number of entries on the send list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        int GetSendListItemCount(int listId);

        /// <summary>
        /// Gets the number of entries on the send list with the given id
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
        int GetSendListItemCount(int listId, SLIStatus status);

        /// <summary>
        /// Returns a page of the items of a send list
        /// </summary>
        /// <returns>Returns a collection of send list items in the given sort order</returns>
        SendListItemCollection GetSendListItemPage(int listId, int pageNo, int pageSize, SLISorts sortColumn, out int totalItems);

        /// <summary>
        /// Returns a page of the items of a send list
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
        /// Returns a collection of send list items in the given sort order
        /// </returns>
        SendListItemCollection GetSendListItemPage(int listId, int pageNo, int pageSize, SLIStatus itemStatus, SLISorts sortColumn, out int totalItems);

        /// <summary>
        /// Returns the information for a specific send list item
        /// </summary>
        /// <param name="itemId">
        /// Id number of the send list item
        /// </param>
        /// <returns>
        /// Send list item
        /// </returns>
        SendListItemDetails GetSendListItem(int itemId);
            
		/// <summary>
        /// Returns the information for a specific send list item
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of a medium on a send list
        /// </param>
        /// <returns>
        /// Send list item
        /// </returns>
        SendListItemDetails GetSendListItem(string serialNo);

        /// <summary>
        /// Returns the information for a specific send list case
        /// </summary>
        /// <param name="id">Unique identifier for a send list case</param>
        /// <returns>Returns the information for the send list case</returns>
        SendListCaseDetails GetSendListCase(int id);
            
        /// <summary>
        /// Returns the information for a specific send list case
        /// </summary>
        /// <param name="caseName">Name of a send list case</param>
        /// <returns>Returns the information for the send list case</returns>
        SendListCaseDetails GetSendListCase(string caseName);
            
        /// <summary>
        /// Gets a listing of the cases for a send list
        /// </summary>
        /// <param name="listId">
        /// Id of the list for which to get cases
        /// </param>
        SendListCaseCollection GetSendListCases(int listId);

        /// <summary>
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="items">Items that will appear on the list(s)</param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        SendListDetails Create(SendListItemCollection items, SLIStatus initialStatus);

        /// <summary>
        /// Gets all of the media in a case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case
        /// </param>
        /// <returns>
        /// Collection of the media in the case
        /// </returns>
        MediumCollection GetCaseMedia(string caseName);

		/// <summary>
		/// Determines if the case is sealed
		/// </summary>
		/// <param name="caseName">
		/// Name of the case
		/// </param>
		/// <returns>
		/// Boolean indicating whether or not the case is sealed
		/// </returns>
		bool IsCaseSealed(string caseName);

        /// <summary>
        /// Merges a collection of send lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        SendListDetails Merge(SendListCollection listCollection);

        /// <summary>
        /// Extracts a send list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        void Extract(SendListDetails compositeList, SendListDetails discreteList);

        /// <summary>
        /// Dissolves a send list from composite.  In other words, extracts all
        /// discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        void Dissolve(SendListDetails compositeList);

        /// <summary>
        /// Transmits a send list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        /// <param name="clear">Whether or not to clear the list after a successful transmit</param>
        void Transmit(SendListDetails list, bool clear);

        /// <summary>
        /// Transmits a send list collection
        /// </summary>
        /// <param name="listCollection">Send list collection to transmit</param>
        /// <param name="clear">Whether or not to clear the lists after a successful transmit</param>
        void Transmit(SendListCollection listCollection, bool clear);

        /// <summary>
        /// Marks a list as in transit
        /// </summary>
        /// <param name="sl">
        /// Receive list
        /// </param>
        void MarkTransit(SendListDetails sl);
            
        /// <summary>
        /// Marks a list as arrived
        /// </summary>
        /// <param name="sl">
        /// Receive list
        /// </param>
        void MarkArrived(SendListDetails sl);

        /// <summary>
        /// Clears a send list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        void Clear(SendListDetails list);

        /// <summary>
        /// Deletes a send list
        /// </summary>
        /// <param name="list">Send list to delete</param>
        void Delete(SendListDetails list);

        /// <summary>
        /// Verifies a send list item
        /// </summary>
        /// <param name="item">
        /// A send list item to verify
        /// </param>
        void VerifyItem(SendListItemDetails item);

        /// <summary>
        /// Removes a send list item
        /// </summary>
        /// <param name="item">
        /// A send list item to remove
        /// </param>
        void RemoveItem(SendListItemDetails item);

        /// <summary>
        /// Updates a send list item
        /// </summary>
        /// <param name="item">
        /// A send list item to update
        /// </param>
        void UpdateItem(SendListItemDetails item);

        /// <summary>
        /// Adds a send list item to an existing list
        /// </summary>
        /// <param name="list">
        /// List to which items should be added
        /// </param>
        /// <param name="item">
        /// Send list item object to add
        /// </param>
        /// <param name="initialStatus">
        /// Items may be added as unverified or verified
        /// </param>
        void AddItem(SendListDetails list, SendListItemDetails item, SLIStatus initialStatus);

        /// <summary>
        /// Removes item from case
        /// </summary>
        /// <param name="itemId">
        /// Id number of send list item object
        /// </param>
        /// <param name="caseId">
        /// Id number of send list case object
        /// </param>
        void RemoveItemFromCase(int itemId, int caseId);
            
        /// <summary>
        /// Updates a send list case
        /// </summary>
        /// <param name="item">
        /// A send list case to update
        /// </param>
        void UpdateCase(SendListCaseDetails sendCase);

        /// <summary>
        /// Deletes a send list case
        /// </summary>
        /// <param name="item">
        /// A send list case to delete
        /// </param>
        void DeleteCase(SendListCaseDetails sendCase);

        /// <summary>
        /// Returns the information for a specific send list scan
        /// </summary>
        /// <param name="id">Unique identifier for a send list scan</param>
        /// <returns>Returns the information for the send list scan</returns>
        SendListScanDetails GetScan(int id);

        /// <summary>
        /// Returns the information for a specific send list scan
        /// </summary>
        /// <param name="name">Unique identifier for a send list scan</param>
        /// <returns>Returns the information for the send list scan</returns>
        SendListScanDetails GetScan(string name);

        /// <summary>
        /// Returns all the scans for a particular list
        /// </summary>
        /// <param name="listName">Name of the list</param>
        /// <returns>Returns the information for the scans</returns>
        SendListScanCollection GetScansForList(string listName, int stage);

        /// <summary>
        /// Returns the information for a specific send list scan item
        /// </summary>
        /// <param name="id">
        /// Id of the item
        /// </param>
        /// <returns>
        /// Send list scan item object
        /// </returns>
        SendListScanItemDetails GetScanItem(int id);

		/// <summary>
		/// Returns the case name for a specific send list scan item
		/// </summary>
		/// <param name="listid">
		/// Id of the list
		/// </param>
		/// <param name="serial">
		/// Serial number
		/// </param>
		/// <returns>
		/// Case name
		/// </returns>
		string GetScanItemCase(int listid, string serial);
			
		/// <summary>
        /// Creates a send list scan
        /// </summary>
        /// <returns>Created send list scan</returns>
        SendListScanDetails CreateScan(string listName, string scanName, SendListScanItemDetails item);

        /// <summary>
        /// Deletes a send list scan
        /// </summary>
        void DeleteScan(SendListScanDetails scan);

        /// <summary>
        /// Adds an item to a scan
        /// </summary>
        void AddScanItem(int scanId, SendListScanItemDetails item);

        /// <summary>
        /// Deletes a set of scan items
        /// </summary>
        void DeleteScanItem(int itemId);

        /// <summary>
        /// Compares a list against one or more scans
        /// </summary>
        /// <param name="listName">
        /// Name of the list against which to compare
        /// </param>
        /// <param name="scans">
        /// Scans to compare against the list
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        SendListCompareResult CompareListToScans(string listName);

        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        EmailGroupCollection GetEmailGroups(SLStatus sl);

        /// <summary>
        /// Attaches an email group to a list status
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        void AttachEmailGroup(EmailGroupDetails e, SLStatus sl);

        /// <summary>
        /// Detaches an email group from a list status
        /// </summary>
        /// <param name="e">
        /// Email group to detach
        /// </param>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        void DetachEmailGroup(EmailGroupDetails e, SLStatus sl);

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

        /// <summary>
        /// Gets the send list cases for the browse page
        /// </summary>
        /// <returns>
        /// A send list case collection
        /// </returns>
        SendListCaseCollection GetSendListCases();
    }
}
