using System;
using System.Web.Services.Protocols;

namespace Bandl.Service.VaultLedger.Recall.Model
{
	/// <summary>
	/// Represents the content of the SOAP header used to secure the XML web
	/// service.  It carries authentication tickets from client to server.
	/// </summary>
	public class TicketHeader : SoapHeader
	{
        public string Account;
        public Guid Ticket;

        public TicketHeader() : this(String.Empty,Guid.Empty) {}

        public TicketHeader(string account, Guid ticket)
		{
            Account = account;
            Ticket = ticket;
		}
	}
}
