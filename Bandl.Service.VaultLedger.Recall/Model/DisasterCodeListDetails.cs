using System;
using System.Collections;

namespace Bandl.Service.VaultLedger.Recall.Model
{
    // Class to represent an item of a list
    [Serializable]
    public class RMMDisasterCodeItem
    {
        public string SerialNo;
        public string MediaCode;
        public string DrpCode;

        public RMMDisasterCodeItem() {}
    }

    /// <summary>
    /// Holds the data for a transmitted disaster code list
    /// </summary>
    [Serializable]
    public class RMMDisasterCodeListDetails
    {
        // Private fields
        public string Name;
        public string Account;
        public string CreateDate;
        public RMMDisasterCodeItem[] Items;

        // Default constructor for serialization only
        public RMMDisasterCodeListDetails() {}

        // Constructor
        public RMMDisasterCodeListDetails(string _listName, string _account, string _createDate, RMMDisasterCodeItem[] _listItems)
        {
            Name = _listName;
            Account = _account;
            CreateDate = _createDate;
            Items = _listItems;
        }
    }
}
