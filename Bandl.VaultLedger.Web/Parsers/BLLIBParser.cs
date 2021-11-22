using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for BLLIBParser.
    /// </summary>
    public class BLLIBParser : Parser, IParserObject
    {
        int notePos = -1;

        public BLLIBParser() {}

        /// <summary>
        /// gets the site name
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Site on success, empty string otherwise
        /// </returns>
        private string GetSiteName(StreamReader sr)
        {
            string fileLine;
            // Read down the file until we find a distribution list.  When
            // we find one, get the destination.
            while ((fileLine = sr.ReadLine()) != null)
                if (fileLine.ToUpper().IndexOf("DESTINATION SITE:") != -1)
                    return fileLine.Substring(fileLine.IndexOf(':') + 1).Trim();
            // No site found
            return String.Empty;
        }

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader sr)
        {
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                // Make the line uppercase
                fileLine = fileLine.ToUpper();
                // Look for headers
                if (fileLine.IndexOf("SERIAL") != -1 && (notePos = fileLine.IndexOf("DESCRIPTION")) != -1)
                {
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
        private void ReadListItems(StreamReader sr, ref IList items)
        {
            string fileLine;
            string n = String.Empty;
            string r = String.Empty;
            char[] c = new char[] {' '};
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length != 0)
                {
                    // Remove all double spaces
                    while (fileLine.IndexOf("  ") != -1) fileLine = fileLine.Replace("  ", " ");
                    // Split on the spaces
                    string[] x = fileLine.Split(c);
                    // Notes, if any
                    if (DataSetNoteAction != "NO ACTION") n = x[1];
                    // Insert the item into the collection
                    if (items is ReceiveListItemCollection)
                    {
                        items.Add(new ReceiveListItemDetails(x[0], n));
                    }
                    else
                    {
                        r = EmployReturnDate ? DateTime.ParseExact(x[2], "yyyyMMdd", null).ToString("yyyy-MM-dd") : String.Empty;
                        items.Add(new SendListItemDetails(x[0], r, x[1], String.Empty));
                    }
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
            IList listCollection;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the report
            string siteName = String.Empty;
            bool destinationLocal = false;
            using (StreamReader sr = new StreamReader(ms))
            {
                try
                {
                    if ((siteName = GetSiteName(sr)).Length == 0)
                        throw new ApplicationException("No site found in report.");
                    else
                        destinationLocal = SiteIsEnterprise(siteName);
                }
                catch (ExternalSiteException)
                {
                    if (!this.IgnoreUnknownSite)
                        throw;
                    else
                        return;
                }
                // Move past the list headers
                MovePastListHeaders(sr);
                // Send or receive lists?
                if (destinationLocal)
                {
                    listCollection = (IList)receiveCollection;
                    ReadListItems(sr, ref listCollection);
                }
                else
                {
                    listCollection = (IList)sendCollection;
                    ReadListItems(sr, ref listCollection);
                }
            }
        }
    }
}
