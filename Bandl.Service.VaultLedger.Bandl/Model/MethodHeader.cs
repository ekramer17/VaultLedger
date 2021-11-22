using System;
using System.Web.Services.Protocols;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
    /// <summary>
    /// Represents the content of the SOAP header used to secure the XML web
    /// service.  It carries the client password.
    /// </summary>
    public class MethodHeader : SoapHeader
    {
        public string AccountNo;
        public string Password;
        public int AccountType;

        public MethodHeader() : this(0, String.Empty, String.Empty) {}

        public MethodHeader(int accountType, string account, string password)
        {
            Password = password;
            AccountNo = account;
            AccountType = accountType;
        }
    }
}
