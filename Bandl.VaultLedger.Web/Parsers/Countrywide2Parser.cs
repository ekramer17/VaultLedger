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
    public class Countrywide2Parser : Parser, IParserObject
    {
        ListTypes t1 = ListTypes.Send;

        public Countrywide2Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader r)
        {
            string fileLine;
            t1 = ListTypes.Send;
            // Run through, stop after last header
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("COUNTRYWIDE REC") != -1)
                {
                    t1 = ListTypes.Receive;
                }
                else if (fileLine.Replace(", ",",").ToLower().IndexOf("media id,notes,return") == 0)
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
        private void ReadListItems(StreamReader r, ref IList i)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length != 0)
                {
                    if (fileLine.IndexOf(',') == -1)
                    {
                        if (i is ReceiveListItemCollection)
                            i.Add(new ReceiveListItemDetails(fileLine.Trim(), String.Empty));
                        else 
                            i.Add(new SendListItemDetails(fileLine.Trim(), String.Empty, String.Empty, String.Empty));
                    }
                    else
                    {
                        // Split on the commas
                        string[] s = fileLine.Split(new char[] {','});
                        // Shipping or receiving?
                        if (i is ReceiveListItemCollection)
                        {
                            i.Add(new ReceiveListItemDetails(s[0], String.Empty));
                        }
                        else
                        {
                            string rd = String.Empty;
                            // Parse the return date
                            if (EmployReturnDate && s[2].IndexOf('/') != -1)
                            {
                                string[] d = s[2].Split(new char[] {'/'});
                                rd = String.Format("{0}-{1}-{2}", d[2], d[0].PadLeft(2,'0'), d[1].PadLeft(2,'0'));
                            }
                            // Add the item to the collection
                            i.Add(new SendListItemDetails(s[0].Trim(), rd, s[1].Trim(), String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sl, out ReceiveListItemCollection rl)
        {
            IList il;
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the parser and obtain the items.  Countrywide
            // always creates send lists; never receive lists.
            using (StreamReader r = new StreamReader(ms))
            {
                // Move past the list headers
                MovePastListHeaders(r);
                // Read list items
                if (t1 == ListTypes.Send)
                {
                    il = (IList)sl;
                    ReadListItems(r, ref il);
                }
                else
                {
                    il = (IList)rl;
                    ReadListItems(r, ref il);
                }
            }
        }
    }
}
