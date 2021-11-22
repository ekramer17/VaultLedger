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
    /// <summary>
    /// Summary description for Ricoh1Parser.
    /// </summary>
    public class Ricoh2Parser : Parser, IParserObject
    {
        private ListTypes listType;
        private String a1;  // account name
        private Int32 COL1 = -1; // volume
        private Int32 COL2 = -1; // date

        public Ricoh2Parser() { listType = ListTypes.Receive; }

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
            char[] c1 = new char[] {'*', '='};

            while ((s1 = r1.ReadLine()) != null)
            {
                if (b1 < 2 && s1.IndexOfAny(c1) != -1 && s1.Replace("*", String.Empty).Replace("=", String.Empty).Trim().Length == 0)
                {
                    b1 += 1;
                }
                // Which?
                if (b1 == 1 && s1.IndexOf("TO BE SENT OFFSITE") != -1)
                {
                    this.listType = ListTypes.Send;
                }
                else if (b1 == 2 && s1.ToUpper().StartsWith("VOLUME"))
                {
                    while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    String[] s2 = s1.ToUpper().Split(new char[] {' '});
                    for (Int32 i = 0; i < s2.Length; i += 1)
                    {
                        if (s2[i] == "VOLUME")
                        {
                            COL1 = i;
                        }
                        else if (s2[i] == "EXPIRATION")
                        {
                            COL2 = i;
                        }
                    }
                }
                else if (b1 == 2 && s1.IndexOf("-") != -1 && s1.Replace("-", String.Empty).Trim().Length == 0)
                {
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
                else if (s1.IndexOf("ENTRY LISTED") != -1)
                {
                    break;
                }
                else if (s1.IndexOf("ENTRIES LISTED") != -1)
                {
                    break;
                }
                else
                {
                    // Compress spaces
                    while(s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    // Split string
                    string[] s2 = s1.Split(new char[] {' ', '\t'});
                    // Does the serial already appear?
                    if (x1.Contains(s2[COL1])) continue;
                    // Get information
                    if (i1 is ReceiveListItemCollection)
                    {
                        i1.Add(new ReceiveListItemDetails(s2[COL1], String.Empty));
                    }
                    else if (EmployReturnDate && COL2 != -1 && s2[COL2].Length != 0)
                    {
                        try
                        {
                            String y1 = DateTime.ParseExact(s2[COL2], "yyyy/MM/dd", null).ToString("yyyy-MM-dd");
                            i1.Add(new SendListItemDetails(s2[COL1], y1, String.Empty, String.Empty));
                        }
                        catch
                        {
                            i1.Add(new SendListItemDetails(s2[COL1], String.Empty, String.Empty, String.Empty));
                        }
                    }
                    else 
                    {
                        i1.Add(new SendListItemDetails(s2[COL1], String.Empty, String.Empty, String.Empty));
                    }
                    // Account?
                    if (this.a1.Length != 0)
                    {
                        s.Add(s2[COL1]);
                        a.Add(this.a1);
                        l.Add(i1 is ReceiveListItemCollection ? Locations.Vault : Locations.Enterprise);
                    }
                    // Add to arraylist
                    x1.Add(s2[COL1]);
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
            string text = UTF8Encoding.UTF8.GetString(fileText);
            a1 = GetAccountName(text.IndexOf("IKON CAPTIAL") != -1 ? "IKON CAPITAL" : "WELLS FARGO");
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
