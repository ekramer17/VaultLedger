using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.IParser;
using System.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a standard Recall report.  We defined the standard.
    /// </summary>
    public class LoewsParser : Parser, IParserObject
    {
        public LoewsParser() {}

        /// <summary>
        /// Gets the list type
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if type was found, else false
        /// </returns>
        private bool GetListType(StreamReader sr, out ListTypes listType)
        {
            string fileLine;
            listType = ListTypes.Receive;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("LOEWS CORPORATION") != -1)
                {
                    listType = fileLine.ToUpper().IndexOf("SHIPPING") != -1 ? ListTypes.Send : ListTypes.Receive;
                    return true;
                }
            }
            // Return unsuccessful
            return false;
        }
        
        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            int ptr;
            string serialNo;
            string fileLine;
            string noteString = String.Empty;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If we've reached a blank line, exit
                if (fileLine.Trim().Length != 0 && (ptr = fileLine.IndexOf(',')) != -1)
                {
                    // Get the serial number
                    serialNo = fileLine.Substring(0, ptr).Trim();
                    // Get the note string
                    if (DataSetNoteAction != "NO ACTION")
                        noteString = fileLine.Substring(ptr+1).Trim();
                    // Create the list item
                    if (itemCollection is ReceiveListItemCollection)
                    {
                        itemCollection.Add(new ReceiveListItemDetails(serialNo, noteString));
                    }
                    else
                    {
                        itemCollection.Add(new SendListItemDetails(serialNo, String.Empty, noteString, String.Empty));
                    }
                }
            }
        }

        /// <summary>
        /// Parses the given text array and returns send list items and 
        /// receive list items.  Use this overload if the stream is a
        /// new TMS send/receive list report, e.g. CA-25.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="sendCollection">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="receiveCollection">
        /// Receptacle for returned receive list item collection
        /// </param>
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            IList lc;
            ListTypes listType;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader sr = new StreamReader(ms))
            {
                // Get list type
                if (GetListType(sr, out listType) == true)
                {
                    lc = listType != ListTypes.Send ? (IList)receiveCollection : (IList)sendCollection;
                    ReadListItems(sr, ref lc);
                }
            }
        }
    }
}
