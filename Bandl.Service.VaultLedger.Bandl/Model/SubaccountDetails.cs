using System;
using System.Data;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
    /// <summary>
    /// Summary description for Subaccount.
    /// </summary>
    public class SubaccountDetails
    {
        private int id;
        private string accountNo;

        public SubaccountDetails(string _accountNo)
        {
            id = 0;
            accountNo = _accountNo;
        }

        public SubaccountDetails(IDataReader r)
        {
            id = r.GetInt32(0);
            accountNo = r.GetString(1);
        }

        public int Id
        {
            get {return id;}
        }

        public string AccountNo
        {
            get {return accountNo;}
        }
    }
}
