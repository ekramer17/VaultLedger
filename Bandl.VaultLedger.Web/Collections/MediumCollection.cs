using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of MediumDetails objects
    /// </summary>
    [Serializable]
    public class MediumCollection : BaseCollection
    {
		public MediumCollection() : base() {}
		public MediumCollection(ICollection c) : base(c) {}
		public MediumCollection(IDataReader r) : base(r) {}

		// Indexer
		public MediumDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (MediumDetails)InnerList[index];
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
                this.Add(new MediumDetails(r));
        }

        public void Remove(string serialNo)
        {
            foreach(MediumDetails m in this)
            {
                if (serialNo == m.SerialNo)
                {
                    Remove(m);
                    break;
                }
            }
        }

		public MediumDetails Find(int mediumId)
		{
			foreach(MediumDetails x in this)
			{
				if (mediumId == x.Id)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}

		public MediumDetails Find(string serialNo)
		{
			foreach(MediumDetails x in this)
			{
				if (serialNo == x.SerialNo)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}
    }
}
