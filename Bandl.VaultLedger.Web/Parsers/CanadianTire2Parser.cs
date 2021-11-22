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
    public class CanadianTire2Parser : Parser, IParserObject
    {
        public CanadianTire2Parser() {}

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
        private void ReadListItems(StreamReader r, ref SendListItemCollection sl, ref ReceiveListItemCollection rl)
        {
            string myLine;
            // Read through the file, collecting items
            while ((myLine = r.ReadLine()) != null)
            {
                myLine = myLine.ToUpper().Trim();
                // Change list type?
                if (myLine.IndexOf("RETRIEVE FROM OFFSITE") != -1)
                {
                    rl.Add(new ReceiveListItemDetails(myLine.Substring(0, myLine.IndexOf(' ')), String.Empty));
                }
                else if (myLine.IndexOf("IS TO BE SENT OFFSITE") != -1)
                {
                    sl.Add(new SendListItemDetails(myLine.Substring(0, myLine.IndexOf(' ')), String.Empty, String.Empty, String.Empty));
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
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader r = new StreamReader(ms))
            {
                ReadListItems(r, ref sl, ref rl);
            }
        }
    }
}
