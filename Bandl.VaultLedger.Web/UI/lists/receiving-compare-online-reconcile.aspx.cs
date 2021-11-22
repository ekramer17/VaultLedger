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
    /// Summary description for receiving_compare_online_reconcile.
    /// </summary>
    public class receiving_compare_online_reconcile : BasePage
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
        private ReceiveListDetails rl = null;
        private ReceiveListItemCollection ri = null;
        public string ListName { get {return rl.Name;} }

        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblTotalItems;
        protected System.Web.UI.WebControls.TextBox txtSerialNum;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnVerify;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnGo;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.HtmlControls.HtmlGenericControl msgDoneReconcile;
        protected System.Web.UI.WebControls.Button btnSolo;
        protected System.Web.UI.WebControls.Button btnCase;
        protected System.Web.UI.WebControls.Label lblItemsUnverified;
        protected System.Web.UI.WebControls.Label lblLastItem;
        protected System.Web.UI.WebControls.DropDownList ddlChooseAction;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.WebControls.Button btnLater;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divPageLinks;
        protected System.Web.UI.HtmlControls.HtmlInputHidden enterGoto;
        protected System.Web.UI.WebControls.Label lblSerialNo;
        protected System.Web.UI.WebControls.Label lblItemsMoved;
        protected System.Web.UI.WebControls.Label serialLabel;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.HtmlControls.HtmlInputHidden unverifiedTapes;
        protected System.Web.UI.HtmlControls.HtmlInputHidden alreadyVerified;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifyThese;
        protected System.Web.UI.HtmlControls.HtmlInputHidden caseSerials;
        protected System.Web.UI.HtmlControls.HtmlInputHidden totalItems;
        protected System.Web.UI.HtmlControls.HtmlInputHidden pageValues;
        protected System.Web.UI.HtmlControls.HtmlInputHidden checkThis;
        protected System.Web.UI.WebControls.Label lblSerialNoAdd;
        protected System.Web.UI.WebControls.Label lblStatusNoAdd;
        protected System.Web.UI.WebControls.Button btnOkNoAdd;
        protected System.Web.UI.HtmlControls.HtmlInputHidden sealedTape;
        protected System.Web.UI.HtmlControls.HtmlInputHidden verifyStage;
        protected System.Web.UI.WebControls.Label lblSealedTape1;
        protected System.Web.UI.WebControls.Label lblSealedTape2;
        protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divSerial;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSealedYes;
        protected System.Web.UI.WebControls.Button btnAddYes;
        protected System.Web.UI.WebControls.Label lblAddSerial;

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
            this.btnSolo.Click += new System.EventHandler(this.btnSolo_Click);
            this.btnCase.Click += new System.EventHandler(this.btnCase_Click);
            this.btnGo.ServerClick += new System.EventHandler(this.btnGo_ServerClick);
            this.btnSealedYes.ServerClick += new System.EventHandler(this.btnSealedYes_ServerClick);
            this.btnOK.ServerClick += new System.EventHandler(this.btnOK_ServerClick);
            this.btnAddYes.Click += new System.EventHandler(this.btnAdd_Click);
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
            this.levelTwo = LevelTwoNav.Receiving;
            this.pageTitle = "Receiving List Reconcile";
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnAddYes, "onclick", "hideMsgBox('msgBoxAdd');");
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxMove');");
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxVerify');");
            this.SetControlAttr(this.btnSolo, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCase, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCancel, "onclick", "hideMsgBox('msgBoxCancel');");
            this.SetControlAttr(this.btnOkNoAdd, "onclick", "hideMsgBox('msgBoxCancel');");
            this.SetControlAttr(this.btnSealedYes, "onclick", "hideMsgBox('msgBoxSealed');");
            this.SetControlAttr(this.btnAddYes, "onclick", "hideMsgBox('msgBoxAdd');");
            // Apply bar code formatting to the serial number box
            this.BarCodeFormat(new Control[] {this.txtSerialNum}, this.btnVerify);
            // Set the default buttons for controls
            this.SetDefaultButton(this.divSerial, "btnVerify");
            // Get the list id from the querystring.  If it does not exist, redirect
            // to the list browse page.
            if (Page.IsPostBack)
            {
                rl = (ReceiveListDetails)this.ViewState["ReceiveList"];
            }
            else if (Request.QueryString["listNumber"] == null)
            {
                Response.Redirect("receive-lists.aspx", false);
            }
            else
            {
                try
                {
                    int x = -1;
                    // Retrieve the list and place it in the viewstate
                    rl = ReceiveList.GetReceiveList(Request.QueryString["listNumber"], true);
                    this.ViewState["ReceiveList"] = rl;
                    // Set the text for the page labels
                    this.lblListNo.Text = rl.Name;
                    this.lblCaption.Text = "Receiving Compare - Online Reconcile";
                    // Set the reconcile stage
                    verifyStage.Value = ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedII) ? "2" : "1";
                    // Get the number of items
                    ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, RLIStatus.AllValues ^ RLIStatus.Removed, RLISorts.SerialNo, out x);
                    this.lblTotalItems.Text = x.ToString();
                    this.totalItems.Value = x.ToString();
                }
                catch
                {
                    Response.Redirect("receive-lists.aspx", false);
                }
                // Set the page values
                pageValues.Value = String.Format("1;{0}", Preference.GetItemsPerPage()); 
                // Set the tab page preference
                TabPageDefault.Update(TabPageDefaults.ReceiveReconcileMethod, Context.Items[CacheKeys.Login], 1);
                // Fetch the list items
                this.ObtainItems();
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Allow one-click verification?
            if (!this.IsPostBack)
            {
                ListItem liv = ddlChooseAction.Items.FindByValue("Verify");
                bool ve = Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES";
                if (ve && liv == null)
                    ddlChooseAction.Items.Add(new ListItem("Verify Selected", "Verify"));
                else if (!ve && liv != null)
                    ddlChooseAction.Items.Remove(liv);
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
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Select the text in the serial number text box
            this.SelectText(this.txtSerialNum);
            // Set the focus to the serial number box
            this.DoFocus(this.txtSerialNum);
            // Serial number label depends on stage of list
            this.serialLabel.Text = rl.Status < RLStatus.FullyVerifiedI ? "Serial/Case Number:" : "Serial Number:";
        }
        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void ObtainItems()
        {
            try
            {
                int x = -1, i = -1, y = 0;
                ReceiveListItemDetails r = null;
                RLIStatus rlis = RLIStatus.AllValues;
                StringBuilder sb1 = new StringBuilder();    // regular serial numbers
                StringBuilder sb2 = new StringBuilder();    // cases and serial numbers
                ArrayList caseTapes = new ArrayList();
                // Get all the list items
                rlis ^= RLIStatus.Processed | RLIStatus.Removed | (ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedII) ? RLIStatus.VerifiedII : RLIStatus.VerifiedI);
                ReceiveListItemCollection rlic = ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, rlis, RLISorts.SerialNo, out x);
                // Remove those tapes in the verifyThese control from the collection
                foreach (string v in verifyThese.Value.Split(new char[] {';'}))
                    if (v.Length != 0 && (r = rlic.Find(v)) != null)
                        rlic.Remove(v);
                // If the item count is zero, redirect as necessary.  Before doing that, though, make sure
                // that there is nothing in the verifyTapes control.  If there is, we need to verify the items first.
                if (rlic.Count == 0)
                {
                    try
                    {
                        // Verify any items in the control
                        VerifyControlItems();
                        // Show correct message box
                        string box = ReceiveList.GetReceiveList(rl.Id, false) != null ? "msgBoxVerify" : "msgBoxEmpty";
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
                // Get all the sealed cases on the receive list
                foreach (ReceiveListItemDetails d in rlic)
                {
                    bool b = false;

                    if (d.CaseName.Length != 0)
                    {
                        foreach (CaseContents c in caseTapes)
                        {
                            if (c.CaseName == d.CaseName)
                            {
                                b = true;
                                break;
                            }
                        }
                        // If false, get the contents of the case
                        if (b == false)
                        {
                            caseTapes.Add(new CaseContents(d.CaseName));
                        }
                    }
                }
                // Create the total item serial number string
                foreach (ReceiveListItemDetails rli in rlic)
                {
                    // Record the serial number if the serial number is not currently in the verifyThese control.
                    if (verifyThese.Value.IndexOf(String.Format("{0};", rli.SerialNo)) == -1)
                    {
                        y += 1;
                        CaseContents c = null;
                        sb1.AppendFormat("{0}`{1};", rli.SerialNo, rli.CaseName);
//                        sb1.AppendFormat("{0};", rli.SerialNo);
                        // If no case, ignore
                        if (rli.CaseName.Length == 0) continue;
                        // Find the case if it is currently in the array
                        for (i = 0; i < caseTapes.Count && c == null; i++)
                            if (((CaseContents)caseTapes[i]).CaseName == rli.CaseName)
                                c = (CaseContents)caseTapes[i];
                        // If case was found, add it to the contents
                        if (c != null) c.Contents.Add(rli.SerialNo);
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
                rlis = ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedII) ? RLIStatus.VerifiedII : RLIStatus.VerifiedI;
                rlic = ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, rlis, RLISorts.SerialNo, out x);
                // Create the verified tapes string
                foreach (ReceiveListItemDetails d in rlic)
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
            RLIStatus rlis = RLIStatus.AllValues ^ RLIStatus.Removed;
            ri = ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, rlis, RLISorts.SerialNo, out y);
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
                case "Missing":
                    this.MakeMissing(0);
                    break;
                case "Verify":
                    this.VerifyItems();
                    break;
                default:
                    break;
            }
        }
        /// <summary>
        /// Verify selected list items
        /// </summary>
        private void VerifyItems()
        {
            ReceiveListItemDetails r = null;
            ReceiveListItemCollection vi = new ReceiveListItemCollection();
            // Get the items from the datagrid
            foreach (string serialNo in oChecked)
                if ((r = ri.Find(serialNo)) != null)
                    if (ReceiveList.StatusEligible(r.Status, RLIStatus.VerifiedI | RLIStatus.VerifiedII))
                        vi.Add(r);
            // Verify the items
            try
            {
                ReceiveList.Verify(rl.Name, ref vi);
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
        private void MakeMissing(int actionCase)
        {
            MediumDetails m = null;
            ReceiveListItemDetails r = null;
            MediumCollection mm = new MediumCollection();
            // Get the items from the datagrid
            foreach (string serialNo in oChecked)
            {
                if ((r = ri.Find(serialNo)) != null)
                {
                    if ((m = Medium.GetMedium(r.SerialNo)).Missing == false) 
                    {
                        m.Missing = true;
                        mm.Add(m);
                    }
                }
            }
            // We don't have to worry about a medium being in a sealed case, because
            // media in sealed cases cannot appear on send lists.  Sealed cases by
            // definition reside at the vault, and no tape at the vault can appear
            // on a shipping list.
            if (mm.Count != 0)
            {
                try
                {
                    if (Medium.Update(ref mm, actionCase))
                    {
                        this.ObtainItems();
                    }
                    else
                    {
                        ClientScript.RegisterStartupScript(GetType(), "msgBoxMissing", "<script language=javascript>showMsgBox('msgBoxMissing')</script>");
                        ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
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
        }
        /// <summary>
        /// Retries the medium update if there was a case integrity exception
        /// and the user selected to remove the individual tape(s) from their
        /// respective sealed cases.
        /// </summary>
        private void btnSolo_Click(object sender, System.EventArgs e)
        {
            if (CollectChecked() == true) MakeMissing(1);
        }
        /// <summary>
        /// Retries the medium update if there was a case integrity exception
        /// and the user selected to update all the media within sealed cases.
        /// </summary>
        private void btnCase_Click(object sender, System.EventArgs e)
        {
            if (CollectChecked() == true) MakeMissing(2);
        }
        /// <summary>
        /// Event handler for the OK button.  Redirect to ship list detail page.
        /// </summary>
        private void btnOK_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect(String.Format("receiving-list-detail.aspx?listNumber={0}", rl.Name), false);
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
                    Response.Redirect(String.Format("receiving-list-detail.aspx?listNumber={0}", rl.Name), false);
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
            ReceiveListItemDetails r = null;
            ReceiveListItemCollection vi = new ReceiveListItemCollection();
            RLIStatus rlis = RLIStatus.AllValues ^ RLIStatus.Removed;
            ReceiveListItemCollection xi = ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, rlis, RLISorts.SerialNo, out x);
            // Verify the tapes in the hidden control
            string[] verifyTapes = this.verifyThese.Value.Split(new char[] {';'});
            // For each of the tapes, add them to the verify collection
            foreach (string serialNo in verifyTapes)
                if (serialNo.Length != 0)
                    if ((r = xi.Find(serialNo)) != null)
                        vi.Add(r);
            // If no items, just return
            if (vi.Count == 0) return;
            // Verify the items
            try
            {
                ReceiveList.Verify(rl.Name, ref vi);
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
            // If list is >= Arrived, or if list is eligible for FullyVerified(ii) status, then no adds but moving is allowed
            // ElseIf the status is submitted or partially verified (i), then adds are allowed
            // Else cannot move and cannot add
            if (rl.Status >= RLStatus.Arrived || ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedII))
            {
                this.lblSerialNo.Text = this.txtSerialNum.Text;
                ClientScript.RegisterStartupScript(GetType(), "msgBoxMove", "<script language=javascript>showMsgBox('msgBoxMove')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
            }
            else if (rl.Status == RLStatus.Submitted || rl.Status == RLStatus.PartiallyVerifiedI)
            {
                ClientScript.RegisterStartupScript(GetType(), "msgBoxAdd", "<script language=javascript>showMsgBox('msgBoxAdd')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                //try
                //{
                //    ReceiveListItemCollection c = new ReceiveListItemCollection();
                //    c.Add(new ReceiveListItemDetails(this.txtSerialNum.Text, String.Empty));
                //    // Add the medium to the list
                //    ReceiveList.AddItems(ref rl, ref c);
                //    // Reobtain the items
                //    ObtainItems();
                //}
                //catch (CollectionErrorException ex)
                //{
                //    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                //}
                //catch (Exception ex)
                //{
                //    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                //}
            }
            else
            {
                this.lblSerialNoAdd.Text = this.txtSerialNum.Text;
                this.lblStatusNoAdd.Text = ListStatus.ToLower(rl.Status);
                ClientScript.RegisterStartupScript(GetType(), "msgBoxNoAdd", "<script language=javascript>showMsgBox('msgBoxNoAdd')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
            }
        }
        /// <summary>
        /// Adds tape to the list
        /// </summary>
        private void btnAdd_Click(object sender, System.EventArgs e)
        {
            try
            {
                ReceiveListItemCollection c = new ReceiveListItemCollection();
                c.Add(new ReceiveListItemDetails(this.txtSerialNum.Text, String.Empty));
                // Call the add routine
                ReceiveList.AddItems(ref rl, ref c);
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
        /// Adds or moves a medium to the enterprise
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            MediumCollection mu = new MediumCollection();
            // If the medium is a case, get all the media in the case
            if (SealedCase.GetSealedCase(txtSerialNum.Text) != null)
            {
                mu = SealedCase.GetResidentMedia(txtSerialNum.Text);
            }
            else
            {
                mu.Add(Medium.GetMedium(txtSerialNum.Text));
            }
            // If it exists then move it; otherwise add it to the enterprise
            if (mu.Count != 0)
            {
                try
                {
                    // Change the location
                    foreach (MediumDetails m in mu)
                        m.Location = Locations.Enterprise;
                    // Update the media
                    Medium.Update(ref mu, 1);
                    // Update the label
                    this.lblItemsMoved.Text = Convert.ToString(Int32.Parse(this.lblItemsMoved.Text) + mu.Count);
                    // Update the items
                    this.ObtainItems();
                }
                catch (CollectionErrorException)
                {
                    this.DisplayErrors(this.PlaceHolder1, mu);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
            else
            {
                try
                {
                    MediumRange[] r = null;
                    // Insert the medium
                    Medium.Insert(txtSerialNum.Text, txtSerialNum.Text, Locations.Enterprise, out r);
                    // Update the label
                    this.lblItemsMoved.Text = Convert.ToString(Int32.Parse(this.lblItemsMoved.Text) + 1);
                    // Update the items
                    this.ObtainItems();
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
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
                string x = (string)ViewState["sealedTape"];
                // Remove the tape from its case
                MediumDetails m = Medium.GetMedium(x);
                SealedCase.RemoveMedium(m);
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
            Response.Redirect(String.Format("receiving-list-detail.aspx?listNumber={0}", rl.Name), false);
        }
    }
}
