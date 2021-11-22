using System;
using System.Web;
using System.Web.Security;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for errorPage.
	/// </summary>
	public class errorPage : BasePage
	{
        protected System.Web.UI.WebControls.Label lblError;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.WebControls.Label lblTitle;
        protected System.Web.UI.WebControls.Label lblCaption;
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
            this.btnOK.Click += new System.EventHandler(this.btnOK_Click);

        }
        #endregion
    
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.createHeader = false;
            this.createNavigation = false;
            this.pageTitle = "Application Error";
            this.helpId = 0;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
		{
            if (!this.IsPostBack)
            {
                try
                {
                    Exception e1 = null;
                    // Unhandled?
                    if (Session[CacheKeys.Exception] != null)
                    {
                        e1 = (Exception)Session[CacheKeys.Exception];
                        Session.Remove(CacheKeys.Exception);
                    }
                    else
                    {
                        e1 = Server.GetLastError();
                    }
                    // Get base exception
                    e1 = e1.GetBaseException();
                    // Display error message
                    lblError.Text = (e1 is HttpUnhandledException) ? e1.Message + "<br><br>" + e1.StackTrace : e1.Message;
                    // Special?
                    if (e1 is NoPrintDataException)
                    {
                        ViewState["CloseWindow"] = 1;
                        lblTitle.Text = "No Report Produced";
                        lblCaption.Text = Configurator.ProductName + " was unable to produce a report.";
                    }
                }
                catch
                {
                    lblError.Text = "An unspecified error has occurred.&nbsp;&nbsp;Check the server event log for more details.";
                }
            }
		}
//        /// <summary>
//        /// Display exception based on type
//        /// </summary>
//        /// <param name="ex"></param>
//        private void DisplayException(Exception e, bool unhandled)
//        {
//            Exception x = e;
//            // Get the innermost exception
//            while (x is HttpUnhandledException && x.InnerException != null) {x = x.InnerException;}
//            // If we've somehow lost session state, display fake timeout message (we really don't
//            // know why this occurs on occasion).  Otherwise, send the user to the login page.
//            if (Session.Count != 0)
//            {
//                // Display the message
//                lblError.Text = e is HttpUnhandledException ? x.Message + "<br><br>" + x.StackTrace : x.Message;
//                // Print exception?
//                if (x is NoPrintDataException)
//                {
//                    ViewState["CloseWindow"] = 1;
//                    lblTitle.Text = "No Report Produced";
//                    lblCaption.Text = Configurator.ProductName + " was unable to produce a report.";
//                }
//            }
//            else
//            {
//                // Abandon the session (just to make sure)
//                Session.Abandon();
//                // Revoke authentication
//                FormsAuthentication.SignOut();
//                // We've lost session state for some unknown reason.  Tell the user that the session has
//                // timed out and then just send him back to the login page.
//                ViewState["Url"] = "login.aspx?error=Session_State_Lost";
//                lblError.Text = "Your session has timed out.&nbsp;&nbsp;Please click 'OK' to return the login page.";
//            }
//        }
        /// <summary>
        /// OK button event handler, redirects to main menu
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
			if (ViewState["CloseWindow"] != null)
			{
				ClientScript.RegisterStartupScript(GetType(), "CloseWindow", "<script language='javascript'>window.close();</script>");
			}
			else if (ViewState["Url"] != null)
			{
				Response.Redirect((string)ViewState["Url"]);
			}
			else
			{
				ClientScript.RegisterStartupScript(GetType(), "CloseWindow", "<script language='javascript'>history.go(-1);</script>");
			}
        }
	}
}
