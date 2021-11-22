using System;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for index.
	/// </summary>
	public class index : BasePage
	{
        protected System.Web.UI.HtmlControls.HtmlTableCell emailSection;
        protected System.Web.UI.HtmlControls.HtmlTableCell ftpSection;
        protected System.Web.UI.HtmlControls.HtmlAnchor listOption;
        protected System.Web.UI.HtmlControls.HtmlGenericControl accountList;

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
            this.pageTitle = "Administrative Tools Menu";
            this.helpId = 20;
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Get the page default for list preferences
            if (!this.IsPostBack)
            {
                switch (TabPageDefault.GetDefault(TabPageDefaults.ListPreferences, Context.Items[CacheKeys.Login]))
                {
                    case 1:
                        listOption.HRef = "list-statuses.aspx";
                        break;
                    case 2:
                        listOption.HRef = "list-email-status.aspx";
                        break;
                    case 3:
                        listOption.HRef = "list-email-alert.aspx";
                        break;
                    case 4  :
                        listOption.HRef = "list-purge.aspx";
                        break;
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            switch (Configurator.ProductType)
            {
                case "RECALL":
//                    emailSection.InnerHtml = String.Empty;
                    ftpSection.InnerHtml = String.Empty;
                    accountList.InnerHtml = "<li><a href=\"accounts.aspx\">View existing accounts</a></li>";
                    break;
                default:
                    listOption.InnerHtml = "List preferences and alerts";
                    break;
            }
            // If we are not using FTP transmission mode, hide the FTP list item
            switch (Configurator.XmitMethod)
            {
                case "FTP":
                    break;
                default:
                    ftpSection.InnerHtml = String.Empty;
                    break;
            }
        }
	}
}
