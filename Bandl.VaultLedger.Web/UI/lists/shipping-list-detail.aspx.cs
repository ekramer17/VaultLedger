using System;
using System.Web;
using System.Text;
using System.Globalization;
using System.Collections.Specialized;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for shipping_list_detail_template.
    /// </summary>
    public class shipping_list_detail : BasePage
    {
        private int pageNo = 1;
        private int pageTotal = 0;
        private SendListDetails sl;
        private SendListItemCollection sli;
        private string backUrl = @".\send-lists.aspx";
        private string backLeft = @"552";
        private string backCaption = "Lists";
		private SLISorts sortOrder = SLISorts.SerialNo;
		// Page controls
        protected System.Web.UI.WebControls.Button btnAdd;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.Button btnReconcile;
        protected System.Web.UI.WebControls.Button btnTransmit;
        protected System.Web.UI.WebControls.DropDownList ddlChooseAction;
        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblStatus;
        protected System.Web.UI.WebControls.Label lblCreateDate;
        protected System.Web.UI.WebControls.Label lblAccount;		
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.LinkButton FirstPage;
        protected System.Web.UI.WebControls.LinkButton PrevPage;
        protected System.Web.UI.WebControls.LinkButton NextPage;
        protected System.Web.UI.WebControls.LinkButton LastPage;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Label CurrentPage;
        protected System.Web.UI.WebControls.Label lblOf;
        protected System.Web.UI.WebControls.Label TotalPages;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.HtmlControls.HtmlInputHidden enterGoto;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divButtons;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.WebControls.Label lblTransmit;
        protected System.Web.UI.WebControls.Label lblReconciled;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.LinkButton exportLink;
        protected System.Web.UI.WebControls.DropDownList ddlCases;
        protected System.Web.UI.WebControls.TextBox createCase;
        protected System.Web.UI.HtmlControls.HtmlInputButton caseOK;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnReturnOK;
        protected System.Web.UI.WebControls.LinkButton listLink;
		protected System.Web.UI.HtmlControls.HtmlInputHidden order;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;

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
			this.enterGoto.ServerChange += new System.EventHandler(this.enterGoto_ServerChange);
			this.btnReturnOK.ServerClick += new System.EventHandler(this.btnReturnOK_ServerClick);
			this.caseOK.ServerClick += new System.EventHandler(this.caseOK_ServerClick);
			this.listLink.Click += new System.EventHandler(this.listLink_Click);
			this.exportLink.Click += new System.EventHandler(this.exportLink_Click);
			this.printLink.Click += new System.EventHandler(this.printLink_Click);
			this.btnAdd.Click += new System.EventHandler(this.btnAdd_Click);
			this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
			this.DataGrid1.ItemCommand += new System.Web.UI.WebControls.DataGridCommandEventHandler(this.DataGrid1_ItemCommand);
			this.btnReconcile.Click += new System.EventHandler(this.btnReconcile_Click);
			this.btnTransmit.Click += new System.EventHandler(this.btnTransmit_Click);
			this.btnYes.Click += new System.EventHandler(this.btnYes_Click);

		}
        #endregion
	
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 12;
            this.levelTwo = LevelTwoNav.Shipping;
			// Set order
			if (!Page.IsPostBack) order.Value = ((Int32)SLISorts.SerialNo).ToString();
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Bar code formattng on the case serial textbox
            this.BarCodeFormat(this.createCase);
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnOK,  "onclick", "hideMsgBox('msgBoxReconcile');");
            this.SetControlAttr(this.caseOK,  "onclick", "hideMsgBox('msgBoxCase');");
            this.SetControlAttr(this.btnReturnOK, "onclick", "hideMsgBox('msgBoxReturnDate');");
            this.SetControlAttr(this.ddlCases, "onchange", "caseSelect(this);");
            // Make sure that the record number text box can only contain digits
            this.SetControlAttr(this.txtPageGoto, "onkeyup", "digitsOnly(this);");
            // Make sure that the enter key changes the hidden field
            this.SetControlAttr(this.txtPageGoto, "onkeypress", "if (keyCode() == 13) document.getElementById('enterGoto').value = this.value;");
            // Get the list id from the querystring.  If it does not exist, redirect
            // to the list browse page.
            if (Page.IsPostBack)
            {
                pageNo = (int)this.ViewState["PageNo"];
                pageTotal = (int)this.ViewState["PageTotal"];
                sl = (SendListDetails)this.ViewState["ListObject"];
                sli = (SendListItemCollection)this.ViewState["ListItems"];
                backUrl = (string)ViewState["backUrl"];
                backLeft = (string)ViewState["backLeft"];
                backCaption = (string)ViewState["backCaption"];
				sortOrder = (SLISorts)ViewState["SortOrder"];
            }
            else
            {
                // Initialize page numbers
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
				// Initialize sort order
				this.ViewState["SortOrder"] = sortOrder;
                // Get the list information
                if (Request.QueryString["listNumber"] == null)
                {
                    Response.Redirect("send-lists.aspx", false);
                }
                else 
                {
                    try
                    {
                        // Retrieve the list
                        string listName = Request.QueryString["listNumber"];
                        sl = SendList.GetSendList(listName, false);
                        this.ViewState["ListObject"] = sl;
                        // Set the text for the page labels
                        this.lblListNo.Text = sl.Name;
                        this.lblCaption.Text = "Shipping List " + sl.Name;
                        this.lblCreateDate.Text = DisplayDate(sl.CreateDate, true, false);
                        this.lblAccount.Text = sl.IsComposite ? "(Composite List)" : sl.Account;
                        // Set message box labels
                        this.lblTransmit.Text = String.Format("Shipping list {0} was transmitted successfully.", sl.Name);
                        this.lblReconciled.Text = String.Format("Shipping list {0} has been fully verified.", sl.Name);
                        // Get the redirect url for the list link
                        if (Request.QueryString["backUrl"] != null)
                        {
                            backUrl = Request.QueryString["backUrl"];
                            backLeft = Request.QueryString["backLeft"];
                            backCaption = Request.QueryString["backCaption"];
                        }
                        ViewState["backUrl"] = backUrl;
                        ViewState["backLeft"] = backLeft;
                        ViewState["backCaption"] = backCaption;
                        // Fetch the list items
                        this.ObtainItems();
                    }
                    catch
                    {
                        Response.Redirect("send-lists.aspx", false);
                    }
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            this.pageTitle = this.lblCaption.Text;
            bool ve = Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES";
            // Set the back link caption
            listLink.Text = backCaption;
            SetControlAttr(listLink, "style", "left:" + backLeft + "px", false);
            // Eligiblility
            ListItem liv = this.ddlSelectAction.Items.FindByValue("Verify");
            ListItem lir = this.ddlSelectAction.Items.FindByValue("Remove");
            ListItem lic = this.ddlSelectAction.Items.FindByValue("AssignCase");
            ListItem lix = this.ddlSelectAction.Items.FindByValue("RemoveCase");
            this.btnAdd.Visible = sl.Status < SLStatus.Xmitted;
            this.btnTransmit.Visible = SendList.StatusEligible(sl, SLStatus.Xmitted);
            this.btnReconcile.Visible = SendList.StatusEligible(sl, SLStatus.FullyVerifiedI | SLStatus.FullyVerifiedII);
            // Verification eligible?
            if (ve && this.btnReconcile.Visible && liv == null)
                ddlSelectAction.Items.Add(new ListItem("Verify Selected", "Verify"));
            else if ((!ve || !this.btnReconcile.Visible) && liv != null)
                ddlSelectAction.Items.Remove(liv);
            // Item remove eligible?
            if (sl.Status <= SLStatus.FullyVerifiedI && lir == null)
                ddlSelectAction.Items.Add(new ListItem("Remove Selected", "Remove"));
            else if (sl.Status > SLStatus.FullyVerifiedI && lir != null)
                ddlSelectAction.Items.Remove(lir);
            // Assign cases eligible?
            if (sl.Status <= SLStatus.FullyVerifiedI && lic == null)
                ddlSelectAction.Items.Add(new ListItem("Assign Case", "AssignCase"));
            else if (sl.Status > SLStatus.FullyVerifiedI && lic != null)
                ddlSelectAction.Items.Remove(lic);
            // Remove cases eligible?
            if (sl.Status <= SLStatus.FullyVerifiedI && lix == null)
                ddlSelectAction.Items.Add(new ListItem("Remove Case", "RemoveCase"));
            else if (sl.Status > SLStatus.FullyVerifiedI && lix != null)
                ddlSelectAction.Items.Remove(lix);
            // Datagrid adjustments
            if (sl.Status == SLStatus.Processed)
            {
                this.DataGrid1.Columns[0].Visible = false;
                this.btnReconcile.Visible = false;
                this.btnAdd.Visible = false;
            }
            // If list is beyond full verified, editing a case should be prohibited
            this.DataGrid1.Columns[4].Visible = sl.Status <= SLStatus.FullyVerifiedI;
            this.DataGrid1.Columns[5].Visible = sl.Status > SLStatus.FullyVerifiedI;
            // If list is composite, show account column....otherwise hide it
            this.DataGrid1.Columns[6].Visible = sl.IsComposite;
            // Restrict roles other than administrators and operators from seeing
            // top controls or checkboxes in the datagrid.  For administrators
            // and operators, render check box invisible for any cleared list.
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                case Role.Operator:
                    break;  // All functions enabled
                case Role.Auditor:
                    this.DataGrid1.Columns[0].Visible = false;
                    this.divButtons.Visible = false;
                    this.btnAdd.Visible = false;
                    break;
                case Role.Viewer:
                    this.DataGrid1.Columns[0].Visible = false;
                    this.divButtons.Visible = false;
                    this.btnAdd.Visible = false;
                    this.HideExportLink();
                    break;
            }
        }
        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void ObtainItems()
        {
            try
            {
                int itemCount, pageSize = Preference.GetItemsPerPage();
                SLIStatus itemStatus = SLIStatus.AllValues ^ SLIStatus.Removed;
                sli = SendList.GetSendListItemPage(sl.Id, pageNo, pageSize, itemStatus, sortOrder, out itemCount);
                // If no items exist, then redirect to the send lists page
                if (itemCount == 0)
                {
                    Response.Redirect("send-lists.aspx", false);
                }
                else if (pageNo > (pageTotal = Convert.ToInt32(Math.Ceiling(itemCount / (double)pageSize))))
                {
                    pageNo = pageTotal;
                    sli = SendList.GetSendListItemPage(sl.Id, pageNo, pageSize, itemStatus, sortOrder, out itemCount);
                }
                // Bind the data
                DataGrid1.DataSource = sli;
                DataGrid1.DataBind();
                // Page links
                this.lnkPagePrev.Enabled  = pageNo != 1;
                this.lnkPageFirst.Enabled = pageNo != 1;
                this.lnkPageNext.Enabled  = pageNo != pageTotal;
                this.lnkPageLast.Enabled  = pageNo != pageTotal;
                this.lblPage.Text = String.Format("Page {0} of {1}", pageNo, pageTotal);
                // Update the viewstate
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
                // Refetch the list in case status has changed
                sl = SendList.GetSendList(sl.Id, false);
                this.ViewState["ListObject"] = sl;
                this.ViewState["ListItems"] = sli;
                // If the list does not exist, redirect to browse page
                if (sl == null)
                    Server.Transfer("send-lists.aspx");
                else
                    this.lblStatus.Text = StatusString(sl.Status);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Handler for page link buttons
        /// </summary>
        protected void LinkButton_Command(Object sender, CommandEventArgs e)
        {
            switch (e.CommandName.ToUpper())
            {
                case "PAGEFIRST":
                    pageNo = 1;
                    break;
                case "PAGELAST":
                    pageNo = pageTotal;
                    break;
                case "PAGENEXT":
                    pageNo += 1;
                    break;
                case "PAGEPREV":
                    pageNo -= 1;
                    break;
            }
            // Update the viewstate, then fetch the grid
            this.ViewState["PageNo"] = pageNo;
            this.ObtainItems();
        }
        /// <summary>
        /// Event handler for the Go button
        /// </summary>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Remove":
                        ClientScript.RegisterStartupScript(GetType(), "msgBoxDelete", "<script language=javascript>showMsgBox('msgBoxDelete')</script>");
                        ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        break;
                    case "AssignCase":
                        this.AssignCases();
                        break;
                    case "RemoveCase":
                        this.RemoveCases();
                        break;
                    case "ReturnDate":
                        if (ReturnDateEligible() == false) return;
                        ClientScript.RegisterStartupScript(GetType(), "msgBoxReturnDate", "<script language=javascript>showMsgBox('msgBoxReturnDate')</script>");
                        ClientScript.RegisterStartupScript(GetType(), "enableCalendar", "<script language=javascript>getObjectById('calendar').onclick = Function(\"return true;\")</script>");
                        ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        break;
                    case "Verify":
                        this.VerifyItems();
                        break;
                    case "Missing":
                        this.MakeMissing();
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Handler for the removal confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            SendListItemCollection ri = new SendListItemCollection();
            SendListItemCollection li = (SendListItemCollection)this.ViewState["ListItems"];
            // Add the checked items to the collection
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                ri.Add(li[i.ItemIndex]);
            // Remove the items from the list
            if (ri.Count != 0)
            {
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
        }
        /// <summary>
        /// Removes items from their cases
        /// </summary>
        private void RemoveCases()
        {
            try
            {
                SendListItemCollection sli = new SendListItemCollection();
                // Collect the items
                foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                    sli.Add(((SendListItemCollection)this.ViewState["ListItems"])[i.ItemIndex]);
                // Remove from the cases
                if (sli.Count != 0) 
                {
                    SendList.RemoveFromCases(sli);
                    ObtainItems();
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Verifies items checked off in the datagrid
        /// </summary>
        private void VerifyItems()
        {
            SendListItemCollection vi = new SendListItemCollection();
            SendListItemCollection li = (SendListItemCollection)this.ViewState["ListItems"];
            // Get the items from the datagrid
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                vi.Add(li[i.ItemIndex]);
            // If there are any items in the collection, verify them.  Then refetch the data.
            if (vi.Count != 0)
            {
                try
                {
                    SendList.Verify(sl.Id, ref vi);
                    this.ObtainItems();
                    // If the list is now fully verified, display the message box
                    switch (sl.Status)
                    {
                        case SLStatus.FullyVerifiedI:
                        case SLStatus.FullyVerifiedII:
                        case SLStatus.Processed:
                            ClientScript.RegisterStartupScript(GetType(), "msgBoxReconcile", "<script language=javascript>showMsgBox('msgBoxReconcile')</script>");
                            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                            break;
                        default:
                            break;
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
        /// Marks the checked media as missing
        /// </summary>
        private void MakeMissing()
        {
            MediumDetails m = null;
            MediumCollection mediumCollection = new MediumCollection();
            SendListItemCollection li = (SendListItemCollection)this.ViewState["ListItems"];
            // Get the items from the datagrid
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                if (li[i.ItemIndex].Status >= SLIStatus.VerifiedI && !SendList.StatusEligible(sl.Status, SLStatus.FullyVerifiedII))
                {
                    this.DisplayErrors(this.PlaceHolder1, "Medium " + li[i.ItemIndex].SerialNo + " may not be marked missing at this stage.&nbsp;&nbsp;It may be marked missing during verification at the vault.");
                    return;
                }
                else if ((m = Medium.GetMedium(li[i.ItemIndex].SerialNo)).Missing == false) 
                {
                    m.Missing = true;
                    mediumCollection.Add(m);
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
        /// Event handler for Add button click
        /// </summary>
        private void btnAdd_Click(object sender, System.EventArgs e)
        {
            if (sl.Status >= SLStatus.FullyVerifiedI)
                this.DisplayErrors(this.PlaceHolder1, "Items may no longer be added to this list .");
            else
                Server.Transfer(String.Format("new-list-manual-scan-step-one.aspx?listNumber={0}", sl.Name));
        }
        /// <summary>
        /// Event handler for Reconcile button click
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnReconcile_Click(object sender, System.EventArgs e)
        {
			if (SendList.StatusEligible(sl, SLStatus.Xmitted))
			{
				Server.Transfer(String.Format("shipping-list-reconcile.aspx?listNumber={0}", this.lblListNo.Text));
			}
			else if (SendList.StatusEligible(sl, SLStatus.FullyVerifiedI | SLStatus.FullyVerifiedII))
            {
                switch (TabPageDefault.GetDefault(TabPageDefaults.SendReconcileMethod, Context.Items[CacheKeys.Login]))
                {
                    case 2:
                        Server.Transfer(String.Format("shipping-list-reconcile.aspx?listNumber={0}", this.lblListNo.Text));
                        break;
                    case 3:
                        Server.Transfer(String.Format("shipping-list-reconcile-rfid.aspx?listNumber={0}", this.lblListNo.Text));
                        break;
                    default:
                        Server.Transfer(String.Format("shipping-compare-online-reconcile.aspx?listNumber={0}", this.lblListNo.Text));
                        break;
                }
            }
            else if (sl.Status == SLStatus.FullyVerifiedI || sl.Status == SLStatus.FullyVerifiedII)
            {
                this.DisplayErrors(this.PlaceHolder1, "This list already fully verified.");
            }
            else
            {
                this.DisplayErrors(this.PlaceHolder1, "List is not currently eligible to be verified.");
            }
        }
        /// <summary>
        /// Event handler for Transmit button click
        /// </summary>
        private void btnTransmit_Click(object sender, System.EventArgs e)
        {
            if (!SendList.StatusEligible(sl, SLStatus.Xmitted))
            {
                this.DisplayErrors(this.PlaceHolder1, "List is not currently eligible to be transmitted.");
            }
            else
            {
                try
                {
                    SendList.Transmit(sl);
                    // Fetch the list
                    this.ObtainItems();
                    // Popup message box
                    ClientScript.RegisterStartupScript(GetType(), "msgBoxTransmit", "<script language=javascript>showMsgBox('msgBoxTransmit')</script>");
                    ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Event handler for the hidden control field change, which tells us that we
        /// should get a new page of items.
        /// </summary>
        private void enterGoto_ServerChange(object sender, System.EventArgs e)
        {
            if (this.txtPageGoto.Text.Length != 0)
            {
                pageNo = Int32.Parse(this.txtPageGoto.Text);
                this.txtPageGoto.Text = String.Empty;
                this.ObtainItems();
            }
        }
        /// <summary>
        /// Assigns the cases for the checked items
        /// </summary>
        private void AssignCases()
        {
            ddlCases.SelectedIndex = 0;
            // Get the send list cases
            SendListCaseCollection c = SendList.GetSendListCases(sl.Id);
            // Delete all cases from the drop down
            for (int i = ddlCases.Items.Count - 1; i > 0; i -= 1) ddlCases.Items.RemoveAt(i);
            // Populate the drop down with the cases on this send list
            for (int i = 0; i < c.Count; i++)
            {
                ddlCases.Items.Add(new ListItem(c[i].Name, c[i].Name));
                if (i == 0) ddlCases.SelectedIndex = 1;
            }
            // Popup message box
            ClientScript.RegisterStartupScript(GetType(), "msgBoxCase", "<script language=javascript>showMsgBox('msgBoxCase');</script>");
            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
            // If no cases, show the new case textbox, otherwise select the top case in the dropdown
            string s = String.Format("getObjectById('createCaseSection').style.display='{0}'", c.Count != 0 ? "none" : "block");
            ClientScript.RegisterStartupScript(GetType(), "caseSection", "<script language=javascript>" + s + "</script>");
        }
        /// <summary>
        /// Button event handler for the datagrid.  The only command is to edit a case.
        /// </summary>
        private void DataGrid1_ItemCommand(object source, System.Web.UI.WebControls.DataGridCommandEventArgs e)
        {
            Server.Transfer("shipping-list-detail-edit-case.aspx?listNumber=" + sl.Name);
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintSLDetail;
            ClientScript.RegisterStartupScript(GetType(), "printWindow", String.Format("<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&id={0}&x=" + Guid.NewGuid().ToString("N") + "')</script>", sl.Id));
        }
        /// <summary>
        /// Event handler for the caseOK button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void caseOK_ServerClick(object sender, System.EventArgs e)
        {
            // Get the case name
            string c = ddlCases.SelectedIndex != 0 ? ddlCases.SelectedItem.Text : createCase.Text;
            // Make sure we have a case name
            if (c.Length == 0)
            {
                DisplayErrors(PlaceHolder1, "No case name was supplied.");
            }
            else
            {
                try
                {
                    SendListItemCollection si = new SendListItemCollection();
                    // Add the tapes to the collection
                    foreach (DataGridItem i in CollectCheckedItems(DataGrid1))
                    {
                        ((SendListItemDetails)sli[i.ItemIndex]).CaseName = c;
                        si.Add(sli[i.ItemIndex]);
                    }
                    // If we have tapes in the collection, update them
                    if (si.Count != 0) SendList.UpdateItems(ref si);
                    // Obtain the list items
                    ObtainItems();
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                }
                catch (Exception ex)
                {
                    DisplayErrors(PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Exports the current list to a file for download
        /// </summary>
        private void exportLink_Click(object sender, System.EventArgs e)
        {
            try
            {
                int c = -1;
                int f1 = 20, f2 = 15, f3 = 15;
                StringBuilder dataString = new StringBuilder();
                bool tabs = Preference.GetPreference(PreferenceKeys.ExportWithTabDelimiters).Value == "YES";
                string header1 = tabs ? "Serial Number" : "Serial Number".PadRight(f1, ' ');
                string header2 = tabs ? "Return Date" : "Return Date".PadRight(f2, ' ');
                string header3 = tabs ? "Status" : "Status".PadRight(f3, ' ');
                string header4 = "Case Number";
                string dash1 = String.Empty.PadRight(f1, '-');
                string dash2 = String.Empty.PadRight(f2, '-');
                string dash3 = String.Empty.PadRight(f3, '-');
                string dash4 = String.Empty.PadRight(15, '-');
                // Retrieve all the list items
                SLIStatus x = SLIStatus.AllValues ^ SLIStatus.Removed;
                SendListItemCollection li = SendList.GetSendListItemPage(sl.Id, 1, 32000, x, SLISorts.SerialNo, out c);
                // Create the top headers
                string title = String.Format("{0} Shipping List {1}", Configurator.ProductName, sl.Name);
                dataString.AppendFormat("{0}{1}{2}{1}", title, Environment.NewLine, String.Empty.PadRight(title.Length,'-'));
                dataString.AppendFormat("Create Date: {0}{1}", DisplayDate(sl.CreateDate), Environment.NewLine);
                dataString.AppendFormat("List Status: {0}{1}", ListStatus.ToUpper(sl.Status), Environment.NewLine);
                dataString.AppendFormat("Account No.: {0}{1}", sl.IsComposite ? "Composite" : sl.Account, Environment.NewLine);
                dataString.AppendFormat("Total Items: {0}{1}", li.Count, Environment.NewLine);
                dataString.AppendFormat("Export Time: {0}{1}", DisplayDate(DateTime.UtcNow), Environment.NewLine);
                dataString.Append(Environment.NewLine);
                // The way the data is written depends on whether or not we're using tabs or spaces
                dataString.AppendFormat("{0}{5}{1}{5}{2}{5}{3}{5}{4}", header1, header2, header3, header4, Environment.NewLine, tabs ? "\t" : "  ");
                dataString.AppendFormat("{0}{5}{1}{5}{2}{5}{3}{5}{4}", dash1, dash2, dash3, dash4, Environment.NewLine, tabs ? "\t" : "  ");
                // Write the data
                if (tabs == true)
                {
                    foreach (SendListItemDetails i in li)
                    {
                        dataString.AppendFormat("{0}\t{1}\t{2}\t{3}\t{4}", i.SerialNo, DisplayDate(i.ReturnDate,false,false), ListStatus.ToUpper(i.Status), i.CaseName, Environment.NewLine);
                    }
                }
                else
                {
                    foreach (SendListItemDetails i in li)
                    {
                        string s1 = i.SerialNo.PadRight(f1, ' ');
                        string s2 = DisplayDate(i.ReturnDate,false,false).PadRight(f2, ' ');
                        string s3 = ListStatus.ToUpper(i.Status).PadRight(f3, ' ');
                        string s4 = i.CaseName;
                        dataString.AppendFormat("{0}  {1}  {2}  {3}  {4}", s1, s2, s3, s4, Environment.NewLine);
                    }
                }
                // Export the data
                DoExport(sl.Name + "_" + sl.CreateDate.ToString("yyyyMMddHHmm") + ".txt", dataString.ToString());
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Event handler for the return date OK button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnReturnOK_ServerClick(object sender, System.EventArgs e)
        {
            SendListItemCollection si = new SendListItemCollection();
            SendListCaseCollection sc = SendList.GetSendListCases(sl.Id);
            // Collect the items into the collection; if sealed case, show error
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                // Get the case name
                SendListCaseDetails d = sc.Find(sli[i.ItemIndex].CaseName);
                // If sealed case, display error
                if (d != null && d.Sealed)
                {
                    DisplayErrors(PlaceHolder1, "Medium " + sli[i.ItemIndex].SerialNo + " is in a sealed case and may not have its return date individually changed");
                    return;
                }
                else
                {
                    sli[i.ItemIndex].ReturnDate = txtReturnDate.Text;
                    si.Add(sli[i.ItemIndex]);
                }
            }
            // Update the items
            try
            {
                SendList.UpdateItems(ref si);
                ObtainItems();
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Determines if editing of return date for selected media is allowed
        /// </summary>
        /// <returns></returns>
        private bool ReturnDateEligible()
        {
            SendListCaseCollection c = SendList.GetSendListCases(sl.Id);
            // Collect the items into the collection; if sealed case, show error
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                // Get the case name
                SendListCaseDetails d = c.Find(sli[i.ItemIndex].CaseName);
                // If sealed case, display error
                if (d != null && d.Sealed)
                {
                    DisplayErrors(PlaceHolder1, "Medium " + sli[i.ItemIndex].SerialNo + " is in a sealed case and may not have its return date individually changed");
                    return false;
                }
            }
            // Return true
            return true;
        }
        /// <summary>
        /// Hides the export link, used when viewer access
        /// </summary>
        /// <returns></returns>
        private void HideExportLink()
        {
            ClientScript.RegisterStartupScript(GetType(), "exportHide", "<script language='javascript'>getObjectById('exportLink').style.display='none';getObjectById('listLink').style.left='619px';</script>");
        }
        /// <summary>
        /// Sends the application to the previous page
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void listLink_Click(object sender, EventArgs e)
        {
            Response.Redirect(backUrl, false);
        }

		/// <summary>
		/// Handler for page link buttons
		/// </summary>
		protected void SortLink_Command(Object sender, CommandEventArgs e)
		{
			if (e.CommandName == "2")
			{
				this.sortOrder = SLISorts.Account;
			}
			else
			{
				this.sortOrder = SLISorts.SerialNo;
			}
			// Update the viewstate, then fetch the grid
			this.ViewState["SortOrder"] = this.sortOrder;
			this.ObtainItems();
		}
	}
}
