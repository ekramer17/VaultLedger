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
    public class SealedCaseDetails : Details
    {
        private int id;
        private string caseName;
        private string returnDate;
        private bool hotSite;
        private string notes;
        private string caseType;
        private byte[] rowVersion = new byte[8];
        // Below fields only used for browse page
        private int numTapes;   // number of tapes in the case
        private string listName = String.Empty;    // list on which case appears

        /// <summary>
        /// Constructor initializes new sealed case manually
        /// </summary>
        public SealedCaseDetails(string _caseName, string _caseType, string _returnDate, string _notes)
        {
            CaseName = _caseName;
            CaseType = _caseType;
            ReturnDate = _returnDate;
            HotSite = false;
            Notes = _notes;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new sealed case using the data in a IDataReader
        /// </summary>
        public SealedCaseDetails(IDataReader r)
        {
            int o;  // ordinal
            // Run through the data retrieved
            foreach(DataRow d in r.GetSchemaTable().Rows)
            {
                // Get the column ordinal
                o = (int)d["ColumnOrdinal"];
                // Get the database depending on column name
                switch(d["ColumnName"].ToString())
                {
                    case "CaseId":
                        id = r.GetInt32(o);
                        break;
                    case "SerialNo":
                        caseName = r.GetString(o);
                        break;
                    case "ReturnDate":
                        returnDate = r.GetString(o);
                        break;
                    case "HotStatus":
                        hotSite = r.GetBoolean(o);
                        break;
                    case "Notes":
                        notes = r.GetString(o);
                        break;
                    case "TypeName":
                        caseType = r.GetString(o);
                        break;
                    case "RowVersion":
                        r.GetBytes(o,0,rowVersion,0,8);
                        break;
                    case "NumTapes":
                        numTapes = r.GetInt32(o);
                        break;
                    case "ListName":
                        listName = r.GetString(o);
                        break;
                }
            }
            // Set row state to unmodified
            this.ObjState = ObjectStates.Unmodified;
        }

        public int Id
        {
            get {return id;}
        }

        public string CaseName
        {
            get {return caseName;}
            set 
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("CaseName", "Case name is a required field.");
                else if (value.Length > 32 )
                    throw new ValueLengthException("CaseName", "Case name may not be more than 32 characters in length.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("CaseName", "Case name may only consist of alphanumeric characters");
                // Set serial number
                caseName = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
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
                        throw new ValueException("ReturnDate", "Return date must be later than today.");
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

        public string CaseType
        {
            get {return caseType;}
            set 
            {
                caseType = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public int NumTapes
        {
            get {return numTapes;}
        }

        public string ListName
        {
            get {return listName;}
        }

        public byte[] RowVersion
        {
            get { return rowVersion; }
        }
    }
}
