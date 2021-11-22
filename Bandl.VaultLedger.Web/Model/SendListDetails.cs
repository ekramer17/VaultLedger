using System;
using System.Data;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
	/// Summary description for SendList.
	/// </summary>
    [Serializable]
    public class SendListDetails : Details
	{
        private int id;
        private string name;
        private string account;
        private DateTime createDate;
        private SLStatus status;
        private SendListDetails[] childLists;
        private SendListItemDetails[] listItems;
        private SendListCaseDetails[] listCases;
        private byte[] rowVersion = new byte[8];

        /// <summary>
        /// Constructor initializes new send list using the data in a IDataReader
        /// </summary>
        public SendListDetails(IDataReader reader)
        {
            // Clear the arrays
            childLists = new SendListDetails[0];
            listItems = new SendListItemDetails[0];
            listCases = new SendListCaseDetails[0];
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ListId"));
            name = reader.GetString(reader.GetOrdinal("ListName"));
            createDate = reader.GetDateTime(reader.GetOrdinal("CreateDate"));
            status = (SLStatus)Enum.ToObject(typeof(SLStatus),reader.GetInt32(reader.GetOrdinal("Status")));
            account = reader.GetString(reader.GetOrdinal("AccountName"));
            reader.GetBytes(reader.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Set row state to unmodified
            this.ObjState = ObjectStates.Unmodified;
        }

        public int Id
        {
            get {return id;}
        }

        public string Name
        {
            get {return name;}
        }

        public string Account
        {
            get {return account;}
        }

        public DateTime CreateDate
        {
            get {return createDate;}
        }

        public SLStatus Status
        {
            get {return status;}
        }

        public bool IsComposite
        {
            get {return account != String.Empty ? false : true;}
        }

        public byte[] RowVersion
        {
            get {return rowVersion;}
        }

        public SendListDetails[] ChildLists
        {
            get {return childLists;}
            set {childLists = value;}
        }

        public SendListItemDetails[] ListItems
        {
            get 
            {
                if (childLists.Length != 0)
                {
                    ArrayList x = new ArrayList();
                    foreach (SendListDetails d in childLists)
                    {
                        foreach (SendListItemDetails i in d.ListItems)
                        {
                            x.Add(i);
                        }
                    }
                    // Return the list
                    return (SendListItemDetails[])x.ToArray(typeof(SendListItemDetails));
                }
                else
                {
                    return listItems;
                }
            }
            set 
            {
                listItems = value;
            }
        }

        public SendListCaseDetails[] ListCases
        {
            get {return listCases;}
            set {listCases = value;}
        }
	}
}
