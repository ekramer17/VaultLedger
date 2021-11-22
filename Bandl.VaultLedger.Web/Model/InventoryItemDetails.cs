using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for VaultDiscrepancyDetails.
    /// </summary>
    [Serializable]
    public class InventoryItemDetails : Details
    {
        private int id;
        private string serialNo;
        private string typeName;    // vault inventory item only
        private string returnDate;  // vault inventory item only
        private bool hotStatus;     // vault inventory item only
        private string notes;       // vault inventory item only

        /// <summary>
        /// Constructor that initializes new vault inventory item manually
        /// </summary>
        public InventoryItemDetails(string _serialNo, string _typeName, bool _hotStatus, string _returnDate, string _notes)
        {
            // Check serial numbers
            if (_serialNo == null || _serialNo.Length == 0)
                throw new ValueRequiredException("_serialNo", "Serial number is a required field.");
            else if (_serialNo.Length > 32)
                throw new ValueLengthException("_serialNo", "Serial number may not be longer than 32 characters.");
            else if (false == new Regex("[a-zA-Z0-9]*").IsMatch(_serialNo))
                throw new ValueFormatException("_serialNo", "Serial number may only consist of alphanumeric characters.");
            // Check notes
            if (_notes == null)
                _notes = String.Empty;
            else if (_notes.Length > 1000)
                throw new ValueLengthException("_notes", "Notes may not be longer than 1000 characters.");
            // Set fields
            notes = _notes;
            serialNo = _serialNo;
            typeName = _typeName;
            hotStatus = _hotStatus;
            // Make sure return date is in correct format
            if (_returnDate.Length == 0 )
            {
                returnDate = String.Empty;
            }
            else
            {
                try
                {
                    DateTime.ParseExact(_returnDate, "yyyy-MM-dd", null);
                    returnDate = _returnDate;
                }
                catch
                {
                    throw new ApplicationException("Return date supplied to inventory item must be in yyyy-MM-dd format.");
                }
            }
        }
        // Constructor with no notes
        public InventoryItemDetails(string _serialNo, string _typeName, bool _hotStatus) : this(_serialNo, _typeName, _hotStatus, String.Empty, String.Empty) {}
        /// <summary>
        /// Constructor initializes new vault discrepancy using the data in a IDataReader
        /// </summary>
        public InventoryItemDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ItemId"));
            serialNo = reader.GetString(reader.GetOrdinal("SerialNo"));
            hotStatus = reader.GetBoolean(reader.GetOrdinal("HotStatus"));
            typeName = reader.GetString(reader.GetOrdinal("TypeName"));
            notes = reader.GetString(reader.GetOrdinal("Notes"));
            returnDate = reader.GetString(reader.GetOrdinal("ReturnDate"));
        }

        // Properties
        public int Id
        {
            get {return id;}
        }
        public string SerialNo 
        {
            get {return serialNo;}
        }
        public string TypeName
        {
            get {return typeName;}
        }
        public bool HotStatus
        {
            get {return hotStatus;}
        }
        public string Notes
        {
            get {return notes;}
        }
        public string ReturnDate
        {
            get {return returnDate;}
        }
    }
}
