using System;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Service.VaultLedger.Recall.Gateway.Bandl
{
	/// <summary>
	/// Summary description for BandlGateway.
	/// </summary>
	public class BandlGateway
	{
        public BandlGateway() {}

        /// <summary>
        /// Sends an audit record to the B&L web service
        /// </summary>
        /// <param name="accountNo">Account number of the list</param>
        /// <param name="listName">Name of the list</param>
        /// <param name="numItems">Number of items on the list</param>
        /// <param name="fileName">Name of file written</param>
        /// <param name="status">Status of the transmission (1 = success, o = failure)</param>
        public void AuditListReceive(string accountNo, string listName, int numItems, string fileName, int status)
        {
            // Create method header for B&L web service
            Bandl.MethodHeader methodHeader = new Bandl.MethodHeader();
            methodHeader.AccountNo = "pl4st1c";
            methodHeader.AccountType = -400;
            // The password should be today's date in yyyy-mm-dd hh:mm:ss
            // format, encrypted and converted to base64.  Difference from
            // actual time may be 24 hours each way, due to potential 
            // international date differences.
            string dateString = DateTime.Now.ToString("yyyy-MM-dd hh:mm:ss");
            methodHeader.Password = Convert.ToBase64String(Balance.Inter(dateString));
            // Transmit audit record to the web service
            Bandl.BandlService proxy = new Bandl.BandlService();
            proxy.MethodHeaderValue = methodHeader;
            proxy.Credentials = System.Net.CredentialCache.DefaultCredentials;
            proxy.AuditListXmitReceive(accountNo, 1, DateTime.Now, listName, numItems, status, fileName);
        }
	}
}
