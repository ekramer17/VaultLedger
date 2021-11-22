using System;
using System.Data;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Business entity representing an FTP profile
	/// </summary>
	[Serializable] 
	public class FtpProfileDetails : Details
	{
        public enum Formats {IronMountain = 1, VitalRecords = 2, Recall = 3, DataSafe = 4}

        // Internal member variables
        private int id;
        private string name;
        private string server;
        private string login;
        private string password;
        private string filePath;
        private Formats format;
        private bool passive;
        private bool secure;
        private byte[] rowVersion = new byte[8];

        /// <summary>
        /// Public manual constructor
        /// </summary>
		public FtpProfileDetails(string _name, string _server, string _login, string _password, string _filePath, Formats _format, bool _passive, bool _secure)
		{
            Name = _name;
            Server = _server;
            Login = _login;
            Password = _password;
            FilePath = _filePath;
            Format = _format;
            Passive = _passive;
            Secure = _secure;
            // Set row state to new
            this.ObjState = ObjectStates.New;
        }
        /// <summary>
        /// Constructor initializes new account using the data in a IDataReader
        /// </summary>
        public FtpProfileDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ProfileId"));
            name = reader.GetString(reader.GetOrdinal("ProfileName"));
            server = reader.GetString(reader.GetOrdinal("Server"));
            login = reader.GetString(reader.GetOrdinal("Login"));
            password = Crypto.Decrypt(Convert.FromBase64String(reader.GetString(reader.GetOrdinal("Password"))));
            filePath = reader.GetString(reader.GetOrdinal("FilePath"));
            format = (Formats)Enum.ToObject(typeof(Formats), reader.GetInt16(reader.GetOrdinal("FileFormat")));
            passive = reader.GetBoolean(reader.GetOrdinal("Passive"));
            secure = reader.GetBoolean(reader.GetOrdinal("Secure"));
            reader.GetBytes(reader.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Set row state to unmodified
            this.ObjState = ObjectStates.Unmodified;
        }
        //
        // Properties
        //
        public int Id
        {
            get {return id;}
        }
        public string Name
        {
            get {return name;}
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Name", "Profile name is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Name", "Profile name may not be more than 256 characters in length.");
                // Set profile name
                name = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Server
        {
            get {return server;}
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Server", "Server name is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Server", "Server name may not be more than 256 characters in length.");
                // Set server name
                server = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Login
        {
            get {return login;}
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Login", "Login is a required field.");
                else if (value.Length > 64 )
                    throw new ValueLengthException("Login", "Login may not be more than 64 characters in length.");
                // Set login
                login = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Password
        {
            get {return password;}
            set 
            { 
                if (null == value || 0 == value.Length)
                {
                    password = String.Empty;
                }
                else
                {
                    password = value;
                }
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string EncryptedPassword
        {
            get {return Convert.ToBase64String(Crypto.Encrypt(password));}
        }
        public string FilePath
        {
            get {return filePath;}
            set 
            { 
                if (null == value || 0 == value.Length)
                    value = "/";
                else if (value.Length > 256 )
                    throw new ValueLengthException("FilePath", "File path may not be more than 256 characters in length.");
                // Set file path
                filePath = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public Formats Format
        {
            get {return format;}
            set {format = value;}
        }
        public bool Passive
        {
            get {return passive;}
            set {passive = value;}
        }
        public bool Secure
        {
            get {return secure;}
            set {secure = value;}
        }
        public byte[] RowVersion
        {
            get {return rowVersion;}
        }
    }
}
