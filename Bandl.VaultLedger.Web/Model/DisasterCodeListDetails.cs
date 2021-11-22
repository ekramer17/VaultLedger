using System;
using System.Data;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for DisasterCodeList.
    /// </summary>
    [Serializable]
    public class DisasterCodeListDetails : Details
    {
        private int id;
        private string name;
        private string account;
        private DateTime createDate;
        private DLStatus status;
        private DisasterCodeListDetails[] childLists;
        private DisasterCodeListItemDetails[] listItems;
        private byte[] rowVersion = new byte[8];

        /// <summary>
        /// Constructor initializes new receive list using the data in a IDataReader
        /// </summary>
        public DisasterCodeListDetails(IDataReader reader)
        {
            // Clear the arrays
            childLists = new DisasterCodeListDetails[0];
            listItems = new DisasterCodeListItemDetails[0];
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ListId"));
            name = reader.GetString(reader.GetOrdinal("ListName"));
            createDate = reader.GetDateTime(reader.GetOrdinal("CreateDate"));
            int statusValue = reader.GetInt32(reader.GetOrdinal("Status"));
            status = (DLStatus)Enum.ToObject(typeof(DLStatus),statusValue);
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

        public DLStatus Status
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

        public DisasterCodeListDetails[] ChildLists
        {
            get {return childLists;}
            set {childLists = value;}
        }

        public DisasterCodeListItemDetails[] ListItems
        {
            get 
            {
                if (childLists.Length != 0)
                {
                    ArrayList x = new ArrayList();
                    foreach (DisasterCodeListDetails d in childLists)
                    {
                        foreach (DisasterCodeListItemDetails i in d.ListItems)
                        {
                            x.Add(i);
                        }
                    }
                    // Return the list
                    return (DisasterCodeListItemDetails[])x.ToArray(typeof(DisasterCodeListItemDetails));
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
