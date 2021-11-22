using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    public class NavistarParser : Parser, IParserObject
    {
        private ListTypes listType = ListTypes.Send;
        private String accountName = String.Empty;
        private String note = String.Empty;
        private Boolean dataprotector = false;

        public NavistarParser() { }

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        /// <returns>
        /// True if headers were found, else false
        /// </returns>
        private bool MovePastListHeaders(StreamReader r1)
        {
            try
            {
                string s1 = null;
                int p1;

                while ((s1 = r1.ReadLine()) != null)
                {
                    if (s1.StartsWith("Subject:"))
                    {
                        s1 = s1.Substring(s1.IndexOf('/') + 1).Trim();
                        p1 = s1.IndexOf('-');
                        p1 = s1.IndexOf('-', p1 + 1);

                        accountName = s1.Substring(0, p1);
                        listType = s1.IndexOf("_VIN_") != -1 ? ListTypes.Receive : ListTypes.Send;

                        if ((p1 = s1.IndexOf("VBOX ")) != -1)
                            note = s1.Substring(p1 + 5).Trim();

                        return true;
                    }
                }

                return false;
            }
            catch
            {
                return false;
            }
        }

        private void ReadListItems(StreamReader r1, ref IList i1, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            if (dataprotector)
                ReadListItems1(r1, ref i1, ref s, ref a, ref l);
            else
                ReadListItems2(r1, ref i1, ref s, ref a, ref l);
        }

        private void ReadListItems1(StreamReader r1, ref IList i1, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string s1;
            ArrayList x1 = new ArrayList();
            // Read through the file, collecting items
            while ((s1 = r1.ReadLine()) != null)
            {
                if ((s1 = s1.Trim()).StartsWith("["))
                {
                    // Get serial
                    s1 = s1.Substring(1, s1.IndexOf("]") - 1);
                    // Add to list
                    if (i1 is ReceiveListItemCollection)
                        i1.Add(new ReceiveListItemDetails(s1, note));
                    else
                        i1.Add(new SendListItemDetails(s1, String.Empty, note, String.Empty));
                    // Add account number and location to array list if we have an account number
                    if (accountName.Length != 0)
                    {
                        s.Add(s1);
                        a.Add(accountName);
                        l.Add(i1 is ReceiveListItemCollection ? Locations.Vault : Locations.Enterprise);
                    }
                    // Add to list
                    x1.Add(s1);
                }
            }
        }

        private void ReadListItems2(StreamReader r1, ref IList i1, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string s1;
            ArrayList x1 = new ArrayList();
            // Read through the file, collecting items
            while ((s1 = r1.ReadLine()) != null)
            {
                if ((s1 = s1.Trim()) == String.Empty)
                {
                    continue;
                }
                else if (s1.ToUpper().StartsWith("VOLSER"))
                {
                    continue;
                }
                else if (s1.ToUpper().StartsWith("TOTAL TAPES"))
                {
                    break;
                }
                else
                {
                    // Split
                    String[] s2 = s1.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    // Add
                    if (i1 is ReceiveListItemCollection)
                    {
                        i1.Add(new ReceiveListItemDetails(s2[0], note));
                    }
                    else
                    {
                        String r = s2.Length > 1 ? s2[1] : String.Empty;
                        // Return date?
                        if (r.Length != 0)
                            r = DateTime.ParseExact(r, "MM/dd/yy", System.Globalization.CultureInfo.InvariantCulture).ToString("yyyy-MM-dd");
                        // Add to list 
                        i1.Add(new SendListItemDetails(s2[0], r, note, String.Empty));
                    }
                    // Add account number and location to array list if we have an account number
                    if (accountName.Length != 0)
                    {
                        s.Add(s1);
                        a.Add(accountName);
                        l.Add(i1 is ReceiveListItemCollection ? Locations.Vault : Locations.Enterprise);
                    }
                    // Add to list
                    x1.Add(s1);
                }
            }
        }

        /// <summary>
        /// Parses the given text array and returns send list items and receive list items
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="sendCollection">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="receiveCollection">
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection s1, out ReceiveListItemCollection r1, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            s1 = new SendListItemCollection();
            r1 = new ReceiveListItemCollection();
            // Get type
            dataprotector = Encoding.UTF8.GetString(fileText).IndexOf("Cell Manager:") != -1;
            // Create a new memory stream
            MemoryStream m1 = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader x1 = new StreamReader(m1))
            {
                if (MovePastListHeaders(x1))
                {
                    if (this.listType == ListTypes.Receive)
                    {
                        IList i1 = (IList)r1;
                        ReadListItems(x1, ref i1, ref s, ref a, ref l);
                    }
                    else
                    {
                        IList i1 = (IList)s1;
                        ReadListItems(x1, ref i1, ref s, ref a, ref l);
                    }
                }
            }
        }
    }
}
