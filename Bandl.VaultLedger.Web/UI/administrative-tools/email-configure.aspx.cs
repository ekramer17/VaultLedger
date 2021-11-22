using System;
using System.Text;
using System.Web.Mail;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for email_configure.
	/// </summary>
	public class email_configure : BasePage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtServerName;
        protected System.Web.UI.WebControls.TextBox txtFromAddress;
        protected System.Web.UI.WebControls.TextBox txtPassword;
        protected System.Web.UI.HtmlControls.HtmlGenericControl BadPassword;
        protected System.Web.UI.WebControls.Button x1;
        protected System.Web.UI.WebControls.Button DoTest;
        protected System.Web.UI.WebControls.Button DoRedirect;
        protected System.Web.UI.WebControls.Button DoPassword;
        protected System.Web.UI.WebControls.Button SaveButton;
        protected System.Web.UI.WebControls.TextBox txtToAddress;
    
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
            this.DoTest.Click += new System.EventHandler(this.DoTest_Click);
            this.SaveButton.Click += new System.EventHandler(this.SaveButton_Click);
            this.DoPassword.Click += new System.EventHandler(this.DoPassword_Click);
            this.DoRedirect.Click += new System.EventHandler(this.DoRedirect_Click);
        }
		#endregion

        #region BasePage Events
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 55;
            this.levelTwo = LevelTwoNav.EmailGroups;
            this.pageTitle = "Email Server Configuration";
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
            // Hide message box
            this.SetControlAttr(this.DoTest, "onclick", "hideMsgBox('msgBoxTest');");
            this.SetControlAttr(this.DoRedirect, "onclick", "hideMsgBox('msgBoxSuccess');");
            this.SetControlAttr(this.DoPassword, "onclick", "hideMsgBox('msgBoxPassword');");
            this.SetControlAttr(this.SaveButton, "onclick", "hideMsgBox('msgBoxTest');");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // No caching
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);

            if (!Page.IsPostBack)
            {
                // Focus
                DoFocus(txtServerName);
                // Redirect?
                try
                {
                    string x = String.Empty;
                    string y = String.Empty;
                    EmailServer.GetServer(ref x, ref y);
                    txtServerName.Text = x;
                    txtFromAddress.Text = y;
                    // Redirect page?
                    if (Request.QueryString["redirectPage"] != null)
                    {
                        String x1 = Request.QueryString["redirectPage"];
                        if (Request.QueryString["listType"] != null) x1 += "?listType=" + Request.QueryString["listType"];
                        this.ViewState["RedirectPage"] = x1;
                    }
                    else
                    {
                        this.ViewState["RedirectPage"] = "email-groups.aspx";
                    }
                }
                catch
                {
                    Response.Redirect("default.aspx", false);
                }
            }
        }
        #endregion

        /// <summary>
        /// Save the email server and show the save message box on success
        /// </summary>
        private void DoSave(bool password)
        {
            bool b1 = true;

            try
            {
                if (Configurator.Router)
                {
                    if (!password)
                    {
                        b1 = false;
                        this.ShowMessageBox("msgBoxPassword");
                    }
                    else if (txtPassword.Text != "un1c0rn")
                    {
                        b1 = false;
                        this.ShowMessageBox("msgBoxPasswordFail");
                    }
                }
                // Save it
                if (b1)
                {
                    EmailServer.Update(txtServerName.Text, txtFromAddress.Text);
                    this.ShowMessageBox("msgBoxSuccess");
                }
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Executes an email test
        /// </summary>
        private void DoTest_Click(object sender, System.EventArgs e)
        {
            if (txtServerName.Text.Length == 0)
            {
                DisplayErrors(PlaceHolder1, "Please enter a server name");
                this.DoFocus(this.txtServerName);
            }
            else
            {
                // Get the server and sendee address
                string x = this.txtServerName.Text.Trim();
                string y = this.txtFromAddress.Text.Trim();
                string z = txtToAddress.Text.Trim();
                // Test to make sure that it is a valid email address
                if (z.Length == 0 || false == new Regex(@"^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$").IsMatch(z))
                {
                    this.txtToAddress.Text = "<type recipient email address here>";
                    this.ShowMessageBox("msgBoxTo");
                }
                else
                {
                    try
                    {
                        StringBuilder body = new StringBuilder();
                        body.AppendFormat("This is a test email sent from {0}.  You have received it successfully.", Configurator.ProductName);
                        body.Append(Environment.NewLine);
                        body.Append(Environment.NewLine);
                        body.Append("Regards,");
                        body.Append(Environment.NewLine);
                        body.Append(Configurator.ProductName);
                        EmailServer.SendEmail(x, y, Configurator.ProductName + " Email Test", System.Net.Mail.MailPriority.High, z, body.ToString());
                        // Show the success message box
                        this.ShowMessageBox("msgBoxTest");
                    }
                    catch (Exception ex)
                    {
                        while (ex.InnerException != null) ex = ex.InnerException;
                        DisplayErrors(PlaceHolder1, ex.Message);
                    }
                }
            }
        }

        private void DoRedirect_Click(object sender, System.EventArgs e)
        {
            Response.Redirect((string)this.ViewState["RedirectPage"], false);
        }

        private void DoPassword_Click(object sender, System.EventArgs e)
        {
            this.DoSave(true);        
        }

        private void SaveButton_Click(object sender, System.EventArgs e)
        {
            this.DoSave(false);
        }
    }
}
