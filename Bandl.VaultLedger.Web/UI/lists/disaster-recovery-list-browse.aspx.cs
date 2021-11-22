using System;
using System.Data;
using System.Web.UI;
using System.Collections;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for disaster_recovery_list_browse.
    /// </summary>
    public class disaster_recovery_list_browse : BasePage
    {
        private int pageNo;
        private int pageTotal;
        private DataGridItem[] dataItems = null;
        private DisasterCodeListCollection disasterLists = null;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.HtmlControls.HtmlInputHidden enterGoto;

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
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
            this.btnNew.Click += new System.EventHandler(this.btnNew_Click);
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.enterGoto.ServerChange += new System.EventHandler(this.enterGoto_ServerChange);
            this.DataGrid1.PreRender += new EventHandler(DataGrid1_PreRender);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Disaster Recovery Lists";
            this.levelTwo = LevelTwoNav.DisasterRecovery;
            this.helpId = 17;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnNo,  "onclick", "hideMsgBox('msgBoxDelete');");
            // Make sure that the record number text box can only contain digits
            this.SetControlAttr(this.txtPageGoto, "onkeyup", "digitsOnly(this);");
            // Make sure that the enter key changes the hidden field
            this.SetControlAttr(this.txtPageGoto, "onkeypress", "if (keyCode() == 13) getObjectById('enterGoto').value = this.value;");

            if (Page.IsPostBack)
            {
                pageNo = (int)this.ViewState["PageNo"];
                pageTotal = (int)this.ViewState["PageTotal"];
                disasterLists = (DisasterCodeListCollection)this.ViewState["Lists"];
            }
            else 
            {
                // Initialize
                pageNo = 1;
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
                // Fetch the lists
                this.ObtainLists();
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            CreateDropdownItems();
            // Restrict roles other than administrators and operators from seeing
            // top controls or checkboxes in the datagrid.  For administrators
            // and operators, render check box invisible for any cleared list.
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                case Role.Operator:
                    break;  // All functions enabled
                case Role.Auditor:
                case Role.Viewer:
                default:
                    this.DataGrid1.Columns[0].Visible = false;
                    this.btnNew.Visible = false;
                    break;
            }
        }
        /// <summary>
        /// Creates list items in the select action dropdown as needed
        /// </summary>
        private void CreateDropdownItems()
        {
            ListItem lix = this.ddlSelectAction.Items.FindByValue("Xmit");
            bool xe = DisasterCodeList.StatusEligible(disasterLists, DLStatus.Xmitted);
            // Add and delete as necessary
            if (xe && lix == null)
                ddlSelectAction.Items.Add(new ListItem("Transmit Selected", "Xmit"));
            else if (!xe && lix != null)
                ddlSelectAction.Items.Remove(lix);
        }
        /// <summary>
        /// Prerender event handler for datagrid
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            // Hide the checkbox for all processed lists
            for (int i = 0; i < disasterLists.Count; i++)
                if (disasterLists[i].Status == DLStatus.Processed)
                    this.DataGrid1.Items[i].Cells[0].Controls[1].Visible = false;
            // If we have no lists for the datagrid, then create an empty table
            // with one row so that we may display a message to the user.
            if (disasterLists.Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Id", typeof(int));
                dataTable.Columns.Add("Name", typeof(string));
                dataTable.Columns.Add("CreateDate", typeof(string));
                dataTable.Columns.Add("Status", typeof(string));
                dataTable.Columns.Add("Account", typeof(string));
                dataTable.Rows.Add(new object[] {0, "", "", "", ""});
                // Bind the datagrid to the empty table
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
                // Create the text in the first column and render the
                // checkbox column invisible
                this.DataGrid1.Columns[0].Visible = false;
                this.DataGrid1.Items[0].Cells[1].Text = "None created";
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
            // Store the page number and fetch the grid
            this.ViewState["PageNo"] = pageNo;
            this.ObtainLists();
        }
        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void ObtainLists()
        {
            try
            {
                int x = 0;
                DLSorts sortOrder = DLSorts.ListName;
                int pageSize = Preference.GetItemsPerPage();
                disasterLists = DisasterCodeList.GetDisasterCodeListPage(pageNo, pageSize, sortOrder, out x);
                // If no lists exist, then set the page number to one.  Otherwise, if
                // the current page number is greater than the total number of pages,
                // get the last page of data.
                if (x == 0)
                {
                    pageNo = 1;
                    pageTotal = 1;
                }
                else if (pageNo > (pageTotal = Convert.ToInt32(Math.Ceiling(x / (double)pageSize))))
                {
                    pageNo = pageTotal;
                    disasterLists = DisasterCodeList.GetDisasterCodeListPage(pageNo, pageSize, sortOrder, out x);
                }
                // Set the viewstate
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["Lists"] = disasterLists;
                this.ViewState["PageTotal"] = pageTotal;
                // Bind the data
                DataGrid1.DataSource = disasterLists;
                DataGrid1.DataBind();
                // Page links
                this.lnkPagePrev.Enabled  = pageNo != 1;
                this.lnkPageFirst.Enabled = pageNo != 1;
                this.lnkPageNext.Enabled  = pageNo != pageTotal;
                this.lnkPageLast.Enabled  = pageNo != pageTotal;
                this.lblPage.Text = String.Format("Page {0} of {1}", pageNo, pageTotal);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(PlaceHolder1, ex.Message);
            }
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
                    case "Merge":
                        this.MergeLists();
                        break;
                    case "Extract":
                        this.DoAction(-2);
                        break;
                    case "Xmit":
                        this.DoAction((int)DLStatus.Xmitted);
                        break;
                    case "Delete":
                        this.ShowMessageBox("msgBoxDelete");
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Merges lists checked in the datagrid
        /// </summary>
        private void MergeLists()
        {
            DisasterCodeListCollection mergeThese = new DisasterCodeListCollection();
            // Add the checked send lists to the merge collection
            foreach (DataGridItem d in dataItems)
                mergeThese.Add(disasterLists[d.ItemIndex]);
            // If we have one list, display error
            if (mergeThese.Count == 1)
            {
                this.DisplayErrors(this.PlaceHolder1, "More than one list must be selected for merging.");
            }
            else
            {
                // Merge the lists and reobtain data
                try
                {
                    DisasterCodeList.Merge(mergeThese);
                    this.ObtainLists();
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Performs action on selected lists
        /// </summary>
        private void DoAction(int actionNo)
        {
            bool oneSuccess = false;
            ArrayList checkThese = new ArrayList();
            // Collect the items if they have not yet been collected
            if (dataItems == null)
                dataItems = this.CollectCheckedItems(this.DataGrid1);
            // Dissolve the lists
            foreach (DataGridItem d in dataItems)
            {
                try
                {
                    switch (actionNo)
                    {
                        case (int)DLStatus.Xmitted:
                            DisasterCodeList.Transmit(disasterLists[d.ItemIndex]);
                            break;
                        case -1:
                            DisasterCodeList.Delete(disasterLists[d.ItemIndex]);
                            break;
                        case -2:
                            DisasterCodeList.Dissolve(disasterLists[d.ItemIndex]);
                            break;
                    }
                    // Record the fact that we had at least one success
                    oneSuccess = true;
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                    checkThese.Add(disasterLists[d.ItemIndex].Name);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    checkThese.Add(disasterLists[d.ItemIndex].Name);
                }
            }
            // If nothing succeeded, just return
            if (oneSuccess == false) return;
            // Reobtain the lists
            this.ObtainLists();
            // Check any grid items with errors
            this.CheckGridItems(checkThese);
        }
        /// <summary>
        /// Checks items in the datagrid
        /// </summary>
        private void CheckGridItems(ArrayList checkThese)
        {
            int i = 0;
            // Look for each list name; if found, check it
            foreach (string listName in checkThese)
                if ((i = disasterLists.IndexOf(listName)) != -1)
                    ((HtmlInputCheckBox)this.DataGrid1.Items[i].Cells[0].Controls[1]).Checked = true;
        }
        /// Event handler for the New List button
        /// </summary>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            switch (TabPageDefault.GetDefault(TabPageDefaults.NewDisasterCodeList, Context.Items[CacheKeys.Login]))
            {
                case 1:
                    Server.Transfer("disaster-recovery-list-append.aspx");
                    break;
                case 2:
                    Server.Transfer("new-dr-list-batch-file-step-one.aspx");
                    break;
                case 3:
                    Server.Transfer("new-dr-list-tms-file.aspx");
                    break;
            }
        }
        /// <summary>
        /// Event handler for the Delete Confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            DoAction(-1);
        }
        /// <summary>
        /// Event handler for hidden field change.  Used for page goto.
        /// </summary>
        private void enterGoto_ServerChange(object sender, System.EventArgs e)
        {
            if (this.txtPageGoto.Text.Length != 0)
            {
                pageNo = Int32.Parse(this.txtPageGoto.Text);
                this.txtPageGoto.Text = String.Empty;
                this.ObtainLists();
            }
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintDLBrowse;
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
    }
}
