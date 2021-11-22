using System;
using System.Text;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for auditor_filter.
	/// </summary>
	public class auditor_filter : BasePage
	{
        private AuditTypes auditType;
        private PrintSources reportType;
        DateTime dateStart = DateTime.MinValue;
        DateTime dateEnd = DateTime.MaxValue;

        protected System.Web.UI.WebControls.TextBox txtEndDate;
		protected System.Web.UI.WebControls.TextBox txtStartDate;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.TextBox txtLogin;
        protected System.Web.UI.WebControls.TextBox txtSerialNo;
        protected System.Web.UI.WebControls.Button btnReport;
        protected System.Web.UI.WebControls.Label lblSerialNo;

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
            this.btnReport.Click += new System.EventHandler(this.btnReport_Click);

        }
        #endregion


        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.levelTwo = LevelTwoNav.None;
            this.helpId = 33;
            // Security
            DoSecurity(Role.Auditor, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                reportType = (PrintSources)this.ViewState["ReportType"];
                auditType = (AuditTypes)this.ViewState["AuditType"];
            }
            else
            {
                if (Request.QueryString["reportType"] != null)
                {
                    reportType = (PrintSources)Enum.Parse(typeof(PrintSources), "AuditorReport" + Request.QueryString["reportType"], true);
                    this.ViewState["ReportType"] = reportType;
                    // Set the audit type
                    auditType = (AuditTypes)Enum.Parse(typeof(AuditTypes),reportType.ToString().Replace("AuditorReport",""));
                    this.ViewState["AuditType"] = auditType;
                    // Set the page caption
                    this.SetPageCaption();
                }
                else
                {
                    Server.Transfer("../default.aspx");
                }
            }
            // Set the page title
            this.pageTitle = this.lblCaption.Text;
            // Bar code format for serial number
            if (this.txtSerialNo.Visible)
            {
                this.BarCodeFormat(this.txtSerialNo, this.btnReport);
            }
        }
        /// <summary>
        /// Sets the caption for the page
        /// </summary>
        private void SetPageCaption()
        {
            switch (this.auditType)
            {
                case AuditTypes.Medium:
                    this.lblCaption.Text = "Media History Report Filter";
                    break;
                case AuditTypes.SendList:
                    this.lblCaption.Text = "Shipping Lists Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.Account:
                    this.lblCaption.Text = "Accounts Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.MediumMovement:
                    this.lblCaption.Text = "Media Movement History Report Filter";
                    break;
                case AuditTypes.ReceiveList:
                    this.lblCaption.Text = "Receiving Lists Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.BarCodePattern:
                    this.lblCaption.Text = "Bar Code Formats Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.SealedCase:
                    this.lblCaption.Text = "Sealed Case Report Filter";
                    this.lblSerialNo.Text = "Case Number:";
                    break;
                case AuditTypes.DisasterCodeList:
                    this.lblCaption.Text = "Disaster Recovery Lists Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.ExternalSite:
                    this.lblCaption.Text = "Site Maps Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.Inventory:
                    this.lblCaption.Text = "Inventory Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.Operator:
                    this.lblCaption.Text = "Users Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.InventoryConflict:
                    this.lblCaption.Text = "Inventory Discrepancy Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.SystemAction:
                    this.lblCaption.Text = "Miscellaneous Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                case AuditTypes.AllValues:
                    this.lblCaption.Text = "Complete Report Filter";
                    this.lblSerialNo.Visible = false;
                    this.txtSerialNo.Visible = false;
                    break;
                default:
                    Server.Transfer("../default.aspx");
                    break;
            }
        }
        /// <summary>
        /// Event handler for the click button
        /// </summary>
        private void btnReport_Click(object sender, System.EventArgs e)
        {
            DateTime ds = new DateTime(1800, 1, 2);
            DateTime de = new DateTime(3999, 1, 2);
            string sd = txtStartDate.Text;
            string ed = txtEndDate.Text;
            string x = null;
            int i = -1;
            // Check the dates
            try
            {
                // Start date
                if (sd.Length != 0) 
                {
                    ds = Time.LocalToUtc(Date.ParseExact((i = sd.IndexOf(' ')) != -1 ? sd.Substring(0,i) : sd));
                }
                // End date
                if (ed.Length != 0) 
                {
                    de = Time.LocalToUtc(Date.ParseExact((i = ed.IndexOf(' ')) != -1 ? ed.Substring(0,i) : ed).AddSeconds(86399));   // 23:59:59
                }
            }
            catch
            {
                x = "Dates must be in valid format.";
            }
            // If we have an error, display it; otherwise send request
            if (x != null)
            {
                this.DisplayErrors(this.PlaceHolder1, x);
            }
            else
            {
                AuditTypes t1 = this.auditType;
                // Set the print source here
                Session[CacheKeys.PrintSource] = reportType;
                // If system action, 'or' it with general action
                Session[CacheKeys.Object] = t1 != AuditTypes.SystemAction ? t1 : t1 | AuditTypes.GeneralAction;
                // Send request
                Session[CacheKeys.WaitRequest] = RequestTypes.PrintAuditReport;
                string qs = String.Format("sd={0}&ed={1}&l={2}&s={3}", ds.ToString("yyyyMMddHHmmss"), de.ToString("yyyyMMddHHmmss"), txtLogin.Text, txtSerialNo.Text);
                ClientScript.RegisterStartupScript(GetType(), "printWindow", String.Format("<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&{0}&x=" + Guid.NewGuid().ToString("N") + "')</script>", qs));
            }
        }
    }
}
