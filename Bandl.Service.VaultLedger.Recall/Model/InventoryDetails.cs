using System;
using System.Collections;

namespace Bandl.Service.VaultLedger.Recall.Model
{
    // Class to represent a single entity
    [Serializable]
    public class InventoryItem
    {
        public string SerialNo = String.Empty;
        public string TypeCode = String.Empty;
        public string ReturnDate = String.Empty;
        public string Description = String.Empty;
        public bool HotStatus = false;
        public InventoryItem() {}
    }
    /// <summary>
    /// Holds the data for inventory returned from the server
    /// </summary>
    [Serializable]
    public class InventoryDetails
    {
        // Private fields
        public string Account;
        public DateTime CreateDate;
        public byte[] HashCode;
        public InventoryItem[] Items;

        // Default constructor for serialization only
        public InventoryDetails() {}

        // Constructor
        public InventoryDetails(string _account, DateTime _createDate, byte[] _hashCode, InventoryItem[] _items)
        {
            Account = _account;
            CreateDate = _createDate;
            HashCode = _hashCode;
            Items = _items;
        }
    }
}
