using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Business entity used to model an Account
    /// </summary>
    [Serializable]
    public class AccountDetails : Details
    {
        // Internal member variables
        private int id;
        private string name;
        private bool primary;
        private string address1;
        private string address2;
        private string city;
        private string state;
        private string zipCode;
        private string country;
        private string contact;
        private string phoneNo;
        private string email;
        private string notes;
        private string ftpProfile;
        private byte[] rowVersion = new byte[8];
        
        /// <summary>
        /// Constructor initializes new account manually
        /// </summary>
        public AccountDetails(string _name, bool _primary, string _address1, 
            string _address2, string _city, string _state, string _zipCode, 
            string _country, string _contact, string _phoneNo, string _email, 
            string _notes, string _ftpProfile)
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
            Notes = _notes;
            FtpProfile = _ftpProfile;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }
        // Another manual constructor
        public AccountDetails(string _name, bool _primary, string _address1, string _address2,
            string _city, string _state, string _zipCode, string _country, string _contact, 
            string _phoneNo, string _email, string _notes) : this (_name, _primary, _address1, 
            _address2, _city, _state, _zipCode, _country, _contact, _phoneNo, _email, _notes, String.Empty) {}
        /// <summary>
        /// Constructor initializes new account using the data in a IDataReader
        /// </summary>
        public AccountDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("AccountId"));
            name = reader.GetString(reader.GetOrdinal("AccountName"));
            primary = reader.GetBoolean(reader.GetOrdinal("Global"));
            address1 = reader.GetString(reader.GetOrdinal("Address1"));
            address2 = reader.GetString(reader.GetOrdinal("Address2"));
            city = reader.GetString(reader.GetOrdinal("City"));
            state = reader.GetString(reader.GetOrdinal("State"));
            zipCode = reader.GetString(reader.GetOrdinal("ZipCode"));
            country = reader.GetString(reader.GetOrdinal("Country"));
            contact = reader.GetString(reader.GetOrdinal("Contact"));
            phoneNo = reader.GetString(reader.GetOrdinal("PhoneNo"));
            email = reader.GetString(reader.GetOrdinal("Email"));
            notes = reader.GetString(reader.GetOrdinal("Notes"));
            ftpProfile = reader.GetString(reader.GetOrdinal("FtpProfile"));
            reader.GetBytes(reader.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Set row state to unmodified
            this.ObjState = ObjectStates.Unmodified;
        }

        // Properties
        public int Id
        {
            get { return id; }
        }
        public string Name
        {
            get { return name; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Name", "Account name is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Name", "Account name may not be more than 256 characters in length.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("Name", "Account name may only consist of alphanumeric characters");
                // Set account name
                name = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public bool Primary
        {
            get { return primary; }
            set 
            { 
                // Set primary flag
                primary = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Address1
        {
            get { return address1; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Address1", "Address (line 1) is a required field.");
                else if (value.Length > 256)
                    throw new ValueLengthException("Address1", "Each line of the address may not be more than 256 characters in length.");
                // Set address
                address1 = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Address2
        {
            get { return address2; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 256)
                    throw new ValueLengthException("Address2", "Each line of the address may not be more than 256 characters in length.");
                // Set address
                address2 = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string City
        {
            get { return city; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("City", "City is a required field.");
                else if (value.Length > 128)
                    throw new ValueLengthException("City", "City may not be more than 128 characters in length.");
                // Set city
                city = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string State
        {
            get { return state; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 128)
                    throw new ValueLengthException("State", "State may not be more than 128 characters in length.");
                // Set state
                state = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string ZipCode
        {
            get { return zipCode; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 32)
                    throw new ValueLengthException("Zip Code", "Zip code may not be more than 32 characters in length.");
                // Set zip code
                zipCode = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Country
        {
            get { return country; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Country", "Country is a required field.");
                else if (value.Length > 128)
                    throw new ValueLengthException("Country", "Country may not be more than 128 characters in length.");
                // Set country
                country = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Contact
        {
            get { return contact; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 256)
                    throw new ValueLengthException("Contact", "Contact name may not be more than 256 characters in length.");
                else if (false == new Regex(@"[a-zA-Z,\-'\.]*").IsMatch(value))
                    throw new ValueFormatException("Contact", "Contact name may only consist of letters, commas, hyphens, apostrophes, and periods.");
                // Set contact name
                contact = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string PhoneNo
        {
            get { return phoneNo; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 64)
                    throw new ValueLengthException("PhoneNo", "Phone number may not be more than 64 characters in length.");
                else if (value.Length > 0 && false == this.IsValidPhoneNo(value))
                    throw new ValueFormatException("PhoneNo", "Phone number is invalid.");
                // Set phone number
                phoneNo = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Email
        {
            get { return email; }
            set 
            {
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 256)
                    throw new ValueLengthException("Email", "Email address may not be more than 256 characters in length.");
                else if (value.Length > 0 && false == new Regex(@"^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$").IsMatch(value))
                    throw new ValueFormatException("Email", "Email address is of an invalid format.");
                // Set email
                email = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Notes
        {
            get { return notes; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 1000)
                    throw new ValueLengthException("Notes", "Notes may not be more than 1000 characters in length.");
                // Set notes
                notes = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string FtpProfile
        {
            get { return ftpProfile; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                // Set notes
                ftpProfile = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public byte[] RowVersion
        {
            get { return rowVersion; }
        }
    }
}
