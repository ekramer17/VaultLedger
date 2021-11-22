using System;
using System.Web;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for new_dr_list_batch_file_step_one.
    /// </summary>
    public class new_dr_list_batch_file_step_one : BasePage
    {
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnOK;

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
            this.btnOK.Click += new System.EventHandler(this.btnOK_Click);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "New Disaster Recovery List";
            this.levelTwo = LevelTwoNav.DisasterRecovery;
            this.helpId = 19;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!this.IsPostBack)
                TabPageDefault.Update(TabPageDefaults.NewDisasterCodeList, Context.Items[CacheKeys.Login], 2);
        }
        /// <summary>
        /// Event handler for OK button
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            byte[] inputFile;
            HttpPostedFile postedFile;

            if (File1.Value.Trim().Length != 0)
            {
                if ((postedFile = File1.PostedFile) == null || postedFile.ContentLength == 0)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Unable to find or access '" + File1.Value + "'");
                }
                else
                {
                    try
                    {
                        // Read the file
                        inputFile = new byte[postedFile.ContentLength];
                        postedFile.InputStream.Read(inputFile, 0, postedFile.ContentLength);
                        // Create the list
                        DisasterCodeListDetails disasterList = DisasterCodeList.Create(inputFile);
                        // Redirect to disaster code list detail
                        if (disasterList != null)
                            Server.Transfer(String.Format("disaster-recovery-list-detail.aspx?listNumber={0}", disasterList.Name));
                        else
                            Server.Transfer("disaster-recovery-list-browse.aspx");
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
