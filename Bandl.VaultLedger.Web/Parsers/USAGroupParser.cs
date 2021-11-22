using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a USA Group report
    /// </summary>
    public class USAGroupParser : Parser, IParserObject
    {
        public USAGroupParser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader sr, out ListTypes listType)
        {
            string fileLine;
            listType = ListTypes.Receive;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Replace("*", String.Empty).Trim().Length == 0)
                {
                    if ((fileLine = sr.ReadLine().ToUpper()).IndexOf("SEND LIST") != -1)
                        listType = ListTypes.Send;
                    else if (fileLine.IndexOf("BRINGBACK LIST") != -1)
                        listType = ListTypes.Receive;
                    else
                        throw new ApplicationException("List type could not be determined by parser.");
                    // Move past the headers
                    while ((fileLine = sr.ReadLine()) != null)
                        if (fileLine.IndexOf("TAPE#") == 0)
                            return true;
                }
            }
            // No more headers found
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
            int i;
            string fileLine;
            string serialNo;
            string noteString = String.Empty;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // Replace tabs with spaces
                fileLine = fileLine.Replace('\t', ' ');
                // If blank line, ignore.  Look for end of list.
                if (fileLine.Trim().Length == 0)
                {
                    continue;
                }
                else if (fileLine.Replace("*", String.Empty).Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("TOTAL NO. OF TAPES") != -1)
                {
                    break;
                }
                // Get the serial number
                serialNo = (i = fileLine.IndexOf(' ')) != -1 ? fileLine.Substring(0, i).Trim() : fileLine.Trim();
                // Send list ot receive list
                if (itemCollection is SendListItemCollection)
                {
                    itemCollection.Add(new SendListItemDetails(serialNo, String.Empty, String.Empty, String.Empty));
                }
                else
                {
                    itemCollection.Add(new ReceiveListItemDetails(serialNo, i != -1 && DataSetNoteAction != "NO ACTION" ? fileLine.Substring(i+1).Trim() : String.Empty));
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
            ListTypes listType;
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
                // Move past the list headers
                if (MovePastListHeaders(sr, out listType))
                {
                    // Read the items of the list
                    if (listType == ListTypes.Receive)
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
