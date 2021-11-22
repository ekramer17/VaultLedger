using System;
using System.IO;
using System.Web;
using System.Text;
using System.Threading;
using System.Reflection;
using System.Collections;
using System.Web.Security;
using System.Security.Principal;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Router;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Gateway.Bandl;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for Login.
    /// </summary>
    public class Login : BasePage
    {
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtPassword;
        protected System.Web.UI.WebControls.TextBox txtLogin;
        protected System.Web.UI.WebControls.Button btnAuthenticate;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.WebControls.Label Error1;
        protected System.Web.UI.WebControls.Label Error2;
        protected System.Web.UI.WebControls.Label lblTitle;
        protected System.Web.UI.WebControls.TextBox txtServer;
        protected System.Web.UI.WebControls.TextBox txtDatabase;
        protected System.Web.UI.WebControls.TextBox txtCompany;
        protected System.Web.UI.WebControls.TextBox txtContact;
        protected System.Web.UI.WebControls.TextBox txtPhoneNo;
        protected System.Web.UI.WebControls.TextBox txtEmail;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.HtmlControls.HtmlInputHidden javaTester;
        protected System.Web.UI.WebControls.Label lblError1;
        protected System.Web.UI.WebControls.Label lblError2;
        protected System.Web.UI.WebControls.Label lblPageCaption;
        protected System.Web.UI.WebControls.Button btnRegister;
        protected System.Web.UI.HtmlControls.HtmlGenericControl normalContent;
        protected System.Web.UI.HtmlControls.HtmlGenericControl registerContent;
        protected System.Web.UI.WebControls.Label lblPageHeader;
        protected System.Web.UI.HtmlControls.HtmlGenericControl normalButtons;
        protected System.Web.UI.WebControls.Label lblError3;
        protected System.Web.UI.WebControls.Label lblError4;
        protected System.Web.UI.WebControls.Label lblError5;
        protected System.Web.UI.WebControls.Label lblError6;
        protected System.Web.UI.WebControls.Label lblEntrust;
        protected System.Web.UI.HtmlControls.HtmlGenericControl entrustContent;
        protected System.Web.UI.HtmlControls.HtmlGenericControl bottomButtons;
        protected System.Web.UI.HtmlControls.HtmlGenericControl newMedia;
        protected System.Web.UI.HtmlControls.HtmlInputHidden localTime;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;

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
            this.btnAuthenticate.Click += new System.EventHandler(this.btnAuthenticate_Click);
            this.btnRegister.Click += new System.EventHandler(this.btnRegister_Click);

        }
        #endregion
    
        #region Overloaded Methods
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 1;
        }

        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxRegister');");
            // If we have a Recall error page and we have an error, then go to Recall 
            // error page.  If we have no error query string but we have a Recall login 
            // page, then redirect there.  None of the Recall functions have any effect
            // if the appropriate tags are not in the appSettings section of web.config.
            if (Request.QueryString["error"] == "Timed_Out")
            {
                lblError1.Text = "Your session has timed out.&nbsp;&nbsp;Please sign in again.";
                // Destroy the session
                this.DestroySession();
                // Redirect to Recall error page (has no effect is no recall page specified in appSettings in web.config)
                this.RecallRedirect(true, "Timed_Out");
            }
            else if (Request.QueryString["error"] == "Session_State_Lost")
            {
                // Destroy the session
                this.DestroySession();
                // Redirect to Recall error page (has no effect is no recall page specified in appSettings in web.config)
                this.RecallRedirect(true, "Session_State_Lost");
            }
            else if (Request.QueryString["error"] != null)
            {
                // Destroy the session
                this.DestroySession();
                // Redirect to Recall error page
                this.RecallRedirect(true, "General_Error");
            }
            else if (Request.QueryString["logout"] == "true")
            {
                // Destroy the session
                this.DestroySession();
                // Redirect to the Recall logout page
                this.RecallRedirect(false);
            }
        }

        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // See if we should do the Entrust login
            if (!Page.IsPostBack && Configurator.RecallLogoutUrl.Length != 0)
            {
                this.DoEntrust();
            }
            else 
            {
                // Get the subscription if we;re not using a router
                if (Configurator.Router == false && this.ViewState["Subscription"] == null)
                {
                    try
                    {
                        this.ViewState["Subscription"] = Subscription.GetSubscription();
                    }
                    catch (Exception ex)
                    {
                        this.lblError2.Text = ex.Message;
                        this.btnAuthenticate.Visible = false;
                    }
                }
                // If there is no subscription and we are not using a router, then we need 
                // to register the product for licensing.  Display will depend on the product type.
                if (Configurator.Router || this.ViewState["Subscription"] == null || ((string)this.ViewState["Subscription"]).Length != 0)
                {
                    this.pageTitle = "Login";
                    this.DoFocus(this.txtLogin);
                    this.lblPageHeader.Text = "Login";
                    this.SetControlAttr(btnAuthenticate, "onclick", "return checkText();");
                    this.lblPageCaption.Text = "Enter usercode/password combination below to gain access to " + Configurator.ProductName + ".";
                    this.normalContent.Visible = this.normalButtons.Visible = true;
                    this.registerContent.Visible = this.btnRegister.Visible = false;
                    this.entrustContent.Visible = false;
                }
                else
                {
                    this.pageTitle = "Register";
                    this.DoFocus(this.txtCompany);
                    this.lblPageHeader.Text = "Register";
                    this.lblPageCaption.Text = "Please take this opportunity to register your instance of " + Configurator.ProductName + ".";
                    this.normalContent.Visible = this.normalButtons.Visible = false;
                    this.registerContent.Visible = this.btnRegister.Visible = true;
                    this.entrustContent.Visible = false;
                }
            }
        }
        #endregion

        #region Private Methods
        /// <summary>
        /// Redirects user to Recall error or login page
        /// </summary>
        /// <param name="isError">Whether the redirect is to the error page (true) or login page (false)</param>
        /// <param name="queryString">Any querystring to apply to end of url</param>
        /// <returns>true if redirected, else false</returns>
        private bool RecallRedirect(bool isError, string queryString)
        {
            if (Configurator.ProductType == "RECALL")
            {
                if (isError == true && Configurator.RecallErrorUrl.Length != 0)
                {
                    string url = Configurator.RecallErrorUrl;
                    if (queryString == null || queryString == String.Empty) queryString = "General_Error";
                    Response.Redirect(String.Format("{0}{1}errordesc={2}", url, url.IndexOf("?") != -1 ? "&" : "?", queryString), true);
                    return true;
                }
                else if (Configurator.RecallLogoutUrl.Length != 0)
                {
                    Response.Redirect(Configurator.RecallLogoutUrl, true);
                    return true;
                }
            }
            // No Recall redirect so return false
            return false;
        }
        /// <summary>
        /// Redirects user to Recall error or login page
        /// </summary>
        /// <param name="isError">Whether the redirect is to the error page (true) or login page (false)</param>
        /// <returns>true if redirected, else false</returns>
        private bool RecallRedirect(bool isError)
        {
            return RecallRedirect(isError, String.Empty);
        }
        /// <summary>
        /// Clears session cache and signs out of forms authentication
        /// </summary>
        private void DestroySession()
        {
            // Abandon
            Session.Abandon();
            // Remove cookie
            if (Request.Cookies[Global.AuthenticationCookie] != null)
            {
                HttpCookie c1 = new HttpCookie(Global.AuthenticationCookie);
                c1.Expires = DateTime.Now.AddYears(-30);
                Response.Cookies.Add(c1);
            }
        }
        /// <summary>
        /// Determines whether the login provided is the support access login.
        /// Support access login is the string "SUPPORT" following by the last
        /// four characters of the main account (global account in web.config).
        /// </summary>
        /// <returns>
        /// True if support login, else false
        /// </returns>
        private bool SupportLogin (string login)
        {
            byte[] b = new byte[] {83, 85, 80, 80, 79, 82, 84}; // SUPPORT

            if (!Configurator.SupportLogin || login.Length != 11)
            {
                return false;
            }
            else if (Encoding.UTF8.GetString(b) != login.Substring(0,7).ToUpper())
            {
                return false;
            }
            else
            {
                try
                {
                    string fourChars = Configurator.GlobalAccount.PadLeft(4, '0');
                    fourChars = fourChars.Substring(fourChars.Length - 3, 4);
                    return fourChars.CompareTo(login.Substring(7,4)) == 0;
                }
                catch
                {
                    return false;
                }
            }
        }

        #endregion

        #region Public Methods
        public void DoAuthenticate(string login, string password)
        {
            try
            {
                string roleName = String.Empty;
                string userName = String.Empty;
                // Create the principal object
                CreatePrincipal(login);
                // Authenticate the user
                roleName = this.AuthenticateUser(login, password, out userName);
                // Check licenses
                CheckLicenses();
                // Coming from autoloader?
                CheckAutoloader();
                // Verify that the version is okay
                CheckVersions();
                // Check the number of days left in the license
                CheckDaysLeft();
                // If the product is of the Recall ReQuest Media Manager variety,
                // perform additional initialization as necessary.
                switch (Configurator.ProductType)
                {
                    case "RECALL":
                        this.RecallInitialization();
                        break;
                    case "B&L":
                    case "BANDL":
                    case "IMATION":
                    default:
                        this.BandlInitialization();
                        break;
                }
                // Make sure that the final bar code patterns are kosher
                PatternDefaultCase.CheckFinalPattern();
                PatternDefaultMedium.CheckFinalPattern();
                // Session variable for current login
                Context.Items[CacheKeys.Login] = userName;
                // Update the current user last login
                OperatorDetails o = Operator.GetOperator(userName);
                o.LastLogin = DateTime.UtcNow;
                Operator.Update(ref o);
                // Create the cookie
                String f1 = Preference.GetPreference(PreferenceKeys.DateDisplayFormat).Value;
                String f2 = Preference.GetPreference(PreferenceKeys.TimeDisplayFormat).Value;
                Global.SetCookie(o.Login, o.Role, f1, f2);
                // Redirect to main menu, signal to clear lists and issue list alerts
                if (Request.QueryString["gotorfid"] != null)
                {
                    Response.Redirect("default.aspx?issuelistalerts=1&purgeclearedlists=1&gotorfid=1", false);
                }
                else
                {
                    Response.Redirect("default.aspx?issuelistalerts=1&purgeclearedlists=1", false);
                }
            }
            catch (ThreadAbortException)
            {
                ;   // Ignore thread abort exceptions..caused by redirects
            }
            catch (Exception ex)
            {
                lblError2.Text = ex.Message;
                RecallRedirect(true, "General_Login_Error");
            }
            finally
            {
                // Leaving the principal as is, i.e. with administrative rights, would
                // cause the administrative tools tab to show up on an unsuccessful
                // login attempt.  To avoid, this, just null the principal object.
                Thread.CurrentPrincipal = null;
                Context.User = null;
            }
        }
        /// <summary>
        /// Handle the Entrust login of Recall
        /// </summary>
        public void DoEntrust()
        {
            lblPageHeader.Text = "Login Error";
            lblPageCaption.Text = "An error occurred during automatic login.  Please see below for details.";
            // Hide the normal parts
            this.bottomButtons.Visible = false;
            this.newMedia.Visible = false;
            // Get the user id and password
            string uid = Request.ServerVariables["HTTP_SCVTMSUSER"];
            string pwd = Request.ServerVariables["HTTP_SCVTMSPASS"];
            // Make sure we have a login and password
            if (uid == null || uid.Length == 0)
            {
                RecallRedirect(true, "No_User_Id_In_Header");
            }
            else if (pwd == null || pwd.Length == 0)
            {
                RecallRedirect(true, "No_Password_In_Header");
            }
            else
            {
                DoAuthenticate(uid, pwd);
            }
        }
        #endregion

        #region Event Handler Methods
        /// <summary>
        /// Authenticate the user
        /// </summary>
        private void btnAuthenticate_Click(object sender, System.EventArgs e)
        {
            if (this.javaTester.Value != "true")
            {
                this.lblError1.Text = "Javascript not enabled";
                this.lblError2.Text = "You must enable javascript in your browser in order to use " + Configurator.ProductName;
            }
            else
            {
                this.DoAuthenticate(txtLogin.Text, txtPassword.Text);
            }
        }
        /// <summary>
        /// Registers a new instance
        /// </summary>
        private void btnRegister_Click(object sender, System.EventArgs e)
        {
            // Clear the errors
            this.lblError3.Text = String.Empty;
            this.lblError4.Text = String.Empty;
            this.lblError5.Text = String.Empty;
            this.lblError6.Text = String.Empty;
            // Company name
            if (this.txtCompany.Text.Trim().Length == 0)
                this.lblError3.Text = "Please enter the name of your company";
            // Contact, phone, and email
            if (this.txtContact.Text.Trim().Length == 0)
                this.lblError4.Text = "Please enter the name of the person responsible for " + Configurator.ProductName + " at your company";
            else
            {
                if (this.txtPhoneNo.Text.Trim().Length == 0)
                    this.lblError5.Text = "Please enter a valid phone number for " + this.txtContact.Text.Trim();
                if (this.txtEmail.Text.Trim().Length == 0 || !Regex.IsMatch(this.txtEmail.Text, @"^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$"))
                    this.lblError6.Text = "Please enter a valid email address for " + this.txtContact.Text.Trim();
            }
            // If no errors, then register
            if (this.lblError3.Text.Length == 0 && this.lblError4.Text.Length == 0 && this.lblError5.Text.Length == 0 && this.lblError6.Text.Length == 0)
            {
                try
                {
                    this.CreatePrincipal(txtLogin.Text);
                    BandlGateway bandlProxy = new BandlGateway();
                    string s = bandlProxy.RegisterClient(this.txtCompany.Text.Trim(), this.txtContact.Text.Trim(), this.txtPhoneNo.Text.Trim(), this.txtEmail.Text.Trim());
                    Subscription.Insert(s);
                    this.ViewState["Subscription"] = s;
                    this.ShowMessageBox("msgBoxRegister");
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
                finally
                {
                    Thread.CurrentPrincipal = null;
                    Context.User = null;
                }
            }
        }
        #endregion

        #region Methods Called By DoAuthenticate()
        /// <summary>
        /// Establish the thread identity before authentication in case we need 
        /// to access the router database.  Regardless of the login, give this
        /// context administrator privileges so that it may access the accounts
        /// and product licenses.  Subsequent requests will have the correct
        /// level of privilege (stored in the cookie at the end of this method).
        /// </summary>
        private void CreatePrincipal(string login)
        {
            CustomPrincipal userPrincipal = new CustomPrincipal(new GenericIdentity(login), new string[] {Role.Administrator.ToString()});
            Thread.CurrentPrincipal = userPrincipal;
            Context.User = userPrincipal;
        }
        /// <summary>
        /// Performs initialization necessary if the application is of the
        /// VaultLedger type.
        /// </summary>
        private void BandlInitialization()
        {
            // If we have no medium types, get them from the web service
            if (MediumType.GetMediumTypes().Count == 0)
                MediumType.GetBandlTypes();
            // If we have no accounts, create one
            if (Account.GetAccounts(false).Count == 0)
            {
                AccountDetails firstAccount = new AccountDetails("Example", false, "Your Street Address", "", "Your City", "Your State", "Your Zip Code", "Your Country", "You", "555-555-1234", "youremail@yourcompany.com", "This is the account that ships with " + Configurator.ProductName + ".  Please edit it with your own information." ); 
                Account.Insert(ref firstAccount);
            }
        }
        /// <summary>
        /// Performs initialization necessary if the application is of the
        /// Recall ReQuest Media Manager type.
        /// </summary>
        private void RecallInitialization()
        {
            // Get an authentication ticket from Recall synchronously.  If 
            // it can't be obtained, throw up the error.
            try
            {
                new Bandl.Library.VaultLedger.Gateway.Recall.RecallGateway().RequestAuthenticationTicket();
            }
            catch (Exception ex)
            {
                RecallRedirect(true, "No_Vault_Authorization_Ticket");
                throw new ApplicationException("Unable to procure vault authorization ticket: " + ex.Message);
            }
            // Get the accounts and media types from Recall.
            MediumType.SynchronizeMediumTypes(true);
            Account.SynchronizeAccounts(true);
            // Verify that we have at least one account, one container 
            // medium type in the database, and one non-container medium
            // type in the database.  Disallow entry if we don't have at 
            // least one of each.
            if (Account.GetAccountCount() == 0)
            {
                RecallRedirect(true, "No_Accounts_Present");
                throw new ApplicationException("No accounts present");
            }
            else if (MediumType.GetMediumTypeCount(true) == 0)
            {
                RecallRedirect(true, "No_Container_Types_Present");
                throw new ApplicationException("No container types present");
            }
            else if (MediumType.GetMediumTypeCount(false) == 0)
            {
                RecallRedirect(true, "No_Medium_Types_Present");
                throw new ApplicationException("No medium types present");
            }
            // Get the subaccounts
            try
            {
                ArrayList subaccounts = new ArrayList();
                foreach (AccountDetails ad in Account.GetAccounts())
                    if (ad.Primary == false)
                        subaccounts.Add(ad.Name);
                // Send the subaccounts
                string[] sa = (string[])subaccounts.ToArray(typeof(string));
                new Bandl.Library.VaultLedger.Gateway.Bandl.BandlGateway().SendSubaccounts(sa);
            }
            catch
            {
                ;
            }
        }
        /// <summary>
        /// Authenticates the user in the login textbox
        /// </summary>
        /// <param name="userName">
        /// Name of user which is displayed on welcome page and in page headers
        /// </param>
        /// <returns>
        /// Name of the role to which authenticated user is assigned, empty string on error
        /// </returns>
        private string AuthenticateUser(string login, string password, out string userName)
        {
            userName = String.Empty;
            string roleName = String.Empty;
            // Attempt to authenticate the operator.  If the operator cannot be
            // authenticated, then check for support login.  Support logins are
            // not allowed if the router is being used (i.e. application is
            // being hosted) because it presents too much of a security risk.
            // If the support login is being used, assign the administrator
            // security role.
            try
            {
                if (Operator.Authenticate(login, password, out roleName))
                {
                    userName = Operator.GetOperator(login).Login;
                }
                else if (this.SupportLogin(login))
                {
                    userName = login;
                    roleName = Role.Administrator.ToString();
                }
            }
            catch (RouterException)
            {
                userName = String.Empty;
                roleName = String.Empty;
            }
            // If no role, attempt to redirect to Recall error page.  Does nothing if the 
            // appropriate appSettings tag does not appear in the web.config file.  If no
            // redirection, throw an exception.
            if (roleName.Length == 0)
            {
                RecallRedirect(true, "Failed_Login");
                throw new ApplicationException("Login/password combination invalid");
            }
            else
            {
                return roleName;
            }
        }
        /// <summary>
        /// Checks to see if we're coming from autoloader
        /// </summary>
        /// <returns>
        /// True on success, else false
        /// </returns>
        private void CheckAutoloader()
        {
            if (Request.Headers["AutoLoader"] != null)
            {
                ProductLicenseDetails p1 = ProductLicense.GetProductLicense(LicenseTypes.Autoloader);
                // Check it out
                if (p1 == null || p1.Units != 1 || Convert.ToDateTime(p1.ExpireDate) < DateTime.Today)
                {
                    throw new ApplicationException("Autoloader not licensed");
                }
            }
        }
        /// <summary>
        /// Checks the licenses in the database against what is in the B&L database
        /// </summary>
        /// <returns>
        /// True on success, else false
        /// </returns>
        private bool CheckLicenses()
        {
            try
            {
                // Retrieve the licenses from the web service
                ProductLicense.RetrieveLicenses();
                // Verify licenses
                if (!ProductLicense.CheckLicense(LicenseTypes.Days))
                {
                    RecallRedirect(true, "Access_License_Expired");
                    throw new ApplicationException("Access license expired");
                }
                else if (!ProductLicense.CheckLicense(LicenseTypes.Operators))
                {
                    RecallRedirect(true, "Need_More_Operator_Licenses");
                    throw new ApplicationException("Too many operators exist in system.  Please call support for assistance.");
                }
                    // 2007-04-25 ERIC: Not necessary...not checking for media at the current time
                    //                else if (!ProductLicense.CheckLicense(LicenseTypes.Media))
                    //                {
                    //                    RecallRedirect(true, "Need_License_For_Additional_Media");
                    //                    throw new ApplicationException("Too many media exist in system.  Please call support for assistance.");
                    //                }
                else
                {
                    // Reset the web service contact failure key
                    ProductLicense.SetContactFailure(new DateTime(1900, 1, 1));
                    // Return true;
                    return true;
                }
            }
            catch (Exception ex)
            {
                try
                {
                    ProductLicenseDetails p = ProductLicense.GetProductLicense(LicenseTypes.Failure);
                    // If there is no failure on record, add one and return.  Allow two days regardless
                    // of the exception.  Allow seven days for contact error.
                    if (p == null || Date.ParseExact(p.IssueDate).Year == 1900)
                    {
                        ProductLicense.SetContactFailure(DateTime.UtcNow);
                        return true;
                    }
                    else if (DateTime.UtcNow < Date.ParseExact(p.IssueDate).AddDays(2))
                    {
                        return true;
                    }
                    else if (ex is System.Net.WebException)
                    {
                        if (DateTime.UtcNow > Date.ParseExact(p.IssueDate).AddDays(7))
                        {
                            RecallRedirect(true, "Cannot_Access_License_Service");
                            throw new ApplicationException("Access denied:&nbsp;&nbsp;Unable to access license service for one week.");
                        }
                        else
                        {
                            return true;
                        }
                    }
                    else
                    {
                        RecallRedirect(true, "License_Evaluation_Error");
                        throw new ApplicationException("License evaluation error:&nbsp;&nbsp;" + ex.Message);
                    }
                }
                catch
                {
                    RecallRedirect(true, "License_Evaluation_Error");
                    throw new ApplicationException("License evaluation error:&nbsp;&nbsp;" + ex.Message);
                }
            }
        }
        /// <summary>
        /// Checks the number of days left in the evaluation, if applicable
        /// </summary>
        private void CheckDaysLeft()
        {
            ProductLicenseDetails p = ProductLicense.GetProductLicense(LicenseTypes.Days);
            if (p.Units == ProductLicenseDetails.Unlimited) return;
            // Check number of days left in license
            TimeSpan ts = Convert.ToDateTime(p.IssueDate).AddDays(p.Units) - Time.UtcToday;
            // Message or exception?
            if (ts.Days < -10)
            {
                throw new ApplicationException("Access license expired");
            }
            else
            {
                Session["MainMenuMessage"] = String.Format("Your {0} evaluation will expire in {1} day{2}.", Configurator.ProductName, ts.Days, ts.Days != 1 ? "s" : String.Empty);
            }
        }
        /// <summary>
        /// Checks the database version against the application (UI.dll) version to
        /// make sure that it is compatible.
        /// </summary>
        private void CheckVersions()
        {
            try
            {
                string min = null, max = null;
                // Get the version number from the database
                DatabaseVersionDetails d = Database.GetVersion();
                // Get the version number of the UI library
                string assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version.ToString();
                // If the version number is 0.0.0.0, let it go.  This version is for in-house use
                // only (debug) and will always use the latest database version.
                if (assemblyVersion.CompareTo("0.0.0.0") == 0) return;
                // Get the range from the web service
                new BandlGateway().GetVersionRange(d.String, out min, out max);
                // Check for compatibility error
                if (assemblyVersion.CompareTo(min) < 0 || assemblyVersion.CompareTo(max) > 0)
                {
                    RecallRedirect(true, "Incompatible_Database_Version");
                    throw new ApplicationException(String.Format("Database version {0} is incompatible with version {1} of {2}", d.String, assemblyVersion, Configurator.ProductName));
                }
            }
            catch
            {
                ;
            }
        }
        #endregion
    }
}