using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
	/// <summary>
	/// Collection of send lists
	/// </summary>
    [Serializable]
    public class SendListCollection : BaseCollection
	{
        public SendListCollection() : base() {}
		public SendListCollection(ICollection c) : base(c) {}
		public SendListCollection(IDataReader r) : base(r) {}

		// Indexer
		public SendListDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (SendListDetails)InnerList[index];
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
				this.Add(new SendListDetails(r));
			}
        }

        public void Remove(string listName)
        {
            foreach(SendListDetails s in this)
            {
                if (listName == s.Name)
                {
                    Remove(s);
                    return;
                }
            }
        }

		public SendListDetails Find(string listName)
		{
			foreach(SendListDetails s in this)
			{
				if (listName == s.Name)
				{
					return(s);
				}
			}
			// id not found
			return null;
		}
		
		public SendListDetails Find(int listId)
        {
			foreach(SendListDetails s in this)
			{
				if (listId == s.Id)
				{
					return(s);
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
