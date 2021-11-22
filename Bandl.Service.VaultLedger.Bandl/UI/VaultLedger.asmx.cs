using System;
using System.IO;
using System.Collections;
using System.Configuration;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Web;
using System.Xml;
using System.Text;
using System.Threading;
using System.Web.Services;
using System.Web.Services.Protocols;
using Bandl.Service.VaultLedger.Bandl.BLL;
using Bandl.Service.VaultLedger.Bandl.DAL;
using Bandl.Service.VaultLedger.Bandl.Model;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Service.VaultLedger.Bandl.Exceptions;

namespace Bandl.Service.VaultLedger.Bandl.UI
{
    /// <summary>
    /// The VaultLedger-related web service to be hosted at B&L.  It provides
    /// license codes, assembly updates, and database scripts.
    /// </summary>
    [WebService(Namespace="http://www.bandl.com",Name="BandlService",Description="A web service to be hosted at B&L.")]
    [SoapDocumentService(RoutingStyle=SoapServiceRoutingStyle.RequestElement)]
    public class BandlService : System.Web.Services.WebService
    {
        public MethodHeader methodHeader;

        public BandlService()
        {
            //CODEGEN: This call is required by the ASP.NET Web Services Designer
            InitializeComponent();
        }

        #region Component Designer generated code
		
        //Required by the Web Services Designer 
        private IContainer components = null;
				
        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
        }

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        protected override void Dispose( bool disposing )
        {
            if(disposing && components != null)
            {
                components.Dispose();
            }
            base.Dispose(disposing);		
        }
		
        #endregion


        /// <summary>
        /// Returns the string parameters needed to access the online help
        /// </summary>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Returns the string parameters needed to access the online help.")]
        public void OnlineHelpParameters(ref string engine, ref string project, ref string window)
        {
            // Set the defaults
            window = "Main Window";
            project = "recall_recallHelp";
            engine = "http://help.bandl.com/roboapi.asp";
            // Authenticate the password; get the parameters on authentication
            if (PCheck(methodHeader.Password) == false)
            {
                throw new AuthenticationException("Invalid password");
            }
            else
            {
                Configurator.GetHelpParameters(methodHeader.AccountType, ref engine, ref project, ref window);
            }
        }

        /// <summary>
        /// Returns the medium type from the database
        /// </summary>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Returns the medium types from the database.")]
        public MediumTypeDetails[] GetMediumTypes()
        {
            // No authentication necessary
            return SQLServer.GetMediumTypes();
        }

        /// <summary>
        /// Returns the string parameters needed to access the online help
        /// </summary>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Receives an application exception.")]
        public void PublishException(string source, string message, string stackTrace)
        {
            string accountNo;
            string accountType;
            bool fileExists = false;
            bool mutexSignal = true;
            bool mutexCreated = false;

            // Authenticate the password
            if (PCheck(methodHeader.Password) == true)
            {
                // Get the account number
                accountNo = methodHeader.AccountNo != null ? methodHeader.AccountNo : String.Empty;
                // Get the account type
                switch (methodHeader.AccountType)
                {
                    case 1: // Recall
                        accountType = "RECALL";
                        break;
                    case 2: // Imation
                        accountType = "IMATION";
                        break;
                    default:
                        accountType = "BANDL";
                        break;
                }
                // Get the current path name
                string filePath = HttpRuntime.AppDomainAppPath;
                if (!filePath.EndsWith(Path.DirectorySeparatorChar.ToString()))
                {
                    filePath += Path.DirectorySeparatorChar.ToString();
                }
                // Append exception subdirectory and create if necessary
                filePath += "exceptions" + Path.DirectorySeparatorChar.ToString();
                if (!Directory.Exists(filePath))
                {
                    Directory.CreateDirectory(filePath);
                }
                // Determine the file name and check to see if it exists
                filePath += DateTime.Today.ToString("yyyy-MM-dd") + ".txt";
                fileExists = File.Exists(filePath);
                // Grab the mutex
                Mutex fileMutex = new Mutex(true, "VaultLedgerExceptionPublisher", out mutexCreated);
                if (!mutexCreated)
                {
                    mutexSignal = fileMutex.WaitOne(TimeSpan.FromSeconds(10), false);
                }
                // Write to the file if we received the mutex
                if (mutexSignal)
                {
                    using (StreamWriter streamWriter = new StreamWriter(filePath, true))
                    {
                        StringBuilder fileLine = new StringBuilder();
                        // Write headers if new file
                        if (!fileExists)
                        {
                            fileLine.Append("Account Type\t");
                            fileLine.Append("Account Number\t");
                            fileLine.Append("Source\t");
                            fileLine.Append("Message\t");
                            fileLine.Append("Stack Trace\t");
                            streamWriter.WriteLine(fileLine.ToString());
                        }
                        // Write the exception
                        fileLine.Remove(0, fileLine.Length);
                        fileLine.AppendFormat("{0}\t", accountType);
                        fileLine.AppendFormat("{0}\t", accountNo);
                        fileLine.AppendFormat("{0}\t", source);
                        fileLine.AppendFormat("{0}\t", message);
                        fileLine.AppendFormat("{0}\t", stackTrace);
                        streamWriter.WriteLine(fileLine.ToString());
                    }
                    // Release the mutex
                    fileMutex.ReleaseMutex();
                }
            }
        }

        /// <summary>
        /// Returns true if there is an updated database script, else false
        /// </summary>
        /// <param name="clientVersion">
        /// Version of the client database in form major.minor.revision
        /// </param>
        /// <returns>
        /// True if there is an updated database script, else false
        /// </returns>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Returns true if there is an updated database script, else false.")]
        public bool NewScriptExists(string clientVersion)
        {
            // Authenticate the password
            if (PCheck(methodHeader.Password) == false)
            {
                throw new AuthenticationException("Invalid password");
            }
            // Make call to database script object and return result
            return DatabaseScript.NewScriptExists(clientVersion);
        }

        /// <summary>
        /// Downloads the latest database script if the client version is not the same 
        /// as the latest version on the server.
        /// </summary>
        /// <param name="clientVersion">
        /// Version of the client database in form major.minor.revision
        /// </param>
        /// <param name="newVersion">
        /// Version number of the database script returned in X.X.X format
        /// </param>
        /// <returns>
        /// Byte array (encrypted) of latest script if different versions, 
        /// null if no update required
        /// </returns>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Returns the latest client database script if the version is different.")]
        public byte[] DownloadNextScript(string clientVersion, out string newVersion)
        {
            newVersion = String.Empty;
            // Authenticate the password
            if (PCheck(methodHeader.Password) == false)
                throw new AuthenticationException("Invalid password");
            // Get the full path of the next script.  Scripts will be named
            // with their version numbers plus ".sqe", e.g. "1_0_1.sqe".
            string nextScript = DatabaseScript.GetNextScript(clientVersion);
            // If there is no next version, then return null
            if (String.Empty == nextScript) 
                return null;
            else
            {
                int lastSlash = nextScript.LastIndexOf(Path.DirectorySeparatorChar.ToString());
                newVersion = nextScript.Substring(lastSlash + 1).Replace(".sqe", String.Empty).Replace("_", ".");
            }
            // Return the byte array (already encrypted)
            return DatabaseScript.ReadScript(nextScript);
        }

        /// <summary>
        /// Receives all the subaccounts for a particular global account
        /// </summary>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Receives all the subaccounts for a particular global account.")]
        public void ReceiveSubaccounts(string[] subaccounts)
        {
            try
            {
                // Authenticate the account based on account type
                if (AuthenticateAccount(methodHeader, String.Empty) == 0)
                    throw new AuthenticationException("Invalid account/password combination");
                // Get the account
                AccountDetails ad = SQLServer.GetAccount(methodHeader.AccountType, methodHeader.AccountNo);
                // If null parameter, create a zero length array
                if (subaccounts == null) subaccounts = new string[0];
                // Get the current subaccounts
                SubaccountDetails[] sds = SQLServer.GetSubaccounts(ad.Id);
                if (sds == null) sds = new SubaccountDetails[0];    // To prevent exceptions below
                // Do subaccount deletes
                for (int i = 0; i < sds.Length; i++)
                {
                    int j = 0;
                    // Does the subaccount still exist?
                    for (; j < subaccounts.Length; j++)
                        if (sds[i].AccountNo == subaccounts[j])
                            break;
                    // If not, delete it
                    if (j == subaccounts.Length)
                        SQLServer.DeleteSubaccount(sds[i].Id);
                }
                // Do subaccount inserts
                for (int i = 0; i < subaccounts.Length; i++)
                {
                    int j = 0;
                    // Does the subaccount already exist?
                    for (; j < sds.Length; j++)
                        if (subaccounts[i] == sds[j].AccountNo)
                            break;
                    // If not, insert it
                    if (j == sds.Length)
                        SQLServer.InsertSubaccount(ad.Id, subaccounts[i]);
                }
            }
            catch (Exception e)
            {
                CreateSoapException(e);
            }
        }

        /// <summary>
        /// Retrieves all the license information for the given Recall client
        /// </summary>
        /// <returns>
        /// Array of licenses
        /// </returns>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Retrieves all the license information for the given Recall client.")]
        public ProductLicenseDetails[] RetrieveLicenses(string companyName)
        {
            // Collect the accounts
            try
            {
                // Authenticate the account based on account type
                int clientId = AuthenticateAccount(methodHeader, companyName);
                // Evaluate result
				if (clientId == 0)
                {
                    throw new AuthenticationException("Invalid account/password combination");
                }
                else
                {
					ArrayList x1 = new ArrayList(SQLServer.RetrieveLicenses(clientId));
					AccountDetails a1 = SQLServer.GetAccount(methodHeader.AccountType, methodHeader.AccountNo);
					// Make sure we have rfid and autoloader license
					foreach (Int32 i1 in Enum.GetValues(typeof(LicenseTypes)))
					{
						bool b1 = false;
						// Find in collection						
						foreach (ProductLicenseDetails p1 in x1)
						{
							if (p1.LicenseType == i1)
							{
								b1 = true;
								break;
							}
						}
						// Add default
						if (b1 == false)
						{
							ProductLicenseDetails p1 = ProductLicenseDetails.DoDefault(i1);
							if (p1 != null) 
							{
								SQLServer.InsertLicense(a1, p1);
								x1.Add(p1);
							}
						}
					}
                    // Disallow dynamic password
                    if (a1.AllowDynamic == true)
					{
						a1.AllowDynamic = false;
						SQLServer.UpdateAccount(a1);
					}
					// Return the license array
                    return (ProductLicenseDetails[])x1.ToArray(typeof(ProductLicenseDetails));
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Creates a new account in the license database")]
        public string CreateAccount(string companyName, string contactName, string phoneNo, string email, string accountNo, int accountType)
        {
            try
            {
                AccountTypes accountEnum = AccountTypes.Bandl;
                DateTime expireDate = new DateTime(9999, 1, 1);
                // This method requires alternate authentication.  For this method, 
                // accountType should be -100, and the accountNo should be "w4113t".
                if (false == AlternateAuthentication(methodHeader, -100, "w4113t"))
                {
                    throw new AuthenticationException("Invalid authentication information for creating new client account");
                }
                // Cast the account type to an account type enumeration
                try
                {
                    accountEnum = (AccountTypes)Enum.ToObject(typeof(AccountTypes), accountType);
                }
                catch
                {
                    throw new ArgumentException("Illegal account type");
                }
                // Create a new account in the database
                int id = SQLServer.InsertAccount(new AccountDetails(companyName, contactName, phoneNo, email, accountNo, accountEnum));
                // Retrieve the new account to get the subscription id
                AccountDetails ca = SQLServer.GetAccount(id);
                // Recall defaults to unlimited everything, no RFID license
                if (accountEnum == AccountTypes.Recall)
                {
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.Operators, -1, expireDate));
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.Media, -1, expireDate));
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.Days, -1, expireDate));
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.RFID, 0, expireDate));
                }
                else
                {
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.Operators, Configurator.OperatorUnits, expireDate));
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.Media, Configurator.MediumUnits, expireDate));
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.Days, Configurator.DaysUnits, expireDate));
                    SQLServer.InsertLicense(ca, new ProductLicenseDetails((int)LicenseTypes.RFID, accountEnum == AccountTypes.Imation ? 1 : 0, expireDate));
                }
                // Return the subscription id
                return ca.Subscription;
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Deletes an account from the license database by subscription",MessageName="DeleteSubscription")]
        public void DeleteAccount(string subscription)
        {
            try
            {
                // This method requires alternate authentication.  For this method, 
                // accountType should be -300, and the accountNo should be "4sp1r1n".
                if (false == AlternateAuthentication(methodHeader, -300, "4sp1r1n"))
                {
                    throw new AuthenticationException("Invalid authentication information for deleting client account");
                }
                // Retrieve the account
                AccountDetails a = SQLServer.GetAccount(subscription);
                // Delete the account if it exists
                if (a == null)
                {
                    throw new ApplicationException("Account not found.");
                }
                else
                {
                    SQLServer.DeleteAccount(a);
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Deletes an account from the license database")]
        public void DeleteAccount(string accountNo, int accountType)
        {
            try
            {
                AccountTypes acType;
                // This method requires alternate authentication.  For this method, 
                // accountType should be -300, and the accountNo should be "4sp1r1n".
                if (false == AlternateAuthentication(methodHeader, -300, "4sp1r1n"))
                {
                    throw new AuthenticationException("Invalid authentication information for deleting client account");
                }
                // Cast the account type to an account type enumeration
                try
                {
                    acType = (AccountTypes)Enum.ToObject(typeof(AccountTypes), accountType);
                }
                catch
                {
                    throw new ArgumentException("Illegal account type");
                }
                // Retrieve the account
                AccountDetails clientAccount = SQLServer.GetAccount(accountType, accountNo);
                // Delete the account if it exists
                if (clientAccount == null)
                {
                    throw new ApplicationException("Account not found.");
                }
                else
                {
                    SQLServer.DeleteAccount(clientAccount);
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="OBSOLETE: Functionality incorporated into CreateAccount method.")]
        public void GrantLicense(string accountNo, int accountType, int licenseType, int units, DateTime expireDate)
        {
            #region Obsolete Code
//            try
//            {
//                // This method requires alternate authentication.  For this method, 
//                // accountType should be -200, and the accountNo should be "ch3ck3rs".
//                if (false == AlternateAuthentication(methodHeader, -200, "ch3ck3rs"))
//                {
//                    throw new AuthenticationException("Invalid authentication information for granting a license");
//                }
//                // Verify that we can cast the account type to an account type enumeration
//                try
//                {
//                    AccountTypes acType = (AccountTypes)Enum.ToObject(typeof(AccountTypes), accountType);
//                }
//                catch
//                {
//                    throw new ArgumentException("Illegal account type");
//                }
//                // Verify that we can cast the license type to an license type enumeration
//                try
//                {
//                    LicenseTypes lcType = (LicenseTypes)Enum.ToObject(typeof(LicenseTypes), licenseType);
//                }
//                catch
//                {
//                    throw new ArgumentException("Illegal license type");
//                }
//                // Create the new license
//                AccountDetails clientAccount = SQLServer.GetAccount(accountType, accountNo);
//                SQLServer.InsertLicense(clientAccount, new ProductLicenseDetails(licenseType, units, expireDate));
//            }
//            catch (Exception e)
//            {
//                throw CreateSoapException(e);
//            }
            #endregion
        }

        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Receives a list transmit audit record for sending a list")]
        public void AuditListXmitSend(DateTime actionTime, string listName, int numItems, int status, string exception)
        {
            try
            {
                // Evaluate result
                if (AuthenticateAccount(methodHeader, String.Empty) == 0)
                {
                    throw new AuthenticationException("Invalid account/password combination");
                }
                else
                {
                    AccountTypes acctType = (AccountTypes)Enum.ToObject(typeof(AccountTypes), methodHeader.AccountType);
                    AuditListXmitDetails.Status result = (AuditListXmitDetails.Status)Enum.ToObject(typeof(AuditListXmitDetails.Status), status);
                    AuditRecord.WriteListXmitRecord(new AuditListXmitDetails(AuditListXmitDetails.Actions.Send, methodHeader.AccountNo, acctType, actionTime, listName, numItems, exception, result));
                }
            }
            catch
            {
                ;   // Ignore any list audit exceptions
            }
        }

        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Receives a list transmit audit record for receiving a list")]
        public void AuditListXmitReceive(string accountNo, int accountType, DateTime actionTime, string listName, int numItems, int status, string fileName)
        {
            try
            {
                // This method requires alternate authentication.  For this method, 
                // accountType should be -400, and the accountNo should be "pl4st1c".
                if (false == AlternateAuthentication(methodHeader, -400, "pl4st1c"))
                {
                    throw new AuthenticationException("Invalid authentication information for auditing a list receive");
                }
                else
                {
                    AccountTypes acctType = (AccountTypes)Enum.ToObject(typeof(AccountTypes), accountType);
                    AuditListXmitDetails.Status result = (AuditListXmitDetails.Status)Enum.ToObject(typeof(AuditListXmitDetails.Status), status);
                    AuditRecord.WriteListXmitRecord(new AuditListXmitDetails(AuditListXmitDetails.Actions.Receive, accountNo, acctType, actionTime, listName, numItems, fileName, result));
                }
            }
            catch
            {
                ;   // Ignore any list audit exceptions
            }
        }
        
        /// <summary>
        /// Retrieves the web application version range for the given database version
        /// </summary>
        /// <returns>
        /// String with the minimum and maximum web versions, separated by a pipe.  For
        /// example, "1.0.0.0|3.1.0.0"
        /// </returns>
        [SoapHeader("methodHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Retrieves the web application version range for the given database version.")]
        public string GetWebVersionRange(string databaseVersion)
        {
            try
            {
                // Authenticate the account
                if (AuthenticateAccount(methodHeader, String.Empty) == 0)
                {
                    throw new AuthenticationException("Invalid account/password combination");
                }
                else
                {
                    string minVersion = "0.0.0.0";
                    string maxVersion = "999.999.999.999";
                    SQLServer.GetWebVersionRange(databaseVersion, out minVersion, out maxVersion);
                    return String.Format("{0}|{1}", minVersion, maxVersion);
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        #region Authentication Methods
        /// <summary>
        /// Authenticates an account
        /// </summary>
        /// <param name="methodHeader">
        /// The SOAP header supplied in the message that contains the account 
        /// type, account number, and password
        /// </param>
        /// <param name="companyName">
        /// Name of the company associated with the account
        /// </param>
        /// <returns>
        /// Id of account on success, else 0
        /// </returns>
        private int AuthenticateAccount(MethodHeader methodHeader, string companyName)
        {
            try
            {
                string hashedPwd;
                AccountDetails ad;
                int accountType = methodHeader.AccountType;
                string accountNo = methodHeader.AccountNo;
                string password = methodHeader.Password;
                // Look for the account in the database.  If it exists, verify
                // the password against it.  If the password cannot be verified
                // but the password is allowed to be dynamically generated for 
                // that account, check the password for validity.  If it is 
                // valid, install it as the new password for this account.
                // If the password is not in the database, look for it in the 
                // account file.  If it is in the account file and the password
                // checks out, then insert the account into the database with
                // the given password.
                if ((ad = SQLServer.GetAccount(accountType, accountNo)) != null)
                {
                    // Check company name change
                    if (ad.Company != String.Empty && companyName.Length > 0)
                        ad.Company = companyName;
                    // Hash the password and check for match
                    if ((hashedPwd = PwordHasher.HashPasswordAndSalt(password,ad.Salt)) != ad.Password)
                    {
                        if (ad.AllowDynamic == false || PCheck(password) == false) 
                            return 0;
                        else
                            ad.Password = password;
                    }
                    // If the object is modified, update it
                    ad.LastContact = DateTime.Now;
                    SQLServer.UpdateAccount(ad);
                    // return
                    return ad.Id;
                }
                // No match
                return 0;
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// This method is used by methods not called from the VaultLedger 
        /// application.  Calls from the registrar, for example, would use this
        /// method for their authentication.  
        /// </summary>
        /// <param name="methodHeader">
        /// The SOAP header supplied in the message that contains the account 
        /// type, account number, and password
        /// </param>
        /// <param name="accountType">
        /// What the accountType in the methodHeader should match
        /// </param>
        /// <param name="accountNo">
        /// What the accountNo in the methodHeader should match
        /// </param>
        /// <returns>
        /// True if successfully authentication, else false
        /// </returns>
        private bool AlternateAuthentication(MethodHeader methodHeader, int accountType, string accountNo)
        {
            if (methodHeader.AccountType != accountType)
            {
                return false;
            }
            else if (methodHeader.AccountNo != accountNo)
            {
                return false;
            }
            else
            {
                try
                {
                    // The password should be today's date in yyyy-mm-dd hh:mm:ss
                    // format, encrypted and converted to base64.  Difference from
                    // actual time may be 48 hours each way, due to potential 
                    // international date differences.
                    byte[] convertedBytes = Convert.FromBase64String(methodHeader.Password);
                    string dateString = Balance.Exhume(convertedBytes);
                    DateTime dateTime = DateTime.Parse(dateString);
                    if (dateTime < DateTime.Today.AddHours(-48))
                    {
                        return false;
                    }
                    else if (dateTime > DateTime.Today.AddHours(48))
                    {
                        return false;
                    }
                    else
                    {
                        return true;
                    }
                }
                catch
                {
                    return false;
                }
            }
        }

        /// <summary>
        /// Checks the validity of a dynamically generated password
        /// </summary>
        /// <param name="password">
        /// Password to check
        /// </param>
        /// <returns>
        /// True if password checks out, else false
        /// </returns>
        private bool PCheck(string password)
        {
            // Initial password should be 32 characters long
            if (password.Length != 32) return false;
            // Remove the 3rd, 4th, 22nd, 23rd characters
            int chkThree = Convert.ToInt32(password[23].ToString());
            int chkEight = Convert.ToInt32(password[22].ToString());
            int chkSeven = Convert.ToInt32(password[4].ToString());
            int chkFour = Convert.ToInt32(password[3].ToString());
            password = password.Remove(23,1);
            password = password.Remove(22,1);
            password = password.Remove(4,1);
            password = password.Remove(3,1);
            // Add the UTF-8 values of the rest of the characters
            int total = 0;
            foreach(char c in password)
                total += Convert.ToInt32(c.ToString());
            // Check the nine checksum
            if (false == Convert.ToString(total + chkThree).EndsWith("3")) 
                return false;
            // Check the five checksum
            if (false == Convert.ToString(total + chkEight).EndsWith("8")) 
                return false;
            // Check the six checksum
            if (false == Convert.ToString(total + chkSeven).EndsWith("7")) 
                return false;
            // Check the two checksum
            if (false == Convert.ToString(total + chkFour).EndsWith("4")) 
                return false;
            // Password is valid
            return true;
        }
        #endregion    
        
        #region Exception Handler
        /// <summary>
        /// Creates a SOAP exception to throw back to the client caller
        /// </summary>
        /// <param name="e">
        /// Exception to be translated into a SOAP exception
        /// </param>
        /// <returns>
        /// The SOAP exception to throw back
        /// </returns>
        private SoapException CreateSoapException(Exception e)
        {
            if (e is AuthenticationException)
                return new SoapException(e.Message, new XmlQualifiedName("Client.Authentication"));
            else if (e is DatabaseException)
                return new SoapException(e.Message, new XmlQualifiedName("Server.Database"));
            else 
                return new SoapException(e.Message, SoapException.ServerFaultCode);
        }
        #endregion
    }
}
