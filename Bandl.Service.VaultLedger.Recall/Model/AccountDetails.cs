using System;

namespace Bandl.Service.VaultLedger.Recall.Model
{
    /// <summary>
    /// Business entity used to model an Account
    /// </summary>
    [Serializable]
    public class AccountDetails
    {
        // Internal member variables
        public string Name;
        public bool   Primary;
        public string Address1;
        public string Address2;
        public string City;
        public string State;
        public string ZipCode;
        public string Country;
        public string Contact;
        public string PhoneNo;
        public string Email;
        public string FilePath;
        
        // Public default contructor for serialization only
        public AccountDetails() {}
        
        /// <summary>
        /// Constructor initializes new account manually
        /// </summary>
        public AccountDetails(string _name, bool _primary, string _address1, string _address2, string _city, string _state, 
            string _zipCode, string _country, string _contact, string _phoneNo, string _email, string _filePath)
        {
            Name = _name;
            Primary = _primary;
            Address1 = _address1;
            Address2 = _address2;
            City = _city;
            State = _state;
            ZipCode = _zipCode;
            Country = _country;
            Contact = _contact;
            PhoneNo = _phoneNo;
            Email = _email;
            FilePath = _filePath;
        }
    }
}
