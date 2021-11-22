using System;
using System.IO;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for Ricoh1Parser.
    /// </summary>
    public class Ricoh6Parser : Parser, IParserObject
    {
        private String account_name;  // account name

        public Ricoh6Parser() { }

        /// <summary>
        /// Find the account name (it's in the footer)
        /// </summary>
        private string ParseAccountName(string file_contents)
        {
            string s = "RICOH Account #";
            int i = file_contents.IndexOf(s);

            if (i == -1) return "";

            s = file_contents.Substring(i + s.Length).Trim();
            return s.Substring(0, s.IndexOf(' '));
        }


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

            while ((s1 = r1.ReadLine()) != null && b1 != 2)
            {
                if (s1.Replace("*", "").Trim().Length == 0)
                {
                    if (++b1 == 2)
                        return true;
                }
            }
            // No more data
            return false;
        }

        private void ReadListItems(StreamReader r1, ref IList i1, ref ArrayList s, ref ArrayList a, ref ArrayList l)
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
                else if (s1.Replace("*", "").Trim().Length == 0)
                {
                    break;
                }
                else
                {
                    // Compress spaces
                    while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    // Split string
                    string[] s2 = s1.Split(new char[] { ' ', '\t' });
                    string serial = s2[1];
                    // Does the serial already appear?
                    if (x1.Contains(serial)) continue;
                    // Get information
                    i1.Add(new SendListItemDetails(serial, "", "", ""));
                    // Account?
                    if (this.account_name.Length != 0)
                    {
                        s.Add(serial);
                        a.Add(this.account_name);
                        l.Add(Locations.Enterprise);
                    }
                    // Add to arraylist
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
            // Account name?
            account_name = ParseAccountName(Encoding.UTF8.GetString(fileText));
            // Create a new memory stream
            MemoryStream m1 = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader x1 = new StreamReader(m1))
            {
                if (MovePastListHeaders(x1))        // ALWAYS SEND LIST IN THIS PARSER
                {
                    IList i1 = (IList)s1;
                    ReadListItems(x1, ref i1, ref s, ref a, ref l);
                }
            }
        }
    }
}
