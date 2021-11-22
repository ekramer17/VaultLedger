using System;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using System.Runtime.Remoting.Messaging;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for account_detail.
	/// </summary>
	public class account_detail : BasePage
	{
		private AccountDetails accountDetails = null;
        private const string NOFTPPROFILE = "(None Selected)";
		protected System.Web.UI.WebControls.Label lblAddress2;
		protected System.Web.UI.WebControls.Label lblCity;
		protected System.Web.UI.WebControls.Label lblState;
		protected System.Web.UI.WebControls.Label lblZipCode;		
		protected System.Web.UI.WebControls.Label lblCountry;
		protected System.Web.UI.WebControls.TextBox txtContact;
		protected System.Web.UI.WebControls.TextBox txtEmail;
		protected System.Web.UI.WebControls.TextBox txtNotes;
		protected System.Web.UI.WebControls.Button btnSave;
		protected System.Web.UI.WebControls.Table table;
        protected System.Web.UI.WebControls.TextBox txtTelephone;
        protected System.Web.UI.WebControls.Label lblAddress1;
        protected System.Web.UI.WebControls.TextBox txtAddress1;
        protected System.Web.UI.WebControls.TextBox txtAddress2;
        protected System.Web.UI.WebControls.TextBox txtCity;
        protected System.Web.UI.WebControls.TextBox txtZipCode;
        protected System.Web.UI.WebControls.TextBox txtState;
        protected System.Web.UI.WebControls.TextBox txtCountry;
        protected System.Web.UI.WebControls.Label lblFtpProfile;
        protected System.Web.UI.WebControls.DropDownList ddlFtpProfile;
        protected System.Web.UI.WebControls.Label lblPageCaption;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.Label lblAccountNum;
        protected System.Web.UI.WebControls.TextBox txtAccountNum;
        protected System.Web.UI.WebControls.Label lblGlobalAcct;
        protected System.Web.UI.HtmlControls.HtmlTableRow globalAccount;
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
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);

        }
        #endregion

        /// <summary>
        /// Modifies the page based on product type
        /// </summary>
        private void ConditionalPageSetup()
        {
            switch (Configurator.ProductType)
            {
                case "RECALL":
                    this.txtAccountNum.Visible = false;
                    this.txtAddress1.Visible = false;
                    this.txtAddress2.Visible = false;
                    this.txtCity.Visible = false;
                    this.txtZipCode.Visible = false;
                    this.txtState.Visible = false;
                    this.txtCountry.Visible = false;
                    break;
                case "B&L":
                case "BANDL":
                case "IMATION":
                    this.lblPageCaption.Text = "View and, if desired, edit the details of a particular account.";
                    this.lblAccountNum.Visible = false;
                    this.lblAddress1.Visible = false;
                    this.lblAddress2.Visible = false;
                    this.lblCity.Visible = false;
                    this.lblZipCode.Visible = false;
                    this.lblState.Visible = false;
                    this.lblCountry.Visible = false;
                    this.globalAccount.Visible = false;
                    break;
            }
            // Show the FTP profile dropdown if XmiMethod is FTP
            if (Configurator.XmitMethod == "FTP")
            {
                this.lblFtpProfile.Visible = true;
                this.ddlFtpProfile.Visible = true;
                this.ddlFtpProfile.Items.Add(NOFTPPROFILE);
                foreach (FtpProfileDetails ftpProfile in FtpProfile.GetProfiles())
                    this.ddlFtpProfile.Items.Add(ftpProfile.Name);
            }
            else
            {
                this.lblFtpProfile.Visible = false;
                this.ddlFtpProfile.Visible = false;
            }
        }
        /// <summary>
        /// Fills the control fields, which is also dependent on product type
        /// </summary>
        private void PopulateControls()
        {
            if (accountDetails == null)
            {
                if (this.ddlFtpProfile.Visible)
                    this.ddlFtpProfile.SelectedIndex = 0;
            }
            else
            {
                // Common fields
                this.txtContact.Text = accountDetails.Contact;
                this.txtTelephone.Text = accountDetails.PhoneNo;
                this.txtEmail.Text = accountDetails.Email;
                this.txtNotes.Text = accountDetails.Notes;
                // FTP dropdown
                if (this.ddlFtpProfile.Visible)
                {
                    if (accountDetails.FtpProfile.Length != 0)
                        this.ddlFtpProfile.SelectedValue = accountDetails.FtpProfile;
                    else
                        this.ddlFtpProfile.SelectedIndex = 0;
                }
                // Labels or textboxes depend on product type
                switch (Configurator.ProductType)
                {
                    case "RECALL":
                        this.lblAccountNum.Text = accountDetails.Name;
                        this.lblGlobalAcct.Text = accountDetails.Primary ? "Yes" : "No";
                        this.lblAddress1.Text = accountDetails.Address1;
                        this.lblAddress2.Text = accountDetails.Address2;
                        this.lblCity.Text = accountDetails.City;
                        this.lblState.Text = accountDetails.State;
                        this.lblZipCode.Text = accountDetails.ZipCode;
                        this.lblCountry.Text = accountDetails.Country;
                        break;
                    case "B&L":
                    case "BANDL":
                    case "IMATION":
                        this.txtAccountNum.Text = accountDetails.Name;
                        this.txtAddress1.Text = accountDetails.Address1;
                        this.txtAddress2.Text = accountDetails.Address2;
                        this.txtCity.Text = accountDetails.City;
                        this.txtState.Text = accountDetails.State;
                        this.txtZipCode.Text = accountDetails.ZipCode;
                        this.txtCountry.Text = accountDetails.Country;
                        break;
                }
            }
        }

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 53;
            this.levelTwo = LevelTwoNav.Accounts;
            this.pageTitle = "Account Detail";
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
            // Set up the page
            this.ConditionalPageSetup();
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
			if (Page.IsPostBack)
			{
				accountDetails = (AccountDetails)this.ViewState["AccountDetails"];
			}
			else if (Context.Handler is accounts)	// Server.Transfer used only when adding new account
			{
				accountDetails = null;
				this.ViewState["AccountDetails"] = accountDetails;
				// Fill the account fields
				this.PopulateControls();
			}
			else
            {
                try
                {
                    string accountName = Request.QueryString["accountNo"];
                    accountDetails = accountName != null ? Account.GetAccount(Request.QueryString["accountNo"]) : null;
                    this.ViewState["AccountDetails"] = accountDetails;
                    // Fill the account fields
                    this.PopulateControls();
                }
                catch
                {
                    Response.Redirect("index.aspx", false);
                }
            }
        }
        /// <summary>
        /// Save button event handler
        /// </summary>
		private void btnSave_Click(object sender, System.EventArgs e)
		{		
            try
            {
                if (accountDetails == null)
                {
                    // Create a new account
                    AccountDetails newOne = new AccountDetails(txtAccountNum.Text, false, txtAddress1.Text, txtAddress2.Text, txtCity.Text,
                        txtState.Text, txtZipCode.Text, txtCountry.Text, txtContact.Text, txtTelephone.Text, txtEmail.Text, txtNotes.Text,
                        this.ddlFtpProfile.Visible && this.ddlFtpProfile.SelectedIndex != 0 ? ddlFtpProfile.SelectedItem.Text : String.Empty);
                    // Add it to the database
                    Account.Insert(ref newOne);
                    // Redirect to the accounts page
                    Response.Redirect("accounts.aspx", false);
                }
                else
                {
                    // Set account fields
                    accountDetails.Contact = txtContact.Text;
                    accountDetails.PhoneNo = txtTelephone.Text;
                    accountDetails.Email = txtEmail.Text;
                    accountDetails.Notes = txtNotes.Text;
                    // Fill the other fields is the textboxes are visible
                    if (this.txtAddress1.Visible)
                    {
                        accountDetails.Name = this.txtAccountNum.Text;
                        accountDetails.Address1 = this.txtAddress1.Text;
                        accountDetails.Address2 = this.txtAddress2.Text;
                        accountDetails.City = this.txtCity.Text;
                        accountDetails.State = this.txtState.Text;
                        accountDetails.ZipCode = this.txtZipCode.Text;
                        accountDetails.Country = this.txtCountry.Text;
                    }
                    // FTP profile
                    if (this.ddlFtpProfile.Visible && this.ddlFtpProfile.SelectedIndex != 0)
                    {
                        accountDetails.FtpProfile = this.ddlFtpProfile.SelectedItem.Text;
                    }
                    else
                    {
                        accountDetails.FtpProfile = String.Empty;
                    }
                    // Update the account
                    Account.Update(ref accountDetails);
                    // Redirect to the accounts page
                    Response.Redirect("accounts.aspx", false);
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Print event
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.AccountDetailPage;
            Session[CacheKeys.PrintObjects] = new object[] {this.accountDetails};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
    }
}
