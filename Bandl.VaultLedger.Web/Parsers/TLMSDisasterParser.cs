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
    public class TLMSDisasterParser : Parser, IParserObject
    {
        int p1 = -1;

        public TLMSDisasterParser() {}

        /// <summary>
        /// Finds the next list source and destinations site mentioned in the report.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if both source and destination were found, else false
        /// </returns>
        private bool MovePastHeaders(StreamReader r1)
        {
            string f1 = null;
            const string s1 = "INVENTORY REPORT FOR LOCATION";
            // Read down the file until we find a header
            while ((f1 = r1.ReadLine()) != null)
            {
                if ((f1 = f1.ToUpper()).IndexOf(s1) != -1)
                {
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

        private void ReadItems(StreamReader r1, ref DisasterCodeListItemCollection i1)
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
                    i1.Add(new DisasterCodeListItemDetails(x1.Substring(0, x1.IndexOf(' ')), String.Empty, String.Empty));
                }
                // If the next character is a '1', then break (may be no line between end of list and next header)
                if (r1.Peek() == '1')
                {
                    break;
                }
            }
        }

        public override void Parse(byte[] fileText, out DisasterCodeListItemCollection disasterItems)
        {
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Create a new disaster code list collection
            disasterItems = new DisasterCodeListItemCollection();
            // Loop
            using (StreamReader r1 = new StreamReader(ms))
            {
                while (MovePastHeaders(r1))
                {
                    ReadItems(r1, ref disasterItems);
                }
            }
        }
    }
}
