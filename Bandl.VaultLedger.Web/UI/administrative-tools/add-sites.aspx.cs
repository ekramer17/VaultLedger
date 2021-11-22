using System;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for add_sites.
	/// </summary>
	public class add_sites : BasePage
	{
		protected System.Web.UI.WebControls.Button btnSave;
		protected System.Web.UI.WebControls.TextBox txtSiteName;
		protected System.Web.UI.WebControls.DropDownList ddlLocation;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvSiteName;
        protected System.Web.UI.WebControls.RegularExpressionValidator revLocation;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowAccount;
		protected System.Web.UI.HtmlControls.HtmlForm Form1;
		
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
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);

        }
		#endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "New Site Map";
            this.levelTwo = LevelTwoNav.SiteMaps;
            this.helpId = 26;
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // If not a postback, see if we should get the accounts
            if (!IsPostBack)
            {
                // Get the preference
                PreferenceDetails p = Preference.GetPreference(PreferenceKeys.AllowTMSAccountAssigns);
                // Get the accounts
                if (p.Value == "YES")
                    foreach(AccountDetails d in Account.GetAccounts())
                        ddlAccount.Items.Add(new ListItem(d.Name, d.Name));
                // Account row visibility
                this.rowAccount.Visible = p.Value == "YES";
            }
            // Focus
            this.DoFocus(txtSiteName);
        }
        /// <summary>
        /// Save button event handler
        /// </summary>
		private void btnSave_Click(object sender, System.EventArgs e)
		{
            try
            {
                string accountName = String.Empty;
                PreferenceDetails p = Preference.GetPreference(PreferenceKeys.AllowTMSAccountAssigns);
                // Get account?
                if (p.Value == "YES" && ddlAccount.SelectedIndex > 1)
                    accountName = ddlAccount.SelectedValue;
                // Create new site details structure
                ExternalSiteDetails d = new ExternalSiteDetails(txtSiteName.Text, 
                                                               (Locations)(Convert.ToInt32(ddlLocation.SelectedValue)),
                                                               accountName);
                // Insert the new site map
                ExternalSite.Insert(ref d);
                // Redirect to the browse page
                Response.Redirect("view-sites.aspx", false);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
		}
	}
}
