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
    /// Parses a ADP report
    /// </summary>
    public class ADP2Parser : Parser, IParserObject
    {
        public ADP2Parser() {}

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
                if (fileLine.ToUpper().IndexOf("REQUEST TO SEND MEDIA OFF-SITE") != -1)
                {
                    listType = ListTypes.Send;
                }
                else if (fileLine.ToUpper().IndexOf("REQUEST TO RECEIVE MEDIA ON-SITE") != -1)
                {
                    listType = ListTypes.Receive;
                }
                else if (fileLine.ToUpper().IndexOf("MEDIA TYPE") != -1 && fileLine.ToUpper().IndexOf("MM") != -1)
                {
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
            string fileLine = null;
            int mm = 0, dd = 0, yyyy = 0;
            char[] c = new char[] {'\t'};
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length == 0)
                {
                    continue;
                }
                else if (fileLine.ToUpper().IndexOf("BELOW TO BE COMPLETED") != -1)
                {
                    break;
                }
                else
                {
                    int j = 0;
                    string serial = String.Empty;
                    bool rd = il is SendListItemCollection;
                    // Remove the tab characters at the beginning
                    while (fileLine[0] == '\t') fileLine = fileLine.Substring(1);
                    // Split on the tabs
                    string[] x = fileLine.Split(c);
                    // Cycle through the fields
                    for (int i = 0; i < x.Length; i++)
                    {
                        if (x[i].Length != 0)
                        {
                            switch (j += 1)
                            {
                                case 3:
                                    serial = x[i].Trim();
                                    break;
                                case 4:
                                    if (rd) mm = Int32.Parse(x[i].Trim());
                                    break;
                                case 5:
                                    if (rd) dd = Int32.Parse(x[i].Trim());
                                    break;
                                case 6:
                                    if (rd) yyyy = Int32.Parse(x[i].Trim());
                                    break;
                            }
                        }
                    }
                    // Create an item if we have a serial number
                    if (serial.Length != 0)
                    {
                        // Send list or receive list?
                        if (il is ReceiveListItemCollection)
                        {
                            il.Add(new ReceiveListItemDetails(serial, String.Empty));
                        }
                        else
                        {
                            string r = EmployReturnDate && mm != 0 ? new DateTime(yyyy, mm, dd).ToString("yyyy-MM-dd") : String.Empty;
                            il.Add(new SendListItemDetails(serial, r, String.Empty, String.Empty));
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
