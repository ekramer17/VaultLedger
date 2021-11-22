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
	/// Summary description for errorPage.
	/// </summary>
	public class errorPage : masterPage
	{
        protected System.Web.UI.WebControls.Button btnRetry;
        protected System.Web.UI.WebControls.Label lblError;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
    
        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            // Set control focus
            SetFocus(this.btnRetry);
            // Display error message
            if (!this.IsPostBack)
            {
                // Get the exception
                Exception x = (Exception)Session[CacheKeys.Exception];
                // Remove the exception from the cache and display the message
                if (x != null)
                {
                    Session.Remove(CacheKeys.Exception);
                    lblError.Text = x.Message;
                }
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
        }
		#endregion

        private void btnRetry_Click(object sender, System.EventArgs e)
        {
            Response.Redirect("create.aspx");
        }
	}
}
