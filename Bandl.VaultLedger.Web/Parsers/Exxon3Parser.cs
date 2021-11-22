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
    /// Summary description for Exxon2Parser.
    /// </summary>
    public class Exxon3Parser : Parser, IParserObject
    {
        private ListTypes t1;
        private String accountName = String.Empty;

        public Exxon3Parser() { this.t1 = ListTypes.Send; }

        /// Moves the position of the streamreader past the list headers, to just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r1)
        {
            Int32 i1 = 0;
            String s1 = null;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.ToUpper().IndexOf("EXXON HOUSTON") != -1)
                {
                    t1 = s1.ToUpper().IndexOf("SHIPPING") != -1 ? ListTypes.Send : ListTypes.Receive;
                    // Account?
                    if ((i1 = s1.IndexOf('#')) == -1)
                    {
                        this.accountName = String.Empty;
                    }
                    else
                    {
                        String a1 = s1.Substring(i1 + 1);
                        this.accountName = a1.Substring(0, a1.IndexOf(' '));
                    }
                    // Return
                    return true;
                }
            }
            // nothing left
            return false;
        }

        private void ReadListItems(StreamReader r1, ref IList il, ref ArrayList s1, ref ArrayList a1, ref ArrayList p1)
        {
            string y1 = null;
            char[] e1 = new char[] {' '};

            while ((y1 = r1.ReadLine()) != null)
            {
                if ((y1 = y1.Trim()).Length != 0)
                {
                    // Add the item
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(y1, String.Empty));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(y1, String.Empty, String.Empty, String.Empty));
                    }
                    // Do we have an account?
                    if (this.accountName.Length > 0)
                    {
                        s1.Add(y1);
                        a1.Add(this.accountName);
                        p1.Add(il is SendListItemCollection ? Locations.Enterprise : Locations.Vault);
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
                while (MovePastListHeaders(r1))
                {
                    if (this.t1 == ListTypes.Receive)
                    {
                        x1 = (IList)rli;
                        ReadListItems(r1, ref x1, ref s1, ref a1, ref l1);
                    }
                    else if (this.t1 == ListTypes.Send)
                    {
                        x1 = (IList)sli;
                        ReadListItems(r1, ref x1, ref s1, ref a1, ref l1);
                    }
                }
            }
        }
    }
}
