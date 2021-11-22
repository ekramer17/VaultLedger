using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
	/// <summary>
	/// Represents a collection of AccountDetails objects
	/// </summary>
	[Serializable]
	public class AccountCollection : BaseCollection
	{
		// Constructors
		public AccountCollection() : base() {}
		public AccountCollection(ICollection c) : base(c) {}
		public AccountCollection(IDataReader r) : base(r) {}

		// Indexer
        public AccountDetails this [int index]
        {
            get
            {
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (AccountDetails)InnerList[index];
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
				this.Add(new AccountDetails(r));
			}
        }

        public void Remove(string accountName)
        {
            foreach(AccountDetails a in this)
            {
                if (accountName == a.Name)
                {
                    Remove(a);
                    break;
                }
            }
        }

		public AccountDetails Find(int id)
		{
			foreach(AccountDetails x in this)
			{
				if (id == x.Id)
				{
					return(x);
				}
			}
			// Not found
			return null;
		}
		
		public AccountDetails Find(string accountName)
        {
			foreach(AccountDetails x in this)
			{
				if (accountName == x.Name)
				{
					return(x);
				}
			}
            // Not found
            return null;
        }

		public int IndexOf(string accountName)
		{
			for (int i = 0; i < this.InnerList.Count; i++ )
			{
				if (accountName == ((AccountDetails)this.InnerList[i]).Name)
				{
					return i;
				}
			}
			// Not found in collection
			return -1;
		}
	}
}
