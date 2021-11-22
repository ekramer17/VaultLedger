using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ConsecoParser.
    /// </summary>
    public class Countrywide1Parser : Parser, IParserObject
    {
        private string noteString = String.Empty;

        public Countrywide1Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader sr, ref string returnDate)
        {
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("Countrywide") == 0)
                {
                    noteString = sr.ReadLine().Trim();
                }
                else
                {
                    // Make the line uppercase and trim it
                    fileLine = fileLine.Trim().ToUpper();
                    // Look for headers.  When found, get the return date.
                    if (fileLine.IndexOf("(NOTE:") == 0)
                    {
                        try
                        {
                            string s = fileLine.Substring(fileLine.Length - 9, 8);
                            returnDate = new DateTime(Convert.ToInt32(s.Substring(6,2)) + 2000, Convert.ToInt32(s.Substring(0,2)), Convert.ToInt32(s.Substring(3,2))).ToString("yyyy-MM-dd");
                        }
                        catch
                        {
                            ;
                        }
                        // Headers found
                        break;
                    }
                    else if (EmployReturnDate && (fileLine.IndexOf("RETURN ON") == 0 || fileLine.IndexOf("RETUN ON") == 0))
                    {
                        try
                        {
                            fileLine = fileLine.Trim();
                            int s1 = fileLine.IndexOf('/');
                            int s2 = fileLine.LastIndexOf('/');
                            int y = Int32.Parse(fileLine.Substring(s2 + 1).Trim());
                            int m = Int32.Parse(fileLine.Substring(s1 - 2, 2).Trim());
                            int d = Int32.Parse(fileLine.Substring(s1 + 1, s2 - s1 - 1).Trim());
                            returnDate = new DateTime(y < 2000 ? y + 2000 : y, m, d).ToString("yyyy-MM-dd");
                        }
                        catch
                        {
                            ;
                        }
                        // Headers found
                        break;
                    }
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
        private void ReadListItems(StreamReader sr, string returnDate, ref IList itemCollection)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
                if (fileLine.Trim().Length != 0)
                    if (itemCollection is SendListItemCollection)
                        itemCollection.Add(new SendListItemDetails(fileLine.Trim().Replace("=",String.Empty), returnDate, noteString, String.Empty));
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
            IList listCollection;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the parser and obtain the items.  Countrywide
            // always creates send lists; never receive lists.
            string returnDate = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Move past the list headers
                MovePastListHeaders(sr, ref returnDate);
                // Countrywide lists are always send lists
                listCollection = (IList)sendCollection;
                ReadListItems(sr, returnDate, ref listCollection);
            }
        }
    }
}
