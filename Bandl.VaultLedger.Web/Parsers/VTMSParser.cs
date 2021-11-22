using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for VTMSParser.
	/// </summary>
	public class VTMSParser : Parser, IParserObject
	{
        private ListTypes listType; // Send or receive list - given on construction because this is discerned through file name

		public VTMSParser(bool sendList)
		{
            listType = sendList ? ListTypes.Send : ListTypes.Receive;
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
            int elementNo;
            string fileLine;
            char[] charArray = new char[] {' '};
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                elementNo = 0;
                fileLine = fileLine.Trim();
                string[] elements = fileLine.Split(charArray);
                // Third field is the serial number
                for (int i = 0; i < elements.Length && elementNo != 3; i++)
                {
                    if (elements[i].Length != 0)
                    {
                        // Add one to the element count
                        elementNo += 1;
                        // If we're on the third element, get the serial number
                        if (elementNo == 3)
                        {
                            if (itemCollection is ReceiveListItemCollection)
                            {
                                ReceiveListItemDetails newItem = new ReceiveListItemDetails(elements[i], String.Empty);
                                itemCollection.Add(newItem);
                            }
                            else
                            {
                                SendListItemDetails newItem = new SendListItemDetails(elements[i], String.Empty, String.Empty, String.Empty);
                                itemCollection.Add(newItem);
                            }
                        }
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
