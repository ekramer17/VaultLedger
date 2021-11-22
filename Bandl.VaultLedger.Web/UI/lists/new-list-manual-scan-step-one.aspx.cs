using System;
using System.Data;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_list_template.
	/// </summary>
	public class new_list_manual_scan_step_one : BasePage
	{
        private SendListDetails sl = null;
        private string cancelUrl;
        private bool displayTabs;

		protected System.Web.UI.WebControls.TextBox txtSerialNum;
		protected System.Web.UI.WebControls.TextBox txtCaseNum;
		protected System.Web.UI.WebControls.TextBox txtDescription;
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.TextBox txtReturnDate;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnDelete;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNext;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.HtmlControls.HtmlGenericControl bottomContent;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.WebControls.Label lblAccount;
        protected System.Web.UI.HtmlControls.HtmlTableCell accountCell;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnAdd;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls2;
        protected System.Web.UI.HtmlControls.HtmlInputHidden maxSerialLength;
        protected System.Web.UI.HtmlControls.HtmlInputHidden serialEditFormat;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentArea;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;

        // Public properties for server transfer
        public string CancelUrl
        {
            get {return cancelUrl;}
        }

        public bool DisplayTabs
        {
            get {return displayTabs;}
        }

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
            this.btnNext.ServerClick += new System.EventHandler(this.btnNext_ServerClick);
            this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 10;
            this.levelTwo = LevelTwoNav.Shipping;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Apply bar code format editing
            this.BarCodeFormat(new Control[] {this.txtSerialNum, this.txtCaseNum}, this.btnAdd);
            // Set the default buttons for controls
            this.SetDefaultButton(this.contentArea, "btnAdd");
            // Load the page            
            if (Page.IsPostBack)
            {
                cancelUrl = (string)this.ViewState["CancelUrl"];
                displayTabs = (bool)this.ViewState["DisplayTabs"];
                if (this.ViewState["ListObject"] != null)
                    sl = (SendListDetails)this.ViewState["ListObject"];
            }
            else
            {
                // Caption depends on whether or not we're creating a new list
                // or editing an existing list.
                if (this.Request.QueryString["listNumber"] == null)
                {
                    this.lblCaption.Text = "New Shipping List&nbsp;&nbsp;-&nbsp;&nbsp;Step 1";
                }
                else
                {
                    sl = SendList.GetSendList(Request.QueryString["listNumber"], true);
                    this.lblCaption.Text = "Edit Shipping List : " + sl.Name;
                    this.ViewState["ListObject"] = sl;
                }
                // Determine the cancel button url and whethere we should display tabs or
                // not.  Tabs should not be displayed if we're editing a list, but they
                // should be displayed if we're creating a new list.
                if (Context.Handler is shipping_list_detail)
                {
                    displayTabs = false;
                    cancelUrl = String.Format("shipping-list-detail.aspx?listNumber={0}", sl.Name);
                }
                else if (Context.Handler is todays_list)
                {
                    displayTabs = true;
                    cancelUrl = "todays-list.aspx";
                }
                else if (Context.Handler is shipping_list_detail_edit_case)
                {
                    cancelUrl = ((shipping_list_detail_edit_case)Context.Handler).CancelUrl;
                    displayTabs = ((shipping_list_detail_edit_case)Context.Handler).DisplayTabs;
                }
                else
                {
                    displayTabs = true;
                    cancelUrl = "send-lists.aspx";
                }
                // Insert page fields into the viewstate
                this.ViewState["CancelUrl"] = cancelUrl;
                this.ViewState["DisplayTabs"] = displayTabs;
                // Get the accounts if necessary
                if (sl != null || Preference.GetPreference(PreferenceKeys.DeclareListAccounts).Value != "YES")
                {
                    lblAccount.Visible = false;
                    ddlAccount.Visible = false;
                }
                else
                {
                    lblAccount.Visible = true;
                    ddlAccount.Visible = true;
                    ddlAccount.Items.Add("-Select Account-");
                    foreach (AccountDetails a in Account.GetAccounts())
                        ddlAccount.Items.Add(a.Name);
                }
                // Set the tab page preference
                if (displayTabs) TabPageDefault.Update(TabPageDefaults.NewSendList, Context.Items[CacheKeys.Login], 1); 
                // Set the rfid characters to strip
                this.maxSerialLength.Value = Preference.GetPreference(PreferenceKeys.MaxRfidSerialLength).Value;
                // Set the rfid formatting parameter
                this.serialEditFormat.Value = ((int)Preference.GetSerialEditFormat()).ToString();
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            StringBuilder x = new StringBuilder();
            // Page title
            this.pageTitle = this.lblCaption.Text;
            // Show tabs if requested
            if ((bool)this.ViewState["DisplayTabs"] == true)
            {
                ProductLicenseDetails p = ProductLicense.GetProductLicense(LicenseTypes.RFID);
                this.tabControls1.Visible = p.Units != 1;
                this.tabControls2.Visible = p.Units == 1;
                this.contentBorderTop.Visible = false;
            }
            else
            {
                this.tabControls1.Visible = false;
                this.tabControls2.Visible = false;
                this.contentBorderTop.Visible = true;
            }
            // Create a datatable and bind it to the grid so that the table will render
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("ReturnDate", typeof(string));
            dataTable.Columns.Add("CaseName", typeof(string));
            dataTable.Columns.Add("Notes", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty, String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Select the contents of the serial number text box
            this.SelectText(this.txtSerialNum);
            // Set the focus to the serial number box
            this.DoFocus(this.txtSerialNum);
        }
        /// <summary>
        /// Event handler for the Next button
        /// </summary>
        private void btnNext_ServerClick(object sender, System.EventArgs e)
		{
            int i = 0;
            bool b = false;
            string s = tableContents.Value;
            SendListItemCollection c = new SendListItemCollection();
            // Check that an account has been assigned it we need it
            if (ddlAccount.Visible && ddlAccount.SelectedIndex == 0)
            {
                this.DisplayErrors(this.PlaceHolder1, "Please select an account for this list.");
                this.DoFocus(this.ddlAccount);
                return;
            
            }
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
                    // Return date
                    string rdate = x.Substring(0, x.IndexOf('`'));
                    x = x.Substring(x.IndexOf('`') + 1);
                    // Case name
                    string caseName = x.Substring(0, x.IndexOf('`'));
                    x = x.Substring(x.IndexOf('`') + 1);
                    // Note
                    string itemNote = x.Substring(0, x.LastIndexOf('`'));
                    // Add the item to the collection
                    c.Add(new SendListItemDetails(serial, rdate, itemNote, caseName));
                    // Truncate the data string
                    s = s.Length > d1 + 3 ? s.Substring(d1 + 3) : String.Empty;
                }
                // Create the list
                if (sl != null)
                {
                    if (!ddlAccount.Visible)
                    {
                        SendList.AddItems(ref sl, ref c, SLIStatus.Submitted);
                    }
                    else
                    {
                        SendList.AddItems(ref sl, ref c, SLIStatus.Submitted, ddlAccount.SelectedItem.Text);
                    }
                }
                else
                {
                    if (!ddlAccount.Visible)
                    {
                        sl = SendList.Create(c, SLIStatus.Submitted);
                    }
                    else
                    {
                        sl = SendList.Create(c, SLIStatus.Submitted, ddlAccount.SelectedItem.Text);
                    }
                }
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                return;
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
                return;
            }
            // Redirect to the case edit page if cases were given
            for (i = 0; i < c.Count && b == false; i++)
                b = c[i].CaseName.Length != 0;
            // Redirect to the next page
            Server.Transfer(String.Format("{0}.aspx?listNumber={1}", b == true ? "shipping-list-detail-edit-case" : "shipping-list-detail", sl.Name));
        }
        // Event handler for cancel button
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect((string)this.ViewState["CancelUrl"], false);
        }
	}
}
