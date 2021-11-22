using System;
using System.Text;
using System.Web.UI;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for report_list_three.
	/// </summary>
	public class report_list_three : BasePage
	{
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.LinkButton linkBarCodeMedium;
        protected System.Web.UI.WebControls.LinkButton linkBarCodeCase;
        protected System.Web.UI.WebControls.LinkButton linkExternalSite;
        protected System.Web.UI.WebControls.LinkButton linkUserSecurity;
        protected System.Web.UI.WebControls.LinkButton linkAccounts;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;

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
            this.linkAccounts.Click += new System.EventHandler(this.reportLink_Click);
            this.linkBarCodeCase.Click += new System.EventHandler(this.reportLink_Click);
            this.linkBarCodeMedium.Click += new System.EventHandler(this.reportLink_Click);
            this.linkExternalSite.Click += new System.EventHandler(this.reportLink_Click);
            this.linkUserSecurity.Click += new System.EventHandler(this.reportLink_Click);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Administrator Reports";
            this.levelTwo = LevelTwoNav.None;
            this.helpId = 32;
            // Security
            DoSecurity(Role.Administrator, "report-list.aspx");

        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Update the tab page default
            if (!Page.IsPostBack)
                TabPageDefault.Update(TabPageDefaults.ReportCategory, Context.Items[CacheKeys.Login], 3);

        }
        /// <summary>
        /// Event handler for when any one of the linkbuttons is clicked
        /// </summary>
        private void reportLink_Click(object sender, System.EventArgs e)
        {
            string r = ((Control)sender).ID.Replace("link","");
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintOtherReport;
            ClientScript.RegisterStartupScript(GetType(), "printWindow", String.Format("<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&r={0}&x=" + Guid.NewGuid().ToString("N") + "')</script>", r));
        }
	}
}
