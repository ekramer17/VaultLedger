using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of send list scans
    /// </summary>
    [Serializable]
    public class SendListScanCollection : BaseCollection
    {
		public SendListScanCollection() {}
		public SendListScanCollection(ICollection c) : base(c) {}
		public SendListScanCollection(IDataReader r) : base(r) {}

		// Indexer
		public SendListScanDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (SendListScanDetails)InnerList[index];
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
				this.Add(new SendListScanDetails(r));
			}
        }

        public void Remove(string scanName)
        {
            foreach(SendListScanDetails s in this)
            {
                if (scanName == s.Name)
                {
                    Remove(s);
                    return;
                }
            }
        }

		public SendListScanDetails Find(int scanId)
		{
			foreach(SendListScanDetails s in this)
			{
				if (scanId == s.Id)
				{
					return s;
				}
			}
			// Not found
			return null;
		}
		
		public SendListScanDetails Find(string scanName)
        {
            foreach(SendListScanDetails s in this)
            {
                if (scanName == s.Name)
                {
                    return s;
                }
            }
            // Not found
            return null;
        }
    }
}
