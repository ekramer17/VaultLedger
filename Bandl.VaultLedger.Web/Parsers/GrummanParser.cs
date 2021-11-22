using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for Grumman1Parser.
    /// </summary>
    public class GrummanParser : Parser, IParserObject
    {
        public GrummanParser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            string fileLine = null;

            while ((fileLine = r.ReadLine()) != null)
            {
                // Convert the string to uppercase
                fileLine = fileLine.ToUpper();
                // Look for the header strings
                if (fileLine.IndexOf("VL ACCESS") != -1 && fileLine.IndexOf("EXPIRE") != -1)
                {
                    return true;
                }
            }
            // No more headers
            return false;
        }

        /// <summary>
        /// Reads the items for a single distribution list in the CA25 report.
        /// Stream reader should be positioned before the first item of the list upon entry.
        /// </summary>
        private void ReadListItems(StreamReader r, ref SendListItemCollection sli)
        {
            string fileLine;
            string serialNo;
            string rdate;

            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // Trim the line
                fileLine = fileLine.Trim();
                // If the length is zero then break
                if (fileLine.Length == 0) break;
                // First column is serial number, last is return date
                serialNo = fileLine.Substring(0, fileLine.IndexOf(' '));
                rdate = fileLine.Substring(fileLine.LastIndexOf(' ') + 1);
                // Parse the return date
                if (EmployReturnDate == true && rdate != String.Empty)
                {
                    string[] x = rdate.Split(new char[] {'/', '-'});    // month, day, year
                    // Make sure we have three elements
                    if (x.Length == 3)
                    {
                        // If year only two digits, add 2000
                        if (x[2].Length < 3)
                        {
                            x[2] = (Int32.Parse(x[2]) + 2000).ToString();
                        }
                        // Replace the rdate
                        rdate = String.Format("{0}-{1:00}-{2:00}", x[2], Int32.Parse(x[0]), Int32.Parse(x[1]));
                    }
                }
                // Add the send list item
                sli.Add(new SendListItemDetails(serialNo, rdate, String.Empty, String.Empty));
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
        /// <param name="rli">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="sli">
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli)
        {
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                while (MovePastListHeaders(r))
                {
                    ReadListItems(r, ref sli);
                }
            }
        }
    }
}
