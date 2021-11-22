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
    /// A business component used to manage send lists
    /// The Bandl.Library.VaultLedger.Model.SendListDetails is used in most 
    /// methods and is used to store serializable information about a send list
    /// </summary>
    public class SendList
    {
        #region Status Methods
        public static SLStatus Statuses
        {
            get
            {
                return SLStatus.Submitted | SendListFactory.Create().GetStatuses() | SLStatus.Processed;
                //if (HttpRuntime.Cache[CacheKeys.SLStatuses] != null)
                //{
                //    return (SLStatus)HttpRuntime.Cache[CacheKeys.SLStatuses];
                //}
                //else
                //{
                //    SLStatus sls = SLStatus.Submitted | SendListFactory.Create().GetStatuses() | SLStatus.Processed;
                //    CacheKeys.Insert(CacheKeys.SLStatuses, sls, TimeSpan.FromMinutes(5));
                //    return sls;
                //}
            }
        }

        public static bool StatusEligible (SLStatus currentStatus, SLStatus desiredStatus)
        {
            foreach (SLStatus ds in Enum.GetValues(typeof(SLStatus)))
            {
                int x = (int)ds/2;
                // Skip the 'all values' value
                if (ds == SLStatus.AllValues) continue;
                // If ds is not in desired status, move to the next value
                if (0 == (ds & desiredStatus)) continue;
                // If we are not employing the desired status, move to the next value
                if (0 == (ds & Statuses)) continue;
                // If we are partially verified and desire to be fully verified, return true.  Also,
                // transmission is a special case; if status >= Transmitted but < Processed, let it go.
                // Otherwise, if the currentStatus is geq the desired status, go to the next value.
                if ((currentStatus == SLStatus.PartiallyVerifiedI) && ds == SLStatus.FullyVerifiedI)
                    return true;
                else if  (currentStatus == SLStatus.PartiallyVerifiedII && ds == SLStatus.FullyVerifiedII)
                    return true;
                else if (ds == SLStatus.Xmitted && currentStatus >= SLStatus.Xmitted && currentStatus < SLStatus.Processed)
                    return true;
                else if (currentStatus >= ds)
                    continue;
                // Run through the statuses
                while (x > 1)
                {
                    // Skip partial verification values
                    if (x == (int)SLStatus.PartiallyVerifiedI) x = x / 2;
                    if (x == (int)SLStatus.PartiallyVerifiedII) x = x / 2;
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

        public static bool StatusEligible (SendListDetails sl, SLStatus desiredStatus)
        {
            return StatusEligible(sl.Status, desiredStatus);
        }
    
        public static bool StatusEligible (SendListCollection slc, SLStatus desiredStatus)
        {
            foreach (SendListDetails sl in slc)
                if (StatusEligible(sl.Status, desiredStatus))
                    return true;
            // None are eligible for the desired status
            return false;
        }

        public static bool StatusEligible (SLIStatus currentStatus, SLIStatus desiredStatus)
        {
            int x = (int)currentStatus, y = (int)desiredStatus;
            return StatusEligible((SLStatus)Enum.ToObject(typeof(SLStatus),x), (SLStatus)Enum.ToObject(typeof(SLStatus),y));
        }

        /// <summary>
        /// Updates the statuses used for send lists
        /// </summary>
        public static void UpdateStatuses(SLStatus statuses)
        {
            // Only certain statuses apply here (e.g., Submitted and Processed are used by every list type, so not necessary here)
            SLStatus x = SLStatus.Arrived | SLStatus.FullyVerifiedI | SLStatus.FullyVerifiedII | SLStatus.Transit | SLStatus.Xmitted;
            // Make sure the parameter contains only valid values
            if (((int)statuses & (int)x) == 0)
                throw new ApplicationException("If not transmitting lists, at least one question per list type must be answered 'Yes'.");
            else
                SendListFactory.Create().UpdateStatuses(statuses & x);  // Makes sure that only valid values are used
        }

        #endregion

        #region Get Methods
        /// <summary>
        /// Returns the information for a specific send list
        /// </summary>
        /// <param name="name">Unique identifier for a send list</param>
        /// <param name="getDetails">
        /// Whether or not the user would like the items and cases of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public static SendListDetails GetSendList(string name, bool getItems) 
        {
            return SendListFactory.Create().GetSendList(name, getItems);
        }

        /// <summary>
        /// Returns the information for a specific send list
        /// </summary>
        /// <param name="id">Unique identifier for a send list</param>
        /// <param name="getDetails">
        /// Whether or not the user would like the items and cases of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public static SendListDetails GetSendList(int id, bool getItems) 
        {
            return SendListFactory.Create().GetSendList(id, getItems);
        }

        /// <summary>
        /// Returns the information for a specific send list on which the given item resides
        /// </summary>
        /// <param name="itemId">Unique identifier for a send list</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public static SendListDetails GetSendListByMedium(string serialNo, bool getItems)
        {
            return SendListFactory.Create().GetSendListByMedium(serialNo, getItems);
        }

        /// <summary>
        /// Gets the send lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve send lists</param>
        /// <returns>Collection of send lists created on the given date</returns>
        public static SendListCollection GetListsByDate(DateTime date) 
        {
            return SendListFactory.Create().GetListsByDate(date);
        }

		/// <summary>
		/// Gets the eligible list status(es) for the desired status
		/// </summary>
		/// <param name="desiredStatus">Desired Status for which to obtain eligible send lists status(es)</param>
		/// <returns>Eligible status(es)</returns>
		public static SLStatus GetEligibleStatus (SLStatus desiredStatus)
		{
			// Status(es) to retrieve - they are eligible to change to the desiredStatus
			SLStatus eligibleStatus = 0;
             
			foreach (SLStatus status in Enum.GetValues(typeof(SLStatus)))
			{
				if (StatusEligible(status, desiredStatus) == true)
					eligibleStatus = (eligibleStatus | status);
			}
            
			return eligibleStatus;
		}

		/// <summary>
		/// Gets the send lists that are eligible to change to the desired status
		/// </summary>
		/// <param name="desiredStatus">Desired Status for which to retrieve send lists that are eligible to change to</param>
		/// <param name="date">Date for which to retrieve send lists</param>
		/// <returns>Collection of send lists eligible to change to the desired status</returns>
		public static SendListCollection GetListsByEligibleStatusAndDate (SLStatus desiredStatus,DateTime date)
		{
			// Status(es) to retrieve - they are eligible to change to the desiredStatus
			SLStatus eligibleStatus = 0;
            eligibleStatus = GetEligibleStatus(desiredStatus);

			return SendListFactory.Create().GetListsByStatusAndDate(eligibleStatus,date);
		}

        /// <summary>
        /// Gets the history of the given list
        /// </summary>
        public static AuditTrailCollection GetHistory(string listname)
        {
            return SendListFactory.Create().GetHistory(listname);
        }

        /// <summary>
        /// Gets the send lists created before a particular date that have been
        /// cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of send lists</returns>
        public static SendListCollection GetCleared(DateTime date) 
        {
            return SendListFactory.Create().GetCleared(date);
        }

        /// <summary>
        /// Returns a page of the contents of the SendList table
        /// </summary>
        /// <returns>Returns a collection of send lists in the given sort order</returns>
        public static SendListCollection GetSendListPage(int pageNo, int pageSize, SLSorts sortColumn, out int totalLists) 
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
				return SendListFactory.Create().GetSendListPage(pageNo, pageSize, sortColumn, out totalLists);
			}
		}

		/// <summary>
		/// Returns a page of the contents of the SendList table
		/// </summary>
		/// <returns>Returns a collection of send lists in the given sort order</returns>
		public static SendListCollection GetSendListPage(int pageNo, int pageSize, SLSorts sortColumn, string filter, out int totalLists) 
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
				return SendListFactory.Create().GetSendListPage(pageNo, pageSize, sortColumn, filter, out totalLists);
			}
		}

        /// <summary>
        /// Returns a page of the items of a send list
        /// </summary>
        /// <returns>Returns a collection of send list items in the given sort order</returns>
        public static SendListItemCollection GetSendListItemPage(int listId, int pageNo, int pageSize, SLISorts sortColumn, out int totalItems) 
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
                return GetSendListItemPage(listId, pageNo, pageSize, SLIStatus.AllValues ^ SLIStatus.Removed, sortColumn, out totalItems);
            }
        }


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
        public static SendListItemCollection GetSendListItemPage(int listId, int pageNo, int pageSize, SLIStatus itemStatus, SLISorts sortColumn, out int totalItems)
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
                return SendListFactory.Create().GetSendListItemPage(listId, pageNo, pageSize, itemStatus, sortColumn, out totalItems);
            }
        }

        /// <summary>
        /// Gets the active send list entry of the given medium
        /// </summary>
        /// <param name="serialNo">
        /// Medium serial number
        /// </param>
        /// <returns>
        /// Send list item
        /// </returns>
        public static SendListItemDetails GetSendListItem(string serialNo)
        {
            return SendListFactory.Create().GetSendListItem(serialNo);
        }

        /// <summary>
        /// Gets the number of entries on the send list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        public static int GetSendListItemCount(int listId)
        {
            return SendListFactory.Create().GetSendListItemCount(listId);
        }

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
        public static int GetSendListItemCount(int listId, SLIStatus status)
        {
            return SendListFactory.Create().GetSendListItemCount(listId, status);
        }

        /// <summary>
        /// Gets a listing of the cases for a send list
        /// </summary>
        /// <param name="listId">
        /// Id of the list for which to get cases
        /// </param>
        public static SendListCaseCollection GetSendListCases(int listId) 
        {
            return SendListFactory.Create().GetSendListCases(listId);
        }

        /// <summary>
        /// Gets the send list cases for the browse page
        /// </summary>
        /// <returns>
        /// A send list case collection
        /// </returns>
        public static SendListCaseCollection GetSendListCases()
        {
            return SendListFactory.Create().GetSendListCases();
        }

        #endregion

        private static void EvaluateTapeExistence(SendListItemCollection slic)
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
                foreach (SendListItemDetails s in slic)
                    if (Medium.GetMedium(s.SerialNo) == null)
                        throw new ApplicationException("Serial number " + s.SerialNo + " is not defined in the system");
            }
        }

        /// <summary>
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="items">Items that will appear on the list(s)</param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        public static SendListDetails Create(SendListItemCollection items, SLIStatus initialStatus)
        {
            return Create(items, initialStatus, String.Empty, true);
        }

        /// <summary>
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="items">Items that will appear on the list(s)</param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        public static SendListDetails Create(SendListItemCollection items, SLIStatus initialStatus, bool doEmail)
        {
            return Create(items, initialStatus, String.Empty, doEmail);
        }

        /// <summary>
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="items">Items that will appear on the list(s)</param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        public static SendListDetails Create(SendListItemCollection items, SLIStatus initialStatus, string accountNo)
        {
            return Create(items, initialStatus, accountNo, true);
        }

        public static SendListDetails Create(SendListItemCollection slic, SLIStatus initialStatus, string accountNo, bool doEmail)
        {
            SendListDetails sl = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify input validity
            if (initialStatus != SLIStatus.Submitted && initialStatus != SLIStatus.VerifiedI)
            {
                throw new ArgumentException("Initial status may be either verified or submitted for send list creation.");
            }
            else if (slic == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (slic.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            else
            {
                EvaluateTapeExistence(slic);
            }
            // Make sure all objects are new objects
            foreach (SendListItemDetails item in slic)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only send list items marked as new may be used to create a send list.  Send list item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create the list
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran();
                    // Create data layer oejects
                    IMedium mdal = MediumFactory.Create(c);
                    ISendList sdal = SendListFactory.Create(c);
                    // If we have an account number, then we should force all the media
                    // to have the given account.
                    if (accountNo != null && accountNo.Length != 0)
                    {
                        String[] s1 = new String[slic.Count];
                        for (int i = 0; i < slic.Count; i += 1) s1[i] = slic[i].SerialNo;
                        mdal.ForceAccount(s1, Locations.Enterprise, accountNo);
                    }
                    // Create the send list
                    sl = sdal.Create(slic, initialStatus);
                    // Commit transaction
                    c.CommitTran();
                }
                catch (Exception e1)
                {
                    c.RollbackTran();
                    throw e1;
                }
            }
            // Send email
            if (doEmail == true)
                SendEmail(sl.Name, SLStatus.None, SLStatus.Submitted);
            // Return the list
            return sl;
        }
            
        /// <summary>
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="fileText">
        /// Text from HtmlInputFile in a byte array
        /// </param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        public static SendListDetails Create(byte[] fileText, SLIStatus initialStatus)
        {
            return Create(fileText, initialStatus, String.Empty);
        }

        /// <summary>
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="fileText">
        /// Text from HtmlInputFile in a byte array
        /// </param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        public static SendListDetails Create(byte[] fileText, SLIStatus initialStatus, string accountNo)
        {
            SendListDetails sl = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of input
            if (initialStatus != SLIStatus.Submitted && initialStatus != SLIStatus.VerifiedI)
            {
                throw new BLLException("New send list items must have either verified or submitted initial status.");
            }
            else if (fileText == null)
            {
                throw new ArgumentNullException("File text byte array may not be null.");
            }
            else if (fileText.Length == 0)
            {
                throw new ArgumentException("File contains no content.");
            }
            // Declare collections
            SendListItemCollection slic;
            SendListCaseCollection slcc;
            // Create the parser
            IParserObject parser = Parser.GetParser(ParserTypes.Movement, fileText);
            if (parser == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            parser.Parse(fileText, out slic, out slcc);
            if (slic == null || slic.Count == 0)
                throw new BLLException("Text from file did not contain any list items.");
            // Evaluate tape existence
            EvaluateTapeExistence(slic);
            // Open a connection in order to create the lists.  We do this 
            // explicitly because we need to employ a transaction in the BLL.
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Create the lists
                try
                {
                    // Begin a transaction
                    c.BeginTran();
                    // Make sure all the media reside at the enterprise.  If they
                    // don't move them.
                    foreach (SendListItemDetails sli in slic)
                    {
                        MediumDetails m = Medium.GetMedium(sli.SerialNo);
                        if (m != null && m.Location != Locations.Enterprise)
                        {
                            m.Location = Locations.Enterprise;
                            MediumFactory.Create(c).Update(m);
                        }
                    }
                    // Create the send list
                    sl = Create(slic, initialStatus, accountNo, false);
                    // Retrieve it to get all of the list items
                    sl = GetSendList(sl.Id, true);
                    // Update the sealed cases
                    SendListCaseCollection sealedCases = new SendListCaseCollection();
                    SendListCaseCollection listCases = new SendListCaseCollection(sl.ListCases);
                    foreach(SendListCaseDetails d1 in slcc)
                    {
                        if (d1.Sealed == true)
                        {
                            foreach(SendListCaseDetails d2 in listCases)
                            {
                                if (d1.Name == d2.Name)
                                {
                                    d2.Sealed = true;
                                    d2.Notes = d1.Notes;
                                    d2.ReturnDate = d1.ReturnDate;
                                    sealedCases.Add(d2);
                                }
                            }
                        }
                    }
                    // Update cases
                    if (sealedCases.Count > 0)
                    {
                        try
                        {
                            UpdateCases(ref sealedCases);
                        }
                        catch (CollectionErrorException)
                        {
                            foreach (SendListCaseDetails listCase in sealedCases)
                                if (listCase.RowError != String.Empty)
                                    throw new BLLException(listCase.RowError);
                        }
                    }
                    // Commit transaction
                    c.CommitTran();
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
            // Send email
            SendEmail(sl.Name, SLStatus.None, SLStatus.Submitted);
            // Return the list
            return sl;
        }
        
        /// <summary>
        /// Merges a collection of send lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        public static SendListDetails Merge(SendListCollection listCollection) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have at least two lists in the collection
            if (listCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list collection object.");
            }
            else if (listCollection.Count < 2)
            {
                throw new ArgumentException("Send list collection must contain at least two send lists to faciliate merging.");
            }
            else
            {
                return SendListFactory.Create().Merge(listCollection);
            }
        }

        /// <summary>
        /// Extracts a send list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        public static void Extract(SendListDetails compositeList, SendListDetails discreteList) 
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
            else if ((new SendListCollection(compositeList.ChildLists)).Find(discreteList.Name) == null)
            {
                throw new BLLException("Given discrete list not found within the given composite list.");
            }
            else
            {
                SendListFactory.Create().Extract(compositeList, discreteList);
            }
        }

        /// <summary>
        /// Dissolves a send list from composite.  In other words, extracts all
        /// discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        public static void Dissolve(SendListDetails compositeList) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have a composite list
            if (compositeList == null)
            {
                throw new ArgumentNullException("Send list reference must be set to an instance of a send list.");
            }
            else if (false == compositeList.IsComposite)
            {
                throw new ArgumentException("A composite list was supplied where a discrete list was expected.");
            }
            else
            {
                // Dissolve the list
                SendListFactory.Create().Dissolve(compositeList);
            }
        }

        #region Transmission Methods
        private static IXmitter CreateXmitter()
        {
            return XmitterFactory.Create();
        }

        private static void Transmit(SendListDetails sl, IXmitter x)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Transmitter must have be instantiated and passed
            if (x == null)
                throw new ApplicationException("Transmitter not instantiated.");
            else if (sl == null)
                throw new ArgumentNullException("Reference must be set to an instance of a send list object.");
            else if (!StatusEligible(sl.Status, SLStatus.Xmitted))
                throw new ApplicationException("List " + sl.Name + " is not eligible for transmitting.");
            // Remember the old status for email alert
            SLStatus oStatus = sl.Status;
            // Create a collection to hold lists to be transmitted
            SendListCollection listCollection = new SendListCollection();
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
            if (sl.IsComposite == false)
            {
                // Refresh the list
                sl = SendList.GetSendList(sl.Id, true);
                // Add to the collection
                listCollection.Add(sl);
            }
            else
            {
                // Get the child lists if we do not have them
                if (sl.ChildLists.Length == 0) sl = GetSendList(sl.Id, true);
                // Transmit each child list in turn
                foreach(SendListDetails cl in sl.ChildLists)
                {
                    // Get the items on the child list
                    SendListDetails s = SendList.GetSendList(cl.Id, true);
                    // If the status of the composite is greater than or equal to
                    // transmitted, then transmit all lists regardless of status.
                    // Otherwise, only transmit those that have yet to be 
                    // transmitted.
                    if (sl.Status >= SLStatus.Xmitted)
                    {
                        listCollection.Add(s);
                    }
                    else if (s.Status < SLStatus.Xmitted)
                    {
                        listCollection.Add(s);
                    }
                }
            }
            // If we have no lists in the collection, we can return
            if (listCollection.Count == 0) return;
            // Keep count of failed lists
            int failedLists = 0;
            string exMessage = String.Empty;
            // Create a transmitter and a data layer object
            ISendList dal = SendListFactory.Create();
            // Loop through the collection, transmitting lists
            foreach(SendListDetails s in listCollection)
            {
                try
                {
                    x.Transmit(s);
                }
                catch (Exception ex)
                {
                    if (exMessage.Length == 0) exMessage = ex.Message;
                    failedLists += 1;
                    continue;
                }
                // Update the database
                dal.Transmit(s, false);
            }
            // If no lists failed, then clear if requested.  Otherwise throw 
            // the appropriate exception.
            if (failedLists != 0)
            {
                if (sl.IsComposite && failedLists != sl.ChildLists.Length)
                    throw new ApplicationException("List " + sl.Name + " transmission only partially successful: " + exMessage);
                else
                    throw new ApplicationException("List " + sl.Name + " transmission failed: " + exMessage);
            }
            // Send any email alert necessary
            SendEmail(sl.Name, oStatus, SLStatus.Xmitted);
        }
        /// <summary>
        /// Transmits a send list
        /// </summary>
        /// <param name="list">
        /// Send list to transmit
        /// </param>
        public static void Transmit(SendListDetails list) 
        {
            Transmit(list, CreateXmitter());
        }
        /// <summary>
        /// Transmits a send list
        /// </summary>
        /// <param name="list">
        /// Send list to transmit
        /// </param>
        public static void Transmit(SendListCollection sendLists)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (sendLists == null)
                throw new ArgumentNullException("Reference must be set to a collection of send list objects.");
            // Because transmission isn't atomic (an early list may be transmitted,
            // only to find that a later list is not transmission-eligible), we want
            // to make sure up-front that everyone is eligible.
            foreach (SendListDetails s in sendLists)
                if (!StatusEligible(s.Status, SLStatus.Xmitted))
                    throw new ApplicationException("List " + s.Name + " is not currently eligible for transmission.");
            // Create the transmitter
            IXmitter x = CreateXmitter();
            // Now transmit each in turn
            foreach (SendListDetails s in sendLists)
                Transmit(s, x);
        }
        #endregion

        /// <summary>
        /// Marks a send list as in transit
        /// </summary>
        /// <param name="sl">
        /// Send list to mark
        /// </param>
        public static void MarkTransit(SendListDetails sl)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have an untransmitted list
            if (sl == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list object.");
            }
            else
            {
                SLStatus oStatus = sl.Status;
                SendListFactory.Create().MarkTransit(sl);
                SendEmail(sl.Name, oStatus, SLStatus.Transit);
            }
        }

        /// <summary>
        /// Marks a send list as arrived
        /// </summary>
        /// <param name="sl">
        /// Send list to mark
        /// </param>
        public static void MarkArrived(SendListDetails sl)
        {
            CustomPermission.Demand(Role.Operator);
            // Must have an untransmitted list
            if (sl == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list object.");
            }
            else
            {
                SLStatus oStatus = sl.Status;
                SendListFactory.Create().MarkArrived(sl);
                SendEmail(sl.Name, oStatus, SLStatus.Arrived);
            }
        }

        /// <summary>
        /// Deletes a given list from the system
        /// </summary>
        /// <param name="list">Send list to delete</param>
        public static void Delete(SendListDetails list)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have an untransmitted list
            if (list == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list object.");
            }
            else
            {
                SendListFactory.Create().Delete(list);
            }
        }

        /// <summary>
        /// Verifies a set of send list items.  This method iterates through
        /// the collection and verifies the items on each list.
        /// </summary>
        /// <param name="sendLists">
        /// A collection send lists to verify
        /// </param>
        public static void Verify(SendListCollection sendLists)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Create a data access layer object
            ISendList dal = SendListFactory.Create();
            // Make sure that each is verification-eligible
            foreach (SendListDetails sl in sendLists)
                if (!StatusEligible(dal.GetSendList(sl.Id, false), SLStatus.FullyVerifiedI | SLStatus.FullyVerifiedII))
                    throw new ArgumentException("List " + sl.Name + " is not currently eligible for verification.");
            // Verify the lists
            foreach (SendListDetails sl in sendLists)
            {
                SendListItemCollection slic = new SendListItemCollection();
                // Get the items of the list
                SendListDetails sx = SendList.GetSendList(sl.Id, true);
                // Place all the list items in the collection
                if (sx.IsComposite == false)
                    slic.Add(sx.ListItems);
                else
                    foreach (SendListDetails sc in sx.ChildLists)
                        slic.Add(sc.ListItems);
                // Verify the list
                Verify(sl.Name, ref slic);
            }
        }

        /// <summary>
        /// Verifies a send list
        /// </summary>
        /// <param name="sl">
        /// A send list to verify
        /// </param>
        public static void Verify(SendListDetails sl)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Create a collection
            SendListCollection slc = new SendListCollection();
            // Add items to it
            slc.Add(sl);
            // Hand to the collection overload
            try
            {
                Verify(slc);
            }
            catch
            {
                if (slc[0].RowError.Length != 0)
                    throw new ApplicationException(slc[0].RowError);
                else
                    throw;
            }

        }

        /// <summary>
        /// Verifies a set of send list items.  This method iterates through
        /// the collection and verifies each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the 
        /// error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection send list items to verify
        /// </param>
        public static void Verify(int listId, ref SendListItemCollection items)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Overload call
            Verify(GetSendList(listId,false).Name, ref items);
        }

        /// <summary>
        /// Verifies a set of send list items.  This method iterates through
        /// the collection and verifies each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the 
        /// error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection send list items to verify
        /// </param>
        public static void Verify(string listName, ref SendListItemCollection items)
        {
            SLStatus actionStatus;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Obtain the receive list
            SendListDetails sl = SendList.GetSendList(listName, false);
            // Eligibility
            if (StatusEligible(sl, SLStatus.FullyVerifiedI))
            {
                actionStatus = SLStatus.FullyVerifiedI;
            }
            else if (StatusEligible(sl, SLStatus.FullyVerifiedII))
            {
                actionStatus = SLStatus.FullyVerifiedII;
            }
            else
            {
                throw new ArgumentException("List " + listName + " is not currently eligible for verification.");
            }
            // Get the current list status
            SLStatus oStatus = sl.Status;
            // Take out any removed items
            for (int i = items.Count-1; i >= 0; i--)
                if (items[i].Status == SLIStatus.Removed)
                    items.RemoveAt(i);
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran("verify send list item");
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Verify each item
                foreach(SendListItemDetails item in items)
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
                        items.Replace(items[i], dal.GetSendListItem(items[i].Id));
                }
            }
            // Send any email alert necessary
            SendEmail(listName, oStatus, actionStatus);
        }

        /// <summary>
        /// Removes a set of send list items.  This method iterates through
        /// the collection and removes each item.  If an error occurs on any
        /// item, the transaction is rolled back and the HasErrors property
        /// of the collection is set to true.  Each item that resulted in error
        /// will have its RowError property set with a description of the 
        /// error.  Upon completion of this routine, the user interface 
        /// component caller should always check the HasErrors property.
        /// </summary>
        /// <param name="item">
        /// A collection send list items to remove
        /// </param>
        public static void RemoveItems(string listName, ref SendListItemCollection items) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Get the status of the list
            SLStatus oStatus = SendList.GetSendList(listName, false).Status;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListItemDetails item in items)
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
                    SendListItemDetails sli;
                    for (int i = 0; i < items.Count; i++)
                    {
                        // If the item no longer exists, then the list has been
                        // completely deleted; just set the status to removed.
                        // Otherwise replace the item with the current item in
                        // order to refresh the rowversion.
                        if ((sli = dal.GetSendListItem(items[i].Id)) != null)
                            items.Replace(items[i], sli);
                        else
                            items[i].ObjState = ObjectStates.Deleted;
                    }
                }
            }
            // Send an email alert if list still exists
            SendListDetails sl = GetSendList(listName, false);
            if (sl != null) SendEmail(listName, oStatus, sl.Status);
        }

        /// <summary>
        /// Updates all items in the collection.  After success, the
        /// caller should refetch any affected lists.
        /// </summary>
        /// <param name="items">
        /// Collection of SendListItemDetails objects
        /// </param>
        public static void UpdateItems(ref SendListItemCollection items) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Validate the input data
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check item status and state
            foreach (SendListItemDetails item in items)
                if (item.ObjState != ObjectStates.Modified)
                    throw new ObjectStateException("Only send list items marked as modified may be updated.  Receive list item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListItemDetails item in items)
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
                        items.Replace(items[i], dal.GetSendListItem(items[i].Id));
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
        /// Collection of SendListItemDetails objects
        /// </param>
        /// <param name="initialStatus">
        /// Items may be added as unverified or verified
        /// </param>
        public static void AddItems(ref SendListDetails list, ref SendListItemCollection items, SLIStatus initialStatus)
        {
            AddItems(ref list, ref items, initialStatus, String.Empty);
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
        /// Collection of SendListItemDetails objects
        /// </param>
        /// <param name="initialStatus">
        /// Items may be added as unverified or verified
        /// </param>
        public static void AddItems(ref SendListDetails list, ref SendListItemCollection items, SLIStatus initialStatus, string accountNo)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have items in the collection
            if (initialStatus != SLIStatus.Submitted && initialStatus != SLIStatus.VerifiedI)
            {
                throw new ArgumentException("Initial status may be either verified or submitted for send list creation.");
            }
            else if (list == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list object.");
            }
            else if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            list.RowError = String.Empty;
            // Make sure each object is new 
            foreach (SendListItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only send list items marked as new may be added.  Receive list item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                IMedium mdal = MediumFactory.Create(c);
                ISendList sdal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListItemDetails item in items)
                {
                    try
                    {
                        // If we are dictating account, do it here
                        if (accountNo != null && accountNo.Length != 0)
                        {
                            mdal.ForceAccount(new String[] {item.SerialNo}, Locations.Enterprise, accountNo);
                        }
                        // Add the item to the list
                        sdal.AddItem(list, item, initialStatus);
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
                    list = GetSendList(list.Id, list.ListItems.Length > 0);
                }
            }
        }

        /// <summary>
        /// Removes items from cases
        /// </summary>
        /// <param name="items">
        /// Collection of SendListItemDetails objects
        /// </param>
        /// <param name="cases">
        /// Collection of SendListCaseDetails objects
        /// </param>
        public static void RemoveFromCases(SendListItemCollection items, SendListCaseCollection cases) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Validate the input data
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                try
                {
                    foreach(SendListItemDetails i in items)
                    {
                        if (i.CaseName.Length != 0)
                        {
                            SendListCaseDetails itemCase = cases.Find(i.CaseName);
                            if (itemCase == null) throw new ApplicationException("Case " + i.CaseName + " not found on list");
                            dal.RemoveItemFromCase(i.Id, itemCase.Id);
                        }
                    }
                    // Commit the transaction
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
        /// Removes items from cases
        /// </summary>
        /// <param name="items">
        /// Collection of SendListItemDetails objects
        /// </param>
        /// <param name="cases">
        /// Collection of SendListCaseDetails objects
        /// </param>
        public static void RemoveFromCases(SendListItemCollection sli) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Validate the input data
            if (sli == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list item collection object.");
            }
            else if (sli.Count == 0)
            {
                throw new ArgumentException("Send list item collection must contain at least one send list item object.");
            }
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                try
                {
                    foreach(SendListItemDetails i in sli)
                    {
                        if (i.CaseName.Length != 0)
                        {
                            SendListCaseDetails d = dal.GetSendListCase(i.CaseName);
                            if (d != null) dal.RemoveItemFromCase(i.Id, d.Id);
                        }
                    }
                    // Commit the transaction
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
        /// Gets the media within a send list case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case
        /// </param>
        /// <returns>
        /// Medium collection containing media within the case
        /// </returns>
        public static MediumCollection GetCaseMedia(string caseName)
        {
            return SendListFactory.Create().GetCaseMedia(caseName);
        }

        /// <summary>
        /// Updates the sealed status, return date, and notes for a 
        /// collection of cases.  This method iterates through the collection
        /// and updates each case.  If an error occurs on any item, the 
        /// transaction is rolled back and the HasErrors property of the 
        /// collection is set to true.  Each item that resulted in error 
        /// will have its RowError property set with an error description.
        /// </summary>
        /// <param name="cases">Collection of send list cases</param>
        public static void UpdateCases(ref SendListCaseCollection sendCases) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Validate the input data
            if (sendCases == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list case collection object.");
            }
            else if (sendCases.Count == 0)
            {
                throw new ArgumentException("Send list case collection must contain at least one send list case object.");
            }
            // Reset the error flag
            sendCases.HasErrors = false;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListCaseDetails sendCase in sendCases)
                {
                    try
                    {
                        dal.UpdateCase(sendCase);
                        sendCase.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        sendCase.RowError = e.Message;
                        sendCases.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (sendCases.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(sendCases);
                }
                else
                {
                    c.CommitTran();
                    // Refresh the items in the collection
                    for (int i = 0; i < sendCases.Count; i++)
                        sendCases.Replace(sendCases[i], dal.GetSendListCase(sendCases[i].Id));
                }
            }
        }

        /// <summary>
        /// Deletes a set of cases from a send list.  This method iterates
        /// through the collection and updates each case.  If an error occurs
        /// on any item, the transaction is rolled back and the HasErrors 
        /// property of the collection is set to true.  Each item that 
        /// resulted in error will have its RowError property set with an 
        /// error description.
        /// </summary>
        /// <param name="cases">Collection of send list cases</param>
        public static void DeleteCases(ref SendListCaseCollection sendCases) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Validate the input data
            if (sendCases == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list case collection object.");
            }
            else if (sendCases.Count == 0)
            {
                throw new ArgumentException("Send list case collection must contain at least one send list case object.");
            }
            // Reset the error flag
            sendCases.HasErrors = false;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListCaseDetails sendCase in sendCases)
                {
                    try
                    {
                        dal.DeleteCase(sendCase);
                        sendCase.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        sendCase.RowError = e.Message;
                        sendCases.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (sendCases.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(sendCases);
                }
                else
                {
                    c.CommitTran();
                    // Refresh the items in the collection
                    foreach(SendListCaseDetails sendCase in sendCases)
                        sendCase.ObjState = ObjectStates.Deleted;
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific send list scan
        /// </summary>
        /// <param name="name">Unique identifier for a send list</param>
        /// <returns>Returns the information for the send list scan</returns>
        public static SendListScanDetails GetScan(string name) 
        {
            return SendListFactory.Create().GetScan(name);
        }

        /// <summary>
        /// Returns the information for a specific send list scan
        /// </summary>
        /// <param name="id">Unique identifier for a send list scan</param>
        /// <returns>Returns the information for the send list scan</returns>
        public static SendListScanDetails GetScan(int id) 
        {
            return SendListFactory.Create().GetScan(id);
        }

        /// <summary>
        /// Gets the scans for a specified send list
        /// </summary>
        /// <param name="listName">
        /// Name of the list
        /// </param>
        /// <returns>
        /// Collection of scans
        /// </returns>
        public static SendListScanCollection GetScansForList(string listName)
        {
            ISendList dal = SendListFactory.Create();
            SendListDetails s = dal.GetSendList(listName, false);
            return dal.GetScansForList(listName, s.Status < SLStatus.Xmitted ? 1 : 2);
        }

        /// <summary>
        /// Creates a send list scan
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
        public static SendListScanDetails CreateScan(string listName, string scanName, ref SendListScanItemCollection items)
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
                throw new ArgumentNullException("Reference must be set to an instance of a send list compare file item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list compare file item collection must contain at least one receive list compare file item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check object states
            foreach (SendListScanItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only compare file items marked as new may be used to create a compare file.  Compare file item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Loop through the items until a scan is created, then add the rest of the items
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Create the send list scan object
                SendListScanDetails createScan = null;
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListScanItemDetails item in items)
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
        /// Creates a send list scan
        /// </summary>
        /// <returns>Created send list scan</returns>
        public static SendListScanDetails CreateScan(string listName, string scanName, byte[] fileText)
        {
            string[] serialNos;
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
            // Create the parser
            IParserObject parser = Parser.GetParser(ParserTypes.Movement, fileText);
            if (parser == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            parser.Parse(fileText, out serialNos, out caseNames);
            if(serialNos == null || serialNos.Length == 0) 
            {
                throw new BLLException("Text from file did not contain any send list items.");
            }
            // Create a new scan list item collection and populate it
            SendListScanItemCollection scanItems = new SendListScanItemCollection();
            for (int i = 0; i < serialNos.Length; i++) 
            {
                scanItems.Add(new SendListScanItemDetails(serialNos[i], caseNames[i]));
            }
            // Create the scan.  If a collection exception was thrown, repackage as a BLL exception
            // since the collection is not accessible to the caller.
            if(scanItems == null || scanItems.Count == 0) 
            {
                throw new BLLException("Text from file did not contain any send list items.");
            }
            // Create the scan.  If a collection exception was thrown, repackage as a BLL exception
            // since the collection is not accessible to the caller.
            try
            {
                return CreateScan(listName, scanName, ref scanItems);
            }
            catch (CollectionErrorException)
            {
                foreach (SendListScanItemDetails s in scanItems)
                    if (s.RowError != String.Empty)
                        throw new BLLException(s.RowError);
            }
            // Different exception was thrown
            return null;
        }

        /// <summary>
        /// Deletes a set of send list scans
        /// </summary>
        /// <returns>Created send list scan</returns>
        public static void DeleteScans(ref SendListScanCollection scans) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (scans == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list compare file collection object.");
            }
            else if (scans.Count == 0)
            {
                throw new ArgumentException("Send list compare file collection must contain at least one send list compare file object.");
            }
            // Reset the error flag
            scans.HasErrors = false;
            // Check states
            foreach (SendListScanDetails scan in scans)
                if (scan.ObjState != ObjectStates.Unmodified)
                    throw new ObjectStateException("Only compare files marked as unmodified may be deleted.  Compare file '" + scan.Name + "' is " + scan.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListScanDetails scan in scans)
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
                    foreach(SendListScanDetails scan in scans)
                        scan.ObjState = ObjectStates.Deleted;
                }
            }
        }

        /// <summary>
        /// Adds a set of items to a scan
        /// </summary>
        /// <returns>Scan to which items were added</returns>
        public static void AddScanItems(ref SendListScanDetails scan, ref SendListScanItemCollection items) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (scan == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list compare file object.");
            }
            else if (scan.LastCompared != String.Empty)
            {
                throw new ArgumentNullException("A compare file may not be altered once it has been compared against its list.");
            }
            else if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list compare file item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list compare file item collection must contain at least one send list compare file item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            scan.RowError = String.Empty;
            // Object states
            foreach (SendListScanItemDetails item in items)
                if (item.ObjState != ObjectStates.New)
                    throw new ObjectStateException("Only compare file items marked as new may be added.  Compare file item '" + item.SerialNo + "' is " + scan.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListScanItemDetails item in items)
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
        public static void DeleteScanItems(ref SendListScanItemCollection items) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (items == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a send list compare file item collection object.");
            }
            else if (items.Count == 0)
            {
                throw new ArgumentException("Send list compare file item collection must contain at least one send list compare file item object.");
            }
            // Reset the error flag
            items.HasErrors = false;
            // Check statuses
            foreach (SendListScanItemDetails item in items)
                if (item.ObjState != ObjectStates.Unmodified)
                    throw new ObjectStateException("Only compare file items marked as unmodified may be deleted.  Compare file item '" + item.SerialNo + "' is " + item.ObjState.ToString().ToLower());
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Remove each item from the list
                foreach(SendListScanItemDetails item in items)
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
                    foreach(SendListScanItemDetails item in items)
                    {
                        item.ObjState = ObjectStates.Deleted;
                    }
                }
            }
        }
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
		public static string GetScanItemCase(int listid, string serial)
		{
			using (IConnection c = ConnectionFactory.Create().Open())
			{
				return SendListFactory.Create(c).GetScanItemCase(listid, serial);
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
        public static SendListCompareResult CompareListToScans(int listId) 
        {
            return CompareListToScans(GetSendList(listId, false).Name);
        }
        /// <summary>
        /// Compares a list against one or more scans
        /// </summary>
        /// <param name="listName">
        /// Name of the list against which to compare
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        public static SendListCompareResult CompareListToScans(string listName) 
        {
            SendListCompareResult lcr = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Must have a list name
            if (listName == null || listName == String.Empty)
            {
                throw new ArgumentException("List name not supplied.");
            }
            else if (listName.Substring(0,3) != "SD-")
            {
                throw new ArgumentException("List name supplied is not a valid shipping list name.");
            }
            // Get the list
            SendListDetails sl = SendList.GetSendList(listName, false);
            // Record the current status of the list
            SLStatus oStatus = sl.Status;
            SLStatus actionStatus = SLStatus.None;
            // Check the eligibility
            if (StatusEligible(sl.Status, SLStatus.FullyVerifiedI) || sl.Status == SLStatus.FullyVerifiedI)
            {
                actionStatus = SLStatus.FullyVerifiedI;
            }
            else if (StatusEligible(sl.Status, SLStatus.FullyVerifiedII))
            {
                actionStatus = SLStatus.FullyVerifiedII;
            }
            else
            {
                throw new ArgumentException("List is not currently verification-eligible.");
            }
            // Create a connection to enforce a transaction
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Create the data access layer object
                ISendList dal = SendListFactory.Create(c);
                // Begin a transaction
                c.BeginTran("compare list to scan");
                // Compare the scans to the list
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
        /// Sends email status alert if list is at or beyond any of the given statuses and 
        /// statuses require email alerts to be sent.
        /// </summary>
        /// <param name="rl"></param>
        /// <param name="rls"></param>
        /// <returns></returns>
        public static void SendEmail(string listName, SLStatus oStatus, SLStatus actionStatus)
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
            SendListCollection c = SendList.GetSendListPage(1, 32767, SLSorts.ListName, out x);
            // Get any active lists past due
            foreach (SendListDetails sl in c)
                if (sl.Status != SLStatus.Processed)
                    if (sl.CreateDate < d)
                        listNames.Add(sl.Name);
            // Send the email
            new Email(Thread.CurrentPrincipal, WindowsIdentity.GetCurrent()).SendOverdueAlert(listNames);
        }

        #region Email Groups
        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        public static EmailGroupCollection GetEmailGroups(SLStatus sl)
        {
            return SendListFactory.Create().GetEmailGroups(sl);
        }

        /// <summary>
        /// Gets the email groups for list alert
        /// </summary>
        /// <returns>
        /// Email group collection
        /// </returns>
        public static EmailGroupCollection GetEmailGroups()
        {
            return SendListFactory.Create().GetEmailGroups();
        }

        /// <summary>
        /// Gets the list alert days for shipping lists
        /// </summary>
        /// <returns></returns>
        public static int GetListAlertDays()
        {
            return SendListFactory.Create().GetListAlertDays();
        }

        /// <summary>
        /// Gets the time of the last list alert
        /// </summary>
        /// <returns></returns>
        public static DateTime GetListAlertTime()
        {
            return SendListFactory.Create().GetListAlertTime();
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
            SendListFactory.Create().UpdateAlertDays(days);
        }

        /// Updates the alert time
        /// </summary>
        /// <param name="d">
        /// Time to update
        /// </param>
        public static void UpdateAlertTime(DateTime d)        
        {
            SendListFactory.Create().UpdateAlertTime(d);
        }

        /// <summary>
        /// Attaches an email group to a list status
        /// </summary>
        /// <param name="x">
        /// Email group to attach
        /// </param>
        /// <param name="y">
        /// Email group to attach
        /// </param>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        public static void ManipulateEmailGroups(EmailGroupCollection x, EmailGroupCollection y, SLStatus sl)
        {
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran("attach email group");
                // Initialize a data access layer object with the connection
                ISendList dal = SendListFactory.Create(c);
                // Attach email groups
                foreach(EmailGroupDetails e in x)
                {
                    try
                    {
                        dal.AttachEmailGroup(e, sl);
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
                        dal.DetachEmailGroup(e, sl);
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
                ISendList dal = SendListFactory.Create(c);
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
            private delegate void EmailDelegate (string listName, SLStatus oStatus, SLStatus actionStatus);
            private delegate void OverdueDelegate(List<String> listNames);
            private WindowsImpersonationContext wic = null;
            private WindowsIdentity wi = null;
            private IPrincipal p = null;

            public Email(IPrincipal _p, WindowsIdentity _wi) {p = _p; wi = _wi;}

            public void Send(string listName, SLStatus oStatus, SLStatus actionStatus)
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
                    Mailer.SendOverdueListAlert(ListTypes.Send, listNames.ToArray(), String.Join(";", r.ToArray()));
                }
                catch
                {
                    ;
                }
            }

            private void DoSend(string listName, SLStatus oStatus, SLStatus actionStatus)
            {
                try
                {
                    // Set the identity and principal
                    Thread.CurrentPrincipal = p;
                    if (wi != null) wic = wi.Impersonate();
                    // Get the list from the database.  If the status is equal to the
                    // old status, just return true.
                    SendListDetails sl = SendList.GetSendList(listName, false);
                    if (sl == null || (sl.Status != actionStatus && sl.Status != SLStatus.Processed)) return;
                    // Initialize
                    string actionVerb = String.Empty;
                    ArrayList recipients1 = new ArrayList();   // action status only
                    ArrayList recipients2 = new ArrayList();   // processed status only
                    ArrayList recipients3 = new ArrayList();   // action status and processed status
                    // Get the operators in the group
                    foreach (EmailGroupDetails e in SendList.GetEmailGroups(actionStatus))
                        foreach (OperatorDetails o in EmailGroup.GetOperators(e))
                            if (o.Email.Length != 0 && !recipients1.Contains(o.Email))
                                recipients1.Add(o.Email);
                    // Get the approriate verb
                    switch (actionStatus)
                    {
                        case SLStatus.Submitted:
                            actionVerb = "created";
                            break;
                        case SLStatus.Arrived:
                            actionVerb = "marked as arrived";
                            break;
                        case SLStatus.Transit:
                            actionVerb = "marked as in transit";
                            break;
                        case SLStatus.Processed:
                            break;
                        default:
                            actionVerb = ListStatus.ToLower(actionStatus);
                            break;
                    }
                    // If also processed, add and remove from groups as appropriate
                    if (sl.Status == SLStatus.Processed)
                    {
                        foreach (EmailGroupDetails e in SendList.GetEmailGroups(sl.Status))
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
                    sl = SendList.GetSendList(listName, true);
                    // Create a collection for active items and one for removed items
                    SendListItemCollection ai = new SendListItemCollection();
                    SendListItemCollection ri = new SendListItemCollection();
                    // Get all the items into a collection
                    if (false == sl.IsComposite)
                    {
                        foreach (SendListItemDetails sli in sl.ListItems)
                        {
                            if (sli.Status != SLIStatus.Removed)
                                ai.Add(sli);
                            else
                                ri.Add(sli);
                        }
                    }
                    else
                    {
                        foreach (SendListDetails s1 in sl.ChildLists)
                        {
                            foreach (SendListItemDetails sli in s1.ListItems)
                            {
                                if (sli.Status != SLIStatus.Removed)
                                    ai.Add(sli);
                                else
                                    ri.Add(sli);
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
                        b.AppendFormat("Shipping list {0} has been {1}.{2}{2}{2}", listName, v.ToUpper(), Environment.NewLine);
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
