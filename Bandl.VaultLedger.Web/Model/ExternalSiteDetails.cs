using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;


namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for external site.
	/// </summary>
    [Serializable]
    public class ExternalSiteDetails : Details
	{
        // Internal member variables
        private int id;
        private string name;
        private Locations location;
        private string account;
        private byte[] rowVersion = new byte[8];
        
        /// <summary>
        /// Constructor initializes new external site manually
        /// </summary>
        public ExternalSiteDetails(string _name, Locations _location)
        {
            Name = _name;
            Location = _location;
            account = String.Empty;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new external site manually
        /// </summary>
        public ExternalSiteDetails(string _name, Locations _location, string _account)
        {
            Name = _name;
            account = _account;
            Location = _location;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new external site using the data in a IDataReader
        /// </summary>
        public ExternalSiteDetails(IDataReader r)
        {
            // Get the data from the current row
            id = r.GetInt32(r.GetOrdinal("SiteId"));
            name = r.GetString(r.GetOrdinal("SiteName"));
            location = r.GetBoolean(r.GetOrdinal("Location")) ? Locations.Enterprise : Locations.Vault;
            account = r.GetString(r.GetOrdinal("AccountName"));
            r.GetBytes(r.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Set row state to unmodified and close the reader
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
                    throw new ValueRequiredException("Name", "Site name is a required field.");
                else if (value.Length > 256)
                    throw new ValueFormatException("Name", "Site name may not be more than 256 characters in length.");
                // Set name
                name = value;
                // Set object status to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public Locations Location
        {
            get { return location; }
            set 
            { 
                location = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Account
        {
            get { return account; }
            set 
            { 
                account = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public byte[] RowVersion
        {
            get { return rowVersion; }
        }
    }
}
