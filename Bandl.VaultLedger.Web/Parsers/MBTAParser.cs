using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Parses an MBTA report
	/// </summary>
	public class MBTAParser : Parser, IParserObject
	{
        private int serialPos = -1;
        private int serialLen = -1;
        private int dataPos = -1;
        private int dataLen = -1;

        public MBTAParser() {}
        
        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader sr)
        {
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (String.Empty == fileLine.Replace("-", String.Empty).Trim())
                {
                    sr.ReadLine(); // Skip next line, which is blank
                    break;
                }
                else if (fileLine.IndexOf("-- DATA SET NAME --") != -1)
                {
                    // Get header indexes
                    serialPos = fileLine.IndexOf("SERIAL");
                    dataPos = fileLine.IndexOf("I-----");
                    // Get lengths
                    serialLen = dataPos - serialPos;
                    dataLen = fileLine.IndexOf("SEQ") - dataPos;
                }
            }
        }

        
        /// <summary>
        /// Reads the items for a single distribution list in the CA25 report.
        /// Stream reader should be positioned before the first item of the 
        /// list upon entry.
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the CA25 report file
        /// </param>
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Number of items added
        /// </returns>
        private void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            string notes;
            string fileLine;
            string serialNo;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null && fileLine.IndexOf("'MASS BAY TRANSIT AUTHORITY'") == -1)
            {
                // Break if we have reached the end of the list
                if (fileLine.IndexOf("'MASS BAY TRANSIT AUTHORITY'") != -1)
                {
                    break;
                }
                else if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                // Get the serial number
                serialNo = fileLine.Substring(serialPos, serialLen).Trim();
                // Get the notes (data set) if we need them
                if (this.DataSetNoteAction != "NO ACTION")
                {
                    notes = fileLine.Substring(dataPos, dataLen).Trim();
                }
                else
                {
                    notes = String.Empty;
                }
                // Construct an item of the correct type and fill it
                if (itemCollection is ReceiveListItemCollection)
                {
                    ReceiveListItemDetails newItem = new ReceiveListItemDetails(serialNo, notes);
                    itemCollection.Add(newItem);
                }
                else
                {
                    SendListItemDetails newItem = new SendListItemDetails(serialNo, String.Empty, notes, String.Empty);
                    // Add the item to the collection
                    itemCollection.Add(newItem);
                }
            }
        }

        /// <summary>
        /// Determines whether or not we're making send list items or receive
        /// list items.
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="itemType">
        /// True if we're creating receive list items, false for send list
        /// </param>
        /// <returns>
        /// One if itemType could be determined, else zero
        /// </returns>
        private int DetermineListItemType(StreamReader sr, out bool itemType)
        {
            string fileLine;
            itemType = false;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Length != 0)
                {
                    if (fileLine.Substring(1).Trim().Substring(0,5) == "FROM ")
                    {
                        itemType = (fileLine.IndexOf("OFFSITE STORAGE") != -1);
                        return 1;
                    }
                }
            }
            // itemType could not be determined
            return 0;
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
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            bool createReceive;
            IList listCollection;
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
                // Read through the stream
                while (DetermineListItemType(sr, out createReceive) != 0)
                {
                    // Move past the list headers
                    MovePastListHeaders(sr);
                    // Read the items of the list
                    if (createReceive == true)
                    {
                        listCollection = (IList)receiveCollection;
                        ReadListItems(sr, ref listCollection);
                    }
                    else 
                    {
                        listCollection = (IList)sendCollection;
                        ReadListItems(sr, ref listCollection);
                    }
                }
            }
        }
	}
}
