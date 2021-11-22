using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for ReceiveListItemDetails.
    /// </summary>
    [Serializable]
    public class ReceiveListItemDetails : Details
    {
        private int id;
        private string serialNo;
        private string caseName;
        private RLIStatus status;
        private string notes;
        private string account; // only used when items are retrieved independently of list, as with getPage()
		private string mediumtype;	// only used in send list detail page print object
		private byte[] rowVersion = new byte[8];

        public ReceiveListItemDetails(string _serialNo, string _notes)
        {
            Notes = _notes;
            caseName = String.Empty;
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

        public ReceiveListItemDetails(IDataReader reader) 
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
                        status = (RLIStatus)Enum.ToObject(typeof(RLIStatus),s);
                        break;
                    case "SerialNo":
                        serialNo = reader.GetString(columnOrdinal);
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
        }

        public RLIStatus Status
        {
            get {return status;}
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

        public string CaseName
        {
            get {return caseName;}
        }

		public string MediumType
		{
			get {return mediumtype;}
            set {mediumtype = value;}   // can be set when displaying report
        }

		public byte[] RowVersion
        {
            get {return rowVersion;}
        }

    }
}
