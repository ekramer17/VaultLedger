using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
	/// <summary>
	/// Summary description for ListPurgeCollection.
	/// </summary>
	[Serializable]
	public class ListPurgeCollection : BaseCollection
	{
        public ListPurgeCollection() : base() {}
        public ListPurgeCollection(ICollection c) : base(c) {}
        public ListPurgeCollection(IDataReader r) : base(r) {}

        // Indexer
        public ListPurgeDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (ListPurgeDetails)InnerList[index];
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
                this.Add(new ListPurgeDetails(r));
            }
        }

        public ListPurgeDetails Find(ListTypes listType)
        {
            foreach(ListPurgeDetails x in this)
            {
                if (listType == x.ListType)
                {
                    return x;
                }
            }
            // Not found
            return null;
        }
    }
}
