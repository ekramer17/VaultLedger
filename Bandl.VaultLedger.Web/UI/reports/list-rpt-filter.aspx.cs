using System;
using System.Text;
using System.Web.UI.WebControls;
using System.Runtime.Remoting.Messaging;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for operator_filter.
	/// </summary>
	public class list_rpt_filter : BasePage
	{
        string reportName = String.Empty;
        protected System.Web.UI.WebControls.TextBox txtEndDate;
		protected System.Web.UI.WebControls.TextBox txtStartDate;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.WebControls.Button btnReport;
		protected System.Web.UI.WebControls.DropDownList ddlStatus;

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
            this.pageTitle = "List Report Filter";
            this.levelTwo = LevelTwoNav.None;
            this.helpId = 33;
            // Security
            DoSecurity(new Role[] {Role.Operator,Role.Auditor}, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                reportName = (string)this.ViewState["reportName"];
            }
            else
            {
                if ((reportName = Request.QueryString["reportName"]) == null)
                {
                    Server.Transfer("report-list.aspx");
                }
                else
                {
                    System.Type enumType = null;
                    // Initialize the page according to the report name
                    switch(Request.QueryString["reportName"].ToLower())
                    {
                        case "shipping":
                            lblCaption.Text = "Shipping List Report Filter";
                            enumType = typeof(SLStatus);
                            break;
                        case "receiving":
                            lblCaption.Text = "Receiving List Report Filter";
                            enumType = typeof(RLStatus);
                            break;
                        case "disasterrecovery":
                            lblCaption.Text = "Disaster Recovery List Report Filter";
                            enumType = typeof(DLStatus);
                            break;
                        default:
                            Server.Transfer("report-list.aspx");
                            break;
                    }
                    // Keep the page type in the viewstate
                    this.ViewState["reportName"] = Request.QueryString["reportName"].ToLower();
                    // Fill the account dropdown
                    this.ddlAccount.Items.Add(String.Empty);
                    foreach (AccountDetails account in Account.GetAccounts())
                        this.ddlAccount.Items.Add(account.Name);
                    // Fill the status dropdown
                    this.ddlStatus.Items.Add(String.Empty);
                    foreach (string statusName in Enum.GetNames(enumType))
                    {
                        if (statusName != "AllValues")
                        {
                            if (enumType == typeof(SLStatus))
                            {
                                SLStatus y = (SLStatus)Enum.Parse(enumType, statusName);
                                if ((y & SendList.Statuses) != 0)
                                    ddlStatus.Items.Add(new ListItem(ListStatus.ToUpper(y), y.ToString()));
                            }
                            else if (enumType == typeof(RLStatus))
                            {
                                RLStatus y = (RLStatus)Enum.Parse(enumType, statusName);
                                if ((y & ReceiveList.Statuses) != 0)
                                    ddlStatus.Items.Add(new ListItem(ListStatus.ToUpper(y), y.ToString()));
                            }
                            else
                            {
                                DLStatus y = (DLStatus)Enum.Parse(enumType, statusName);
                                if ((y & DisasterCodeList.Statuses) != 0 && y != DLStatus.Xmitted)
                                    ddlStatus.Items.Add(new ListItem(ListStatus.ToUpper(y), y.ToString()));
                            }
                        }
                    }
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            this.pageTitle = this.lblCaption.Text;
        }
        /// <summary>
        /// Event handler for the report button
        /// </summary>
        private void btnReport_Click(object sender, System.EventArgs e)
        {
            int i = -1;
            string ed = txtEndDate.Text;
            string sd = txtStartDate.Text;
            string st = ddlStatus.SelectedValue;
            string ac = ddlAccount.SelectedValue;
            // Check the dates.  If okay send asyncrhonous request
            if (!this.CheckDate(ref ed, true) || !this.CheckDate(ref ed, true))
            {
                this.DisplayErrors(this.PlaceHolder1, "Dates must be in valid formats.");
            }
            else
            {
                try
                {
                    switch (reportName.Substring(0,1).ToUpper())
                    {
                        case "S":
                            Session[CacheKeys.WaitRequest] = RequestTypes.PrintSLReport;
                            break;
                        case "R":
                            Session[CacheKeys.WaitRequest] = RequestTypes.PrintRLReport;
                            break;
                        case "D":
                            Session[CacheKeys.WaitRequest] = RequestTypes.PrintDLReport;
                            break;
                    }
                    // Put the dates in proper format
                    if (sd.Length != 0) 
                    {
                        DateTime ds = Date.ParseExact((i = sd.IndexOf(' ')) != -1 ? sd.Substring(0,i) : sd);
                        sd = Time.LocalToUtc(ds).ToString("yyyyMMddHHmmss");
                    }
                    // End date
                    if (ed.Length != 0) 
                    {
                        DateTime de = Date.ParseExact((i = ed.IndexOf(' ')) != -1 ? ed.Substring(0,i) : ed);
                        ed = Time.LocalToUtc(de.AddSeconds(86399)).ToString("yyyyMMddHHmmss");
                    }
                    // Send request
                    string qs = String.Format("sd={0}&ed={1}&st={2}&ac={3}", sd, ed, st, ac);
                    ClientScript.RegisterStartupScript(GetType(), "printWindow", String.Format("<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&{0}&x=" + Guid.NewGuid().ToString("N") + "')</script>", qs));
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
    }
}
