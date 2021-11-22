using System;
using System.Web;
using System.Web.Security;
using System.Web.SessionState;
using System.Security.Principal;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using System.Threading;

namespace Bandl.VaultLedger.Web.UI 
{
	/// <summary>
	/// Summary description for Global.
	/// </summary>
	public class Global : System.Web.HttpApplication
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		public Global()
		{
			InitializeComponent();
		}	

        /// <summary>
        /// Gets the virtual root, strips end slash if necessary
        /// </summary>
        public static String UrlRoot
        {
            get
            {
                String p1 = HttpRuntime.AppDomainAppVirtualPath;
                return p1.EndsWith("/") == false ? p1 : (p1.Length != 1 ? p1.Substring(0, p1.Length - 1) : String.Empty);
            }
        }

        /// <summary>
        /// Redirects and catches any annoying ThreadAbortException that may arise as a result of cutting the request short.
        /// </summary>
        /// <param name="url">Url to which we should redirect</param>
        private void DoNavigate(string url)
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
        /// Name of the cookie that we are using to impersonate the forms authentication cookie
        /// </summary>
        public static String AuthenticationCookie
        {
            get { return String.Format("{0}_Authenticate_680E473950DF48B69A33FC8C4CA8920B", Configurator.ProductName.Replace(" ", String.Empty)); }
        }
		
        public static void SetCookie(String login, String role, String date, String time)
        {
            Global.SetCookie(login, String.Format("{0}${1}${2}", role, date, time));
        }

        public static void SetCookie(String login, String data)
        {
            DateTime x1 = DateTime.Now.AddMinutes(Configurator.SessionTimeout + 1);
            FormsAuthenticationTicket t1 = new FormsAuthenticationTicket(1, login, DateTime.Now, x1, false, data);
            HttpContext.Current.Response.Cookies.Add(new HttpCookie(Global.AuthenticationCookie, FormsAuthentication.Encrypt(t1)));
        }

        /// <summary>
        /// Authenticate the request
        /// </summary>
        protected void Application_AuthenticateRequest(Object sender, EventArgs e)
        {
            String p1 = Request.FilePath;
            FormsAuthenticationTicket t1 = null;
            HttpCookie c1 = Request.Cookies[Global.AuthenticationCookie];
            // Assign a name to the thread
            if (Thread.CurrentThread.Name == null)
            {
                Thread.CurrentThread.Name = Guid.NewGuid().ToString("N");
            }
            // Do we have a cookie and executing a page or service?
            if (c1 != null && (p1.EndsWith(".aspx") || p1.EndsWith(".asmx") || p1.EndsWith(".ashx")))
            {
                // Decrypt the ticket
                try
                {
                    t1 = FormsAuthentication.Decrypt(c1.Value);
                }
                catch
                {
                    ;
                }
                // Is the ticket expired?
                if (t1 == null)
                {
                    if (!p1.EndsWith("/login.aspx"))
                    {
                        DoNavigate(UrlRoot + "/login.aspx");
                    }
                }
                else
                {
                    // Expired?
                    if (t1.Expiration < DateTime.Now)
                    {
                        if (!p1.EndsWith("/login.aspx"))
                        {
                            DoNavigate(UrlRoot + "/login.aspx?error=Timed_Out");
                        }
                    }
                    else
                    {
                        String[] u1 = t1.UserData.Split(new char[] {'$'});    // role$timezone$dateformat$timeformat
                        // Create generic identity and principal
                        CustomPrincipal p2 = new CustomPrincipal(new GenericIdentity(t1.Name), new String[] { u1[0] }); // role name
                        // Assign the principal to both the thread and the request context
                        Thread.CurrentPrincipal = p2;
                        Context.User = p2;
                        // Set cookie
                        Global.SetCookie(t1.Name, t1.UserData);
                        // Set context items
                        Context.Items[CacheKeys.Role] = u1[0];
                        Context.Items[CacheKeys.Login] = t1.Name;
                        Context.Items[CacheKeys.DateMask] = u1[1];
                        Context.Items[CacheKeys.TimeMask] = u1[2];
                    }
                }
            }
        }
        
        protected void Application_PreRequestHandlerExecute(Object sender, EventArgs e)
        {
            HttpCookie c1 = null;
            String p1 = Request.FilePath;
            // Authenticated? Are we licensed?
            if (p1.EndsWith(".aspx") == false)
            {
                ;   // only care about .aspx (and .asmx?)
            }
            else if (p1.EndsWith("/login.aspx") || p1.EndsWith("/errorPage.aspx"))
            {
                ;   // can always navigate to login page and error page
            }
            else if ((c1 = Request.Cookies[Global.AuthenticationCookie]) == null)   // for any other pages, we must be authenticated
            {
                DoNavigate(Global.UrlRoot + "/login.aspx");
            }
        }

        /// <summary>
        /// Takes care of unhandled exceptions
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        protected void Application_Error(Object sender, EventArgs e)
        {
            try
            {
                Exception e1 = Server.GetLastError().GetBaseException();
                // Thread abort?
                if (e1 is ThreadAbortException)
                {
                    Server.ClearError();   // No action necessary - generally harmless
                }
                else if (Request.FilePath.EndsWith("errorPage.aspx") == false)
                {
                    Server.Transfer("~/errorPage.aspx");
                }
            }
            catch
            {
                ;
            }
        }

        // Ensure SessionID in order to prevent the following exception when the Application Pool Recycles
        // [HttpException]: Session state has created a session id, but cannot save it because the response 
        // was already flushed by the application
        protected void Session_Start(object sender, EventArgs e)
        {
            String x1 = Session.SessionID;
        }

        /// <summary>
/// /////////////
/// </summary>
/// <param name="sender"></param>
/// <param name="e"></param>
/// 

//        protected void Application_AuthenticateRequest(Object sender, EventArgs e)
//        {
//            // Get the authentication cookie
//            string cookieName = FormsAuthentication.FormsCookieName;
//            HttpCookie authCookie = Context.Request.Cookies[cookieName];
//            // If the cookie can't be found, don't issue the ticket
//            if (authCookie == null) return;
//            // Get the authentication ticket
//            FormsAuthenticationTicket authTicket = FormsAuthentication.Decrypt(authCookie.Value);
//            // Create generic identity and principal
//            GenericIdentity i = new GenericIdentity(authTicket.Name);
//            CustomPrincipal p = new CustomPrincipal(i, new string[] {authTicket.UserData}); // role name
//            // Assign the thread a name
//            if (Thread.CurrentThread.Name == null) Thread.CurrentThread.Name = Guid.NewGuid().ToString("N");
//            // Assign the principal to both the thread and the request context
//            Thread.CurrentPrincipal = p;
//            Context.User = p;
//        }

//        protected void Application_PreRequestHandlerExecute(Object sender, EventArgs e)
//        {
//            // If the cookie expiration object is not equal to null and we are not passed the timeout period, adjust 
//            // the cookie expiration.  Otherwise, if the request is authenticated, force timeout of the session.
//            if (Session[CacheKeys.CookieExpiration] != null && (DateTime)Session[CacheKeys.CookieExpiration] > DateTime.Now)
//            {
//                Session[CacheKeys.CookieExpiration] = DateTime.Now.AddMinutes(Configurator.SessionTimeout);
//            }
//            else if (Request.IsAuthenticated)
//            {
//                // Clear all the session cache
//                Session.RemoveAll();
//                // Remove the forms authentcation ticket
//                FormsAuthentication.SignOut();
//                // Redirect to login page
//                Response.Redirect("login.aspx?error=Timed_Out", true);
//            }
//        }
        
//		protected void Application_Error(Object sender, EventArgs e)
//		{
//            try
//            {
//                // Get the exception
//                Exception ex = Server.GetLastError();
//                // Clear the error to prevent appdomain from cycling
//                Server.ClearError();
//                // Don't worry about thread abort exceptions.  They are often
//                // caused by redirects and are generally harmless.
//                if (ex is ThreadAbortException) return;
//                // Drill down until we get to the exception that contains the significant message.
//                while (ex is HttpUnhandledException && ex.InnerException != null) {ex = ex.InnerException;}
//                // Place error in session - will be removed in a moment
//                Session["UnhandledException"] = ex;
//                // Publish it to the web service
//                new Bandl.Library.VaultLedger.Gateway.Bandl.BandlGateway().PublishException(ex);
//                // Redirect to the error page
//                Server.Transfer(HttpRuntime.AppDomainAppVirtualPath + "/errorPage.aspx");
//            }
//            catch
//            {
//                ;
//            }
//        }
			
		#region Web Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{    
			this.components = new System.ComponentModel.Container();
		}
		#endregion
	}
}

