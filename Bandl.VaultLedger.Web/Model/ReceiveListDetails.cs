using System;
using System.Data;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for ReceiveList.
    /// </summary>
    [Serializable]
    public class ReceiveListDetails : Details
    {
        private int id;
        private string name;
        private string account;
        private DateTime createDate;
        private RLStatus status;
        private ReceiveListDetails[] childLists;
        private ReceiveListItemDetails[] listItems;
        private byte[] rowVersion = new byte[8];

        /// <summary>
        /// Constructor initializes new receive list using the data in a IDataReader
        /// </summary>
        public ReceiveListDetails(IDataReader reader)
        {
            // Clear the arrays
            childLists = new ReceiveListDetails[0];
            listItems = new ReceiveListItemDetails[0];
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ListId"));
            name = reader.GetString(reader.GetOrdinal("ListName"));
            createDate = reader.GetDateTime(reader.GetOrdinal("CreateDate"));
            status = (RLStatus)Enum.ToObject(typeof(RLStatus),reader.GetInt32(reader.GetOrdinal("Status")));
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

        public RLStatus Status
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

        public ReceiveListDetails[] ChildLists
        {
            get {return childLists;}
            set {childLists = value;}
        }

        public ReceiveListItemDetails[] ListItems
        {
            get 
            {
                if (childLists.Length != 0)
                {
                    ArrayList x = new ArrayList();
                    foreach (ReceiveListDetails d in childLists)
                    {
                        foreach (ReceiveListItemDetails i in d.ListItems)
                        {
                            x.Add(i);
                        }
                    }
                    // Return the list
                    return (ReceiveListItemDetails[])x.ToArray(typeof(ReceiveListItemDetails));
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
    }
}
