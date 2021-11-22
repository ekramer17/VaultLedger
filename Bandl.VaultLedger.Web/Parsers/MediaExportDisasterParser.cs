using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Takes a file exported from the Media Search page and creates a disaster recovery 
	/// report out of it.  At the moment, it will takes the first three characters of the 
	/// notes field and use it as the disaster code.  This may have to change, or at 
	/// least be a soft option, in the future.
	/// </summary>
	public class MediaExportDisasterParser : Parser, IParserObject
	{
        int notesStart = -1;    // Offset where the Notes field starts; only used when export delimiter is spaces rather than tabs

        public MediaExportDisasterParser() {}

        private void MovePastListHeaders(StreamReader r)
        {
            string fileLine = null;
            // Read past the headers
            while((fileLine = r.ReadLine()) != null) 
            {
                if (fileLine.StartsWith("Serial Number") && fileLine.IndexOf("Notes") != -1)
                {
                    // Get the notes offset in case we need it
                    notesStart = fileLine.IndexOf("Notes");
                    // Pass the next line, which should be hyphens
                    r.ReadLine();
                    // Break the loop
                    break;
                }
            }
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
        private void ReadListItems(StreamReader r, ref DisasterCodeListItemCollection disasterItems)
        {
            string fileLine = null;
            string serialNo = null;
            string noteText = null;

            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().Length != 0)
                {
                    // The serial number will always be the text at the beginning of the line up
                    // to the first space or tab.  If we are delimited by tabs, then the notes
                    // field will be the eighth column; if we are using spaces, take the notes 
                    // from the offset found in the MovePastListHeaders method.
                    if (fileLine.IndexOf('\t') != -1)
                    {
                        string[] splitLine = fileLine.Trim().Split(new char[] {'\t'});
                        serialNo = splitLine[0];
                        noteText = splitLine[7];
                    }
                    else
                    {
                        serialNo = fileLine.Substring(0, fileLine.IndexOf(' '));
                        noteText = fileLine.Substring(notesStart).Trim();
                    }
                    // Add the new disaster code list item.  The maximum length of 
                    // the disaster code is three characters.
                    disasterItems.Add(new DisasterCodeListItemDetails(serialNo, noteText.Length <= 3 ? noteText : noteText.Substring(0,3), String.Empty));
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
        public override void Parse(byte[] fileText, out DisasterCodeListItemCollection disasterItems)
        {
            // Create a new disaster code list collection
            disasterItems = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Read past the headers
                MovePastListHeaders(r);
                // Read the list items
                ReadListItems(r, ref disasterItems);
            }
        }
    }
}
