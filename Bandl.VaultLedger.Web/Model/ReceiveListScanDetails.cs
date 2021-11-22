using System;
using System.Data;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for ReceiveListScan.
    /// </summary>
    [Serializable]
    public class ReceiveListScanDetails : Details
    {
        private int id;
        private string name;
        private string list;
        private DateTime createDate;
        private string lastCompared;
        private ReceiveListScanItemDetails[] scanItems;
        private int itemCount; // used for browse listings (items are not retrieved)

        /// <summary>
        /// Constructor initializes new receive list scan using the data in a IDataReader
        /// </summary>
        public ReceiveListScanDetails(IDataReader reader)
        {
            // Clear the array
            scanItems = null;
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("ScanId"));
            name = reader.GetString(reader.GetOrdinal("ScanName"));
            createDate = reader.GetDateTime(reader.GetOrdinal("CreateDate"));
            list = reader.GetString(reader.GetOrdinal("ListName"));
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
                if (new Regex(@"^RE\-[0-9]{7}$").IsMatch(value) == false)
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

        public ReceiveListScanItemDetails[] ScanItems
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
