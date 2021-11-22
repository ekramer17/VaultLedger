using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for VideotronDisasterParser.
	/// </summary>
	public class VideotronDisasterParser : Parser, IParserObject
	{
        public VideotronDisasterParser() {}

        private bool MovePastListHeaders(StreamReader r1)
        {
            string s1;
            bool b1 = false;
            // Read past the headers
            while ((s1 = r1.ReadLine()) != null)
            {
                if (b1 == false && (s1 = s1.ToUpper()).IndexOf("DATASET NAME") != -1 && s1.IndexOf("CREATING JOBNAME") != -1)
                {
                    b1 = true;
                }
                else if (b1 == true && s1.Replace("-", " ").Trim().Length == 0)
                {
                    return true;
                }
            }
            // No headers found
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
        private void ReadListItems(StreamReader r1, ref DisasterCodeListItemCollection i1)
        {
            string s1;

            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.Trim().Length == 0)
                {
                    break;
                }
                else if (s1.Trim().ToUpper().IndexOf("INVENTORY OF VOLUMES BY LOCATION") != -1)
                {
                    break;
                }
                else if (s1.Trim().ToUpper().StartsWith("REMOVABLE MEDIA MANAGER"))
                {
                    break;
                }
                else
                {
                    s1 = s1.Trim();
                    s1 = s1.Substring(0, s1.IndexOf(' '));
                    i1.Add(new DisasterCodeListItemDetails(s1, String.Empty, String.Empty));
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
        public override void Parse(byte[] b1, out DisasterCodeListItemCollection i1)
        {
            // Create a new disaster code list collection
            i1 = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream m1 = new MemoryStream(b1);
            // Read through the stream, collecting items
            using (StreamReader r1 = new StreamReader(m1))
            {
                while (MovePastListHeaders(r1))
                {
                    ReadListItems(r1, ref i1);
                }
            }
        }
    }
}
