using System;
using System.Web;
using System.Threading;
using System.Collections;
using System.Web.SessionState;
using System.Security.Principal;
using Bandl.Library.VaultLedger.BLL;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.VaultLedger.Web.UI
{

    /// <summary>
    /// Summary description for AsyncRequet.
    /// 
    /// Encapsulates a asynchronous request made by a client.
    /// </summary>
    public class AsyncRequest
    {
        private AsyncRequestState ars;

        #region Constructor
        /// <summary>
        /// Default constructor
        /// </summary>
        /// <param name="ar">Reponse result on which to perform operations.</param>
        public AsyncRequest(AsyncRequestState _ars)
        {
            ars = _ars;
        }
        #endregion

        #region Private Properties
        private HttpSessionState Session
        {
            get
            {
                return ars.Context.Session;
            }
        }

        private NameValueCollection QueryString
        {
            get
            {
                return ars.Context.Request.QueryString;
            }
        }

        private DateTime MaxTime
        {
            get
            {
                return new DateTime(8999, 1, 1);
            }
        }

        private DateTime MinTime
        {
            get
            {
                return new DateTime(1799, 1, 1);
            }
        }
        #endregion

        /// <summary>
        /// Gets an object from the session cache and then removes it from the cache
        /// </summary>
        /// <param name="key">key value</param>
        /// <returns>object if present, else null</returns>
        private object GetSessionObject(string key)
        {
            object o = Session[key];
            if (o != null) Session.Remove(key);
            return o;
        }
        /// <summary>
        /// Sets the time portion of a datetime value to 23:59:59.999
        /// </summary>
        /// <param name="d">DateTime of which to max time value</param>
        /// <returns>DateTime with maxxed time value</returns>
        private DateTime SetTimeMax(DateTime d)
        {
            d = d.AddHours(23 - d.Hour);
            d = d.AddMinutes(59 - d.Minute);
            d = d.AddSeconds(59 - d.Second);
            d = d.AddMilliseconds(999 - d.Millisecond);
            // Return it
            return d;
        }
        /// <summary>
        /// Sets the time portion of a datetime value to 00:00:00.000
        /// </summary>
        /// <param name="d">DateTime of which to max time value</param>
        /// <returns>DateTime with maxxed time value</returns>
        private DateTime SetTimeMin(DateTime d)
        {
            d = d.AddHours(-d.Hour);
            d = d.AddMinutes(-d.Minute);
            d = d.AddSeconds(-d.Second);
            d = d.AddMilliseconds(-d.Millisecond);
            // Return it
            return d;
        }
        /// <summary>
        /// This is where the non-CPU-bound activity takes place
        /// </summary>
        public void ProcessRequest()
        {
            try
            {
                // Set the principal object (if we have one) and remove it
                if (Session[CacheKeys.Principal] != null)
                {
                    Thread.CurrentPrincipal = (IPrincipal)Session[CacheKeys.Principal];
                    Session.Remove(CacheKeys.Principal);
                }
                // Perform asynchronous actions
                if (QueryString["timezone"] != null)
                {
                    Session[CacheKeys.TimeZone] = Int32.Parse(QueryString["timezone"]);
                }
                else if (QueryString["issuelistalerts"] != null)
                {
                    ActionList.IssueAlerts(DateTime.UtcNow);        // Perform email alerts
                }
                else if (QueryString["purgeclearedlists"] != null)
                {
                    ActionList.PurgeClearedLists();        // Perform list purges
                }
                else if (Session[CacheKeys.WaitRequest] != null)    // All actions requiring use of the wait page
                {
                    // Get the request type from the session object, then remove it
                    RequestTypes r = (RequestTypes)Session[CacheKeys.WaitRequest];
                    Session.Remove(CacheKeys.WaitRequest);
                    // Depending on the request type, execute the action
                    switch (r)
                    {
                        case RequestTypes.AuditTrailPrune:
                            AuditTrail.CleanAuditTrail();
                            break;
                        case RequestTypes.InventoryReconcile:
                            CompareInventory(QueryString["download"], QueryString["i"]);
                            break;
                        case RequestTypes.PrintDLBrowse:
                            GetDLBrowsePrint();
                            break;
                        case RequestTypes.PrintDLDetail:
                            GetDLDetailPrint(Int32.Parse(QueryString["id"]));
                            break;
                        case RequestTypes.PrintRLBrowse:
                            GetRLBrowsePrint();
                            break;
                        case RequestTypes.PrintRLDetail:
                            GetRLDetailPrint(Int32.Parse(QueryString["id"]));
                            break;
                        case RequestTypes.PrintSLBrowse:
                            GetSLBrowsePrint();
                            break;
                        case RequestTypes.PrintSLDetail:
                            GetSLDetailPrint(Int32.Parse(QueryString["id"]));
                            break;
                        case RequestTypes.PrintFindMedia:
                            GetFindMediaPage();
                            break;
                        case RequestTypes.PrintMediumDetail:
                            GetMediumDetailPage(QueryString["s"]);
                            break;
                        case RequestTypes.PrintInventory:
                            GetInventoryDiscrepancies();
                            break;
                        case RequestTypes.PrintDLReport:
                            CreateDisasterReport(QueryString["sd"], QueryString["ed"], QueryString["st"], QueryString["ac"]);
                            break;
                        case RequestTypes.PrintRLReport:
                            CreateReceiveReport(QueryString["sd"], QueryString["ed"], QueryString["st"], QueryString["ac"]);
                            break;
                        case RequestTypes.PrintSLReport:
                            CreateSendReport(QueryString["sd"], QueryString["ed"], QueryString["st"], QueryString["ac"]);
                            break;
                        case RequestTypes.PrintMediumReport:
                            CreateMediumReport(QueryString["rd1"], QueryString["rd2"]);
                            break;
                        case RequestTypes.PrintAuditReport:
                            CreateAuditorReport(QueryString["sd"], QueryString["ed"], QueryString["l"], QueryString["s"]);
                            break;
                        case RequestTypes.PrintOtherReport:
                            CreateOtherReport(QueryString["r"]);
                            break;
                        default:
                            break;
                    }
                }
            }
            catch (Exception e)
            {
                Session[CacheKeys.Exception] = e;
            }
            finally
            {
                ars.Complete(); // Tell asp.net that the request is complete
            }
        }

        #region Process Methods
        /// <summary>
        /// Compare inventory, download if requested
        /// </summary>
        private void CompareInventory(string download, string accounts)
        {
			ArrayList[] s1 = null;
			ArrayList[] n1 = null;
			// Download inventory or parse batch file byte stream if requested
            if ("1".CompareTo(download) == 0)
            {
                foreach (string i1 in accounts.Split(new char[] {','}))
                {
                    switch (Configurator.XmitMethod)
                    {
                        case "RECALLSERVICE":
                            Inventory.DownloadInventory(Account.GetAccount(Convert.ToInt32(i1)).Name, Vendors.Recall);
                            break;
                        case "IRONMOUNTAINSERVICE":
                            Inventory.DownloadInventory(Account.GetAccount(Convert.ToInt32(i1)).Name, Vendors.IronMountain);
                            break;
                        case "VYTALRECORDSSERVICE":
                            Inventory.DownloadInventory(Account.GetAccount(Convert.ToInt32(i1)).Name, Vendors.VytalRecords);
                            break;
                    }
                }
            }
            else if ("0".CompareTo(download) == 0)
            {
                string[] a1 = null;
                accounts = String.Empty;
                AccountDetails m1 = null;
				Inventory.UploadInventory((byte[])GetSessionObject(CacheKeys.Object), out s1, out n1, out a1);
                // Retrieve accounts
                AccountCollection c1 = Account.GetAccounts(false);
                // Resolve accounts to id numbers
                for (int i = 0; i < a1.Length; i += 1)
                {
                    if ((m1 = c1.Find(a1[i])) == null)
                    {
                        throw new ApplicationException("Account " + a1[i] + " does not exist");
                    }
                    else
                    {
                        accounts += String.Format("{0}{1}", i != 0 ? "," : String.Empty, m1.Id);
                    }
                }
            }
            // Compare the inventory
            PreferenceDetails p = Preference.GetPreference(PreferenceKeys.AllowAddsOnReconcile);
            Inventory.CompareInventories(accounts, p.Value == "YES" || p.Value == "TRUE");
			// Add notes?
			if (n1 != null)
			{
				Hashtable h1 = new Hashtable();
				String p1 = Preference.GetPreference(PreferenceKeys.TmsDataSetNotes).Value;
				// Take action?
				if (p1 == "APPEND" || p1 == "REPLACE")
				{
					for (int i = 0; i < s1.Length; i++)
					{
						String[] s2 = (String[])s1[i].ToArray(typeof(String));
						String[] n2 = (String[])n1[i].ToArray(typeof(String)); 

						for (int y = 0; y < s2.Length; y += 1)
						{
							if (n2[y].Length != 0)
							{
								if (!h1.ContainsKey(n2[y])) h1[n2[y]] = new ArrayList();
								// Add serial number
								((ArrayList)h1[n2[y]]).Add(s2[y]);
							}
						}
					}
					// Get hash table enumerator
					IDictionaryEnumerator e1 = h1.GetEnumerator();
					// Update the notes
					while (e1.MoveNext())
					{
						Medium.DoNotes((String[])((ArrayList)e1.Value).ToArray(typeof(String)), (String)e1.Key, p1 == "REPLACE");
					}
				}
			}
		}
        /// <summary>
        /// Get the disaster code list object for printing
        /// </summary>
        private void GetDLBrowsePrint()
        {
            int lc;
            DLSorts order = DLSorts.ListName;
            ars.Context.Session[CacheKeys.PrintSource] = PrintSources.DisasterCodeListsPage;
            ars.Context.Session[CacheKeys.PrintObjects] = new object[] {DisasterCodeList.GetDisasterCodeListPage(1, Int32.MaxValue, order, out lc)};
        }
        /// <summary>
        /// Get the disaster code list items for printing
        /// </summary>
        private void GetDLDetailPrint(int id)
        {
            int lc;
            DLISorts order = DLISorts.SerialNo;
            DisasterCodeListDetails dl = DisasterCodeList.GetDisasterCodeList(id, false);
            DisasterCodeListItemCollection dli = DisasterCodeList.GetDisasterCodeListItemPage(id, 1, Int32.MaxValue, DLIStatus.AllValues ^ DLIStatus.Removed, order, out lc);
            // Create print objects and open print page
            ars.Context.Session[CacheKeys.PrintSource] = PrintSources.DisasterCodeListDetailPage;
            ars.Context.Session[CacheKeys.PrintObjects] = new object[] {dl, dli};
        }
        /// <summary>
        /// Get the receive list object for printing
        /// </summary>
        private void GetRLBrowsePrint()
        {
            int lc;
            RLSorts order = RLSorts.ListName;
            Session[CacheKeys.PrintSource] = PrintSources.ReceiveListsPage;
            Session[CacheKeys.PrintObjects] = new object[] {ReceiveList.GetReceiveListPage(1, Int32.MaxValue, order, out lc)};
        }
        /// <summary>
        /// Get the receive list items for printing
        /// </summary>
        private void GetRLDetailPrint(int id)
        {
            int lc;
            RLISorts order = RLISorts.SerialNo;
            ReceiveListDetails rl = ReceiveList.GetReceiveList(id, false);
            ReceiveListItemCollection rli = ReceiveList.GetReceiveListItemPage(id, 1, Int32.MaxValue, RLIStatus.AllValues ^ RLIStatus.Removed, order, out lc);
            // Replace medium type with typecode?
            if (Configurator.ProductType == "RECALL")
            {
                MediumTypeCollection c1 = MediumType.GetMediumTypes(false);
                for (int i = 0; i < rli.Count; i += 1)
                {
                    rli[i].MediumType = c1.Find(rli[i].MediumType, false).RecallCode;
                }
            }
            // Create print objects and open print page
            Session[CacheKeys.PrintSource] = PrintSources.ReceiveListDetailPage;
            Session[CacheKeys.PrintObjects] = new object[] {rl, rli};
        }
        /// <summary>
        /// Get the send list object for printing
        /// </summary>
        private void GetSLBrowsePrint()
        {
            int lc;
            SLSorts order = SLSorts.ListName;
            Session[CacheKeys.PrintSource] = PrintSources.SendListsPage;
            Session[CacheKeys.PrintObjects] = new object[] {SendList.GetSendListPage(1, Int32.MaxValue, order, out lc)};
        }
        /// <summary>
        /// Get the send list items for printing
        /// </summary>
        private void GetSLDetailPrint(int id)
        {
            int lc;
            SLISorts order = SLISorts.SerialNo;
            SendListDetails sl = SendList.GetSendList(id, false);
            SendListItemCollection sli = SendList.GetSendListItemPage(id, 1, Int32.MaxValue, SLIStatus.AllValues ^ SLIStatus.Removed, order, out lc);
            // Replace medium type with typecode?
            if (Configurator.ProductType == "RECALL")
            {
                MediumTypeCollection c1 = MediumType.GetMediumTypes(false);
                for (int i = 0; i < sli.Count; i += 1)
                {
                    sli[i].MediumType = c1.Find(sli[i].MediumType, false).RecallCode;
                }
            }
            // Create print objects and open print page
            Session[CacheKeys.PrintSource] = PrintSources.SendListDetailPage;
            Session[CacheKeys.PrintObjects] = new object[] {sl, sli};
        }
        /// <summary>
        /// Get the medium collection for printing
        /// </summary>
        private void GetFindMediaPage()
        {
            int x = 0;
            MediumFilter m = (MediumFilter)GetSessionObject(CacheKeys.Object);
            MediumCollection c = Medium.GetMediumPage(1, Int32.MaxValue, m, MediumSorts.Serial, out x);
            // Do not let user print more than 3000 records
            if (x <= 7500)
            {
                Session[CacheKeys.PrintSource] = PrintSources.FindMediaPage;
                Session[CacheKeys.PrintObjects] = new object[] {c};
            }
            else
            {
                throw new NoPrintDataException("A maximum of 7500 records may be printed at one time.&nbsp;&nbsp;Please narrow your search.");
            }
        }
        /// <summary>
        /// Get the medium collection for printing
        /// </summary>
        private void GetMediumDetailPage(string serialNo)
        {
            // Get the current array list; we must add audit collection to it
            ArrayList x = new ArrayList((object[])Session[CacheKeys.PrintObjects]);
            // Get the audit collection and add it to the arraylist
            x.Add(AuditTrail.GetMediumTrail(serialNo));
            // Replace session object
            Session[CacheKeys.PrintObjects] = (object[])x.ToArray(typeof(object));
        }
        /// <summary>
        /// Get inventory discrepancies for printing
        /// </summary>
        private void GetInventoryDiscrepancies()
        {
            int x = 0;
            // Get the accounts

            object[] o1 = (object[])GetSessionObject(CacheKeys.Object);
            InventoryConflictSorts order = InventoryConflictSorts.SerialNo;
            InventoryConflictTypes conflictType = (InventoryConflictTypes)o1[0];
            String accounts = (String)o1[1];
            // Fetch conflicts
            InventoryConflictCollection c = InventoryConflict.GetConflictPage(1, Int32.MaxValue, accounts, conflictType, order, out x);
            // Insert into session objects
            if (x <= 7500)
            {
                Session[CacheKeys.PrintSource] = PrintSources.InventoryReconcilePage;
                Session[CacheKeys.PrintObjects] = new object[] {c};
            }
            else
            {
                throw new NoPrintDataException("A maximum of 7500 records may be printed at one time.&nbsp;&nbsp;Please resolve some of your discrepancies and try again.");
            }
        }
        /// <summary>
        /// Gets the report information from the database
        /// </summary>
        /// <param name="sd">start date as string</param>
        /// <param name="ed">end date as string</param>
        /// <param name="st">list status</param>
        /// <param name="ac">account</param></param>
        private void CreateDisasterReport(string sd, string ed, string st, string ac)
        {
            int lc = 0;
            DLSorts order = DLSorts.ListName;
            // Adjust the datetimes
            DateTime de = ed.Length != 0 ? DateTime.ParseExact(ed, "yyyyMMddHHmmss", null) : MaxTime;
            DateTime ds = sd.Length != 0 ? DateTime.ParseExact(sd, "yyyyMMddHHmmss", null) : MinTime;
            // Status and account cannot be null
            st = st != null ? st : String.Empty;
            ac = ac != null ? ac : String.Empty;
            // Get the list collection
            DisasterCodeListCollection dl = DisasterCodeList.GetDisasterCodeListPage(1, Int32.MaxValue, order, out lc);
            // Run through the lists, removing where filtered out
            for (int i = dl.Count - 1; i >= 0; i--)
            {
                if (dl[i].CreateDate.CompareTo(ds) < 0 || dl[i].CreateDate.CompareTo(de) > 0) 
                {
                    dl.RemoveAt(i);
                }
                else if (st.Length != 0 && dl[i].Status.ToString() != st)
                {
                    dl.RemoveAt(i);
                }
                else if (ac.Length != 0 && dl[i].Account != ac)
                {
                    if (!dl[i].IsComposite)
                    {
                        dl.RemoveAt(i);
                    }
                    else
                    {
                        bool keepThis = false;
                        DisasterCodeListDetails d = DisasterCodeList.GetDisasterCodeList(dl[i].Id, true);
                        // If the account is found in the children, keep the list
                        for (int j = d.ChildLists.Length - 1; j > -1 && keepThis == false; j--)
                            keepThis = (d.ChildLists[j].Account == ac);
                        // If the account did not appear, remove the list
                        if (keepThis == false) dl.RemoveAt(i);
                    }
                }
            }
            // Cache for the print page
            Session[CacheKeys.PrintSource] = PrintSources.DisasterCodeListsReport;
            Session[CacheKeys.PrintObjects] = new object[] {dl};
        }
        /// <summary>
        /// Gets the report information from the database
        /// </summary>
        /// <param name="sd">start date as string</param>
        /// <param name="ed">end date as string</param>
        /// <param name="st">list status</param>
        /// <param name="ac">account</param></param>
        private void CreateReceiveReport(string sd, string ed, string st, string ac)
        {
            int lc = 0;
            RLSorts order = RLSorts.ListName;
            // Adjust the datetimes
            DateTime de = ed.Length != 0 ? DateTime.ParseExact(ed, "yyyyMMddHHmmss", null) : MaxTime;
            DateTime ds = sd.Length != 0 ? DateTime.ParseExact(sd, "yyyyMMddHHmmss", null) : MinTime;
            // Status and account cannot be null
            st = st != null ? st : String.Empty;
            ac = ac != null ? ac : String.Empty;
            // Get the list collection
            ReceiveListCollection rl = ReceiveList.GetReceiveListPage(1, Int32.MaxValue, order, out lc);
            // Run through the lists, removing where filtered out
            for (int i = rl.Count - 1; i >= 0; i--)
            {
                if (rl[i].CreateDate.CompareTo(ds) < 0 || rl[i].CreateDate.CompareTo(de) > 0) 
                {
                    rl.RemoveAt(i);
                }
                else if (st.Length != 0 && rl[i].Status.ToString() != st)
                {
                    rl.RemoveAt(i);
                }
                else if (ac.Length != 0 && rl[i].Account != ac)
                {
                    if (!rl[i].IsComposite)
                    {
                        rl.RemoveAt(i);
                    }
                    else
                    {
                        bool keepThis = false;
                        ReceiveListDetails r = ReceiveList.GetReceiveList(rl[i].Id, true);
                        // If the account is found in the children, keep the list
                        for (int j = r.ChildLists.Length - 1; j > -1 && keepThis == false; j--)
                            keepThis = (r.ChildLists[j].Account == ac);
                        // If the account did not appear, remove the list
                        if (keepThis == false) rl.RemoveAt(i);
                    }
                }
            }
            // Cache for the print page
            Session[CacheKeys.PrintSource] = PrintSources.ReceiveListsReport;
            Session[CacheKeys.PrintObjects] = new object[] {rl};
        }
        /// <summary>
        /// Gets the report information from the database
        /// </summary>
        /// <param name="sd">start date as string</param>
        /// <param name="ed">end date as string</param>
        /// <param name="st">list status</param>
        /// <param name="ac">account</param></param>
        private void CreateSendReport(string sd, string ed, string st, string ac)
        {
            int lc = 0;
            SLSorts order = SLSorts.ListName;
            // Adjust the datetimes
            DateTime de = ed.Length != 0 ? DateTime.ParseExact(ed, "yyyyMMddHHmmss", null) : MaxTime;
            DateTime ds = sd.Length != 0 ? DateTime.ParseExact(sd, "yyyyMMddHHmmss", null) : MinTime;
            // Status and account cannot be null
            st = st != null ? st : String.Empty;
            ac = ac != null ? ac : String.Empty;
            // Get the list collection
            SendListCollection sl = SendList.GetSendListPage(1, Int32.MaxValue, order, out lc);
            // Run through the lists, removing where filtered out
            for (int i = sl.Count - 1; i >= 0; i--)
            {
                if (sl[i].CreateDate.CompareTo(ds) < 0 || sl[i].CreateDate.CompareTo(de) > 0) 
                {
                    sl.RemoveAt(i);
                }
                else if (st.Length != 0 && sl[i].Status.ToString() != st)
                {
                    sl.RemoveAt(i);
                }
                else if (ac.Length != 0 && sl[i].Account != ac)
                {
                    if (!sl[i].IsComposite)
                    {
                        sl.RemoveAt(i);
                    }
                    else
                    {
                        bool keepThis = false;
                        SendListDetails s = SendList.GetSendList(sl[i].Id, true);
                        // If the account is found in the children, keep the list
                        for (int j = s.ChildLists.Length - 1; j > -1 && keepThis == false; j--)
                            keepThis = (s.ChildLists[j].Account == ac);
                        // If the account did not appear, remove the list
                        if (keepThis == false) sl.RemoveAt(i);
                    }
                }
            }
            // Cache for the print page
            Session[CacheKeys.PrintSource] = PrintSources.SendListsReport;
            Session[CacheKeys.PrintObjects] = new object[] {sl};
        }
        /// <summary>
        /// Gets the report information from the database
        /// </summary>
        private void CreateMediumReport(string rd1, string rd2)
        {
            int x = 0;
            MediumFilter f = (MediumFilter)GetSessionObject(CacheKeys.Object);
            // Adjust the return dates
            DateTime d2 = rd2.Length != 0 ? DateTime.ParseExact(rd2, "yyyyMMdd", null) : MaxTime;
            DateTime d1 = rd1.Length != 0 ? DateTime.ParseExact(rd1, "yyyyMMdd", null) : MinTime;
            // Get strings for comparison
            string ds = d1.ToString("yyyy-MM-dd");
            string de = d2.ToString("yyyy-MM-dd");
            // Get the records from the database
            MediumCollection m = Medium.GetMediumPage(1, Int32.MaxValue, f, MediumSorts.Serial, out x);
            // If we have return dates, then filter out anything that does not accord
            // with those dates.  We have to do this here because the filter can only
            // handle a single return date.  Here we have a range.
            if (rd1.Length != 0 || rd2.Length != 0)
                for (int i = m.Count - 1; i >= 0; i--)
                    if (m[i].ReturnDate.CompareTo(ds) < 0 || m[i].ReturnDate.CompareTo(de) > 0)
                        m.RemoveAt(i);
            // Cache the print objects
            if (m.Count <= 7500)
            {
                Session[CacheKeys.PrintSource] = PrintSources.FindMediaReport;
                Session[CacheKeys.PrintObjects] = new object[] {m};
            }
            else
            {
                throw new NoPrintDataException("A maximum of 7500 records may be printed at one time.&nbsp;&nbsp;Please narrow your criteria and try again.");
            }
        }
        /// <summary>
        /// Gets the report information from the database
        /// </summary>
        /// <param name="sd">start date</param>
        /// <param name="ed">end date</param>
        /// <param name="l">login</param>
        /// <param name="s">serial number</param>
        private void CreateAuditorReport(string sd, string ed, string l, string s)
        {
            int r = 0;
            // Uppercase l and s
            l = l.ToUpper();
            s = s.ToUpper();
            // Adjust the datetimes
            DateTime d2 = ed.Length != 0 ? DateTime.ParseExact(ed, "yyyyMMddHHmmss", null) : MaxTime;
            DateTime d1 = sd.Length != 0 ? DateTime.ParseExact(sd, "yyyyMMddHHmmss", null) : MinTime;
            // Get the audit trail page
            AuditTypes x = (AuditTypes)GetSessionObject(CacheKeys.Object);
            AuditTrailCollection t = AuditTrail.GetAuditTrailPage(1, Int32.MaxValue, x, d1, d2, s, l, out r);
            //// If we have a login or a serial number, we have to filter here
            //// because these fields are not used by the stored procedure.
            //if (l.Length != 0 || s.Length != 0)
            //    for (int i = t.Count - 1; i >= 0; i--)
            //        if ((l.Length != 0 && t[i].Login.ToUpper() != l) || (s.Length != 0 && t[i].ObjectName.ToUpper() != s))
            //            t.RemoveAt(i);
            // Cache the print object (print source is set in auditor-filter.aspx)
            Session[CacheKeys.PrintObjects] = new object[] {t};
        }
        /// <summary>
        /// Gets the report information from the database
        /// </summary>
        private void CreateOtherReport(string reportName)
        {
            switch (reportName)
            {
                case "BarCodeMedium":
                    Session[CacheKeys.PrintSource] = PrintSources.BarCodeMediumReport;
                    Session[CacheKeys.PrintObjects] = new object[] {PatternDefaultMedium.GetPatternDefaults()};
                    break;
                case "BarCodeCase":
                    Session[CacheKeys.PrintSource] = PrintSources.BarCodeCaseReport;
                    Session[CacheKeys.PrintObjects] = new object[] {PatternDefaultCase.GetPatternDefaultCases()};
                    break;
                case "ExternalSite":
                    Session[CacheKeys.PrintSource] = PrintSources.ExternalSiteReport;
                    Session[CacheKeys.PrintObjects] = new object[] {ExternalSite.GetExternalSites()};
                    break;
                case "UserSecurity":
                    Session[CacheKeys.PrintSource] = PrintSources.UserSecurityReport;
                    Session[CacheKeys.PrintObjects] = new object[] {Operator.GetOperators()};
                    break;
                case "Accounts":
                    Session[CacheKeys.PrintSource] = PrintSources.AccountsReport;
                    Session[CacheKeys.PrintObjects] = new object[] {Account.GetAccounts()};
                    break;
                default:
                    throw new ApplicationException("Print report called with invalid report name.");
            }
        }
        #endregion
    }
}