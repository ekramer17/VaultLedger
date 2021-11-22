using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for TMSReport.
	/// </summary>
	public class TMSReport
	{
        #region TmsItem Class
        private class TmsItem
        {
            public SendListItemDetails SndItem = null;
            public MediumDetails Medium = null;
            public string AccountNo = null;
            public string SerialNo = null;

            public TmsItem (SendListItemDetails si, string serialNo, string accountNo) 
            {
                SndItem = si;
                SerialNo = serialNo;
                AccountNo = accountNo != null ? accountNo : accountNo;
            }
        }
        #endregion

        public static string DictateString
        {
            get {return "DICTATESTRING";}
        }

        public static void CreateLists(byte[] fileText, string fileName, ref SendListCollection sendLists, ref ReceiveListCollection receiveLists, ref List<String> excludedSerials)
        {
            CreateLists(false, fileText, fileName, String.Empty, ref sendLists, ref receiveLists, ref excludedSerials);
        }

        public static void CreateLists(byte[] fileText, string fileName, string accountNo, ref SendListCollection sendLists, ref ReceiveListCollection receiveLists, ref List<String> excludedSerials)
        {
            CreateLists(false, fileText, fileName, accountNo, ref sendLists, ref receiveLists, ref excludedSerials);
        }
        
        public static void CreateLists(bool auto, byte[] fileText, string fileName, string accountNo, ref SendListCollection sendLists, ref ReceiveListCollection receiveLists, ref List<String> excludedSerials)
        {
            int i = -1, k;
            MediumDetails m = null;
            ArrayList itemList = new ArrayList();
            ArrayList os = new ArrayList();
            ArrayList oa = new ArrayList();
            ArrayList ol = new ArrayList();
            ArrayList omit1 = new ArrayList();
            ArrayList omit2 = new ArrayList();
            string doNotes = Preference.GetPreference(PreferenceKeys.TmsDataSetNotes).Value;
            bool doSkip = Preference.GetPreference(PreferenceKeys.TmsSkipTapesNotResident).Value[0] == 'Y';
            bool doAdd = Preference.GetPreference(PreferenceKeys.AllowAddsOnTMSListCreation).Value[0] == 'Y';
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (fileText == null || fileText.Length == 0)
                throw new ArgumentException("File contains no content.");
            // Initialize
            SendListItemCollection sli = null;
            ReceiveListItemCollection rli = null;
            if (sendLists != null) sendLists = new SendListCollection();
            if (receiveLists != null) receiveLists = new ReceiveListCollection();
            // Parse the report
            IParserObject p = Parser.GetParser(ParserTypes.Movement, fileText, fileName);
            if (p == null) throw new BLLException("Report was not of a recognized type");
            // Set the dictate account switch
            p.AllowAccountDictate(accountNo == TMSReport.DictateString);
            if (accountNo == TMSReport.DictateString) accountNo = String.Empty;
            // Parse the report
            p.Parse(fileText, out sli, out rli, out os, out oa, out ol);
            // If we're not adding dynamically, exclude unrecognized serial numbers
            if (doAdd == false)
            {
                for (i = sli.Count - 1; i >= 0; --i)
                {
                    if (Medium.GetMedium(sli[i].SerialNo) == null)
                    {
                        excludedSerials.Add(sli[i].SerialNo);
                        sli.RemoveAt(i);
                    }
                }

                for (i = rli.Count - 1; i >= 0; --i)
                {
                    if (Medium.GetMedium(rli[i].SerialNo) == null)
                    {
                        excludedSerials.Add(rli[i].SerialNo);
                        rli.RemoveAt(i);
                    }
                }
            }
            // Check the items for validity
            if(sli.Count == 0 && rli.Count == 0)
            {
                throw new ApplicationException("No valid serial numbers were found in the report.");
            }
            else if(sli.Count != 0 && sendLists == null)
            {
                throw new ApplicationException("Items for a shipping list were found, but only items for a receiving list should have been present."); 
            }
            else if(rli.Count != 0 && receiveLists == null)
            {
                throw new ApplicationException("Items for a receiving list were found, but only items for a shipping list should have been present."); 
            }
            // Open a connection in order to create the lists
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                IMedium mdal = MediumFactory.Create(c);
                IPatternDefaultMedium pdal = PatternDefaultMediumFactory.Create(c);
                MediumCollection mu = new MediumCollection();
                MediumCollection mi = new MediumCollection();
                // Create the lists
                try
                {
                    // Removals?
                    if (auto == true)
                    {
                        SendListItemDetails y1 = null;
                        ReceiveListItemDetails y2 = null;
                        // Remove active items
                        for (i = sli.Count - 1; i > -1; i -= 1)
                        {
                            if ((y1 = SendList.GetSendListItem(sli[i].SerialNo)) != null)
                            {
                                if (y1.Status != SLIStatus.Submitted)   // submitted will be switched to new list
                                {
                                    sli.RemoveAt(i);
                                }
                            }
                        }
                        // Remove active receive
                        for (i = rli.Count - 1; i > -1; i -= 1)
                        {
                            if ((y2 = ReceiveList.GetReceiveListItem(rli[i].SerialNo)) != null)
                            {
                                if (y2.Status != RLIStatus.Submitted)   // submitted will be switched to new list
                                {
                                    rli.RemoveAt(i);
                                }
                            }
                        }
                    }

                    // Begin a transaction
                    c.BeginTran();

                    #region Update medium accounts if allowing TMS to do so
                    // Force medium accounts where required
                    if (Preference.GetPreference(PreferenceKeys.AllowTMSAccountAssigns).Value == "YES")
                    {
                        for (i = 0; i < os.Count; i++)
                        {
                            // If no medium then insert it, else update if account or location different
                            if ((m = mdal.GetMedium((string)os[i])) == null)
                            {
                                string x = null;
                                string mediumType = null;
                                pdal.GetMediumDefaults((string)os[i], out mediumType, out x);
                                mdal.Insert(new MediumDetails((string)os[i], mediumType, (string)oa[i], (Locations)ol[i], "", ""));
                            }
                            else
                            {
                                bool update = false;
                                string account = (string)oa[i];
                                Locations loc = (Locations)ol[i];

                                if (m.Location != loc)
                                {
                                    m.Location = loc;
                                    update = true;
                                }

                                if (!String.IsNullOrWhiteSpace(account) && m.Account != account)
                                {
                                    m.Account = account;
                                    update = true;
                                }

                                if (update)
                                    mdal.Update(m);
                            }
                        }
                    }
                    #endregion

                    #region Create send lists
                    // Create the send lists
                    if (sli.Count != 0)
                    {
                        // Collect all the serial numbers
                        foreach(SendListItemDetails si in sli)
                        {
                            i = si.SerialNo.IndexOf(p.GetDictateIndicator());
                            // Get the correct serial number and account number
                            string s = i != -1 ? si.SerialNo.Substring(0,i) : si.SerialNo;
                            string a = i != -1 ? si.SerialNo.Substring(i).Replace(p.GetDictateIndicator(), "") : accountNo;
                            // Create a new item and append it to the list
                            itemList.Add(new TmsItem(si, s, a));
                        }
                        // For each medium, update the medium location if necessary.  The word of the 
                        // TMS report is law.  If the system says that a tape is offsite and the TMS 
                        // report says that it is onsite, then we must move the tape to onsite.
                        for (k = itemList.Count - 1; k > -1; k -= 1)
                        {
                            TmsItem ti = (TmsItem)itemList[k];

                            if ((ti.Medium = mdal.GetMedium(ti.SerialNo)) == null)
                            {
                                string mediumType, x;
                                // Get the medium default parameters
                                pdal.GetMediumDefaults(ti.SerialNo, out mediumType, out x);
                                // Blank the notes field if preference demands it
                                if (doNotes == "NO ACTION") ti.SndItem.Notes = String.Empty;
                                // Assign the medium to the item object and add the medium to the insert collection
                                mi.Add(ti.Medium = new MediumDetails(ti.SerialNo, mediumType, ti.AccountNo.Length != 0 ? ti.AccountNo : x, Locations.Enterprise, "", ""));
                                // If we're dictating, parse the serial number and assign to the send list item
                                if ((i = ti.SndItem.SerialNo.IndexOf(p.GetDictateIndicator())) != -1) ti.SndItem.SerialNo = ti.SerialNo;
                                // Make sure the state of the list item is new
                                ti.SndItem.ObjState = ObjectStates.New;
                            }
                            else
                            {
                                if (ti.Medium.Location != Locations.Enterprise) 
                                {
                                    if (doSkip == true) // skip if residence challenged?
                                    {
                                        omit1.Add(ti.SerialNo);
                                        itemList.RemoveAt(k);
                                        sli.RemoveAt(k);
                                        continue;
                                    }
                                    else
                                    {
                                        ti.Medium.Missing = false;
                                        ti.Medium.Location = Locations.Enterprise;
                                    }
                                }
                                // Edit the item notes according to preference
                                switch (doNotes)
                                {
                                    case "REPLACE":
                                        // Nothing need be done; item notes will overwrite medium notes
                                        break;
                                    case "APPEND":
                                        ti.SndItem.Notes = String.Format("{0} {1}", ti.Medium.Notes, ti.SndItem.Notes);
                                        break;
                                    default:
                                        ti.SndItem.Notes = String.Empty;
                                        break;
                                }
                                // We might have to force the account number
                                if ((i = ti.SndItem.SerialNo.IndexOf(p.GetDictateIndicator())) != -1)
                                {
                                    ti.Medium.Account = ti.AccountNo;
                                    // Make sure the serial number does not have the account dictation in it
                                    ti.SndItem.SerialNo = ti.SerialNo;
                                }
                                else if (accountNo.Length != 0)
                                {
                                    ti.Medium.Account = ti.AccountNo;
                                }
                                // If modified, add it to the collection of media to be updated
                                if (ti.Medium.ObjState == ObjectStates.Modified) mu.Add(ti.Medium);
                                // Make sure the state of the item is new
                                ti.SndItem.ObjState = ObjectStates.New;
                            }
                        }
                        // Update the media to be updated
                        foreach (MediumDetails m1 in mu) mdal.Update(m1);
                        // Insert each medium to be inserted
                        foreach (MediumDetails m1 in mi) mdal.Insert(m1);
                        // Items in sli should be the same as items in tmsitem list (no 
                        // need to place in new collection container), so just create the list.
                        if (sli.Count != 0)
                        {
                            sendLists.Add(SendList.Create(sli, SLIStatus.Submitted, false));
                        }
                    }
                    #endregion

                    #region Create receive lists
                    // Create the receive lists
                    if (rli.Count != 0)
                    {
                        for (i = rli.Count - 1; i > -1; i -= 1)
                        {
                            // Update the medium location if necessary.  The word of the TMS report
                            // is law.  If the system says that a tape is onsite and the TMS report
                            // says that it is offsite, then we must move the tape to offsite.
                            if ((m = Medium.GetMedium(rli[i].SerialNo)) != null)
                            {
                                if (m.Location != Locations.Vault) 
                                {
                                    if (doSkip == true)
                                    {
                                        omit2.Add(rli[i].SerialNo);
                                        rli.RemoveAt(i);
                                        continue;
                                    }
                                    else
                                    {
                                        m.Missing = false;
                                        m.Location = Locations.Vault;
                                    }
                                }
                                // Edit the item notes according to preference
                                switch (doNotes)
                                {
                                    case "REPLACE":
                                        // Nothing need be done; item notes will overwrite medium notes
                                        break;
                                    case "APPEND":
                                        rli[i].Notes = String.Format("{0} {1}", m.Notes, rli[i].Notes);
                                        break;
                                    default:
                                        rli[i].Notes = String.Empty;
                                        break;
                                }
                                // Update the medium if it has been modified
                                if (m.ObjState == ObjectStates.Modified)
                                {
                                    Medium.Update(ref m, 1);
                                }
                            }
                            // Reset state to new so that list can be created.  No itegrity violation here,
                            // as all item objects are created by parser.
                            rli[i].ObjState = ObjectStates.New;
                        }
                        // Create the receive lists
                        if (rli.Count != 0)
                        {
                            receiveLists.Add(ReceiveList.Create(rli, false));
                        }
                    }
                    #endregion

                    // Journalize the omissions
                    foreach (string s1 in omit1)
                    {
                        Medium.Journalize(s1, "Medium excluded from placement on shipping list due to residence discrepancy");
                    }

                    foreach (string s1 in omit2)
                    {
                        Medium.Journalize(s1, "Medium excluded from placement on receiving list due to residence discrepancy");
                    }

                    // Commit the transaction
                    c.CommitTran();

                    // Send out send list emails
                    if (sendLists != null)
                        foreach (SendListDetails s in sendLists)
                            SendList.SendEmail(s.Name, SLStatus.None, SLStatus.Submitted);
                    // Send out receive list emails
                    if (receiveLists != null)
                        foreach (ReceiveListDetails r in receiveLists)
                            ReceiveList.SendEmail(r.Name, RLStatus.None, RLStatus.Submitted);
                }
                catch
                {
                    c.RollbackTran();
                    receiveLists = null;
                    sendLists = null;
                    throw;
                }
            }
        }

        public static void CreateDRLists(byte[] fileText, string fileName, ref DisasterCodeListCollection disasterLists)
        {
            MediumDetails m = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (fileText == null || fileText.Length == 0)
                throw new ArgumentException("File contains no content.");
            // Initialize
            disasterLists = new DisasterCodeListCollection();
            DisasterCodeListItemCollection disasterItems;
            // Parse the report
            IParserObject parser = Parser.GetParser(ParserTypes.Disaster, fileText, fileName);
            if (parser == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            parser.Parse(fileText, out disasterItems);
            // Return if no disaster code items
            if(disasterItems.Count == 0) return;
            // Open a connection in order to create the lists
            using (IConnection dbc = ConnectionFactory.Create().Open())
            {
                // Create the lists
                try
                {
                    // Begin a transaction
                    dbc.BeginTran();
                    // Tweak the media as necessary
                    foreach(DisasterCodeListItemDetails disasterItem in disasterItems)
                    {
                        // Update the medium location if necessary.  The word of the TMS report
                        // is law, and any tape with a DR code is offsite.
                        if ((m = Medium.GetMedium(disasterItem.SerialNo)) != null && m.Location != Locations.Vault)
                        {
                            m.Location = Locations.Vault;
                            Medium.Update(ref m, 1);
                        }
                    }
                    // Create the disaster code lists
                    disasterLists.Add(DisasterCodeList.Create(disasterItems, false));
                    // Commit the transaction
                    dbc.CommitTran();
                    // Send out disaster code list emails
                    foreach (DisasterCodeListDetails d in disasterLists)
                        DisasterCodeList.SendEmail(d.Name, DLStatus.None, DLStatus.Submitted);
                }
                catch
                {
                    disasterLists = null;
                    dbc.RollbackTran();
                    throw;
                }
            }
        }
    }
}
