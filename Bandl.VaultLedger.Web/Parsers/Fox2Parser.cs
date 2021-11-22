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
    /// Parses a Fox report
    /// </summary>
    public class Fox2Parser : Parser, IParserObject
    {
        public Fox2Parser() {}

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
        private void ReadListItems(StreamReader r, ref ReceiveListItemCollection rl)
        {
            string fileLine = null;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // Skip blank lines
                if (fileLine.Trim().Length == 0) continue;
                // Remove quotes, split on commas
                string[] x = fileLine.Replace("\"", "").Trim().Split(new char[] {','});
                // If first string is "TOTAL", then break
                if (x[0].StartsWith("TOTAL")) break;
                // Get serial number number and note
                string mySerial = x[0].Trim();
                string myNote = this.DataSetNoteAction != "NO ACTION" ? x[2].Trim() : String.Empty;
                // Add list item
                rl.Add(new ReceiveListItemDetails(mySerial, myNote));
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
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // First line contains headers
                r.ReadLine();
                // Read the items
                ReadListItems(r, ref rl);
            }
        }
    }
}
