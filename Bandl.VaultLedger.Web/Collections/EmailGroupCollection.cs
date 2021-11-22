using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of EmailGroupDetails objects
    /// </summary>
    [Serializable]
    public class EmailGroupCollection : BaseCollection
    {
        // Constructors
        public EmailGroupCollection() : base() {}
        public EmailGroupCollection(ICollection c) : base(c) {}
        public EmailGroupCollection(IDataReader r) : base(r) {}

        // Indexer
        public EmailGroupDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (EmailGroupDetails)InnerList[index];
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
                this.Add(new EmailGroupDetails(r));
            }
        }

        public void Remove(string groupName)
        {
            foreach(EmailGroupDetails x in this)
            {
                if (groupName == x.Name)
                {
                    Remove(x);
                    break;
                }
            }
        }

        public EmailGroupDetails Find(int id)
        {
            foreach(EmailGroupDetails x in this)
            {
                if (id == x.Id)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }
		
        public EmailGroupDetails Find(string groupName)
        {
            foreach(EmailGroupDetails x in this)
            {
                if (groupName == x.Name)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }

        public int IndexOf(string groupName)
        {
            for (int i = 0; i < this.InnerList.Count; i++ )
            {
                if (groupName == ((EmailGroupDetails)this.InnerList[i]).Name)
                {
                    return i;
                }
            }
            // Not found in collection
            return -1;
        }
    }
}
