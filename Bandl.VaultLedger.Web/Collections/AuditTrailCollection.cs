using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
	/// <summary>
	/// Summary description for AuditTrailCollection.
	/// </summary>
    [Serializable]
    public class AuditTrailCollection : BaseCollection
	{
        public AuditTrailCollection() : base() {}
		public AuditTrailCollection(ICollection c) : base(c) {}
		public AuditTrailCollection(IDataReader r) : base(r) {}

		// Indexer
		public AuditTrailDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (AuditTrailDetails)InnerList[index];
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
                this.Add(new AuditTrailDetails(r));
            }
        }
    }
}
