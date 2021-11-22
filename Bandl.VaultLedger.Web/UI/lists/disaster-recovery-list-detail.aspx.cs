using System;
using System.Web;
using System.Text;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for disaster_recovery_list_detail.
	/// </summary>
	public class disaster_recovery_list_detail : BasePage
	{
        private int listId = 0;
        private int pageNo = 1;
        private int pageTotal = 0;
        private DataGridItem[] dataItems = null;
        private DisasterCodeListDetails dl = null;
        // Fields used in server transfer to case edit page
        private DisasterCodeListItemCollection editableItems = null;

        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblStatus;
        protected System.Web.UI.WebControls.Label lblCreateDate;
        protected System.Web.UI.WebControls.Label lblAccount;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnAdd;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Button btnTransmit;
        protected System.Web.UI.WebControls.Label lblTransmit;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.HtmlControls.HtmlInputHidden enterGoto;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.Button btnXmitYes;
        protected System.Web.UI.WebControls.Button btnXmitNo;
        protected System.Web.UI.WebControls.Label lblConfirm;
        protected System.Web.UI.WebControls.LinkButton exportLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divButtons;
        // Public Properties
        public int ListId {get {return this.listId;}}
        public DisasterCodeListItemCollection EditableItems {get {return this.editableItems;}}
	
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
            this.btnTransmit.Click += new System.EventHandler(this.btnTransmit_Click);
            this.btnXmitYes.Click += new System.EventHandler(this.btnXmitYes_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.enterGoto.ServerChange += new System.EventHandler(this.enterGoto_ServerChange);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 18;
            this.levelTwo = LevelTwoNav.DisasterRecovery;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnNo,  "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnXmitYes, "onclick", "hideMsgBox('msgBoxConfirm');");
            this.SetControlAttr(this.btnXmitNo,  "onclick", "hideMsgBox('msgBoxConfirm');");
            // Make sure that the record number text box can only contain digits
            this.SetControlAttr(this.txtPageGoto, "onkeyup", "digitsOnly(this);");
            // Make sure that the enter key changes the hidden field
            this.SetControlAttr(this.txtPageGoto, "onkeypress", "if (keyCode() == 13) getObjectById('enterGoto').value = this.value;");
            // Get the list id from the querystring.  If it does not exist, redirect
            // to the list browse page.
            if (Page.IsPostBack)
            {
                listId = (int)this.ViewState["ListId"];
                pageNo = (int)this.ViewState["PageNo"];
                pageTotal = (int)this.ViewState["PageTotal"];
                dl = (DisasterCodeListDetails)this.ViewState["ListObject"];
            }
            else
            {
                // Initialize
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;

                if (Request.QueryString["listNumber"] == null)
                {
                    Server.Transfer("disaster-recovery-list-browse.aspx");
                }
                else 
                {
                    try
                    {
                        // Retrieve the list
                        string listName = Request.QueryString["listNumber"];
                        dl = DisasterCodeList.GetDisasterCodeList(listName, false);
                        this.ViewState["ListObject"] = dl;
                        // Place the id in the viewstate
                        listId = dl.Id;
                        this.ViewState["ListId"] = listId;
                        // Set the text for the page labels
                        this.lblListNo.Text = dl.Name;
                        this.lblCaption.Text = "Disaster Recovery List " + dl.Name;
                        this.lblCreateDate.Text = DisplayDate(dl.CreateDate, true, false);
                        this.lblAccount.Text = dl.IsComposite ? "(Composite List)" : dl.Account;
                        // Set message box labels
                        this.lblTransmit.Text = String.Format("Disaster recovery list {0} was transmitted successfully.", dl.Name);
                        // Fetch the list items
                        this.ObtainItems();
                    }
                    catch
                    {
                        Server.Transfer("disaster-recovery-list-browse.aspx");
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
            // If the status of the list is beyond transmitted, it may not be altered
            if (dl.Status >= DLStatus.Xmitted)
            {
                this.DataGrid1.Columns[0].Visible = false;
                this.btnAdd.Visible = false;
            }
            // If the list is not eligible to be transmitted, hide the button
            this.btnTransmit.Visible = 0 != (DisasterCodeList.Statuses & DLStatus.Xmitted);
        }
        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void ObtainItems()
        {
            try
            {
                int itemCount = 0;
                DLISorts sortOrder = DLISorts.SerialNo;
                int pageSize = Preference.GetItemsPerPage();
                DLIStatus itemStatus = DLIStatus.AllValues ^ DLIStatus.Removed;
                DisasterCodeListItemCollection disasterItems = DisasterCodeList.GetDisasterCodeListItemPage(listId, pageNo, pageSize, itemStatus, sortOrder, out itemCount);
                // If no items exist, then redirect to the send lists page
                if (itemCount == 0)
                {
                    Response.Redirect("disaster-recovery-list-browse.aspx", false);
                }
                else if (pageNo > (pageTotal = Convert.ToInt32(Math.Ceiling(itemCount / (double)pageSize))))
                {
                    pageNo = pageTotal;
                    disasterItems = DisasterCodeList.GetDisasterCodeListItemPage(listId, pageNo, pageSize, itemStatus, sortOrder, out itemCount);
                }
                // Bind the data
                DataGrid1.DataSource = disasterItems;
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
                this.ViewState["ListItems"] = disasterItems;
                // Always get the list in case the status has changed
                dl = DisasterCodeList.GetDisasterCodeList(listId, false);
                this.lblStatus.Text = StatusString(dl.Status);
                this.ViewState["ListObject"] = dl;
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
            if ((dataItems = this.CollectCheckedItems(this.DataGrid1)).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Remove":
                        this.ShowMessageBox("msgBoxDelete");
                        break;
                    case "Edit":
                        this.GatherEditableItems();
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
            DisasterCodeListItemCollection ri = new DisasterCodeListItemCollection();
            DisasterCodeListItemCollection li = (DisasterCodeListItemCollection)this.ViewState["ListItems"];
            // Collect the items if they have not yet been collected
            if (dataItems == null)
                dataItems = this.CollectCheckedItems(this.DataGrid1);
            // Add the checked items to the collection
            foreach (DataGridItem i in dataItems)
                ri.Add(li[i.ItemIndex]);
            // Remove the items from the list
            try
            {
                DisasterCodeList.RemoveItems(dl.Name, ref ri);
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
        /// Edits the selected items
        /// </summary>
        private void GatherEditableItems()
        {
            // Clear the case items collection
            this.editableItems = new DisasterCodeListItemCollection();
            // Get a reference to the displayed item collection
            DisasterCodeListItemCollection li = (DisasterCodeListItemCollection)this.ViewState["ListItems"];
            // Add the checked items to the collection
            foreach (DataGridItem i in dataItems)
                editableItems.Add(li[i.ItemIndex]);
            // Transfer to the case edit page
            Server.Transfer("disaster-recovery-list-edit.aspx");
        }
        /// <summary>
        /// Event handler for Add button click
        /// </summary>
        private void btnAdd_Click(object sender, System.EventArgs e)
        {
            Server.Transfer(String.Format("disaster-recovery-list-append.aspx?listNumber={0}", this.lblListNo.Text));
        }
        /// <summary>
        /// Event handler for transmit confirmation button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnXmitYes_Click(object sender, System.EventArgs e)
        {
            this.XmitList();        
        }
        /// <summary>
        /// Event handler for Transmit button click
        /// </summary>
        private void btnTransmit_Click(object sender, System.EventArgs e)
        {
            switch (dl.Status)
            {
                case DLStatus.Submitted:
                    this.XmitList();
                    break;
                case DLStatus.Xmitted:
                case DLStatus.Processed:
                    lblConfirm.Text = "This list has already been " + ListStatus.ToLower(dl.Status) + ".";
                    this.ShowMessageBox("msgBoxConfirm");
                    break;
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
        /// Transmits the list
        /// </summary>
        private void XmitList()
        {
            try
            {
                DisasterCodeList.Transmit(DisasterCodeList.GetDisasterCodeList(listId, true));
                // Fetch the list
                this.ObtainItems();
                // Popup message box
                this.ShowMessageBox("msgBoxTransmit");
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintDLDetail;
            ClientScript.RegisterStartupScript(GetType(), "printWindow", String.Format("<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&id={0}&x=" + Guid.NewGuid().ToString("N") + "')</script>", listId));
        }
        /// <summary>
        /// Exports the current list to a file for download
        /// </summary>
        private void exportLink_Click(object sender, System.EventArgs e)
        {
            try
            {
                int c = -1;
                int f1 = 20, f2 = 10, f3 = 15;
                StringBuilder dataString = new StringBuilder();
                bool tabs = Preference.GetPreference(PreferenceKeys.ExportWithTabDelimiters).Value == "YES";
                // Header strings
                string header1 = tabs ? "Serial Number" : "Serial Number".PadRight(f1, ' ');
                string header2 = tabs ? "DR Code" : "DR Code".PadRight(f2, ' ');
                string header3 = tabs ? "Status" : "Status".PadRight(f3, ' ');
                string header4 = "Account";
                string dash1 = String.Empty.PadRight(f1, '-');
                string dash2 = String.Empty.PadRight(f2, '-');
                string dash3 = String.Empty.PadRight(f3, '-');
                string dash4 = String.Empty.PadRight(20, '-');
                // Get the list items
                DLIStatus x = DLIStatus.AllValues ^ DLIStatus.Removed;
                DisasterCodeListItemCollection li = DisasterCodeList.GetDisasterCodeListItemPage(dl.Id, 1, 32000, x, DLISorts.SerialNo, out c);
                // Create the top headers
                string title = String.Format("{0} Disaster Recovery List {1}", Configurator.ProductName, dl.Name);
                dataString.AppendFormat("{0}{1}{2}{1}", title, Environment.NewLine, String.Empty.PadRight(title.Length,'-'));
                dataString.AppendFormat("Create Date: {0}{1}", DisplayDate(dl.CreateDate), Environment.NewLine);
                dataString.AppendFormat("List Status: {0}{1}", ListStatus.ToUpper(dl.Status), Environment.NewLine);
                dataString.AppendFormat("Account No.: {0}{1}", dl.IsComposite ? "Composite" : dl.Account, Environment.NewLine);
                dataString.AppendFormat("Total Items: {0}{1}", li.Count, Environment.NewLine);
                dataString.AppendFormat("Export Time: {0}{1}", DisplayDate(DateTime.UtcNow), Environment.NewLine);
                dataString.Append(Environment.NewLine);
                // The way the data is written depends on whether or not we're using tabs or spaces
                dataString.AppendFormat("{0}{5}{1}{5}{2}{5}{3}{5}{4}", header1, header2, header3, header4, Environment.NewLine, tabs ? "\t" : "  ");
                dataString.AppendFormat("{0}{5}{1}{5}{2}{5}{3}{5}{4}", dash1, dash2, dash3, dash4, Environment.NewLine, tabs ? "\t" : "  ");
                // Write the data
                if (tabs == true)
                {
                    foreach (DisasterCodeListItemDetails i in li)
                    {
                        dataString.AppendFormat("{0}\t{1}\t{2}\t{3}\t{4}", i.SerialNo, i.Code, ListStatus.ToUpper(i.Status), i.Account, Environment.NewLine);
                    }
                }
                else
                {
                    foreach (DisasterCodeListItemDetails i in li)
                    {
                        string s1 = i.SerialNo.PadRight(f1, ' ');
                        string s2 = i.Code.PadRight(f2, ' ');
                        string s3 = ListStatus.ToUpper(i.Status).PadRight(f3, ' ');
                        string s4 = i.Account;
                        dataString.AppendFormat("{0}  {1}  {2}  {3}  {4}", s1, s2, s3, s4, Environment.NewLine);
                    }
                }
                // Export the data
                DoExport(dl.Name + "_" + dl.CreateDate.ToString("yyyyMMddHHmm") + ".txt", dataString.ToString());
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
    }
}
