using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for CGI2DisasterParser.
    /// </summary>
    public class CGI2DisasterParser : Parser, IParserObject
    {
        public CGI2DisasterParser() {}

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
                if ((fileLine = fileLine.Trim()).Length != 0)
                {
                    // Replace dousble spaces with single
                    while (fileLine.IndexOf("  ") != -1)
                    {
                        fileLine = fileLine.Replace("  ", " ");
                    }
                    // Split into columns
                    string[] x = fileLine.Split(new char[] {' '});
                    // Third column contains serial number, fourth contains data note, fifth (if it exists, contains disaster recovery code
                    string dcode = x.Length < 5 ? String.Empty : x[4].Length > 3 ? x[4].Substring(0,3) : x[4];
                    c.Add(new DisasterCodeListItemDetails(x[2], dcode, DataSetNoteAction != "NO ACTION" ? x[3] : String.Empty));
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
            // Create a new disaster code list collection
            li = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Skip first line
                r.ReadLine();
                // Read the list items
                ReadListItems(r, ref li);
            }
        }
    }
}
