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
    public class SendListCaseCollection : BaseCollection
    {
		public SendListCaseCollection() : base() {}
		public SendListCaseCollection(ICollection c) : base(c) {}
		public SendListCaseCollection(IDataReader r) : base(r) {}
        public SendListCaseCollection(SendListDetails sendList) : base()  {this.Add(sendList);}

		// Indexer
		public SendListCaseDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (SendListCaseDetails)InnerList[index];
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

        public int Add(SendListDetails sendList)
        {
            int totalAdded = 0;

            if (sendList != null)
            {
                if (!sendList.IsComposite)
                {
                    totalAdded += this.Add(sendList.ListCases);
                }
                else
                {
                    foreach (SendListDetails childList in sendList.ChildLists)
                    {
                        totalAdded += this.Add(childList.ListCases);
                    }
                }
            }

            return totalAdded;
        }

        public override void Fill(IDataReader r)
        {
			while(r.Read() == true)
			{
				this.Add(new SendListCaseDetails(r));
			}
        }

        public SendListCaseDetails Find(string caseName)
        {
            foreach(SendListCaseDetails listCase in this)
            {
                if (caseName == listCase.Name)
                {
                    return listCase;
                }
            }
            // return
            return null;
        }

		public void Remove(int caseId)
		{
			foreach(SendListCaseDetails c in this)
			{
				if (caseId == c.Id)
				{
					Remove(c);
					return;
				}
			}
		}

		public void Remove(string caseName)
        {
            foreach(SendListCaseDetails c in this)
            {
                if (caseName == c.Name)
                {
                    Remove(c);
                    return;
                }
            }
        }
    }
}
