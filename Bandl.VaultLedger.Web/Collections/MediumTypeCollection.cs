using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of MediumTypeDetails objects
    /// </summary>
    [Serializable]
    public class MediumTypeCollection : BaseCollection
    {
        public MediumTypeCollection() : base() {}
        public MediumTypeCollection(ICollection c) : base(c) {}
        public MediumTypeCollection(IDataReader r) : base(r) {}

        // Indexer
        public MediumTypeDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (MediumTypeDetails)InnerList[index];
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
                this.Add(new MediumTypeDetails(r));
            }
        }

        public void Remove(string typeName)
        {
            foreach(MediumTypeDetails m in this)
            {
                if (typeName == m.Name)
                {
                    Remove(m);
                    return;
                }
            }
        }

        public MediumTypeDetails Find(int typeId)
        {
            foreach(MediumTypeDetails x in this)
            {
                if (typeId == x.Id)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }

        public MediumTypeDetails Find(string typeName, bool container)
        {
            foreach(MediumTypeDetails x in this)
            {
                if (typeName == x.Name && x.Container == container)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }

        public MediumTypeDetails FindCode(string recallCode, bool container)
        {
            foreach(MediumTypeDetails x in this)
            {
                if (recallCode == x.RecallCode && x.Container == container)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }

        public MediumTypeDetails Find(string typeName, string recallCode, bool container)
        {
            foreach(MediumTypeDetails x in this)
            {
                if (typeName == x.Name && x.Container == container)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }

        public int IndexOf(string typeName)
        {
            for (int i = 0; i < this.InnerList.Count; i++ )
            {
                if (typeName == ((MediumTypeDetails)this.InnerList[i]).Name)
                {
                    return i;
                }
            }
            // Not found in collection
            return -1;
        }
    }
}
