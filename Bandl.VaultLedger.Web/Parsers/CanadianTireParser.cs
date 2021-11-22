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
    /// Parses a Canadian Tire report
    /// </summary>
    public class CanadianTireParser : Parser, IParserObject
    {
        public CanadianTireParser() {}

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
                if (fileLine.ToUpper().IndexOf("CANADIAN TIRE RETURN") != -1)
                {
                    listType = ListTypes.Receive;
                    return true;
                }
                else if (fileLine.ToUpper().IndexOf("CANADIAN TIRE PICK") != -1)
                {
                    listType = ListTypes.Send;
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
        private void ReadListItems(StreamReader sr, ref IList il)
        {
            string fileLine;
            char[] c = new char[] {' ', '\t'};
            // Read through the file, collecting items
            while ((fileLine = LeftTrim(sr.ReadLine())) != null)
            {
                if (fileLine.Length < 10)
                {
                    continue;
                }
                else if (fileLine.ToUpper().Substring(0,6) == "TOTAL ")
                {
                    continue;
                }
                else
                {
                    string n = String.Empty;
                    // Skip to the second space; if fewer than three fields, skip line
                    string[] fields = fileLine.Split(c);
                    // Get the notes field
                    if (DataSetNoteAction != "NO ACTION") n = fileLine.Substring(fileLine.IndexOf(fields[2]) + fields[2].Length).Trim();
                    // Send list or receive list?
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(fields[2].ToUpper(), n));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(fields[2].ToUpper(), String.Empty, n, String.Empty));
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
            IList il;
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
            using (StreamReader r = new StreamReader(ms))
            {
                // Move past the list headers
                if (MovePastListHeaders(r, out listType))
                {
                    // Read the items of the list
                    if (listType == ListTypes.Receive)
                    {
                        il = (IList)receiveCollection;
                        ReadListItems(r, ref il);
                    }
                    else 
                    {
                        il = (IList)sendCollection;
                        ReadListItems(r, ref il);
                    }
                }
            }
        }
    }
}
