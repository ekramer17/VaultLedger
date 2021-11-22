using System;
using System.Web.UI;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for report_list_two.
    /// </summary>
    public class report_list_two : BasePage
    {
        private PrintSources reportType;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
        protected System.Web.UI.WebControls.LinkButton medium;
        protected System.Web.UI.WebControls.LinkButton sendList;
        protected System.Web.UI.WebControls.LinkButton mediumMovement;
        protected System.Web.UI.WebControls.LinkButton receiveList;
        protected System.Web.UI.WebControls.LinkButton barCodePattern;
        protected System.Web.UI.WebControls.LinkButton sealedCase;
        protected System.Web.UI.WebControls.LinkButton disasterCodeList;
        protected System.Web.UI.WebControls.LinkButton externalSite;
        protected System.Web.UI.WebControls.LinkButton user;
        protected System.Web.UI.WebControls.LinkButton account;
        protected System.Web.UI.WebControls.LinkButton miscellaneous;
        protected System.Web.UI.WebControls.LinkButton inventory;
        protected System.Web.UI.WebControls.LinkButton inventoryConflict;
        protected System.Web.UI.WebControls.LinkButton complete;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;

        public PrintSources ReportType
        {
            get {return reportType;}
        }

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
            this.medium.Click += new System.EventHandler(this.reportLink_Click);
            this.sendList.Click += new System.EventHandler(this.reportLink_Click);
            this.account.Click += new System.EventHandler(this.reportLink_Click);
            this.mediumMovement.Click += new System.EventHandler(this.reportLink_Click);
            this.receiveList.Click += new System.EventHandler(this.reportLink_Click);
            this.externalSite.Click += new System.EventHandler(this.reportLink_Click);
            this.sealedCase.Click += new System.EventHandler(this.reportLink_Click);
            this.disasterCodeList.Click += new System.EventHandler(this.reportLink_Click);
            this.user.Click += new System.EventHandler(this.reportLink_Click);
            this.inventory.Click += new System.EventHandler(this.reportLink_Click);
            this.barCodePattern.Click += new System.EventHandler(this.reportLink_Click);
            this.miscellaneous.Click += new System.EventHandler(this.reportLink_Click);
            this.inventoryConflict.Click += new System.EventHandler(this.reportLink_Click);
            this.complete.Click += new System.EventHandler(this.reportLink_Click);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Auditor Reports";
            this.levelTwo = LevelTwoNav.None;
            this.helpId = 32;
            // Security
            DoSecurity(Role.Auditor, "report-list.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                    this.threeTabs.Visible = true;
                    this.twoTabs.Visible = false;
                    break;
                case Role.Auditor:
                    this.threeTabs.Visible = false;
                    this.twoTabs.Visible = true;
                    break;
                default:
                    break;
            }
            // Update the tab page default
            if (!Page.IsPostBack)
            {
                TabPageDefault.Update(TabPageDefaults.ReportCategory, Context.Items[CacheKeys.Login], 2);
            }

        }
        /// <summary>
        /// Event handler for when any one of the linkbuttons is clicked
        /// </summary>
        private void reportLink_Click(object sender, System.EventArgs e)
        {
            // The user link could not be named "operator" because that is a
            // reserved keyword.  Everything else is named along its
            // auditor type enumeration.
            switch (((Control)sender).ID)
            {
                case "user":
                    reportType = PrintSources.AuditorReportOperator;
                    Response.Redirect("auditor-filter.aspx?reportType=operator");
                    break;
                case "miscellaneous":
                    reportType = PrintSources.AuditorReportSystemAction;
                    Response.Redirect("auditor-filter.aspx?reportType=systemAction");
                    break;
                case "complete":
                    reportType = PrintSources.AuditorReportAllValues;
                    Response.Redirect("auditor-filter.aspx?reportType=allValues");
                    break;
                default:
                    reportType = (PrintSources)Enum.Parse(typeof(PrintSources),String.Format("AuditorReport{0}",(((Control)sender).ID)),true);
                    Response.Redirect("auditor-filter.aspx?reportType=" + ((Control)sender).ID);
                    break;
            }
        }
    }
}