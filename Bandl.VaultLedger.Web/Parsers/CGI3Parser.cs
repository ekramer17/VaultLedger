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
    /// Summary description for CGI2Parser.
    /// </summary>
    public class CGI3Parser : Parser, IParserObject
    {
        public CGI3Parser() {}

        /// Moves the position of the streamreader past the list headers, to just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r1)
        {
            string s1;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.IndexOf("RUBANS A FAIRE") != -1)
                {
                    for (int i = 0; i < 3; i += 1) r1.ReadLine();   // skip three lines
                    return true;
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
        private void ReadListItems(StreamReader r1, ref ReceiveListItemCollection c1)
        {
            string s1 = null;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1[0] != ' ')
                {
                    break;
                }
                else if (s1.Trim().Length == 0)
                {
                    break;
                }
                else
                {
                    string[] x1 = s1.Split(new char[] {' '});
                    // Loop
                    for (int i = 0; i < x1.Length; i += 1)
                    {
                        if ((x1[i] = x1[i].Trim()).Length == 0)
                        {
                            ;
                        }
                        else if (x1[i].IndexOf('\0') != -1)
                        {
                            ;
                        }
                        else
                        {
                            c1.Add(new ReceiveListItemDetails(x1[i], String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s, out ArrayList a, out ArrayList l)
        {
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
                    ReadListItems(r1, ref rli);
                }
            }
        }
    }
}
