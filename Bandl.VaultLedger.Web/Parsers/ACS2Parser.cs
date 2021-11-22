using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.IParser;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ACS2.
    /// </summary>
    public class ACS2Parser : Parser, IParserObject
    {
        ListTypes listType;

        public ACS2Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            string fileLine;

            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().ToUpper().StartsWith("SUBJECT") == true)
                {
                    continue;
                }
                else if (fileLine.IndexOf("Please SEND to the vault") != -1)
                {
                    listType = ListTypes.Send;
                    return true;
                }
                else if (fileLine.IndexOf("Tapes to SEND to Recall") != -1)
                {
                    listType = ListTypes.Send;
                    return true;
                }
                else if (fileLine.IndexOf("Tapes to RETURN from Recall") != -1)
                {
                    listType = ListTypes.Receive;
                    return true;
                }
            }
            // No header found
            return false;
        }
        
        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="il">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadListItems(StreamReader r, ref IList il)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // If we've reached a blank line then break
                if (fileLine.Trim() == String.Empty)
                {
                    break;
                }
                else if (fileLine.Trim().StartsWith("="))
                {
                    continue;
                }
                else if (il is ReceiveListItemCollection)
                {
                    il.Add(new ReceiveListItemDetails(fileLine.Trim(), String.Empty));
                }
                else
                {
                    il.Add(new SendListItemDetails(fileLine.Trim(), String.Empty, String.Empty, String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli)
        {
            IList il;
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Get the list items
            using (StreamReader r = new StreamReader(ms))
            {
                if (MovePastListHeaders(r) == true)
                {
                    if (listType == ListTypes.Send)
                    {
                        il = (IList)sli;
                        ReadListItems(r, ref il);
                    }
                    else
                    {
                        il = (IList)rli;
                        ReadListItems(r, ref il);
                    }
                }
            }
        }
    }
}
