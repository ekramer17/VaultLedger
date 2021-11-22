using System;
using System.IO;
using System.Web;
using System.Text;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for ActionList.
	/// </summary>
	public class ActionList
	{
        private delegate void PurgeDelegate();
        private delegate void AlertDelegate(DateTime d);

        #region Purge Methods

        /// <summary>
        /// Gets the set of list purge parameters from the database
        /// </summary>
        /// <returns>
        /// Collection of ListPurgeDetails objects
        /// </returns>
        public static ListPurgeCollection GetPurgeParameters()
        {
            return ActionListFactory.Create().GetPurgeParameters();
        }

        public static void BeginPurgeClearedLists()
        {
            PurgeDelegate purgeDelegate = new PurgeDelegate(PurgeClearedLists);
            purgeDelegate.BeginInvoke(null, null);
        }

        /// <summary>
        /// Cleans the cleared lists from the database
        /// </summary>
        public static void PurgeClearedLists()
        {
            // Get the purge details from the database
            ListPurgeCollection listPurges = GetPurgeParameters();
            // For each of the list purge details, retrieve the records.  If 
            // that list type is to be archived, archive it.  Then delete the
            // records from the database.
            foreach (ListPurgeDetails lp in listPurges)
            {
                // Remove the expired lists from the database.  Archive if necessary.
                try
                {
                    DateTime lateDate = Time.UtcToday.AddDays(-lp.Days);
                    // Archive if necessary
                    if (lp.Archive == true)
                    {
                        switch (lp.ListType)
                        {
                            case ListTypes.Send:
                                ArchiveSendLists(SendListFactory.Create().GetCleared(lateDate));
                                break;
                            case ListTypes.Receive:
                                ArchiveReceiveLists(ReceiveListFactory.Create().GetCleared(lateDate));
                                break;
                            case ListTypes.DisasterCode:
                                ArchiveDisasterCodeLists(DisasterCodeListFactory.Create().GetCleared(lateDate));
                                break;
                        }
                    }
                    // Clean the records
                    ActionListFactory.Create().PurgeLists(lp.ListType, lateDate);
                }
                catch
                {
                    ;
                }

            }
        }
        /// <summary>
        /// Updates list purge parameters
        /// </summary>
        public static void UpdatePurgeParameters(ref ListPurgeCollection listPurges)
        {
            if (listPurges == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a list purge parameter collection object.");
            }
            else if (listPurges.Count == 0)
            {
                throw new ArgumentException("List purge parameter collection must contain at least one list purge parameter object.");
            }
            // Reset the error flag
            listPurges.HasErrors = false;
            // Perform the updates
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Reset the collection error flag
                listPurges.HasErrors = false;
                // Create a DAL object
                IActionList dal = ActionListFactory.Create(c);
                // Loop through the list purge parameter objects
                foreach (ListPurgeDetails listPurge in listPurges)
                {
                    if (listPurge.ObjState == ObjectStates.Modified)
                    {
                        try
                        {
                            dal.UpdatePurgeParameters(listPurge);
                            listPurge.RowError = String.Empty;
                        }
                        catch (Exception e)
                        {
                            listPurge.RowError = e.Message;
                            listPurges.HasErrors = true;
                        }
                    }
                }
                // If the collection has errors, roll back the transaction and
                // throw a collection exception.
                if (listPurges.HasErrors)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(listPurges);
                }
                else
                {
                    c.CommitTran();
                    // Get the current purge parameters and create an empty collection
                    ListPurgeCollection currentParameters = GetPurgeParameters();
                    ListPurgeCollection returnCollection = new ListPurgeCollection();
                    // Fill the empty collection with the updated versions of those
                    // purge parameters that were modified.  Simply add those that were not.
                    foreach (ListPurgeDetails listPurge in listPurges)
                    {
                        if (listPurge.ObjState != ObjectStates.Modified)
                        {
                            returnCollection.Add(listPurge);
                        }
                        else
                        {
                            returnCollection.Add(currentParameters.Find(listPurge.ListType));
                        }
                    
                    }
                    // Return the updated collection by reference
                    listPurges = returnCollection;
                }
            }
        }


        private static void ArchiveSendLists(SendListCollection sendLists)
        {
        }

        private static void ArchiveReceiveLists(ReceiveListCollection receiveLists)
        {
        }

        private static void ArchiveDisasterCodeLists(DisasterCodeListCollection disasterCodeLists)
        {
        }

        #endregion

        #region Alert Methods

        public static void BeginIssueAlerts(DateTime d)
        {
            AlertDelegate alertDelegate = new AlertDelegate(IssueAlerts);
            alertDelegate.BeginInvoke(d, null, null);
        }

        /// <summary>
        /// Issues alerts for the list types
        /// </summary>
        /// <param name="d">current local date</param>
        public static void IssueAlerts(DateTime d)
        {
            DateTime s, r, c;
            d = new DateTime(d.Year, d.Month, d.Day);
            // Get the dates from the database
            s = SendList.GetListAlertTime();
            r = ReceiveList.GetListAlertTime();
            c = DisasterCodeList.GetListAlertTime();
            // Check each against the local date...if local date is later then issue alert
            if (s < d) 
            {
                try
                {
                    SendList.SendOverdueAlert(); 
                    SendList.UpdateAlertTime(d);
                }
                catch
                {
                    ;
                }
            }
        
            if (r < d)
            {
                try
                {
                    ReceiveList.SendOverdueAlert(); 
                    ReceiveList.UpdateAlertTime(d);
                }
                catch
                {
                    ;
                }
            }
            
            if (c < d)
            {
                try
                {
                    DisasterCodeList.SendOverdueAlert();
                    DisasterCodeList.UpdateAlertTime(d);
                }
                catch
                {
                    ;
                }
            }
        }
        #endregion

    }

    #region List Status Class
    /// <summary>
    /// Summary description for ListStatus.
    /// </summary>
    public class ListStatus
    {
        private static string RecallAdjust(string x)
        {
            // Strip I and II if Recall
            if (Configurator.ProductType != "RECALL")
                return x;
            else
                return x.Replace(" (I)",String.Empty).Replace(" (II)",String.Empty);
        }

        private static RLStatus XmitAdjust(RLStatus x)
        {
            if (x != RLStatus.Xmitted) 
            {
                return x;
            }
            else
            {
                RLStatus rx = RLStatus.Xmitted;
                int rls = (int)ReceiveList.Statuses;
                // Get the lowest valid status at or beyond xmitted
                while (rx != RLStatus.Processed)
                {
                    if (rx == RLStatus.PartiallyVerifiedI && (rls & (int)RLStatus.FullyVerifiedI) != 0)
                        break;
                    else if (rx == RLStatus.PartiallyVerifiedII && (rls & (int)RLStatus.FullyVerifiedII) != 0)
                        break;
                    else if ((rls & (int)rx) != 0)
                        break;
                    else
                        rx = (RLStatus)Enum.ToObject(typeof(RLStatus), (int)rx * 2);
                }
                // Return
                return rx;
            }
        }

        private static SLStatus XmitAdjust(SLStatus x)
        {
            if (x != SLStatus.Xmitted) 
            {
                return x;
            }
            else
            {
                SLStatus sx = SLStatus.Xmitted;
                int sls = (int)SendList.Statuses;
                // Get the lowest valid status at or beyond xmitted
                while (sx != SLStatus.Processed)
                {
                    if (sx == SLStatus.PartiallyVerifiedII && (sls & (int)SLStatus.FullyVerifiedII) != 0)
                        break;
                    else if ((sls & (int)sx) != 0)
                        break;
                    else
                        sx = (SLStatus)Enum.ToObject(typeof(SLStatus), (int)sx * 2);
                }
                // Return
                return sx;
            }
        }

        private static DLStatus XmitAdjust(DLStatus x)
        {
            if (x != DLStatus.Xmitted) 
            {
                return x;
            }
            else
            {
                DLStatus dx = DLStatus.Xmitted;
                int dls = (int)DisasterCodeList.Statuses;
                // Get the lowest valid status at or beyond xmitted
                while (dx != DLStatus.Processed)
                {
                    if ((dls & (int)dx) != 0)
                        break;
                    else
                        dx = (DLStatus)Enum.ToObject(typeof(DLStatus), (int)dx * 2);
                }
                // Return
                return dx;
            }
        }

        #region Receive List Status Translations
        /// <summary>
        /// Translates a receive list status to a string, using uppercase where necessary
        /// </summary>
        /// <param name="rls">Status</param>
        /// <returns>String format of status</returns>
        public static string ToUpper(RLStatus rls)
        {
            switch (XmitAdjust(rls))
            {
                case RLStatus.Arrived:
                    return "Arrived";
                case RLStatus.FullyVerifiedI:
                    return RecallAdjust("Fully Verified (I)");
                case RLStatus.FullyVerifiedII:
                    return RecallAdjust("Fully Verified (II)");
                case RLStatus.Transit:
                    return "In Transit";
                case RLStatus.PartiallyVerifiedI:
                    return RecallAdjust("Partially Verified (I)");
                case RLStatus.PartiallyVerifiedII:
                    return RecallAdjust("Partially Verified (II)");
                case RLStatus.Processed:
                    return "Processed";
                case RLStatus.Submitted:
                    return "Submitted";
                case RLStatus.Xmitted:
                    return "Transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        /// <summary>
        /// Translates a receive list status to a string, using lowercase where necessary
        /// </summary>
        /// <param name="rls">Status</param>
        /// <returns>String format of status</returns>
        public static string ToLower(RLStatus rls)
        {
            switch (XmitAdjust(rls))
            {
                case RLStatus.Arrived:
                    return "arrived";
                case RLStatus.FullyVerifiedI:
                    return RecallAdjust("fully verified (I)");
                case RLStatus.FullyVerifiedII:
                    return RecallAdjust("fully verified (II)");
                case RLStatus.Transit:
                    return "in transit";
                case RLStatus.PartiallyVerifiedI:
                    return RecallAdjust("partially verified (I)");
                case RLStatus.PartiallyVerifiedII:
                    return RecallAdjust("partially verified (II)");
                case RLStatus.Processed:
                    return "processed";
                case RLStatus.Submitted:
                    return "submitted";
                case RLStatus.Xmitted:
                    return "transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        #endregion
    
        #region Receive List Item Status Translations
        /// <summary>
        /// Translates a receive list item status to a string, using uppercase where necessary
        /// </summary>
        /// <param name="rlis">Status</param>
        /// <returns>String format of status</returns>
        public static string ToUpper(RLIStatus rlis)
        {
            switch (rlis)
            {
                case RLIStatus.Arrived:
                    return "Arrived";
                case RLIStatus.VerifiedI:
                    return RecallAdjust("Verified (I)");
                case RLIStatus.VerifiedII:
                    return RecallAdjust("Verified (II)");
                case RLIStatus.Transit:
                    return "In Transit";
                case RLIStatus.Processed:
                    return "Processed";
                case RLIStatus.Removed:
                    return "Removed";
                case RLIStatus.Submitted:
                    return "Submitted";
                case RLIStatus.Xmitted:
                    return "Transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        /// <summary>
        /// Translates a receive list item status to a string, using lowercase where necessary
        /// </summary>
        /// <param name="rlis">Status</param>
        /// <returns>String format of status</returns>
        public static string ToLower(RLIStatus rlis)
        {
            switch (rlis)
            {
                case RLIStatus.Arrived:
                    return "arrived";
                case RLIStatus.VerifiedI:
                    return RecallAdjust("verified (I)");
                case RLIStatus.VerifiedII:
                    return RecallAdjust("verified (II)");
                case RLIStatus.Transit:
                    return "in transit";
                case RLIStatus.Processed:
                    return "processed";
                case RLIStatus.Removed:
                    return "Removed";
                case RLIStatus.Submitted:
                    return "submitted";
                case RLIStatus.Xmitted:
                    return "transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        #endregion

        #region Send List Status Translations
        /// <summary>
        /// Translates a send list status to a string, using uppercase where necessary
        /// </summary>
        /// <param name="sls">Status</param>
        /// <returns>String format of status</returns>
        public static string ToUpper(SLStatus sls)
        {
            switch (XmitAdjust(sls))
            {
                case SLStatus.Arrived:
                    return "Arrived";
                case SLStatus.FullyVerifiedI:
                    return RecallAdjust("Fully Verified (I)");
                case SLStatus.FullyVerifiedII:
                    return RecallAdjust("Fully Verified (II)");
                case SLStatus.Transit:
                    return "In Transit";
                case SLStatus.PartiallyVerifiedI:
                    return RecallAdjust("Partially Verified (I)");
                case SLStatus.PartiallyVerifiedII:
                    return RecallAdjust("Partially Verified (II)");
                case SLStatus.Processed:
                    return "Processed";
                case SLStatus.Submitted:
                    return "Submitted";
                case SLStatus.Xmitted:
                    return "Transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        /// <summary>
        /// Translates a send list status to a string, using lowercase where necessary
        /// </summary>
        /// <param name="sls">Status</param>
        /// <returns>String format of status</returns>
        public static string ToLower(SLStatus sls)
        {
            // Translate the status
            switch (XmitAdjust(sls))
            {
                case SLStatus.Arrived:
                    return "arrived";
                case SLStatus.FullyVerifiedI:
                    return RecallAdjust("fully verified (I)");
                case SLStatus.FullyVerifiedII:
                    return RecallAdjust("fully verified (II)");
                case SLStatus.Transit:
                    return "in transit";
                case SLStatus.PartiallyVerifiedI:
                    return RecallAdjust("partially verified (I)");
                case SLStatus.PartiallyVerifiedII:
                    return RecallAdjust("partially verified (II)");
                case SLStatus.Processed:
                    return "processed";
                case SLStatus.Submitted:
                    return "submitted";
                case SLStatus.Xmitted:
                    return "transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        #endregion

        #region Send List Item Status Translations
        /// <summary>
        /// Translates a send list item status to a string, using uppercase where necessary
        /// </summary>
        /// <param name="slis">Status</param>
        /// <returns>String format of status</returns>
        public static string ToUpper(SLIStatus slis)
        {
            switch (slis)
            {
                case SLIStatus.Arrived:
                    return "Arrived";
                case SLIStatus.VerifiedI:
                    return RecallAdjust("Verified (I)");
                case SLIStatus.VerifiedII:
                    return RecallAdjust("Verified (II)");
                case SLIStatus.Transit:
                    return "In Transit";
                case SLIStatus.Processed:
                    return "Processed";
                case SLIStatus.Removed:
                    return "Removed";
                case SLIStatus.Submitted:
                    return "Submitted";
                case SLIStatus.Xmitted:
                    return "Transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        /// <summary>
        /// Translates a send list item status to a string, using lowercase where necessary
        /// </summary>
        /// <param name="rlis">Status</param>
        /// <returns>String format of status</returns>
        public static string ToLower(SLIStatus slis)
        {
            switch (slis)
            {
                case SLIStatus.Arrived:
                    return "arrived";
                case SLIStatus.VerifiedI:
                    return RecallAdjust("verified (I)");
                case SLIStatus.VerifiedII:
                    return RecallAdjust("verified (II)");
                case SLIStatus.Transit:
                    return "in transit";
                case SLIStatus.Processed:
                    return "processed";
                case SLIStatus.Removed:
                    return "Removed";
                case SLIStatus.Submitted:
                    return "submitted";
                case SLIStatus.Xmitted:
                    return "transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        #endregion

        #region Disaster List Status Translations
        /// <summary>
        /// Translates a disaster list status to a string, using uppercase where necessary
        /// </summary>
        /// <param name="rls">Status</param>
        /// <returns>String format of status</returns>
        public static string ToUpper(DLStatus dls)
        {
            switch (XmitAdjust(dls))
            {
                case DLStatus.Processed:
                    return "Processed";
                case DLStatus.Submitted:
                    return "Submitted";
                case DLStatus.Xmitted:
                    return "Transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        /// <summary>
        /// Translates a disaster list status to a string, using lowercase where necessary
        /// </summary>
        /// <param name="rls">Status</param>
        /// <returns>String format of status</returns>
        public static string ToLower(DLStatus dls)
        {
            // Translate the status
            switch (XmitAdjust(dls))
            {
                case DLStatus.Processed:
                    return "processed";
                case DLStatus.Submitted:
                    return "submitted";
                case DLStatus.Xmitted:
                    return "transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        #endregion

        #region Disaster List Item Status Translations
        /// <summary>
        /// Translates a disaster list item status to a string, using uppercase where necessary
        /// </summary>
        /// <param name="rlis">Status</param>
        /// <returns>String format of status</returns>
        public static string ToUpper(DLIStatus dlis)
        {
            switch (dlis)
            {
                case DLIStatus.Processed:
                    return "Processed";
                case DLIStatus.Removed:
                    return "Removed";
                case DLIStatus.Submitted:
                    return "Submitted";
                case DLIStatus.Xmitted:
                    return "Transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        /// <summary>
        /// Translates a disaster list item status to a string, using lowercase where necessary
        /// </summary>
        /// <param name="dlis">Status</param>
        /// <returns>String format of status</returns>
        public static string ToLower(DLIStatus dlis)
        {
            switch (dlis)
            {
                case DLIStatus.Processed:
                    return "processed";
                case DLIStatus.Removed:
                    return "Removed";
                case DLIStatus.Submitted:
                    return "submitted";
                case DLIStatus.Xmitted:
                    return "transmitted";
                default:
                    return "<MYSTERYSTATUS>";
            }
        }
        #endregion

    }
    #endregion
}
