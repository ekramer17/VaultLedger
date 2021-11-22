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
    public class LACountyDisasterParser : Parser, IParserObject
    {
        public LACountyDisasterParser() {}

        private bool MovePastListHeaders(StreamReader sr)
        {
            string fileLine;
            // Read past the headers
            while((fileLine = sr.ReadLine()) != null) 
                if (fileLine.IndexOf("VCRT-DATE") != -1)
                    if (fileLine.IndexOf("VCRT-TIME") != -1)
                        return true;
            // No more entries
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
        private void ReadListItems(StreamReader sr, ref DisasterCodeListItemCollection dlc)
        {
            string fileLine;
            string serialNo;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if ((serialNo = fileLine.Substring(0, fileLine.IndexOf(' ')).Trim()).Length == 0)
                {
                    break;
                }
                else
                {
                    dlc.Add(new DisasterCodeListItemDetails(serialNo, String.Empty, String.Empty));
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
            // Create a new disaster code list collection
            listItems = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader sr = new StreamReader(ms))
                while (MovePastListHeaders(sr))
                    ReadListItems(sr, ref listItems);
        }
    }
}
