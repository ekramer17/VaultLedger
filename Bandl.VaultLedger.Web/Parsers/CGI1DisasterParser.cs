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
    public class CGI1DisasterParser : Parser, IParserObject
    {
        public CGI1DisasterParser() {}

        private void MovePastListHeaders(StreamReader sr)
        {
            string fileLine;
            // Read past the headers
            while((fileLine = sr.ReadLine()) != null) 
                if (fileLine.Replace(" ","").Replace("-","").Length == 0)
                    break;

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
            string fileLine;

            while ((fileLine = r.ReadLine()) != null)
            {
                fileLine = fileLine.Replace("\t"," ").Trim();
                // Replace double spaces with single
                while (fileLine.IndexOf("  ") != -1)
                    fileLine = fileLine.Replace("  ", " ");
                // Get the serial number from the third column
                if (fileLine.Length != 0)
                    c.Add(new DisasterCodeListItemDetails(fileLine.Trim().Split(new char[] {' '})[2], String.Empty, String.Empty));
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
            // Create a new disaster code list collection
            li = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Read past the headers
                MovePastListHeaders(r);
                // Read the list items
                ReadListItems(r, ref li);
            }
        }
    }
}
