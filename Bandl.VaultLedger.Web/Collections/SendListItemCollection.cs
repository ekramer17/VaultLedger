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
    public class SendListItemCollection : BaseCollection
    {
        public SendListItemCollection() : base() {}
		public SendListItemCollection(ICollection c) : base(c) {}
		public SendListItemCollection(IDataReader r) : base(r) {}
        public SendListItemCollection(SendListDetails sendList) : base()  {this.Add(sendList);}

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

        public int Add(SendListDetails sendList)
        {
            int totalAdded = 0;

            if (sendList != null)
            {
                if (!sendList.IsComposite)
                {
                    totalAdded += this.Add(sendList.ListItems);
                }
                else
                {
                    foreach (SendListDetails childList in sendList.ChildLists)
                    {
                        totalAdded += this.Add(childList.ListItems);
                    }
                }
            }

            return totalAdded;
        }

        public override void Fill(IDataReader r)
        {
            while(r.Read() == true) 
                this.Add(new SendListItemDetails(r));
        }

        public void Remove(string serialNo)
        {
            foreach(SendListItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    Remove(item);
                    return;
                }
            }
        }

		public SendListItemDetails Find(int itemId)
		{
			foreach(SendListItemDetails item in this)
			{
				if (itemId == item.Id)
				{
					return item;
				}
			}
			// return
			return null;
		}
		
		public SendListItemDetails Find(string serialNo)
        {
            foreach(SendListItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    return item;
                }
            }
            // return
            return null;
        }
    }
}
