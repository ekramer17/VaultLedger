using System;
using System.Data;
using System.Text;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for ProductLicenseDetails.
	/// </summary>
    [Serializable]
    public class ProductLicenseDetails : Details
	{
        public static int Unlimited = -1;
        private LicenseTypes licenseType;
        private int units;
        private DateTime issueDate;
        private DateTime expireDate;
        private string val;
        private string ray;

        private void Consolidate()
        {
            // Compute val
            string str = String.Format(@"%U{0}%I{1}%E{2}", units, issueDate.ToString("yyyyMMdd"), expireDate.ToString("yyyyMMdd"));
            byte[] f = new byte[32 - str.Length];
            new Random().NextBytes(f);
        
            // First byte (index=0) should be checksum:3 of str
            int total = 0;
            foreach(char c in str) {total += c;}
            Encoding.UTF8.GetBytes(Convert.ToString((13 - total % 10) % 10), 0, 1, f, 0);

            // Compute vector
            byte[] x = new byte[8];
            byte[] rayBytes = new byte[16];
            new Random().NextBytes(x);  // 8 bytes
            int n = Convert.ToInt32(issueDate.ToString("yyyyMMdd")) + ((int)licenseType * 6002);
            byte[] y = Encoding.UTF8.GetBytes(n.ToString());    // 8 bytes
            for (int i = 0; i < 8; i++)
            {
                rayBytes[i * 2] = x[i];
                rayBytes[i * 2 + 1] = y[i];
            }

            // Encrypt value
            byte[] valBytes = Crypto.Encrypt(str + Encoding.UTF8.GetString(f), rayBytes);

            // Get strings
            val = Convert.ToBase64String(valBytes);
            ray = Convert.ToBase64String(rayBytes);
        }

        private bool Split(int _id, byte[] _val, byte[] _ray)
        {
            try
            {
                bool b1, b2, b3;    // prevents reading of garbage and end of string
                b1 = b2 = b3 = false;
                // Decrypt
                string str = Crypto.Decrypt(_val, _ray);
                byte[] f = Encoding.UTF8.GetBytes(str.Substring(str.IndexOf("%E") + 10));
                // Test checksum
                int total = 0;
                foreach(char c in str.Substring(0,str.IndexOf("%E")+10)) {total += c;}
                if ((total + Convert.ToInt32(Encoding.UTF8.GetString(f, 0, 1))) % 10 != 3)
                    return false;
                // Split the string into fields
                string[] fields = str.Split(new char[] {'%'});
                foreach(string s in fields)
                {
                    if (s.Length > 1)
                    {
                        switch (s[0])
                        {
                            case 'U':
                                if (!b1) units = Convert.ToInt32(s.Substring(1));
                                b1 = true;
                                break;
                            case 'I':
                                if (!b2 && issueDate.ToString("yyyy/MM/dd") != String.Format("{0}/{1}/{2}", s.Substring(1,4), s.Substring(5,2), s.Substring(7,2))) return false;
                                b2 = true;
                                break;
                            case 'E':
                                if (!b3) expireDate = DateTime.Parse(String.Format("{0}/{1}/{2}", s.Substring(1,4), s.Substring(5,2), s.Substring(7,2)));
                                b3 = true;
                                break;
                        }
                    }
                }
                // Test the vector
                byte[] y = new byte[8];
                for (int i = 0; i < 8; i++) y[i] = _ray[i * 2 + 1];
                int n = Convert.ToInt32(Encoding.UTF8.GetString(y)) - (_id * 6002);
                if (n.ToString() != issueDate.ToString("yyyyMMdd"))
                    return false;
                else
                    return true;
            }
            catch
            {
                return false;
            }

        }

        public ProductLicenseDetails(LicenseTypes _type, int _units, DateTime _issueDate, DateTime _expireDate)
        {
            if (_units < -1)
                throw new ValueException("_units", "Units must be greater than or equal to -1.");
            else if (_issueDate > DateTime.UtcNow)
                throw new ValueException("_issueDate", "Issue date cannot be greater than the current time.");
            // Set fields
            units = _units;
            issueDate = _issueDate;
            expireDate = _expireDate;
            licenseType = _type;
            // Create the string and vector values
            this.Consolidate();
            // Set this.ObjState
            this.ObjState = ObjectStates.New;
        }
 
        public ProductLicenseDetails(LicenseTypes _type, byte[] _val, byte[] _ray)
        {
            licenseType = _type;
            issueDate = DateTime.UtcNow;
            expireDate = DateTime.UtcNow.AddDays(7);
            val = Convert.ToBase64String(_val);
            ray = Convert.ToBase64String(_ray);
            // Set this.ObjState
            this.ObjState = ObjectStates.New;
        }
        
        public ProductLicenseDetails(IDataReader reader) 
        {
            int id = reader.GetInt32(0);
            licenseType = (LicenseTypes)Enum.ToObject(typeof(LicenseTypes),id);
            val = reader.GetString(1);
            issueDate = reader.GetDateTime(2);
            ray = reader.GetString(3);
            // Set this.ObjState
            this.ObjState = ObjectStates.Unmodified;
            // Processing depends on the license key
            switch (id)
            {
                case 1: // Operators
                case 2: // Media
                case 3: // Days
                case 6: // Failures
                case 7: // RFID
				case 8: // Autoloader
					if (Split(id, Convert.FromBase64String(val), Convert.FromBase64String(ray)) == false)
                    {
                        throw new ValueException("License retrieved from database is invalid.");
                    }
                    else
                    {
                        break;
                    }
                default:
                    break;
            }
        }

       
        public LicenseTypes LicenseType
        {
            get {return licenseType;}
        }

        public int Units
        {
            get {return units;}
            set 
            {
                if (value < -1)
                {
                    throw new ValueException("Units", "Units must be greater than or equal to -1.");
                }
                // Set value
                units = value;
                // Consolidate to get vectors
                this.Consolidate();
                // Set object to modified state
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string IssueDate
        {
            get 
            {
                try
                {
                    return issueDate.ToString("yyyy-MM-dd");
                }
                catch
                {
                    return String.Empty;
                }
            }
            set
            {
                try
                {
                    issueDate = Date.ParseExact(value);
                }
                catch
                {
                    throw new ValueFormatException("IssueDate", "Issue date is in an invalid format.");
                }
                // Consolidate to get vectors
                this.Consolidate();
                // Set object to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string ExpireDate
        {
            get 
            {
                try
                {
                    return expireDate.ToString("yyyy-MM-dd");
                }
                catch
                {
                    return String.Empty;
                }
            }
            set
            {
                try
                {
                    expireDate = Date.ParseExact(value);
                }
                catch
                {
                    throw new ValueFormatException("ExpireDate", "Expire date is in an invalid format.");
                }
                // Consolidate to get vectors
                this.Consolidate();
                // Set object to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public byte[] Value
        {
            get {return Convert.FromBase64String(val);}
        }

        public byte[] Ray
        {
            get {return Convert.FromBase64String(ray);}
        }

        public string Value64
        {
            get {return val;}
        }

        public string Ray64
        {
            get {return ray;}
        }

	}
}
