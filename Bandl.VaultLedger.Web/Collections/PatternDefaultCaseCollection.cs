using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of PatternDefaultCaseDetails objects
    /// </summary>
    [Serializable]
    public class PatternDefaultCaseCollection : BaseCollection
    {
		public PatternDefaultCaseCollection() : base() {}
        public PatternDefaultCaseCollection(IDataReader r) : base(r) {}

		// Indexer
		public PatternDefaultCaseDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (PatternDefaultCaseDetails)InnerList[index];
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
				InnerList.Add(new PatternDefaultCaseDetails(r));
			}
		}

        public PatternDefaultCaseDetails Find(string pattern)
        {
            foreach(PatternDefaultCaseDetails x in this)
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
            foreach(PatternDefaultCaseDetails x in this)
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
