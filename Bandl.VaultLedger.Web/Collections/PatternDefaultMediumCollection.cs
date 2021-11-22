using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of PatternDefaultMediumDetails objects
    /// </summary>
    [Serializable]
    public class PatternDefaultMediumCollection : BaseCollection
    {
        public PatternDefaultMediumCollection() : base() {}
        public PatternDefaultMediumCollection(IDataReader r) : base(r) {}

		// Indexer
		public PatternDefaultMediumDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (PatternDefaultMediumDetails)InnerList[index];
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
				InnerList.Add(new PatternDefaultMediumDetails(r));
			}
		}

        public PatternDefaultMediumDetails Find(string pattern)
        {
            foreach(PatternDefaultMediumDetails x in this)
            {
                if (pattern == x.Pattern)
                {
                    return x;
                }
            }
            // Not found
            return null;
        }

		public override void Insert(int index, object o)
		{
			// If element already in collection then return
			if (index == InnerList.Count && index != 0) 
			{
				throw new ApplicationException("Cannot add a pattern after the catch-all.");
			}
			else
			{
				base.Insert(index, o);
			}
		}

		public override void Remove(object o)
		{
			// Cannot remove last element
			if (o == InnerList[InnerList.Count-1])
			{
				throw new ApplicationException("Cannot remove catch-all pattern");
			}
			else
			{
				base.Remove(o);
			}
		}

		public void Remove(string pattern)
		{
			foreach(PatternDefaultMediumDetails x in this)
			{
				if (pattern == x.Pattern)
				{
					Remove(x);
					return;
				}
			}
		}
	}
}
