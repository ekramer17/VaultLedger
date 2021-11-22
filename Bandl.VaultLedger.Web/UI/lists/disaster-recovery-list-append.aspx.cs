using System;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for append_recovery_list1.
    /// </summary>
    public class disaster_recovery_list_append : BasePage
    {
        private bool displayTabs = true;
        private DisasterCodeListDetails dl = null;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.TextBox txtSerialNo;
        protected System.Web.UI.WebControls.TextBox txtDisasterCode;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnAdd;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.HtmlControls.HtmlGenericControl topPanel;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;

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
            this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);
            this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_ServerClick);

        }
        #endregion
        
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 19;
            this.levelTwo = LevelTwoNav.DisasterRecovery;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Apply bar code format editing
            this.BarCodeFormat(new Control[] {this.txtSerialNo}, this.btnAdd);
            // Set the default buttons for controls
            this.SetDefaultButton(this.topPanel, "btnAdd");
            // Load the page
            if (Page.IsPostBack)
            {
                displayTabs = (bool)this.ViewState["DisplayTabs"];
                if (this.ViewState["ListObject"] != null)
                   dl = (DisasterCodeListDetails)this.ViewState["ListObject"];
            }
            else
            {
                string cancelUrl = String.Empty;
                // Caption depends on whether or not we're creating a new list
                // or editing an existing list.
                if (this.Request.QueryString["listNumber"] == null)
                {
                    this.lblCaption.Text = "New Disaster Recovery List";
                }
                else
                {
                    dl = DisasterCodeList.GetDisasterCodeList(Request.QueryString["listNumber"], true);
                    this.lblCaption.Text = "Edit Disaster Recovery List&nbsp;&nbsp;:&nbsp;&nbsp;" + dl.Name;
                    this.ViewState["ListObject"] = dl;
                }
                // Determine the cancel button url and whethere we should display tabs or
                // not.  Tabs should not be displayed if we're editing a list, but they
                // should be displayed if we're creating a new list.
                if (Context.Handler is disaster_recovery_list_detail)
                {
                    displayTabs = false;
                    cancelUrl = String.Format("disaster-recovery-list-detail.aspx?listNumber={0}", dl.Name);
                }
                else
                {
                    displayTabs = true;
                    cancelUrl = "disaster-recovery-list-browse.aspx";
                }
                // Insert page fields into the viewstate
                this.ViewState["CancelUrl"] = cancelUrl;
                this.ViewState["DisplayTabs"] = displayTabs;
                // Set the tab page preference
                if (displayTabs == true)
                    TabPageDefault.Update(TabPageDefaults.NewDisasterCodeList, Context.Items[CacheKeys.Login], 1);
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Page title
            this.pageTitle = this.lblCaption.Text;
            // Show tabs if requested
            this.tabControls.Visible = (bool)this.ViewState["DisplayTabs"];
            this.contentBorderTop.Visible = !((bool)this.ViewState["DisplayTabs"]);
            // Create a datatable and bind it to the grid so that the table will render
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("Code", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Select the contents of the serial number text box
            this.SelectText(this.txtSerialNo);
            // Set the focus to the serial number box
            this.DoFocus(this.txtSerialNo);
        }
        /// <summary>
        /// Event handler for save button
        /// </summary>
        public void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            string s = tableContents.Value;
            DisasterCodeListItemCollection dlic = new DisasterCodeListItemCollection();
            // Create or append to the list
            try
            {
                // Create the collection of items
                while (s.Length != 0)
                {
                    // Get the delimiter position
                    int d1 = s.IndexOf("`0;");
                    int d2 = s.IndexOf("`1;");
                    // Break if neither string found
                    if (d1 == -1 && d2 == -1) break;
                    // Get the smaller of the two (but must be positive)
                    if (d1 == -1 || (d2 != -1 && d2 < d1)) d1 = d2;
                    // Use d1 as the position from here on out               
                    string x = s.Substring(0, d1 + 2);
                    // Serial number
                    string serial = x.Substring(0, x.IndexOf('`'));
                    x = x.Substring(x.IndexOf('`') + 1);
                    // Note
                    string drcode = x.Substring(0, x.LastIndexOf('`'));
                    // Add the item to the collection
                    dlic.Add(new DisasterCodeListItemDetails(serial, drcode, String.Empty));
                    // Truncate the data string
                    s = s.Length > d1 + 3 ? s.Substring(d1 + 3) : String.Empty;
                }
                // Create the list
                if (dl != null)
                {
                    DisasterCodeList.AddItems(ref dl, ref dlic);
                }
                else
                {
                    dl = DisasterCodeList.Create(dlic);
                }
                // Redirect to the detail page
                Server.Transfer(String.Format("disaster-recovery-list-detail.aspx?listNumber={0}", dl.Name));
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
        /// Event handler for cancel button
        /// </summary>
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect((string)this.ViewState["CancelUrl"], false);
        }
    }
}
