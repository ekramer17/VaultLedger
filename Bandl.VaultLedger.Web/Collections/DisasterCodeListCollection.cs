using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of disaster code lists
    /// </summary>
    [Serializable]
    public class DisasterCodeListCollection : BaseCollection
    {
		// Constructors
        public DisasterCodeListCollection() : base() {}
		public DisasterCodeListCollection(ICollection c) : base(c) {}
		public DisasterCodeListCollection(IDataReader r) : base(r) {}

		// Indexer
        public DisasterCodeListDetails this [int index]
        {
            get
            {
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (DisasterCodeListDetails)InnerList[index];
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
				this.Add(new DisasterCodeListDetails(r));
			}
        }

        public void Remove(string listName)
        {
            foreach(DisasterCodeListDetails s in this)
            {
                if (listName == s.Name)
                {
                    Remove(s);
					break;
                }
            }
        }

        public DisasterCodeListDetails Find(int listId)
        {
			foreach(DisasterCodeListDetails x in this)
			{
				if (listId == x.Id)
				{
					return(x);
				}
			}
            // Not found
            return null;
        }

		public DisasterCodeListDetails Find(string listName)
		{
			foreach(DisasterCodeListDetails x in this)
			{
				if (listName == x.Name)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}
    }
}
