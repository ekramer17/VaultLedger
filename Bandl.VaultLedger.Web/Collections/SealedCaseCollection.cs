using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of send list items
    /// </summary>
    [Serializable]
    public class SealedCaseCollection : BaseCollection
    {
        public SealedCaseCollection() : base() {}
        public SealedCaseCollection(ICollection c) : base(c) {}
        public SealedCaseCollection(IDataReader r) : base(r) {}
        public SealedCaseCollection(SendListDetails sendList) : base()  {this.Add(sendList);}

        // Indexer
        public SealedCaseDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (SealedCaseDetails)InnerList[index];
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
                this.Add(new SealedCaseDetails(r));
            }
        }

        public SealedCaseDetails Find(string caseName)
        {
            foreach(SealedCaseDetails c in this)
            {
                if (caseName == c.CaseName)
                {
                    return c;
                }
            }
            // return
            return null;
        }

        public void Remove(int caseId)
        {
            foreach(SealedCaseDetails c in this)
            {
                if (caseId == c.Id)
                {
                    Remove(c);
                    return;
                }
            }
        }

        public SealedCaseDetails Find(int id)
        {
            foreach(SealedCaseDetails c in this)
            {
                if (id == c.Id)
                {
                    return c;
                }
            }
            // Not found
            return null;
        }

        public void Remove(string caseName)
        {
            foreach(SealedCaseDetails c in this)
            {
                if (caseName == c.CaseName)
                {
                    Remove(c);
                    return;
                }
            }
        }
    }
}
