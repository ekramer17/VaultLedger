using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.Caching;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
	/// <summary>
	/// Summary description for pageThree.
	/// </summary>
	public class pageThree : masterPage
	{
        protected System.Web.UI.WebControls.PlaceHolder msgHolder;
        protected System.Web.UI.WebControls.Button btnBack;
        protected System.Web.UI.WebControls.Button btnNext;
        protected System.Web.UI.WebControls.RadioButton rbDownload;
        protected System.Web.UI.WebControls.RadioButton rbAllowHost;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        private bool oneClick = false;
    
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
            this.btnBack.Click += new System.EventHandler(this.btnBack_Click);
            this.btnNext.Click += new System.EventHandler(this.btnNext_Click);
        }
		#endregion

        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            if (this.IsPostBack)
            {
                oneClick = (bool)this.ViewState["oneClick"];
            }
            else if (Session[CacheKeys.Owner] == null) 
            {
                Response.Redirect("pageOne.aspx", true);
            }
            // Set the focus
            SetFocus(rbDownload.Checked ? rbDownload : rbAllowHost);
            // Set the viewstate
            ViewState["oneClick"] = oneClick;
        }

        private void btnNext_Click(object sender, System.EventArgs e)
        {
            if (oneClick == false)
            {
                // Set the click flag
                this.ViewState["oneClick"] = oneClick = true;
                // Register or redirect
                if (this.rbDownload.Checked)
                {
                    Response.Redirect("download.aspx");
                }
                else
                {
                    this.Register((OwnerDetails)Session[CacheKeys.Owner]);
                }
            }
        }

        private void btnBack_Click(object sender, System.EventArgs e)
        {
            Response.Redirect("pageTwo.aspx");
        }
	}
}
