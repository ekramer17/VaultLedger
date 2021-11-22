using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for AmericanCenturyDisasterParser.
    /// </summary>
    public class AmericanCenturyDisasterParser : Parser, IParserObject
    {
        public AmericanCenturyDisasterParser() {}

        private bool MovePastListHeaders(StreamReader r)
        {
            string fileLine;
            // Find the header
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("DATASET NAME") != -1)
                {
                    return true;
                }
            }
            // No more headers found
            return false;
        }
        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="rr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="li">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadListItems(StreamReader r, ref DisasterCodeListItemCollection c)
        {
            int i = -1;
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().Length < 10)
                {
                    break;
                }
                else if (fileLine.Trim().ToUpper().Substring(0,6) == "TOTAL ")
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("AMERICAN CENTURY") != -1)
                {
                    break;
                }
                else if (fileLine[0] == ' ')
                {
                    continue;
                }
                else
                {
                    // Get the serial number
                    string serialNo = fileLine.Trim();
                    serialNo = serialNo.Substring(0, serialNo.IndexOf(' '));
                    // Make sure we don't already have it
                    for (i = 0; i < c.Count; i += 1)
                    {
                        if (c[i].SerialNo == serialNo)
                        {
                            break;
                        }
                    }
                    // If we reached end of loop, add item
                    if (i == c.Count)
                    {
                        c.Add(new DisasterCodeListItemDetails(serialNo, String.Empty, String.Empty));
                    }
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
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Create a new disaster code list collection
            li = new DisasterCodeListItemCollection();
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader r = new StreamReader(ms))
            {
                while(MovePastListHeaders(r))
                {
                    ReadListItems(r, ref li);
                }
            }
        }
    }
}
