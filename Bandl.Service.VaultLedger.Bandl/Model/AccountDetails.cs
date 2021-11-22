using System;
using System.Data;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
    public enum AccountTypes 
    {
        Bandl = 0, 
        Recall = 1,
        Imation = 2
    }

    /// <summary>
    /// Summary description for AccountDetails.
    /// </summary>
    public class AccountDetails
    {
        private int id;
        private string company;
        private string contact;
        private string phoneNo;
        private string email;
        private string password;
        private string salt;
        private string accountNo;
        private AccountTypes accountType;
        private bool allowDynamic;
        private DateTime lastContact;
        private string subscription;

        public AccountDetails(string _company, string _contact, string _phoneNo, string _email, string _accountNo, AccountTypes _accountType)
        {
            id = 0;
            company = _company;
            contact = _contact;
            phoneNo = _phoneNo;
            email = _email;
            password = String.Empty;
            salt = String.Empty;
            accountNo = _accountNo;
            accountType = _accountType;
            allowDynamic = true;
            lastContact = new DateTime(1900, 1, 1);
            subscription = String.Empty;
        }

        public AccountDetails(IDataReader reader)
        {
            id = reader.GetInt32(0);
            company = reader.GetString(1);
            contact = reader.GetString(2);
            phoneNo = reader.GetString(3);
            email = reader.GetString(4);
            password = reader.GetString(5);
            salt = reader.GetString(6);
            accountNo = reader.GetString(7);
            accountType = (AccountTypes)reader.GetInt32(8);
            allowDynamic = reader.GetBoolean(9);
            lastContact = reader.GetDateTime(10);
            subscription = reader.GetString(11);
        }

        public int Id
        {
            get {return id;}
        }

        public string AccountNo
        {
            get {return accountNo;}
        }

        public string Company
        {
            get {return company;}
            set {company = value;}
        }

        public string Contact
        {
            get {return contact;}
        }

        public string PhoneNo
        {
            get {return phoneNo;}
        }

        public string Email
        {
            get {return email;}
        }

        public DateTime LastContact
        {
            get {return lastContact;}
            set {lastContact = value;}
        }

        public string Subscription
        {
            get {return subscription;}
        }

        public string Password
        {
            get {return password;}
            set 
            {
                allowDynamic = false;
                salt = PwordHasher.CreateSalt(5);
                password = PwordHasher.HashPasswordAndSalt(value, salt);
            }
        }

        public string Salt
        {
            get {return salt;}
        }

        public bool AllowDynamic
        {
            get {return allowDynamic;}
            set {allowDynamic = value;}
        }

        public AccountTypes AccountType
        {
            get {return accountType;}
        }

    }
}
