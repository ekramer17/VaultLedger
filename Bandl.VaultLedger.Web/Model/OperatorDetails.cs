using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Business entity used to model an Operator
    /// </summary>
    [Serializable]
    public class OperatorDetails : Details
	{
        // Internal member variables
        private int id;
        private string login;
        private string password;
        private string salt;
        private string name;
        private int role;
        private string phoneNo;
        private string email;
        private string notes;
        private DateTime lastLogin;
        private byte[] rowVersion = new byte[8];
        
        /// <summary>
        /// Constructor initializes new operator manually
        /// </summary>
        public OperatorDetails(string _login, string _password, string _name, string _role, string _phoneNo, string _email, string _notes)
        {
            Login = _login;
            Password = _password;
            Name = _name;
            Role = _role;
            PhoneNo = _phoneNo;
            Email = _email;
            Notes = _notes;
            LastLogin = new DateTime(1900,1,1);
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new operator using the data in a IDataReader
        /// </summary>
        public OperatorDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("OperatorId"));
            login = reader.GetString(reader.GetOrdinal("Login"));
            password = reader.GetString(reader.GetOrdinal("Password"));
            salt = reader.GetString(reader.GetOrdinal("Salt"));
            name = reader.GetString(reader.GetOrdinal("OperatorName"));
            role = reader.GetInt32(reader.GetOrdinal("Role"));
            phoneNo = reader.GetString(reader.GetOrdinal("PhoneNo"));
            email = reader.GetString(reader.GetOrdinal("Email"));
            notes = reader.GetString(reader.GetOrdinal("Notes"));
            lastLogin = reader.GetDateTime(reader.GetOrdinal("LastLogin"));
            reader.GetBytes(reader.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Set row state to unmodified
            this.ObjState = ObjectStates.Unmodified;
        }

        // Properties
        public int Id
        {
            get { return id; }
        }
        public string Login
        {
            get { return login; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Login", "Login is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Login", "Login may not be more than 256 characters in length.");
                else if ("SYSTEM" == value.ToUpper() || "VAULTLEDGER" == value.ToUpper())
                    throw new ValueException("Login", "'" + value + "' is invalid as a login because it is a reserved word.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("Login", "Login may only consist of alphanumeric characters");
                // Set login
                login = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Password
        {
            get { return password; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Password", "Password is a required field.");
                else if (value.Length > 16 )
                    throw new ValueLengthException("Password", "Password may not be more than 16 characters in length.");
                // Create salt value, hash password
                salt = PwordHasher.CreateSalt(5);
                password = PwordHasher.HashPasswordAndSalt(value, salt);
                // Set object to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Name
        {
            get { return name; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 256)
                    throw new ValueLengthException("Name", "Operator name may not be more than 256 characters in length.");
                else if (false == new Regex(@"[a-zA-Z ,\-'\.]*").IsMatch(value))
                    throw new ValueFormatException("Name", "Operator name may only consist of letters, spaces, commas, hyphens, apostrophes, and periods.");
                // Set operator name
                name = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Role
        {
            get 
            { 
                return Enum.GetName(typeof(Role), role);
            }
            set
            {
                try 
                {
                    // Set role
                    role = (int)Enum.Parse(typeof(Role), value, true);
                    // Set object state to modified
                    this.ObjState = ObjectStates.Modified;
                }
                catch
                {
                    throw new ValueException("Role", "Security role '" + value + "' is invalid.");
                }
            }
        }
        public string Salt
        {
            get { return salt; }
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
        public DateTime LastLogin
        {
            get { return lastLogin; }
            set 
            { 
                lastLogin = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public byte[] RowVersion
        {
            get { return rowVersion; }
        }
    }
}
