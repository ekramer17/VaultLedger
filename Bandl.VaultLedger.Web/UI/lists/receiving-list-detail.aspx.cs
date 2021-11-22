using System;
using System.Web;
using System.Text;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for receiving_list_detail.
	/// </summary>
	public class receiving_list_detail : BasePage
	{
        private int pageNo = 1;
        private int pageTotal = 0;
        private ReceiveListDetails rl = null;
        private string backUrl = @".\receive-lists.aspx";
        private string backLeft = "552";
        private string backCaption = "Lists";
		private RLISorts sortOrder = RLISorts.SerialNo;

		protected System.Web.UI.WebControls.Label lblListNo;
		protected System.Web.UI.WebControls.Label lblStatus;
		protected System.Web.UI.WebControls.Label lblCreateDate;
		protected System.Web.UI.WebControls.Label lblAccount;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Button btnAdd;
		protected System.Web.UI.WebControls.Button btnGo;
		protected System.Web.UI.WebControls.Button btnReconcile;
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.LinkButton FirstPage;
		protected System.Web.UI.WebControls.LinkButton PrevPage;
		protected System.Web.UI.WebControls.LinkButton NextPage;
		protected System.Web.UI.WebControls.LinkButton LastPage;
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divAction;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divPageLinks;
        protected System.Web.UI.HtmlControls.HtmlInputHidden enterGoto;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divButtons;
        protected System.Web.UI.WebControls.Label lblTransmit;
        protected System.Web.UI.WebControls.Label lblReconciled;
        protected System.Web.UI.WebControls.Button btnSolo;
        protected System.Web.UI.WebControls.Button btnCase;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.WebControls.Button btnMedia;
        protected System.Web.UI.WebControls.Button btnCases;
        protected System.Web.UI.WebControls.Button btnNeither;
        protected System.Web.UI.WebControls.LinkButton exportLink;
        protected System.Web.UI.WebControls.LinkButton listLink;
		protected System.Web.UI.WebControls.Button btnTransmit;
        protected System.Web.UI.WebControls.Button btnCaseAdd;
        protected System.Web.UI.WebControls.Button btnCaseAddCancel;
        protected System.Web.UI.WebControls.TextBox txtCaseName;

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
            this.exportLink.Click += new System.EventHandler(this.exportLink_Click);
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
            this.btnAdd.Click += new System.EventHandler(this.btnAdd_Click);
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.btnReconcile.Click += new System.EventHandler(this.btnReconcile_Click);
            this.btnTransmit.Click += new System.EventHandler(this.btnTransmit_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.btnSolo.Click += new System.EventHandler(this.btnSolo_Click);
            this.btnCase.Click += new System.EventHandler(this.btnCase_Click);
            this.btnMedia.Click += new System.EventHandler(this.btnYes_Click);
            this.btnCases.Click += new System.EventHandler(this.btnCases_Click);
            this.btnCaseAdd.Click += new System.EventHandler(this.btnCaseAdd_Click);
            this.enterGoto.ServerChange += new System.EventHandler(this.enterGoto_ServerChange);
            this.listLink.Click += new EventHandler(listLink_Click);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 15;
            this.levelTwo = LevelTwoNav.Receiving;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnNo, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxReconcile');");
            this.SetControlAttr(this.btnSolo, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCase, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCancel, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnMedia, "onclick", "hideMsgBox('msgBoxRemove');");
            this.SetControlAttr(this.btnCases, "onclick", "hideMsgBox('msgBoxRemove');");
            this.SetControlAttr(this.btnNeither, "onclick", "hideMsgBox('msgBoxRemove');");
            this.SetControlAttr(this.btnCaseAdd, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnCaseAddCancel, "onclick", "hideMsgBox('msgBoxDelete');");
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
                rl = (ReceiveListDetails)this.ViewState["ListObject"];
                backUrl = (string)ViewState["backUrl"];
                backLeft = (string)ViewState["backLeft"];
                backCaption = (string)ViewState["backCaption"];
				sortOrder = (RLISorts)ViewState["SortOrder"];
			}
            else
            {
                // Initialize
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
				// Initialize sort order
				this.ViewState["SortOrder"] = sortOrder;

                if (Request.QueryString["listNumber"] == null)
                {
                    Response.Redirect("receive-lists.aspx", false);
                }
                else 
                {
                    try
                    {
                        // Retrieve the list
                        string listName = Request.QueryString["listNumber"];
                        rl = ReceiveList.GetReceiveList(listName, false);
                        this.ViewState["ListObject"] = rl;
                        // Set the text for the page labels
                        this.lblListNo.Text = rl.Name;
                        this.lblCaption.Text = "Receiving List " + rl.Name;
                        this.lblCreateDate.Text = DisplayDate(rl.CreateDate, true, false);
                        this.lblAccount.Text = rl.IsComposite ? "(Composite List)" : rl.Account;
                        // Set message box labels
                        this.lblTransmit.Text = String.Format("Receiving list {0} was transmitted successfully.", rl.Name);
                        this.lblReconciled.Text = String.Format("Receiving list {0} has been fully verified.", rl.Name);
                        // Page title
                        this.pageTitle = this.lblCaption.Text;
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
                        Response.Redirect("receive-lists.aspx", false);
                    }
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            bool ve = Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES";
            // Set the back link caption
            listLink.Text = backCaption;
            SetControlAttr(listLink, "style", "left:" + backLeft + "px", false);
            // Eligiblility
            ListItem liv = this.ddlSelectAction.Items.FindByValue("Verify");
            ListItem lir = this.ddlSelectAction.Items.FindByValue("Remove");
            ListItem lica = this.ddlSelectAction.Items.FindByValue("CaseAdd");
            ListItem licr = this.ddlSelectAction.Items.FindByValue("CaseRemove");
            this.btnAdd.Visible = rl.Status < RLStatus.Xmitted;
            this.btnTransmit.Visible = ReceiveList.StatusEligible(rl, RLStatus.Xmitted);
            this.btnReconcile.Visible = ReceiveList.StatusEligible(rl, RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII);
            // Verification eligible?
            if (ve && this.btnReconcile.Visible && liv == null)
                ddlSelectAction.Items.Add(new ListItem("Verify Selected", "Verify"));
            else if ((!ve || !this.btnReconcile.Visible) && liv != null)
                ddlSelectAction.Items.Remove(liv);
            // Remove eligible?
            if (rl.Status <= RLStatus.Xmitted && lir == null)
                ddlSelectAction.Items.Add(new ListItem("Remove Selected", "Remove"));
            else if (rl.Status > RLStatus.Xmitted && lir != null)
                ddlSelectAction.Items.Remove(lir);
            // Add / remove from case?
            if (rl.Status < RLStatus.Transit && lica == null)
            {
                ddlSelectAction.Items.Add(new ListItem("Add To Case", "CaseAdd"));
                ddlSelectAction.Items.Add(new ListItem("Remove From Case", "CaseRemove"));
            }
            else if (rl.Status >= RLStatus.Transit && lica != null)
            {
                ddlSelectAction.Items.Remove(lica);
                ddlSelectAction.Items.Remove(licr);
            }

            // Datagrid adjustments
            if (rl.Status == RLStatus.Processed)
            {
                this.DataGrid1.Columns[0].Visible = false;
                this.btnReconcile.Visible = false;
                this.btnAdd.Visible = false;
            }
            // If list is composite, show account column....otherwise hide it
            this.DataGrid1.Columns[4].Visible = rl.IsComposite;
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
                RLIStatus itemStatus = RLIStatus.AllValues ^ RLIStatus.Removed;
                ReceiveListItemCollection receiveItems = ReceiveList.GetReceiveListItemPage(rl.Id, pageNo, pageSize, itemStatus, sortOrder, out itemCount);
                // If no items exist, then redirect to the send lists page
                if (itemCount == 0)
                {
                    Response.Redirect("receive-lists.aspx", false);
                }
                else if (pageNo > (pageTotal = Convert.ToInt32(Math.Ceiling(itemCount / (double)pageSize))))
                {
                    pageNo = pageTotal;
                    receiveItems = ReceiveList.GetReceiveListItemPage(rl.Id, pageNo, pageSize, itemStatus, sortOrder, out itemCount);
                }
                // Bind the data
                DataGrid1.DataSource = receiveItems;
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
                this.ViewState["ListItems"] = receiveItems;
                // Refetch the list in case status has changed
                rl = ReceiveList.GetReceiveList(rl.Id, false);
                this.ViewState["ListObject"] = rl;
                // If the list does not exist, redirect to browse page
                if (rl == null)
                    Server.Transfer("receive-lists.aspx");
                else
                    this.lblStatus.Text = StatusString(rl.Status);
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
                    case "Verify":
                        VerifyItems();
                        break;
                    case "Missing":
                        MakeMissing(0);
                        break;
                    case "Remove":
                        ShowRemoveBox();
                        break;
                    case "CaseAdd":
                        ClientScript.RegisterStartupScript(GetType(), "msgBoxCase", "<script language=javascript>showMsgBox('msgBoxCase')</script>");
                        ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        break;
                    case "CaseRemove":
                        RemoveItemsFromCase();
                        break;
                    default:
                        break;
                }
            }
            
        }
        /// <summary>
        /// When deleting media off the list, shows the appropriate confirmation box
        /// </summary>
        private void ShowRemoveBox()
        {
            string boxName = "msgBoxDelete";
            ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
            // If there is a sealed case involved, use the remove box
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                if (li[i.ItemIndex].CaseName.Length != 0)
                {
                    boxName = "msgBoxRemove";
                    break;
                }
            }
            // Show the box
            ClientScript.RegisterStartupScript(GetType(), boxName, "<script language=javascript>showMsgBox('" + boxName + "')</script>");
            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
        }
        /// <summary>
        /// Handler for the removal confirmation button
        /// </summary>
        private void btnCaseAdd_Click(object sender, System.EventArgs e)
        {
            try
            {
                MediumCollection m = new MediumCollection();
                ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
                // Get the items from the datagrid
                foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                    m.Add(Medium.GetMedium(li[i.ItemIndex].SerialNo));
                // Remove
                SealedCase.InsertMedia(txtCaseName.Text, m);
                // Refresh
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
        /// Handler for the removal confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            ReceiveListItemCollection ri = new ReceiveListItemCollection();
            ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
            // Add the checked items to the collection
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                ri.Add(li[i.ItemIndex]);
            // Remove the items from the list
            if (ri.Count != 0)
            {
                try
                {
                    ReceiveList.RemoveItems(rl.Name, ref ri);
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
        /// Handler for the removal confirmation button where user chooses to remove all tapes in the sealed cases
        /// </summary>
        private void btnCases_Click(object sender, System.EventArgs e)
        {
            int x = 0;
            ArrayList caseNames = new ArrayList();
            ReceiveListItemCollection ri = new ReceiveListItemCollection();
            ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
            ReceiveListItemCollection pi = ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, RLISorts.SerialNo, out x);
            // Add case names to the array list            
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                if (li[i.ItemIndex].CaseName == String.Empty)
                {                   
                    ri.Add(li[i.ItemIndex]);
                }
                else if (caseNames.IndexOf(li[i.ItemIndex].CaseName) == -1)
                {
                    caseNames.Add(li[i.ItemIndex].CaseName);
                }
            }
            // Remove the items from the list
            if (ri.Count != 0 || caseNames.Count != 0)
            {
                try
                {
                    // Remove the cases
                    if (caseNames.Count != 0)
                        ReceiveList.RemoveSealedCases(rl, (string[])caseNames.ToArray(typeof(string)));
                    // Remove the individual items
                    if (ri.Count != 0)
                        ReceiveList.RemoveItems(rl.Name, ref ri);
                    // Fetch the list from the database
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
        /// Verifies items checked off in the datagrid
        /// </summary>
        private void VerifyItems()
        {
            ReceiveListItemCollection vi = new ReceiveListItemCollection();
            ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
            // Get the items from the datagrid
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                vi.Add(li[i.ItemIndex]);
            // If there are any items in the collection, verify them.  Then refetch the data.
            try
            {
                ReceiveList.Verify(rl.Name, ref vi);
                this.ObtainItems();
                // If the list is now fully verified, display the message box
                switch (rl.Status)
                {
                    case RLStatus.FullyVerifiedI:
                    case RLStatus.FullyVerifiedII:
                    case RLStatus.Processed:
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
        /// <summary>
        /// Marks the checked media as missing
        /// </summary>
        private void MakeMissing(int caseAction)
        {
            MediumDetails m = null;
            MediumCollection mc = new MediumCollection();
            ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
            // Get the items from the datagrid
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                if (li[i.ItemIndex].Status >= RLIStatus.VerifiedI && !ReceiveList.StatusEligible(rl.Status, RLStatus.FullyVerifiedII))
                {
                    DisplayErrors(this.PlaceHolder1, "Medium " + li[i.ItemIndex].SerialNo + " may not be marked missing at this stage.&nbsp;&nbsp;It may be marked missing during verification at the enterprise.");
                    return;
                }
                else if ((m = Medium.GetMedium(li[i.ItemIndex].SerialNo)).Missing == false) 
                {
                    m.Missing = true;
                    mc.Add(m);
                }
            }
            // Update the medium as missing.  If the item is in a sealed case and no
            // case action was specified, display the missing message box.
            if (mc.Count != 0)
            {
                try
                {
                    if (Medium.Update(ref mc, caseAction))
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
        /// Removes items from sealed case
        /// </summary>
        private void RemoveItemsFromCase()
        {
            try
            {
                MediumCollection m = new MediumCollection();
                ReceiveListItemCollection li = (ReceiveListItemCollection)this.ViewState["ListItems"];
                // Get the items from the datagrid
                foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                    m.Add(Medium.GetMedium(li[i.ItemIndex].SerialNo));
                // Remove
                SealedCase.RemoveMedia(m);
                // Refresh
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
        /// Retries the medium update if there was a case integrity exception
        /// and the user selected to remove the individual tape(s) from their
        /// respective sealed cases.
        /// </summary>
        private void btnSolo_Click(object sender, System.EventArgs e)
        {
            this.MakeMissing(1);
        }
        /// <summary>
        /// Retries the medium update if there was a case integrity exception
        /// and the user selected to update all the media within sealed cases.
        /// </summary>
        private void btnCase_Click(object sender, System.EventArgs e)
        {
            this.MakeMissing(2);
        }
        /// <summary>
        /// Event handler for Add button click
        /// </summary>
        private void btnAdd_Click(object sender, System.EventArgs e)
        {
            if (rl.Status >= RLStatus.Xmitted)
                this.DisplayErrors(this.PlaceHolder1, "Items may no longer be added to this list.");
            else
                Server.Transfer(String.Format("new-receive-list-manual-scan-step-one.aspx?listNumber={0}", rl.Name));
        }
        /// <summary>
        /// Event handler for Reconcile button click
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnReconcile_Click(object sender, System.EventArgs e)
        {
            if (ReceiveList.StatusEligible(rl, RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII))
            {
                switch (TabPageDefault.GetDefault(TabPageDefaults.ReceiveReconcileMethod, Context.Items[CacheKeys.Login]))
                {
                    case 2:
                        Server.Transfer(String.Format("receiving-list-reconcile.aspx?listNumber={0}", this.lblListNo.Text));
                        break;
                    case 3:
                        Server.Transfer(String.Format("receiving-list-reconcile-rfid.aspx?listNumber={0}", this.lblListNo.Text));
                        break;
                    default:
                        Server.Transfer(String.Format("receiving-compare-online-reconcile.aspx?listNumber={0}", this.lblListNo.Text));
                        break;
                }

                Server.Transfer(String.Format("receiving-compare-online-reconcile.aspx?listNumber={0}", rl.Name));
            }
            else if (rl.Status == RLStatus.FullyVerifiedI || rl.Status == RLStatus.FullyVerifiedII)
            {
                this.DisplayErrors(this.PlaceHolder1, "This list already fully verified.");
            }
            else
            {
                this.DisplayErrors(this.PlaceHolder1, "This list is not currently eligible to be reconciled.");
            }
        }
        /// <summary>
        /// Event handler for Transmit button click
        /// </summary>
        private void btnTransmit_Click(object sender, System.EventArgs e)
        {
            if (!ReceiveList.StatusEligible(rl, RLStatus.Xmitted))
            {
                this.DisplayErrors(this.PlaceHolder1, "This list is not currently eligible to be transmitted.");
            }
            else
            {
                try
                {
                    // Get the list items
                    ReceiveList.Transmit(ReceiveList.GetReceiveList(rl.Id, true));
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
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintRLDetail;
            ClientScript.RegisterStartupScript(GetType(), "printWindow", String.Format("<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&id={0}&x=" + Guid.NewGuid().ToString("N") + "')</script>", rl.Id));
        }
        /// <summary>
        /// Exports the current list to a file for download
        /// </summary>
        private void exportLink_Click(object sender, System.EventArgs e)
        {
            try
            {
                int c = -1;
                int f1 = 20, f2 = 15;
                StringBuilder dataString = new StringBuilder();
                bool tabs = Preference.GetPreference(PreferenceKeys.ExportWithTabDelimiters).Value == "YES";
                // Header strings
                string header1 = tabs ? "Serial Number" : "Serial Number".PadRight(f1, ' ');
                string header2 = tabs ? "Status" : "Status".PadRight(f2, ' ');
                string header3 = tabs ? "Case Number" : "Case Number";
                string dash1 = String.Empty.PadRight(f1, '-');
                string dash2 = String.Empty.PadRight(f2, '-');
                string dash3 = String.Empty.PadRight(15, '-');
                // Retrieve all the list items
                RLIStatus x = RLIStatus.AllValues ^ RLIStatus.Removed;
                ReceiveListItemCollection li = ReceiveList.GetReceiveListItemPage(rl.Id, 1, 32000, x, RLISorts.SerialNo, out c);
                // Create the top headers
                string title = String.Format("{0} Receiving List {1}", Configurator.ProductName, rl.Name);
                dataString.AppendFormat("{0}{1}{2}{1}", title, Environment.NewLine, String.Empty.PadRight(title.Length,'-'));
                dataString.AppendFormat("Create Date: {0}{1}", DisplayDate(rl.CreateDate), Environment.NewLine);
                dataString.AppendFormat("List Status: {0}{1}", ListStatus.ToUpper(rl.Status), Environment.NewLine);
                dataString.AppendFormat("Account No.: {0}{1}", rl.IsComposite ? "Composite" : rl.Account, Environment.NewLine);
                dataString.AppendFormat("Total Items: {0}{1}", li.Count, Environment.NewLine);
                dataString.AppendFormat("Export Time: {0}{1}", DisplayDate(DateTime.UtcNow), Environment.NewLine);
                dataString.Append(Environment.NewLine);
                // The way the data is written depends on whether or not we're using tabs or spaces
                dataString.AppendFormat("{0}{4}{1}{4}{2}{4}{3}", header1, header2, header3, Environment.NewLine, tabs ? "\t" : "  ");
                dataString.AppendFormat("{0}{4}{1}{4}{2}{4}{3}", dash1, dash2, dash3, Environment.NewLine, tabs ? "\t" : "  ");
                // Write the data
                // Write the data
                if (tabs == true)
                {
                    foreach (ReceiveListItemDetails i in li)
                    {
                        dataString.AppendFormat("{0}\t{1}\t{2}\t{3}", i.SerialNo, ListStatus.ToUpper(i.Status), i.CaseName, Environment.NewLine);
                    }
                }
                else
                {
                    foreach (ReceiveListItemDetails i in li)
                    {
                        string s1 = i.SerialNo.PadRight(f1, ' ');
                        string s2 = ListStatus.ToUpper(i.Status).PadRight(f2, ' ');
                        dataString.AppendFormat("{0}  {1}  {2}  {3}", s1, s2, i.CaseName, Environment.NewLine);
                    }
                }
                // Export the data
                DoExport(rl.Name + "_" + rl.CreateDate.ToString("yyyyMMddHHmm") + ".txt", dataString.ToString());
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
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
				this.sortOrder = RLISorts.Account;
			}
			else
			{
				this.sortOrder = RLISorts.SerialNo;
			}
			// Update the viewstate, then fetch the grid
			this.ViewState["SortOrder"] = this.sortOrder;
			this.ObtainItems();
		}
	}
}
