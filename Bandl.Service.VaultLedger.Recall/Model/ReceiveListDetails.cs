using System;
using System.Collections;

namespace Bandl.Service.VaultLedger.Recall.Model
{
    // Class to represent an item of a list
    [Serializable]
    public class RMMReceiveItem
    {
        public string SerialNo;
        public string MediaCode;
        public RMMReceiveItem() {}
    }

    /// <summary>
    /// Holds the data for a transmitted receive list
    /// </summary>
    [Serializable]
    public class RMMReceiveListDetails
    {
        // Private fields
        public string Name;
        public string Account;
        public string CreateDate;
        public RMMReceiveItem[] Items;

        // Default constructor for serialization only
        public RMMReceiveListDetails() {}

        // Constructor
        public RMMReceiveListDetails(string _listName, string _account, string _createDate, RMMReceiveItem[] _listItems)
        {
            Name = _listName;
            Account = _account;
            CreateDate = _createDate;
            Items = _listItems;
        }
    }
}
