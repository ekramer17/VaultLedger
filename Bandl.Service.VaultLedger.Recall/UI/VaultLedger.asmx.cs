using System;
using System.IO;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Web;
using System.Xml;
using System.Text;
using System.Threading;
using System.Web.Services;
using System.Configuration;
using System.Web.Services.Protocols;
using Bandl.Service.VaultLedger.Recall.BLL;
using Bandl.Service.VaultLedger.Recall.DAL;
using Bandl.Service.VaultLedger.Recall.Model;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Service.VaultLedger.Recall.Exceptions;
using Bandl.Service.VaultLedger.Recall.Gateway.Bandl;

namespace Bandl.Service.VaultLedger.Recall.UI
{
    /// <summary>
    /// The VaultLedger-related web service to be hosted at Recall.  It 
    /// provides account information, medium type information, receives
    /// lists from the client, and allows the client to download
    /// account inventories.
    /// </summary>
    [WebService(Namespace="http://www.bandl.com",Name="RecallService",Description="A web service to be hosted at the central Recall location.")]
    public class RecallService : System.Web.Services.WebService
    {
        // Declare a public variable of type TicketHeader to hold the the
        // authorization ticket SOAP header
        public TicketHeader ticketHeader;

        // Timeout value to use on mutex creation
        private int MutexTimeout
        {
            get
            {
                int timeout = Convert.ToInt32(ConfigurationSettings.AppSettings["MutexTimeout"]);
                return timeout > 0 ? timeout : 10000;
            }
        }

        public RecallService()
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
        /// Examines an authentication ticket to determine whether or not
        /// it is authentic.
        /// </summary>
        private void AuthenticateTicket()
        {
            try 
            {
                if (ticketHeader.Account == String.Empty || ticketHeader.Ticket == Guid.Empty)
                    throw new AuthenticationException("Invalid authentication ticket");
                else 
                    SQLServer.AuthenticateTicket(ticketHeader.Account,ticketHeader.Ticket);
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Requests an authentication ticket from the web service to use with
        /// future calls.
        /// </summary>
        /// <param name="account">
        /// Name of the account requesting the ticket
        /// </param>
        /// <param name="password">
        /// Password needed for authentication
        /// </param>
        /// <returns>
        /// Globally unique ticket
        /// </returns>
        [WebMethod(Description="Requests an authentication ticket from the web service to use with future calls.")]
        public Guid RequestTicket(string account, string password)
        {
            try
            {
                string filePath;
                string hashedPwd;
                LocalAccountDetails lad;
                // Make sure we have an account number of valid length
                if (null == account || account.Length < 4 || account.Length > 5)
                    throw new AuthenticationException("Invalid account/password combination");
                // Make sure that the account exists in the file.  Recall may
                // have taken it out but not removed it from the database.
                if ((filePath = AccountFile.GetFilePath(account)) == null)
                {
                    // Mark the account as deleted in the database if it exists
                    if ((lad = SQLServer.RetrieveGlobalAccount(account)) != null)
                        SQLServer.DeleteGlobalAccount(lad);
                    // throw an authentication exception
                    throw new AuthenticationException("Account not found");
                }
                // Look for the account in the database.  If it exists, verify
                // the password against it.  If the password cannot be verified
                // but the password is allowed to be dynamically generated for 
                // that account, check the password for validity.  If it is 
                // valid, install it as the new password for this account.
                // If the password is not in the database, and if the password
                // checks out, then insert the account into the database with
                // the given password.
                if ((lad = SQLServer.RetrieveGlobalAccount(account)) != null)
                {
                    if ((hashedPwd = PwordHasher.HashPasswordAndSalt(password,lad.Salt)) != lad.Password)
                    {
                        if (lad.AllowDynamic == false || PCheck(password) == false) 
                            throw new AuthenticationException("Invalid account/password combination");
                        else
                        {
                            lad.Password = hashedPwd;
                            SQLServer.UpdateGlobalAccount(lad);
                        }
                    }
                }
                else
                {
                    if (PCheck(password) == false)
                        throw new AuthenticationException("Invalid account/password combination");
                    else
                        SQLServer.CreateGlobalAccount(new LocalAccountDetails(account,password,false,filePath));
                }
                // Create and return ticket
                return SQLServer.CreateTicket(account);
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Retrieves all the account information for the global account
        /// attached to the authentication ticket.
        /// </summary>
        /// <returns>
        /// Array of accounts
        /// </returns>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Retrieves all the accounts associated with the given global account.")]
        public AccountDetails[] RetrieveAccounts()
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();

            // Collect the accounts
            try
            {
                return AccountFile.RetrieveAccounts(ticketHeader.Account);
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Retrieves all the medium type information
        /// </summary>
        /// <returns>
        /// Array of medium types
        /// </returns>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Retrieves all the medium types.")]
        public MediumTypeDetails[] RetrieveMediumTypes()
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();
            // Collect the mediumt types
            try
            {
                return MediumTypeFile.RetrieveMediumTypes(false);
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Transmits a send list to the server
        /// </summary>
        /// <param name="sendList">
        /// A transmitted send list
        /// </param>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Transmits an array of send list to the server.")]
        public void TransmitSendLists(RMMSendListDetails[] sendLists)
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();
            // Grab/create the appropriate mutex and write the file.
            try
            {
                bool mutexCreated;
                string fileName = null;
                // Grab the mutex for the account of the send list.  The name of
                // the mutex will be "RMM" + "Send" + account number.
                Mutex m = new Mutex(true, "RMMSend" + ticketHeader.Account, out mutexCreated);
                // If we didn't create the mutex, then wait for it.  If we 
                // timeout, then throw an exception.
                if (false == mutexCreated) 
                    if (false == m.WaitOne(MutexTimeout, false))
                        throw new ApplicationException("Unable to grab send list mutex prior to timeout.");
                // Write the files and release the mutex
                try
                {
                    BandlGateway bandlGate = new BandlGateway();
                    foreach(RMMSendListDetails sendList in sendLists)
                    {
//                        try
//                        {
                            fileName = String.Empty;
                            fileName = SendListFile.Write(sendList);
//                            bandlGate.AuditListReceive(sendList.Account, sendList.Name, sendList.Items.Length, fileName, 1);
//                        }
//                        catch (Exception e)
//                        {
//                            try
//                            {
//                                bandlGate.AuditListReceive(sendList.Account, sendList.Name, sendList.Items.Length, e.Message, 0);
//                            }
//                            catch
//                            {
//                                ;
//                            }
//                            finally
//                            {
//                                throw;
//                            }
//                        }
                    }
                }
                finally
                {
                    m.ReleaseMutex();
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Transmits a receive list to the server
        /// </summary>
        /// <param name="receiveList">
        /// A transmitted receive list
        /// </param>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Transmits an array of receive lists to the server.")]
        public void TransmitReceiveLists(RMMReceiveListDetails[] receiveLists)
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();
            // Grab/create the appropriate mutex and write the file.
            try 
            {
                bool mutexCreated;
                string fileName = null;
                // Grab the mutex for the account of the send list.  The name of
                // the mutex will be "RMM" + "Receive" + account number.
                Mutex m = new Mutex(true, "RMMReceive" + ticketHeader.Account, out mutexCreated);
                // If we didn't create the mutex, then wait for it.  If we 
                // timeout, then throw an exception.
                if (false == mutexCreated) 
                    if (false == m.WaitOne(MutexTimeout, false))
                        throw new ApplicationException("Unable to grab receive list mutex prior to timeout.");
                // Write the file and release the mutex
                try
                {
                    BandlGateway bandlGate = new BandlGateway();
                    foreach(RMMReceiveListDetails receiveList in receiveLists)
                    {
//                        try
//                        {
                            fileName = String.Empty;
                            fileName = ReceiveListFile.Write(receiveList);
//                            bandlGate.AuditListReceive(receiveList.Account, receiveList.Name, receiveList.Items.Length, fileName, 1);
//                        }
//                        catch (Exception e)
//                        {
//                            try
//                            {
//                                bandlGate.AuditListReceive(receiveList.Account, receiveList.Name, receiveList.Items.Length, e.Message, 0);
//                            }
//                            catch
//                            {
//                                ;
//                            }
//                            finally
//                            {
//                                throw;
//                            }
//                        }
                    }
                }
                finally
                {
                    m.ReleaseMutex();
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Transmits a disaster code list to the server
        /// </summary>
        /// <param name="disasterCodeList">
        /// A transmitted disaster code list
        /// </param>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Transmits an array of disaster code lists to the server.")]
        public void TransmitDisasterCodeLists(RMMDisasterCodeListDetails[] disasterCodeLists)
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();
            // Grab/create the appropriate mutex and write the file.
            try 
            {
                bool mutexCreated;
                string fileName = null;
                // Grab the mutex for the account of the send list.  The name of
                // the mutex will be "RMM" + "DRP" + account number.
                Mutex m = new Mutex(true, "RMMDRP" + ticketHeader.Account, out mutexCreated);
                // If we didn't create the mutex, then wait for it.  If we 
                // timeout, then throw an exception.
                if (false == mutexCreated) 
                    if (false == m.WaitOne(MutexTimeout, false))
                        throw new ApplicationException("Unable to grab disaster code list mutex prior to timeout.");
                // Write the file and release the mutex
                try
                {
                    BandlGateway bandlGate = new BandlGateway();
                    foreach(RMMDisasterCodeListDetails disasterList in disasterCodeLists)
                    {
//                        try
//                        {
                            fileName = String.Empty;
                            fileName = DisasterCodeListFile.Write(disasterList);
//                            bandlGate.AuditListReceive(disasterList.Account, disasterList.Name, disasterList.Items.Length, fileName, 1);
//                        }
//                        catch (Exception e)
//                        {
//                            try
//                            {
//                                bandlGate.AuditListReceive(disasterList.Account, disasterList.Name, disasterList.Items.Length, e.Message, 0);
//                            }
//                            catch
//                            {
//                                ;
//                            }
//                            finally
//                            {
//                                throw;
//                            }
//                        }
                    }
                }
                finally
                {
                    m.ReleaseMutex();
                }
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Gets a hash of the inventory file for the given account
        /// </summary>
        /// <param name="account">
        /// Account for which to get inventory
        /// </param>
        /// <returns>
        /// Hash of the inventory file
        /// </returns>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Retrieves the hash of the inventory file for the given account.")]
        public byte[] GetInventoryFileHash(string account)
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();
            // Verify that the account belongs to the global
            if (ticketHeader.Account != account)
                if (false == SQLServer.VerifyServiceAccount(account, ticketHeader.Account))
                    throw new ApplicationException("Service account does not exist under global account");
            // Get the inventory file attributes
            try
            {
                return InventoryFile.GetFileHash(account);
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
            }
        }

        /// <summary>
        /// Retrieves the inventory for the given account
        /// </summary>
        /// <param name="accountName">
        /// Account for which to retrieve inventory
        /// </param>
        /// <param name="createDate">
        /// Date of inventory sought
        /// </param>
        [SoapHeader("ticketHeader",Direction=SoapHeaderDirection.In)]
        [WebMethod(Description="Retrieves the inventory for the given account.")]
        public InventoryDetails DownloadInventory(string account)
        {
            // Authenticate the ticket in the SOAP header
            AuthenticateTicket();
            // Verify that the account belongs to the global
            if (ticketHeader.Account != account)
                if (false == SQLServer.VerifyServiceAccount(account, ticketHeader.Account))
                    throw new ApplicationException("Service account does not exist under global account");
            // Get the inventory
            try 
            {
                return InventoryFile.Read(account);
            }
            catch (Exception e)
            {
                throw CreateSoapException(e);
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
            // Decrypt the string using same key and vector as in product gateway

            // Initial password should be 32 characters long
            if (password.Length != 32) return false;
            // Remove the 20th, 31th, 68th, 83rd characters
            int chkTwo = Convert.ToInt32(password[26].ToString());
            int chkSix = Convert.ToInt32(password[14].ToString());
            int chkFive = Convert.ToInt32(password[9].ToString());
            int chkNine = Convert.ToInt32(password[8].ToString());
            password = password.Remove(26,1);
            password = password.Remove(14,1);
            password = password.Remove(9,1);
            password = password.Remove(8,1);
            // Add the UTF-8 values of the rest of the characters
            int total = 0;
            foreach(char c in password)
                total += Convert.ToInt32(c.ToString());
            // Check the nine checksum
            if (false == Convert.ToString(total + chkNine).EndsWith("9")) 
                return false;
            // Check the five checksum
            if (false == Convert.ToString(total + chkFive).EndsWith("5")) 
                return false;
            // Check the six checksum
            if (false == Convert.ToString(total + chkSix).EndsWith("6")) 
                return false;
            // Check the two checksum
            if (false == Convert.ToString(total + chkTwo).EndsWith("2")) 
                return false;
            // Password is valid
            return true;
        }

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
            else if (e is FileNotFoundException)
                return new SoapException(e.Message, new XmlQualifiedName("Client.FileName"));
            else 
                return new SoapException(e.Message, SoapException.ServerFaultCode);
        }
    }
}
