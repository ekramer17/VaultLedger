using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of FtpProfileDetails objects
    /// </summary>
    [Serializable]
    public class FtpProfileCollection : BaseCollection
	{
        // Constructors
        public FtpProfileCollection() : base() {}
        public FtpProfileCollection(ICollection c) : base(c) {}
        public FtpProfileCollection(IDataReader r) : base(r) {}

        // Indexer
        public FtpProfileDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (FtpProfileDetails)InnerList[index];
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
                this.Add(new FtpProfileDetails(r));
            }
        }

        public void Remove(string profileName)
        {
            foreach(FtpProfileDetails x in this)
            {
                if (profileName == x.Name)
                {
                    Remove(x);
                    break;
                }
            }
        }

        public FtpProfileDetails Find(int id)
        {
            foreach(FtpProfileDetails x in this)
            {
                if (id == x.Id)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }
		
        public FtpProfileDetails Find(string profileName)
        {
            foreach(FtpProfileDetails x in this)
            {
                if (profileName == x.Name)
                {
                    return(x);
                }
            }
            // Not found
            return null;
        }
    }
}
