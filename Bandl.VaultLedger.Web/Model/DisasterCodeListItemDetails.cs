using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for DisasterCodeListItemDetails.
    /// </summary>
    [Serializable]
    public class DisasterCodeListItemDetails : Details
    {
        private int id;
        private string code;
        private string serialNo;
        private string caseName;
        private DLIStatus status;
        private string account; // only used when items are retrieved independently of list, as with getPage()
        private string notes;
        private byte[] rowVersion = new byte[8];

        public DisasterCodeListItemDetails(string _serialNo, string _code, string _notes)
        {
            Code = _code;
            Notes = _notes;
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

        public DisasterCodeListItemDetails(IDataReader r) 
        {
            foreach(DataRow dr in r.GetSchemaTable().Rows)
            {
                int c = (int)dr["ColumnOrdinal"];

                switch(dr["ColumnName"].ToString())
                {
                    case "ItemId":
                        id = r.GetInt32(c);
                        break;
                    case "Code":
                        code = r.GetString(c);
                        break;
                    case "Status":
                        status = (DLIStatus)Enum.ToObject(typeof(DLIStatus),r.GetInt32(c));
                        break;
                    case "SerialNo":
                        serialNo = r.GetString(c);
                        break;
                    case "CaseName":
                        caseName = r.GetString(c);
                        break;
                    case "Notes":
                        notes = r.GetString(c);
                        break;
                    case "AccountName":
                        account = r.GetString(c);
                        break;
                    case "RowVersion":
                        r.GetBytes(c,0,rowVersion,0,8);
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

        public string CaseName
        {
            get {return caseName;}
        }

        public DLIStatus Status
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

        public string Code
        {
            get 
            {
                return code;
            }
            set
            {
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 32 )
                    throw new ValueLengthException("Code", "Disaster code may not be more than 32 characters in length.");
                else if (false == new Regex("[a-zA-Z]*").IsMatch(value))
                    throw new ValueFormatException("Code", "Disaster code may only consist of alphanumeric characters");
                // Set code
                code = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public byte[] RowVersion
        {
            get {return rowVersion;}
        }

    }
}
