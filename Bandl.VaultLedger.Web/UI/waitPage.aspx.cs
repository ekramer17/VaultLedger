using System;
using System.Web;
using System.Text;
using System.Threading;
using System.Security.Principal;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for waitPage.
	/// </summary>
	public class waitPage : BasePage
	{
        protected string redirectPage = "print.aspx";   // default redirect page is the print page
        protected string queryString = String.Empty;
        protected string errorPage = String.Empty;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.WebControls.Label lblWaitText;
        protected System.Web.UI.HtmlControls.HtmlInputHidden url;
        protected System.Web.UI.HtmlControls.HtmlInputHidden gif;
        protected System.Web.UI.HtmlControls.HtmlInputHidden eUrl;
        protected System.Web.UI.HtmlControls.HtmlInputHidden rUrl;
        protected System.Web.UI.HtmlControls.HtmlImage pleaseWait;

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

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.createHeader = false;
            this.createNavigation = false;
            this.pageTitle = "Please Wait";
            this.helpId = 0;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Get the redirect page
            if (Request.QueryString["redirectPage"] != null) redirectPage = Request.QueryString["redirectPage"];
            // Get the error page if it exists
            if (Request.QueryString["errorPage"] != null) errorPage = Request.QueryString["errorPage"];
            // Get the proper gif path
            this.gif.Value = String.Format("resources/img/{0}/interface/please_wait.gif", Configurator.ProductType == "RECALL" ? "recall" : "bandl");
            // Get the entire query string
            queryString = Request.Url.Query;
            // Create the label text
            this.CreateLabelText(redirectPage);
            // Set the next url values
            this.url.Value = redirectPage + queryString;
            this.rUrl.Value = "handlers/requesthandlerasync.ashx" + queryString;
            this.eUrl.Value = errorPage.Length != 0 ? errorPage : redirectPage + queryString;
            // Set the principal for spawned thread in asynchronous handler
            Session[CacheKeys.Principal] = Thread.CurrentPrincipal;
        }
        /// <summary>
        /// Given the name of the page, form the text for the wait label
        /// </summary>
        /// <param name="nextPage"></param>
        private void CreateLabelText(string nextPage)
        {
            int index = nextPage.LastIndexOf("/",nextPage.Length - 1, nextPage.Length);
            if (index != -1) nextPage = nextPage.Substring(index + 1);
            
            switch (nextPage)
            {
                case "reconcile-inventory.aspx":
                    lblWaitText.Text = "Please wait while the vault inventory is downloaded and compared against the local inventory.";
                    break;
                case "audit-expirations.aspx":
                    lblWaitText.Text = "Please wait while the audit trails are pruned.";
                    break;
                case "bar-code-formats.aspx":
                    lblWaitText.Text = "Please wait while the media are updated with the new bar code formats.";
                    break;
                case "case-formats.aspx":
                    lblWaitText.Text = "Please wait while the cases are updated with the new bar code formats.";
                    break;
                default:
                    lblWaitText.Text = "Please wait while the report is generated.";
                    break;
            }
        }
    }
}
