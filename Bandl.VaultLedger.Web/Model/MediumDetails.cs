using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for MediumDetails.
    /// </summary>
    [Serializable]
    public class MediumDetails : Details
    {
        private int id;
        private string serialNo;
        private Locations location;
        private string lastMoveDate;
        private string returnDate;
        private bool hotSite;
        private bool missing;
        private bool destroyed;
        private string flipside;
        private string notes;
        private string mediumType;
        private string account;
        private byte[] rowVersion = new byte[8];
        private string caseName;
        private string disaster;

        /// <summary>
        /// Constructor initializes new medium manually
        /// </summary>
        public MediumDetails(string _serialNo, string _mediumType, string _account, Locations _location, string _flipside, string _notes)
        {
            SerialNo = _serialNo;
            MediumType = _mediumType;
            Account = _account;
            Location = _location;
            ReturnDate = String.Empty;
            HotSite = false;
            Missing = false;
            Flipside = _flipside;
            Notes = _notes;
            // Set the last move date field to empty because there is no set property
            lastMoveDate = String.Empty;
            disaster = String.Empty;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new medium using the data in a IDataReader
        /// </summary>
        public MediumDetails(IDataReader r)
        {
            foreach(DataRow dr in r.GetSchemaTable().Rows)
            {
                int c = (int)dr["ColumnOrdinal"];

                switch(dr["ColumnName"].ToString())
                {
                    case "MediumId":
                        id = r.GetInt32(c);
                        break;
                    case "SerialNo":
                        serialNo = r.GetString(c);
                        break;
                    case "TypeName":
                        mediumType = r.GetString(c);
                        break;
                    case "AccountName":
                        account = r.GetString(c);
                        break;
                    case "Location":
                        Int16 locationValue = Convert.ToInt16(r.GetBoolean(c));
                        location = (Locations)Enum.ToObject(typeof(Locations), locationValue);
                        break;
                    case "ReturnDate":
                        returnDate = r.GetString(c);
                        break;
                    case "LastMoveDate":
                        lastMoveDate = r.GetString(c);
                        break;
                    case "HotSite":
                        hotSite = r.GetBoolean(c);
                        break;
                    case "Missing":
                        missing = r.GetBoolean(c);
                        break;
                    case "BSide":
                        flipside = r.GetString(c);
                        break;
                    case "CaseName":
                        caseName = r.GetString(c);
                        break;
                    case "Notes":
                        notes = r.GetString(c);
                        break;
                    case "Disaster":
                        disaster = r.GetString(c);
                        break;
                    case "Destroyed":
                        destroyed = r.GetBoolean(c);
                        break;
                    case "RowVersion":
                        r.GetBytes(c,0,rowVersion,0,8);
                        break;
                }
            }
            // Set row state to unmodified and close the reader
            this.ObjState = ObjectStates.Unmodified;
        }

        public int Id
        {
            get {return id;}
        }
        public string SerialNo
        {
            get {return serialNo;}
            set 
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("SerialNo", "Serial number is a required field.");
                else if (value.Length > 32 )
                    throw new ValueLengthException("SerialNo", "Serial number may not be more than 32 characters in length.");
                // Set serial number
                serialNo = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public Locations Location 
        {
            get {return location;}
            set 
            {
                if (value != location)
                {
                    location = value;
                    lastMoveDate = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
                    this.ObjState = ObjectStates.Modified;
                }
            }
        }
        public string LastMoveDate
        {
            get {return lastMoveDate;}
        }
        public string ReturnDate
        {
            get {return returnDate;}
            set 
            {
                // If the string is empty, just set it to empty.  Otherwise, 
                // make sure that the supplied string is not only a valid date
                // but also later than today.
                if (value == null || String.Empty == value)
                {
                    returnDate = String.Empty;
                    this.ObjState = ObjectStates.Modified;
                }
                else
                {
                    string dateString;

                    try
                    {
                        dateString = Date.ParseExact(value).ToString("yyyy-MM-dd");
                    }
                    catch
                    {
                        throw new ValueFormatException("ReturnDate", "Return date is in an invalid format.");
                    }
                    // Verify that return date is in the future
                    if (0 > dateString.CompareTo(Time.Local.ToString("yyyy-MM-dd")))
                        throw new ValueException("ReturnDate", "Return date must be equal to or later than today.");
                    // Set the return date and update the object state
                    returnDate = dateString;
                    this.ObjState = ObjectStates.Modified;
                }
            }
        }
        public bool HotSite
        {
            get {return hotSite;}
            set 
            {
                hotSite = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public bool Missing
        {
            get {return missing;}
            set 
            {
                missing = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public bool Destroyed
        {
            get {return destroyed;}
            set 
            {
                missing = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Flipside
        {
            get {return flipside;}
            set 
            {
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 32 )
                    throw new ValueLengthException("Flipside", "B-side serial number may not be more than 32 characters in length.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("Flipside", "B-side serial number may only consist of alphanumeric characters");
                // Set b-side serial number
                flipside = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Notes
        {
            get {return notes;}
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
        public string MediumType
        {
            get {return mediumType;}
            set 
            {
                mediumType = value;
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Account
        {
            get {return account;}
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
        public string CaseName
        {
            get {return caseName;}
        }
        public string Disaster
        {
            get {return disaster;}
        }
    }
}
