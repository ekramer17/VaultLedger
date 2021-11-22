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
	/// Summary description for receiving_list_reconcile_rfid.
	/// </summary>
	public class receiving_list_reconcile_rfid : BasePage
	{
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblTotalItems;
        protected System.Web.UI.WebControls.Label lblItemsUnverified;
        protected System.Web.UI.WebControls.Label lblLastItem;
        protected System.Web.UI.WebControls.Label lblItemsMoved;
        protected System.Web.UI.WebControls.Label lblItemsNotOnList;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DropDownList ddlChooseAction;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnLater;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnGo;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divPageLinks;
        protected System.Web.UI.HtmlControls.HtmlInputHidden pageValues;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifiedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unverifiedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifyThese;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unrecognizedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden missingTapes;
        protected System.Web.UI.WebControls.TextBox txtSerialNo;
        protected System.Web.UI.WebControls.PlaceHolder Placeholder1;
        protected System.Web.UI.WebControls.Table Table1;
        protected System.Web.UI.WebControls.TextBox txtExpected;
        protected System.Web.UI.HtmlControls.HtmlGenericControl manualBox;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unrecognizedCases;

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

        #region Private Fields
        private int id = 0; // list id
        private string name = null; // list name
        private int verifyStage = 0; // verification stage
        private int maxSerial = 0;   // max serial length
        private int formatType = 0;  // serial number editing format
        #endregion

        #region Public Properties
        public string ListName { get {return name;} }
        #endregion

        #region BasePage Overloads
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 31;
            this.levelTwo = LevelTwoNav.Receiving;
            this.pageTitle = "Receiving List Reconcile";
            // Security handled in the load event so that we don't have to fetch the list twice
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
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
                    Response.Redirect("receive-lists.aspx", true);
                }
                else 
                {
                    try
                    {
                        // Retrieve the list
                        ReceiveListDetails rl = ReceiveList.GetReceiveList(Request.QueryString["listNumber"], false);
                        // Place id and name in the viewstate
                        id = rl.Id;
                        name = rl.Name;
                        this.ViewState["Id"] = id;
                        this.ViewState["Name"] = name;
                        // Get the verification stage
                        if (ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedI))
                        {
                            verifyStage = 1;
                        }
                        else if (ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedII))
                        {
                            verifyStage = 2;
                        }
                        else 
                        {
                            Server.Transfer("receiving-list-detail.aspx?listNumber=" + rl.Name);
                        }
                        // Perform security check; only operators should be able to access stage 2, only vaulters for stage 1
                        DoSecurity(verifyStage == 2 ? Role.Operator : Role.VaultOps);
                        // Set the rfid max serial length, and serial number format edit type
                        maxSerial = Int32.Parse(Preference.GetPreference(PreferenceKeys.MaxRfidSerialLength).Value);
                        formatType = (int)Preference.GetSerialEditFormat();
                        // Place information in viewstate
                        this.ViewState["Stage"] = verifyStage;
                        this.ViewState["Length"] = maxSerial;
                        this.ViewState["Format"] = formatType;
                        // Set the text for the page labels
                        this.lblListNo.Text = rl.Name;
                        this.lblCaption.Text = "Receiving Compare - RFID Reconcile";
                        // Set the page values
                        pageValues.Value = String.Format("1;{0}", Preference.GetItemsPerPage()); 
                        // Set the tab page preference
                        TabPageDefault.Update(TabPageDefaults.ReceiveReconcileMethod, Context.Items[CacheKeys.Login], 3);
                        // Fetch the list items
                        this.ObtainItems();
                    }
                    catch
                    {
                        Response.Redirect("receive-lists.aspx", true);
                    }
                }
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Make sure that the expected count text box can only contain digits
            this.SetControlAttr(this.txtExpected, "onkeyup", "digitsOnly(this);");

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
            // Set the default button and formatting for the serial number text box
            this.BarCodeFormat(this.txtSerialNo);
            this.SetDefaultButton(this.manualBox, "btnVerify");
//            this.SetControlAttr(this.txtSerialNo, "onkeydown", "return false;", true);  // Prevents submit button from firing
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
                RLIStatus searchStatus = RLIStatus.AllValues ^ (RLIStatus.Processed | RLIStatus.Removed);
                ReceiveListItemCollection listItems = ReceiveList.GetReceiveListItemPage(id, 1, 32000, searchStatus, RLISorts.SerialNo, out x);
                // Set the list number total number of items
                this.lblTotalItems.Text = x.ToString();
                // Place all the verified tapes in the verified tapes control.  Place any unverified tapes that are not in
                // the verifyThese control into the unverified tapes control.
                foreach (ReceiveListItemDetails rli in listItems)
                {
                    if (rli.Status == RLIStatus.VerifiedI || rli.Status == RLIStatus.VerifiedII)
                    {
                        verifiedString.Append(rli.SerialNo + '`' + rli.CaseName + ';');
                    }
                    else if ((";" + verifyThese.Value).IndexOf(";" + rli.SerialNo + "`") == -1)
                    {
                        unverifiedString.Append(rli.SerialNo + '`' + rli.CaseName + ';');
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
                        ReceiveListDetails rl = ReceiveList.GetReceiveList(id, false);
                        // Verify any items in the controls if the list still exists
                        if (rl != null)
                        {
                            PerformPendingActions(false);
                        }
                        // Check to make sure we have no items left
                        if (verifyThese.Value.Length == 0)
                        {
                            // Show correct message box
                            ClientScript.RegisterStartupScript(GetType(), "STARTUP", String.Format("<script language=javascript>doStartup({0})</script>", rl != null ? 1 : 2));
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
                if (x.IndexOf("`1") != -1)
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
            // Any medium can be marked missing at any time.  If in a sealed case, we'll remove them individually.
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
            ReceiveListItemDetails d = null;
            ReceiveListItemCollection verifyItems = new ReceiveListItemCollection();
            // For each serial number, get the send list item
            foreach (string serialNo in CollectCheckedItems())
            {
                if ((d = ReceiveList.GetReceiveListItem(serialNo)) != null)
                {
                    if (d != null && ReceiveList.StatusEligible(d.Status, RLIStatus.VerifiedI | RLIStatus.VerifiedII))
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
                    ReceiveList.Verify(this.ListName, ref verifyItems);
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
        /// Handles the btnLater click.  Attempts should made to move unrecognized media, 
        /// then verify media.
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
        /// Performs pending actions.  This would be (1) unpack cases, (2) move items, and (3) verify items
        /// </summary>
        /// <returns>
        /// true on success, else false
        /// </returns>
        private bool PerformPendingActions(bool doObtain)
        {
            // Move unrecognized items
            if (MovePendingItems() == false)
            {
                return false;
            }
            // Verify items for the list
            if (VerifyPendingItems() == false)
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
        /// Moves unrecognized items to the enterprise
        /// </summary>
        private bool MovePendingItems()
        {
            try
            {
                // Create an array list to hold the receive list items
                ReceiveListItemCollection moveThese = new ReceiveListItemCollection();
                // Split on the semicolons in the unrecognized tapes control
                foreach (string i in unrecognizedTapes.Value.Split(new char[] {';'}))
                {
                    if (i.Length != 0)
                    {
                        // Split on the backward apostrophe
                        string[] individualFields = i.Split(new char[] {'`'});
                        // If the last field is a zero then ignore the entry
                        if (individualFields[2] == "0") continue;
                        // Get the medium if it exists
                        MediumDetails m = Medium.GetMedium(individualFields[0]);
                        // If the tape is not in the system, add it at the enterprise
                        if (m == null)
                        {
                            Medium.Insert(individualFields[0], Locations.Enterprise);
                        }
                        else
                        {
                            // Missing?
                            if (m.Missing == true)
                            {
                                this.missingTapes.Value += individualFields[0] + ";";
                                m.Missing = false;
                            }
                            // At enterprise?
                            if (m.Location != Locations.Enterprise)
                            {
                                m.Location = Locations.Enterprise;
                            }
                            // If modified, then update
                            if (m.ObjState == ObjectStates.Modified)
                            {
                                Medium.Update(ref m, 1);
                            }
                        }
                    }
                    // Note that we're not removing any tapes from the control.  This is because we don't want the popup window 
                    // to appear if the user happens to scan the tape again.  If this function runs again, any tape that was processed 
                    // here previously will not be missing, nor will it have its location at the vault, so it will not be updated.
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
        /// true if everything okay, else false
        /// </returns>
        private bool VerifyPendingItems()
        {
            try
            {
                ReceiveListItemCollection verifyTapes = new ReceiveListItemCollection();
                // Split on the semicolons in the unrecognized tapes control
                foreach (string i in verifyThese.Value.Split(new char[] {';'}))
                {
                    if (i.Length != 0)
                    {
                        // Get the receive list item
                        ReceiveListItemDetails d = ReceiveList.GetReceiveListItem(i.Substring(0,i.IndexOf("`")));
                        // If still verification eligible, then add to the collection
                        if (d != null && ReceiveList.StatusEligible(d.Status, RLIStatus.VerifiedI | RLIStatus.VerifiedII))
                        {
                            verifyTapes.Add(d);
                        }
                    }
                }
                // Update the send list items
                if (verifyTapes.Count != 0)
                {
                    ReceiveList.Verify(ListName, ref verifyTapes);
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
    }
}
