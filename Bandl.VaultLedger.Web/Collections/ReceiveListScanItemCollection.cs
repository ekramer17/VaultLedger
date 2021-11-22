using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of receive list items
    /// </summary>
    [Serializable]
    public class ReceiveListScanItemCollection : BaseCollection
    {
        public ReceiveListScanItemCollection() : base() {}
		public ReceiveListScanItemCollection(ICollection c) : base(c) {}
		public ReceiveListScanItemCollection(IDataReader r) : base(r) {}

		// Indexer
		public ReceiveListScanItemDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (ReceiveListScanItemDetails)InnerList[index];
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
				this.Add(new ReceiveListScanItemDetails(r));
			}
        }

		public ReceiveListScanItemDetails Find(int itemId)
		{
			foreach(ReceiveListScanItemDetails item in this)
			{
				if (itemId == item.Id)
				{
					return item;
				}
			}
			// not found
			return null;
		}
		
		public ReceiveListScanItemDetails Find(string serialNo)
        {
            foreach(ReceiveListScanItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    return item;
                }
            }
            // not found
            return null;
        }

        public void Remove(string serialNo)
        {
            foreach(ReceiveListScanItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    Remove(item);
                    return;
                }
            }
        }
    }
}
