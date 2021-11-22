using System;
using System.Text;
using System.Threading;
using System.Collections;
using System.Text.RegularExpressions;
using System.Collections.Specialized;
using System.Web.Services.Protocols;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Router;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Gateway.Bandl;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Gateway.Recall
{
    /// <summary>
    /// Summary description for Gateway.
    /// </summary>
    public class RecallGateway
    {
        // Field indicating whether or not we have attempted a ticekt request.
        // In each method that accesses the web service (excepting the method
        // that itself requests authentication tickets), if an authentication
        // failure occurs we will make one attempt to request a new ticket.
        private bool RequestAttempted = false;
        private bool LicensePresent = false;

        // public constructor
        public RecallGateway() {}

        // Global account property
        private string GlobalAccount
        {
            get
            {
                if (!Configurator.Router)
                {
                    return Configurator.GlobalAccount;
                }
                else
                {
                    int accountType;
                    string accountNo;
                    string login = Thread.CurrentPrincipal.Identity.Name;
                    RouterDb.GetAccount(login, out accountNo, out accountType);
                    return accountNo;
                }
            }
        }

		#region Type Collections
		private MediumTypeCollection caseTypes = null;
		private MediumTypeCollection mediumTypes = null;

		private MediumTypeCollection CaseTypes
		{
			get
			{
				if (caseTypes == null)
				{
					caseTypes = ((IMediumType)MediumTypeFactory.Create()).GetMediumTypes(true);
				}
				// Return the media codes
				return caseTypes;
			}
		}

		private MediumTypeCollection MediumTypes
		{
			get
			{
				if (mediumTypes == null)
				{
					mediumTypes = ((IMediumType)MediumTypeFactory.Create()).GetMediumTypes(false);
				}
				// Return the media codes
				return mediumTypes;
			}
		}

		#endregion

        /// <summary>
        /// Makes initial contact with the request web service.  In doing so,
        /// gets an authentication ticket to use with future requests.
        /// </summary>
        public void RequestAuthenticationTicket()
        {
            try
            {
                // Initialize
                RequestAttempted = true;
                bool dynamicGeneration = false;
                string password = ReadPassword();
                // If we have a password in the configuration file, then use that.  Otherwise,
                // generate a new password.
                if (password == String.Empty)
                {
                    dynamicGeneration = true;
                    password = GeneratePword();
                }
                // Send to web service
                Recall.RecallService remoteProxy = new Recall.RecallService();
                Guid ticket = remoteProxy.RequestTicket(GlobalAccount, password);
                // If sucessful and dynamically generated, encrypt and write to configuration file
                if (dynamicGeneration == true) WritePassword(password);
                // Place the ticket in the database
                IOperator dal = (IOperator)OperatorFactory.Create();
                dal.InsertRecallTicket(Thread.CurrentPrincipal.Identity.Name, ticket);
            }
            catch (SoapException e)
            {
                HandleSoapException(e);
            }
        }

        
        /// <summary>
        /// Retrieves the accounts from the web service
        /// </summary>
        /// <returns>
        /// Collection of accounts
        /// </returns>
        public AccountCollection RetrieveAccounts()
        {
            try
            {
                Recall.AccountDetails[] remoteAccounts = null;
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                remoteProxy.TicketHeaderValue = GetTicketHeader();
                // Get the accounts from the web service
                try
                {
                    remoteAccounts = remoteProxy.RetrieveAccounts();
                }
                catch(SoapException e)
                {
                    if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                        throw;
                    else
                    {
                        RequestAuthenticationTicket();
                        remoteProxy.TicketHeaderValue = GetTicketHeader();
                        remoteAccounts = remoteProxy.RetrieveAccounts();
                    }
                }
                // Transfer the remote accounts to a collection to return
                ArrayList returnAccounts = new ArrayList(remoteAccounts.Length);
                for(int i = 0; i < remoteAccounts.Length; i++)
                {
                    Model.AccountDetails newAccount = new Model.AccountDetails(remoteAccounts[i].Name,remoteAccounts[i].Primary,remoteAccounts[i].Address1,remoteAccounts[i].Address2,remoteAccounts[i].City,remoteAccounts[i].State,remoteAccounts[i].ZipCode,remoteAccounts[i].Country,remoteAccounts[i].Contact,remoteAccounts[i].PhoneNo,remoteAccounts[i].Email,String.Empty);
                    returnAccounts.Add(newAccount);
                }
                // Return a collection of the remote accounts
                return new AccountCollection(returnAccounts);
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return null;    // Unreachable: HandleSoapException always throws exception
            }
        }


        /// <summary>
        /// Retrieves the medium types from the web service
        /// </summary>
        /// <returns>
        /// True on success, else false
        /// </returns>
        public MediumTypeCollection RetrieveMediumTypes()
        {
            try
            {
                Recall.MediumTypeDetails[] remoteTypes = null;
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                remoteProxy.TicketHeaderValue = GetTicketHeader();
                // Get the accounts from the web service
                try
                {
                    remoteTypes = remoteProxy.RetrieveMediumTypes();
                }
                catch(SoapException e)
                {
                    if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                        throw;
                    else
                    {
                        RequestAuthenticationTicket();
                        remoteProxy.TicketHeaderValue = GetTicketHeader();
                        remoteTypes = remoteProxy.RetrieveMediumTypes();
                    }
                }
                // Transfer the remote accounts to a collection to return
                ArrayList returnTypes = new ArrayList(remoteTypes.Length);
                for(int i = 0; i < remoteTypes.Length; i++)
                {
                    Model.MediumTypeDetails newType = new Model.MediumTypeDetails(remoteTypes[i].TypeName,remoteTypes[i].TwoSided,remoteTypes[i].Container,remoteTypes[i].RecallCode);
                    returnTypes.Add(newType);
                }
                // Return a collection of the remote accounts
                return new MediumTypeCollection(returnTypes);
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return null;    // Unreachable: HandleSoapException always throws exception
            }
        }

        /// <summary>
        /// Creates a remote send list from a local send list
        /// </summary>
        /// <param name="sendList">
        /// List to transform
        /// </param>
        /// <returns>
        /// Remote list details object
        /// </returns>
        private Recall.RMMSendListDetails TransformSendList(SendListDetails sendList)
        {
			ArrayList remoteItems = new ArrayList();
			IMedium mediumDAL = (IMedium)MediumFactory.Create();
			StringCollection sealedCases = new StringCollection();
			// Loop through the sealed cases, creating a line for each
			foreach (SendListCaseDetails c in sendList.ListCases)
			{
				if (c.Sealed == true)
				{
					// Add the sealed case name to the array list so that we may check
					// for it later when we're adding individual media.  If a medium is
					// in a sealed case, then that medium should not be written to the file.
					sealedCases.Add(c.Name);
					// Create a new remote send list item
					Recall.RMMSendItem ri = new Recall.RMMSendItem();
					ri.SerialNo = c.Name;
					ri.MediaCode = CaseTypes.Find(c.Type,true).RecallCode;
					ri.Description = c.Notes;
					ri.DrpCode = String.Empty;
                    ri.ReturnDate = c.ReturnDate.Length != 0 ? Date.ParseExact(c.ReturnDate).ToString("MM/dd/yyyy") : String.Empty;
					// Add the item to the collection
					remoteItems.Add(ri);
				}
			}
			// Now go through the media, ignoring those in sealed cases
			foreach (SendListItemDetails si in sendList.ListItems)
			{
                // If the item has been removed, or if the medium is in
                // on of the sealed cases, go to the next record.
                if (si.Status == SLIStatus.Removed)
                {
                    continue;
                }
				else if (si.CaseName.Length != 0 && sealedCases.IndexOf(si.CaseName) != -1)
				{
					continue;
				}
                // Retrieve the medium so that we may retrieve its type
                MediumDetails m = mediumDAL.GetMedium(si.SerialNo);
				// Create a new remote send list item
				Recall.RMMSendItem ri = new Recall.RMMSendItem();
				ri.SerialNo = si.SerialNo;
				ri.MediaCode = MediumTypes.Find(m.MediumType,false).RecallCode;
				ri.Description = m.Notes;   // Use the notes from the medium (should be same as send list item notes as of 5/20/2005)
				ri.DrpCode = String.Empty;
                ri.ReturnDate = si.ReturnDate.Length != 0 ? Date.ParseExact(si.ReturnDate).ToString("MM/dd/yyyy") : String.Empty;
				// Add the item to the collection
				remoteItems.Add(ri);
			}
			// Create the remote send list
			Recall.RMMSendListDetails remoteList = new Recall.RMMSendListDetails();
			remoteList.Name = sendList.Name;
			remoteList.Account = sendList.Account;
			remoteList.CreateDate = sendList.CreateDate.ToString("MM/dd/yyyy");
			remoteList.Items = (Recall.RMMSendItem[])remoteItems.ToArray(typeof(Recall.RMMSendItem));
			// Return the remote send list
			return remoteList;
        }

       
        /// <summary>
        /// Transmits a send list to the server
        /// </summary>
        /// <param name="sendList">
        /// List to transmit
        /// </param>
        /// <returns>
        /// True on success, else false
        /// </returns>
        public bool TransmitSendList(SendListDetails sendList)
        {
            // Composite lists are not allowed
            if (sendList.IsComposite)
                throw new ApplicationException("Composite lists may not be transmitted.");
            // Create an array of remote receive details objects from the
            // given collection.  We have a collection here because in the
            // beginning we allowed the transmission of multiple discrete
            // lists at once.  This is no longer allowed, but leaving the
            // ArrayList is easier than changing the web service interface.
            ArrayList xmitLists = new ArrayList();
            xmitLists.Add(TransformSendList(sendList));
            // Create an array from the array list
            Recall.RMMSendListDetails[] remoteLists = 
                (Recall.RMMSendListDetails[])xmitLists.ToArray(typeof(Recall.RMMSendListDetails));
            // Transmit the array to the web service
            try
            {
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                // Two chances to transmit lists.  Second chance only when
                // first chance resulted in an authentication exception.
                while (true)
                {
                    try
                    {
                        // Transmit the send list
                        try
                        {
                            remoteProxy.TicketHeaderValue = GetTicketHeader();
                            remoteProxy.TransmitSendLists(remoteLists);
                            // Return success
                            return true;
                        }
                        catch //(Exception e)
                        {
//                            new BandlGateway().AuditListXmit(DateTime.UtcNow, sendList.Name, sendList.ListItems.Length, 0, e.Message);
                            throw;
                        }
                    }
                    catch (SoapException e)
                    {
                        if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            RequestAuthenticationTicket();
                    }
                }
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return false;
            }
        }


        /// <summary>
        /// Creates a remote receive list from a local receive list
        /// </summary>
        /// <param name="receiveList">
        /// List to transform
        /// </param>
        /// <returns>
        /// Remote list details object
        /// </returns>
        private Recall.RMMReceiveListDetails TransformReceiveList(ReceiveListDetails receiveList)
        {
			ArrayList remoteItems = new ArrayList();
			IMedium mediumDAL = (IMedium)MediumFactory.Create();
			StringCollection doneCases = new StringCollection();
			ISealedCase caseDAL = (ISealedCase)SealedCaseFactory.Create();
			foreach(ReceiveListItemDetails receiveItem in receiveList.ListItems)
			{
				bool caseDone = false;
                // If the item has been removed, go to the next record
                if (receiveItem.Status != RLIStatus.Removed)
                {
                    // If there's a case, check to see if it's already been accounted
                    // for.  If it has, skip the entry; otherwise add the case to the
                    // file contents.  If there is no case, just add the medium
                    if (receiveItem.CaseName.Length != 0)
                    {
                        foreach (string caseName in doneCases)
                        {
                            if (receiveItem.CaseName == caseName)
                            {
                                caseDone = true;
                                break;
                            }
                        }
                        // If case not already processed, add it
                        if (caseDone == false)
                        {
                            doneCases.Add(receiveItem.CaseName);
                            SealedCaseDetails sealedCase = caseDAL.GetSealedCase(receiveItem.CaseName);
                            // Create a new remote list item
                            Recall.RMMReceiveItem remoteItem = new Recall.RMMReceiveItem();
                            remoteItem.MediaCode = CaseTypes.Find(sealedCase.CaseType,true).RecallCode;
                            remoteItem.SerialNo = sealedCase.CaseName;
                            // Add to the remote item collection
                            remoteItems.Add(remoteItem);
                        }
                    }
                    else
                    {
                        MediumDetails medium = mediumDAL.GetMedium(receiveItem.SerialNo);
                        // Create a new remote list item
                        Recall.RMMReceiveItem remoteItem = new Recall.RMMReceiveItem();
                        remoteItem.MediaCode = MediumTypes.Find(medium.MediumType,false).RecallCode;
                        remoteItem.SerialNo = medium.SerialNo;
                        // Add to the remote item collection
                        remoteItems.Add(remoteItem);
                    }
                }
			}
			// Create a new remote list object
			Recall.RMMReceiveListDetails remoteList = new Recall.RMMReceiveListDetails();
			remoteList.Name = receiveList.Name;
			remoteList.Account = receiveList.Account;
			remoteList.CreateDate = receiveList.CreateDate.ToString("MM/dd/yyyy");
			remoteList.Items = (Recall.RMMReceiveItem[])remoteItems.ToArray(typeof(Recall.RMMReceiveItem));
			// Return the remote list
			return remoteList;
        }


        /// <summary>
        /// Transmits a receive lists to the server
        /// </summary>
        /// <param name="receiveList">
        /// List to transmit
        /// </param>
        /// <returns>
        /// True on success, else false
        /// </returns>
        public bool TransmitReceiveList(ReceiveListDetails receiveList)
        {
            // Composite lists are not allowed
            if (receiveList.IsComposite) 
                throw new ApplicationException("Composite lists may not be transmitted.");
            // Create an array of remote receive details objects from the
            // given collection.  We have a collection here because in the
            // beginning we allowed the transmission of multiple discrete
            // lists at once.  This is no longer allowed, but leaving the
            // ArrayList is easier than changing the web service interface.
            ArrayList xmitLists = new ArrayList();
            xmitLists.Add(TransformReceiveList(receiveList));
            // Create an array from the array list
            Recall.RMMReceiveListDetails[] remoteLists = 
                (Recall.RMMReceiveListDetails[])xmitLists.ToArray(typeof(Recall.RMMReceiveListDetails));
            // Transmit the array of lists to the web service
            try
            {
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                // Two chances to transmit lists.  Second chance only when
                // first chance resulted in an authentication exception.
                while (true)
                {
                    try
                    {
                        try
                        {
                            remoteProxy.TicketHeaderValue = GetTicketHeader();
                            remoteProxy.TransmitReceiveLists(remoteLists);
                            // Return success
                            return true;
                        }
                        catch //(Exception e)
                        {
//                            new BandlGateway().AuditListXmit(DateTime.UtcNow, receiveList.Name, receiveList.ListItems.Length, 0, e.Message);
                            throw;
                        }
                    }
                    catch (SoapException e)
                    {
                        if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            RequestAuthenticationTicket();
                    }
                }
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return false;
            }
        }


        /// <summary>
        /// Creates a remote disaster code list from a local disaster code list
        /// </summary>
        /// <param name="disasterCodeList">
        /// List to transform
        /// </param>
        /// <returns>
        /// Remote list details object
        /// </returns>
        private Recall.RMMDisasterCodeListDetails TransformDisasterCodeList(DisasterCodeListDetails dcl)
        {
			IMedium mdal = (IMedium)MediumFactory.Create();
			ISealedCase cdal = (ISealedCase)SealedCaseFactory.Create();
            // Create an array list to hold processed cases
            ArrayList cp = new ArrayList();
            // Create an arraylist to hold the remote list items
			ArrayList ri = new ArrayList(dcl.ListItems.Length);
			// Run through the disaster items, creating remote list items
			foreach(DisasterCodeListItemDetails di in dcl.ListItems)
			{
                // If the item has been removed, go to the next record
                if (di.Status != DLIStatus.Removed)
                {
                    // Create new remote item
                    Recall.RMMDisasterCodeItem r = new Recall.RMMDisasterCodeItem();
                    // If the medium is not in a case, create a new item with that medium.  If
                    // it is in a sealed case and that case has not yet been accounted for,
                    // create an item for the sealed case.
                    if (di.CaseName.Length == 0)
                    {
                        r.SerialNo = di.SerialNo;
                        r.DrpCode = di.Code;
                        r.MediaCode = MediumTypes.Find(mdal.GetMedium(di.SerialNo).MediumType,false).RecallCode;
                    }
                    else
                    {
                        int i = -1;
                        // Attempt to find the case
                        for (i = 0; i < cp.Count; i++)
                            if ((string)cp[i] == di.CaseName)
                                break;
                        // If not found, add to the arraylist and create a remote item
                        if (i == cp.Count)
                        {
                            cp.Add(di.CaseName);
                            r.SerialNo = di.CaseName;
                            r.DrpCode = di.Code;
                            r.MediaCode = CaseTypes.Find(cdal.GetSealedCase(di.CaseName).CaseType,true).RecallCode;
                        }
                    }
                    // Add the item to the array list
                    ri.Add(r);
                }
			}
			// Create a new list object
			Recall.RMMDisasterCodeListDetails rl = new Recall.RMMDisasterCodeListDetails();
			rl.Name = dcl.Name;
			rl.Account = dcl.Account;
			rl.CreateDate = dcl.CreateDate.ToString("MM/dd/yyyy");
			rl.Items = (Recall.RMMDisasterCodeItem[])ri.ToArray(typeof(Recall.RMMDisasterCodeItem));
			// Return the remote list
			return rl;
        }

    
        /// <summary>
        /// Transmits a disaster code list to the server
        /// </summary>
        /// <param name="disasterCodeLists">
        /// Collection of lists to transmit
        /// </param>
        /// <returns>
        /// True on success, else false
        /// </returns>
        public bool TransmitDisasterCodeList(DisasterCodeListDetails disasterList)
        {
            // Composite lists are not allowed
            if (disasterList.IsComposite) 
                throw new ApplicationException("Composite lists may not be transmitted.");
            // Create an array of remote receive details objects from the
            // given collection.  We have a collection here because in the
            // beginning we allowed the transmission of multiple discrete
            // lists at once.  This is no longer allowed, but leaving the
            // ArrayList is easier than changing the web service interface.
            ArrayList xmitLists = new ArrayList();
            xmitLists.Add(TransformDisasterCodeList(disasterList));
            // Create an array from the array list
            Recall.RMMDisasterCodeListDetails[] remoteLists = 
                (Recall.RMMDisasterCodeListDetails[])xmitLists.ToArray(typeof(Recall.RMMDisasterCodeListDetails));
            // Transmit the array of lists to the web service
            try
            {
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                // Two chances to transmit lists.  Second chance only when
                // first chance resulted in an authentication exception.
                while (true)
                {
                    try
                    {
                        try
                        {
                            remoteProxy.TicketHeaderValue = GetTicketHeader();
                            remoteProxy.TransmitDisasterCodeLists(remoteLists);
                            // Return success
                            return true;
                        }
                        catch //(Exception e)
                        {
//                            new BandlGateway().AuditListXmit(DateTime.UtcNow, disasterList.Name, disasterList.ListItems.Length, 0, e.Message);
                            throw;
                        }
                    }
                    catch (SoapException e)
                    {
                        if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            RequestAuthenticationTicket();
                    }
                }
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return false;
            }
        }

        
        /// <summary>
        /// Gets the inventory file attributes of size and last write time
        /// </summary>
        /// <param name="account">
        /// Account for which to get inventory
        /// </param>
        /// <returns>
        /// Hash of the inventory file on the server, null if file 
        /// does not exist
        /// </returns>
        public byte[] GetInventoryFileHash(string account)
        {
            try
            {
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                // Get the file attributes from the web service
                while (true)
                {
                    try
                    {
                        remoteProxy.TicketHeaderValue = GetTicketHeader();
                        return remoteProxy.GetInventoryFileHash(account);
                    }
                    catch(SoapException e)
                    {
                        if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            RequestAuthenticationTicket();
                    }
                }
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return null;
            }
        }


        /// <summary>
        /// Downloads the inventory for a particular account from the web service
        /// </summary>
        /// <param name="account">
        /// Account for which to download inventory
        /// </param>
        /// <returns>
        /// Returns the number of items in the downloaded inventory
        /// </returns>
        public int DownloadInventory(string account)
        {
            try
            {
                // Create the proxy and instantiate a new ticket soap header
                Recall.RecallService remoteProxy = new Recall.RecallService();
                // Two chances to download inventory.  Second chance only when
                // first chance resulted in an authentication exception.
                while (true)
                {
                    try
                    {
                        remoteProxy.TicketHeaderValue = GetTicketHeader();
                        Recall.InventoryDetails inventory = remoteProxy.DownloadInventory(account);
                        ArrayList ii = new ArrayList(inventory.Items.Length);
                        // Get the medium types
                        IMediumType dalM = (IMediumType)MediumTypeFactory.Create();
                        MediumTypeCollection mediumTypes = dalM.GetMediumTypes();
                        // Add entries to arrays
                        foreach(Recall.InventoryItem i in inventory.Items)
                        {   
                            InventoryItemDetails ni = null;
                            foreach(Model.MediumTypeDetails medType in mediumTypes)
                            {
                                if (i.TypeCode == medType.RecallCode)
                                {
                                    // Adjust the return date.  Recall return dates are always in MM/dd/yyyy 
                                    // format.  We need to switch it to the yyyy-MM-dd format.
                                    string rd = i.ReturnDate.Length != 0 ? DateTime.ParseExact(i.ReturnDate, "MM/dd/yyyy", null).ToString("yyyy-MM-dd") : String.Empty;
                                    // Create the inventory item and add it to the list
                                    ii.Add(ni = new InventoryItemDetails(i.SerialNo, medType.Name, i.HotStatus, rd, i.Description));
                                    // Break the loop
                                    break;
                                }
                            }
                            // If medium type was unrecognized, throw exception
                            if (ni == null) throw new ApplicationException(String.Format("Unrecognized medium type ({0}) in remote inventory item.  Serial number {1}.", i.TypeCode, i.SerialNo));
                        }
                        // Add inventory to the database
                        InventoryFactory.Create().InsertInventory(account, Locations.Vault, inventory.HashCode, (InventoryItemDetails[])ii.ToArray(typeof(InventoryItemDetails)));
                        // Return the number of items in the inventory
                        return inventory.Items.Length;

                    }
                    catch (SoapException e)
                    {
                        if (RequestAttempted || e.Code.ToString() != "Client.Authentication")
                            throw;
                        else
                            RequestAuthenticationTicket();
                    }
                    catch (InvalidOperationException e)
                    {
                        Exception x = e.InnerException;
                        string m = e.Message + String.Format(" (Account: {0}).", account);
                        while (x != null) {m += " " + x.Message; x = x.InnerException;}
                        throw new InvalidOperationException(m);
                    }
                }
            }
            catch(SoapException e)
            {
                HandleSoapException(e);
                return 0;
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
            pwdBuilder.Insert(8, Convert.ToString((19 - total % 10) % 10));
            pwdBuilder.Insert(9, Convert.ToString((15 - total % 10) % 10));
            pwdBuilder.Insert(14, Convert.ToString((16 - total % 10) % 10));
            pwdBuilder.Insert(26, Convert.ToString((12 - total % 10) % 10));
            // Encrypt and convert to string
            return pwdBuilder.ToString();
        }

        
        /// <summary>
        /// Creates and populates a new ticket header
        /// </summary>
        /// <returns>
        /// Ticket header
        /// </returns>
        private Recall.TicketHeader GetTicketHeader()
        {
            // Create a new ticket
            Recall.TicketHeader newTicket = new Recall.TicketHeader();
            // Populate the ticket soap header
            newTicket.Account = GlobalAccount;
            newTicket.Ticket = GetOperatorTicket();
            // Return the ticket
            return newTicket;
        }


        /// <summary>
        /// Gets the authentication ticket for the current operator
        /// </summary>
        /// <returns>
        /// Authentication ticket
        /// </returns>
        private Guid GetOperatorTicket()
        {
            IOperator dal = (IOperator)OperatorFactory.Create();
            return dal.GetRecallTicket(Thread.CurrentPrincipal.Identity.Name);        
        }
        

        /// <summary>
        /// Soap exception handler
        /// </summary>
        /// <param name="e">
        /// Soap exception
        /// </param>
        private void HandleSoapException(SoapException e)
        {
            // Three possible fault codes: Client.Authentication, Server.Database, ServerFaultCode
            throw new ApplicationException("[FaultCode:" + e.Code.ToString() + "]" + e.Message);
        }

        private string ReadPassword()
        {
            // Get the value from the database
            IProductLicense dal = ProductLicenseFactory.Create();
            ProductLicenseDetails pld = dal.GetProductLicense(LicenseTypes.Recall);
            if (pld == null) return String.Empty;
            // Decrypt the string
            LicensePresent = true;
            return Crypto.Decrypt(pld.Value, pld.Ray);
        }

        private void WritePassword(string password)
        {
            // Encrypt string with default key, newly created vector
            byte[] r = new byte[16];
            byte[] p = Crypto.Encrypt(password, out r);
            ProductLicenseDetails pld = new ProductLicenseDetails(LicenseTypes.Recall, p, r); 
            // Insert into database
            IProductLicense dal = ProductLicenseFactory.Create();
            if (false == LicensePresent)
                dal.Insert(pld);
            else 
                dal.Update(pld);
        }
    }
}
