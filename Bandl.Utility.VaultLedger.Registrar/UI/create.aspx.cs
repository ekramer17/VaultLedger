using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.Caching;
using System.Threading;
using System.Configuration;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Utility.VaultLedger.Registrar.BLL;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
	/// <summary>
	/// Summary description for success.
	/// </summary>
	public class create : masterPage
	{
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        public string Uid = String.Empty;
        public string Pwd = String.Empty;
        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!this.IsPostBack)
            {
                // Get the usercode if it exists
                object o = GetSessionObject(CacheKeys.Uid);
                if (o != null) Uid = (string)o;
                // Get the password if it exists
                o = GetSessionObject(CacheKeys.Pwd);
                if (o != null) Pwd = (string)o;

                if (EmptyNull(Request.QueryString["r"]) == "1")
                {
                    // Do nothing this is the post back from the wait page
                }
                else
                {
                    // If we are using the pass-through, create the user and place him in the session
                    if (EmptyNull(Request.QueryString["passThru"]) == "1")
                    {
                        try
                        {
                            string n = EmptyNull(Request.QueryString["name"]);
                            string m = EmptyNull(Request.QueryString["email"]);
                            string p = EmptyNull(Request.QueryString["phone"]);
                            string c = EmptyNull(Request.QueryString["company"]);
                            string a1 = EmptyNull(Request.QueryString["address1"]);
                            string a2 = EmptyNull(Request.QueryString["address2"]);
                            string i = EmptyNull(Request.QueryString["city"]);
                            string s = EmptyNull(Request.QueryString["state"]);
                            string z = EmptyNull(Request.QueryString["zip"]);
                            string u = EmptyNull(Request.QueryString["country"]);
                            // Create the new owner
                            Session[CacheKeys.Owner] = new OwnerDetails(c, a1, a2, i, s, z, u, n, p, m, String.Empty, AccountTypes.Bandl);
                        }
                        catch
                        {
                            Response.Redirect("pageOne.aspx");
                        }
                    }
                    // If we have no owner, redirect to page one
                    if (Session[CacheKeys.Owner] == null)
                    {
                        Response.Redirect("pageOne.aspx");
                    }
                    else
                    {
                        this.Register((OwnerDetails)Session[CacheKeys.Owner]);
                    }
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
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
        }
		#endregion

        private void btnGo_Click(object sender, System.EventArgs e)
        {
            Response.Redirect(ConfigurationSettings.AppSettings["ApplicationUrl"]);
        }
    }
}
