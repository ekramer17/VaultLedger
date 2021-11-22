using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of ExternalSiteDetails objects
    /// </summary>
    [Serializable]
    public class ExternalSiteCollection : BaseCollection
    {
		public ExternalSiteCollection() : base() {}
		public ExternalSiteCollection(ICollection c) : base(c) {}
		public ExternalSiteCollection(IDataReader r) : base(r) {}

		// Indexer
		public ExternalSiteDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (ExternalSiteDetails)InnerList[index];
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
                this.Add(new ExternalSiteDetails(r));
        }

        public void Remove(string siteName)
        {
            foreach(ExternalSiteDetails s in this)
            {
                if (siteName == s.Name)
                {
                    Remove(s);
                    break;
                }
            }
        }

		public ExternalSiteDetails Find(int siteId)
		{
			foreach(ExternalSiteDetails s in this)
			{
				if (siteId == s.Id)
				{
					return s;
				}
			}
			// Not found
			return null;
		}
		
		public ExternalSiteDetails Find(string siteName)
        {
            foreach(ExternalSiteDetails s in this)
            {
                if (siteName == s.Name)
                {
                    return s;
                }
            }
            // Not found
            return null;
        }
    }
}
