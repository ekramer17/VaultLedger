using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.IParser;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
//F A R M   B U R E A U   I N S U R A N C E
    /// <summary>
    /// Parses a CA25 report
    /// </summary>
    public class CA25DisasterParser : Parser, IParserObject
    {
        int tapeStart = -1;
        bool isFarmBureau = false; // skip LIB inventory (FARM BUREAU INSURANCE)
        string siteName = String.Empty;

        public CA25DisasterParser() {}

        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            int p1 = 0;
            int p2 = 0;
            int dashed = 0;
            string fileLine;

            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.IndexOf("INVENTORY LIST FOR VAULT") != -1)
                {
                    // Get the site name
                    p1 = fileLine.IndexOf("(") + 1;
                    p2 = fileLine.LastIndexOf(")");
                    this.siteName = fileLine.Substring(p1, p2 - p1).ToUpper().Trim();
                    // Get through the headers
                    while ((fileLine = r.ReadLine()) != null)
                    {
                        if (0 == fileLine.Trim().Replace("-", String.Empty).Length)
                        {
                            if (++dashed > 1) 
                            {
                                return true;
                            }
                        }
                        else if (dashed == 1 && fileLine.IndexOf("VOLSER") != -1)
                        {
                            tapeStart = fileLine.IndexOf("VOLSER");
                        }
                    }
                }
            }

            return false;
        }


        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadListItems(StreamReader r, ref DisasterCodeListItemCollection c)
        {
            string fileLine = null;
            // Read through the list
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine.Length < 30)
                {
                    break;
                }
                else if (fileLine.IndexOf(" PAGE ") != -1)
                {
                    break;
                }
                else if (this.isFarmBureau && this.siteName != "COMB" && this.siteName != "DMS" && this.siteName != "DMSP" && this.siteName != "RECV" )
                {
                    ;   // skip
                }
                else
                {
                    // Get the serial number
                    string str1 = fileLine.Substring(tapeStart, fileLine.IndexOf(' ', tapeStart) - tapeStart).Trim();
                    // Add the item
                    c.Add(new DisasterCodeListItemDetails(str1, String.Empty, String.Empty));
                }
            }
        }

        /// <summary>
        /// Parses the given text array and returns a collection of 
        /// DisasterCodeListItemDetails objects.  Use this overload when
        /// creating a new disaster code list from a stream.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="listItems">
        /// Receptacle for returned disaster code list items
        /// </param>
        public override void Parse(byte[] fileText, out DisasterCodeListItemCollection li)
        {
            StreamReader r1 = null;
            // Create a new disaster code list collection
            li = new DisasterCodeListItemCollection();
            // Farm bureau?
            using (r1 = new StreamReader(new MemoryStream(fileText)))
            {
                this.isFarmBureau = (r1.ReadToEnd().IndexOf("F A R M   B U R E A U   I N S U R A N C E") != -1);
            }
            // Read through the stream, collecting items
            using (r1 = new StreamReader(new MemoryStream(fileText)))
            {
                while (MovePastListHeaders(r1))
                {
                    ReadListItems(r1, ref li);
                }
            }
        }
    }
}
