using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for DomesticSendParser.
    /// </summary>
    public class DomesticSendParser : Parser, IParserObject
    {
        public DomesticSendParser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader sr)
        {
            string fileLine;
            // Read until past the headers
            while ((fileLine = sr.ReadLine()) != null)
                if (fileLine.IndexOf("Export Time:") != -1)
                    while ((fileLine = sr.ReadLine()) != null)
                        if (fileLine.IndexOf('-') != -1 && fileLine.Replace("-",String.Empty).Trim().Length == 0)
                            return true;
            // Headers not found
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
        private void ReadListItems(StreamReader sr, ref ReceiveListItemCollection rlic)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
                if (fileLine.Trim().Length != 0)
                    rlic.Add(new ReceiveListItemDetails(fileLine.Substring(0, fileLine.IndexOf(' ')), String.Empty));
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
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the parser and obtain the items.  Domestic
            // send lists can only create receive lists as output.
            using (StreamReader sr = new StreamReader(ms))
            {
                if (MovePastListHeaders(sr))
                    ReadListItems(sr, ref receiveCollection);
            }
        }
    }
}
