using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of receive lists
    /// </summary>
    [Serializable]
    public class ReceiveListCollection : BaseCollection
    {
        public ReceiveListCollection() : base() {}
		public ReceiveListCollection(ICollection c) : base(c) {}
		public ReceiveListCollection(IDataReader r) : base(r) {}

		// Indexer
		public ReceiveListDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (ReceiveListDetails)InnerList[index];
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
				this.Add(new ReceiveListDetails(r));
			}
        }

        public void Remove(string listName)
        {
            foreach(ReceiveListDetails s in this)
            {
                if (listName == s.Name)
                {
                    Remove(s);
                    return;
                }
            }
        }

		public ReceiveListDetails Find(int listId)
		{
			foreach(ReceiveListDetails receiveList in this)
			{
				if (listId == receiveList.Id)
				{
					return receiveList;
				}
			}
			// id not found
			return null;
		}
		
		public ReceiveListDetails Find(string listName)
        {
			foreach(ReceiveListDetails receiveList in this)
			{
				if (listName == receiveList.Name)
				{
					return receiveList;
				}
			}
            // id not found
            return null;
        }

        public int IndexOf(int id)
        {
            for (int i = 0; i < this.Count; i++)
            {
                if (id == this[i].Id)
                {
                    return i;
                }
            }
            // id not found
            return -1;
        }

        public int IndexOf(string listName)
        {
            for (int i = 0; i < this.Count; i++)
            {
                if (listName == this[i].Name)
                {
                    return i;
                }
            }
            // id not found
            return -1;
        }
    }
}
