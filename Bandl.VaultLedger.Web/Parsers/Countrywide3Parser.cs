using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ConsecoParser.
    /// </summary>
    public class Countrywide3Parser : Parser, IParserObject
    {
        private string fileLine = null;

        public Countrywide3Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader r)
        {
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("MEDIA ID") != -1)
                {
                    break;
                }
            }
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
        private void ReadListItems(StreamReader sr, ref ReceiveListItemCollection r)
        {
            while ((fileLine = sr.ReadLine()) != null)
                if (fileLine.Trim().Length != 0)
                    r.Add(new ReceiveListItemDetails(fileLine.Trim(), String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection si, out ReceiveListItemCollection ri)
        {
            // Create the new collections
            si = new SendListItemCollection();
            ri = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the parser and obtain the items.  Countrywide
            // always creates send lists; never receive lists.
            using (StreamReader r = new StreamReader(ms))
            {
                // Move past the list headers
                MovePastListHeaders(r);
                // These reports are always receive lists
                ReadListItems(r, ref ri);
            }
        }
    }
}
