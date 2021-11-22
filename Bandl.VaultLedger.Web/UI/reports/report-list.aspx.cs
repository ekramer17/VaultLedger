using System;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for report_list.
	/// </summary>
	public class report_list : BasePage
	{
        protected System.Web.UI.WebControls.LinkButton linkSend;
        protected System.Web.UI.WebControls.LinkButton linkReceive;
        protected System.Web.UI.WebControls.LinkButton linkDisaster;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl oneTab;
		protected System.Web.UI.WebControls.LinkButton LinkMedia;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;
	
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
			this.linkSend.Click += new System.EventHandler(this.linkSend_Click);
			this.linkReceive.Click += new System.EventHandler(this.linkReceive_Click);
			this.linkDisaster.Click += new System.EventHandler(this.linkDisaster_Click);
			this.LinkMedia.Click += new System.EventHandler(this.LinkMedia_Click);

		}
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Operator Reports";
            this.levelTwo = LevelTwoNav.None;
            this.helpId = 32;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Security
            DoSecurity(new Role[] {Role.Operator,Role.Auditor}, "default.aspx");
            // Alter appearance
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                    this.threeTabs.Visible = true;
                    this.twoTabs.Visible = false;
                    this.oneTab.Visible = false;
                    break;
                case Role.Auditor:
                    this.threeTabs.Visible = false;
                    this.twoTabs.Visible = true;
                    this.oneTab.Visible = false;
                    break;
                default:
                    this.threeTabs.Visible = false;
                    this.twoTabs.Visible = false;
                    this.oneTab.Visible = true;
                    break;
            }
            // Update the tab page default
            if (!Page.IsPostBack)
                TabPageDefault.Update(TabPageDefaults.ReportCategory, Context.Items[CacheKeys.Login], 1);
        }

        private void linkSend_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("list-rpt-filter.aspx?reportName=shipping");
        }

        private void linkReceive_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("list-rpt-filter.aspx?reportName=receiving");
        }

        private void linkDisaster_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("list-rpt-filter.aspx?reportName=disasterRecovery");
        }

		private void LinkMedia_Click(object sender, System.EventArgs e)
		{
			Server.Transfer("media-rpt-filter.aspx");
		}
	}
}
