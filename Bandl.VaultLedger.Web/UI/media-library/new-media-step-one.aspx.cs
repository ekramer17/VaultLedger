using System;
using System.Web.UI;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_media_step_one.
	/// </summary>
	public class new_media_step_one : BasePage
	{
		protected System.Web.UI.WebControls.TextBox txtSSN;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNext;
		protected System.Web.UI.WebControls.TextBox txtESN;
		protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;

        private string startNo;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        private string endNo;
 
        public string StartNo
        {
            get
            {
                return startNo;
            }
        }

        public string EndNo
        {
            get
            {
                return endNo;
            }
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
            this.btnNext.ServerClick += new System.EventHandler(this.btnNext_ServerClick);

        }
        #endregion


        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "New Media";
            this.levelTwo = LevelTwoNav.New;
            this.helpId = 7;
            // Auditors and viewers should not be able to access this page;
            // redirect them to the main menu
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Apply bar code format editing
            this.BarCodeFormat(new Control[] {txtSSN, txtESN}, this.btnNext);
            // Register the Next button as the default
            this.SetDefaultButton(this.contentBorderTop, "btnNext");
            // Set the focus to the start text field
            this.DoFocus(this.txtSSN);
        }

        private void btnNext_ServerClick(object sender, System.EventArgs e)
        {
            if (txtSSN.Text.Trim() == String.Empty)
            {
                this.DisplayErrors(this.PlaceHolder1, "Starting serial number is required");
            }
            else
            {
                this.endNo = txtESN.Text.Trim();
                this.startNo = txtSSN.Text.Trim();
                if (endNo.Length == 0) endNo = StartNo;
                // Validate input
                if (endNo.CompareTo(startNo) < 0)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Ending serial number must be greater than or equal to starting serial number");
                }
                else
                {
                    try
                    {
                        // Can it be previewed?
                        MediumRange[] ranges = null;
                        Medium.PreviewInsert(startNo, endNo, out ranges);
                        if (ranges == null || ranges.Length == 0)
                            this.DisplayErrors(this.PlaceHolder1, "All media in this range already exist.");
                        else
                            Server.Transfer("new-media-step-two.aspx");
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
            }
        }
	}
}
