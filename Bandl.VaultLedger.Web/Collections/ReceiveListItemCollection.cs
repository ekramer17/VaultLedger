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
    public class ReceiveListItemCollection : BaseCollection
    {
        public ReceiveListItemCollection() : base() {}
		public ReceiveListItemCollection(ICollection c) : base(c) {}
		public ReceiveListItemCollection(IDataReader r) : base(r) {}
        public ReceiveListItemCollection(ReceiveListDetails receiveList) : base()  {this.Add(receiveList);}

		// Indexer
		public ReceiveListItemDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (ReceiveListItemDetails)InnerList[index];
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

        public int Add(ReceiveListDetails receiveList)
        {
            int totalAdded = 0;

            if (receiveList != null)
            {
                if (!receiveList.IsComposite)
                {
                    totalAdded += this.Add(receiveList.ListItems);
                }
                else
                {
                    foreach (ReceiveListDetails childList in receiveList.ChildLists)
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
			{
				this.Add(new ReceiveListItemDetails(r));
			}
		}

        public void Remove(string serialNo)
        {
            foreach(ReceiveListItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    Remove(item);
                    return;
                }
            }
        }

		public ReceiveListItemDetails Find(int id)
		{
			foreach(ReceiveListItemDetails item in this)
			{
				if (id == item.Id)
				{
					return item;
				}
			}
			// return
			return null;
		}

		public ReceiveListItemDetails Find(string serialNo)
        {
            foreach(ReceiveListItemDetails item in this)
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
