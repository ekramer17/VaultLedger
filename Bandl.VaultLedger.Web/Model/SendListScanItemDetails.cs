using System;
using System.Data;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for SendListScanItemDetails.
	/// </summary>
	[Serializable]
	public class SendListScanItemDetails : Details
	{
        private int id;
        private string serialNo;
        private string caseName;

        /// <summary>
        /// Constructor initializes new send list scan item
        /// </summary>
        public SendListScanItemDetails(string _serialNo, string _caseName)
        {
            // Get the data from the current row
            SerialNo = _serialNo;
            CaseName = _caseName;
            // Set row state to new
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new send list scan item using the data in a IDataReader
        /// </summary>
        public SendListScanItemDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ItemId"));
            serialNo = reader.GetString(reader.GetOrdinal("SerialNo"));
            caseName = reader.GetString(reader.GetOrdinal("CaseName"));
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
            set 
            {
                if (value == null || value.Length == 0)
                    throw new ValueRequiredException("SerialNo", "Serial number not supplied.");
                else if (value.Length > 32)
                    throw new ValueLengthException("SerialNo", "Serial number may not be longer than 32 characters.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("SerialNo", "Serial number may only consist of alphanumeric characters.");
                // Set the serial number
                serialNo = value;
                // Set the object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public string CaseName
        {
            get {return caseName;}
            set 
            {
                if (value == null)
                    value = String.Empty;
                else if (value.Length > 32)
                    throw new ValueLengthException("CaseName", "Case name may not be longer than 32 characters.");
                else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(value))
                    throw new ValueFormatException("CaseName", "Case name may only consist of alphanumeric characters.");
                // Set the case name
                caseName = value;
                // Set the object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
    }
}
