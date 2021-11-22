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
    /// Summary description for shipping_compare_online_reconcile.
    /// </summary>
    public class shipping_compare_online_reconcile : BasePage
    {
        #region CaseContents class
        private class CaseContents
        {
            public string CaseName = null;
            public ArrayList Contents = null;
            public CaseContents(string caseName)
            {
                CaseName = caseName;
                Contents = new ArrayList();
            }
            public CaseContents(string caseName, string serialNo) 
            {
                Contents = new ArrayList();
                Contents.Add(serialNo);
                CaseName = caseName;
            }
        }
        #endregion

        private ArrayList oChecked = null;
        private SendListDetails sl = null;
        private SendListItemCollection si = null;
        public string ListName { get {return sl.Name;} }

        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.TextBox txtSerialNum;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblItemsUnverified;
        protected System.Web.UI.WebControls.Label lblTotalItems;
        protected System.Web.UI.WebControls.Label lblItemsAdded;
        protected System.Web.UI.WebControls.DropDownList ddlChooseAction;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnGo;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.HtmlControls.HtmlGenericControl msgBoxVerify;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.HtmlControls.HtmlGenericControl msgBoxAdd;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.WebControls.Label lblLastItem;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.WebControls.Button btnLater;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divPageLinks;
        protected System.Web.UI.WebControls.ImageButton btnAdd;
        protected System.Web.UI.WebControls.Label lblSerialNo;
        protected System.Web.UI.WebControls.Label lblMoveSerial;
        protected System.Web.UI.WebControls.Button btnMove;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnVerify;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.HtmlControls.HtmlInputHidden caseSerials;
        protected System.Web.UI.HtmlControls.HtmlInputHidden totalItems;
        protected System.Web.UI.HtmlControls.HtmlInputHidden pageValues;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unverifiedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden alreadyVerified;
        protected System.Web.UI.HtmlControls.HtmlInputHidden checkThis;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.HtmlControls.HtmlInputHidden sealedTape;
        protected System.Web.UI.HtmlControls.HtmlInputHidden sealedCases;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifyStage;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifyThese;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSealedYes;
        protected System.Web.UI.WebControls.Label lblSealedTape1;
        protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divSerial;
        protected System.Web.UI.WebControls.Label lblSealedTape2;

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
            this.listLink.Click += new System.EventHandler(this.listLink_Click);
            this.btnLater.Click += new System.EventHandler(this.btnLater_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.btnMove.Click += new System.EventHandler(this.btnMove_Click);
            this.btnGo.ServerClick += new System.EventHandler(this.btnGo_ServerClick);
            this.btnOK.ServerClick += new System.EventHandler(this.btnOK_ServerClick);
            this.btnSealedYes.ServerClick += new System.EventHandler(this.btnSealedYes_ServerClick);
            this.checkThis.ServerChange += new System.EventHandler(this.checkThis_ServerChange);
            this.sealedTape.ServerChange += new System.EventHandler(this.sealedTape_ServerChange);

        }
        #endregion
	
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 31;
            this.levelTwo = LevelTwoNav.Shipping;
            this.pageTitle = "Shipping List Reconcile";
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxAdd');");
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxVerify');");
            this.SetControlAttr(this.btnMove, "onclick", "hideMsgBox('msgBoxMove');");
            // Apply bar code formatting to the serial number box
            this.BarCodeFormat(new Control[] {this.txtSerialNum}, this.btnVerify);
            // Set the default buttons for controls
            this.SetDefaultButton(this.divSerial, "btnVerify");
            // Get the list id from the querystring.  If it does not exist, redirect
            // to the list browse page.
            if (Page.IsPostBack)
            {
                sl = (SendListDetails)this.ViewState["SendList"];
            }
            else
            {
                // Initialize
                if (Request.QueryString["listNumber"] == null)
                {
                    Response.Redirect("send-lists.aspx", false);
                }
                else 
                {
                    try
                    {
                        int x = -1;
                        // Retrieve the list and place it in the viewstate
                        sl = SendList.GetSendList(Request.QueryString["listNumber"], true);
                        this.ViewState["SendList"] = sl;
                        // Set the text for the page labels
                        this.lblListNo.Text = sl.Name;
                        this.lblCaption.Text = "Shipping Compare - Online Reconcile";
                        // Get the number of items
                        SendList.GetSendListItemPage(sl.Id, 1, 32000, SLIStatus.AllValues ^ SLIStatus.Removed, SLISorts.SerialNo, out x);
                        this.lblTotalItems.Text = x.ToString();
                        this.totalItems.Value = x.ToString();
                    }
                    catch
                    {
                        Response.Redirect("send-lists.aspx", false);
                    }
                }
                // Should the remove item option be present?
                if (sl.Status >= SLStatus.FullyVerifiedI)
                    this.ddlChooseAction.Items.Remove(this.ddlChooseAction.Items.FindByValue("Remove"));
                // Set the reconcile stage
                verifyStage.Value = SendList.StatusEligible(sl.Status, SLStatus.FullyVerifiedII) ? "2" : "1";
                // Set the page values
                pageValues.Value = String.Format("1;{0}", Preference.GetItemsPerPage()); 
                // Set the tab page preference
                TabPageDefault.Update(TabPageDefaults.SendReconcileMethod, Context.Items[CacheKeys.Login], 1);
                // Fetch the list items
                this.ObtainItems();
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (!this.IsPostBack)
            {
                // Allow one-click verification?
                ListItem liv = ddlChooseAction.Items.FindByValue("Verify");
                bool ve = Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES";
                if (ve && liv == null)
                {
                    ddlChooseAction.Items.Add(new ListItem("Verify Selected", "Verify"));
                }
                else if (!ve && liv != null)
                {
                    ddlChooseAction.Items.Remove(liv);
                }
            }
            // Which tabs to we show?
            if (ProductLicense.GetProductLicense(LicenseTypes.RFID).Units == 1) 
            {
                this.twoTabs.Visible = false;
                this.threeTabs.Visible = true;
            }
            else
            {
                this.threeTabs.Visible = false;
                this.twoTabs.Visible = true;
            }
            // Set the text for the message boxes
            this.lblSerialNo.Text = this.txtSerialNum.Text;
            // Create a datatable and bind it to the grid so that the table will render
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("CaseName", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Select the text in the serial number text box
            this.SelectText(this.txtSerialNum);
            // Set the focus to the serial number box
            this.DoFocus(this.txtSerialNum);
        }
        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void ObtainItems()
        {
            try
            {
                int x = -1, i = -1, y = 0;
                SendListItemDetails s = null;
                SLIStatus slis = SLIStatus.AllValues;
                StringBuilder sb1 = new StringBuilder();    // regular serial numbers
                StringBuilder sb2 = new StringBuilder();    // cases and serial numbers
                ArrayList caseTapes = new ArrayList();
                // Get all the list items
                slis ^= SLIStatus.Processed | SLIStatus.Removed | (SendList.StatusEligible(sl.Status, SLStatus.FullyVerifiedII) ? SLIStatus.VerifiedII : SLIStatus.VerifiedI);
                SendListItemCollection slic = SendList.GetSendListItemPage(sl.Id, 1, 32000, slis, SLISorts.SerialNo, out x);
                // Remove those tapes in the verifyThese control from the collection
                foreach (string v in verifyThese.Value.Split(new char[] {';'}))
                    if (v.Length != 0 && (s = slic.Find(v)) != null)
                        slic.Remove(v);
                // If the item count is zero, redirect as necessary.  Before doing that, though, make sure
                // that there is nothing in the verifyTapes control.  If there is, we need to verify the items first.
                if (slic.Count == 0)
                {
                    try
                    {
                        // Verify any items in the control
                        VerifyControlItems();
                        // Show correct message box
                        string box = SendList.GetSendList(sl.Id, false) != null ? "msgBoxVerify" : "msgBoxEmpty";
                        ClientScript.RegisterStartupScript(GetType(), box, "<script language=javascript>showMsgBox('" + box + "')</script>");
                        ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        // Blank the unverified tapes control and table contents control
                        unverifiedTapes.Value = String.Empty;
                        tableContents.Value = String.Empty;
                        // Nothing left to do, just return
                        return;
                    }
                    catch
                    {
                        // Error in verification.  Remove everything from the verifyThese control so
                        // that they may be placed in the table contents control.
                        verifyThese.Value = String.Empty;
                    }
                }
                // Blank the sealed cases control
                sealedCases.Value = String.Empty;
                // Get all the cases on the send list
                foreach (SendListCaseDetails d in SendList.GetSendListCases(sl.Id))
                {
                    caseTapes.Add(new CaseContents(d.Name));
                    if (d.Sealed == true) sealedCases.Value += d.Name + ";";
                }
                // Create the total item serial number string
                foreach (SendListItemDetails sli in slic)
                {
                    // Record the serial number if the serial number is not currently in the verifyThese control.
                    if (verifyThese.Value.IndexOf(String.Format("{0};", sli.SerialNo)) == -1)
                    {
                        y += 1;
                        CaseContents c = null;
                        sb1.AppendFormat("{0}`{1};", sli.SerialNo, sli.CaseName);
                        // If no case, ignore
                        if (sli.CaseName.Length == 0) continue;
                        // Find the case if it is currently in the array
                        for (i = 0; i < caseTapes.Count && c == null; i++)
                            if (((CaseContents)caseTapes[i]).CaseName == sli.CaseName)
                                c = (CaseContents)caseTapes[i];
                        // If case was found, add it to the contents
                        if (c != null) c.Contents.Add(sli.SerialNo);
                    }
                }
                // Place the serial numbers in the serial number hidden control
                unverifiedTapes.Value = sb1.ToString();
                lblItemsUnverified.Text = y.ToString();
                // Create the case contents string
                for (i = 0; i < caseTapes.Count; i++)
                {
                    CaseContents c = (CaseContents)caseTapes[i];
                    sb2.AppendFormat("{0}(", c.CaseName);
                    // Insert the tapes
                    for (int j = 0; j < c.Contents.Count; j++)
                        sb2.AppendFormat("{0}{1}", (string)c.Contents[j], j != c.Contents.Count - 1 ? "," : String.Empty);
                    // Add the ending parenthesis
                    sb2.Append(");");
                }
                // Assign in to the case serial control
                this.caseSerials.Value = sb2.ToString();
                // Get the verified tapes
                sb1 = new StringBuilder();
                slis = SendList.StatusEligible(sl.Status, SLStatus.FullyVerifiedII) ? SLIStatus.VerifiedII : SLIStatus.VerifiedI;
                slic = SendList.GetSendListItemPage(sl.Id, 1, 32000, slis, SLISorts.SerialNo, out x);
                // Create the verified tapes string
                foreach (SendListItemDetails d in slic)
                    sb1.AppendFormat("{0};", d.SerialNo);
                // Set the control value
                alreadyVerified.Value = sb1.ToString();
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
        private bool CollectChecked()
        {
            int y = -1;
            oChecked = new ArrayList();
            // Get the checked objects in the table contents control
            foreach (string x in tableContents.Value.Split(new char[] {';'}))
                if (x.IndexOf("`1") != -1)
                    oChecked.Add(x.Substring(0, x.IndexOf("`")));
            // Return if no checked items
            if (oChecked.Count == 0) return false;
            // Get a fresh representation of the list items
            SLIStatus slis = SLIStatus.AllValues ^ SLIStatus.Removed;
            si = SendList.GetSendListItemPage(sl.Id, 1, 32000, slis, SLISorts.SerialNo, out y);
            // Return true
            return true;
        }
        /// <summary>
        /// Handler for the Go button
        /// </summary>
        private void btnGo_ServerClick(object sender, System.EventArgs e)
        {
            // If we have no checked items, just return
            if (CollectChecked() == false) return;
            // Perform the correct action
            switch (this.ddlChooseAction.SelectedValue)
            {
                case "Remove":
                    this.RemoveItems();
                    break;
                case "Missing":
                    this.MakeMissing();
                    break;
                case "Verify":
                    this.VerifyItems();
                    break;
                default:
                    break;
            }
        }
        /// <summary>
        /// Removes selected items from the list
        /// </summary>
        private void RemoveItems()
        {
            SendListItemDetails s = null;
            SendListItemCollection ri = new SendListItemCollection();
            // Add the checked items to the collection
            foreach (string serialNo in oChecked)
                if ((s = si.Find(serialNo)) != null)
                    ri.Add(s);
            // Remove the items from the list
            try
            {
                SendList.RemoveItems(sl.Name, ref ri);
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
        /// Verify selected list items
        /// </summary>
        private void VerifyItems()
        {
            SendListItemDetails s = null;
            SendListItemCollection vi = new SendListItemCollection();
            // Get the items from the datagrid
            foreach (string serialNo in oChecked)
                if ((s = si.Find(serialNo)) != null)
                    if (SendList.StatusEligible(s.Status, SLIStatus.VerifiedI | SLIStatus.VerifiedII))
                        vi.Add(s);
            // Verify the items
            try
            {
                SendList.Verify(sl.Name, ref vi);
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
        private void MakeMissing()
        {
            MediumDetails m = null;
            SendListItemDetails s = null;
            MediumCollection mediumCollection = new MediumCollection();
            // Get the items from the datagrid
            foreach (string serialNo in oChecked)
            {
                if ((s = si.Find(serialNo)) != null)
                {
                    if ((m = Medium.GetMedium(s.SerialNo)).Missing == false) 
                    {
                        m.Missing = true;
                        mediumCollection.Add(m);
                    }
                }
            }
            // We don't have to worry about a medium being in a sealed case, because
            // media in sealed cases cannot appear on send lists.  Sealed cases by
            // definition reside at the vault, and no tape at the vault can appear
            // on a shipping list.
            if (mediumCollection.Count != 0)
            {
                try
                {
                    Medium.Update(ref mediumCollection, 1);
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
        /// Event handler for Yes button.  Adds an item to the list.
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            try
            {
                SendListItemCollection ai = new SendListItemCollection();
                ai.Add(new SendListItemDetails(this.txtSerialNum.Text, String.Empty, String.Empty, String.Empty));
                // Call the add routine
                SendList.AddItems(ref sl, ref ai, SLIStatus.VerifiedI);
                // Increment the 'items added' label
                this.lblItemsAdded.Text = (Int32.Parse(this.lblItemsAdded.Text) + 1).ToString();
                // Modify the last scanned label
                this.lblLastItem.Text = this.txtSerialNum.Text;
                // Clear the serial number field				
                this.txtSerialNum.Text = String.Empty;
                // Refetch the data
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
        /// Event handler for move button.  Moves an item to the vault.
        /// </summary>
        private void btnMove_Click(object sender, System.EventArgs e)
        {
            try
            {
                MediumDetails m = Medium.GetMedium(this.txtSerialNum.Text);
                // If the medium does not exist, add it. Otherwise, move it.
                if (m == null)
                {
                    MediumRange[] x = null;
                    Medium.Insert(txtSerialNum.Text, txtSerialNum.Text, Locations.Vault, out x);
                }
                else if (m.Location != Locations.Vault)
                {
                    m.Missing = false;
                    m.Location = Locations.Vault;
                    Medium.Update(ref m, 1);
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Event handler for the OK button.  Redirect to ship list detail page.
        /// </summary>
        private void btnOK_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sl.Name), false);
        }
        /// <summary>
        /// Event handler for the Finish Later button.  Redirect to ship list detail page.
        /// </summary>
        private void btnLater_Click(object sender, System.EventArgs e)
        {
            try
            {
                VerifyControlItems();
                // Retrieve the items - will pop up message box if appropriate
                ObtainItems();
                // If a message box is not shown, redirect to shipping detail page
                if (!ClientScript.IsStartupScriptRegistered("msgBoxVerify") && !ClientScript.IsStartupScriptRegistered("msgBoxEmpty"))
                    Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sl.Name), false);
            }
            catch
            {
                ;
            }
        }
        /// <summary>
        /// Verifies the items in the verifyThese control
        /// </summary>
        private void VerifyControlItems()
        {
            int x = -1;
            SendListItemDetails s = null;
            SendListItemCollection vi = new SendListItemCollection();
            SLIStatus slis = SLIStatus.AllValues ^ SLIStatus.Removed;
            SendListItemCollection si = SendList.GetSendListItemPage(sl.Id, 1, 32000, slis, SLISorts.SerialNo, out x);
            // Verify the tapes in the hidden control
            string[] verifyTapes = this.verifyThese.Value.Split(new char[] {';'});
            // For each of the tapes, add them to the verify collection
            foreach (string serialNo in verifyTapes)
                if (serialNo.Length != 0)
                    if ((s = si.Find(serialNo)) != null)
                        vi.Add(s);
            // If no items, just return
            if (vi.Count == 0) return;
            // Verify the items
            try
            {
                SendList.Verify(sl.Name, ref vi);
                verifyThese.Value = String.Empty;
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                throw;
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
                throw;
            }
        }
        /// <summary>
        /// We have an unrecognized serial number.  We need to determine whether we want to ask the user
        /// to add the medium to the list, or move the medium to the vault.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void checkThis_ServerChange(object sender, System.EventArgs e)
        {
            // Verify any items in the control
            ObtainItems();
            // Check the server change
            if (sl.Status < SLStatus.FullyVerifiedI)
            {
                ClientScript.RegisterStartupScript(GetType(), "msgBoxAdd", "<script language=javascript>showMsgBox('msgBoxAdd')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
            }
            else
            {
                this.lblMoveSerial.Text = this.txtSerialNum.Text;
                ClientScript.RegisterStartupScript(GetType(), "msgBoxMove", "<script language=javascript>showMsgBox('msgBoxMove')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
            }
        }
        /// <summary>
        /// We have a tape in a sealed case while being verified at the vault....this should not be.  Prompts
        /// user to state whether he wishes to remove the tape from its sealed case or not.
        /// </summary>
        private void sealedTape_ServerChange(object sender, EventArgs e)
        {
            // Make sure we have something in the control
            if (sealedTape.Value.Length == 0) return;
            // Initialize the message box
            lblSealedTape1.Text = sealedTape.Value;
            lblSealedTape2.Text = sealedTape.Value;
            // Place the serial number in the viewstate.  We do this b/c if the user says "No" and then
            // attempts to verify the same serial number, the message box will not pop up if we do not
            // blank the sealedTape control value.
            ViewState["sealedTape"] = sealedTape.Value;
            sealedTape.Value = String.Empty;
            // Display the message box
            ClientScript.RegisterStartupScript(GetType(), "msgBoxSealed", "<script language=javascript>showMsgBox('msgBoxSealed')</script>");
            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
        }
        /// <summary>
        /// User has elected to remove tape from sealed case (see sealedTape_ServerChange)
        /// </summary>
        private void btnSealedYes_ServerClick(object sender, EventArgs e)
        {
            try
            {
                int y = -1;
                string x = (string)ViewState["sealedTape"];
                // Get the cases for the list
                SendListCaseCollection c = SendList.GetSendListCases(sl.Id);
                // Find the list item in the collection
                SendListItemCollection i = new SendListItemCollection();
                SLIStatus slis = SLIStatus.AllValues ^ SLIStatus.Removed;
                i.Add(SendList.GetSendListItemPage(sl.Id, 1, 32000, slis, SLISorts.SerialNo, out y).Find(x));
                // Remove the tape from its case
                SendList.RemoveFromCases(i, c);
                // Add the tape to the verifyThese control
                verifyThese.Value += x + ';';
                lblLastItem.Text = x;
                // Obtain the items
                ObtainItems();
                // If no tapes left unverified, click the Finish Later button
                ClientScript.RegisterStartupScript(GetType(), "laterCheck", "if (getObjectById('unverifiedTapes').value.length == 0) getObjectById('btnLater').click();");
            }
            catch (Exception ex)
            {
                DisplayErrors(this.PlaceHolder1, ex.Message);
            }
            finally
            {
                // Reset the control
                sealedTape.Value = String.Empty;
            }
        }
        /// <summary>
        /// Click event handler for list link
        /// </summary>
        private void listLink_Click(object sender, EventArgs e)
        {
            Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sl.Name), false);
        }
    }
}
