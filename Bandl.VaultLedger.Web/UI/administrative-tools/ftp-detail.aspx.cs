using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for ftp_detail.
	/// </summary>
	public class ftp_detail : BasePage
	{
        private FtpProfileDetails ftpProfile;
        private string samePwd = "f6HeTk";
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtName;
        protected System.Web.UI.WebControls.TextBox txtServer;
        protected System.Web.UI.WebControls.TextBox txtLogin;
        protected System.Web.UI.WebControls.TextBox txtFilePath;
        protected System.Web.UI.WebControls.DropDownList ddlPassive;
        protected System.Web.UI.WebControls.DropDownList ddlSecure;
        protected System.Web.UI.WebControls.DropDownList ddlFormat;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.Label lblPageTitle;
        protected System.Web.UI.WebControls.TextBox txtPassword1;
        protected System.Web.UI.WebControls.TextBox txtPassword2;
        protected System.Web.UI.WebControls.Label lblPageCaption;
    
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
            this.levelTwo = LevelTwoNav.FtpProfiles;
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                if (this.ViewState["ProfileDetails"] != null)
                {
                    ftpProfile = (FtpProfileDetails)this.ViewState["ProfileDetails"];
                }
            }
            else
            {
                try
                {
                    if (Request.QueryString["profile"] != null)
                    {
                        ftpProfile = FtpProfile.GetProfile(Request.QueryString["profile"]);
                        this.ViewState["ProfileDetails"] = ftpProfile;
                        // Populate the controls
                        this.PopulateControls();
                    }
                }
                catch
                {
                    Response.Redirect("index.aspx", false);
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (ftpProfile != null)
            {
                this.helpId = 58;
                this.pageTitle = "FTP Profile Detail";
                this.lblPageTitle.Text = String.Format("{0}&nbsp;&nbsp;:&nbsp;&nbsp;{1}", this.pageTitle, ftpProfile.Name);
            }
            else
            {
                this.helpId = 52;
                this.pageTitle = "New FTP Profile";
                this.lblPageTitle.Text = this.pageTitle;
                this.lblPageCaption.Text = "Create a new FTP profile";
            }
            // Set control focus
            this.DoFocus(this.txtName);
        }
        /// <summary>
        /// Populate the controls if we're given a profile
        /// </summary>
        private void PopulateControls()
        {
            this.txtName.Text = ftpProfile.Name;
            this.txtServer.Text = ftpProfile.Server;
            this.txtLogin.Text = ftpProfile.Login;
            this.txtFilePath.Text = ftpProfile.FilePath;
            this.txtPassword1.Text = ftpProfile.Password;
            this.ddlSecure.SelectedValue = ftpProfile.Secure.ToString();
            this.ddlPassive.SelectedValue = ftpProfile.Passive.ToString();
            this.ddlFormat.SelectedValue = ((short)ftpProfile.Format).ToString();
            // We have to use a startup script because password fields won't initialize by setting text
            ClientScript.RegisterStartupScript(GetType(), "Pwd1", "<script language=javascript>getObjectById('txtPassword1').value = '" + samePwd + "'</script>");
            ClientScript.RegisterStartupScript(GetType(), "Pwd2", "<script language=javascript>getObjectById('txtPassword2').value = '" + samePwd + "'</script>");
        }
        /// <summary>
        /// Save button event handler
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            // Make sure the user has selected a file format
            if (this.ddlFormat.SelectedItem == this.ddlFormat.Items[0])
            {
                this.DisplayErrors(this.PlaceHolder1, "Please select a file format");
            }
            else if (this.txtPassword1.Text != this.txtPassword2.Text)
            {
                this.DisplayErrors(this.PlaceHolder1, "Passwords do not match");
            }
            else 
            {
                try
                {
                    FtpProfileDetails.Formats fileFormat = (FtpProfileDetails.Formats)Enum.ToObject(typeof(FtpProfileDetails.Formats),Convert.ToInt16(this.ddlFormat.SelectedValue));

                    if (ftpProfile != null)
                    {
                        ftpProfile.Name = this.txtName.Text;
                        ftpProfile.Server = this.txtServer.Text;
                        ftpProfile.Login = this.txtLogin.Text;
                        if (this.txtPassword1.Text != samePwd)
                            ftpProfile.Password = this.txtPassword1.Text;
                        ftpProfile.FilePath = this.txtFilePath.Text;
                        ftpProfile.Secure = Convert.ToBoolean(this.ddlSecure.SelectedValue);
                        ftpProfile.Passive = Convert.ToBoolean(this.ddlPassive.SelectedValue);
                        ftpProfile.Format = fileFormat;
                        FtpProfile.Update(ref ftpProfile);
                    }
                    else
                    {
                        ftpProfile = new FtpProfileDetails(this.txtName.Text,
                            this.txtServer.Text,
                            this.txtLogin.Text,
                            this.txtPassword1.Text,
                            this.txtFilePath.Text,
                            fileFormat,
                            Convert.ToBoolean(this.ddlPassive.SelectedValue),
                            Convert.ToBoolean(this.ddlSecure.SelectedValue));
                        FtpProfile.Insert(ref ftpProfile);
                    }
                    // Go to the profile listing page
                    Server.Transfer("ftp-profiles.aspx");
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
    }
}
