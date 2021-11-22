using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
	/// <summary>
	/// Summary description for AuditExpirationCollection.
	/// </summary>
	[Serializable]
    public class AuditExpirationCollection : BaseCollection
	{
        public AuditExpirationCollection() : base() {}
		public AuditExpirationCollection(ICollection c) : base(c) {}
		public AuditExpirationCollection(IDataReader r) : base(r) {}

		// Indexer
		public AuditExpirationDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (AuditExpirationDetails)InnerList[index];
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
                this.Add(new AuditExpirationDetails(r));
            }
        }

        public AuditExpirationDetails Find(AuditTypes auditType)
        {
            foreach(AuditExpirationDetails x in this)
            {
                if (auditType == x.AuditType )
                {
                    return x;
                }
            }
            // Not found
            return null;
        }
	}
}
