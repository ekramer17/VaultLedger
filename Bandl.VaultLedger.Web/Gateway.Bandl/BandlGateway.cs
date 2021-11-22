using System;
using System.Net;
using System.Web;
using System.Text;
using Microsoft.Win32;
using System.Threading;
using System.Collections;
using System.Web.Caching;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Router;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using System.Security.Cryptography.X509Certificates;
using System.Web.Services.Protocols;

namespace Bandl.Library.VaultLedger.Gateway.Bandl
{
	/// <summary>
	/// Gateway to the B&amp;L web service
	/// </summary>
	public class BandlGateway
	{
        private class MyPolicy : ICertificatePolicy
        {
            public bool CheckValidationResult(ServicePoint s1, X509Certificate x1, WebRequest w1, int p1)
            {
                return true;
            }
        }

        public BandlGateway() {}

        /// <summary>
        /// Overload of the CreateHeader(ref bool, bool) method
        /// </summary>
        private Bandl.MethodHeader CreateHeader(ref bool dynamicPassword)
        {
            return CreateHeader(ref dynamicPassword, true);
        }

        /// <summary>
        /// Overload of the CreateHeader(ref bool, bool) method
        /// </summary>
        private Bandl.BandlService CreateService()
        {
            Bandl.BandlService b = new Bandl.BandlService();
            // Any proxy in the configuration file?
            if (Configurator.Proxy.Length != 0)
            {
                b.Proxy = new WebProxy(Configurator.Proxy, true);
            }
            else if (WebProxy.GetDefaultProxy() != null)
            {
                WebProxy p = WebProxy.GetDefaultProxy();
                p.BypassProxyOnLocal = true;
                b.Proxy = p;
            }
            // Hit us up with the policy object to bypass SSL checks
            System.Net.ServicePointManager.CertificatePolicy = new MyPolicy();
            // Return the service object
            return b;

        }

        /// <summary>
        /// Creates a SOAP header used in calling methods of the web service
        /// </summary>
        /// <param name="dynamicPassword">
        /// In: If true, forces generation of new password.  If false, checks
        /// database first, and generates new password only if password not
        /// present in database.
        /// Out: True if a password was dynamically generated, else false
        /// </param>
        /// <param name="accountNo">
        /// Get the account number.  The online help method in particular
        /// does not want to attempt to get the account number, for if the
        /// router is used then the account number cannot be resolved until
        /// the user actually logs in.  As a result, we would not be able
        /// to display help on the login page.
        /// </param>
        /// <returns>
        /// SOAP header
        /// </returns>
        private Bandl.MethodHeader CreateHeader(ref bool dynamicPassword, bool accountNo)
        {
            // Create new header and assign the password
            Bandl.MethodHeader newHeader = new Bandl.MethodHeader();
            // Get the product type
            string accountType = Configurator.ProductType;
            // If it's hosted at Recall, we must get both pieces of information from the 
            // router; otherwise we can get the subscription from the client database.
            if (Configurator.Router && accountNo == true && accountType == "RECALL")
            {
                int t1 = 0;     // account type
                string a1 = String.Empty;   // account number
                string login = Thread.CurrentPrincipal.Identity.Name;
                RouterDb.GetAccount(login, out a1, out t1);
                newHeader.AccountType = t1;
                newHeader.AccountNo = a1;
            }
            else
            {
                // Get the account type and account number
                switch (accountType)
                {
                    case "RECALL":
                        if (accountNo) newHeader.AccountNo = Configurator.GlobalAccount;
                        newHeader.AccountType = 1;
                        break;
                    case "IMATION":
                        if (accountNo) newHeader.AccountNo = SubscriptionFactory.Create().GetSubscription();
                        newHeader.AccountType = 2;
                        break;
                    case "BANDL":
                    case "B&L":
                    default:
                        if (accountNo) newHeader.AccountNo = SubscriptionFactory.Create().GetSubscription();
                        newHeader.AccountType = 0;
                        break;
                }
            }
            // Get the password
            if (dynamicPassword == true)
            {
                newHeader.Password = GeneratePword();
            }
            else if (!accountNo || ((newHeader.Password = ReadPassword()) == String.Empty))
            {
                dynamicPassword = true;
                newHeader.Password = GeneratePword();
            }
            // Return the header
            return newHeader;
        }
        
        /// <summary>
        /// Gets the string parameters needed to access the online help
        /// from the web service
        /// </summary>
        public void OnlineHelpParameters(out string engine, out string project, out string window)
        {
            // If the parameters are in the cache, then get them from there
            if (HttpRuntime.Cache[CacheKeys.HelpParameters] != null)
            {
                string[] helpParms = (string[])HttpRuntime.Cache[CacheKeys.HelpParameters];
                engine  = helpParms[0];
                project = helpParms[1];
                window  = helpParms[2];

            }
            else
            {
                // Initialize
                engine  = String.Empty;
                project = String.Empty;
                window  = String.Empty;
                // Obtain the parameters from the web service
                try
                {
                    // Create the service object
                    bool dynamicPassword = false;
                    Bandl.BandlService b = CreateService();
                    b.MethodHeaderValue = CreateHeader(ref dynamicPassword, false);
                    // Get the account type
                    switch (Configurator.ProductType.ToLower())
                    {
                        case "b&l":
                        case "bandl":
                            b.MethodHeaderValue.AccountType = 0;
                            break;
                        case "imation":
                            b.MethodHeaderValue.AccountType = 2;
                            break;
                        case "recall":
                        default:
                            b.MethodHeaderValue.AccountType = 1;
                            break;
                    }
                    b.OnlineHelpParameters(ref engine, ref project, ref window);
                    // Insert the parameters into the appliction cache
                    string[] helpParms = new string[] {engine, project, window};
                    CacheKeys.Insert(CacheKeys.HelpParameters, helpParms, TimeSpan.FromMinutes(30));
                }
                catch(SoapException e)
                {
                    HandleSoapException(e);
                }
            }
        }

        /// <summary>
        /// Registers a new client with the B&L web service
        /// </summary>
        /// <returns>
        /// Subscription id
        /// </returns>
        public string RegisterClient(string companyName, string contactName, string phoneNo, string email)
        {
            try
            {
                Bandl.BandlService b = CreateService();
                Bandl.MethodHeader mh = new Bandl.MethodHeader();
                mh.AccountNo = "w4113t";
                mh.AccountType = -100;
                // The password should be today's date in yyyy-MM-dd hh:mm:ss
                // format, encrypted and converted to base64.  Difference from
                // actual time may be 24 hours each way, due to potential 
                // international date differences.
                string dateString = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
                mh.Password = Convert.ToBase64String(Crypto.Encrypt(dateString));
                // Set the method header
                b.MethodHeaderValue = mh;
                // Get the account information
                int accountType = 0;
                string accountNo = String.Empty;
                switch (Configurator.ProductType.ToLower())
                {
                    case "recall":
                        accountType = 1;
                        if ((accountNo = Configurator.GlobalAccount) == String.Empty)
                            throw new ApplicationException("No global account specified in configuration file.");
                        else
                            break;
                    case "imation":
                        accountType = 2;
                        break;
                    case "b&l":
                    case "bandl":
                    default:
                        accountType = 0;
                        break;
                }
                // Register the client
                return b.CreateAccount(companyName, contactName, phoneNo, email, accountNo, accountType);
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                throw;
            }
        }

        /// <summary>
        /// Retrieves default medium types from the B&L web service.  Should only be used
        /// if the product type is B&L and there are no medium types in the database currently.
        /// </summary>
        /// <returns>
        /// Collection of default medium types
        /// </returns>
        public MediumTypeCollection GetMediumTypes()
        {
            try
            {
                // Create the service object
                bool dynamicPassword = true;
                Bandl.BandlService b = CreateService();
                b.MethodHeaderValue = CreateHeader(ref dynamicPassword, false);
                // Create medium type collection
                MediumTypeCollection mediumTypes = new MediumTypeCollection();
                // Get the medium types
                foreach(Bandl.MediumTypeDetails m in b.GetMediumTypes())
                    mediumTypes.Add(new Model.MediumTypeDetails(m.TypeName, m.TwoSided, m.Container, String.Empty));
                // Return the medium types
                return mediumTypes;
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                throw;
            }
        }

        /// <summary>
        /// Sends exception information to the web service
        /// </summary>
        public void PublishException(Exception e)
        {
            try
            {
                // Create the service object
                Bandl.BandlService b = CreateService();
                // Create the header
                bool dynamicPassword = false;
                b.MethodHeaderValue = CreateHeader(ref dynamicPassword);
                // Publish the exception
                b.PublishException(e.Source, e.Message, e.StackTrace);
            }
            catch
            {
                ;
            }
        }

        /// <summary>
        /// Checks whether or not a new database script exists
        /// </summary>
        /// <returns>
        /// True if a new script exists, else false
        /// </returns>
        public bool NewScriptExists(string clientVersion)
        {
            try
            {
                bool returnValue;
                // Create the service object
                bool dynamicPassword = false;
                Bandl.BandlService b = CreateService();
                // Make web method call
                while (true)
                {
                    try
                    {
                        b.MethodHeaderValue = CreateHeader(ref dynamicPassword);
                        returnValue = b.NewScriptExists(clientVersion);
                        break;
                    }
                    catch (SoapException e)
                    {
                        // If there was an authentication issue, try to dynamically 
                        // generate a new password.  This will be accepted on the 
                        // other end if the account number is currently allowing 
                        // dynamic password generation.
                        if (dynamicPassword || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            dynamicPassword = true;
                    }
                }
                // If sucessful and password dynamically generated, write 
                // password to database
                if (dynamicPassword == true) WritePassword(b.MethodHeaderValue.Password);
                // Return the result of the web method call
                return returnValue;
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return false;
            }
        }

        /// <summary>
        /// Downloads the new database script
        /// </summary>
        /// <returns>
        /// Array of bytes representing the new script, null if no new script
        /// </returns>
        public byte[] DownloadNextScript(ref DatabaseVersionDetails currentVersion)
        {
            try
            {
                byte[] returnValue;
                // Create the service object
                bool dynamicPassword = false;
                Bandl.BandlService b = CreateService();
                // Make web method call
                while (true)
                {
                    try
                    {
                        string nextVersion = String.Empty;
                        b.MethodHeaderValue = CreateHeader(ref dynamicPassword);
                        returnValue = b.DownloadNextScript(currentVersion.String, out nextVersion);
                        // Dissect the version string
                        if (returnValue != null)
                        {
                            try
                            {
                                string[] versionParts = nextVersion.Split(new char[] {'.'});
                                int major = Convert.ToInt32(versionParts[0]);
                                int minor = Convert.ToInt32(versionParts[1]);
                                int revision = Convert.ToInt32(versionParts[2]);
                                currentVersion = new DatabaseVersionDetails(major, minor, revision);
                            }
                            catch (Exception e)
                            {
                                throw new ApplicationException("Error encountered while dissecting database version number: " + e.Message);
                            }
                        }
                        // Break the loop
                        break;
                    }
                    catch (SoapException e)
                    {
                        // If there was an authentication issue, try to dynamically 
                        // generate a new password.  This will be accepted on the 
                        // other end if the account number is currently allowing 
                        // dynamic password generation.
                        if (dynamicPassword || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            dynamicPassword = true;
                    }
                }
                // If sucessful and password dynamically generated, write 
                // password to database
                if (dynamicPassword == true) WritePassword(b.MethodHeaderValue.Password);
                // Return the result of the web method call
                return returnValue;
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return null;
            }
        }

        /// <summary>
        /// Retrieves product licenses from the web service
        /// </summary>
        /// <returns>
        /// Collection of product licenses
        /// </returns>
        public ProductLicenseCollection RetrieveLicenses()
        {
            string companyName = null;
            // Get the company name
            try
            {
                companyName = ((string)Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\MS Setup (ACME)\User Info").GetValue("DefCompany",String.Empty)).Trim();
            }
            catch
            {
                companyName = String.Empty;
            }

            try
            {
                // Get the service object and create an array to receive the remote licenses
                bool dynamicPassword = false;
                Bandl.BandlService b = CreateService();
                Bandl.ProductLicenseDetails[] remoteLicenses;
                // Call the web service and retrieve licenses
                while (true)
                {
                    try
                    {
                        b.MethodHeaderValue = CreateHeader(ref dynamicPassword);
                        remoteLicenses = b.RetrieveLicenses(companyName);
                        break;
                    }
                    catch (SoapException e)
                    {
                        // If there was an authentication issue, try to dynamically 
                        // generate a new password.  This will be accepted on the 
                        // other end if the account number is currently allowing 
                        // dynamic password generation.
                        if (dynamicPassword || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            dynamicPassword = true;
                    }
                }
                // If sucessful and password dynamically generated, write password to database
                if (dynamicPassword == true) WritePassword(b.MethodHeaderValue.Password);
                // Transfer the remote licenses to a collection to return
                ArrayList returnLicenses = new ArrayList(remoteLicenses.Length);
                for(int i = 0; i < remoteLicenses.Length; i++)
                {
                    LicenseTypes licenseType = (LicenseTypes)Enum.ToObject(typeof(LicenseTypes),remoteLicenses[i].LicenseType);
                    Model.ProductLicenseDetails newLicense = new Model.ProductLicenseDetails(licenseType, remoteLicenses[i].Units, remoteLicenses[i].IssueDate, remoteLicenses[i].ExpireDate);
                    returnLicenses.Add(newLicense);
                }
                // Return a collection of the remote licenses
                return new ProductLicenseCollection(returnLicenses);
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return null;    // Unreachable: HandleSoapException always throws exception
            }
        }

        /// <summary>
        /// Retrieves product licenses from the web service
        /// </summary>
        /// <returns>
        /// Collection of product licenses
        /// </returns>
        public void SendSubaccounts(string[] subaccounts)
        {
            try
            {
                // Get the service object and create an array to receive the remote licenses
                bool dynamicPassword = false;
                Bandl.BandlService b = CreateService();
                // Call the web service and retrieve licenses
                while (true)
                {
                    try
                    {
                        b.MethodHeaderValue = CreateHeader(ref dynamicPassword);
                        b.ReceiveSubaccounts(subaccounts);
                        break;
                    }
                    catch (SoapException e)
                    {
                        // If there was an authentication issue, try to dynamically 
                        // generate a new password.  This will be accepted on the 
                        // other end if the account number is currently allowing 
                        // dynamic password generation.
                        if (dynamicPassword || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            dynamicPassword = true;
                    }
                }
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
            }
        }

        /// <summary>
        /// Gets the acceptible version range from the web service
        /// </summary>
        public void GetVersionRange(string databaseVersion, out string minVersion, out string maxVersion)
        {
            // Initialize version
            minVersion = "0.0.0.0";
            maxVersion = "999.999.999.999";
            // Get the version range
            try
            {
                // Get the service object and create an array to receive the remote licenses
                bool dynamicPassword = false;
                Bandl.BandlService b = CreateService();
                // Call the web service and retrieve licenses
                while (true)
                {
                    try
                    {
                        b.MethodHeaderValue = CreateHeader(ref dynamicPassword);
                        string returnString = b.GetWebVersionRange(databaseVersion);
                        string[] s = returnString.Split(new char[] {'|'});
                        minVersion = s[0];
                        maxVersion = s[1];
                        break;
                    }
                    catch (SoapException e)
                    {
                        // If there was an authentication issue, try to dynamically 
                        // generate a new password.  This will be accepted on the 
                        // other end if the account number is currently allowing 
                        // dynamic password generation.
                        if (dynamicPassword || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            dynamicPassword = true;
                    }
                }
                // If sucessful and password dynamically generated, write password to database
                if (dynamicPassword == true) WritePassword(b.MethodHeaderValue.Password);
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
            }
        }

        /// <summary>
        /// Sends an audit record of a list transmission to the web service (OBSOLETE)
        /// </summary>
        public void AuditListXmit(DateTime dateTime, string listName, int numItems, int result, string exception)
        {
            ;
        }

        /// <summary>
        /// Sends an audit record of a list transmission to the web service (OBSOLETE)
        /// </summary>
        public void AuditListXmit(DateTime dateTime, string listName, int numItems, int result)
        {
            ;
        }

        /// <summary>
        /// Soap exception handler
        /// </summary>
        /// <param name="e">
        /// Soap exception
        /// </param>
        private void HandleSoapException(SoapException e)
        {
            switch(e.Code.ToString())
            {
                case "Client.Authentication":
                    throw new ApplicationException(e.Message);
                case "Server.Database":
                    throw new ApplicationException(e.Message);
                default:
                    throw new ApplicationException(e.Message);
            }
        }

        /// <summary>
        /// Generates a password according to a certain format
        /// </summary>
        /// <returns>
        /// Password
        /// </returns>
        private string GeneratePword()
        {
            int total = 0;
            Random randomGenerator = new Random();
            StringBuilder pwdBuilder = new StringBuilder(32);
            // Need 28 alphanumeric characters randomly generated
            for(int i = 0; i < 28; i++)
            {
                char nextChar = Convert.ToChar(randomGenerator.Next(48,57));
                total += Convert.ToInt32(nextChar.ToString());
                pwdBuilder.Append(nextChar);
            }
            // Insert checksums
            pwdBuilder.Insert(3, Convert.ToString((14 - total % 10) % 10));
            pwdBuilder.Insert(4, Convert.ToString((17 - total % 10) % 10));
            pwdBuilder.Insert(22, Convert.ToString((18 - total % 10) % 10));
            pwdBuilder.Insert(23, Convert.ToString((13 - total % 10) % 10));
            // Encrypt and convert to string
            return pwdBuilder.ToString();
        }

        private string ReadPassword()
        {
            // Get the value from the database
            IProductLicense dal = ProductLicenseFactory.Create();
            Model.ProductLicenseDetails pld = dal.GetProductLicense(LicenseTypes.Bandl);
            if (pld == null) return String.Empty;
            // Decrypt the string
            return Crypto.Decrypt(pld.Value, pld.Ray);
        }

        private void WritePassword(string password)
        {
            // Encrypt string with default key, newly created vector
            byte[] r = new byte[16];
            byte[] p = Crypto.Encrypt(password, out r);
            Model.ProductLicenseDetails pld = new Model.ProductLicenseDetails(LicenseTypes.Bandl, p, r); 
            // Insert into database
            ProductLicenseFactory.Create().Insert(pld);
        }
    }
}
