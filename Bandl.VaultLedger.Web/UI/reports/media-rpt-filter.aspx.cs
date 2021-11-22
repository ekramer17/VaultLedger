using System;
using System.IO;
using System.Web;
using System.Text;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for operator_filter.
	/// </summary>
	public class media_rpt_filter : BasePage
	{
		protected System.Web.UI.WebControls.TextBox txtEndDate;
		protected System.Web.UI.WebControls.TextBox txtStartDate;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.DropDownList ddlMissing;
		protected System.Web.UI.WebControls.DropDownList ddlAccount;
		protected System.Web.UI.WebControls.DropDownList ddlMediaType;
		protected System.Web.UI.WebControls.TextBox txtSerialNo;
        protected System.Web.UI.WebControls.Button btnReport;
        protected System.Web.UI.WebControls.Label lblPurpose;
		protected System.Web.UI.WebControls.DropDownList ddlLocation;

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
            this.pageTitle = "Media Report Filter";
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
            // Bar code format for serial number
            this.BarCodeFormat(this.txtSerialNo, this.btnReport);
            // Fill dropdowns
            if (!Page.IsPostBack)
            {
                // Fill the account dropdown
                this.ddlAccount.Items.Add(String.Empty);
                foreach (AccountDetails account in Account.GetAccounts())
                    this.ddlAccount.Items.Add(account.Name);
                // Fill the media type dropdown
                this.ddlMediaType.Items.Add(String.Empty);
                foreach (MediumTypeDetails mediumType in MediumType.GetMediumTypes(false))
                    this.ddlMediaType.Items.Add(mediumType.Name);
            }
        }
        /// <summary>
        /// Event handler for the click button
        /// </summary>
        private void btnReport_Click(object sender, System.EventArgs e)
        {
            // Initialize dates
            string rd1 = txtStartDate.Text;
            string rd2 = txtEndDate.Text;
            // Check the dates
            if (!this.CheckDate(ref rd1, true) || !this.CheckDate(ref rd2, true))
            {
                this.DisplayErrors(this.PlaceHolder1, "Dates must be in valid formats.");
            }
            else
            {
                try
                {
                    MediumFilter m = new MediumFilter();
                    // Put the dates in proper format
                    if (rd1.Length != 0) rd1 = Date.ParseExact(rd1).ToString("yyyyMMdd");
                    if (rd2.Length != 0) rd2 = Date.ParseExact(rd2).ToString("yyyyMMdd");
                    // Construct the filter
                    if (this.ddlAccount.SelectedIndex != 0) m.Account = ddlAccount.SelectedValue;
                    if (this.ddlLocation.SelectedIndex != 0) m.Location = (Locations)Enum.Parse(typeof(Locations), ddlLocation.SelectedValue);
                    if (this.ddlMediaType.SelectedIndex != 0) m.MediumType = ddlMediaType.SelectedValue;
                    if (this.ddlMissing.SelectedIndex != 0) m.Missing = Convert.ToBoolean(ddlMissing.SelectedValue.ToLower());
                    if (this.txtSerialNo.Text.Length != 0) m.StartingSerialNo = txtSerialNo.Text;
                    // Add it to the session cache
                    Session[CacheKeys.Object] = m;
                    // Send request
                    string qs = String.Format("rd1={0}&rd2={1}", rd1, rd2);
                    Session[CacheKeys.WaitRequest] = RequestTypes.PrintMediumReport;
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
