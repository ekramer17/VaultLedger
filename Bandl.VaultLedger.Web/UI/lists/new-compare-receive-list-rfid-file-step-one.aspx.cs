using System;
using System.Web;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_compare_receive_list_rfid_file_step_one.
	/// </summary>
	public class new_compare_receive_list_rfid_file_step_one : BasePage
	{
        ReceiveListDetails pageList = null;
        public ReceiveListDetails ListObject { get {return pageList;} }

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls;
        protected System.Web.UI.HtmlControls.HtmlAnchor batchLink;
        protected System.Web.UI.HtmlControls.HtmlAnchor manualLink;
        protected System.Web.UI.WebControls.TextBox txtFileName;
	
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
            this.batchLink.ServerClick += new System.EventHandler(this.batchLink_ServerClick);
            this.manualLink.ServerClick += new EventHandler(manualLink_ServerClick);
            this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 13;
            this.levelTwo = LevelTwoNav.Receiving;
            this.pageTitle = "New Receiving Compare File";
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                pageList = (ReceiveListDetails)this.ViewState["PageList"];
            }
            else
            {
                if (Context.Handler is receiving_list_reconcile)
                {
                    pageList = ((receiving_list_reconcile)Context.Handler).ListObject;
                }
                else if (Context.Handler is new_compare_receive_list_manual_scan)
                {
                    pageList = ((new_compare_receive_list_manual_scan)Context.Handler).ListObject;
                }
                else if (Context.Handler is new_compare_receive_list_batch_file_step_one)
                {
                    pageList = ((new_compare_receive_list_batch_file_step_one)Context.Handler).ListObject;
                }
                else
                {
                    Response.Redirect("receive-lists.aspx", false);
                }
                // Insert list into viewstate
                this.ViewState["PageList"] = pageList;
                // Display default compare file name
                this.txtFileName.Text = Date.Display(Time.Local, true, true, true);
                // Set the tab page preference
                TabPageDefault.Update(TabPageDefaults.ReceiveReconcileNewFile, Context.Items[CacheKeys.Login], 3);
                // Create page caption
                lblCaption.Text = String.Format("New Receiving Compare File&nbsp;&nbsp;:&nbsp;&nbsp;List {0}", pageList.Name);
            }
        }
        /// <summary>
        /// Event handler for the OK button
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            byte[] inputFile;
            HttpPostedFile postedFile;

            if (0 == this.txtFileName.Text.Trim().Length)
            {
                this.DisplayErrors(this.PlaceHolder1, "Please enter a name for the compare file");
            }
            else if (0 == this.File1.Value.Length)
            {
                this.DisplayErrors(this.PlaceHolder1, "Please enter the path of the batch scanner file");
            }
            else if ((postedFile = File1.PostedFile) == null || postedFile.ContentLength == 0)
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
                    // Get the scan items
                    ReceiveListScanItemCollection ri = Imation.GetReceiveScanItems(inputFile);
                    // Create the scan
                    ReceiveList.CreateScan(pageList.Name, this.txtFileName.Text.Trim(), ref ri);
                    // Redirect to receiving list reconcile
                    Server.Transfer(String.Format("receiving-list-reconcile.aspx?listNumber={0}", pageList.Name));
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Event handler for the cancel button
        /// </summary>
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect(String.Format("receiving-list-reconcile.aspx?listNumber={0}", pageList.Name), false);
        }
        /// <summary>
        /// Transfer to manual scan link
        /// </summary>
        private void batchLink_ServerClick(object sender, System.EventArgs e)
        {
            Server.Transfer("new-compare-receive-list-batch-file-step-one.aspx");
        }
        /// <summary>
        /// Transfer to manual scan link
        /// </summary>
        private void manualLink_ServerClick(object sender, System.EventArgs e)
        {
            Server.Transfer("new-compare-receive-list-manual-scan.aspx");
        }
    }
}
