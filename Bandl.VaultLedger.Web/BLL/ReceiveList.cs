using System;
using System.Web;
using System.Text;
using System.Web.Mail;
using System.Threading;
using System.Collections;
using System.Collections.Generic;
using System.Security.Principal;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Xmitters;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage receive lists
    /// The Bandl.Library.VaultLedger.Model.ReceiveListDetails is used in most 
    /// methods and is used to store serializable information about a 
    /// receive list.
    /// </summary>
    public class ReceiveList
    {
        #region Status Methods
        public static RLStatus Statuses
        {
            get
            {
                return RLStatus.Submitted | ReceiveListFactory.Create().GetStatuses() | RLStatus.Processed;
                //if (HttpRuntime.Cache[CacheKeys.RLStatuses] != null)
                //{
                //    return (RLStatus)HttpRuntime.Cache[CacheKeys.RLStatuses];
                //}
                //else
                //{
                //    RLStatus rls =  RLStatus.Submitted | ReceiveListFactory.Create().GetStatuses() | RLStatus.Processed;
                //    CacheKeys.Insert(CacheKeys.RLStatuses, rls, TimeSpan.FromMinutes(5));
                //    return rls;
                //}
            }
        }

        private static void EvaluateTapeExistence(ReceiveListItemCollection rlic)
        {
            if (Preference.GetPreference(PreferenceKeys.CreateTapesAdminOnly).Value[0] == 'N')
            {
                // DO NOTHING
            }
            else if (CustomPermission.CurrentOperatorRole() == Role.Administrator)
            {
                // DO NOTHING
            }
            else
            {
                foreach (ReceiveListItemDetails r in rlic)
                    if (Medium.GetMedium(r.SerialNo) == null && SealedCase.GetSealedCase(r.SerialNo) == null)
                        throw new ApplicationException("Serial number " + r.SerialNo + " is not defined in the system");
            }
        }

        public static bool StatusEligible (RLStatus currentStatus, RLStatus desiredStatus)
        {
            foreach (RLStatus ds in Enum.GetValues(typeof(RLStatus)))
            {
                int x = (int)ds/2;
                // Skip the 'all values' value
                if (ds == RLStatus.AllValues) continue;
                // If ds is not in desired status, move to the next value
                if (0 == (ds & desiredStatus)) continue;
                // If we are not employing the desired status, move to the next value
                if (0 == (ds & Statuses)) continue;
                // If we are partially verified and desire to be fully verified, return true.  Also,
                // transmission is a special case; if status >= Transmitted but < Processed, let it go.
                // Otherwise, if the currentStatus is geq the desired status, go to the next value.
                if (currentStatus == RLStatus.PartiallyVerifiedI && ds == RLStatus.FullyVerifiedI)
                    return true;
                else if  (currentStatus == RLStatus.PartiallyVerifiedII && ds == RLStatus.FullyVerifiedII)
                    return true;
                else if (ds == RLStatus.Xmitted && currentStatus >= RLStatus.Xmitted && currentStatus < RLStatus.Processed)
                    return true;
                else if (currentStatus >= ds)
                    continue;
                // Run through the statuses
                while (x > 1)
                {
                    // Skip partial verification values
                    if (x == (int)RLStatus.PartiallyVerifiedI) x = x / 2;
                    if (x == (int)RLStatus.PartiallyVerifiedII) x = x / 2;
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

        public static bool StatusEligible (ReceiveListDetails rl, RLStatus desiredStatus)
        {
            return StatusEligible(rl.Status, desiredStatus);
        }
    
        public static bool StatusEligible (ReceiveListCollection rlc, RLStatus desiredStatus)
        {
            foreach (ReceiveListDetails rl in rlc)
                if (StatusEligible(rl.Status, desiredStatus))
                    return true;
            // None are eligible for the desired status
            return false;
        }

        public static bool StatusEligible (RLIStatus currentStatus, RLIStatus desiredStatus)
        {
            RLStatus rl = (RLStatus)Enum.ToObject(typeof(RLStatus),(int)currentStatus);
            RLStatus ds = (RLStatus)Enum.ToObject(typeof(RLStatus),(int)desiredStatus);
            return StatusEligible(rl, ds);
        }

        /// <summary>
        /// Updates the statuses used for receive lists
        /// </summary>
        public static void UpdateStatuses(RLStatus statuses)
        {
            // Only certain statuses apply here (e.g., Submitted and Processed are used by every list type, so not necessary here)
            RLStatus x = RLStatus.Arrived | RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII | RLStatus.Transit | RLStatus.Xmitted;
            // Make sure the parameter contains only valid values
            if (((int)statuses & (int)x) == 0)
                throw new ApplicationException("If not transmitting lists, at least one question per list type must be answered 'Yes'.");
            else
                ReceiveListFactory.Create().UpdateStatuses(statuses & x);  // Makes sure that only valid values are used
        }
        #endregion

        #region Get Methods
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
        public static ReceiveListDetails GetReceiveList(int id, bool getItems) 
        {
            return ReceiveListFactory.Create().GetReceiveList(id, getItems);
        }

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
        public static ReceiveListDetails GetReceiveList(string listName, bool getItems) 
        {
            return ReceiveListFactory.Create().GetReceiveList(listName, getItems);
        }

        /// <summary>
        /// Returns the information for a specific receive list
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of a medium
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the receive list</returns>
        public static ReceiveListDetails GetReceiveListByMedium(string serialNo, bool getItems) 
        {
            return ReceiveListFactory.Create().GetReceiveListByMedium(serialNo, getItems);
        }

        /// <summary>
        /// Gets the receive lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve receive lists</param>
        /// <returns>Collection of receive lists created on the given date</returns>
        public static ReceiveListCollection GetListsByDate(DateTime date)
        {
            return ReceiveListFactory.Create().GetListsByDate(date);
        }

		/// <summary>
		/// Gets the eligible list status(es) for the desired status
		/// </summary>
		/// <param name="desiredStatus">Desired Status for which to obtain eligible receive lists status(es)</param>
		/// <returns>Eligible status(es)</returns>
		public static RLStatus GetEligibleStatus (RLStatus desiredStatus)
		{
			// Status(es) to retrieve - they are eligible to change to the desiredStatus
			RLStatus eligibleStatus = 0;
             
			foreach (RLStatus status in Enum.GetValues(typeof(RLStatus)))
			{
				if (StatusEligible(status, desiredStatus) == true)
					eligibleStatus = (eligibleStatus | status);
			}
            
			return eligibleStatus;
		}

		/// <summary>
		/// Gets the receive lists for particular status(es) and date
		/// </summary>
		/// <param name="desiredStatus">Desired Status for which to retrieve receive lists that are eligible to change to</param>
		/// <param name="date">Date for which to retrieve receive lists</param>
		/// <returns>Collection of receive lists created on the given date in the eligible status(es)</returns>
		public static ReceiveListCollection GetListsByEligibleStatusAndDate(RLStatus desiredStatus,DateTime date)
		{
			// Status(es) to retrieve - they are eligible to change to the desiredStatus
			RLStatus eligibleStatus = 0;
			eligibleStatus = GetEligibleStatus(desiredStatus);

			return ReceiveListFactory.Create().GetListsByStatusAndDate(eligibleStatus,date);
		}

        /// <summary>
        /// Gets the history of the given list
        /// </summary>
        public static AuditTrailCollection GetHistory(string listname)
        {
            return ReceiveListFactory.Create().GetHistory(listname);
        }

        /// <summary>
        /// Gets the receive lists created before a particular date that have been
        /// cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of receive lists</returns>
        public static ReceiveListCollection GetCleared(DateTime date) 
        {
            return ReceiveListFactory.Create().GetCleared(date);
        }

        /// <summary>
        /// Returns a page of the contents of the ReceiveList table
        /// </summary>
        /// <returns>Returns a collection of receive lists in the given sort order</returns>
        public static ReceiveListCollection GetReceiveListPage(int pageNo, int pageSize, RLSorts sortColumn, out int totalLists) 
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
                return ReceiveListFactory.Create().GetReceiveListPage(pageNo, pageSize, sortColumn, out totalLists);
            }
        }

		/// <summary>
		/// Returns a page of the contents of the ReceiveList table
		/// </summary>
		/// <returns>Returns a collection of receive lists in the given sort order</returns>
		public static ReceiveListCollection GetReceiveListPage(int pageNo, int pageSize, RLSorts sortColumn, string filter, out int totalLists) 
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
				return ReceiveListFactory.Create().GetReceiveListPage(pageNo, pageSize, sortColumn, filter, out totalLists);
			}
		}

        /// <summary>
        /// Gets the active receive list entry of the given medium
        /// </summary>
        /// <param name="serialNo">
        /// Medium serial number
        /// </param>
        /// <returns>
        /// Send list item
        /// </returns>
        public static ReceiveListItemDetails GetReceiveListItem(string serialNo)
        {
            return ReceiveListFactory.Create().GetReceiveListItem(serialNo);
        }

        /// <summary>
        /// Gets the number of entries on the receive list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        public static int GetReceiveListItemCount(int listId)
        {
            return ReceiveListFactory.Create().GetReceiveListItemCount(listId);
        }

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
        public static int GetReceiveListItemCount(int listId, RLIStatus status)
        {
            return ReceiveListFactory.Create().GetReceiveListItemCount(listId, status);
        }

        /// <summary>
        /// Returns a page of the items of a receive list
        /// </summary>
        /// <returns>Returns a collection of receive list items in the given sort order</returns>
        public static ReceiveListItemCollection GetReceiveListItemPage(int listId, int pageNo, int pageSize, RLISorts sortColumn, out int totalItems) 
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
                return GetReceiveListItemPage(listId, pageNo, pageSize, RLIStatus.AllValues ^ RLIStatus.Removed, sortColumn, out totalItems);
            }
        }

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
        public static ReceiveListItemCollection GetReceiveListItemPage(int listId, int pageNo, int pageSize, RLIStatus itemStatus, RLISorts sortColumn, out int totalItems)
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
                return ReceiveListFactory.Create().GetReceiveListItemPage(listId, pageNo, pageSize, itemStatus, sortColumn, out totalItems);
            }
        }
        #endregion

        #region Create Methods
        public static ReceiveListDetails Create(ReceiveListItemCollection items)
        {
            return Create(items, true);
        }
        
        /// <summary>
        /// Creates a new receive list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>
        /// Receive list details object containing the created receive list
        /// </returns>
        public static ReceiveListDetails Create(ReceiveListItemCollection items, bool doEmail)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list item collection must contain at least one receive list item object.");
            }
            else
            {
                EvaluateTapeExistence(items);
            }
            // Check item statuses
            foreach (ReceiveListItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only receive list items marked as new may be used to create a receive list.  Receive list item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create the list
            ReceiveListDetails rl = ReceiveListFactory.Create().Create(items);
            // Send email
            if (doEmail == true)
                SendEmail(rl.Name, RLStatus.None, RLStatus.Submitted);
            // Return the list
            return rl;
        }

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
        public static ReceiveListDetails Create(DateTime receiveDate, String accounts)
        {
            CustomPermission.Demand(Role.Operator);
            ReceiveListDetails rl = ReceiveListFactory.Create().Create(receiveDate, accounts);
            // If no items, return null
            if (rl == null) return null;
            // Send email
            SendEmail(rl.Name, RLStatus.None, RLStatus.Submitted);
            // Return the list
            return rl;
        }
        #endregion
   
        /// <summary>
        /// Merges a collection of receive lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        public static ReceiveListDetails Merge(ReceiveListCollection listCollection) 
        {
            CustomPermission.Demand(Role.Operator);
            // Must have at least two lists in the collection
            if (listCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list collection object.");
            }
            else if (listCollection.Count < 2)
            {
                throw new ArgumentException("Receive list collection must contain at least two receive lists to faciliate merging.");
            }
            // Merge the lists
            return ReceiveListFactory.Create().Merge(listCollection);
        }

        /// <summary>
        /// Extracts a receive list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        public static void Extract(ReceiveListDetails compositeList, ReceiveListDetails discreteList) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify parameters
            if (compositeList == null)
            {
                throw new ArgumentNullException("Composite list reference must be set to an instance of a receive list.");
            }
            else if (discreteList == null)
            {
                throw new ArgumentNullException("Discrete list reference must be set to an instance of a receive list.");
            }
            else if (compositeList.IsComposite == false)
            {
                throw new ArgumentException("A discrete list was supplied where a composite list was expected.");
            }
            else if (discreteList.IsComposite == true)
            {
                throw new ArgumentException("A composite list was supplied where a discrete list was expected.");
            }
            // If the discrete list is verified to be one of the child lists of the composite,
            // then extract it.  Otherwise through an exception.
            if ((new ReceiveListCollection(compositeList.ChildLists)).Find(discreteList.Name) == null)
            {
                throw new BLLException("Given discrete list not found within the given composite list.");
            }
            else
            {
                using (IConnection c = ConnectionFactory.Create().Open())
                {
                    try
                    {
                        c.BeginTran("extract receive list");
                        IReceiveList dal = ReceiveListFactory.Create(c);
                        dal.Extract(compositeList, discreteList);
                        c.CommitTran();
                    }
                    catch
                    {
                        c.RollbackTran();
                        throw;
                    }
                }
            }
        }

        /// <summary>
        /// Dissolves a receive list from composite.  In other words, extracts all
        /// discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        public static void Dissolve(ReceiveListDetails compositeList) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have a composite list
            if (compositeList == null)
            {
                throw new ArgumentNullException("Receive list reference must be set to an instance of a receive list.");
            }
            else if (false == compositeList.IsComposite)
            {
                throw new ArgumentException("A composite list was supplied where a discrete list was expected.");
            }
            else
            {
                using (IConnection c = ConnectionFactory.Create().Open())
                {
                    try
                    {
                        c.BeginTran("extract receive list");
                        IReceiveList dal = ReceiveListFactory.Create(c);
                        dal.Dissolve(compositeList);
                        c.CommitTran();
                    }
                    catch
                    {
                        c.RollbackTran();
                        throw;
                    }
                }
            }
        }

        #region Transmission Methods
        private static IXmitter CreateXmitter()
        {
            return XmitterFactory.Create();
        }
        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="rl">
        /// Receive list to transmit
        /// </param>
        private static void Transmit(ReceiveListDetails rl, IXmitter x)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (x == null)
                throw new ApplicationException("Transmitter not instantiated.");
            else if (rl == null)
                throw new ArgumentNullException("Reference must be set to an instance of a receive list object.");
            else if (!StatusEligible(rl.Status, RLStatus.Xmitted))
                throw new ApplicationException("List " + rl.Name + " is not eligible for transmitting.");
            // Remember the old status for email alert
            RLStatus oStatus = rl.Status;
            // Create a collection to hold lists to be transmitted
            ReceiveListCollection listCollection = new ReceiveListCollection();
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
            if (rl.IsComposite == false)
            {
                // Refresh the list
                rl = ReceiveList.GetReceiveList(rl.Id, true);
                // Add to the collection
                listCollection.Add(rl);
            }
            else
            {
                // Get the child lists if we do not have them
                if (rl.ChildLists.Length == 0) rl = GetReceiveList(rl.Id, true);
                // Transmit each child list in turn
                foreach(ReceiveListDetails cl in rl.ChildLists)
                {
                    // Get the items on the child list
                    ReceiveListDetails r = ReceiveList.GetReceiveList(cl.Id, true);
                    // If the status of the composite is greater than or equal to
                    // transmitted, then transmit all lists regardless of status.
                    // Otherwise, only transmit those that have yet to be 
                    // transmitted.
                    if (rl.Status >= RLStatus.Xmitted)
                    {
                        listCollection.Add(r);
                    }
                    else if (r.Status < RLStatus.Xmitted)
                    {
                        listCollection.Add(r);
                    }
                }
            }
            // If we have no lists in the collection, we can return
            if (listCollection.Count == 0) return;
            // Keep count of failed lists
            int failedLists = 0;
            string exMessage = String.Empty;
            // Create a data layer object
            IReceiveList dal = ReceiveListFactory.Create();
            // Loop through the collection, transmitting lists
            foreach(ReceiveListDetails r in listCollection)
            {
                try
                {
                    x.Transmit(r);
                }
                catch (Exception ex)
                {
                    if (exMessage.Length == 0) exMessage = ex.Message;
                    failedLists += 1;
                    continue;
                }
                // Update the database
                dal.Transmit(r);
            }
            // If any lists failed throw the appropriate exception.
            if (failedLists != 0)
            {
                if (rl.IsComposite && failedLists != rl.ChildLists.Length)
                    throw new ApplicationException("List " + rl.Name + " transmission only partially successful: " + exMessage);
                else
                    throw new ApplicationException("List " + rl.Name + " transmission failed: " + exMessage);
            }
            // Send any email alert necessary
            SendEmail(rl.Name, oStatus, RLStatus.Xmitted);
        }
        /// <summary>
        /// Transmits a receive list collection
        /// </summary>
        /// <param name="receiveLists">
        /// Receive list collection to transmit
        /// </param>
        public static void Transmit(ReceiveListCollection rlc)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (rlc == null)
                throw new ArgumentNullException("Reference must be set to a collection of receive list objects.");
            // Because transmission isn't atomic (an early list may be transmitted,
            // only to find that a later list is not transmission-eligible), we want
            // to make sure up-front that everyone is eligible.
            foreach (ReceiveListDetails r in rlc)
                if (!StatusEligible(r.Status, RLStatus.Xmitted))
                    throw new ApplicationException("List " + r.Name + " is not currently eligible for transmission.");
            // Get a transmitter
            IXmitter x = CreateXmitter();
            // Now transmit each in turn
            foreach (ReceiveListDetails rl in rlc)
                Transmit(rl, x);
        }
        
        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="list">
        /// Receive list to transmit
        /// </param>
        public static void Transmit(ReceiveListDetails list) 
        {
            // Get a transmitter
            IXmitter x = CreateXmitter();
            // Transmit the list
            Transmit(list, x);
        }
        #endregion

        /// <summary>
        /// Marks a receive list as in transit
        /// </summary>
        /// <param name="rl">
        /// Receive list to mark
        /// </param>
        public static void MarkTransit(ReceiveListDetails rl)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have an untransmitted list
            if (rl == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list object.");
            }
            else if (!StatusEligible(rl.Status, RLStatus.Transit))
            {
                throw new ApplicationException("List " + rl.Name + " is not eligible to be marked as in transit.");
            }
            else
            {
                RLStatus oStatus = rl.Status;
                ReceiveListFactory.Create().MarkTransit(rl);
                SendEmail(rl.Name, oStatus, RLStatus.Transit);
            }
        }

        /// <summary>
        /// Marks a receive list as arrived
        /// </summary>
        /// <param name="rl">
        /// Receive list to mark
        /// </param>
        public static void MarkArrived(ReceiveListDetails rl)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have an untransmitted list
            if (rl == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list object.");
            }
            else if (!StatusEligible(rl.Status, RLStatus.Arrived))
            {
                throw new ApplicationException("List " + rl.Name + " is not eligible to be marked as arrived.");
            }
            else
            {
                RLStatus oStatus = rl.Status;
                ReceiveListFactory.Create().MarkArrived(rl);
                SendEmail(rl.Name, oStatus, RLStatus.Arrived);
            }
        }

        /// <summary>
        /// Deletes a given list from the system
        /// </summary>
        /// <param name="list">Receive list to delete</param>
        public static void Delete(ReceiveListDetails list)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have an untransmitted list
            if (list == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list object.");
            }
            else if (list.Status >= RLStatus.Xmitted)
            {
                throw new ApplicationException("A receive list may not be deleted once it has attained at least " + ListStatus.ToLower(RLStatus.Xmitted) + " status.");
            }
            else
            {
                ReceiveListFactory.Create().Delete(list);
            }
        }

        /// <summary>
        /// Verifies a set of receive lists.  This method iterates through
        /// the collection and verifies the items on each list.
        /// </summary>
        /// <param name="receiveLists">
        /// A collection receive lists to verify
        /// </param>
        public static void Verify(ReceiveListCollection receiveLists)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (receiveLists == null)
                throw new ArgumentNullException("Reference must be set to an instance of a receive list collection object.");
            // Create a data access layer
            IReceiveList dal = ReceiveListFactory.Create();
            // Make sure that each is verification-eligible
            foreach (ReceiveListDetails rl in receiveLists)
                if (!StatusEligible(dal.GetReceiveList(rl.Id, false), RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII))
                    throw new ArgumentException("List " + rl.Name + " is not currently eligible for verification.");
            // Verify the lists
            foreach (ReceiveListDetails rl in receiveLists)
            {
                ReceiveListItemCollection rlic = new ReceiveListItemCollection();
                // Get the items of the list
                ReceiveListDetails rx = ReceiveList.GetReceiveList(rl.Id, true);
                // Place all the list items in the collection
                if (rx.IsComposite == false)
                    rlic.Add(rx.ListItems);
                else
                    foreach (ReceiveListDetails rc in rx.ChildLists)
                        rlic.Add(rc.ListItems);
                // Verify the list
                Verify(rl.Name, ref rlic);
            }
        }

        /// <summary>
        /// Verifies a receive list
        /// </summary>
        /// <param name="receiveList">
        /// A receive list to verify
        /// </param>
        public static void Verify(ReceiveListDetails rl)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Create a collection
            ReceiveListCollection rlc = new ReceiveListCollection();
            rlc.Add(rl);
            // Hand to the collection overload
            try
            {
                Verify(rlc);
            }
            catch
            {
                if (rlc[0].RowError.Length != 0)
                    throw new ApplicationException(rlc[0].RowError);
                else
                    throw;
            }

        }

        /// <summary>
        /// Verifies a set of receive list items.  This method iterates through
        /// the collection and verifies each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the 
        /// error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection receive list items to verify
        /// </param>
        public static void Verify(int listId, ref ReceiveListItemCollection items)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Overload call
            Verify(GetReceiveList(listId, false).Name, ref items);
        }
        
        /// <summary>
        /// Verifies a set of receive list items.  This method iterates through
        /// the collection and verifies each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the 
        /// error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection receive list items to verify
        /// </param>
        public static void Verify(string listName, ref ReceiveListItemCollection items)
        {
            RLStatus actionStatus;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list item collection must contain at least one receive list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Obtain the receive list
            ReceiveListDetails rl = ReceiveList.GetReceiveList(listName, false);
            // Eligibility
            if (StatusEligible(rl, RLStatus.FullyVerifiedI))
            {
                actionStatus = RLStatus.FullyVerifiedI;
            }
            else if (StatusEligible(rl, RLStatus.FullyVerifiedII))
            {
                actionStatus = RLStatus.FullyVerifiedII;
            }
            else
            {
                throw new ArgumentException("List " + listName + " is not currently eligible for verification.");
            }
            // Get the current list status
            RLStatus oStatus = rl.Status;
            // Remove anybody from the collection with removed status
            for (int i = items.Count-1; i >= 0; i--)
                if (items[i].Status == RLIStatus.Removed)
                    items.RemoveAt(i);
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran("verify receive list item");
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Verify each item on the list
                foreach(ReceiveListItemDetails item in items)
                {
                    try
                    {
                        dal.VerifyItem(item);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    // Refresh the items in the collection
                    for (int i = 0; i < items.Count; i++)
                        items.Replace(items[i], dal.GetReceiveListItem(items[i].Id));
                }
            }
            // Send any email alert necessary
            SendEmail(listName, oStatus, actionStatus);
        }

        /// <summary>
        /// Removes a set of receive list items.  This method iterates through
        /// the collection and removes each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the 
        /// error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection receive list items to remove
        /// </param>
        public static void RemoveItems(string listName, ref ReceiveListItemCollection items) 
        {
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list item collection must contain at least one receive list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Get the status of the list
            RLStatus oStatus = ReceiveList.GetReceiveList(listName, false).Status;
            // Check status values
            foreach (ReceiveListItemDetails i in items)
                if (i.Status >= RLIStatus.Xmitted)
                    throw new ObjectStateException("A medium may not be removed from a receive list once it has attained at least " + ListStatus.ToLower(RLIStatus.Xmitted) + " status.");
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListItemDetails item in items)
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
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    ReceiveListItemDetails rli;
                    for (int i = 0; i < items.Count; i++)
                    {
                        // If the item no longer exists, then the list has been
                        // completely deleted; just set the status to removed.
                        // Otherwise replace the item with the current item in
                        // order to refresh the rowversion.
                        if ((rli = dal.GetReceiveListItem(items[i].Id)) != null)
                            items.Replace(items[i], rli);
                        else
                            items[i].ObjState = ObjectStates.Deleted;
                    }
                }
            }
            // Send an email alert if list still exists
            ReceiveListDetails rl = GetReceiveList(listName, false);
            if (rl != null) SendEmail(listName, oStatus, rl.Status);
        }

        /// <summary>
        /// Updates a set of receive list items.  This method iterates through
        /// the collection and updates each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the error.
        /// </summary>
        /// <param name="items">
        /// A collection of receive list items to update
        /// </param>
        /// <remarks>
        /// For a receive list item, only the Notes property can change
        /// </remarks>
        public static void UpdateItems(ref ReceiveListItemCollection items) 
        {
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list item collection must contain at least one receive list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check status and state
            foreach (ReceiveListItemDetails item in items)
            {
                if (item.Status >= RLIStatus.Xmitted)
                {
                    throw new ObjectStateException("Items on a receive list may not be altered once the list has attained at least " + ListStatus.ToLower(RLStatus.Xmitted) + " status.");
                }
                else if (item.ObjState != ObjectStates.Modified)
                {
                    throw new ObjectStateException("Only receive list items marked as modified may be updated.  Receive list item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
                }
            }
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListItemDetails item in items)
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
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    // Refresh the items in the collection
                    for (int i = 0; i < items.Count; i++)
                        items.Replace(items[i], dal.GetReceiveListItem(items[i].Id));
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
        /// Collection of ReceiveListItemDetails objects
        /// </param>
        public static void AddItems(ref ReceiveListDetails list, ref ReceiveListItemCollection items) 
        {
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (list == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list object.");
            }
            else if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list item collection must contain at least one receive list item object.");
            }
            else if (list.Status >= RLStatus.Xmitted)
            {
                throw new ObjectStateException("Items may not be added to a list once the list has attained " + ListStatus.ToLower(RLStatus.Xmitted) + " status or greater.");
            }
            // Reset the error flag
            items.HasErrors = false;
            list.RowError = String.Empty;
            // Check item states
            foreach (ReceiveListItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only receive list items marked as new may be added.  Receive list item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListItemDetails item in items)
                {
                    try
                    {
                        dal.AddItem(list, item);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    // Refetch the list.  Get items if it had them before
                    list = GetReceiveList(list.Id, list.ListItems.Length > 0);
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific receive list scan
        /// </summary>
        /// <param name="name">
        /// Unique identifier for a receive list
        /// </param>
        /// <returns>
        /// Returns the information for the receive list scan
        /// </returns>
        public static ReceiveListScanDetails GetScan(string name) 
        {
            return ReceiveListFactory.Create().GetScan(name);
        }

        /// <summary>
        /// Returns the information for a specific receive list scan
        /// </summary>
        /// <param name="id">Unique identifier for a receive list scan</param>
        /// <returns>Returns the information for the receive list scan</returns>
        public static ReceiveListScanDetails GetScan(int id) 
        {
            return ReceiveListFactory.Create().GetScan(id);
        }

        /// <summary>
        /// Gets the scans for a specified receive list
        /// </summary>
        /// <param name="listName">
        /// Name of the list
        /// </param>
        /// <returns>
        /// Collection of scans
        /// </returns>
        public static ReceiveListScanCollection GetScansForList(string listName)
        {
            IReceiveList dal = ReceiveListFactory.Create();
            ReceiveListDetails r = dal.GetReceiveList(listName, false);
            return dal.GetScansForList(listName, StatusEligible(r.Status, RLStatus.FullyVerifiedI) ? 1 : 2);
        }

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
        public static ReceiveListScanDetails CreateScan(string listName, string scanName, ref ReceiveListScanItemCollection items)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (listName == null || listName == String.Empty)
            {
                throw new ArgumentException("List name not supplied.");
            }
            else if (scanName == null || scanName == String.Empty)
            {
                throw new ArgumentException("Compare file name not supplied.");
            }
            else if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list compare file item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list compare file item collection must contain at least one receive list compare file item object.");
            }
            else if (!StatusEligible(ReceiveListFactory.Create().GetReceiveList(listName, false), RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII))
            {
                throw new ArgumentException("List " + listName + " is not currently eligible for verification.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check object states
            foreach (ReceiveListScanItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only compare file items marked as new may be used to create a compare file.  Compare file item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Loop through the items until a scan is created, then add the rest of the items
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Create the receive list scan object
                ReceiveListScanDetails createScan = null;
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListScanItemDetails item in items)
                {
                    try
                    {
                        if (createScan == null)
                        {
                            createScan = dal.CreateScan(listName, scanName, item);
                            item.RowError = String.Empty;
                        }
                        else
                        {
                            dal.AddScanItem(createScan.Id, item);
                            item.RowError = String.Empty;
                        }
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    // Return the scan
                    return GetScan(createScan.Id);
                }
            }
        }

        /// <summary>
        /// Creates a receive list scan
        /// </summary>
        /// <param name="listName">
        /// List to which to attach the scan
        /// </param>
        /// <param name="scanName">
        /// Name to assign to the scan
        /// </param>
        /// <param name="fileText">
        /// HtmlInputStream copied to a byte array
        /// </param>
        /// <returns>
        /// Created receive list scan
        /// </returns>
        public static ReceiveListScanDetails CreateScan(string listName, string scanName, byte[] fileText)
        {
            string[] serials;
            string[] caseNames;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (listName == null || listName == String.Empty)
            {
                throw new ArgumentException("List name not supplied.");
            }
            else if (scanName == null || scanName == String.Empty)
            {
                throw new ArgumentException("Compare file name not supplied.");
            }
            else if (fileText == null || fileText.Length == 0)
            {
                throw new ArgumentException("File contains no content.");
            }
            else if (!StatusEligible(ReceiveListFactory.Create().GetReceiveList(listName, false), RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII))
            {
                throw new ArgumentException("List " + listName + " is not currently eligible for verification.");
            }
            // Create the parser
            IParserObject parser = Parser.GetParser(ParserTypes.Movement, fileText);
            if (parser == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            parser.Parse(fileText, out serials, out caseNames);
            if(serials == null || serials.Length == 0) 
                throw new BLLException("Text from file did not contain any receive list items.");
            // Create a new scan list item collection and populate it
            ReceiveListScanItemCollection scanItems = new ReceiveListScanItemCollection();
            foreach (string serialNo in serials) 
                scanItems.Add(new ReceiveListScanItemDetails(serialNo));
            // Create the scan.  If a collection exception was thrown, repackage as a BLL exception
            // since the collection is not accessible to the caller.
            try
            {
                return CreateScan(listName, scanName, ref scanItems);
            }
            catch (CollectionErrorException)
            {
                foreach (ReceiveListScanItemDetails r in scanItems)
                    if (r.RowError != String.Empty)
                        throw new BLLException(r.RowError);
            }
            // Different exception was thrown
            return null;
        }

        /// <summary>
        /// Deletes a set of receive list scans
        /// </summary>
        /// <returns>Created receive list scan</returns>
        public static void DeleteScans(ref ReceiveListScanCollection scans) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (scans == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list compare file collection object.");
            }
            else if (scans.Count == 0)
            {
                throw new ArgumentException("Receive list compare file collection must contain at least one receive list compare file object.");
            }
            // Reset the error flag
            scans.HasErrors = false;
            // Check scan statuses
            foreach (ReceiveListScanDetails scan in scans)
                if (scan.ObjState != ObjectStates.Unmodified)
                    throw new ObjectStateException("Only compare files marked as unmodified may be deleted.  Compare file '" + scan.Name + "' is " + scan.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListScanDetails scan in scans)
                {
                    try
                    {
                        dal.DeleteScan(scan);
                        scan.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        scan.RowError = e.Message;
                        scans.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (scans.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(scans);
                }
                else
                {
                    c.CommitTran();
                    // Alter the object states
                    foreach(ReceiveListScanDetails scan in scans)
                        scan.ObjState = ObjectStates.Deleted;
                }
            }
        }

        /// <summary>
        /// Adds a set of items to a scan
        /// </summary>
        /// <returns>Scan to which items were added</returns>
        public static void AddScanItems(ref ReceiveListScanDetails scan, ref ReceiveListScanItemCollection items)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (scan == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list compare file object.");
            }
            else if (scan.LastCompared != String.Empty)
            {
                throw new ArgumentNullException("A compare file may not be altered once it has been compared against its list.");
            }
            else if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list compare file item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list compare file item collection must contain at least one receive list compare file item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            scan.RowError = String.Empty;
            // Check item statuses
            foreach (ReceiveListScanItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only compare file items marked as new may be added.  Compare file item '" + item.SerialNo + "' is " + scan.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListScanItemDetails item in items)
                {
                    try
                    {
                        dal.AddScanItem(scan.Id, item);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    // Refresh the scan
                    scan = GetScan(scan.Id);
                }
            }
        }

        /// <summary>
        /// Deletes a set of scan items
        /// </summary>
        public static void DeleteScanItems(ref ReceiveListScanItemCollection items) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a receive list compare file item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Receive list compare file item collection must contain at least one receive list compare file item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check item statuses
            foreach (ReceiveListScanItemDetails item in items)
                if (item.ObjState != ObjectStates.Unmodified)
                    throw new ObjectStateException("Only compare file items marked as unmodified may be deleted.  Compare file item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Remove each item from the list
                foreach(ReceiveListScanItemDetails item in items)
                {
                    try
                    {
                        dal.DeleteScanItem(item.Id);
                        item.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        item.RowError = e.Message;
                        items.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (items.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(items);
                }
                else
                {
                    c.CommitTran();
                    // Alter the object states
                    foreach(ReceiveListScanItemDetails item in items)
                    {
                        item.ObjState = ObjectStates.Deleted;
                    }
                }
            }
        }
        /// <summary>
        /// Compares a list against one or more scans
        /// </summary>
        /// <param name="listId">
        /// Id of the list against which to compare
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        public static ListCompareResult CompareListToScans(int listId) 
        {
            return CompareListToScans(GetReceiveList(listId, false).Name);
        }
        /// <summary>
        /// Compares a list against one or more scans
        /// </summary>
        /// <param name="listName">
        /// Name of the list against which to compare
        /// </param>
        /// <param name="scans">
        /// One or more scans to compare against the list
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        public static ListCompareResult CompareListToScans(string listName) 
        {
            ListCompareResult lcr = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have a list name
            if (listName == null || listName == String.Empty)
            {
                throw new ArgumentException("List name not supplied.");
            }
            else if (listName.Substring(0,3) != "RE-")
            {
                throw new ArgumentException("List name supplied is not a valid receive list name.");
            }
            // Get the list
            ReceiveListDetails rl = ReceiveList.GetReceiveList(listName, false);
            // Record the current status of the list
            RLStatus oStatus = rl.Status;
            RLStatus actionStatus = RLStatus.None;
            // Check the eligibility
            if (StatusEligible(rl.Status, RLStatus.FullyVerifiedI))
            {
                actionStatus = RLStatus.FullyVerifiedI;
            }
            else if (StatusEligible(rl.Status, RLStatus.FullyVerifiedII))
            {
                actionStatus = RLStatus.FullyVerifiedII;
            }
            else
            {
                throw new ArgumentException("List is not currently verification-eligible.");
            }
            // Create a connection to enforce a transaction
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Create the data access layer object
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Begin a transaction
                c.BeginTran("compare list to scan");
                // Dissolve the composite list
                try
                {
                    lcr = dal.CompareListToScans(listName);
                    c.CommitTran();
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
            // Send email alerts
            SendEmail(listName, oStatus, actionStatus);
            // return the result
            return lcr;
        }

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
        public static bool SealedCaseVerified(string caseName, string serialNo)
        {
            return ReceiveListFactory.Create().SealedCaseVerified(caseName, serialNo);
        }

        /// <summary>
        /// Removes a sealed case from the list
        /// </summary>
        /// <param name="rl">
        /// List detail object
        /// </param>
        /// <param name="caseName">
        /// Case to remove from list
        /// </param>
        public static void RemoveSealedCases(ReceiveListDetails rl, string[] caseNames)
        {
            // Create a connection to enforce a transaction
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Create the data access layer object
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Begin a transaction
                c.BeginTran("remove case from list");
                // Dissolve the composite list
                try
                {
                    foreach (string caseName in caseNames)
                    {
                        dal.RemoveSealedCase(rl, caseName);
                        rl = GetReceiveList(rl.Id, false);
                    }
                    // Commit
                    c.CommitTran();
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
        }

        /// <summary>
        /// Sends email status alert if list is at or beyond any of the given statuses and 
        /// statuses require email alerts to be sent.
        /// </summary>
        /// <param name="rl"></param>
        /// <param name="rls"></param>
        /// <returns></returns>
        public static void SendEmail(string listName, RLStatus oStatus, RLStatus actionStatus)
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
            ReceiveListCollection c = ReceiveList.GetReceiveListPage(1, 32767, RLSorts.ListName, out x);
            // Get any active lists past due
            foreach (ReceiveListDetails rl in c)
                if (rl.Status != RLStatus.Processed)
                    if (rl.CreateDate < d)
                        listNames.Add(rl.Name);
            // Send the email
            new Email(Thread.CurrentPrincipal, WindowsIdentity.GetCurrent()).SendOverdueAlert(listNames);
        }


        #region Email Group Methods
        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        public static EmailGroupCollection GetEmailGroups(RLStatus rl)
        {
            return ReceiveListFactory.Create().GetEmailGroups(rl);
        }

        /// <summary>
        /// Gets the email groups for list alert
        /// </summary>
        /// <returns>
        /// Email group collection
        /// </returns>
        public static EmailGroupCollection GetEmailGroups()
        {
            return ReceiveListFactory.Create().GetEmailGroups();
        }

        /// <summary>
        /// Gets the list alert days
        /// </summary>
        /// <returns></returns>
        public static int GetListAlertDays()
        {
            return ReceiveListFactory.Create().GetListAlertDays();
        }

        /// <summary>
        /// Gets the time of the last list alert
        /// </summary>
        /// <returns></returns>
        public static DateTime GetListAlertTime()
        {
            return ReceiveListFactory.Create().GetListAlertTime();
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
            ReceiveListFactory.Create().UpdateAlertDays(days);
        }

        /// Updates the alert time
        /// </summary>
        /// <param name="d">
        /// Time to update
        /// </param>
        public static void UpdateAlertTime(DateTime d)        
        {
            ReceiveListFactory.Create().UpdateAlertTime(d);
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
        /// <param name="rl">
        /// List status to which to attach and detach
        /// </param>
        public static void ManipulateEmailGroups(EmailGroupCollection x, EmailGroupCollection y, RLStatus rl)
        {
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran("attach email group");
                // Initialize a data access layer object with the connection
                IReceiveList dal = ReceiveListFactory.Create(c);
                // Attach email groups
                foreach(EmailGroupDetails e in x)
                {
                    try
                    {
                        dal.AttachEmailGroup(e, rl);
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
                        dal.DetachEmailGroup(e, rl);
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
                IReceiveList dal = ReceiveListFactory.Create(c);
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
            private delegate void EmailDelegate (string listName, RLStatus oStatus, RLStatus actionStatus);
            private delegate void OverdueDelegate (List<String> listNames);
            private WindowsImpersonationContext wic;
            private WindowsIdentity wi;
            private IPrincipal p;

            public Email(IPrincipal _p, WindowsIdentity _wi) {p = _p; wi = _wi;}

            public void Send(string listName, RLStatus oStatus, RLStatus actionStatus)
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
                    Mailer.SendOverdueListAlert(ListTypes.Receive, listNames.ToArray(), String.Join(";", r.ToArray()));
                }
                catch
                {
                    ;
                }
            }

            private void DoSend(string listName, RLStatus oStatus, RLStatus actionStatus)
            {
                try
                {
                    // Set the identity and principal
                    Thread.CurrentPrincipal = p;
                    if (wi != null) wic = wi.Impersonate();
                    // Get the list from the database.  If the status is equal to the
                    // old status, just return true.
                    ReceiveListDetails rl = GetReceiveList(listName, false);
                    if (rl == null || (rl.Status != actionStatus && rl.Status != RLStatus.Processed)) return;
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
                        case RLStatus.Submitted:
                            actionVerb = "created";
                            break;
                        case RLStatus.Arrived:
                            actionVerb = "marked as arrived";
                            break;
                        case RLStatus.Transit:
                            actionVerb = "marked as in transit";
                            break;
                        case RLStatus.Processed:
                            break;
                        default:
                            actionVerb = ListStatus.ToLower(actionStatus);
                            break;
                    }
                    // If also processed, add and remove from groups as appropriate
                    if (rl.Status == RLStatus.Processed)
                    {
                        foreach (EmailGroupDetails e in GetEmailGroups(rl.Status))
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
                    // Get the list items from the database so that we can add the tapes to the emails
                    rl = GetReceiveList(listName, true);
                    // Create a collection for active items and one for removed items
                    ReceiveListItemCollection ai = new ReceiveListItemCollection();
                    ReceiveListItemCollection ri = new ReceiveListItemCollection();
                    // Get all the items into a collection
                    if (false == rl.IsComposite)
                    {
                        foreach (ReceiveListItemDetails rli in rl.ListItems)
                        {
                            if (rli.Status != RLIStatus.Removed)
                                ai.Add(rli);
                            else
                                ri.Add(rli);
                        }
                    }
                    else
                    {
                        foreach (ReceiveListDetails r1 in rl.ChildLists)
                        {
                            foreach (ReceiveListItemDetails rli in r1.ListItems)
                            {
                                if (rli.Status != RLIStatus.Removed)
                                    ai.Add(rli);
                                else
                                    ri.Add(rli);
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
                        b.AppendFormat("Receiving list {0} has been {1}.{2}{2}{2}", listName, v.ToUpper(), Environment.NewLine);
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
