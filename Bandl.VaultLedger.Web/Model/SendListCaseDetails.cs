using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for SendListCaseDetails.
    /// </summary>
    [Serializable]
    public class SendListCaseDetails : Details
    {
        private int id;
        private string name;
        private string type;
        private string returnDate;
        private string notes;
        private bool closed;    // sealed is a keyword in C#
        private byte[] rowVersion = new byte[8];
        // Below fields only used for browse page
        private int numTapes;   // number of tapes in the case
        private string listName = String.Empty;    // list on which case appears

        public SendListCaseDetails(string _name, bool _sealed, string _returnDate, string _notes) 
        {
            Name = _name;
            Sealed = _sealed;
            ReturnDate = _returnDate;
            Notes = _notes;
            // Set row state to new
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new send list using the data in a IDataReader
        /// </summary>
        public SendListCaseDetails(IDataReader r)
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
                    case "CaseName":
                        name = r.GetString(o);
                        break;
                    case "ReturnDate":
                        returnDate = r.GetString(o);
                        break;
                    case "Sealed":
                        closed = r.GetBoolean(o);
                        break;
                    case "Notes":
                        notes = r.GetString(o);
                        break;
                    case "TypeName":
                        type = r.GetString(o);
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

        public string Name
        {
            get {return name;}
            set 
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Name", "Case name is a required field.");
                else if (value.Length > 32 )
                    throw new ValueLengthException("Name", "Case name may not be more than 32 characters in length.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("Name", "Case name may only consist of alphanumeric characters");
                // Set account name
                name = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Type
        {
            get {return type;}
        }

        public string ReturnDate
        {
            get {return returnDate;}
            set 
            {
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

        public bool Sealed
        {
            get {return closed;}
            set 
            {
                closed = value;
                if (!closed) ReturnDate = String.Empty;
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
            get {return rowVersion;}
        }
    }
}
