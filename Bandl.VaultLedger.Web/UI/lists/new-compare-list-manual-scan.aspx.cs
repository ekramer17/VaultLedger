using System;
using System.Web;
using System.Data;
using System.Web.UI;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_compare_list_manual_scan.
	/// </summary>
	public class new_compare_list_manual_scan : BasePage
	{
        SendListDetails pageList = null;
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.TextBox txtFileName;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtSerialNo;
        protected System.Web.UI.WebControls.TextBox txtCaseName;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl todaysList;
        protected System.Web.UI.HtmlControls.HtmlAnchor batchLink;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnAdd;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.WebControls.Button btnDefault;
        protected System.Web.UI.HtmlControls.HtmlAnchor rfidLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;
        protected System.Web.UI.HtmlControls.HtmlAnchor batchLinkTwo;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabThree;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabTwo;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
	
        public SendListDetails ListObject { get {return pageList;} }

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
            this.batchLink.ServerClick += new System.EventHandler(this.batchLink_ServerClick);
            this.rfidLink.ServerClick += new System.EventHandler(this.rfidLink_ServerClick);
            this.batchLinkTwo.ServerClick += new System.EventHandler(this.batchLink_ServerClick);
            this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);
            this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 13;
            this.levelTwo = LevelTwoNav.Shipping;
            this.pageTitle = "New Shipping Compare File";
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                pageList = (SendListDetails)this.ViewState["PageList"];
            }
            else
            {
                if (Context.Handler is shipping_list_reconcile)
                {
                    pageList = ((shipping_list_reconcile)Context.Handler).ListObject;
                }
                else if (Context.Handler is new_compare_list_batch_file_step_one)
                {
                    pageList = ((new_compare_list_batch_file_step_one)Context.Handler).ListObject;
                }
                else if (Context.Handler is new_compare_list_rfid_file_step_one)
                {
                    pageList = ((new_compare_list_rfid_file_step_one)Context.Handler).ListObject;
                }
                else
                {
                    Response.Redirect("send-lists.aspx");
                }
                // Insert list into viewstate
                this.ViewState["PageList"] = pageList;
                // Display default compare file name
                this.txtFileName.Text = Date.Display(Time.Local, true, true, true);
                // Set the tab page preference
                TabPageDefault.Update(TabPageDefaults.SendReconcileNewFile, Context.Items[CacheKeys.Login], 1);
                // Create page caption
                lblCaption.Text = String.Format("New Shipping Compare File&nbsp;&nbsp;:&nbsp;&nbsp;List {0}", pageList.Name);
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Apply bar code format editing
            this.BarCodeFormat(new Control[] {this.txtSerialNo, this.txtCaseName}, this.btnAdd, true);
            // Set up datagrid so that it has one blank row
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("CaseName", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Which tabs are visible?
            ProductLicenseDetails p = ProductLicense.GetProductLicense(LicenseTypes.RFID);
            this.threeTabs.Visible = p.Units == 1;
            this.twoTabs.Visible = p.Units != 1;
            // Render the bottom portion invisible
            this.SetControlAttr(this.todaysList, "style", "display:none", false);
            // Select the text in the serial number text box
            this.SelectText(this.txtSerialNo);
            // Set focus to the serial number text box
            this.DoFocus(this.txtSerialNo);
        }
        /// <summary>
        /// Event handler for the save button
        /// </summary>
        private void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            // Make sure there is a file name
            if (this.txtFileName.Text.Trim().Length == 0)
            {
                this.DisplayErrors(this.PlaceHolder1, "Please enter a name for the new compare file");
            }
            else
            {
                SendListScanItemCollection scanItems = new SendListScanItemCollection();
                // Get the value of the hidden field
                string[] itemEntries = this.tableContents.Value.Split(new char[] {';'});
                // Make sure there is a file name
                if (itemEntries.Length == 1 && itemEntries[0] == String.Empty)
                {
                    this.DisplayErrors(this.PlaceHolder1, "At least one serial number must be entered in order to create a new compare file");
                }
                else
                {
                    // Add the entries to the scan items collection
                    foreach (string singleItem in itemEntries)
                    {
                        if (singleItem.Length != 0)
                        {
                            string[] splitFields = singleItem.Split(new char[] {'|'});
                            scanItems.Add(new SendListScanItemDetails(splitFields[0], splitFields[1]));
                        }
                    }
                    // Create the compare file and redirect to the reconcile page
                    try
                    {   
                        SendList.CreateScan(pageList.Name, this.txtFileName.Text.Trim(), ref scanItems);
                        Response.Redirect(String.Format("shipping-list-reconcile.aspx?listNumber={0}", pageList.Name), true);
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
        }
        /// <summary>
        /// Event handler for the cancel button
        /// </summary>
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect(String.Format("shipping-list-reconcile.aspx?listNumber={0}", pageList.Name), true);
        }
        /// <summary>
        /// Transfer to batch scan page
        /// </summary>
        private void batchLink_ServerClick(object sender, System.EventArgs e)
        {
            Server.Transfer("new-compare-list-batch-file-step-one.aspx");
        }
        /// <summary>
        /// Transfer to rfid scan page
        /// </summary>
        private void rfidLink_ServerClick(object sender, System.EventArgs e)
        {
            Server.Transfer("new-compare-list-rfid-file-step-one.aspx");
        }
    }
}
