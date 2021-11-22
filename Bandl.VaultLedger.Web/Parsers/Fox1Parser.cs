using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a Fox report
    /// </summary>
    public class Fox1Parser : Parser, IParserObject
    {
        int p1, p2;

        public Fox1Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader sr)
        {
            string fileLine;
            // Find the last header row
            while ((fileLine = sr.ReadLine()) != null)
                if ((p1 = (fileLine = fileLine.ToUpper()).IndexOf("VOLID")) != -1 && (p2 = fileLine.IndexOf("LABEL")) != -1)
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
        private void ReadListItems(StreamReader sr, ref IList il)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    continue;
                }
                else if (fileLine.IndexOf("FINAL TOTALS") != -1)
                {
                    break;
                }
                else
                {
                    string n = String.Empty;
                    // Get the serial number
                    string s = Trim(fileLine.Substring(p1));
                    // Get the notes field
                    if (DataSetNoteAction != "NO ACTION") 
                        n = Trim(fileLine.Substring(p2));
                    // Always receive list
                    il.Add(new ReceiveListItemDetails(s, n));
                }
            }
        }

        /// <summary>
        /// Parses the given text array and returns send list items and 
        /// receive list items.  Use this overload if the stream is a
        /// new TMS send/receive list report, e.g. CA-25.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="sendCollection">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="receiveCollection">
        /// Receptacle for returned receive list item collection
        /// </param>
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            IList il = (IList)receiveCollection;    // Fox has only been created for receiving lists
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
                if (MovePastListHeaders(r))
                    ReadListItems(r, ref il);
        }
    }
}
