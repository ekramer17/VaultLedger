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
	public class Ricoh1Parser : Parser, IParserObject
	{
        private ListTypes listType;
        private String accountName;

        public Ricoh1Parser() { listType = ListTypes.Send; accountName = String.Empty; }

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
            int i1 = -1;
            bool x1 = false;
            string s1 = null;
            char[] c1 = new char[] {'*', '='};

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.IndexOfAny(c1) != -1 && s1.Replace("*", String.Empty).Replace("=", String.Empty).Trim().Length == 0)
                {
                    if (++b1 == 2) return x1;
                }
                else if (b1 == 1)
                {
                    if (s1.IndexOf(" RETRIEVAL ") != -1)
                    {
                        this.listType = ListTypes.Receive;
                        x1 = true;
                    }
                    else if (s1.IndexOf(" SENT ") != -1)
                    {
                        this.listType = ListTypes.Send;
                        x1 = true;
                    }
                    // Account?
                    if (x1 == true && accountName.Length == 0)
                    {
                        if (s1.Trim().StartsWith("IKON") && (i1 = s1.IndexOf('-')) != -1)
                        {
                            String s2 = s1.Substring(i1 + 1).Trim();
                            accountName = this.GetAccountName(s2.Substring(0, s2.IndexOf(' ')));
                        }
                        else if ((i1 = s1.IndexOf(" - ")) != -1 && s1.Substring(0,i1).Trim().IndexOf(" ") == -1)
                        {
                            accountName = this.GetAccountName(s1.Substring(0,i1).Trim());
                        }
                    }
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
                if ((s1 = s1.Trim()) == String.Empty || s1.StartsWith("R"))
                {
                    continue;
                }
                else if (s1.Replace("*", String.Empty).Replace("=", String.Empty).Trim() == String.Empty)
                {
                    break;
                }
                else
                {
                    // Compress spaces
                    while(s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    // Split string
                    string[] s2 = s1.Split(new char[] {' ', '\t'});
                    // How many segments?
                    if (s2.Length == 1)
                    {
                        if (x1.Contains(s2[0]))
                        {
                            continue;
                        }
                        else if (i1 is ReceiveListItemCollection)
                        {
                            i1.Add(new ReceiveListItemDetails(s2[0], String.Empty));
                        }
                        else
                        {
                            i1.Add(new SendListItemDetails(s2[0], String.Empty, String.Empty, String.Empty));
                        }
                        // Add to list
                        x1.Add(s2[0]);
                    }
                    else
                    {
                        // Get serial numbers
                        for (int i = 1; i < s2.Length; i += 2)
                        {
                            if (Regex.IsMatch(s2[i - 1], "^[0-9]+$") == false)
                            {
                                break;
                            }
                            else if (x1.Contains(s2[i]))
                            {
                                continue;
                            }
                            else if (i1 is ReceiveListItemCollection)
                            {
                                i1.Add(new ReceiveListItemDetails(s2[i], String.Empty));
                            }
                            else
                            {
                                i1.Add(new SendListItemDetails(s2[i], String.Empty, String.Empty, String.Empty));
                            }
                            // Add account number and location to array list if we have an account number
                            if (accountName.Length != 0)
                            {
                                s.Add(s2[i]);
                                a.Add(this.accountName);
                                l.Add(i1 is ReceiveListItemCollection ? Locations.Vault : Locations.Enterprise);
                            }
                            // Add to list
                            x1.Add(s2[i]);
                        }
                    }
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
