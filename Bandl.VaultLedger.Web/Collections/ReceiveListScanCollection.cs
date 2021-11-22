using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of receive list scans
    /// </summary>
    [Serializable]
    public class ReceiveListScanCollection : BaseCollection
    {
		public ReceiveListScanCollection() : base() {}
		public ReceiveListScanCollection(ICollection c) : base(c) {}
		public ReceiveListScanCollection(IDataReader r) : base(r) {}

		// Indexer
		public ReceiveListScanDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (ReceiveListScanDetails)InnerList[index];
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
				this.Add(new ReceiveListScanDetails(r));
			}
        }

        public void Remove(string scanName)
        {
            foreach(ReceiveListScanDetails scan in this)
            {
                if (scanName == scan.Name)
                {
                    Remove(scan);
                    return;
                }
            }
        }

		public ReceiveListScanDetails Find(int scanId)
		{
			foreach(ReceiveListScanDetails scan in this)
			{
				if (scanId == scan.Id)
				{
					return scan;
				}
			}
			// Not found
			return null;
		}
		
		public ReceiveListScanDetails Find(string scanName)
        {
            foreach(ReceiveListScanDetails scan in this)
            {
                if (scanName == scan.Name)
                {
                    return scan;
                }
            }
            // Not found
            return null;
        }
    }
}
