using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of send list items
    /// </summary>
    [Serializable]
    public class SendListScanItemCollection : BaseCollection
    {
        public SendListScanItemCollection() : base() {}
		public SendListScanItemCollection(ICollection c) : base(c) {}
		public SendListScanItemCollection(IDataReader r) : base(r) {}

		// Indexer
		public SendListItemDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (SendListItemDetails)InnerList[index];
				}
			}
            set
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    InnerList[index] = value;
                }
            }
        }

        public override void Fill(IDataReader r)
        {
			while(r.Read() == true) 
			{
				this.Add(new SendListScanItemDetails(r));
			}
        }

		public void Remove(string serialNo)
        {
            foreach(SendListScanItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    Remove(item);
                    return;
                }
            }
        }

        public SendListScanItemDetails Find(string serialNo)
        {
            foreach(SendListScanItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    return item;
                }
            }
            // not found
            return null;
        }
    }
}
