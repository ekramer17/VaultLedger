using System;
using System.Text;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_receive_list_manual_scan_step_one.
	/// </summary>
	public class new_receive_list_manual_scan_step_one : BasePage
	{
        private ReceiveListDetails rl = null;
        private bool displayTabs = true;
        
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.TextBox txtSerialNum;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnAuto;
        protected System.Web.UI.WebControls.TextBox txtNotes;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnAdd;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNext;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls;
        protected System.Web.UI.WebControls.TextBox txtAccounts;
        protected System.Web.UI.WebControls.DataGrid GridView1;
        protected System.Web.UI.WebControls.Button btnAccountOK;
        protected System.Web.UI.WebControls.Button btnAccountCancel;
        protected System.Web.UI.WebControls.DropDownList ddlAccounts;
        protected System.Web.UI.HtmlControls.HtmlInputHidden hidden1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl accountDetail;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;		

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
            this.btnAccountOK.Click += new System.EventHandler(this.btnAccountOK_Click);
            this.btnAuto.ServerClick += new System.EventHandler(this.btnAuto_ServerClick);
            this.btnNext.ServerClick += new System.EventHandler(this.btnNext_ServerClick);
            this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_ServerClick);
            this.Load += new System.EventHandler(this.Page_Load);

        }
        #endregion

        public bool DisplayTabs { get {return displayTabs;} }

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 16;
            this.levelTwo = LevelTwoNav.Receiving;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Hide the message box on button click
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxNone');");
            this.SetControlAttr(this.btnAccountOK, "onclick", "hideMsgBox('msgBoxAccounts');");
            this.SetControlAttr(this.btnAccountCancel, "onclick", "hideMsgBox('msgBoxAccounts');");
            this.SetControlAttr(this.ddlAccounts, "onchange", "onChange(this);");
            // Apply bar code format editing
            this.BarCodeFormat(new Control[] {this.txtSerialNum}, this.btnAdd);
            // Set the default buttons for controls
            this.SetDefaultButton(this.accountDetail, "btnAdd");
            // Table checkerd
            ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString(), "<script type=\"text/javascript\">var x1 = new TableChecker(1).initialize('GridView1')</script>");
            // Load the page
            if (Page.IsPostBack)
            {
                displayTabs = (bool)this.ViewState["DisplayTabs"];
                if (this.ViewState["ListObject"] != null)
                    rl = (ReceiveListDetails)this.ViewState["ListObject"];
            }
            else
            {
                string cancelUrl = String.Empty;
                this.txtReturnDate.Text = DisplayDate(DateTime.UtcNow, true, false);
                // Caption depends on whether or not we're creating a new list
                // or editing an existing list.
                if (this.Request.QueryString["listNumber"] == null)
                {
                    this.lblCaption.Text = "New Receiving List";
                }
                else
                {
                    rl = ReceiveList.GetReceiveList(Request.QueryString["listNumber"], true);
                    this.lblCaption.Text = "Edit Receiving List  :  " + rl.Name;
                    this.ViewState["ListObject"] = rl;
                }
                // Determine the cancel button url and whethere we should display tabs or
                // not.  Tabs should not be displayed if we're editing a list, but they
                // should be displayed if we're creating a new list.
                if (Context.Handler is receiving_list_detail)
                {
                    displayTabs = false;
                    cancelUrl = String.Format("receiving-list-detail.aspx?listNumber={0}", rl.Name);
                }
                else if (Context.Handler is todays_receiving_list)
                {
                    displayTabs = true;
                    cancelUrl = "todays-receiving-list.aspx";
                }
                else
                {
                    displayTabs = true;
                    cancelUrl = "receive-lists.aspx";
                }
                // Insert page fields into the viewstate
                this.ViewState["CancelUrl"] = cancelUrl;
                this.ViewState["DisplayTabs"] = displayTabs;
                // Set the tab page preference
                if (displayTabs)
                {
                    TabPageDefault.Update(TabPageDefaults.NewReceiveList, Context.Items[CacheKeys.Login], 1);
                }
                // Populate the accounts
                AccountCollection c1 = Account.GetAccounts(true);
                this.GridView1.DataSource = c1;
                this.GridView1.DataBind();
                this.PopulateAccounts(c1);
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
            if ((bool)this.ViewState["DisplayTabs"] == true)
            {
                this.tabControls.Visible = true;
                this.contentBorderTop.Visible = false;
            }
            else
            {
                this.tabControls.Visible = false;
                this.contentBorderTop.Visible = true;
            }
            // Create a datatable and bind it to the grid so that the table will render
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("Notes", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Select the text in the serial number text box
            this.SelectText(this.txtSerialNum);
            // Set the focus to the serial number box
            this.DoFocus(this.txtSerialNum);
        }
        /// <summary>
        /// Event handler for the Next button
        /// </summary>
        private void btnNext_ServerClick(object sender, System.EventArgs e)
        {
            string s = tableContents.Value;
            ReceiveListItemCollection rlc = new ReceiveListItemCollection();

			if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
			{
				if (Preference.GetPreference(PreferenceKeys.ReceiveListAdminOnly).Value == "YES")
				{
					this.DisplayErrors(this.PlaceHolder1, "Only administrators are allowed to manually create receiving lists");
					return;
				}
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
                    // Note
                    string itemNote = x.Substring(0, x.LastIndexOf('`'));
                    // Is this serial number a case or a medium?  Add the item(s)
                    // to the collection
                    if (SealedCase.GetSealedCase(serial) == null)
                    {
                        rlc.Add(new ReceiveListItemDetails(serial, itemNote));
                    }
                    else
                    {
                        foreach (MediumDetails m in SealedCase.GetResidentMedia(serial))
                            if (rlc.Find(m.SerialNo) == null)
                                rlc.Add(new ReceiveListItemDetails(m.SerialNo, itemNote));
                    }
                    // Truncate the data string
                    s = s.Length > d1 + 3 ? s.Substring(d1 + 3) : String.Empty;
                }
                // Create the list
                if (rl != null)
                {
                    ReceiveList.AddItems(ref rl, ref rlc);
                }
                else
                {
                    rl = ReceiveList.Create(rlc);
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
            // Transfer to the detail page
            Server.Transfer("receiving-list-detail.aspx?listNumber=" + rl.Name);
        }
        /// <summary>
        /// Event handler for cancel button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect((string)this.ViewState["CancelUrl"], false);
        }
        /// <summary>
        /// Autogenerate a list
        /// </summary>
        private void btnAuto_ServerClick(object sender, System.EventArgs e)
        {
			if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
			{
				if (Preference.GetPreference(PreferenceKeys.ReceiveListAdminOnly).Value == "YES")
				{
					this.DisplayErrors(this.PlaceHolder1, "Only administrators are allowed to manually create receiving lists");
					return;
				}
			}
			
			DateTime d = new DateTime(1900, 1, 1);

            if (txtReturnDate.Text.Trim().Length == 0)
            {
                d = Time.Today;
            }
            else
            {
                try
                {
                    d = Date.ParseExact(txtReturnDate.Text.Trim());
                }
                catch
                {
                    this.DisplayErrors(this.PlaceHolder1, "Illegal date format");
                    this.SelectText(txtReturnDate);
                    this.DoFocus(txtReturnDate);
                    return;
                }
            }

            try
            {
                if ((rl = ReceiveList.Create(d.AddHours(23).AddMinutes(59).AddSeconds(59), this.ddlAccounts.SelectedValue)) == null)
                {
                    this.ShowMessageBox("msgBoxNone");
                }
                else
                {
                    Server.Transfer("receiving-list-detail.aspx?listNumber=" + rl.Name);
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }

        private void PopulateAccounts(AccountCollection c1)
        {
            this.ddlAccounts.Items.Clear();
            this.ddlAccounts.Items.Add(new ListItem("(All accounts)", String.Empty));
            foreach (AccountDetails a1 in c1) this.ddlAccounts.Items.Add(new ListItem(a1.Name, a1.Id.ToString()));
            this.ddlAccounts.Items.Add(new ListItem("Select multiple ...", String.Empty));
        }

        private void btnAccountOK_Click(object sender, System.EventArgs e)
        {
            int y1 = 0;
            int y2 = 0;
            string s1 = String.Empty;
            string s2 = String.Empty;

            if (this.hidden1.Value.Length != 0)
            {
                foreach (DataGridItem r1 in GridView1.Items)
                {
                    if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        if (((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked)
                        {
                            s1 += "," + r1.Cells[2].Text;
                            s2 += "," + r1.Cells[1].Text;
                            y1 += 1;
                        }
                        else
                        {
                            y2 += 1;
                        }
                    }
                }
                // Populate dropdown
                this.PopulateAccounts(Account.GetAccounts(true));
                // All accounts?
                if (y1 == 0 || y2 == 0)
                {
                    this.ddlAccounts.SelectedIndex = 0;
                }
                else
                {
                    // Add string as second to last item
                    this.ddlAccounts.Items.Insert(this.ddlAccounts.Items.Count - 1, new ListItem(s1.Substring(1), s2.Substring(1)));
                    // Select in the drop down
                    this.ddlAccounts.SelectedIndex = this.ddlAccounts.Items.Count - 2;
                }
            }
        }
	}
}
