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
    /// Parses an ING report
    /// </summary>
    public class INGParser : Parser, IParserObject
    {
        private ListTypes listType;

        public INGParser(ListTypes x) {listType = x;}

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
        private void ReadListItems(StreamReader r, ref IList il)
        {
            string fileLine = null;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // Skip any blank lines
                if (fileLine.Trim().Length == 0) continue;
                // Eliminate double spaces
                while (fileLine.IndexOf("  ") != -1) fileLine = fileLine.Replace("  ", " ");
                // Split into columns
                string[] x = fileLine.Split(new char[] {' '});
                // If fewer than three columns then break
                if (x.Length < 3) break;
                // Get the data
                string myNote = (this.DataSetNoteAction == "NO ACTION" || x.Length < 4) ? String.Empty : x[3];
                string mySerial = x[2];
                // Add to the collection
                if (il is ReceiveListItemCollection)
                {
                    il.Add(new ReceiveListItemDetails(mySerial, myNote));
                }
                else
                {
                    il.Add(new SendListItemDetails(mySerial, String.Empty, myNote, String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sl, out ReceiveListItemCollection rl)
        {
            IList il = null;
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Collect the items
            using (StreamReader r = new StreamReader(ms))
            {
                if (listType == ListTypes.Receive)
                {
                    il = (IList)rl;
                    ReadListItems(r, ref il);
                }
                else
                {
                    il = (IList)sl;
                    ReadListItems(r, ref il);
                }
            }
        }
    }
}
