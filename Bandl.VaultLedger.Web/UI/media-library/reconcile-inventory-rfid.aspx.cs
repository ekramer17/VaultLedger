using System;
using System.Web;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for reconcile_inventory_rfid.
	/// </summary>
	public class reconcile_inventory_rfid : BasePage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls;
        protected System.Web.UI.HtmlControls.HtmlAnchor rfidLink;
        protected System.Web.UI.HtmlControls.HtmlAnchor batchLink;
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
            this.batchLink.ServerClick += new System.EventHandler(this.batchLink_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Reconcile Inventory";
            this.levelTwo = LevelTwoNav.Reconcile;
            this.helpId = 54;
            // Auditors and viewers should not be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Session[CacheKeys.Exception] != null)
            {
                this.DisplayErrors(this.PlaceHolder1, ((Exception)Session[CacheKeys.Exception]).Message);
                Session.Remove(CacheKeys.Exception);
            }
            // If not postback, set tab page preference
            if (!this.IsPostBack)
                TabPageDefault.Update(TabPageDefaults.InventoryFile, Context.Items[CacheKeys.Login], 2);
        }
        /// Event handler for OK button
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            HttpPostedFile postedFile;

            if (File1.Value.Trim().Length != 0)
            {
                if ((postedFile = File1.PostedFile) == null || postedFile.ContentLength == 0)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Unable to find or access '" + File1.Value + "'");
                }
                else
                {
                    // Upload the file
                    byte[] b = new byte[File1.PostedFile.ContentLength];
                    File1.PostedFile.InputStream.Read(b, 0, File1.PostedFile.ContentLength);
                    // Add session objects
                    Session[CacheKeys.Object] = b;
                    Session[CacheKeys.WaitRequest] = RequestTypes.InventoryReconcile;
                    // Redirect to wait page
                    Response.Redirect("../waitPage.aspx?redirectPage=media-library/reconcile-inventory.aspx&box=1&download=0&errorPage=media-library/reconcile-inventory-rfid.aspx&x=" + Guid.NewGuid().ToString("N"), false);
                }
            }
        }
        /// <summary>
        /// Transfer to batch scan link
        /// </summary>
        private void batchLink_ServerClick(object sender, System.EventArgs e)
        {
            Server.Transfer("reconcile-inventory-batch.aspx");
        }
    }
}
