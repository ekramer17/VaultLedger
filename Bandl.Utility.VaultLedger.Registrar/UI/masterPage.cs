using System;
using System.IO;
using System.Web;
using System.Text;
using System.Drawing;
using System.Web.UI;
using System.Threading;
using System.Web.SessionState;
using System.Web.UI.WebControls;
using System.Security.Principal;
using Bandl.Utility.VaultLedger.Registrar.BLL;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
    public class masterPage : Page
    {
        #region Web Form Designer generated code
        override protected void OnInit(EventArgs e)
        {
            //
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
            this.Load += new System.EventHandler(this.Page_Load);
            this.Init += new System.EventHandler(this.Page_Init);
            this.PreRender += new System.EventHandler(this.Page_PreRender);

        }
        #endregion

        #region Public Properties
        protected string ProductName
        {
            get 
            {
                return Configurator.ProductName;
            }
        }

        protected string TotalPages
        {
            get 
            {
                return Configurator.AllowDownload ? "3" : "2";
            }
        }
        #endregion

        #region Protected Properties
        protected string ImageVirtualDirectory 
        {
            get 
            {
                switch (Configurator.ProductType)
                {
                    case "RECALL":
                        return String.Format("{0}/resources/img/{1}", HttpRuntime.AppDomainAppVirtualPath, "recall");
                    default:
                        return String.Format("{0}/resources/img/{1}", HttpRuntime.AppDomainAppVirtualPath, "bandl");
                }
            }
        }
        #endregion

        #region Event Handlers
        /// <summary>
        /// Page init event handler.  No descendents should implement
        /// a page init event handler.  Override the Event_PageInit
        /// method instead.
        /// </summary>
        protected void Page_Init(object sender, System.EventArgs e)
        {
            Configurator.BaseDirectory = HttpRuntime.AppDomainAppPath;
            Event_PageInit(sender, e);
        }
        /// <summary>
        /// Page load event handler.  No descendents should implement
        /// a page load event handler.  Override the Event_PageLoad 
        /// method instead.
        /// </summary>
        protected void Page_Load(object sender, System.EventArgs e)
        {
            Event_PageLoad(sender, e);
        }
        /// <summary>
        /// Page prerender event handler.  No descendents should implement
        /// a page prerender event handler.  Override the Event_PagePreRender
        /// method instead.
        /// </summary>
        protected void Page_PreRender(object sender, System.EventArgs e)
        {
            Event_PagePreRender(sender, e);
        }
        /// <summary>
        /// Page init event tripped by init in this base page.  Page
        /// classes descending from this class should override this
        /// method and implement page init code in it rather than
        /// creating a Page_Init event handler, which would override
        /// the one in this base page.
        /// </summary>
        virtual protected void Event_PageInit(object sender, System.EventArgs e) {}
        /// <summary>
        /// Page load event tripped by load in this base page.  Page
        /// classes descending from this class should override this
        /// method and implement page loading code in it rather than
        /// creating a Page_Load event handler, which would override
        /// the one in this base page.
        /// </summary>
        virtual protected void Event_PageLoad(object sender, System.EventArgs e) {}
        /// <summary>
        /// Page prerender event tripped by load in this base page.  Page
        /// classes descending from this class should override this
        /// method and implement page loading code in it rather than
        /// creating a Page_Load event handler, which would override
        /// the one in this base page.
        /// </summary>
        virtual protected void Event_PagePreRender(object sender, System.EventArgs e) {}
        #endregion

        #region Display Methods
        public string BuildStyles()
        {
            string styleBase;
            // Get the stylesheet directory
            switch (Configurator.ProductType)
            {
                case "RECALL":
                    styleBase = String.Format("{0}/resources/style/recall", HttpRuntime.AppDomainAppVirtualPath);
                    break;
                default:
                    styleBase = String.Format("{0}/resources/style/bandl", HttpRuntime.AppDomainAppVirtualPath);
                    break;
            }
            // Build the string
            StringBuilder s = new StringBuilder("<style type=\"text/css\">");
            s.AppendFormat("@import url({0}/registrar.css);", styleBase);
            s.AppendFormat("</style>{0}", Environment.NewLine);
            // Functions
            s.AppendFormat("<script language=\"JavaScript\" src=\"{0}/functions.js\" ", HttpRuntime.AppDomainAppVirtualPath);
            s.Append("type=\"text/javascript\"></script>");
            s.Append(Environment.NewLine);
            // Return
            return s.ToString();
        }

        public string BuildBody()
        {
            StringBuilder bodyBuilder = new StringBuilder();
            string productType = Configurator.ProductType;
            // Special case if the database prefix is "RQMM_".  Bit of a fake-out here.  Putting a registrar up
            // that is to look like Recall but act like B&L.
            if (Configurator.DbNamePrefix == "RQMM_")
            {
                productType = "RECALL";
            }
            // Build the header
            switch (productType)
            {
                case "RECALL":
                    bodyBuilder.AppendFormat("<div style=\"BORDER-RIGHT:#27274f 1px solid;BACKGROUND:url({0}/topBar.gif) repeat-x; WIDTH:779px; POSITION:relative; HEIGHT:59px\">{1}", ImageVirtualDirectory, Environment.NewLine);
                    bodyBuilder.AppendFormat("   <div style=\"Z-INDEX:2;LEFT:30px;POSITION:absolute;TOP:16px\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      <IMG alt=\"recall\" src=\"{0}/recallLogo.gif\"/>{1}", ImageVirtualDirectory, Environment.NewLine);
                    bodyBuilder.AppendFormat("   </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("   <div style=\"Z-INDEX:2;LEFT:131px;POSITION:absolute;TOP:22px\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      <IMG height=\"15\" src=\"{0}/reQuestLogo.gif\" width=\"153\" border=\"0\">{1}", ImageVirtualDirectory, Environment.NewLine);
                    bodyBuilder.AppendFormat("   </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("   <div style=\"FLOAT:right; MARGIN:24px 6px 0px 0px\" align=\"right\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      <div style=\"font:12px tahoma,arial,sans-serif;font-weight:bold;color:#27274F\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("         Client Registrar{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("   </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("</div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("<div style=\"BORDER-TOP:#000 1px solid;BORDER-RIGHT:#27274f 1px solid;BORDER-BOTTOM:1px solid #000;background:#00529B;POSITION:relative;WIDTH:779px;HEIGHT:21px\"/>{0}", Environment.NewLine);
                    break;
                default:
                    bodyBuilder.AppendFormat("<div style=\"BORDER-RIGHT:#2E2B24 1px solid;BACKGROUND:url({0}/topBar.gif) repeat-x; WIDTH:779px; POSITION:relative; HEIGHT:59px\">{1}", ImageVirtualDirectory, Environment.NewLine);
                    bodyBuilder.AppendFormat("   <div style=\"Z-INDEX:2;LEFT:30px;POSITION:absolute;TOP:6px\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      <IMG alt=\"bandl\" src=\"{0}/bandlLogo.gif\"/>{1}", ImageVirtualDirectory, Environment.NewLine);
                    bodyBuilder.AppendFormat("   </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("   <div style=\"Z-INDEX:2;LEFT:108px;POSITION:absolute;TOP:19px\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      <IMG height=\"26\" src=\"{0}/vaultLedger.gif\" width=\"92\" border=\"0\">{1}", ImageVirtualDirectory, Environment.NewLine);
                    bodyBuilder.AppendFormat("   </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("   <div style=\"FLOAT:right; MARGIN:24px 6px 0px 0px\" align=\"right\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      <div style=\"font:12px tahoma,arial,sans-serif;font-weight:bold;color:#2E2B24\">{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("         Client Registrar{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("      </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("   </div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("</div>{0}", Environment.NewLine);
                    bodyBuilder.AppendFormat("<div style=\"BORDER-TOP:#000 1px solid;BORDER-RIGHT:#2E2B24 1px solid;BORDER-BOTTOM:1px solid #000;background:#00529B;POSITION:relative;WIDTH:779px;HEIGHT:21px\"/>{0}", Environment.NewLine);
                    break;
            }
            // Return the string
            return bodyBuilder.ToString();
        }
        #endregion

        #region Utility Methods
        protected void SetFocus(Control ctrl)
        {
            // Define the JavaScript function for the specified control.
            string focusScript = "<script language='javascript'>document.getElementById('" + ctrl.ClientID + "').focus();</script>";
            // Add the JavaScript code to the page.
            Page.RegisterStartupScript("SetControlFocus", focusScript);
        }

        /// <summary>
        /// Sets the default button for the page
        /// </summary>
        /// <param name="buttonName">
        /// Name of the button to set as the default
        /// </param>
        protected void SetDefaultButton(string buttonName)
        {
            this.RegisterHiddenField("__EVENTTARGET", buttonName);
        }

        protected string EmptyNull(string s)
        {
            return s != null ? s : String.Empty;
        }

        protected object GetSessionObject(string key)
        {
            if (Session[key] == null) return null;
            object o = Session[key];
            Session.Remove(key);
            return o;
        }
        #endregion

        private delegate void EmptyDelegate(OwnerDetails o, HttpSessionState q, WindowsIdentity i);

        protected void Register(OwnerDetails o)
        {
            // Call method asycnhronously
            Logger oLogger = new Logger();
            oLogger.WriteLine(WindowsIdentity.GetCurrent().Name);
            Session[CacheKeys.AsyncResult] = new EmptyDelegate(DoRegister).BeginInvoke(o, HttpContext.Current.Session, WindowsIdentity.GetCurrent(), null, null);
            // Redirect
            Response.Redirect("waitPage.aspx?r=1");
        }

        private void DoRegister(OwnerDetails o, HttpSessionState q, WindowsIdentity i)
        {
            try
            {
                // Impersonate the calling thread
                WindowsImpersonationContext c = i.Impersonate();
                // Register
                ((IProcessObject)(new BLL.Registrar(o))).Execute(q);
                // Clean the cache
                Session.Remove(CacheKeys.Owner);
                // Undo the identity
                c.Undo();
            }
            catch (Exception e)
            {
                Session[CacheKeys.Exception] = e;
            }
        }
    }
}
