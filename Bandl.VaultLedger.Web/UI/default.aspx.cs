using System;
using System.Web;
using System.Text;
using System.Reflection;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for main_menu.
    /// </summary>
    public class defaultPage : BasePage
    {
        protected System.Web.UI.HtmlControls.HtmlGenericControl mainAdmin;
		protected System.Web.UI.HtmlControls.HtmlGenericControl divNews;
        protected System.Web.UI.WebControls.Label lblPageHeader;
        protected System.Web.UI.HtmlControls.HtmlAnchor linkList;
        protected System.Web.UI.HtmlControls.HtmlAnchor linkMedia;
        protected System.Web.UI.HtmlControls.HtmlAnchor linkAdmin;
        protected System.Web.UI.HtmlControls.HtmlAnchor linkReport;
        protected System.Web.UI.WebControls.Label lblMsgBoxDisplay;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.HtmlControls.HtmlGenericControl menuBottom;
        protected System.Web.UI.HtmlControls.HtmlGenericControl version1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl version2;
        protected System.Web.UI.WebControls.Label lblNews;

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
            this.helpId = 2;
            this.pageTitle = "Main Menu";
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!this.IsPostBack)
            {
                // Main menu message
                if (Session["MainMenuMessage"] != null)
                {
                    this.lblNews.Text = (string)Session["MainMenuMessage"];
                    Session.Remove("MainMenuMessage");
                }
            }
            // If we have an error message, display it
            if (Session["ErrorMessage"] != null)
            {
                this.ShowMessageBox("msgBoxDisplay");
                this.SetControlAttr(btnOK, "onclick", "location.href='" + HttpRuntime.AppDomainAppVirtualPath + "/default.aspx'");
                this.lblMsgBoxDisplay.Text = (string)Session["ErrorMessage"];
                Session.Remove("ErrorMessage");
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Render the greeting
            lblPageHeader.Text = this.lblGreeting.Text;
            // Render the news portion visible if we have text
            this.divNews.Visible = this.lblNews.Text.Length != 0;
            // If viewer or VaultOps, bottom row should not be visible.  Otherwise, if the user is not an 
            // administrator, the system administrator section should be invisible.
            switch (CustomPermission.CurrentOperatorRole())
            {
				case Role.VaultOps:
				case Role.Viewer:
                    menuBottom.Visible = false;
                    ClientScript.RegisterStartupScript(GetType(), "version1", "<script language='javascript'>getObjectById('version1').style.display='block'</script>");
                    break;
                case Role.Operator:
                case Role.Auditor:
                    mainAdmin.Visible = false;
                    break;
				default:
                    break;
            }
            // Set link hrefs
            string virtualPath = HttpRuntime.AppDomainAppVirtualPath;
            linkList.HRef = virtualPath + "/lists/todays-list.aspx";
            linkMedia.HRef = virtualPath + "/media-library/find-media.aspx";
            linkAdmin.HRef = virtualPath + "/administrative-tools/index.aspx";
            linkReport.HRef = virtualPath + "/reports/report-list.aspx";
            // Get the assembly and database versions
            AssemblyName mainAssembly = Assembly.GetAssembly(typeof(Account)).GetName();    // BLL assembly
            version1.InnerHtml = String.Format("{0} , {1}", mainAssembly.Version.ToString(), Database.GetVersion().String);
            version2.InnerHtml = String.Format("{0} , {1}", mainAssembly.Version.ToString(), Database.GetVersion().String);
            // Issue list alerts?
            if (Request.QueryString["issuelistalerts"] != null)
            {
                this.GenerateEmailAlertScript();
            }
/*
            // Purge cleared lists?
            if (Request.QueryString["purgeclearedlists"] != null)
            {
                this.GenerateClearPurgedScript();
            }
*/            
            // If we have an RFID license and the querystring dictates, goto the RFID list creation page.  This must occur after asynchronous actions.
            if (Request.QueryString["gotorfid"] != null && ProductLicense.GetProductLicense(LicenseTypes.RFID).Units == 1)
            {
                this.GotoRfidStartPage();
            }
        }
        /// <summary>
        /// Generates startup script to issue alerts
        /// </summary>
        public void GenerateEmailAlertScript()
        {
            StringBuilder b = new StringBuilder();
            b.AppendFormat("{0}<script type=\"text/javascript\">{0}{0}", Environment.NewLine);
            b.AppendFormat("(function() ", Environment.NewLine);
            b.AppendFormat("{{{0}", Environment.NewLine);
            b.AppendFormat("   var q = createXmlHttpRequest();{0}", Environment.NewLine);
            b.AppendFormat("   var url = \"handlers/requesthandlerasync.ashx?issuelistalerts=1&x=" + Guid.NewGuid().ToString("N") + "\";{0}", Environment.NewLine);
            b.AppendFormat("   q.open(\"GET\",url,true);{0}", Environment.NewLine);
            b.AppendFormat("   q.send(null);{0}", Environment.NewLine);
            b.AppendFormat("}})(){0}", Environment.NewLine);
            b.AppendFormat("</script>{0}", Environment.NewLine);
            ClientScript.RegisterStartupScript(GetType(), "EMAILALERT", b.ToString());
        }
/*
        /// <summary>
        /// Generates startup script to purge cleared lists
        /// </summary>
        public void GenerateClearPurgedScript()
        {
            StringBuilder b = new StringBuilder();
            b.AppendFormat("{0}<script type=\"text/javascript\">{0}{0}", Environment.NewLine);
            b.AppendFormat("function doPurges(){0}", Environment.NewLine);
            b.AppendFormat("{{{0}", Environment.NewLine);
            b.AppendFormat("   var q = createXmlHttpRequest();{0}", Environment.NewLine);
            b.AppendFormat("   var url = \"handlers/requesthandlerasync.ashx?purgeclearedlists=1&x=" + Guid.NewGuid().ToString("N") + "\";{0}", Environment.NewLine);
            b.AppendFormat("   q.open(\"GET\",url,true);{0}", Environment.NewLine);
            b.AppendFormat("   q.send(null);{0}", Environment.NewLine);
            b.AppendFormat("}}{0}{0}", Environment.NewLine);
            b.AppendFormat("doPurges();{0}{0}", Environment.NewLine); // Call the function
            b.AppendFormat("</script>{0}", Environment.NewLine);
            ClientScript.RegisterStartupScript(GetType(), "PURGECLEARED", b.ToString());
        }
*/
        /// <summary>
        /// Goes directly to the RFID start page
        /// </summary>
        public void GotoRfidStartPage()
        {
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                case Role.Operator:
                    StringBuilder b = new StringBuilder();
                    b.AppendFormat("{0}<script type=\"text/javascript\">{0}{0}", Environment.NewLine);
                    b.AppendFormat("window.location.href='lists/new-list-rfid-file.aspx'{0}", Environment.NewLine);
                    b.AppendFormat("</script>{0}", Environment.NewLine);
                    ClientScript.RegisterStartupScript(GetType(), "GOTORFID", b.ToString());
                    break;
                default:
                    break;
            }
        }
    }
}
