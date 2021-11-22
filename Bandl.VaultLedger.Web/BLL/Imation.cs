using System;
using System.Collections;
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
	/// Summary description for Imation.
	/// </summary>
	public class Imation
	{
        #region ImationItem Class
        private class ImationItem
        {
            public SendListItemDetails SndItem = null;
            public MediumDetails Medium = null;
            public string AccountNo = null;
            public string SerialNo = null;

            public ImationItem (SendListItemDetails si, string serialNo, string accountNo) 
            {
                SndItem = si;
                SerialNo = serialNo;
                AccountNo = accountNo != null ? accountNo : accountNo;
            }
        }
        #endregion

        public static string AccountDictate
        {
            get {return "DICTATESTRING";}
        }

		
        /// <summary>
        /// Creates a send list from the rfid file
        /// </summary>
        /// <param name="fileText"></param>
        /// <param name="accountNo"></param>
        /// <returns></returns>
        public static SendListCollection CreateSendList(byte[] fileText, string accountNo)
		{
            int i = -1;
            ArrayList il = new ArrayList();
            SendListCollection returnObject = new SendListCollection();
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (fileText == null || fileText.Length == 0)
                throw new ArgumentException("File contains no content.");
            // Initialize
            SendListItemCollection sli = null;
            SendListCaseCollection slc = null;
            // Get the parser
            IParserObject p = Parser.GetParser(ParserTypes.Movement, fileText);
            if (p == null) throw new BLLException("Report was not of a recognized type");
            // Set the dictate account switch
            p.AllowAccountDictate(accountNo == AccountDictate);
            if (accountNo == AccountDictate) accountNo = String.Empty;
            // Parse the report
            p.Parse(fileText, out sli, out slc);
            // Check the items for validity
            if (sli.Count == 0) return returnObject;
            // Open a connection in order to create the lists
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                IMedium mdal = MediumFactory.Create(c);
                ISendList sdal = SendListFactory.Create(c);
                MediumCollection mu = new MediumCollection();
                MediumCollection mi = new MediumCollection();
                // Create the lists
                try
                {
                    // Begin a transaction
                    c.BeginTran();
                    // Collect all the serial numbers
                    foreach(SendListItemDetails si in sli)
                    {
                        i = si.SerialNo.IndexOf(p.GetDictateIndicator());
                        // Get the correct serial number and account number
                        string s = i != -1 ? si.SerialNo.Substring(0,i) : si.SerialNo;
                        string a = i != -1 ? si.SerialNo.Substring(i).Replace(p.GetDictateIndicator(), "") : accountNo;
                        // Create a new item and append it to the list
                        il.Add(new ImationItem(si, s, a));
                    }
                    // Create a pattern default medium dal object for peeking at attributes
                    IPatternDefaultMedium pdal = PatternDefaultMediumFactory.Create(c);
                    // For each medium, update the medium location if necessary.  The word of the 
                    // RFID report is law.  If the system says that a tape is offsite and the RFID 
                    // report says that it is onsite, then we must move the tape to onsite.
                    foreach (ImationItem ii in il)
                    {
                        if ((ii.Medium = mdal.GetMedium(ii.SerialNo)) == null)
                        {
                            string mediumType, x;
                            // Get the medium default parameters
                            pdal.GetMediumDefaults(ii.SerialNo, out mediumType, out x);
                            // Assign the medium to the item object and add the medium to the insert collection
                            mi.Add(ii.Medium = new MediumDetails(ii.SerialNo, mediumType, ii.AccountNo.Length != 0 ? ii.AccountNo : x, Locations.Enterprise, "", ""));
                            // If we're dictating, parse the serial number and assign to the send list item
                            if ((i = ii.SndItem.SerialNo.IndexOf(p.GetDictateIndicator())) != -1) ii.SndItem.SerialNo = ii.SerialNo;
                            // Make sure the state of the list item is new
                            ii.SndItem.ObjState = ObjectStates.New;
                        }
                        else
                        {
                            if (ii.Medium.Location != Locations.Enterprise) 
                            {
                                ii.Medium.Missing = false;
                                ii.Medium.Location = Locations.Enterprise;
                            }
                            // We might have to force the account number
                            if ((i = ii.SndItem.SerialNo.IndexOf(p.GetDictateIndicator())) != -1)
                            {
                                ii.Medium.Account = ii.AccountNo;
                                // Make sure the serial number does not have the account dictation in it
                                ii.SndItem.SerialNo = ii.SerialNo;
                            }
                            else if (accountNo.Length != 0)
                            {
                                ii.Medium.Account = ii.AccountNo;
                            }
                            // If modified, add it to the collection of media to be updated
                            if (ii.Medium.ObjState == ObjectStates.Modified)
                            {
                                mu.Add(ii.Medium);
                            }
                            // Make sure the state of the item is new
                            ii.SndItem.ObjState = ObjectStates.New;
                        }
                    }
                    // Update the media to be updated
                    foreach (MediumDetails m in mu) mdal.Update(m);
                    // Insert each medium to be inserted
                    foreach (MediumDetails m in mi) mdal.Insert(m);
                    // Create the list
                    returnObject.Add(SendList.Create(sli, SLIStatus.Submitted, false));
                    // Update any sealed cases
                    foreach (SendListCaseDetails d in slc)
                    {
                        if (d.Sealed == true)
                        {
                            SendListCaseDetails d1 = sdal.GetSendListCase(d.Name);
                            d1.Sealed = true;
                            sdal.UpdateCase(d1);
                        }
                    }
                    // Commit the transaction
                    c.CommitTran();
                    // Send out send list emails
                    if (returnObject != null)
                        foreach (SendListDetails s in returnObject)
                            SendList.SendEmail(s.Name, SLStatus.None, SLStatus.Submitted);
                    // Return the created list(s)
                    return returnObject;
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
        }
        /// <summary>
        /// Creates a receive list from the rfid file
        /// </summary>
        /// <param name="fileText"></param>
        /// <param name="accountNo"></param>
        /// <returns></returns>
        public static ReceiveListCollection CreateReceiveList(byte[] fileText)
        {
            ReceiveListCollection returnObject = new ReceiveListCollection();
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (fileText == null || fileText.Length == 0)
                throw new ArgumentException("File contains no content.");
            // Initialize
            ReceiveListItemCollection rli = null;
            // Get the parser
            IParserObject p = Parser.GetParser(ParserTypes.Movement, fileText);
            if (p == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            p.Parse(fileText, out rli);
            // Check the items for validity
            if (rli.Count == 0) return returnObject;
            // Open a connection in order to create the lists
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    foreach(ReceiveListItemDetails ri in rli)
                    {
                        MediumDetails m = null;
                        // Update the medium location if necessary.  The word of the TMS report
                        // is law.  If the system says that a tape is onsite and the TMS report
                        // says that it is offsite, then we must move the tape to offsite.
                        if ((m = Medium.GetMedium(ri.SerialNo)) != null)
                        {
                            if (m.Location != Locations.Vault) 
                            {
                                m.Missing = false;
                                m.Location = Locations.Vault;
                            }
                            // Update the medium if it has been modified
                            if (m.ObjState == ObjectStates.Modified)
                                Medium.Update(ref m, 1);
                        }
                        // Reset state to new so that list can be created.  No itegrity violation here,
                        // as all item objects are created by parser.
                        ri.ObjState = ObjectStates.New;
                    }
                    // Create the receive lists
                    returnObject.Add(ReceiveList.Create(rli, false));
                    // Commit the transaction
                    c.CommitTran();
                    // Send out receive list emails
                    foreach (ReceiveListDetails r in returnObject)
                        ReceiveList.SendEmail(r.Name, RLStatus.None, RLStatus.Submitted);
                    // Return the list
                    return returnObject;
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
        }
        /// <summary>
        /// Creates a receive list from the rfid file
        /// </summary>
        /// <param name="fileText"></param>
        /// <param name="accountNo"></param>
        /// <returns></returns>
        public static SendListScanItemCollection GetSendScanItems(byte[] fileText)
        {
            string[] serials = null;
            string[] caseNames = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (fileText == null || fileText.Length == 0)
                throw new ArgumentException("File contains no content.");
            // Initialize
            SendListScanItemCollection returnObject = new SendListScanItemCollection();
            // Get the parser
            IParserObject p = Parser.GetParser(ParserTypes.Movement, fileText);
            if (p == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            p.Parse(fileText, out serials, out caseNames);
            // Create the send list scan items
            for (int i = 0; i < serials.Length; i++)
                returnObject.Add(new SendListScanItemDetails(serials[i], caseNames[i]));
            // Return the scan items
            return returnObject;
        }
        /// <summary>
        /// Creates a receive list from the rfid file
        /// </summary>
        /// <param name="fileText"></param>
        /// <param name="accountNo"></param>
        /// <returns></returns>
        public static ReceiveListScanItemCollection GetReceiveScanItems(byte[] fileText)
        {
            string[] serials = null;
            string[] caseNames = null;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Verify validity of data
            if (fileText == null || fileText.Length == 0)
                throw new ArgumentException("File contains no content.");
            // Initialize
            ReceiveListScanItemCollection returnObject = new ReceiveListScanItemCollection();
            // Get the parser
            IParserObject p = Parser.GetParser(ParserTypes.Movement, fileText);
            if (p == null) throw new BLLException("Report was not of a recognized type");
            // Parse the report
            p.Parse(fileText, out serials, out caseNames);
            // Create the receive list scan items
            for (int i = 0; i < serials.Length; i++)
                returnObject.Add(new ReceiveListScanItemDetails(serials[i]));
            // Return the scan items
            return returnObject;
        }
    }
}
