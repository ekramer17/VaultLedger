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
    public class CGI3DisasterParser : Parser, IParserObject
    {
        string fileLine = null;
        int s1 = -1;
        int n1 = -1;
        int c1 = -1;

        public CGI3DisasterParser() {}

        private bool MovePastListHeaders(StreamReader r)
        {
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.IndexOf("DATA SET NAME") != -1 && fileLine.IndexOf("SERIAL") != -1)
                {
                    // Get the column markers
                    fileLine = fileLine.Trim();
                    s1 = fileLine.IndexOf("SERIAL");
                    n1 = fileLine.IndexOf("DATA SET");
                    c1 = fileLine.LastIndexOf("NAME");
                    // Skip next line
                    r.ReadLine();
                    // Return true
                    return true;
                }
            }
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
            // Read through the list
            while ((fileLine = r.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length == 0)
                {
                    continue;
                }
                else if (fileLine.ToUpper().IndexOf("END OF REPORT") != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("INVENTORY OF VOLUMES") != -1)
                {
                    break;
                }
                else
                {
                    // Get the serial
                    string s = (s = fileLine.Substring(s1)).Substring(0, s.IndexOf(' '));
                    // Get the disaster code
                    string d = fileLine.Length <= c1 ? String.Empty : fileLine.Substring(c1).Trim();
                    if (d.Length > 3) d = String.Format("{0}{1}{2}", d[0], d[2], d[3]);
                    // Get the note
                    string n = DataSetNoteAction != "NO ACTION" ? fileLine.Substring(0, n1).Trim() : String.Empty;
                    // Create the item
                    c.Add(new DisasterCodeListItemDetails(s, d, n));
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
                while (MovePastListHeaders(r))
                {
                    ReadListItems(r, ref li);
                }
            }
        }
    }
}
