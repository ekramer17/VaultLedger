using System;
using System.Data;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for SendListScan.
    /// </summary>
    [Serializable]
    public class SendListScanDetails : Details
    {
        private int id;
        private string name;
        private string list;
        private DateTime createDate;
        private string lastCompared;
        private SendListScanItemDetails[] scanItems;
        private int itemCount; // used for browse listings (items are not retrieved)

        /// <summary>
        /// Constructor initializes new send list scan using the data in a IDataReader
        /// </summary>
        public SendListScanDetails(IDataReader reader)
        {
            // Clear the array
            scanItems = new SendListScanItemDetails[0];
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ScanId"));
            name = reader.GetString(reader.GetOrdinal("ScanName"));
            list = reader.GetString(reader.GetOrdinal("ListName"));
            createDate = reader.GetDateTime(reader.GetOrdinal("CreateDate"));
            lastCompared = reader.GetString(reader.GetOrdinal("Compared"));
            // Itemcount may or may not be present
            try {itemCount = reader.GetInt32(reader.GetOrdinal("ItemCount"));}
            catch {itemCount = -1;}
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
            set 
            {
                if (value == null || value.Trim() == String.Empty)
                    throw new ValueRequiredException("Name", "File name is a required field.");
                else if (this.ContainsSQLWildcards(value) == true)
                    throw new ValueException("Name", "File name may not contain percent signs or underscores.");
                // Set the file name
                name = value;
                // Set the object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public int ItemCount
        {
            get {return itemCount;}
        }

        public string ListName
        {
            get {return list;}
            set 
            {
                if (new Regex(@"^SD\-[0-9]{7}$").IsMatch(value) == false)
                    throw new ValueException("ListName", "List name is of an invalid format.");
                // Set list
                list = value;
                // Set the object state to modified
                this.ObjState = ObjectStates.Modified;
            }        
        }

        public string LastCompared
        {
            get {return lastCompared;}
        }

        public DateTime CreateDate
        {
            get {return createDate;}
        }

        public SendListScanItemDetails[] ScanItems
        {
            get {return scanItems;}
            set 
            {
                scanItems = value;
                itemCount = scanItems.Length;
            }
        }
    }
}
