using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for CGI3DisasterParser.
    /// </summary>
    public class CGI4DisasterParser : Parser, IParserObject
    {
        string fileLine = null;

        public CGI4DisasterParser() {}

        private bool MovePastListHeaders(StreamReader r)
        {
            while ((fileLine = r.ReadLine()) != null)
                if (fileLine.IndexOf("-") != -1 && fileLine.Replace("-","").Replace("\t","").Trim().Length == 0)
                    return true;
            // No more
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
            char[] t1 = new char[] {'\t'};
            // Read through the list
            while ((fileLine = r.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length == 0)
                {
                    continue;
                }
                else
                {
                    string[] s1 = fileLine.Trim().Split(t1);
                    // Second column contains serial number
                    c.Add(new DisasterCodeListItemDetails(s1[1], String.Empty, String.Empty));
                }
            }
        }
        /// <summary>
        /// Parses the given text array and returns a collection of 
        /// DisasterCodeListItemDetails objects.  Use this overload when
        /// creating a new disaster code list from a stream.x
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
                MovePastListHeaders(r);
                ReadListItems(r, ref li);
            }
        }
    }
}
