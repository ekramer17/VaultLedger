using System;
using System.Web;
using System.Text;
using System.Web.Mail;
using System.Threading;
using System.Collections;
using System.Security.Principal;
using System.Collections.Generic;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Xmitters;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage disaster code lists
    /// The Bandl.Library.VaultLedger.Model.DisasterCodeListDetails is used in most 
    /// methods and is used to store serializable information about a 
    /// disaster code list.
    /// </summary>
    public class DisasterCodeList
    {
        public static DLStatus Statuses
        {
            get
            {
                return DLStatus.Submitted | DisasterCodeListFactory.Create().GetStatuses() | DLStatus.Processed;
                //if (HttpRuntime.Cache[CacheKeys.DLStatuses] != null)
                //{
                //    return (DLStatus)HttpRuntime.Cache[CacheKeys.DLStatuses];
                //}
                //else
                //{
                //    DLStatus dls = DLStatus.Submitted | DisasterCodeListFactory.Create().GetStatuses() | DLStatus.Processed;
                //    CacheKeys.Insert(CacheKeys.DLStatuses, dls, TimeSpan.FromMinutes(5));
                //    return dls;
                //}
            }
        }

        public static bool StatusEligible (DLStatus currentStatus, DLStatus desiredStatus)
        {
            foreach (DLStatus ds in Enum.GetValues(typeof(DLStatus)))
            {
                int x = (int)ds/2;
                // Skip the 'all values' value
                if (ds == DLStatus.AllValues) continue;
                // If ds is not in desired status, move to the next value
                if (0 == (ds & desiredStatus)) continue;
                // If we are not employing the desired status, move to the next value
                if (0 == (ds & Statuses)) continue;
                // If we are partially verified and desire to be fully verified, return true.  Also,
                // transmission is a special case; if status >= Transmitted but < Processed, let it go.
                // Otherwise, if the currentStatus is geq the desired status, go to the next value.
                if (ds == DLStatus.Xmitted && currentStatus >= DLStatus.Xmitted)
                    return true;
                else if (currentStatus >= ds)
                    continue;
                // Run through the statuses
                while (x > 1)
                {
                    // If x is now equal to the current status value, return true
                    if (x <= (int)currentStatus) return true;
                    // If the x status is used, break
                    if ((x & (int)Statuses) != 0) break;
                    // Go down one status value
                    x = x / 2;
                }
            }
            // Current status not eligible for any of the desired statuses
            return false;
        }

        public static bool StatusEligible (DisasterCodeListDetails dl, DLStatus desiredStatus)
        {
            return StatusEligible(dl.Status, desiredStatus);
        }
    
        public static bool StatusEligible (DisasterCodeListCollection dlc, DLStatus desiredStatus)
        {
            foreach (DisasterCodeListDetails dl in dlc)
                if (StatusEligible(dl.Status, desiredStatus))
                    return true;
            // None are eligible for the desired status
            return false;
        }

        /// <summary>
        /// Updates the statuses used for disaster code lists
        /// </summary>
        public static void UpdateStatuses(DLStatus statuses)
        {
            // Only transmitteed status applies here (unlike Send and Receive, a middle status is not necessary)
            statuses = ((int)statuses & (int)DLStatus.Xmitted) != 0 ? DLStatus.Xmitted : DLStatus.None;
            // Update the statuses
            DisasterCodeListFactory.Create().UpdateStatuses(statuses);
        }

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
        public static DisasterCodeListDetails GetDisasterCodeList(int id, bool getItems) 
        {
            if (id <= 0)
            {
                throw new ArgumentException("Disaster code list id must be greater than zero.");
            }
            else
            {
                return DisasterCodeListFactory.Create().GetDisasterCodeList(id, getItems);
            }
        }

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
        public static DisasterCodeListDetails GetDisasterCodeList(string listName, bool getItems) 
        {
            if(listName == null)
            {
                throw new ArgumentNullException("Name of list may not be null.");
            }
            else if (listName == String.Empty)
            {
                throw new ArgumentException("Name of list may not be an empty string.");
            }
            else
            {
                return DisasterCodeListFactory.Create().GetDisasterCodeList(listName, getItems);
            }
        }

        /// <summary>
        /// Returns a page of the contents of the DisasterCodeList table
        /// </summary>
        /// <returns>Returns a collection of disaster code lists in the given sort order</returns>
        public static DisasterCodeListCollection GetDisasterCodeListPage(int pageNo, int pageSize, DLSorts sortColumn, out int totalLists) 
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
                return DisasterCodeListFactory.Create().GetDisasterCodeListPage(pageNo, pageSize, sortColumn, out totalLists);
            }
        }

        /// <summary>
        /// Returns a page of the items of a disaster code list
        /// </summary>
        /// <returns>Returns a collection of disaster code items in the given sort order</returns>
        public static DisasterCodeListItemCollection GetDisasterCodeListItemPage(int listId, int pageNo, int pageSize, DLISorts sortColumn, out int totalItems) 
        {
            return GetDisasterCodeListItemPage(listId, pageNo, pageSize, DLIStatus.AllValues ^ DLIStatus.Removed, sortColumn, out totalItems);
        }

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
        public static DisasterCodeListItemCollection GetDisasterCodeListItemPage(int listId, int pageNo, int pageSize, DLIStatus itemStatus, DLISorts sortColumn, out int totalItems)
        {
            if (listId <= 0)
            {
                throw new ArgumentException("List id number must be greater than zero.");
            }
            else if (pageNo <= 0)
            {
                throw new ArgumentException("Page number must be greater than zero.");
            }
            else if (pageSize <= 0)
            {
                throw new ArgumentException("Page size must be greater than zero.");
            }
            else
            {
                return DisasterCodeListFactory.Create().GetDisasterCodeListItemPage(listId, pageNo, pageSize, itemStatus, sortColumn, out totalItems);
            }
        }
            
        /// <summary>
        /// Gets the disaster code lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve disaster code lists</param>
        /// <returns>Collection of disaster code lists created on the given date</returns>
        public static DisasterCodeListCollection GetListsByDate(DateTime date)
        {
            return DisasterCodeListFactory.Create().GetListsByDate(date);
        }

        /// <summary>
        /// Gets the disaster code lists created before a particular date that
        /// have been cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of disaster code lists</returns>
        public static DisasterCodeListCollection GetCleared(DateTime date) 
        {
            return DisasterCodeListFactory.Create().GetCleared(date);
        }

        /// <summary>
        /// Creates a new disaster code list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>
        /// Disaster code list details object containing the created disaster code list
        /// </returns>
        public static DisasterCodeListDetails Create(DisasterCodeListItemCollection items)
        {
            return Create(items, true);
        }
        
        /// <summary>
        /// Creates a new disaster code list from an HtmlInputFile byte array
        /// </summary>
        /// <param name="fileText">
        /// Text from HtmlInputFile in a byte array
        /// </param>
        /// <returns>List details object containing the created list</returns>
        public static DisasterCodeListDetails Create(byte[] fileText)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have a byte array
            if (fileText == null)
            {
                throw new ArgumentNullException("File text byte array may not be null.");
            }
            else if (fileText.Length == 0)
            {
                throw new ArgumentException("File contains no content.");
            }
            // Declare item collection
            DisasterCodeListItemCollection dlic = null;
            // Create the parser
            IParserObject p = Parser.GetParser(ParserTypes.Disaster, fileText);
            if (p == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report and reate the list
            try
            {
                // Parse the report
                p.Parse(fileText, out dlic);
                // Create the list
                return Create(dlic);
            }
            catch (CollectionErrorException)
            {
                foreach (DisasterCodeListItemDetails r in dlic)
                    if (r.RowError != String.Empty)
                        throw new BLLException(r.RowError);
                // This will never be reached, since at least one row will have error text
                return null;
            }
        }

        /// <summary>
        /// Creates a new disaster code list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>
        /// Disaster code list details object containing the created disaster code list
        /// </returns>
        public static DisasterCodeListDetails Create(DisasterCodeListItemCollection dlic, bool doEmail)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (dlic == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list item collection object.");
            }
            else if (dlic.Count == 0)
            {
                throw new ArgumentException("Disaster code list item collection must contain at least one disaster code list item object.");
            }
            // Check object states
            foreach (DisasterCodeListItemDetails i in dlic)
                if (i.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only disaster code list items marked as new may be used to create a disaster code list.  Disaster code list item '" + i.SerialNo + "' is " + i.ObjState.ToString().ToLower());
            // Create a connection with which to create the list
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran();
                    // Create data layer objects
                    IDisasterCodeList dal = DisasterCodeListFactory.Create(c);
                    // Create the list from the item collection
                    DisasterCodeListDetails dl = dal.Create(dlic);
                    // If no transmission, we should clear the list
                    if ((Statuses & DLStatus.Xmitted) == 0) dal.Clear(dl);
                    // Send email
                    if (doEmail) SendEmail(dl.Name, DLStatus.None, DLStatus.Submitted);
                    // Commit transaction
                    c.CommitTran();
                    // Return the list
                    return dl;
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
        }

        /// <summary>
        /// Merges a collection of disaster code lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        public static DisasterCodeListDetails Merge(DisasterCodeListCollection listCollection) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have at least two lists in the collection
            if (listCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list collection object.");
            }
            else if (listCollection.Count < 2)
            {
                throw new ArgumentException("Disaster code list collection must contain at least two disaster code lists to faciliate merging.");
            }
            // Run through the list collection, making sure all lists are of requisite status values
            foreach (DisasterCodeListDetails dl in listCollection)
                if (dl.Status >= DLStatus.Xmitted)
                    throw new ApplicationException("A disaster recovery list may not be merged once it has attained at least " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            // Merge the lists
            return DisasterCodeListFactory.Create().Merge(listCollection);
        }

        /// <summary>
        /// Extracts a disaster code list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        public static void Extract(DisasterCodeListDetails compositeList, DisasterCodeListDetails discreteList) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify parameters
            if (compositeList == null)
            {
                throw new ArgumentNullException("Composite list reference must be set to an instance of a disaster code list.");
            }
            else if (discreteList == null)
            {
                throw new ArgumentNullException("Discrete list reference must be set to an instance of a disaster code list.");
            }
            else if (compositeList.IsComposite == false)
            {
                throw new ArgumentException("A discrete list was supplied where a composite list was expected.");
            }
            else if (discreteList.IsComposite == true)
            {
                throw new ArgumentException("A composite list was supplied where a discrete list was expected.");
            }
            else if ((new DisasterCodeListCollection(compositeList.ChildLists)).Find(discreteList.Name) == null)
            {
                throw new BLLException("Given discrete list not found within the given composite list.");
            }
            // Check status values
            if (compositeList.Status >= DLStatus.Xmitted)
                throw new ApplicationException("A disaster recovery list may not be extracted once it has attained at least " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            // Extract the list
            DisasterCodeListFactory.Create().Extract(compositeList, discreteList);
        }

        /// <summary>
        /// Dissolves a disaster code list from composite.  In other words, 
        /// extracts all discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        public static void Dissolve(DisasterCodeListDetails compositeList) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have a composit list
            if (compositeList == null)
            {
                throw new ArgumentNullException("Disaster code list reference must be set to an instance of a disaster code list.");
            }
            else if (false == compositeList.IsComposite)
            {
                throw new ArgumentException("A composite list was supplied where a discrete list was expected.");
            }
            // Check status values
            if (compositeList.Status >= DLStatus.Xmitted)
                throw new ApplicationException("A disaster recovery list may not be dissolved once it has attained at least " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            // Dissolve the list
            DisasterCodeListFactory.Create().Dissolve(compositeList);
        }


        #region Transmission Methods
        private static IXmitter CreateXmitter()
        {
            return XmitterFactory.Create();
        }
        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="dl">
        /// Disaster code list to transmit
        /// </param>
        private static void Transmit(DisasterCodeListDetails dl, IXmitter x)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (x == null)
                throw new ApplicationException("Transmitter not instantiated.");
            else if (dl == null)
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list object.");
            // Remember the old status for email alert
            DLStatus oStatus = dl.Status;
            // Create a collection to hold lists to be transmitted
            DisasterCodeListCollection listCollection = new DisasterCodeListCollection();
            // If the list is a composite, we should transmit a discrete
            // and then mark that discrete as transmitted in the database.
            // Repeat until no more discretes.  This method represents the
            // smallest chance for a list to be transmitted and not marked
            // as such in the database.  Because it may be possible that the
            // composite was interrupted before being completely transmitted,
            // we should check to see if all discretes have been transmitted.
            // If so, then add all the discretes to the collection.  If not, 
            // only those lists not yet transmitted should be added.  If the 
            // list is not a composite, then none of the above applies.
            if (dl.IsComposite == false)
            {
                listCollection.Add(dl);
            }
            else
            {
                // Get the child lists if we do not have them
                if (dl.ChildLists.Length == 0) dl = GetDisasterCodeList(dl.Id, true);
                // Transmit each child list in turn
                foreach(DisasterCodeListDetails cl in dl.ChildLists)
                {
                    // Get the items on the child list
                    DisasterCodeListDetails d = DisasterCodeList.GetDisasterCodeList(cl.Id, true);
                    // If the status of the composite is greater than or equal to
                    // transmitted, then transmit all lists regardless of status.
                    // Otherwise, only transmit those that have yet to be 
                    // transmitted.
                    if (dl.Status >= DLStatus.Xmitted)
                    {
                        listCollection.Add(d);
                    }
                    else if (d.Status == DLStatus.Submitted)
                    {
                        listCollection.Add(d);
                    }
                }
            }
            // If we have no lists in the collection, we can return
            if (listCollection.Count == 0) return;
            // Keep count of failed lists
            int failedLists = 0;
            string exMessage = String.Empty;
            // Create a data layer object
            IDisasterCodeList dal = DisasterCodeListFactory.Create();
            // Loop through the collection, transmitting lists
            foreach(DisasterCodeListDetails d in listCollection)
            {
                try
                {
                    x.Transmit(d);
                }
                catch (Exception ex)
                {
                    if (exMessage.Length == 0) exMessage = ex.Message;
                    failedLists += 1;
                    continue;
                }
                // Update the database
                dal.Transmit(d);
            }
            // If no lists failed, then clear.  Otherwise throw exception.
            if (failedLists != 0)
            {
                if (dl.IsComposite && failedLists != dl.ChildLists.Length)
                    throw new ApplicationException("List " + dl.Name + " transmission only partially successful: " + exMessage);
                else
                    throw new ApplicationException("List " + dl.Name + " transmission failed: " + exMessage);
            }
            // Send any email alert necessary
            SendEmail(dl.Name, oStatus, DLStatus.Xmitted);
        }
        /// <summary>
        /// Transmits a disaster code list collection
        /// </summary>
        /// <param name="list">Disaster code list collection to transmit</param>
        public static void Transmit(DisasterCodeListCollection disasterLists) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (disasterLists == null)
                throw new ArgumentNullException("Reference must be set to a collection of disaster code list objects.");
            // Get a transmitter for the batch
            IXmitter x = CreateXmitter();
            // Transmit each in turn
            foreach (DisasterCodeListDetails d in disasterLists)
                Transmit(d, x);
        }
        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="list">Disaster code list to transmit</param>
        public static void Transmit(DisasterCodeListDetails dl) 
        {
            Transmit(dl, CreateXmitter());
        }
        #endregion

        /// <summary>
        /// Deletes a given list from the system
        /// </summary>
        /// <param name="list">Disaster code list to delete</param>
        public static void Delete(DisasterCodeListDetails list)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have a list that has not yet been transmitted
            if (list == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list object.");
            }
            else if (list.Status >= DLStatus.Xmitted)
            {
                throw new ApplicationException("A disaster receovery list may not be deleted once it has attained " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            }
            else
            {
                DisasterCodeListFactory.Create().Delete(list);
            }
        }

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
        public static int GetDisasterCodeListItemCount(int listId, DLIStatus status)
        {
            return DisasterCodeListFactory.Create().GetDisasterCodeListItemCount(listId, status);
        }

        /// <summary>
        /// Removes a set of disaster code list items.  This method iterates 
        /// through the collection and removes each item.  If an error occurs
        /// on any item, the transaction is rolled back and the HasErrors 
        /// property of the collection is set to true.  Each item that resulted
        /// in error will have its RowError property set with a description of
        /// the error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection disaster code list items to remove
        /// </param>
        public static void RemoveItems(string listName, ref DisasterCodeListItemCollection items) 
        {
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Must have a list object that contains untransmitted items
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Disaster code list item collection must contain at least one disaster code list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check items
            foreach (DisasterCodeListItemDetails item in items)
                if (item.Status >= DLIStatus.Xmitted)
                    throw new ApplicationException("A disaster receovery list may not be altered once it has attained " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            // Get the status of the list
            DLStatus oStatus = DisasterCodeList.GetDisasterCodeList(listName, false).Status;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IDisasterCodeList dal = DisasterCodeListFactory.Create(c);
                // Remove each item from the list
                foreach(DisasterCodeListItemDetails item in items)
                {
                    try
                    {
                        dal.RemoveItem(item);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction and refresh the items in the collection.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    DisasterCodeListItemDetails d;
                    for (int i = 0; i < items.Count; i++)
                    {
                        // If the item no longer exists, then the list has been
                        // completely deleted; just set the status to removed.
                        // Otherwise replace the item with the current item in
                        // order to refresh the rowversion.
                        if ((d = dal.GetDisasterCodeListItem(items[i].Id)) != null)
                            items.Replace(items[i], d);
                        else
                            items[i].ObjState = ObjectStates.Deleted;
                    }
                }
            }
            // Send an email alert if list still exists
            DisasterCodeListDetails dl = GetDisasterCodeList(listName, false);
            if (dl != null) SendEmail(listName, oStatus, dl.Status);
        }

        /// <summary>
        /// Updates a set of disaster code list items.  This method iterates 
        /// through the collection and updates each item.  If an error occurs
        /// on any item, the transaction is rolled back and the HasErrors 
        /// property of the collection is set to true.  Each item that resulted
        /// in error will have its RowError property set with a description of 
        /// the error.
        /// </summary>
        /// <param name="items">
        /// A collection of disaster code list items to update
        /// </param>
        public static void UpdateItems(ref DisasterCodeListItemCollection items) 
        {
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Must have a list object that contains untransmitted items
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Disaster code list item collection must contain at least one disaster code list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Item status
            foreach (DisasterCodeListItemDetails item in items)
                if (item.Status >= DLIStatus.Xmitted)
                    throw new ApplicationException("A disaster receovery list may not be altered once it has attained " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IDisasterCodeList dal = DisasterCodeListFactory.Create(c);
                // Remove each item from the list
                foreach(DisasterCodeListItemDetails item in items)
                {
                    try
                    {
                        dal.UpdateItem(item);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction and refresh the items in the collection.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    for (int i = 0; i < items.Count; i++)
                        items.Replace(items[i], dal.GetDisasterCodeListItem(items[i].Id));
                }
            }
        }

        /// <summary>
        /// Adds all items in the collection to a given list.  This method 
        /// iterates through the collection and adds each item.  If an error
        /// occurs on any item, the transaction is rolled back and the 
        /// HasErrors property of the collection is set to true.  Each item 
        /// that resulted in error will have its RowError property set with 
        /// a description of the error.
        /// </summary>
        /// <param name="list">
        /// List to which items should be added.  Upon success, this list
        /// is refetched.
        /// </param>
        /// <param name="items">
        /// Collection of DisasterCodeListItemDetails objects
        /// </param>
        public static void AddItems(ref DisasterCodeListDetails list, ref DisasterCodeListItemCollection items) 
        {
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Must have a list object that has not yet been transmitted
            if (list == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list object.");
            }
            else if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a disaster code list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Disaster code list item collection must contain at least one disaster code list item object.");
            }
            else if (list.Status >= DLStatus.Xmitted)
            {
                throw new ApplicationException("A disaster receovery list may not be altered once it has attained " + ListStatus.ToLower(DLStatus.Xmitted) + " status.");
            }
            // Reset the error flag
            items.HasErrors = false;
            list.RowError = String.Empty;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IDisasterCodeList dal = DisasterCodeListFactory.Create(c);
                // Remove each item from the list
                foreach(DisasterCodeListItemDetails item in items)
                {
                    try
                    {
                        dal.AddItem(list.Name, item);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Commit the transaction if no errors.  Otherwise
                // roll it back and throw a collection exception.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    list = GetDisasterCodeList(list.Id, true);
                }
            }
        }

        /// <summary>
        /// Sends email status alert if list is at or beyond any of the given statuses and 
        /// statuses require email alerts to be sent.
        /// </summary>
        /// <param name="dl"></param>
        /// <param name="dls"></param>
        /// <returns></returns>
        public static void SendEmail(string listName, DLStatus oStatus, DLStatus actionStatus)
        {
            new Email(Thread.CurrentPrincipal, WindowsIdentity.GetCurrent()).Send(listName, oStatus, actionStatus);
        }

        /// <summary>
        /// Sends email alert for lists that are overdue for processing
        /// </summary>
        public static void SendOverdueAlert()
        {
            int x = -1;
            int lad = GetListAlertDays();
            List<String> listNames = new List<String>();
            // If not issuing alerts, just return
            if (lad == 0) return;
            // Get the date against which to compare
            DateTime d = DateTime.UtcNow.AddDays(-(lad - 1));
            d = new DateTime(d.Year, d.Month, d.Day);   // Remove time portion
            // Get all the lists from the database
            DisasterCodeListCollection c = DisasterCodeList.GetDisasterCodeListPage(1, 32767, DLSorts.ListName, out x);
            // Get any active lists past due
            foreach (DisasterCodeListDetails dl in c)
                if (dl.Status != DLStatus.Processed)
                    if (dl.CreateDate < d)
                        listNames.Add(dl.Name);
            // Send the email
            new Email(Thread.CurrentPrincipal, WindowsIdentity.GetCurrent()).SendOverdueAlert(listNames);
        }

        #region Email Group Methods
        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="dl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        public static EmailGroupCollection GetEmailGroups(DLStatus dl)
        {
            return DisasterCodeListFactory.Create().GetEmailGroups(dl);
        }

        /// <summary>
        /// Gets the email groups for list alert
        /// </summary>
        /// <returns>
        /// Email group collection
        /// </returns>
        public static EmailGroupCollection GetEmailGroups()
        {
            return DisasterCodeListFactory.Create().GetEmailGroups();
        }

        /// <summary>
        /// Gets the list alert days
        /// </summary>
        /// <returns></returns>
        public static int GetListAlertDays()
        {
            return DisasterCodeListFactory.Create().GetListAlertDays();
        }

        /// <summary>
        /// Gets the time of the last list alert
        /// </summary>
        /// <returns></returns>
        public static DateTime GetListAlertTime()
        {
            return DisasterCodeListFactory.Create().GetListAlertTime();
        }

        /// <summary>
        /// Updates the alert days
        /// </summary>
        /// <param name="listTypes">
        /// Type of list
        /// </param>
        /// <param name="days">
        /// Days for alert
        /// </param>
        public static void UpdateAlertDays(int days)
        {
            DisasterCodeListFactory.Create().UpdateAlertDays(days);
        }

        /// Updates the alert time
        /// </summary>
        /// <param name="d">
        /// Time to update
        /// </param>
        public static void UpdateAlertTime(DateTime d)        
        {
            DisasterCodeListFactory.Create().UpdateAlertTime(d);
        }

        /// <summary>
        /// Attaches an email group to a list status
        /// </summary>
        /// <param name="x">
        /// Email group to attach
        /// </param>
        /// <param name="y">
        /// Email group to detach
        /// </param>
        /// <param name="dl">
        /// List status to which to attach and detach
        /// </param>
        public static void ManipulateEmailGroups(EmailGroupCollection x, EmailGroupCollection y, DLStatus dl)
        {
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran("attach email group");
                // Initialize a data access layer object with the connection
                IDisasterCodeList dal = DisasterCodeListFactory.Create(c);
                // Attach email groups
                foreach(EmailGroupDetails e in x)
                {
                    try
                    {
                        dal.AttachEmailGroup(e, dl);
                        e.RowError = String.Empty;
                    }
                    catch (Exception ex)
                    {
                        e.RowError = ex.Message;
                        x.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred
                if (x.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(x);
                }
                // Detach email groups
                foreach (EmailGroupDetails e in y)
                {
                    try
                    {
                        dal.DetachEmailGroup(e, dl);
                        e.RowError = String.Empty;
                    }
                    catch (Exception ex)
                    {
                        e.RowError = ex.Message;
                        y.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred
                if (y.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(y);
                }
                // Commit the transaction
                c.CommitTran();
            }
        }

        /// <summary>
        /// Attaches an email group to a list alert
        /// </summary>
        /// <param name="x">
        /// Email group to attach
        /// </param>
        /// <param name="y">
        /// Email group to detach
        /// </param>
        public static void ManipulateEmailGroups(EmailGroupCollection x, EmailGroupCollection y)
        {
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran("attach email group");
                // Initialize a data access layer object with the connection
                IDisasterCodeList dal = DisasterCodeListFactory.Create(c);
                // Attach email groups
                foreach(EmailGroupDetails e in x)
                {
                    try
                    {
                        dal.AttachEmailGroup(e);
                        e.RowError = String.Empty;
                    }
                    catch (Exception ex)
                    {
                        e.RowError = ex.Message;
                        x.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred
                if (x.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(x);
                }
                // Detach email groups
                foreach (EmailGroupDetails e in y)
                {
                    try
                    {
                        dal.DetachEmailGroup(e);
                        e.RowError = String.Empty;
                    }
                    catch (Exception ex)
                    {
                        e.RowError = ex.Message;
                        y.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred
                if (y.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(y);
                }
                // Commit the transaction
                c.CommitTran();
            }
        }
        #endregion

        #region Email Class
        private class Email
        {
            private delegate void EmailDelegate (string listName, DLStatus oStatus, DLStatus actionStatus);
            private delegate void OverdueDelegate(List<String> listNames);
            private WindowsImpersonationContext wic;
            private WindowsIdentity wi;
            private IPrincipal p;

            public Email(IPrincipal _p, WindowsIdentity _wi) {p = _p; wi = _wi;}

            public void Send(string listName, DLStatus oStatus, DLStatus actionStatus)
            {
                new EmailDelegate(DoSend).BeginInvoke(listName, oStatus, actionStatus, null, null);
            }


            public void SendOverdueAlert(List<String> listNames)
            {
                new OverdueDelegate(DoAlert).BeginInvoke(listNames, null, null);
            }

            private void DoAlert(List<String> listNames)
            {
                try
                {
                    List<String> r = new List<String>();  // recipients
                    // If nothing, just return
                    if (listNames == null || listNames.Count == 0) return;
                    // Get the operators in the group
                    foreach (EmailGroupDetails e in SendList.GetEmailGroups())
                        foreach (OperatorDetails o in EmailGroup.GetOperators(e))
                            if (o.Email.Length != 0 && !r.Contains(o.Email))
                                r.Add(o.Email);
                    // Send email
                    Mailer.SendOverdueListAlert(ListTypes.DisasterCode, listNames.ToArray(), String.Join(";", r.ToArray()));
                }
                catch
                {
                    ;
                }
                finally
                {
                    if (wic != null) wic.Undo();
                }
            }

            private void DoSend(string listName, DLStatus oStatus, DLStatus actionStatus)
            {
                try
                {
                    // Set the identity and principal
                    Thread.CurrentPrincipal = p;
                    if (wi != null) wic = wi.Impersonate();
                    // Get the list from the database.  If the status is equal to the
                    // old status, just return true.
                    DisasterCodeListDetails dl = GetDisasterCodeList(listName, false);
                    if (dl == null || (dl.Status != actionStatus && dl.Status != DLStatus.Processed)) return;
                    // Initialize
                    string actionVerb = String.Empty;
                    ArrayList recipients1 = new ArrayList();   // action status only
                    ArrayList recipients2 = new ArrayList();   // processed status only
                    ArrayList recipients3 = new ArrayList();   // action status and processed status
                    // Get the operators in the group
                    foreach (EmailGroupDetails e in GetEmailGroups(actionStatus))
                        foreach (OperatorDetails o in EmailGroup.GetOperators(e))
                            if (o.Email.Length != 0 && !recipients1.Contains(o.Email))
                                recipients1.Add(o.Email);
                    // Get the approriate verb
                    switch (actionStatus)
                    {
                        case DLStatus.Submitted:
                            actionVerb = "created";
                            break;
                        case DLStatus.Processed:
                            break;
                        default:
                            actionVerb = ListStatus.ToLower(actionStatus);
                            break;
                    }
                    // If also processed, add and remove from groups as appropriate
                    if (dl.Status == DLStatus.Processed)
                    {
                        foreach (EmailGroupDetails e in GetEmailGroups(dl.Status))
                        {
                            foreach (OperatorDetails o in EmailGroup.GetOperators(e))
                            {
                                if (o.Email.Length != 0)
                                {
                                    if (recipients1.Contains(o.Email))
                                    {
                                        recipients3.Add(o.Email);
                                        recipients1.Remove(o.Email);
                                    }
                                    else
                                    {
                                        recipients2.Add(o.Email);
                                    }
                                }
                            }
                        }
                    }
                    // Get the list items from the database
                    dl = GetDisasterCodeList(listName, true);
                    // Create a collection for active items and one for removed items
                    DisasterCodeListItemCollection ai = new DisasterCodeListItemCollection();
                    DisasterCodeListItemCollection ri = new DisasterCodeListItemCollection();
                    // Get all the items into a collection
                    if (false == dl.IsComposite)
                    {
                        foreach (DisasterCodeListItemDetails dli in dl.ListItems)
                        {
                            if (dli.Status != DLIStatus.Removed)
                                ai.Add(dli);
                            else
                                ri.Add(dli);
                        }
                    }
                    else
                    {
                        foreach (DisasterCodeListDetails d1 in dl.ChildLists)
                        {
                            foreach (DisasterCodeListItemDetails dli in d1.ListItems)
                            {
                                if (dli.Status != DLIStatus.Removed)
                                    ai.Add(dli);
                                else
                                    ri.Add(dli);
                            }
                        }
                    }
                    // Create strings to hold the tapes on the list
                    StringBuilder m1 = new StringBuilder();
                    StringBuilder m2 = new StringBuilder();
                    // Build the active medium list strings
                    for (int i = 0; i < ai.Count; i += 1)
                    {
                        m1.AppendFormat("{0}{1}", i % 5 != 0 ? "\t" : Environment.NewLine, ai[i].SerialNo);
                    }
                    // Build the removed medium list strings
                    for (int i = 0; i < ri.Count; i += 1)
                    {
                        m2.AppendFormat("{0}{1}", i % 5 != 0 ? "\t" : Environment.NewLine, ri[i].SerialNo);
                    }
                    // Send the emails
                    for (int i = 1; i < 4; i++)
                    {
                        ArrayList x = null;
                        string v = null;
                        // Get the recipient list and verb based on iteration
                        switch (i)
                        {
                            case 1:
                                x = recipients1;
                                v = actionVerb;
                                break;
                            case 2:
                                x = recipients2;
                                v = "processed";
                                break;
                            case 3:
                                x = recipients3;
                                v = actionVerb + " and processed";
                                break;
                        }
                        // If no recipients, move on
                        if (x.Count == 0) continue;
                        // Create the string body
                        StringBuilder b = new StringBuilder();
                        b.AppendFormat("This is a list status email alert from {0}.{1}{1}", Configurator.ProductName, Environment.NewLine);
                        b.AppendFormat("Disaster recovery list {0} has been {1}.{2}{2}{2}", listName, v.ToUpper(), Environment.NewLine);
                        b.AppendFormat("The media currently on this list are:{0}{1}", Environment.NewLine, m1.ToString());
                        if (m2.Length != 0) b.AppendFormat("{0}{0}The media that have been removed from this list are:{0}{1}", Environment.NewLine, m2.ToString());
                        // Send the email
                        EmailServer.SendEmail((string[])x.ToArray(typeof(string)), b.ToString());
                    }
                }
                catch
                {
                    ;
                }
                finally
                {
                    if (wic != null) wic.Undo();
                }
            }
        }
        #endregion
    }
}
