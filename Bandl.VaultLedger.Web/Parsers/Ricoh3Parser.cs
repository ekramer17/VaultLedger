using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for Ricoh3Parser.
    /// </summary>
    public class Ricoh3Parser : Parser, IParserObject
    {
        private ListTypes listType;
        private String accountName;  // account name

        public Ricoh3Parser() { listType = ListTypes.Receive; }

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
            int b1 = 0;
            string s1 = null;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.IndexOf('*') != -1 && s1.Replace("*", "").Trim() == "")
                {
                    if (++b1 == 2)
                        return true;
                }
                else if (b1 == 1)
                {
                    // Is shipping list?
                    if (s1.IndexOf("VOLUMES SENT TO OFF-SITE VAULT") != -1)
                        this.listType = ListTypes.Send;
                    // Get account name
                    s1 = s1.Substring(s1.IndexOf('#') + 1);
                    accountName = s1.Substring(0, s1.IndexOf(' '));

                }
            }
            // No more data
            return false;
        }

        private void ReadListItems(StreamReader r1, ref IList i1, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            int i;
            string s1, serial;
            ArrayList x1 = new ArrayList();
            // Read through the file, collecting items
            while ((s1 = r1.ReadLine()) != null)
            {
                if ((s1 = s1.Trim()) == String.Empty)
                {
                    continue;
                }
                else if (s1.IndexOf('*') != -1 && s1.Replace("*", String.Empty).Trim() == String.Empty)
                {
                    break;
                }
                else
                {
                    s1 = s1.Substring(s1.IndexOf(' ') + 1).Trim();

                    i = s1.IndexOf("Expires:");
                    serial = i != -1 ? s1.Substring(0, i).Trim() : s1;

                    if (i1 is ReceiveListItemCollection)
                    {
                        i1.Add(new ReceiveListItemDetails(serial, String.Empty));
                    }
                    else if (this.EmployReturnDate && i != -1)
                    {
                        DateTime r = DateTime.ParseExact(s1.Substring(i + 8).Trim(), 
                            new String[] { "MM/dd/yyyy" }, 
                            DateTimeFormatInfo.InvariantInfo, 
                            DateTimeStyles.AllowWhiteSpaces);
                        i1.Add(new SendListItemDetails(serial, r.ToString("yyyy-MM-dd"), String.Empty, String.Empty));
                    }
                    else
                    {
                        i1.Add(new SendListItemDetails(serial, String.Empty, String.Empty, String.Empty));
                    }

                    if (this.accountName.Length != 0)
                    {
                        s.Add(serial);
                        a.Add(this.accountName);
                        l.Add(i1 is ReceiveListItemCollection ? Locations.Vault : Locations.Enterprise);
                    }

                    x1.Add(serial);
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
