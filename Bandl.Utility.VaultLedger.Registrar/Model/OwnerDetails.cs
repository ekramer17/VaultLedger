using System;
using System.Data;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
    [Serializable]
    public enum AccountTypes
    {
        Bandl = 0, 
        Recall = 1
    }

    /// <summary>
	/// Represents the client as he is known in the registrar database.  Is
	/// the "owner" of the client application database that is created in
	/// its name.  Otherwise may be known as the licensee.
	/// </summary>
	[Serializable]
	public class OwnerDetails : Details
	{
        private int id;
        private string company;
        private string address1;
        private string address2;
        private string city;
        private string state;
        private string zipCode;
        private string country;
        private string contact;
        private string phoneNo;
        private string email;
        private string accountNo;
        private AccountTypes accountType; // Recall only for now
        private string subscription;

        public OwnerDetails(string _company, string _address1, string _address2, string _city, string _state, string _zipCode, string _country, string _contact, string _phoneNo, string _email, string _accountNo, AccountTypes _accountType)
        {
            company = _company;
            address1 = _address1;
            address2 = _address2;
            city = _city;
            state = _state;
            zipCode = _zipCode;
            country = _country;
            contact = _contact;
            phoneNo = _phoneNo;
            email = _email;
            AccountNo = _accountNo;
            accountType = _accountType;
            subscription = String.Empty;
            this.ObjState = ObjectStates.New;
        }

        public OwnerDetails(IDataReader r)
        {
            id = r.GetInt32(r.GetOrdinal("OwnerId"));
            company = r.GetString(r.GetOrdinal("Company"));
            address1 = r.GetString(r.GetOrdinal("Address1"));
            address2 = r.GetString(r.GetOrdinal("Address2"));
            city = r.GetString(r.GetOrdinal("City"));
            state = r.GetString(r.GetOrdinal("State"));
            zipCode = r.GetString(r.GetOrdinal("ZipCode"));
            country = r.GetString(r.GetOrdinal("Country"));
            contact = r.GetString(r.GetOrdinal("Contact"));
            phoneNo = r.GetString(r.GetOrdinal("PhoneNo"));
            email = r.GetString(r.GetOrdinal("Email"));
            accountNo = r.GetString(r.GetOrdinal("AccountNo"));
            accountType = (AccountTypes)Enum.ToObject(typeof(AccountTypes),r.GetInt32(r.GetOrdinal("AccountType")));
            // If subscription appears, get it
            if (r.GetSchemaTable().Columns.IndexOf("Subscription") != -1)
                subscription = r.GetString(r.GetOrdinal("Subscription"));
            // Set the object state
            this.ObjState = ObjectStates.Unmodified;
        }

        public int Id
        {
            get {return id;}
        }

        public string Company
        {
            get {return company;}
            set 
            {
                company = value;                 
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Address1
        {
            get {return address1;}
            set 
            {
                address1 = value; 
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Address2
        {
            get {return address2;}
            set 
            {
                address2 = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string City
        {
            get {return city;}
            set 
            {
                city = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string State
        {
            get {return state;}
            set 
            {
                state = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string ZipCode
        {
            get {return zipCode;}
            set 
            {
                zipCode = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Country
        {
            get {return country;}
            set 
            {
                country = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Contact
        {
            get {return contact;}
            set 
            {
                contact = value;                
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string PhoneNo
        {
            get {return phoneNo;}
            set 
            {
                phoneNo = value;                
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Email
        {
            get {return email;}
            set 
            {
                email = value;
                this.ObjState = ObjectStates.Modified;
            }
        }


        public string AccountNo
        {
            get {return accountNo;}
            set 
            {
                if (Configurator.ProductType == "RECALL" && (value == null || value == String.Empty))
                {
                    throw new ArgumentException("Account not supplied");
                }
                else
                {
                    accountNo = value;                
                    this.ObjState = ObjectStates.Modified;
                }
            }
        }

        public AccountTypes AccountType
        {
            get {return accountType;}
            set 
            {
                accountType = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Subscription
        {
            get {return subscription;}
            set {subscription = value;}
        }
    }
}
