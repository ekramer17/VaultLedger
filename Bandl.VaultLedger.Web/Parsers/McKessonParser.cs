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
    /// Summary description for McKessonParser.
    /// </summary>
    public class McKessonParser : Parser, IParserObject
    {
        private ListTypes t1;

        public McKessonParser() { this.t1 = ListTypes.Send; }

        /// Moves the position of the streamreader past the list headers, to just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r1)
        {
            String s1 = null;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.IndexOf("from location") != -1 && s1.IndexOf("to location") != -1)
                {
                    // Initialize
                    String x1 = null;
                    String x2 = null;
                    // Split into columns
                    while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    String[] s2 = s1.Split( new char[] {' '} );
                    // Get the locations
                    for (Int32 i = 0; i < s2.Length; i += 1)
                    {
                        if (s2[i].ToUpper() == "LOCATION")
                        {
                            if (s2[i-1].ToUpper() == "FROM")
                            {
                                x1 = s2[i+1].ToUpper().Trim();
                            }
                            else if (s2[i-1].ToUpper() == "TO")
                            {
                                x2 = s2[i+1].ToUpper().Trim();
                            }
                        }
                        // Do we have both?
                        if (x1 != null && x2 != null)
                        {
                            if (x1 == "VLHQ" && x2 == "IBMNAT1")
                            {
                                this.t1 = ListTypes.Receive;
                            }
                            else if (x1 == "VLHQ" && x2 == "SHELF")
                            {
                                this.t1 = ListTypes.Receive;
                            }
                            else if (x1 == "IBMNAT1" && x2 == "VLHQ")
                            {
                                this.t1 = ListTypes.Send;
                            }
                            else
                            {
                                break;
                            }
                            // Move past rest of headers
                            while (true)
                            {
                                if ((s1 = r1.ReadLine()) == null)
                                {
                                    return false;
                                }
                                else if (s1.Replace('-', ' ').Trim().Length == 0)
                                {
                                    return true;
                                }
                            }
                        }
                    }
                }
            }
            // nothing left
            return false;
        }

        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="r">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="il">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadListItems(StreamReader r1, ref IList c1)
        {
            string s1 = null;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1[0] != ' ')
                {
                    break;
                }
                else if ((s1 = s1.Trim()).Length == 0)
                {
                    break;
                }
                else
                {
                    // Replace double spaces
                    while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    // Split into columns
                    String[] x1 = s1.Split(new char[] {' '});
                    // Create list item
                    if (c1 is ReceiveListItemCollection)
                    {
                        c1.Add(new ReceiveListItemDetails(x1[0], x1[1]));
                    }
                    else
                    {
                        c1.Add(new SendListItemDetails(x1[0], String.Empty, x1[1], String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            IList x1 = null;
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r1 = new StreamReader(ms))
            {
                while (MovePastListHeaders(r1))
                {
                    if (this.t1 == ListTypes.Receive)
                    {
                        x1 = (IList)rli;
                        ReadListItems(r1, ref x1);
                    }
                    else if (this.t1 == ListTypes.Send)
                    {
                        x1 = (IList)sli;
                        ReadListItems(r1, ref x1);
                    }
                }
            }
        }
    }
}
