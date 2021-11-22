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
    public class IndianaFarmDisasterParser : Parser, IParserObject
    {
        int p1 = 0;

        public IndianaFarmDisasterParser() {}

        private bool MovePastListHeaders(StreamReader r1)
        {
            String s1 = null;
            // Loop
            while ((s1 = r1.ReadLine()) != null)
            {
                if ((s1 = s1.ToUpper()).IndexOf("SERIAL") != -1 && s1.IndexOf("CLASS") != -1 && (p1 = s1.IndexOf("LOCATION")) != -1)
                {
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
        private void ReadListItems(StreamReader r1, ref DisasterCodeListItemCollection c1)
        {
            String s1 = null;
            // Read through the list
            while ((s1 = r1.ReadLine()) != null)
            {
                if (0 == s1.Trim().Length)
                {
                    continue;
                }
                else if (s1.Substring(p1, 5) == "VAULT")
                {
                    String s2 = s1.Trim();
                    c1.Add(new DisasterCodeListItemDetails(s2.Substring(0, s2.IndexOf(' ')), String.Empty, String.Empty));
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
        public override void Parse(byte[] b1, out DisasterCodeListItemCollection i1)
        {
            // Create a new disaster code list collection
            i1 = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream m1 = new MemoryStream(b1);
            // Read through the stream, collecting items
            using (StreamReader r1 = new StreamReader(m1))
            {
                MovePastListHeaders(r1);
                ReadListItems(r1, ref i1);
            }
        }
    }
}
