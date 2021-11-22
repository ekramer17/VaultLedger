using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Text;
using System.Web.Caching;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Utility.VaultLedger.Registrar.BLL;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
	/// <summary>
	/// Summary description for busy.
	/// </summary>
    public class waitPage : masterPage
    {
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.HtmlControls.HtmlImage pleaseWait;
        protected System.Web.UI.HtmlControls.HtmlInputHidden nextUrl;
        protected System.Web.UI.HtmlControls.HtmlInputHidden gifPath;
        protected System.Web.UI.HtmlControls.HtmlInputHidden errorUrl;
        private string redirectPage = "create.aspx";
        private string errorPage = "errorPage.aspx";

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

        public string ProductTitle { get {return Configurator.ProductName;} }

        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            // Get the redirect page
            if (Request.QueryString["redirectPage"] != null)
                redirectPage = String.Format("{0}/{1}", HttpRuntime.AppDomainAppVirtualPath, Request.QueryString["redirectPage"]);
            // Get the error page if it exists
            if (Request.QueryString["errorPage"] != null)
                errorPage = String.Format("{0}/{1}", HttpRuntime.AppDomainAppVirtualPath, Request.QueryString["errorPage"]);
            // Get the proper gif path
            this.gifPath.Value = String.Format("resources/img/{0}/pleaseWait.gif", Configurator.ProductType == "RECALL" ? "recall" : "bandl");
            // Set the next url values
            this.nextUrl.Value = redirectPage + Request.Url.Query;
            this.errorUrl.Value = errorPage;

        }
    }
}
