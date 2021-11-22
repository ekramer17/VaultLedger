using System;
using System.Data;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for reconcile_inventory_template.
    /// </summary>
    public class reconcile_inventory : BasePage
    {
        private int pageNo = 1;
        private int pageTotal = 1;
        private InventoryConflictCollection iConflicts = null;
        private InventoryConflictTypes conflictType;
        private String accounts = String.Empty;

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Label lblPage;
        protected System.Web.UI.WebControls.Button btnSolo;
        protected System.Web.UI.WebControls.Button btnCase;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.Button btnUpload;
        protected System.Web.UI.WebControls.Label pageCaption;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.WebControls.Button btnAccountOK;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCompare;
        protected System.Web.UI.WebControls.DataGrid GridView1;
        protected System.Web.UI.WebControls.DataGrid GridView2;
        protected System.Web.UI.WebControls.DataGrid GridView3;
        protected System.Web.UI.WebControls.HyperLink FilterLink;
        protected System.Web.UI.WebControls.Button btnAccountCancel;
	
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
            this.btnUpload.Click += new System.EventHandler(this.btnUpload_Click);
            this.btnAccountOK.Click += new System.EventHandler(this.btnAccountOK_Click);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Reconcile Inventory";
            this.levelTwo = LevelTwoNav.Reconcile;
            this.helpId = 6;
            // Set the page according to product type
            switch (Configurator.ProductType)
            {
                case "RECALL":
//                    this.btnUpload.Visible = false;
                    break;
                default:
                    this.btnCompare.Visible = false;
                    this.pageCaption.Text = this.pageCaption.Text.Replace("the vault, click Compare to Recall", "a file from the batch scanner, click Upload File");
                    break;
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnSolo, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCase, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCancel, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnAccountOK, "onclick", "hideMsgBox('msgBoxAccounts');");
            this.SetControlAttr(this.btnAccountCancel, "onclick", "hideMsgBox('msgBoxAccounts');");
            // Make sure that the record number text box can only contain digits
            this.SetControlAttr(this.txtPageGoto, "onkeyup", "digitsOnly(this);");

            if (Page.IsPostBack)
            {
                pageNo = (int)this.ViewState["PageNo"];
                pageTotal = (int)this.ViewState["PageTotal"];
                // Restore viewstate
                if (this.ViewState["Conflicts"] != null) iConflicts = (InventoryConflictCollection)this.ViewState["Conflicts"];
                if (this.ViewState["Type"] != null) conflictType = (InventoryConflictTypes)this.ViewState["Type"];
                if (this.ViewState["Accounts"] != null) accounts = (String)this.ViewState["Accounts"];
                // Go button click?
                if (Request["__EVENTTARGET"] == "btnGo")
                {
                    this.btnGo_Click();
                }
                else if (Request["__EVENTTARGET"] == "DoFilter")
                {
                    this.FetchConflicts(false);
                }
            }
            else
            {
                // Initialize
                pageNo = 1;
                bool boxOk = false;
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
                // If there is an exception, display it
                if (Session[CacheKeys.Exception] != null)
                {
                    this.DisplayErrors(this.PlaceHolder1, ((Exception)Session[CacheKeys.Exception]).Message);
                    Session.Remove(CacheKeys.Exception);
                }
                else
                {
                    boxOk = NullIsEmpty(Request.QueryString["box"]) == "1";
                }
                // Populate the accounts
                AccountCollection c1 = Account.GetAccounts(true);
                this.GridView1.DataSource = c1;
                this.GridView2.DataSource = c1;
                this.GridView1.DataBind();
                this.GridView2.DataBind();
                // Populate conflict type grid
                DataTable t1 = new DataTable();
                t1.Columns.Add("Id", typeof(int));
                t1.Columns.Add("Type", typeof(string));
                t1.Rows.Add(new object[] {(Int32)InventoryConflictTypes.Account, "Account"});
                t1.Rows.Add(new object[] {(Int32)InventoryConflictTypes.Location, "Location"});
                t1.Rows.Add(new object[] {(Int32)InventoryConflictTypes.ObjectType, "Object Type"});
                t1.Rows.Add(new object[] {(Int32)InventoryConflictTypes.UnknownSerial, "Unknown Serial&nbsp;&nbsp;(ignores account filter)"});
                this.GridView3.DataSource = t1;
                this.GridView3.DataBind();
                // Check all items in grid 1
                foreach (DataGridItem r1 in this.GridView1.Items)
                {
                    if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        ((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked = true;
                    }
                }
                // Check all items in grid 2
                foreach (DataGridItem r1 in this.GridView2.Items)
                {
                    if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        ((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked = true;
                    }
                }
                // Check all items in grid 3
                foreach (DataGridItem r1 in this.GridView3.Items)
                {
                    if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        ((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked = true;
                    }
                }
                // Fetch the discrepancies
                this.FetchConflicts(boxOk);
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Security considerations
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                case Role.Operator:
                    break;  // All functions enabled
                case Role.Auditor:
                case Role.Viewer:
                default:
                    this.DataGrid1.Columns[0].Visible = false;
                    this.btnCompare.Visible = false;
                    this.btnUpload.Visible = false;
                    break;
            }
        }
        /// <summary>
        /// Prerender event handler for datagrid
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            // If we have no items for the datagrid, then create an empty table
            // with one row so that we may display a message to the user.
            if (iConflicts.Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Id", typeof(int));
                dataTable.Columns.Add("SerialNo", typeof(string));
                dataTable.Columns.Add("ConflictType", typeof(int));
                dataTable.Columns.Add("RecordedDate", typeof(string));
                dataTable.Columns.Add("Details", typeof(string));
                dataTable.Rows.Add(new object[] {0, "", 0, "", ""});
                // Bind the datagrid to the empty table
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
                // Create the text in the first column and render the
                // checkbox column invisible
                this.DataGrid1.Columns[0].Visible = false;
                this.DataGrid1.Items[0].Cells[1].Text = "No current discrepancies";
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
            this.FetchConflicts(false);
        }
        /// <summary>
        /// Fetches the discrepancies from the database
        /// </summary>
        private void FetchConflicts(bool messageBox)
        {
            try
            {
                int x = -1;
                bool f1 = false;
                int pageSize = Preference.GetItemsPerPage();
                string a1 = String.Empty;
                int t1 = 0;

                // Accounts?
                foreach (DataGridItem r1 in this.GridView2.Items)
                {
                    if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        if (((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked)
                        {
                            a1 += "," + r1.Cells[1].Text;
                        }
                        else
                        {
                            f1 = true;
                        }
                    }
                }
                // Conflict types?
                foreach (DataGridItem r1 in this.GridView3.Items)
                {
                    if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        if (((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked)
                        {
                            t1 += Int32.Parse(r1.Cells[1].Text);
                        }
                        else
                        {
                            f1 = true;
                        }
                    }
                }
                // Set parameters
                accounts = a1.Substring(1);
                InventoryConflictSorts sortOrder = InventoryConflictSorts.SerialNo;
                conflictType = (InventoryConflictTypes)Enum.ToObject(typeof(InventoryConflictTypes), t1);
                iConflicts = InventoryConflict.GetConflictPage(pageNo, pageSize, accounts, conflictType, sortOrder, out x);
                // If no discrepancies exist, then set the page number to one.  Otherwise, if
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
                    iConflicts = InventoryConflict.GetConflictPage(pageNo, pageSize, accounts, conflictType, sortOrder, out x);
                }
                // Bind the data
                DataGrid1.DataSource = iConflicts;
                DataGrid1.DataBind();
                // Page links
                this.lnkPagePrev.Enabled  = pageNo != 1;
                this.lnkPageFirst.Enabled = pageNo != 1;
                this.lnkPageNext.Enabled  = pageNo != pageTotal;
                this.lnkPageLast.Enabled  = pageNo != pageTotal;
                this.lblPage.Text = String.Format("Page {0} of {1}", pageNo, pageTotal);
                // Viewstate
                this.ViewState["Conflicts"] = iConflicts;
                this.ViewState["Accounts"] = accounts;
                this.ViewState["Type"] = conflictType;
                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
                // Filtered?
                if (f1)
                {
                    this.FilterLink.ForeColor = System.Drawing.Color.Red;
                    this.FilterLink.Text = "RESULTS FILTERED";
                }
                else
                {
                    this.FilterLink.ForeColor = System.Drawing.Color.Black;
                    this.FilterLink.Text = "RESULTS UNFILTERED";
                }
                // If we don't have any results, then there are no discrepancies.  Display the message box if requested.
                if (iConflicts.Count == 0 && messageBox == true)
                {
                    this.ShowMessageBox("zeroConflicts", "msgBoxNone");
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Handler for the Go button click event
        /// </summary>
        private void btnGo_Click()
        {
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue.ToUpper())
                {
                    case "IGNORE":
                        this.IgnoreConflicts();
                        break;
                    case "MISSING":
                        this.MarkMissing(0);
                        break;
                    case "MOVE":
                        this.SwitchLocation();
                        break;
                    case "ADD":
                        this.CreateMedia();
                        break;
                    case "ADDCASE":
                        this.CreateCases();
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Designate the selected media as missing
        /// </summary>
        private void MarkMissing(int caseAction)
        {
            MediumCollection mediumCollection = this.RetrieveCheckedMedia();
            // Mark the media as missing
            foreach(MediumDetails m in mediumCollection) m.Missing = true;
            // Update the medium collection.  If the update function returns true, 
            // then we should refetch the discrepancies.  If false, then a case
            // violation occurred and we should display the message box.
            try
            {
                if (Medium.Update(ref mediumCollection, caseAction))
                {
                    this.FetchConflicts(true);
                }
                else
                {
                    this.ShowMessageBox("msgBoxMissing");
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
        /// Create media from the checked items
        /// </summary>
        private void CreateMedia()
        {
            try
            {
                foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                {
                    if (iConflicts[i.ItemIndex].ConflictType == InventoryConflictTypes.UnknownSerial)
                    {
                        Locations l = iConflicts[i.ItemIndex].Details.ToLower().IndexOf("enterprise") != -1 ? Locations.Enterprise : Locations.Vault;
                        MediumDetails m = new MediumDetails(iConflicts[i.ItemIndex].SerialNo, String.Empty, String.Empty, l, String.Empty, String.Empty);
                        Medium.Insert(ref m);
                    }
                }
                // Fetch the conflicts
                this.FetchConflicts(true);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
                // Fetch the conflicts here b/c we may have added one or more items before crapping out
                this.FetchConflicts(true);
            }
        }
        /// <summary>
        /// Create empty sealed cases from the checked items
        /// </summary>
        private void CreateCases()
        {
            try
            {

                foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                {
                    if (iConflicts[i.ItemIndex].ConflictType == InventoryConflictTypes.UnknownSerial)
                    {
                        SealedCase.Insert(new SealedCaseDetails(iConflicts[i.ItemIndex].SerialNo, String.Empty, String.Empty, String.Empty));
                    }
                }
                // Fetch the conflicts
                this.FetchConflicts(true);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
                // Fetch the conflicts here b/c we may have added one or more items before crapping out
                this.FetchConflicts(true);
            }
        }
        /// <summary>
        /// Move the media to the opposite of its current location
        /// </summary>
        private void SwitchLocation()
        {
            MediumCollection mediumCollection = this.RetrieveCheckedMedia();
            // Switch the location for each of the media in the collection
            foreach (MediumDetails m in mediumCollection)
            {
                switch (m.Location)
                {
                    case Locations.Enterprise:
                        m.Location = Locations.Vault;
                        break;
                    case Locations.Vault:
                        m.Location = Locations.Enterprise;
                        break;
                }            
            }
            // Update the media.  We don't have to worry about case violations here
            // because we are not marking anything as missing.
            try
            {
                Medium.Update(ref mediumCollection, 0);
                this.FetchConflicts(true);
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
        /// Ignore the inventory conflicts
        /// </summary>
        private void IgnoreConflicts()
        {
            // Create collection to hold the conflicts to be ignored
            InventoryConflictCollection ignoreThese = new InventoryConflictCollection();
            // Collect the items
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                ignoreThese.Add(iConflicts[i.ItemIndex]);
            // Ignore each in turn
            try
            {
                InventoryConflict.IgnoreConflicts(ref ignoreThese);
                this.FetchConflicts(true);
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
        /// Gathers the checked items into a medium collection.  Simply a convenience method.
        /// </summary>
        private MediumCollection RetrieveCheckedMedia()
        {
            MediumCollection m = new MediumCollection();
            // Retrieve each medium and add it to the collection
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                m.Add(Medium.GetMedium(i.Cells[1].Text));
            // Return the collection
            return m;
        }
        /// <summary>
        /// Transfers to the file upload page
        /// </summary>
        private void btnUpload_Click(object sender, System.EventArgs e)
        {
            switch (TabPageDefault.GetDefault(TabPageDefaults.InventoryFile, Context.Items[CacheKeys.Login]))
            {
                case 1:
                    Server.Transfer("reconcile-inventory-batch.aspx");
                    break;
                case 2:
                    Server.Transfer("reconcile-inventory-rfid.aspx");
                    break;
            }
        }
        /// <summary>
        /// Event handler for button which, when pressed, instructs the system
        /// to remove a medium from a sealed case.
        /// </summary>
        private void btnSolo_Click(object sender, System.EventArgs e)
        {
            this.MarkMissing(1);
        }
        /// <summary>
        /// Event handler for button which, when pressed, instructs the system
        /// to mark an entire sealed case as missing.
        /// </summary>
        private void btnCase_Click(object sender, System.EventArgs e)
        {
            this.MarkMissing(2);
        }
        /// <summary>
        /// Event handler for the text changed event of the page textbox.  Goes
        /// to the page number in the text box when the user clicks enter.
        /// </summary>
        private void txtPageGoto_TextChanged(object sender, System.EventArgs e)
        {
            pageNo = Convert.ToInt32(this.txtPageGoto.Text);
            this.txtPageGoto.Text = String.Empty;
            this.FetchConflicts(false);
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintInventory;
            Session[CacheKeys.Object] = new object[] {conflictType, accounts};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }

        private void btnAccountOK_Click(object sender, System.EventArgs e)
        {
            String s1 = String.Empty;
            // Accounts?
            foreach (DataGridItem r1 in this.GridView1.Items)
            {
                if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                {
                    if (((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked)
                    {
                        s1 += "," + r1.Cells[1].Text;
                    }
                }
            }
            // Redirect?
            if (s1.Length != 0)
            {
                String u1 = String.Format("../waitPage.aspx?redirectPage=media-library/reconcile-inventory.aspx&box=1&download=1&i={0}&x={1}", s1.Substring(1), Guid.NewGuid().ToString("N"));
                Session[CacheKeys.WaitRequest] = RequestTypes.InventoryReconcile;
                Response.Redirect(u1, false);
            }
        }
    }
}
