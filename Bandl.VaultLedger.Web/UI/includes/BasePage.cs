using System;
using System.IO;
using System.Web;
using System.Xml;
using System.Text;
using System.Web.UI;
using System.Drawing;
using System.Xml.Xsl;
using System.Security;
using System.Threading;
using System.Xml.XPath;
using System.Collections;
using System.Web.Security;
using System.Security.Principal;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using System.Collections.Specialized;

namespace Bandl.VaultLedger.Web.UI
{
    public class BasePage : Page
    {
        // Level two navigation enumeration
        protected enum LevelTwoNav
        {
            None = 0,
            Find,
            Reconcile,
            New,
            Todays,
            Shipping,
            Receiving,
            DisasterRecovery,
            BarCodeFormats,
            CaseFormats,
            SiteMaps,
            Users,
            EmailGroups,
            Accounts,
            FtpProfiles,
            Preferences,
            Types,
            Cases,
            RFIDInitialize
        }

        protected LevelTwoNav levelTwo = LevelTwoNav.None;
        protected delegate void PrincipalDelegate(IPrincipal p);
        protected delegate void EmptyDelegate();
        // Page objects
        protected System.Web.UI.WebControls.Label lblGreeting;
        protected System.Web.UI.HtmlControls.HtmlImage iLogo;
        protected System.Web.UI.HtmlControls.HtmlImage iProduct;
        protected System.Web.UI.HtmlControls.HtmlImage imationLogo;
        protected System.Web.UI.HtmlControls.HtmlGenericControl constants;
        protected System.Web.UI.HtmlControls.HtmlGenericControl helpHeaders;
        protected System.Web.UI.HtmlControls.HtmlGenericControl imationBlock;
        // Page fields
        protected string pageTitle = String.Empty;
        protected bool createNavigation = true; // create the navigation tabs
        protected bool createHeader = true;     // create the header links, i.e. profile, help, logout
        protected int helpId = 0;

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
            this.Unload += new EventHandler(this.Page_Unload);
            this.PreRender += new EventHandler(this.Page_PreRender);
        }
        #endregion

        #region Protected Properties
        protected string ImagePathDirectory 
        {
            get 
            {
                switch (Configurator.ProductType)
                {
                    case "RECALL":
                        return Path.Combine(Path.Combine(Path.Combine(HttpRuntime.AppDomainAppPath, "resources"), "img"), "recall");
                    default:
                        return Path.Combine(Path.Combine(Path.Combine(HttpRuntime.AppDomainAppPath, "resources"), "img"), "bandl");
                }
            }
        }

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

        protected string ProductName
        {
            get
            {
                return Configurator.ProductName;
            }
        }

        protected string PageTitle
        {
            get
            {
                if (pageTitle.Length != 0)
                {
                    return String.Format("{0} - {1}", ProductName,  pageTitle);
                }
                else
                {
                    return ProductName;
                }
            }
        }
        #endregion

        /// <summary>
        /// Page init event handler.  No descendents should implement
        /// a page init event handler.  Override the Event_PageInit
        /// method instead.
        /// </summary>
        protected void Page_Init(object sender, System.EventArgs e)
        {
            // If we a level two navigation in the viewstate, get it here.
            if (this.ViewState["LevelTwo"] != null)
                this.levelTwo = (LevelTwoNav)this.ViewState["LevelTwo"];
            // Fire the surrogate page init event for descendant classes
            Event_PageInit(sender, e);
        }

        /// <summary>
        /// Page load event handler.  No descendents should implement
        /// a page load event handler.  Override the Event_PageLoad 
        /// method instead.
        /// </summary>
        protected void Page_Load(object sender, System.EventArgs e)
        {
            // Set the header images
            if (this.iProduct != null)
            {
                if (Configurator.ProductType != "IMATION")
                {
                    iProduct.Attributes.Add("src", String.Format("{0}/interface/logo_header.gif", ImageVirtualDirectory));
                }
                else
                {
                    iProduct.Attributes.Add("src", String.Format("{0}/interface/logo_imation_header.gif", ImageVirtualDirectory));
                    SetControlAttr(iProduct, "style", "position:absolute;margin-top:-5px;left:228px", false);
                }
            }
            if (this.iLogo != null) 
            {
                iLogo.Attributes.Add("src", String.Format("{0}/interface/logo.gif", ImageVirtualDirectory));
            }
            // Set header images, and set the greeting if greeting label exists, 
            // and the session login exists.
            if (this.createHeader == true)
            {
                // Set the greeting label
                if (lblGreeting != null && Context.Items[CacheKeys.Login] != null)
                {
                    if (((string)Context.Items[CacheKeys.Login]).Length != 0)
                    {
                        lblGreeting.Text = String.Format("Welcome, {0}", Context.Items[CacheKeys.Login]);
                        lblGreeting.Font.Bold = true;
                    }
                    else
                    {
                        lblGreeting.Text = String.Empty;
                    }
                }
            }
            // Fire the surrogate page load event for descendant classes
            Event_PageLoad(sender, e);
        }

        /// <summary>
        /// Page prerender event handler.  No descendents should implement
        /// a page prerender event handler.  Override the Event_PagePreRender
        /// method instead.
        /// </summary>
        protected void Page_PreRender(object sender, System.EventArgs e)
        {
            // Fire the surrogate page prerender event for descendant classes
            Event_PagePreRender(sender, e);
            // Place the level two navigation in the viewstate
            if (!Page.IsPostBack)
                this.ViewState["LevelTwo"] = this.levelTwo;
            // If Imation, we have to move the constants block and show the imation graphic
            if (Configurator.ProductType == "IMATION")
            {
                lblGreeting.Visible = false;
                SetControlAttr(imationBlock, "style", "position:absolute;top:11px;left:654px;z-index:2", false);
                imationLogo.Attributes.Add("src", String.Format("{0}/interface/logo_imation.gif", ImageVirtualDirectory));
                SetControlAttr(this.helpHeaders, "style", String.Format("position:absolute;left:{0}px;margin-top:-5px", Request.CurrentExecutionFilePath.ToLower().EndsWith("/login.aspx") ? 188 : 124), false);
            }
        }

        /// <summary>
        /// Page unload event handler.  No descendents should implement
        /// a page unload event handler.  Override the Event_PageUnload
        /// method instead.
        /// </summary>
        protected void Page_Unload(object sender, System.EventArgs e)
        {
            // Fire the surrogate page unload event for descendant classes
            Event_PageUnload(sender, e);
        }
        
        #region Event Overloads
        /// <summary>
        /// Page init event tripped by load in this base page.  Page
        /// classes descending from this class should override this
        /// method and implement page loading code in it rather than
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
        /// classes descending from this class should override this method 
        /// and implement page prerender code in it rather than creating a 
        /// Page_PreRender event handler, which would override the one in 
        /// this base page.
        /// </summary>
        virtual protected void Event_PagePreRender(object sender, System.EventArgs e) {}

        /// <summary>
        /// Page unload event tripped by unload event in this base page.  Page
        /// classes descending from this class should override this method 
        /// and implement page unload code in it rather than creating a 
        /// Page_Unload event handler, which would override the one in 
        /// this base page.
        /// </summary>
        virtual protected void Event_PageUnload(object sender, System.EventArgs e) {}
        #endregion
        
        #region Static Header Methods
        /// <summary>
        /// Imports all the stylesheets that may need to be used by the page
        /// </summary>
        /// <returns>
        /// String to be placed in the response
        /// </returns>
        public static string BuildStyleImports()
        {
            string styleBase = String.Empty;
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
            StringBuilder styleBuilder = new StringBuilder();
            styleBuilder.AppendFormat("<link rel=\"stylesheet\" type=\"text/css\" href=\"{0}/tables.css\" media=\"screen\" />{1}", styleBase, Environment.NewLine);
            styleBuilder.AppendFormat("<link rel=\"stylesheet\" type=\"text/css\" href=\"{0}/main.css\" media=\"screen\" />{1}", styleBase, Environment.NewLine);
            styleBuilder.AppendFormat("<link rel=\"stylesheet\" type=\"text/css\" href=\"{0}/msgBox.css\" media=\"screen\" />{1}", styleBase, Environment.NewLine);
            return styleBuilder.ToString();
        }
        /// <summary>
        /// Includes the javascript files that may be needed by the page
        /// </summary>
        /// <returns>
        /// String to be placed in the response
        /// </returns>
        public static string BuildIncludes()
        {
            string virtualBase = HttpRuntime.AppDomainAppVirtualPath;
            // Functions
            StringBuilder scriptBuilder = new StringBuilder("<script language=\"JavaScript\" ");
            scriptBuilder.AppendFormat("src=\"{0}/includes/functions.js\" ", virtualBase);
            scriptBuilder.Append("type=\"text/javascript\"></script>");
            scriptBuilder.Append(Environment.NewLine);
            // Calendar
            scriptBuilder.Append("<script language=\"JavaScript\" ");
            scriptBuilder.AppendFormat("src=\"{0}/includes/calendar.js\" ", virtualBase);
            scriptBuilder.Append("type=\"text/javascript\"></script>");
            scriptBuilder.Append(Environment.NewLine);
            // Date
            scriptBuilder.Append("<script language=\"JavaScript\" ");
            scriptBuilder.AppendFormat("src=\"{0}/includes/date.js\" ", virtualBase);
            scriptBuilder.Append("type=\"text/javascript\"></script>");
            scriptBuilder.Append(Environment.NewLine);
            // Message Box
            scriptBuilder.Append("<script language=\"JavaScript\" ");
            scriptBuilder.AppendFormat("src=\"{0}/includes/msgBox.js\" ", virtualBase);
            scriptBuilder.Append("type=\"text/javascript\"></script>");
            scriptBuilder.Append(Environment.NewLine);
            // Robohelp
            scriptBuilder.Append("<script language=\"JavaScript\" ");
            scriptBuilder.AppendFormat("src=\"{0}/includes/robohelp_csh.js\" ", virtualBase);
            scriptBuilder.Append("type=\"text/javascript\"></script>");
            scriptBuilder.Append(Environment.NewLine);
            // Return
            return scriptBuilder.ToString();
        }

        #endregion

        #region Navigation Builder Methods
        /// <summary>
        /// Builds the header of the page
        /// </summary>
        /// <param name="level">
        /// Which level to build (constants - 0, level one tabs - 1, level two tabs - 2
        /// </param>
        /// <returns>
        /// String to be placed in the response
        /// </returns>
        public string BuildHeader(int level)
        {
            String x1 = null;
            XslCompiledTransform c1 = new XslCompiledTransform();
            // Some pages may not want certain things rendered.  If the level
            // is zero but the page does not want the headers rendered, return
            // the empty string.  Likewise, return the empty string if the
            // level is one but the page does not want navigation rendered.
            // And if the level is two but the page does not want navigation
            // rendered, return text that will create only the blue bar.
            if (level == 0 && !this.createHeader)
            {
                return String.Empty;
            }
            else if (level == 1 && !this.createNavigation)
            {
                return String.Empty;
            }
            else if (level == 2 && !this.createNavigation)
            {
                return "<div id=\"levelTwoNav\"></div>";
            }
            // Otherwise, render headers and navigation links normally.  Get 
            // the application domain path.
            StringBuilder domainPath = new StringBuilder(HttpRuntime.AppDomainAppPath);
            if (!HttpRuntime.AppDomainAppPath.EndsWith(Path.DirectorySeparatorChar.ToString()))
            {
                domainPath.Append(Path.DirectorySeparatorChar);
            }
            domainPath.Append("xml");
            domainPath.Append(Path.DirectorySeparatorChar);
            // Set the xslt argument list to the current page
            XsltArgumentList xsltArgs = null;
            if (Request != null)
            {
                xsltArgs = new XsltArgumentList();
                xsltArgs.AddParam("currentUrl", "", Request.CurrentExecutionFilePath.Replace(Request.ApplicationPath,"").Substring(1));
            }
            // Load the xsl document
            switch (level)
            {
                case 0:     // top constants
                    c1.Load(String.Format("{0}constants.xslt", domainPath.ToString()));
                    break;
                case 1:     // tab level ones
                    c1.Load(String.Format("{0}levelOnes.xslt", domainPath.ToString()));
                    break;
                case 2:     // tab level twos
                    c1.Load(String.Format("{0}levelTwos.xslt", domainPath.ToString()));
                    break;
                default:
                    throw new ApplicationException("Invalid header constant");
            }
            // Transform the document
            using (XmlReader r1 = XmlReader.Create(String.Format("{0}navigation.xml", domainPath.ToString())))
            {
                using (StringWriter w1 = new StringWriter())
                {
                    c1.Transform(r1, xsltArgs, w1);
                    x1 = w1.ToString();
                }
            }
            // Build the navigation string by stripping out unnecessary xml/xsl text and
            // by replacing the base url string with the correct value
            StringBuilder returnValue = new StringBuilder(x1).Replace(" xmlns:fo=\"http://www.w3.org/1999/XSL/Format\"", "");
            returnValue = returnValue.Replace("[BASE_URL]", String.Format("{0}/", HttpRuntime.AppDomainAppVirtualPath)).Replace("[IMAGE_URL]", ImageVirtualDirectory);
            // Add the help value for the constant string, and if we have a session login,
            // alter the link for the user profile.
            if (level == 0) 
            {
                // Build the help link url.  If this is the login page, then we should not
                // show the profile link nor the logout link, since neither makes sense in
                // the context of the login page.
                if (Request.CurrentExecutionFilePath.ToLower().EndsWith("/login.aspx"))
                {
                    returnValue = new StringBuilder(BuildHelpLink().Replace("<a", "<a id=\"firstBtn\" "));
                }
                else
                {
                    returnValue = returnValue.Replace("<a href=\"#\">Help</a>", BuildHelpLink());
                    // Supply user detail link to My Profile anchor
                    if (Context.Items[CacheKeys.Login] != null && ((string)Context.Items[CacheKeys.Login]).Length != 0)
                    {
                        returnValue = returnValue.Replace("user-detail.aspx", String.Format("user-detail.aspx?login={0}", (string)Context.Items[CacheKeys.Login]));
                    }
                }
            }
            else if (level == 1)
            {
                string s1 = null;
                string s2 = null;
                // Reports tab page default
                switch (TabPageDefault.GetDefault(TabPageDefaults.ReportCategory, Context.Items[CacheKeys.Login]))
                {
                    case 2:
                        s1 = String.Format("href=\"{0}/reports/report-list.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                        s2 = String.Format("href=\"{0}/reports/report-list-two.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                        returnValue = returnValue.Replace(s1, s2);
                        break;
                    case 3:
                        s1 = String.Format("href=\"{0}/reports/report-list.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                        s2 = String.Format("href=\"{0}/reports/report-list-three.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                        returnValue = returnValue.Replace(s1, s2);
                        break;
                }
                // Lists tab page default
                if (TabPageDefault.GetDefault(TabPageDefaults.TodaysList, Context.Items[CacheKeys.Login]) == 2)
                {
                    s1 = String.Format("href=\"{0}/lists/todays-list.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                    s2 = String.Format("href=\"{0}/lists/todays-receiving-list.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                    returnValue = returnValue.Replace(s1, s2);
                }

            }
            else if (level == 2)
            {
                if (TabPageDefault.GetDefault(TabPageDefaults.TodaysList, Context.Items[CacheKeys.Login]) == 2)
                {
                    string s1 = String.Format("href=\"{0}/lists/todays-list.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                    string s2 = String.Format("href=\"{0}/lists/todays-receiving-list.aspx\"", HttpRuntime.AppDomainAppVirtualPath);
                    returnValue = returnValue.Replace(s1, s2);
                }
            }
            // Hide any inaccessible tabs that should be inaccessible due to the
            // security level of the current user.
            returnValue = this.HideInaccessibleTabs(returnValue, level);
            // If we are dealing with level two, then call the function that selects the correct
            // level two navigation item.  Otherwise just return the string.
            if (level != 2)
            {
                return returnValue.ToString();
            }
            else
            {
                return SelectLevelTwo(returnValue);
            }
        }
        /// <summary>
        /// Hides tabs that should be inaccessible according to the security level
        /// of the currently logged in user.
        /// </summary>
        /// <param name="s">Stringbuilder containing level two navigation string</param>
        /// <param name="level">Level of navigation being altered</param>
        private StringBuilder HideInaccessibleTabs(StringBuilder s, int level)
        {
            // We must check for the login page explicitly, because if the request
            // is for the login page then there will be no security context.  The
            // only adjustment for the login page is to hide the administrator
            // tab in the level one navigation html.
            if (Request.CurrentExecutionFilePath.ToLower().EndsWith("/login.aspx"))
            {
                if (level == 1)
                {					
                    s = s.Replace(String.Format("<a href=\"{0}/administrative-tools/index.aspx\"><img src=\"{1}/btns/l1_admin_0.gif\" border=\"0\" alt=\"Administrative Tools\" title=\"Administrative Tools\"></a>", HttpRuntime.AppDomainAppVirtualPath, ImageVirtualDirectory),"");
                    s = s.Replace(String.Format("<a href=\"{0}/reports/report-list.aspx\"><img src=\"{1}/btns/l1_reports_0.gif\" border=\"0\" alt=\"Reports\" title=\"Reports\"></a>", HttpRuntime.AppDomainAppVirtualPath, ImageVirtualDirectory),"");
                }
            }
            else
            {
                // If we're looking at the level one tabs, then prevent the admin
                // tab from showing if the current user is not an administrator.
                // If we're looking at the level two tabs, then prevent the level
                // two new media link from showing if the current user is an
                // auditor or operator.
                if (level == 1)
                {
                    switch (CustomPermission.CurrentOperatorRole())
                    {
                        case Role.Administrator:
                            break;
                        case Role.Operator:
                        case Role.Auditor:
                            s = s.Replace(String.Format("<a href=\"{0}/administrative-tools/index.aspx\"><img src=\"{1}/btns/l1_admin_0.gif\" border=\"0\" alt=\"Administrative Tools\" title=\"Administrative Tools\"></a>", HttpRuntime.AppDomainAppVirtualPath, ImageVirtualDirectory),"");
                            break;
                        case Role.VaultOps:
                        case Role.Viewer:
                            s = s.Replace(String.Format("<a href=\"{0}/administrative-tools/index.aspx\"><img src=\"{1}/btns/l1_admin_0.gif\" border=\"0\" alt=\"Administrative Tools\" title=\"Administrative Tools\"></a>", HttpRuntime.AppDomainAppVirtualPath, ImageVirtualDirectory),"");
                            s = s.Replace(String.Format("<a href=\"{0}/reports/report-list.aspx\"><img src=\"{1}/btns/l1_reports_0.gif\" border=\"0\" alt=\"Reports\" title=\"Reports\"></a>", HttpRuntime.AppDomainAppVirtualPath, ImageVirtualDirectory),"");
                            break;
                    }
                }
                else if (level == 2)
                {
                    switch (CustomPermission.CurrentOperatorRole())
                    {
                        case Role.Administrator:
                        case Role.Operator:
                            break;
                        case Role.VaultOps:
                            s = s.Replace(String.Format("<a href=\"{0}/lists/disaster-recovery-list-browse.aspx\">Disaster Recovery</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                            s = s.Replace(String.Format("<a href=\"{0}/media-library/new-media-step-one.aspx\">New</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                            s = s.Replace(String.Format("<a href=\"{0}/media-library/media-types.aspx\">Types</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                            break;
                        case Role.Auditor:
                        case Role.Viewer:
                            s = s.Replace(String.Format("<a href=\"{0}/media-library/new-media-step-one.aspx\">New</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                            s = s.Replace(String.Format("<a href=\"{0}/media-library/media-types.aspx\">Types</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                            break;
                    }
                    // Medium types only visible to BANDL branded product.  Email groups and ftp profiles are also not visible to Recall.
                    switch (Configurator.ProductType)
                    {
                        case "RECALL":
                            s = s.Replace(String.Format("<a href=\"{0}/media-library/media-types.aspx\">Types</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                            s = s.Replace(String.Format("<a href=\"{0}/administrative-tools/ftp-profiles.aspx\">Ftp Profiles</a>", HttpRuntime.AppDomainAppVirtualPath), String.Empty);
                            s = s.Replace(String.Format("<a href=\"{0}/administrative-tools/email-groups.aspx\">Email Groups</a>", HttpRuntime.AppDomainAppVirtualPath), String.Empty);
                            break;
                        default:
                            break;
                    }
                    // Imation RFID initialization only available if licensed
                    if (ProductLicense.GetProductLicense(LicenseTypes.RFID).Units != 1)
                    {
                        s = s.Replace(String.Format("<a href=\"{0}/media-library/rfid-tag-initialize.aspx\">RFID Initialize</a>", HttpRuntime.AppDomainAppVirtualPath),"");
                    }
                }
            }
            // Return the stringbuilder
            return s;
        }
        /// <summary>
        /// Highlights the correct level two navigation header
        /// </summary>
        /// <param name="s">Stringbuilder containing level two navigation string</param>
        /// <returns>Level two navigation header, after adjustment</returns>
        private string SelectLevelTwo(StringBuilder s)
        {
            // If the selected brackets already appear, then just return.  This means that
            // the XPath transformation took care of the highlight.
            if (s.ToString().IndexOf("[ ") != -1)
            {
                return s.ToString();
            }
            else
            {
                string selectName = this.SpacesBeforeCaps(this.levelTwo);
                // Enumerations can't have aposotrophes, so we need to place
                // one in the string manually if necessary.  Currently the only
                // level two header that requires one is "Todays".
                if (selectName == "Todays") selectName = "Today's";
                // Find the string in the level two navigation string.  If it appears,
                // surround it with brackets and set its tag id to "selected".
                s = s.Replace(selectName, String.Format("[ {0} ]", selectName));   
                // If we performed the replace, set the prior tag to have an
                // id of "selected".
                int bracketIndex = s.ToString().IndexOf("[");
                if (bracketIndex != -1)
                {
                    int closeIndex = s.ToString().LastIndexOf(">", bracketIndex, bracketIndex);
                    s = s.Replace(">", " id=\"selected\">", closeIndex, 1);
                }
                // Return the string
                return s.ToString();
            }
        }
        /// <summary>
        /// Builds the help link and replaces in the response where necessary
        /// </summary>
        /// <returns>
        /// Help link
        /// </returns>
        private string BuildHelpLink()
        {
            try
            {
                string roboEngine;
                string roboProject;
                string roboWindow;
                // Get help parameters from the web service (if the parameters are cached, the
                // web service will retrieve them from the cache.
                Bandl.Library.VaultLedger.Gateway.Bandl.BandlGateway bandlProxy = new Bandl.Library.VaultLedger.Gateway.Bandl.BandlGateway();
                bandlProxy.OnlineHelpParameters(out roboEngine, out roboProject, out roboWindow);
                // Formulate help string anchor
                StringBuilder newValue = new StringBuilder("<a href='javascript:RH_ShowHelp(");
                newValue.Append("0,");  // first parameter
                newValue.AppendFormat("\"{0}?project={1}>{2}\",", roboEngine, roboProject, roboWindow); // 2nd parameter
                newValue.AppendFormat("HH_HELP_CONTEXT,{0})'>Help</a>", helpId); // 3rd and 4th parameters
                // Replace in the given string
                return newValue.ToString();
            }
            catch
            {
                return "<a href=\"#\">Help</a>";
            }
        }

        #endregion

        #region Utility Methods
        /// <summary>
        /// Retruns true if security permission granted, otherwise false
        /// </summary>
        /// <param name="permitThese">
        /// Roles permitted to access the page
        /// </param>
        /// <param name="redirectPage">
        /// Page to which the user should be redirected if not allowed to
        /// access the page in question.  Redirect page will be prepended
        /// with the virtual root.
        /// </param>
        protected bool DoSecurity(Role[] permitThese, string redirectPage) 
        {
            // If we're an administrator or we don't have any roles, return true
            if (CustomPermission.CurrentOperatorRole() == Role.Administrator)
                return true;
            else if (permitThese == null && permitThese.Length == 0)
                return true;
            // If we find the role, return true
            for (int i = 0; i < permitThese.Length; i++)
                if (CustomPermission.CurrentOperatorRole() == permitThese[i])
                    return true;
            // Otherwise, if we have a redirect page, redirect there
            if (redirectPage != null && redirectPage.Length != 0)
            {
                // Adding a querystring forces new page rather than from cache
                if (redirectPage.EndsWith("default.aspx"))
                {
                    Session["ErrorMessage"] = "You do not have security permission to access that page at this time.";
                    Server.Transfer(String.Format("{0}/default.aspx?parm1={1}", HttpRuntime.AppDomainAppVirtualPath, Guid.NewGuid().ToString("N")));
                }
                else
                {
                    Server.Transfer(String.Format("{0}/{1}", HttpRuntime.AppDomainAppVirtualPath, redirectPage));
                }
            }
            // Return false
            return false;

        }
        /// <summary>
        /// Retrurns true if security permission granted, otherwise false
        /// </summary>
        /// <param name="permitThis">
        /// Role permitted to access the page
        /// </param>
        /// <param name="redirectPage">
        /// Page to which the user should be redirected if not allowed to
        /// access the page in question.  Redirect page will be prepended
        /// with the virtual root.
        /// </param>
        protected bool DoSecurity(Role permitThis, string redirectPage) 
        {
            return DoSecurity(new Role[] {permitThis}, redirectPage);
        }
        /// <summary>
        /// Retrurns true if security permission granted, otherwise false
        /// </summary>
        /// <param name="permitThese">
        /// Role permitted to access the page
        /// </param>
        protected bool DoSecurity(Role[] permitThese) 
        {
            return DoSecurity(permitThese, HttpRuntime.AppDomainAppVirtualPath + "/default.aspx");
        }
        /// <summary>
        /// Retrurns true if security permission granted, otherwise false
        /// </summary>
        /// <param name="permitThis">
        /// Role permitted to access the page
        /// </param>
        protected bool DoSecurity(Role permitThis) 
        {
            return DoSecurity(new Role[] {permitThis}, HttpRuntime.AppDomainAppVirtualPath + "/default.aspx");
        }
        /// <summary>
        /// Grants focus to a given control on the page
        /// </summary>
        /// <param name="c">
        /// Control to which to grant focus
        /// </param>
        protected void DoFocus(Control c)  
        {
            if (!ClientScript.IsStartupScriptRegistered("DoFocus"))
            {
                ClientScript.RegisterStartupScript(GetType(), "DoFocus", String.Format("<script language='javascript'>var e = getObjectById('{0}'); if (e && !e.disabled) e.focus();</script>", c.ID));
            }
        }
        /// <summary>
        /// Sets the default button for the page
        /// </summary>
        /// <param name="buttonName">
        /// Name of the button to set as the default
        /// </param>
//        protected void SetDefaultButton(string buttonName)
//        {
//            this.RegisterHiddenField("__EVENTTARGET", buttonName);
//        }
        /// <summary>
        /// Redirects an enter keypress for a given control to a given 
        /// button.  This should be the last attribute assigned to a control.
        /// </summary>
        /// <param name="control">
        /// Html control from which to redirect enter key
        /// </param>
        /// <param name="buttonName">
        /// Name of the button to set as the default
        /// </param>
        protected void SetDefaultButton(HtmlControl control, string buttonName)
        {
            this.SetControlAttr(control, "onkeydown", String.Format("return enterClick(getObjectById('{0}'), event);", buttonName));
        }
        /// <summary>
        /// Redirects an enter keypress for a given control to a given 
        /// button.  This should be the last attribute assigned to a control.
        /// </summary>
        /// <param name="control">
        /// Web control from which to redirect enter key
        /// </param>
        /// <param name="buttonName">
        /// Name of the button to set as the default
        /// </param>
        protected void SetDefaultButton(WebControl control, string buttonName)
        {
            this.SetControlAttr(control, "onkeydown", String.Format("enterClick(getObjectById('{0}'), event);", buttonName));
        }
        /// <summary>
        /// Performs redirect, catches exception
        /// </summary>
        /// <param name="url">
        /// Url to which to redirect
        /// </param>
        protected void DoNavigate(String url)
        {
            try
            {
                Response.Redirect(url, true);
            }
            catch (ThreadAbortException)
            {
                ;
            }
        }
        /// <summary>
        /// Grants focus to a given control on the page
        /// </summary>
        /// <param name="c">
        /// Control to which to grant focus
        /// </param>
        protected void SelectText(Control c)  
        {
            if (c is TextBox || c is HtmlInputText)
                ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString("N"), String.Format("<script language='javascript'>getObjectById('{0}').select()</script>", c.ID));
        }
        /// <summary>
        /// Embeds the beep sound tag on the page
        /// </summary>
        /// <param name="autoStart">
        /// Whether or not to autostart the beep
        /// </param>
        protected void RegisterBeep(bool autoStart)
        {
            if (!ClientScript.IsStartupScriptRegistered("BEEP"))
            {
                ClientScript.RegisterStartupScript(GetType(), "BEEP", String.Format("<embed src=\"{0}/sounds/msgBox.wav\" name=\"beep\" hidden=\"true\" autostart=\"{0}\">", HttpRuntime.AppDomainAppVirtualPath, autoStart ? "true" : "false"));
            }
        }
        /// <summary>
        /// Shows a message box of the given name
        /// </summary>
        /// <param name="boxName">
        /// Name of the message box to show
        /// </param>
        /// <param name="playBeep">
        /// Plays a beep upon showing message box when true
        /// </param>
        /// <param name="scriptName">
        /// Name to assign to the startup script
        /// </param>
        protected void ShowMessageBox(string scriptName, string boxName)  
        {
            if (!ClientScript.IsStartupScriptRegistered(scriptName))
            {
                // Show message box
                ClientScript.RegisterStartupScript(GetType(), scriptName, String.Format("<script language=javascript>showMsgBox('{0}')</script>", boxName));
                // Register beep
                RegisterBeep(true);
            }
        }
        /// <summary>
        /// Shows a message box of the given name
        /// </summary>
        /// <param name="boxName">
        /// Name of the message box to show
        /// </param>
        protected void ShowMessageBox(string boxName)  
        {
            ShowMessageBox(boxName, boxName);
        }
        /// <summary>
        /// Collects all the checked items from a datagrid into a datagriditem array
        /// </summary>
        /// <param name="dataGrid">
        /// Datagrid from which to collect the items.  The checkbox defaults to
        /// the first cell (index 0), second control (index 1).
        /// </param>
        /// <param name="cellNo">
        /// Index of the cell in which the checkbox sits
        /// </param>
        /// <param name="controlNo">
        /// Index of the checkbox control within the cell
        /// </param>
        /// <returns>
        /// Array of checked datagriditems.  If none are checked, returns null.
        /// </returns>
        protected DataGridItem[] CollectCheckedItems(DataGrid dataGrid, int cellNo, int controlNo)
        {
            ArrayList checkedItems = new ArrayList();
            foreach(DataGridItem dataItem in dataGrid.Items)
            {
                if (((HtmlInputCheckBox)dataItem.Cells[cellNo].Controls[controlNo]).Checked)
                {
                    checkedItems.Add(dataItem);
                }
            }
            // If no items, then return null.  Otherwise, transform the array 
            // list to an array and return it.
            return (DataGridItem[])checkedItems.ToArray(typeof(DataGridItem));
        }
        /// <summary>
        /// Collects all the checked items from a datagrid into a datagriditem array
        /// </summary>
        /// <param name="dataGrid">
        /// Datagrid from which to collect the items.  The checkbox defaults to
        /// the first cell (index 0), second control (index 1).
        /// </param>
        /// <returns>
        /// Array of checked datagriditems.  If none are checked, returns null.
        /// </returns>
        protected DataGridItem[] CollectCheckedItems(DataGrid dataGrid)
        {
            return this.CollectCheckedItems(dataGrid, 0, 1);
        }
        /// <summary>
        /// Clears all the checkboxes in a datagrid, where the checkbox appears
        /// as the specified control within the specified cell.
        /// </summary>
        /// <param name="dataGrid">
        /// Datagrid containing checkboxes to clear
        /// </param>
        /// <param name="cellNo">
        /// Number of cell that contains checkbox control
        /// </param>
        /// <param name="controlNo">
        /// Index of the control within the given cell
        /// </param>
        protected void ClearCheckedItems(DataGrid dataGrid, int cellNo, int controlNo)
        {
            foreach(DataGridItem dataItem in dataGrid.Items)
            {
                ((HtmlInputCheckBox)dataItem.Cells[cellNo].Controls[controlNo]).Checked = false;
            }
        }
        /// <summary>
        /// Clears all the checkboxes in a datagrid, where the checkbox appears
        /// in the first cell (index=0), second control (index=1).
        /// </summary>
        /// <param name="dataGrid">
        /// Datagrid containing checkboxes to clear
        /// </param>
        protected void ClearCheckedItems(DataGrid dataGrid)
        {
            this.ClearCheckedItems(dataGrid, 0, 1);
        }
        /// <summary>
        /// Adds an attribute to a web control
        /// </summary>
        /// <param name="control">
        /// Control to which to add attribute
        /// </param>
        /// <param name="key">
        /// Attribute key
        /// </param>
        /// <param name="val">
        /// Attribute value
        /// </param>
        private void SetControlAttr(WebControl control, string key, string val)
        {
            this.SetControlAttr((Control)control, key, val);
        }
        /// <summary>
        /// Adds an attribute to an html control
        /// </summary>
        /// <param name="control">
        /// Control to which to add attribute
        /// </param>
        /// <param name="key">
        /// Attribute key
        /// </param>
        /// <param name="val">
        /// Attribute value
        /// </param>
        private void SetControlAttr(HtmlControl control, string key, string val)
        {
            this.SetControlAttr((Control)control, key, val);
        }
        /// <summary>
        /// Adds an attribute to a control.  This is a private method to ensure
        /// that only web controls and html controls can add attributes
        /// </summary>
        /// <param name="control">
        /// Control to which to add attribute
        /// </param>
        /// <param name="key">
        /// Attribute key
        /// </param>
        /// <param name="val">
        /// Attribute value
        /// </param>
        protected void SetControlAttr(Control control, string key, string val)
        {
            this.SetControlAttr(control, key, val, true);
        }
        /// <summary>
        /// Adds an attribute to a control.  This is a private method to ensure
        /// that only web controls and html controls can add attributes
        /// </summary>
        /// <param name="control">
        /// Control to which to add attribute
        /// </param>
        /// <param name="key">
        /// Attribute key
        /// </param>
        /// <param name="val">
        /// Attribute value
        /// </param>
        /// <param name="append">
        /// Append new value to the current attribute value if true, replace if false
        /// </param>
        protected void SetControlAttr(Control control, string key, string val, bool append)
        {
            string nextValue = null;
            string originalValue = null;
            // Get the current control value
            if (control is WebControl)
            {
                if (((WebControl)control).Attributes[key] != null)
                {
                    originalValue = ((WebControl)control).Attributes[key].Trim();
                }
            }
            else if (control is HtmlControl)
            {
                if (((HtmlControl)control).Attributes[key] != null)
                {
                    originalValue = ((HtmlControl)control).Attributes[key].Trim();
                }
            }
            else
            {
                return;
            }
            // If we're not appending, just replace the value with the supplied.  Otherwise
            // append to any value that may currently exist.
            if (append == false)
            {
                nextValue = val;
            }
            else
            {
                // If the string already exists in the attribute, no need to add it again; just return.
                // If the current value exists and does not end with '}' or ';', then add a semicolon
                // before appending the new value.  Otherwise, just append the value.
                if (originalValue != null && originalValue.IndexOf(val) != -1)
                {
                    return;
                }
                else if (originalValue != null && !originalValue.EndsWith("}") && !originalValue.EndsWith(";"))
                {
                    nextValue = String.Format("{0}; {1}", originalValue, val);
                }
                else if (originalValue != null && originalValue.Length != 0)
                {
                    nextValue = String.Format("{0} {1}", originalValue, val);
                }
                else
                {
                    nextValue = val;
                }
            }
            // Assign to the control.  If it existed before, reassign it; otherwise
            // add it to the attribute collection.
            if (control is WebControl)
            {
                if (originalValue != null)
                {
                    ((WebControl)control).Attributes[key] = nextValue;
                }
                else
                {
                    ((WebControl)control).Attributes.Add(key, nextValue);
                }
            }
            else if (control is HtmlControl)
            {
                if (originalValue != null)
                {
                    ((HtmlControl)control).Attributes[key] = nextValue;
                }
                else
                {
                    ((HtmlControl)control).Attributes.Add(key, nextValue);
                }
            }
        }
        /// <summary>
        /// Applies standard bar code format editing to an array of controls
        /// </summary>
        /// <param name="editControls">
        /// Controls to which to apply bar code editing
        /// </param>
        protected void BarCodeFormat(Control editControl)
        {
            this.BarCodeFormat(new Control[] {editControl});
        }
        /// <summary>
        /// Applies standard bar code format editing to an array of controls
        /// </summary>
        /// <param name="editControls">
        /// Controls to which to apply bar code editing
        /// </param>
        protected void BarCodeFormat(Control[] editControls)
        {
            this.BarCodeFormat(editControls, null);
        }
        /// <summary>
        /// Applies standard bar code format editing to an array of controls
        /// </summary>
        /// <param name="editControls">
        /// Controls to which to apply bar code editing
        /// </param>
        /// <param name="defaultButton">
        /// A reference to the default button on the page.  When using the online
        /// scanner, the default button will postback but the server code will not
        /// know about any text changes to the field that may have been performed
        /// just prior to submission.  As a result, we have to add code to the onclick
        /// event of the button that will edit the text for all appropriate text controls
        /// since we cannot be sure which control will have caused the submission.
        /// </param>
        protected void BarCodeFormat(Control editControl, Control defaultButton)
        {
            this.BarCodeFormat(new Control[] {editControl}, defaultButton);
        }
        /// <summary>
        /// Applies standard bar code format editing to an array of controls
        /// </summary>
        /// <param name="editControls">
        /// Controls to which to apply bar code editing
        /// </param>
        /// <param name="defaultButton">
        /// A reference to the default button on the page.  When using the online
        /// scanner, the default button will postback but the server code will not
        /// know about any text changes to the field that may have been performed
        /// just prior to submission.  As a result, we have to add code to the onclick
        /// event of the button that will edit the text for all appropriate text controls
        /// since we cannot be sure which control will have caused the submission.
        /// </param>
        protected void BarCodeFormat(Control[] editControls, Control defaultButton)
        {
            this.BarCodeFormat(editControls, defaultButton, false);
        }
        /// <summary>
        /// Applies standard bar code format editing to an array of controls
        /// </summary>
        /// <param name="editControls">
        /// Controls to which to apply bar code editing
        /// </param>
        /// <param name="defaultButton">
        /// A reference to the default button on the page.  When using the online
        /// scanner, the default button will postback but the server code will not
        /// know about any text changes to the field that may have been performed
        /// just prior to submission.  As a result, we have to add code to the onclick
        /// event of the button that will edit the text for all appropriate text controls
        /// since we cannot be sure which control will have caused the submission.
        /// </param>
        /// <param name="raiseClick">
        /// Whether or not we should raise a click event on the default button
        /// when the enter key is pressed on the given control.
        /// </param>
        protected void BarCodeFormat(Control editControl, Control defaultButton, bool raiseClick)
        {
            this.BarCodeFormat(new Control[] {editControl}, defaultButton, raiseClick);
        }
        /// <summary>
        /// Applies standard bar code format editing to an array of controls
        /// </summary>
        /// <param name="editControls">
        /// Controls to which to apply bar code editing
        /// </param>
        /// <param name="defaultButton">
        /// A reference to the default button on the page.  When using the online
        /// scanner, the default button will postback but the server code will not
        /// know about any text changes to the field that may have been performed
        /// just prior to submission.  As a result, we have to add code to the onclick
        /// event of the button that will edit the text for all appropriate text controls
        /// since we cannot be sure which control will have caused the submission.
        /// </param>
        /// <param name="raiseClick">
        /// Whether or not we should raise a click event on the default button
        /// when the enter key is pressed on the given control.
        /// </param>
        protected void BarCodeFormat(Control[] editControls, Control defaultButton, bool raiseClick)
        {
            string raiseEvent = String.Empty;
            StringBuilder buttonClick = new StringBuilder();
            SerialEditFormatTypes editType = SerialEditFormatTypes.None;
            bool buttonOkay = (defaultButton != null && (defaultButton is Button || defaultButton is HtmlInputButton));
            // Get the edit type
            try
            {
                editType = Preference.GetSerialEditFormat();
                if (buttonOkay == true && raiseClick == true)
                {
                    raiseEvent = String.Format("if (keyCode() == 13) { getObjectById('{0}').click() } ", defaultButton.ClientID);
                }
            }
            catch
            {
                editType = SerialEditFormatTypes.None;
            }
            // Add attributes to perform editing
            foreach (Control o in editControls)
            {
                switch (editType)
                {
                    case SerialEditFormatTypes.RecallStandard:
                        this.SetControlAttr(o, "onblur", "var x1 = recallSerial(this.value, true); if (this.value != x1) this.value = x1;");
                        this.SetControlAttr(o, "onkeyup", "var x1 = recallSerial(this.value, false); if (this.value != x1) this.value = x1;");
                        buttonClick.AppendFormat("getObjectById('{0}').value = recallSerial(getObjectById('{0}').value, true);", o.ClientID);
                        break;
                    case SerialEditFormatTypes.UpperOnly:
                        this.SetControlAttr(o, "onkeyup", "upperOnly(this);");
                        break;
                    default:
                        break;
                }
                // If we should raise the click event for the default button, attach to keyup event
                if (raiseEvent.Length != 0)
                {
                    this.SetControlAttr(o, "onkeyup", raiseEvent);
                }
            }
            // Set the click attribute on the button
            if (buttonOkay == true && buttonClick.Length != 0)
            {
                HtmlControl h1 = (defaultButton is HtmlControl) ? (HtmlControl)defaultButton : null;
                WebControl w1 = (defaultButton is WebControl) ? (WebControl)defaultButton : null;
                String p1 = w1 != null ? w1.Attributes["onclick"] : h1.Attributes["onclick"];
                this.SetControlAttr(defaultButton, "onclick", buttonClick.ToString() + (p1 != null ? p1 : String.Empty), false);
            }
        }
        /// <summary>
        /// Scrolls a page to a given anchor upon loading
        /// </summary>
        /// <param name="anchorName">
        /// Name of anchor to which to scroll
        /// </param>
        protected void ScrollOnLoad(string anchorName)
        {
            if (!ClientScript.IsStartupScriptRegistered("ScrollOnLoad"))
            {
                string javaScript = String.Format("<script>location.replace(\"#{0}\")</script>", anchorName);
                ClientScript.RegisterStartupScript(GetType(), "ScrollOnLoad", javaScript);
            }
        }
        /// <summary>
        /// Takes a string and inserts spaces before each capital letter
        /// </summary>
        /// <param name="enumObject">
        /// Enumeration to transfer into string and inject spaces
        /// </param>
        /// <returns>
        /// String with injected spaces
        /// </returns>
        protected string SpacesBeforeCaps(Enum enumObject)
        {
            return this.SpacesBeforeCaps(enumObject.ToString());
        }
        /// <summary>
        /// Takes a string and inserts spaces before each capital letter
        /// </summary>
        /// <param name="textString">
        /// String into which to inject spaces
        /// </param>
        /// <returns>
        /// String with injected spaces
        /// </returns>
        protected string SpacesBeforeCaps(string textString)
        {
            if (textString.Length == 0)
            {
                return textString;
            }
            else
            {
                StringBuilder builder = new StringBuilder();
                // Insert the first character
                builder.Append(textString[0]);
                // Insert spaces before each subsequent uppercase character
                for (int i = 1; i < textString.Length; i++)
                {
                    if (Char.IsUpper(textString, i))
                    {
                        builder.AppendFormat(" {0}", textString[i]);
                    }
                    else
                    {
                        builder.Append(textString[i]);
                    }
                }
                // Return the string
                return builder.ToString();
            }
        }

        /// <summary>
        /// Verifies the validity of a date
        /// </summary>
        /// <param name="dateString">
        /// String supposed to be a date.  If the function returns true,
        /// the string is returned is yyyy/MM/dd format.
        /// </param>
        /// <param name="allowEmpty">
        /// Allows an empty string to pass and return true
        /// </param>
        /// <returns>
        /// True if the string is a valid date.
        /// </returns>
        protected bool CheckDate(ref string dateString, bool allowEmpty)
        {
            string tempString = String.Empty;
            // Make sure that we have a string of some length
            if (dateString == null)
            {
                return false;
            }
            else if (dateString.Length == 0)
            {
                return allowEmpty;
            }
            // Check the date
            try
            {
                dateString = Date.ParseExact(dateString).ToString("yyyy-MM-dd");
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Verifies the validity of a date
        /// </summary>
        /// <param name="dateString">
        /// String supposed to be a date
        /// </param>
        /// <param name="allowEmpty">
        /// Allows an empty string to pass and return true
        /// </param>
        /// <returns>
        /// True if the string is a valid date
        /// </returns>
        protected bool CheckDate(string dateString, bool allowEmpty)
        {
            string tempString = String.Empty;
            // Make sure that we have a string of some length
            if (dateString == null)
            {
                return false;
            }
            else if (dateString.Length == 0)
            {
                return allowEmpty;
            }
            // Check the date
            try
            {
                dateString = Date.ParseExact(dateString).ToString("yyyy-MM-dd");
                return true;
            }
            catch
            {
                return false;
            }
        }
        /// <summary>
        /// Takes a string to word wrap and a maximum line length and returns the
        /// string wrapped appropriately.
        /// </summary>
        /// <param name="wrapThis">Line to wrap</param>
        /// <param name="maxLine">Maximum characters per line</param>
        /// <returns>String with breaks (br tags)</returns>
        protected string WordWrap(string wrapThis, int maxLine)
        {
            StringBuilder returnString;
            ArrayList wrappedText;
            string nextLine;
            char nextChar;
            int totalLength;
            int pointer;
            string breakChars = " \n";
            // Initialize
            wrappedText = new ArrayList();
            totalLength = 0;
            pointer = 0;
            // Replace all tabs with spaces and eliminate all carriage returns
            wrapThis = wrapThis.Replace('\t', ' ').Replace("\r", String.Empty);
            // Compress all consecutive spaces
            while (wrapThis.IndexOf("  ") != -1)
            {
                wrapThis = wrapThis.Replace("  ", " ");
            }
            // Loop through the string
            while (totalLength < wrapThis.Length)
            {
                nextChar = '\0';
                // Get the maximum line
                nextLine = wrapThis.Substring(totalLength);
                if (nextLine.Length > maxLine)
                {
                    nextChar = nextLine[maxLine];
                    nextLine = nextLine.Substring(0, maxLine);
                }
                // If the line contains a newline, cut it there.  Otherwise, if the next char
                // is not a space and the line contains a space, cut the line at the
                // last space.
                if ((pointer = nextLine.IndexOf('\n')) != -1)
                {
                    nextLine = nextLine.Substring(0, pointer);
                }
                else if (breakChars.IndexOf(nextChar) != -1 && (pointer = nextLine.LastIndexOf(' ')) != -1)
                {
                    nextLine = nextLine.Substring(0, pointer);
                }
                // Add the line to the array list of lines
                wrappedText.Add(nextLine);
                // Add to the total length
                totalLength += nextLine.Length;
                // If the next character is a space, eliminate it from the string
                if (wrapThis.Length > totalLength && breakChars.IndexOf(wrapThis[totalLength]) != -1)
                {
                    wrapThis = wrapThis.Substring(0, totalLength) + wrapThis.Substring(totalLength+1);
                }
            }
            // Create a new string builder
            returnString = new StringBuilder(totalLength + wrappedText.Count * 5);
            // Insert breaks after every line
            for (int i = 0; i < wrappedText.Count; i++)
            {
                returnString.AppendFormat("{0}{1}", i != 0 ? "<br />" : "", ((string)wrappedText[i]).Trim());
            }
            // Return the string
            return returnString.ToString();
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(object date)
        {
            return DisplayDate(date, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(object date, bool local)
        {
            return DisplayDate(date, local, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(object date, bool local, bool time)
        {
            return DisplayDate(date, local, time, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(object date, bool local, bool time, bool seconds)
        {
            try
            {
                if (date is DateTime)
                {
                    return DisplayDate((DateTime)date, local, time, seconds);
                }
            }
            catch
            {
                ;
            }
            // Use the string override
            return DisplayDate(Convert.ToString(date), local, time, seconds);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(string date)
        {
            return DisplayDate(date, true, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(string date, bool local)
        {
            return DisplayDate(date, local, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(string date, bool local, bool time)
        {
            return DisplayDate(date, local, time, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(string date, bool local, bool time, bool seconds)
        {
            if (date.Length == 0)
            {
                return String.Empty;
            }
            else
            {
                DateTime d = Date.ParseExact(date);
                // Return depending on 'local' parameter
                return Date.Display(local ? Time.UtcToLocal(d) : d, time, seconds);
            }
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(DateTime date)
        {
            return DisplayDate(date, true, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(DateTime date, bool local)
        {
            return DisplayDate(date, local, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(DateTime date, bool local, bool time)
        {
            return DisplayDate(date, local, time, true);
        }
        /// <summary>
        /// Formats a date for display
        /// </summary>
        /// <param name="date">Date to format</param>
        /// <returns>String representing date to display</returns>
        public string DisplayDate(DateTime date, bool local, bool time, bool seconds)
        {
            if (local == false)
            {
                return Date.Display(date, time);
            }
            else
            {
                return Date.Display(Time.UtcToLocal(date), time, seconds);
            }
        }
        /// <summary>
        /// Gets the string version of a list otr list item status
        /// </summary>
        /// <param name="o">List or list item enumeration</param>
        /// <param name="upper">True if we want uppercase, else false</param>
        /// <returns>String representation of status</returns>
        public string StatusString(object o, bool upper)
        {
            if (o is SLStatus)
                return upper ? ListStatus.ToUpper((SLStatus)o) : ListStatus.ToLower((SLStatus)o);
            else if (o is SLIStatus)
                return upper ? ListStatus.ToUpper((SLIStatus)o) : ListStatus.ToLower((SLIStatus)o);
            else if (o is RLStatus)
                return upper ? ListStatus.ToUpper((RLStatus)o) : ListStatus.ToLower((RLStatus)o);
            else if (o is RLIStatus)
                return upper ? ListStatus.ToUpper((RLIStatus)o) : ListStatus.ToLower((RLIStatus)o);
            else if (o is DLStatus)
                return upper ? ListStatus.ToUpper((DLStatus)o) : ListStatus.ToLower((DLStatus)o);
            else if (o is DLIStatus)
                return upper ? ListStatus.ToUpper((DLIStatus)o) : ListStatus.ToLower((DLIStatus)o);
            else
                return String.Empty;
        }
        /// <summary>
        /// Gets the string version of a list or list item status
        /// </summary>
        /// <param name="o">List or list item enumeration</param>
        /// <returns>String representation of status (uppercase)</returns>
        public string StatusString(object o)
        {
            return StatusString(o, true);
        }
        /// <summary>
        /// Transforms null strings to the empty string; convenience function
        /// </summary>
        /// <param name="s">String to test</param>
        /// <returns>Empty string if s is null, otherwise s</returns>
        public string NullIsEmpty(string s)
        {
            return s != null ? s : String.Empty;
        }
        /// <summary>
        /// Creates a file for exporting
        /// </summary>
        /// <param name="sessionid">Id of http session</param>
        /// <param name="fileName">Name of file</param>
        /// <param name="data">Data to export</param>
        /// <returns>Full path of file created</returns>
        public void DoExport(string fileName, string data)
        {
            Response.Clear();
            Response.ContentType = "text/plain";
            Response.ContentEncoding = System.Text.Encoding.GetEncoding("UTF-8");
            Response.AppendHeader("Content-Disposition", "attachment;filename=" + fileName);
            Response.AppendHeader("Content-Length", data.Length.ToString()); // x1.Length.ToString());
            Response.Write(data);
            Response.Flush();
            Response.SuppressContent = true;
            HttpContext.Current.ApplicationInstance.CompleteRequest();

        }
        #endregion

        #region Error Display Methods
        /// <summary>
        /// Displays an error message, in a label within the given placeholder.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error message
        /// </param>
        /// <param name="eMessage">
        /// An error message ro display
        /// </param>
        protected bool DisplayErrors(PlaceHolder placeHolder, string eMessage)
        {
            return this.DisplayErrors(placeHolder, new string[1] {eMessage});
        }
        /// <summary>
        /// Displays an error message, in a label within the given placeholder.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error message
        /// </param>
        /// <param name="eMessage">
        /// An error message ro display
        /// </param>
        /// <param name="caption">
        /// Caption to display before displaying the error messages
        /// </param>
        protected bool DisplayErrors(PlaceHolder placeHolder, string eMessage, string caption)
        {
            return this.DisplayErrors(placeHolder, new string[1] {eMessage}, caption);
        }
        /// <summary>
        /// Displays an array of error messages, one on each line, in the given
        /// placeholder.  A table is created in the placeholder and one error
        /// message is placed on each line.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error messages
        /// </param>
        /// <param name="collectionBase">
        /// A collection of objects from which to glean row errors.  Must be a
        /// descendant of BaseCollection in order to ensure thaty RowError
        /// property exists in constituent objects. 
        /// </param>
        protected bool DisplayErrors(PlaceHolder placeHolder, CollectionBase collectionBase)
        {
            if (collectionBase is BaseCollection)
            {
                ArrayList eMessages = new ArrayList();
                // Place error messages in the arraylist
                foreach(Details detailObject in collectionBase)
                {
                    if (detailObject.RowError.Length != 0)
                    {
                        eMessages.Add(detailObject.RowError);
                    }
                }
                // Call the overload
                return this.DisplayErrors(placeHolder, (string[])eMessages.ToArray(typeof(string)));
            }
            else
            {
                return this.DisplayErrors(placeHolder, "Collection error display called on invalid collection");
            }
        }
        /// <summary>
        /// Displays an array of error messages, one on each line, in the given
        /// placeholder.  A table is created in the placeholder and one error
        /// message is placed on each line.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error messages
        /// </param>
        /// <param name="eMessages">
        /// A collection of error strings
        /// </param>
        protected bool DisplayErrors(PlaceHolder placeHolder, StringCollection eMessages)
        {
            if (eMessages.Count != 0)
            {
                return this.DisplayErrors(placeHolder, (string[])new ArrayList(eMessages).ToArray(typeof(string)));
            }
            else
            {
                return this.DisplayErrors(placeHolder, "Collection error display called on invalid collection");
            }
        }
        /// <summary>
        /// Displays an array of error messages, one on each line, in the given
        /// placeholder.  A table is created in the placeholder and one error
        /// message is placed on each line.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error messages
        /// </param>
        /// <param name="eMessages">
        /// An array of error messages ro display
        /// </param>
        protected bool DisplayErrors(PlaceHolder placeHolder, string[] eMessages)
        {
            // If there are no error messages in the array, create one
            if (eMessages.Length != 0)
            {
                return this.DisplayErrors(placeHolder, eMessages, "The following error(s) have occurred:");
            }
            else
            {
                string[] s = new string[1] {"Collection error display called on empty array"};
                return this.DisplayErrors(placeHolder, s, "The following error(s) have occurred:");
            }
        }
        /// <summary>
        /// Displays an array of error messages, one on each line, in the given
        /// placeholder.  A table is created in the placeholder and one error
        /// message is placed on each line.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error messages
        /// </param>
        /// <param name="eMessages">
        /// An array of error messages ro display
        /// </param>
        /// <param name="caption">
        /// Caption to display before displaying the error messages
        /// </param>
        /// <returns>
        /// Always returns false
        /// </returns>
        protected bool DisplayErrors(PlaceHolder placeHolder, string[] eMessages, string caption)
        {
            Table tblError = null;
            // If there is already a table in the placeholder, then get
            // a reference to it.  Otherwise, create a new table.
            if (placeHolder.Controls.Count != 0 && placeHolder.Controls[0] is Table)
            {
                tblError = (Table)placeHolder.Controls[0];
            }
            else
            {
                tblError = new Table();
                // Set the backcolor
                switch (Configurator.ProductType)
                {
                    case "RECALL":
                        tblError.BackColor = Color.FromArgb(226,226,226);
                        break;
                    default:
                        tblError.BackColor = Color.LightGray;
                        break;
                }
            }
            // Add the row announcing that errors have occurred
            TableRow newRow = new TableRow();
            TableCell newCell = new TableCell();
            Label errorText = new Label();
            errorText.ForeColor = Color.Red;
            errorText.Text = caption;
            newCell.Controls.Add(errorText);
            newRow.Cells.Add(newCell);
            tblError.Rows.Add(newRow);
            // Add the error messages to the table
            for (int i = 0; i < eMessages.Length; i++)
            {
                // Flag for new message
                bool newMessage = true;
                // Run through the messages before this one, making sure
                // that it does not simply reiterate an earlier message.
                for (int j = 0; j < i; j++)
                {
                    if (eMessages[i] == eMessages[j])
                    {
                        newMessage = false;
                        break;
                    }
                }
                // If we have a new message, create a cell for it.
                if (newMessage == true)
                {
                    newRow = new TableRow();
                    newCell = new TableCell();
                    errorText = new Label();
                    errorText.ForeColor = Color.Red;
                    errorText.Text = "* " + eMessages[i];
                    newCell.Controls.Add(errorText);
                    newRow.Cells.Add(newCell);
                    tblError.Rows.Add(newRow);
                }
            }
            // Add the table to the placeholder
            placeHolder.Controls.Add(tblError);
            // Return false
            return false;
        }

        #endregion

    }
}

