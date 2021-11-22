using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    [Serializable]
    public class InventoryConflictDetails : Details
    {
        private int id;
        private string serialNo;
        private string details;
        private string account;
        private DateTime recordedDate;
        private InventoryConflictTypes conflictType;
        
        /// <summary>
        /// Constructor initializes new vault discrepancy using the data in a IDataReader
        /// </summary>
        public InventoryConflictDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("Id"));
            serialNo = reader.GetString(reader.GetOrdinal("SerialNo"));
            recordedDate = reader.GetDateTime(reader.GetOrdinal("RecordedDate"));
            details = reader.GetString(reader.GetOrdinal("Details"));
            account = reader.GetString(reader.GetOrdinal("AccountName"));
            conflictType = (InventoryConflictTypes)Enum.ToObject(typeof(InventoryConflictTypes),reader.GetInt32(reader.GetOrdinal("ConflictType")));
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
        public string AccountName
        {
            get {return account;}
        }
        public DateTime RecordedDate
        {
            get {return recordedDate;}
        }
        public InventoryConflictTypes ConflictType
        {
            get {return conflictType;}
        }
        public string Details
        {
            get {return details;}
        }
    }
}
