using System;
using System.Collections;

namespace Bandl.Service.VaultLedger.Recall.Model
{
    // Class to represent an item of a list
    [Serializable]
    public class RMMSendItem
    {
        public string SerialNo;
        public string MediaCode;
        public string DrpCode;
        public string Description;
        public string ReturnDate;

        public RMMSendItem() {}
    }

    /// <summary>
    /// Holds the data for a transmitted send list
    /// </summary>
    [Serializable]
	public class RMMSendListDetails
	{
        // Private fields
        public string Name;
        public string Account;
        public string CreateDate;
        public RMMSendItem[] Items;

        // Default constructor for serialization only
        public RMMSendListDetails() {}

        // Constructor
		public RMMSendListDetails(string _listName, string _account, string _createDate, RMMSendItem[] _listItems)
		{
            Name = _listName;
            Account = _account;
            CreateDate = _createDate;
            Items = _listItems;
		}
	}
}
