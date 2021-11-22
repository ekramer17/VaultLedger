using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of PreferenceDetails objects
    /// </summary>
    [Serializable]
    public class PreferenceCollection : BaseCollection
    {
        public PreferenceCollection() : base() {}
        public PreferenceCollection(ICollection c) : base(c) {}
        public PreferenceCollection(IDataReader r) : base(r) {}

        // Indexer
        public PreferenceDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (PreferenceDetails)InnerList[index];
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
                this.Add(new PreferenceDetails(r));
            }
        }

        public void Remove(PreferenceKeys key)
        {
            foreach(PreferenceDetails x in this)
            {
                if (key == x.Key)
                {
                    Remove(x);
                    break;
                }
            }
        }

        public PreferenceDetails Find(PreferenceKeys key)
        {
            foreach(PreferenceDetails x in this)
            {
                if (key == x.Key)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }
    }
}
