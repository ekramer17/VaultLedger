using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
	/// <summary>
	/// Collection of OperatorDetails objects
	/// </summary>
    [Serializable]
	public class OperatorCollection : BaseCollection
	{
        public OperatorCollection() : base() {}
		public OperatorCollection(ICollection c) : base(c) {}
		public OperatorCollection(IDataReader r) : base(r) {}

		// Indexer
		public OperatorDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (OperatorDetails)InnerList[index];
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
				this.Add(new OperatorDetails(r));
			}
        }

        public void Remove(string login)
        {
            foreach(OperatorDetails x in this)
            {
                if (login == x.Name)
                {
                    Remove(x);
                    break;
                }
            }
        }

		public OperatorDetails Find(int operatorId)
		{
			foreach(OperatorDetails x in this)
			{
				if (operatorId == x.Id)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}

		public OperatorDetails Find(string login)
		{
			foreach(OperatorDetails x in this)
			{
				if (login == x.Login)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}
    }
}
