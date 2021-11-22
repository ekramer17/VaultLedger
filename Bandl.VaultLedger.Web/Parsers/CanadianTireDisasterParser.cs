using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ExxonDisasterParser.
    /// </summary>
    public class CanadianTireDisasterParser : Parser, IParserObject
    {
        public CanadianTireDisasterParser() {}

        private bool MovePastListHeaders(StreamReader sr)
        {
            string fileLine;
            // Find the header
            while ((fileLine = sr.ReadLine()) != null)
                if (fileLine.ToUpper().IndexOf("CANADIAN TIRE DRP") != -1)
                    return true;
            // No more headers found
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
        private void ReadListItems(StreamReader sr, ref DisasterCodeListItemCollection li)
        {
            string fileLine;
            char[] c = new char[] {' ', '\t'};
            // Read through the file, collecting items
            while ((fileLine = LeftTrim(sr.ReadLine())) != null)
            {
                if (fileLine.Length < 10)
                {
                    continue;
                }
                else if (fileLine.ToUpper().Substring(0,6) == "TOTAL ")
                {
                    continue;
                }
                else
                {
                    li.Add(new DisasterCodeListItemDetails(fileLine.Split(c)[2].ToUpper(), String.Empty, String.Empty));
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
        public override void Parse(byte[] fileText, out DisasterCodeListItemCollection listItems)
        {
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Create a new disaster code list collection
            listItems = new DisasterCodeListItemCollection();
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader r = new StreamReader(ms))
                while(MovePastListHeaders(r))
                    ReadListItems(r, ref listItems);
        }
    }
}
