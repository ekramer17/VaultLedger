using System;
using System.Data;
using System.Text;
using System.Web.UI;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for shipping_list_reconcile_rfid.
	/// </summary>
	public class shipping_list_reconcile_rfid : BasePage
	{
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblTotalItems;
        protected System.Web.UI.WebControls.Label lblItemsUnverified;
        protected System.Web.UI.WebControls.Label lblLastItem;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DropDownList ddlChooseAction;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Button btnLater;
        protected System.Web.UI.WebControls.Label lblSerialNo;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Label lblMoveSerial;
        protected System.Web.UI.WebControls.Button btnMove;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnGo;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divPageLinks;
        protected System.Web.UI.HtmlControls.HtmlInputHidden pageValues;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifiedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unverifiedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unrecognizedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifyThese;
        protected System.Web.UI.HtmlControls.HtmlInputHidden missingTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unrecognizedCases;
        protected System.Web.UI.WebControls.Label lblItemsNotOnList;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.WebControls.TextBox txtSerialNo;
        protected System.Web.UI.WebControls.TextBox txtCaseName;
        protected System.Web.UI.WebControls.TextBox txtExpected;
        protected System.Web.UI.WebControls.Table Table1;

        #region Private Fields
        private int id = 0; // list id
        private string name = null; // list name
        private int verifyStage = 0; // verification stage
        private int maxSerial = 0;
        protected System.Web.UI.HtmlControls.HtmlGenericControl manualBox;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnVerify;
        private int formatType = 0;  // serial number editing format
        #endregion

        #region Public Properties
        public string ListName { get {return name;} }
        #endregion

		#region Web Form Designer generated code
		override protected void OnInit(EventArgs e)
		{
			//
			// CODEGEN: This call is required by the ASP.NET Web Form Designer.
			//
			InitializeComponent();
			base.OnInit(e);
		}
		
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{    

        }
		#endregion

        #region BasePage Overloads
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 31;
            this.levelTwo = LevelTwoNav.Shipping;
            this.pageTitle = "Shipping List Reconcile";
            // Security handled in the load event so that we don't have to fetch the list twice
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Make sure that the expected count text box can only contain digits
            this.SetControlAttr(this.txtExpected, "onkeyup", "digitsOnly(this);");
            // Get the list id from the querystring.  If it does not exist, redirect
            // to the list browse page.
            if (Page.IsPostBack)
            {
                id = (int)this.ViewState["Id"];
                name = (string)this.ViewState["Name"];
                verifyStage = (int)this.ViewState["Stage"];
                maxSerial = (int)this.ViewState["Length"];
                formatType = (int)this.ViewState["Format"];
            }
            else
            {
                 // Initialize
                if (Request.QueryString["listNumber"] == null)
                {
                    Response.Redirect("send-lists.aspx", true);
                }
                else 
                {
                    try
                    {
                        // Retrieve the list
                        SendListDetails sl = SendList.GetSendList(Request.QueryString["listNumber"], false);
                        // Place id and name in the viewstate
                        id = sl.Id;
                        name = sl.Name;
                        this.ViewState["Id"] = id;
                        this.ViewState["Name"] = name;
                        // Get the verification stage
                        if (SendList.StatusEligible(sl.Status, SLStatus.FullyVerifiedI))
                        {
                            verifyStage = 1;
                        }
                        else if (SendList.StatusEligible(sl.Status, SLStatus.FullyVerifiedII))
                        {
                            verifyStage = 2;
                        }
                        else 
                        {
                            Server.Transfer("shipping-list-detail.aspx?listNumber=" + sl.Name);
                        }
                        // Perform security check; only operators should be able to access stage 1, only vaulters for stage 2
                        DoSecurity(verifyStage == 1 ? Role.Operator : Role.VaultOps);
                        // Set rfid max serial length, and serial number format edit type
                        maxSerial = Int32.Parse(Preference.GetPreference(PreferenceKeys.MaxRfidSerialLength).Value);
                        formatType = (int)Preference.GetSerialEditFormat();
                        // Place information in viewstate
                        this.ViewState["Stage"] = verifyStage;
                        this.ViewState["Length"] = maxSerial;
                        this.ViewState["Format"] = formatType;
                        // Set the text for the page labels
                        this.lblListNo.Text = sl.Name;
                        this.lblCaption.Text = "Shipping Compare - RFID Reconcile";
                        // Set the page values
                        pageValues.Value = String.Format("1;{0}", Preference.GetItemsPerPage()); 
                        // Set the tab page preference
                        TabPageDefault.Update(TabPageDefaults.SendReconcileMethod, Context.Items[CacheKeys.Login], 3);
                        // Fetch the list items
                        this.ObtainItems();
                    }
                    catch
                    {
                        Response.Redirect("send-lists.aspx", true);
                    }
                }
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (!this.IsPostBack)
            {
                // Obtain the verify item if it's in the dropdown
                ListItem verifyItem = ddlChooseAction.Items.FindByValue("Verify");
                // Allow one-click verification?
                if (Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES")
                {
                    if (verifyItem == null)
                    {
                        ddlChooseAction.Items.Add(new ListItem("Verify Selected", "Verify"));
                    }
                }
                else
                {
                    if (verifyItem != null)
                    {
                        ddlChooseAction.Items.Remove(verifyItem);
                    }
                }
                // Check to see if remove item should be allowed.  Should be allowed in stage 1, not stage 2
                if (this.verifyStage != 1)
                {
                    this.ddlChooseAction.Items.Remove(this.ddlChooseAction.Items.FindByValue("Remove"));
                }
            }
            // Create a datatable and bind it to the grid so that the table will render
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("CaseName", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Embed the beep
            this.RegisterBeep(false);
            // Set the default button and formatting for the serial number and case names text box
            this.BarCodeFormat(new Control[] {this.txtSerialNo, this.txtCaseName}, this.btnVerify);
            this.SetDefaultButton(this.manualBox, "btnVerify");
//            this.SetControlAttr(this.txtSerialNo, "onkeydown", "return false;", true);  // Prevents submit button from firing
//            this.SetControlAttr(this.txtCaseName, "onkeydown", "return false;", true);  // Prevents submit button from firing
            // Register the javascript variables
            ClientScript.RegisterStartupScript(GetType(), "VARIABLES", String.Format("<script>verifyStage={0};maxSerial={1};formatType={2};</script>", verifyStage, maxSerial, formatType));
            // If no startup script has been registered, do so now (just in case we have missing tapes about which we need to notify the user
            if (!ClientScript.IsStartupScriptRegistered("STARTUP"))
            {
                ClientScript.RegisterStartupScript(GetType(), "STARTUP", "<script language=javascript>doStartup(0)</script>");
            }
        }
        #endregion

        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void ObtainItems()
        {
            try
            {
                int x = -1;
                int unverifiedCount = 0;
                StringBuilder verifiedString = new StringBuilder();
                StringBuilder unverifiedString = new StringBuilder();
                // Clear the all items and unverified items control
                this.unverifiedTapes.Value = String.Empty;
                // Obtain all the list items
                SLIStatus searchStatus = SLIStatus.AllValues ^ (SLIStatus.Processed | SLIStatus.Removed);
                SendListItemCollection listItems = SendList.GetSendListItemPage(id, 1, 32000, searchStatus, SLISorts.SerialNo, out x);
                // Set the list number total number of items
                this.lblTotalItems.Text = x.ToString();
                // Place all the verified tapes in the verified tapes control.  Place any unverified tapes that are not in
                // the verifyThese control into the unverified tapes control.
                foreach (SendListItemDetails sli in listItems)
                {
                    if (sli.Status == SLIStatus.VerifiedI || sli.Status == SLIStatus.VerifiedII)
                    {
                        verifiedString.Append(sli.SerialNo + '`' + sli.CaseName + ';');
                    }
                    else if ((";" + verifyThese.Value).IndexOf(";" + sli.SerialNo + "`") == -1)
                    {
                        unverifiedString.Append(sli.SerialNo + '`' + sli.CaseName + ';');
                        unverifiedCount += 1;
                    }
                }
                // Set the number of unverified tapes
                this.lblItemsUnverified.Text = unverifiedCount.ToString();
                // If have nothing unverified and we have nothing pending verification, then we either have
                // no more list or we are fully verified.  If no more list, display as such.  Otherwise, if we 
                // have any tapes pending verification, we have to verify them before we can declare fully verified.
                if (unverifiedString.Length == 0)
                {
                    try
                    {
                        SendListDetails sl = SendList.GetSendList(id, false);
                        // Verify any items in the controls if the list still exists
                        if (sl != null)
                        {
                            PerformPendingActions(false);
                        }
                        // Check to make sure we have no items left
                        if (verifyThese.Value.Length == 0)
                        {
                            // Show correct message box
                            ClientScript.RegisterStartupScript(GetType(), "STARTUP", String.Format("<script language=javascript>doStartup({0})</script>", sl != null ? 1 : 2));
                            // Blank the unverified tapes control and table contents control
                            unverifiedTapes.Value = String.Empty;
                            tableContents.Value = String.Empty;
                        }
                    }
                    catch
                    {
                        // Error in verification.  Remove everything from the verifyThese control, then obtain the items again
                        // so that all the items in the verifyThese control will now appear in the unverified control.
                        verifyThese.Value = String.Empty;
                        this.ObtainItems();
                    }
                }
                else
                {
                    // Assign values to controls
                    unverifiedTapes.Value = unverifiedString.ToString();
                    verifiedTapes.Value = verifiedString.ToString();
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Collects checked serial numbers
        /// </summary>
        /// <returns>True if at least one serial number was checked, else false</returns>
        private ArrayList CollectCheckedItems()
        {
            ArrayList checkedItems = new ArrayList();
            // Get the checked objects in the table contents control
            foreach (string x in tableContents.Value.Split(new char[] {';'}))
            {
                if (x.EndsWith("`1"))
                {
                    checkedItems.Add(x.Substring(0, x.IndexOf("`")));
                }
            }
            // Return the array list
            return checkedItems;
        }
        /// <summary>
        /// Handles the Go button, which could either remove items, verify items, or mark items as missing
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnGo_ServerClick(object sender, System.EventArgs e)
        {
            switch (this.ddlChooseAction.SelectedValue)
            {
                case "Remove":
                    this.RemoveCheckedItems();
                    break;
                case "Missing":
                    this.MarkCheckedMissing();
                    break;
                case "Verify":
                    this.VerifyCheckedItems();
                    break;
                default:
                    break;
            }
        }
        /// <summary>
        /// Removes selected items from the list
        /// </summary>
        private void RemoveCheckedItems()
        {
            SendListItemDetails d = null;
            SendListItemCollection removeThese = new SendListItemCollection();
            // For each serial number, get the send list item
            foreach (string serialNo in CollectCheckedItems())
            {
                if ((d = SendList.GetSendListItem(serialNo)) != null)
                {
                    removeThese.Add(d);
                }
            }
            // Remove the items from the list
            try
            {
                SendList.RemoveItems(this.ListName, ref removeThese);
                this.ObtainItems();
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Marks the checked media as missing
        /// </summary>
        private void MarkCheckedMissing()
        {
            MediumDetails m = null;
            MediumCollection missingThese = new MediumCollection();
            // Get the items from the datagrid
            foreach (string serialNo in CollectCheckedItems())
            {
                if ((m = Medium.GetMedium(serialNo)) != null) 
                {
                    if (m.Missing == false) 
                    {
                        m.Missing = true;
                        missingThese.Add(m);
                    }
                }
            }
            // We don't have to worry about a medium being in a sealed case, because
            // media in sealed cases cannot appear on send lists.  Sealed cases by
            // definition reside at the vault, and no tape at the vault can appear
            // on a shipping list.
            if (missingThese.Count != 0)
            {
                try
                {
                    Medium.Update(ref missingThese, 1);
                    this.ObtainItems();
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Verify selected list items
        /// </summary>
        private void VerifyCheckedItems()
        {
            SendListItemDetails d = null;
            SendListItemCollection verifyItems = new SendListItemCollection();
            // For each serial number, get the send list item
            foreach (string serialNo in CollectCheckedItems())
            {
                if ((d = SendList.GetSendListItem(serialNo)) != null)
                {
                    if (d != null && SendList.StatusEligible(d.Status, SLIStatus.VerifiedI | SLIStatus.VerifiedII))
                    {
                        verifyItems.Add(d);
                    }
                }
            }
            // Verify the items
            try
            {
                if (verifyItems.Count != 0)
                {
                    SendList.Verify(this.ListName, ref verifyItems);
                    this.ObtainItems();
                }
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Handles the btnLater click.  Attempts should made to (1) add unrecognized media, 
        /// then (2) switch cases, and then (3) verify media.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnLater_Click(object sender, System.EventArgs e)
        {
            try
            {
                // Perform any pending actions
                if (PerformPendingActions(true) == true)
                {
                    if (!ClientScript.IsStartupScriptRegistered("STARTUP"))
                    {
                        ClientScript.RegisterStartupScript(GetType(), "STARTUP", "<script language=javascript>doStartup(3)</script>");
                    }
                }
            }
            catch
            {
                ;
            }
        }
        /// <summary>
        /// Performs pending actions.  This would be (1) add items, (2) verify currently unverified items, 
        /// (3) switch cases for verified items, and (4) update any new cases with correct sealed statuses and return dates
        /// </summary>
        /// <returns>
        /// true on success, else false
        /// </returns>
        private bool PerformPendingActions(bool doObtain)
        {
            // Add unrecognized items
            if (AddPendingItems() == false)
            {
                return false;
            }
            // Verify items for the list (switches cases as well as verifies)
            if (VerifyPendingItems() == false)
            {
                return false;
            }
            // Switch cases for tapes in the already verified control
            if (SwitchVerifiedCases() == false)
            {
                return false;
            }
            // Updates the cases that were introduced in the add or verify
            if (UpdateInsertedCases() == false)
            {
                return false;
            }
            // Get the items if requested
            if (doObtain == true)
            {
                this.ObtainItems();
            }
            // Return
            return true;
        }
        /// <summary>
        /// Adds items to the list
        /// </summary>
        private bool AddPendingItems()
        {
            try
            {
                ArrayList removeStrings = new ArrayList();
                // Create an array list to hold the send list items
                SendListItemCollection addThese = new SendListItemCollection();
                // Split on the semicolons in the unrecognized tapes control
                foreach (string i in unrecognizedTapes.Value.Split(new char[] {';'}))
                {
                    if (i.Length != 0)
                    {
                        // Split on the backward apostrophes
                        string[] individualFields = i.Split(new char[] {'`'});
                        // Only add the tape to the list if the last field is a 1
                        if (individualFields[3] == "0") continue;
                        // Get the return date and add the tape
                        string rdate = individualFields[2].Length != 0 ? Date.ParseExact(individualFields[2]).ToString("yyyy-MM-dd") : String.Empty;
                        addThese.Add(new SendListItemDetails(individualFields[0], rdate, String.Empty, individualFields[1]));
                        // Get the medium if it exists
                        MediumDetails m = Medium.GetMedium(individualFields[0]);
                        // If it isn't null and it's missing, add it to the missing item field
                        if (m != null && m.Missing == true)
                        {
                            this.missingTapes.Value += individualFields[0] + ";";
                        }
                        else if (m != null && m.Location != Locations.Enterprise)
                        {
                            m.Location = Locations.Enterprise;
                            Medium.Update(ref m, 1);
                        }
                        // Add to strings to remove list
                        removeStrings.Add(i + ";");
                    }
                }
                // Call the add routine if we have media
                if (addThese.Count != 0)
                {
                    // Get the send list
                    SendListDetails sl = SendList.GetSendList(ListName, false);
                    // If there is no list, return false
                    if (sl == null) return false;
                    // Add the items to the list
                    SendList.AddItems(ref sl, ref addThese, SLIStatus.VerifiedI);
                    // Remove any added tapes from the unrecognized control.  We want to keep those tapes
                    // that the user has declared that he wishes to ignore so that if he scans them again,
                    // the popup will not prompt the user to add the tape again.
                    foreach (string removeThis in removeStrings)
                    {
                        this.unrecognizedTapes.Value = this.unrecognizedTapes.Value.Replace(removeThis, String.Empty);
                    }
                }
                // Return 
                return true;
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
            // Error occurred
            return false;
        }
        /// <summary>
        /// Verifies the items in the verifyThese control
        /// </summary>
        /// <returns>
        /// 0 if everything okay, else -100
        /// </returns>
        private bool VerifyPendingItems()
        {
            try
            {
                SendListItemCollection verifyTapes = new SendListItemCollection();
                SendListItemCollection updateItems = new SendListItemCollection();
                // Split the control value
                string[] controlTapes = verifyThese.Value.Split(new char[] {';'});
                // Update the items first, then do the verifies.  We have to do this
                // because the rowversions will change between updates and verifies.
                foreach (string i in controlTapes)
                {
                    if (i.Length != 0)
                    {
                        // Get the send list item
                        SendListItemDetails d = SendList.GetSendListItem(i.Substring(0, i.IndexOf("`")));
                        // If the case name is different from the original case name, then update the case name
                        if (d.CaseName != i.Substring(i.IndexOf("`") + 1))
                        {
                            d.CaseName = i.Substring(i.IndexOf("`") + 1);
                            updateItems.Add(d);
                        }
                    }
                }
                // If we have and items to update, do so
                if (updateItems.Count != 0)
                {
                    SendList.UpdateItems(ref updateItems);
                }
                // Now do the verifications
                foreach (string i in controlTapes)
                {
                    if (i.Length != 0)
                    {
                        // Get the send list item
                        SendListItemDetails d = SendList.GetSendListItem(i.Substring(0, i.IndexOf("`")));
                        // If still verification eligible, then add to the collection
                        if (d != null && SendList.StatusEligible(d.Status, SLIStatus.VerifiedI | SLIStatus.VerifiedII))
                        {
                            verifyTapes.Add(d);
                        }
                    }
                }
                // Update the send list items
                if (verifyTapes.Count != 0)
                {
                    SendList.Verify(ListName, ref verifyTapes);
                }
                // Empty the hidden control
                this.verifyThese.Value = String.Empty;
                // Return 
                return true;
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
            // Error occurred
            return false;
        }
        /// <summary>
        /// Switches cases where necessary for tapes that have already been verified
        /// </summary>
        /// <returns>
        /// true if everything okay, else false
        /// </returns>
        private bool SwitchVerifiedCases()
        {
            try
            {
                SendListItemCollection updateItems = new SendListItemCollection();
                // Update the items with the new cases
                foreach (string i in verifiedTapes.Value.Split(new char[] {';'}))
                {
                    if (i.Length != 0)
                    {
                        // Get the send list item
                        SendListItemDetails d = SendList.GetSendListItem(i.Substring(0, i.IndexOf("`")));
                        // If the case name is different from the original case name, then update the case name
                        if (d != null && d.CaseName != i.Substring(i.IndexOf("`") + 1))
                        {
                            d.CaseName = i.Substring(i.IndexOf("`") + 1);
                            updateItems.Add(d);
                        }
                    }
                }
                // If we have and items to update, do so
                if (updateItems.Count != 0)
                {
                    SendList.UpdateItems(ref updateItems);
                }
                // Return 
                return true;
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
            // Error occurred
            return false;
        }
        /// <summary>
        /// Updates the parameters for introduced cases
        /// </summary>
        private bool UpdateInsertedCases()
        {
            try
            {
                SendListCaseDetails d;
                ArrayList removeStrings = new ArrayList();
                SendListCaseCollection updateThese = new SendListCaseCollection();
                // Get the send list
                SendListDetails sl = SendList.GetSendList(ListName, false);
                // If there is no send list, return false
                if (sl == null) return false;
                // Get the send list cases.  Unrecognized cases should have been added
                // when items were either added or verified.  In other words, they
                // should exist in the database at this point.  Fetch them.
                SendListCaseCollection c = SendList.GetSendListCases(sl.Id);
                // Split on the semicolons in the unrecognized cases control
                foreach (string i in unrecognizedCases.Value.Split(new char[] {';'}))
                {
                    if (i.Length != 0)
                    {
                        // Split on the backward apostrophes
                        string[] individualFields = i.Split(new char[] {'`'});
                        // Only pay attention if the last field is a 1
                        if (individualFields[3] == "0") continue;
                        // Find the send list case in the collection
                        if ((d = c.Find(individualFields[0])) != null)
                        {
                            // Seal or unseal case
                            d.Sealed = individualFields[2] != "0";
                            // Get the return date (only if present and case is sealed)
                            d.ReturnDate = d.Sealed && individualFields[1].Length != 0 ? Date.ParseExact(individualFields[1]).ToString("yyyy-MM-dd") : String.Empty;
                            // Add the case to the update collection
                            updateThese.Add(d);
                            // Add to strings to remove list
                            removeStrings.Add(i + ";");
                        }
                    }
                }
                // Update the send list cases
                if (updateThese.Count != 0)
                {
                    SendList.UpdateCases(ref updateThese);
                    // Remove any added cases from the unrecognized control.  We want to keep those cases
                    // that the user has declared that he wishes to ignore so that if he scans them again,
                    // the popup will not prompt the user to add the case again.
                    foreach (string removeThis in removeStrings)
                    {
                        this.unrecognizedCases.Value = this.unrecognizedCases.Value.Replace(removeThis, String.Empty);
                    }
                }
                // Return 
                return true;
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
            // Error occurred
            return false;
        }
    }
}
