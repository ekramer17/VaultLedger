using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
	/// Summary description for SendListItemDetails.
	/// </summary>
    [Serializable]
    public class SendListItemDetails : Details
    {
        private int id;
        private string serialNo;
        private SLIStatus status;
        private string returnDate;
        private string account; // only used when items are retrieved independently of list, as with getPage()
        private string caseName;
        private string notes;
		private string mediumtype;	// only used in send list detail page print object
		private byte[] rowVersion = new byte[8];
        
        public SendListItemDetails(string _serialNo, string _returnDate, string _notes, string _caseName)
        {
            Notes = _notes;
            CaseName = _caseName;
            ReturnDate = _returnDate;
            // Serial number is read only property.  We need checks here.
            if (_serialNo == null || _serialNo.Length == 0)
                throw new ValueRequiredException("_serialNo", "Serial number not supplied.");
            else if (_serialNo.Length > 32)
                throw new ValueLengthException("_serialNo", "Serial number may not be longer than 32 characters.");
            else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(_serialNo))
                throw new ValueFormatException("_serialNo", "Serial number may only consist of alphanumeric characters.");
            // Set the serial number
            serialNo = _serialNo;
            // Set row state and case state
            this.ObjState = ObjectStates.New;
        }

        public SendListItemDetails(IDataReader reader) 
        {
            int columnOrdinal;
            DataTable schemaTable = reader.GetSchemaTable();
            foreach(DataRow schemaRow in schemaTable.Rows)
            {
                columnOrdinal = (int)schemaRow["ColumnOrdinal"];
                switch(schemaRow["ColumnName"].ToString())
                {
                    case "ItemId":
                        id = reader.GetInt32(columnOrdinal);
                        break;
                    case "Status":
                        int s = reader.GetInt32(columnOrdinal);
                        status = (SLIStatus)Enum.ToObject(typeof(SLIStatus),s);
                        break;
                    case "SerialNo":
                        serialNo = reader.GetString(columnOrdinal);
                        break;
                    case "ReturnDate":
                        returnDate = reader.GetString(columnOrdinal);
                        break;
                    case "CaseName":
                        caseName = reader.GetString(columnOrdinal);
                        break;
                    case "Notes":
                        notes = reader.GetString(columnOrdinal);
                        break;
                    case "AccountName":
                        account = reader.GetString(columnOrdinal);
                        break;
					case "MediumType":
						mediumtype = reader.GetString(columnOrdinal);
						break;
					case "RowVersion":
                        reader.GetBytes(columnOrdinal,0,rowVersion,0,8);
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

        public string SerialNo
        {
            get {return serialNo;}
            set {serialNo = value;}
        }

        public SLIStatus Status
        {
            get {return status;}
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
                    string dateString = null;

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
                else if (value.Length > 1000 )
                    throw new ValueLengthException("Notes", "Notes may not be more than 1000 characters in length.");
                // Set notes
                notes = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string Account
        {
            get {return account;}
        }

		public string MediumType
		{
			get {return mediumtype;}
            set {mediumtype = value;}   // can be set when displaying report
        }

		public string CaseName
        {
            get {return caseName;}
            set 
            {
                if (value == null)
                    value = String.Empty;
                else if (value.Length > 32 )
                    throw new ValueLengthException("CaseName", "Case name may not be more than 32 characters in length.");
                // Set the case name
                caseName = value;
                // Set the object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public byte[] RowVersion
        {
            get {return rowVersion;}
        }

	}
}
