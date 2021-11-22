using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    public class Navistar2Parser : Parser, IParserObject
    {
        public Navistar2Parser() { }

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
            string s1 = null;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.ToUpper().Contains("VOLSER"))
                    if (s1.ToUpper().Contains("RETURN DATE"))
                        return true;
            }

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
                else if ((s1 = s1.Trim()) == "FINAL TOTALS")
                {
                    break;
                }
                else
                {
                    // Split
                    String[] s2 = s1.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    // Add
                    String r = s2.Length > 1 ? s2[1] : String.Empty;
                    // Return date?
                    if (r.Length != 0)
                        r = DateTime.ParseExact(r, "MM/dd/yy", System.Globalization.CultureInfo.InvariantCulture).ToString("yyyy-MM-dd");
                    // Add to list 
                    i1.Add(new SendListItemDetails(s2[0], r, String.Empty, String.Empty));
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
            // Create a new memory stream
            MemoryStream m1 = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader x1 = new StreamReader(m1))
            {
                if (MovePastListHeaders(x1))
                {
                    IList i1 = (IList)s1;
                    ReadListItems(x1, ref i1, ref s, ref a, ref l);
                }
            }
        }
    }
}
