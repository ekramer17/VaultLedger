using System;
using System.Web.Services.Protocols;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.Gateway.Bandl
{
	/// <summary>
	/// Summary description for Class1.
	/// </summary>
	public class BandlGateway
	{
        private enum LicenseType
        {
            Operator = 1,
            Media = 2,
            Days = 3
        }

        /// <summary>
        /// Creates a new account and evaluation licenses
        /// </summary>
        /// <param name="o">
        /// Details of the owner (client) of the new account
        /// </param>
        /// <returns>
        /// The subscription id of the new account
        /// </returns>
        public static string CreateAccount(OwnerDetails o)
        {
            try
            {
                // Create the web service proxy
                Bandl.BandlService webProxy = new Bandl.BandlService();
                // Create the account
                try
                {
                    webProxy.MethodHeaderValue = CreateHeader(-100, "w4113t");
                    return webProxy.CreateAccount(o.Company, o.Contact, o.PhoneNo, o.Email, o.AccountNo, (int)o.AccountType);
                }
                catch
                {
                    try
                    {
                        
                        webProxy.MethodHeaderValue = CreateHeader(-300, "4sp1r1n");
                        webProxy.DeleteAccount(o.AccountNo, (int)o.AccountType);
                    }
                    catch
                    {
                        // Ignore any exception thrown from delete method;
                    }
                    finally
                    {
                        throw;
                    }
                }
            }
            catch (SoapException e)
            {
                HandleSoapException(e);
                return null;    // Inaccessible b/c HandleSoapException always throws exception
            }
        }

        /// <summary>
        /// Deletes an account
        /// </summary>
        /// <param name="o">
        /// Details of the owner (client) of the account
        /// </param>
        public static void DeleteAccount(OwnerDetails o)
        {
            try
            {
                Bandl.BandlService bs = new Bandl.BandlService();
                bs.MethodHeaderValue = CreateHeader(-300, "4sp1r1n");
                bs.DeleteAccount(o.Subscription);
            }
            catch (SoapException e)
            {
                HandleSoapException(e);
            }
        }

        /// <summary>
        /// Soap exception handler
        /// </summary>
        /// <param name="e">
        /// Soap exception
        /// </param>
        private static void HandleSoapException(SoapException e)
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
        /// Creates a SOAP header used in calling methods of the web service
        /// </summary>
        /// <returns>
        /// SOAP header
        /// </returns>
        private static Bandl.MethodHeader CreateHeader(int accountType, string accountNo)
        {
            // Create new header and assign the password
            Bandl.MethodHeader newHeader = new Bandl.MethodHeader();
            // Set the accountType and accountNo
            newHeader.AccountType = accountType;
            newHeader.AccountNo = accountNo;
            // Generate the password
            string dateString = DateTime.Now.ToString("yyyy-MM-dd hh:mm:ss");
            newHeader.Password = Convert.ToBase64String(Balance.Inter(dateString));
            // Return the header
            return newHeader;
        }
	}
}
