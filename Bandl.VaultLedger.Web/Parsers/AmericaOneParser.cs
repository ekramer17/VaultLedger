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
    public class AmericaOneParser : Parser, IParserObject
    {
        private ListTypes t1;
        private Int32 p1 = -1;

        public AmericaOneParser() { this.t1 = ListTypes.Send; }

        /// Moves the position of the streamreader past the list headers, to just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r1)
        {
            String s1 = null;
            Boolean b1 = false;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (b1 == false && (s1 = s1.ToUpper()).Length != 0)
                {
                    t1 = s1.IndexOf("PICK") != -1 ? ListTypes.Receive : ListTypes.Send;
                    b1 = true;
                }
                else if (b1 == true && s1.IndexOf("VOLSER")!= -1)
                {
                    p1 = s1.IndexOf("DESCRIPTION");
                    return true;
                }
            }
            // nothing left
            return false;
        }

        private void ReadListItems(StreamReader r1, ref IList il)
        {
            bool b1 = true;
            string y1 = null;
            string n1 = null;   // notes
            string s1 = null;   // serial
            char[] e1 = new char[] {' '};

            while ((y1 = r1.ReadLine()) != null)
            {
                if (y1.Trim().Length != 0)
                {
                    // Find description position?
                    if (this.p1 != -1 && b1 == true)
                    {
                        while (y1[this.p1 - 1] != ' ') this.p1 -= 1;
                    }
                    // Flag
                    b1 = false;
                    // Get strings
                    s1 = y1.Trim().Split(e1)[0];
                    n1 = this.p1 != -1 ? y1.Substring(this.p1).Split(e1)[0] : String.Empty;
                    // Add the item
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(s1, n1));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(s1, String.Empty, n1, String.Empty));
                    }
                }
                else if (b1 == false)
                {
                    break;
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
        public override void Parse(byte[] t1, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s1, out ArrayList a1, out ArrayList l1)
        {
            IList x1 = null;
            s1 = new ArrayList();
            a1 = new ArrayList();
            l1 = new ArrayList();
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Read through the file, collecting items
            using (StreamReader r1 = new StreamReader(new MemoryStream(t1)))
            {
                if (MovePastListHeaders(r1))
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
