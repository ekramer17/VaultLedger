using System;
using System.IO;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a TLMS inventory report
    /// </summary>
    public class TLMSInventoryParser : InventoryParser
    {
        int p1 = -1;

        public TLMSInventoryParser() {}

        /// <summary>
        /// Finds the next list source and destinations site mentioned in the report.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if both source and destination were found, else false
        /// </returns>
        private bool MovePastHeaders(StreamReader r1, out string x1)
        {
            string f1 = null;
            Match m1 = null;
            x1 = String.Empty;
            const string s1 = "INVENTORY REPORT FOR LOCATION";
            // Read down the file until we find a header
            while ((f1 = r1.ReadLine()) != null)
            {
                if ((f1 = f1.ToUpper()).IndexOf(s1) != -1)
                {
                    f1 = f1.Substring(f1.IndexOf(s1) + s1.Length).Trim();
                    f1 = f1.Substring(0, f1.IndexOf("TLMS006")).Trim();
                    // Get the site
                    if (null != (m1 = Regex.Match(f1, " IN.*SEQUENCE")))
                    {
                        x1 = f1.Substring(0, m1.Index).Trim();
                    }
                    else
                    {
                        x1 = f1.Trim();
                    }
                    // Move past the headers
                    while ((f1 = r1.ReadLine()) != null)
                    {
                        if (f1.Trim().StartsWith("SERIAL"))
                        {
                            p1 = f1.IndexOf("SERIAL");
                        }
                        else if (f1.Trim().IndexOf('-') == 0 && f1.Replace('-', ' ').Trim().Length == 0)
                        {
                            break;
                        }
                    }
                    // Return
                    return true;
                }
            }
            // Return
            return false;
        }

        private void ReadItems(StreamReader r1, ArrayList s1)
        {
            string x1 = String.Empty;
            // Read through the file, collecting items
            while ((x1 = r1.ReadLine()) != null)
            {
                // End of section?
                if (x1.StartsWith("*"))
                {
                    break;
                }
                else if (x1.Length > 1 && x1.Substring(1).Replace('*', ' ').Trim().Length == 0)
                {
                    break;
                }
                else
                {
                    x1 = x1.Substring(this.p1);
                    s1.Add(x1.Substring(0, x1.IndexOf(' ')));
                }
                // If the next character is a '1', then break (may be no line between end of list and next header)
                if (r1.Peek() == '1')
                {
                    break;
                }
            }
        }

        public override void Parse(byte[] fileText)
        {
            int accountIndex;
            string sitename = null;
            string accountname = null;
            // Create arraylists for the serial number and accounts
            ArrayList s = new ArrayList();
            ArrayList a = new ArrayList();
            // Location always enterprise
            this.myLocation = Locations.Enterprise;
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader r1 = new StreamReader(ms))
            {
                while (MovePastHeaders(r1, out sitename))
                {
                    accountIndex = -1;
                    // Get the account
                    new Parser().SiteIsEnterprise(sitename, out accountname);
                    // Have one?
                    if (accountname.Length == 0)
                    {
                        throw new ApplicationException("No account is associated with external site '" + sitename + "'.");
                    }
                    // Add account to arraylist?
                    for (int i = 0; i < a.Count; i++)
                    {
                        if (accountname.CompareTo((string)a[i]) == 0)
                        {
                            accountIndex = i;
                            break;
                        }
                    }
                    // Add account?
                    if (accountIndex == -1)
                    {
                        a.Add(accountname);
                        s.Add(new ArrayList());
                        accountIndex = a.Count - 1;
                    }
                    // Read the list items
                    ReadItems(r1, (ArrayList)s[accountIndex]);
                }
            }
            // Convert serial number arraylist to array of arraylists
            this.mySerials = (ArrayList[])s.ToArray(typeof(ArrayList));
            // Convert account number arraylist to string array
            this.myAccounts = (string[])a.ToArray(typeof(string));
        }
    }
}
