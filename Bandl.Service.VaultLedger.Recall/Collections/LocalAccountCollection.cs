using System;
using System.Data;
using System.Collections;
using Bandl.Service.VaultLedger.Recall.Model;

namespace Bandl.Service.VaultLedger.Recall.Collections
{
    /// <summary>
    /// Represents a collection of AccountDetails objects
    /// </summary>
    [Serializable]
    public class LocalAccountCollection : BaseCollection
    {
        // Constructors
        public LocalAccountCollection() : base() {}
        public LocalAccountCollection(ICollection c) : base(c) {}
        public LocalAccountCollection(IDataReader r) : base(r) {}

        // Indexer
        public LocalAccountDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (LocalAccountDetails)InnerList[index];
                }
            }
        }

        public override void Fill(IDataReader r)
        {
            while(r.Read() == true) 
            {
                this.Add(new LocalAccountDetails(r));
            }
        }

        public void Remove(string accountName)
        {
            foreach(LocalAccountDetails a in this)
            {
                if (accountName == a.Name)
                {
                    Remove(a);
                    break;
                }
            }
        }

        public LocalAccountDetails Find(int id)
        {
            foreach(LocalAccountDetails x in this)
            {
                if (id == x.Id)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }
		
        public LocalAccountDetails Find(string accountName)
        {
            foreach(LocalAccountDetails x in this)
            {
                if (accountName == x.Name)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }
    }
}
