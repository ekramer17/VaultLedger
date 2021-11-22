using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of PatternIgnoreDetails objects
    /// </summary>
    [Serializable]
    public class PatternIgnoreCollection : BaseCollection
    {
		public PatternIgnoreCollection() {}
		public PatternIgnoreCollection(ICollection c) : base(c) {}
		public PatternIgnoreCollection(IDataReader r) : base (r) {}

		// Indexer
		public PatternIgnoreDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (PatternIgnoreDetails)InnerList[index];
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
				this.Add(new PatternIgnoreDetails(r));
			}
        }

		public PatternIgnoreDetails Find(int patternId)
		{
			foreach(PatternIgnoreDetails x in this)
			{
				if (patternId == x.Id)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}

		public PatternIgnoreDetails Find(string pattern)
		{
			foreach(PatternIgnoreDetails x in this)
			{
				if (pattern == x.Pattern)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}

        public void Remove(string pattern)
        {
            foreach(PatternIgnoreDetails p in this)
            {
                if (pattern == p.Pattern)
                {
                    Remove(p);
                    return;
                }
            }
        }
    }
}
