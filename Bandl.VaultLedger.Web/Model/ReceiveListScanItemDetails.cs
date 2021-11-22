using System;
using System.Data;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for ReceiveListScanItemDetails.
    /// </summary>
    [Serializable]
    public class ReceiveListScanItemDetails : Details
    {
        private int id;
        private string serialNo;

        /// <summary>
        /// Constructor initializes new receive list scan item
        /// </summary>
        public ReceiveListScanItemDetails(string _serialNo)
        {
            // Assign serial number
            SerialNo = _serialNo;
            // Set row state to new
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new receive list scan item using the data in a IDataReader
        /// </summary>
        public ReceiveListScanItemDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ItemId"));
            serialNo = reader.GetString(reader.GetOrdinal("SerialNo"));
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
    }
}
