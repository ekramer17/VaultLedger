using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of disaster code list items
    /// </summary>
    [Serializable]
    public class DisasterCodeListItemCollection : BaseCollection
    {
		// Constrcutors
		public DisasterCodeListItemCollection() : base() {}
		public DisasterCodeListItemCollection(ICollection c) : base(c) {}
		public DisasterCodeListItemCollection(IDataReader r) : base(r) {}
        public DisasterCodeListItemCollection(DisasterCodeListDetails disasterCodeList) : base()  {this.Add(disasterCodeList);}

		// Indexer
		public DisasterCodeListItemDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (DisasterCodeListItemDetails)InnerList[index];
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

        public int Add(DisasterCodeListDetails disasterCodeList)
        {
            int totalAdded = 0;

            if (disasterCodeList != null)
            {
                if (!disasterCodeList.IsComposite)
                {
                    totalAdded += this.Add(disasterCodeList.ListItems);
                }
                else
                {
                    foreach (DisasterCodeListDetails childList in disasterCodeList.ChildLists)
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
				this.Add(new DisasterCodeListItemDetails(r));
			}
        }


        public void Remove(string serialNo)
        {
            foreach(DisasterCodeListItemDetails item in this)
            {
                if (serialNo == item.SerialNo)
                {
                    Remove(item);
                    break;
                }
            }
        }

		public DisasterCodeListItemDetails Find(int id)
		{
			foreach(DisasterCodeListItemDetails x in this)
			{
				if (id == x.Id)
				{
					return x;
				}
			}
			// Not found
			return null;
		}
		
		public DisasterCodeListItemDetails Find(string serialNo)
        {
            foreach(DisasterCodeListItemDetails x in this)
            {
                if (serialNo == x.SerialNo)
                {
                    return x;
                }
            }
            // Not found
            return null;
        }
    }
}
