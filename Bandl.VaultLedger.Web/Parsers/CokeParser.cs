using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for CokeParser.
	/// </summary>
	public class CokeParser : Parser, IParserObject
	{
        public CokeParser() {}

        /// <summary>
        /// Finds the next list in the CA25 report and returns the name of its site
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Site on success, empty string if no more lists found in report
        /// </returns>
        private string FindNextListSite(StreamReader sr, out ReportType listType)
        {
            string fileLine;
            listType = ReportType.Picking;
            // Read down the file until we find a distribution list.  When
            // we find one, get the destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("DISTRIBUTION LIST FOR VAULT") != -1)
                {
                    listType = ReportType.Distribution;
                }
                else if (fileLine.ToUpper().IndexOf("PICKING LIST FOR VAULT") != -1)
                {
                    listType = ReportType.Picking;
                }
                else
                {
                    continue;
                }
                // Get the site name
                string d = fileLine.Substring(fileLine.ToUpper().IndexOf("VAULT") + 6).Trim();
                return d.IndexOf('-') != -1 ? d.Substring(0, d.IndexOf('-')).Trim() : d;
            }
            // No more lists found
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
                if (fileLine.Replace("=", String.Empty).Trim().Length == 0)
                {
                    break;
                }
            }
        }

        /// <summary>
        /// Reads the items for a single distribution list in the CA25 report.
        /// Stream reader should be positioned before the first item of the 
        /// list upon entry.
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the CA25 report file
        /// </param>
        private void ReadListItems(StreamReader sr, ReportType listType, bool headerLocal, ref SendListItemCollection sendCollection, ref ReceiveListItemCollection receiveCollection)
        {
            string fileLine;
            bool lineLocal = false;
            bool receiveList = false;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Replace("=", String.Empty).Trim().Length == 0)
                {
                    break;
                }
                // Get the field values
                string[] columnText = fileLine.Trim().Split(new char[] {' '});
                // Check the resolution of the source site.  Go to the next entry if the source is the same
                // as the destination or if the source is unrecognized and we are ignoring unknown sites.
                // If the source cannot be resolved and we are not ignoring unknown sites, throw an exception.
                try
                {
                    lineLocal = SiteIsEnterprise(columnText[1]);
                }
                catch (ExternalSiteException)
                {
                    if (!this.IgnoreUnknownSite)
                        throw;
                    else
                        continue;
                }
                // Only process if different locations
                if (lineLocal != headerLocal)
                {
                    // Determine whether we are creating receive list items or send list items                
                    if (headerLocal == true)
                        receiveList = listType != ReportType.Picking;
                    else
                        receiveList = listType != ReportType.Distribution;
                    // Construct an item of the correct type and fill it
                    if (receiveList == true)
                        receiveCollection.Add(new ReceiveListItemDetails(columnText[0], String.Empty));
                    else
                        sendCollection.Add(new SendListItemDetails(columnText[0], String.Empty, String.Empty, String.Empty));
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
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            ReportType listType;
            bool headerLocal = false;
            string fileLine = String.Empty;
            string headerSite = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((headerSite = FindNextListSite(sr, out listType)) != String.Empty) 
                {
                    try
                    {
                        headerLocal = SiteIsEnterprise(headerSite);
                    }
                    catch (ExternalSiteException)
                    {
                        if (!this.IgnoreUnknownSite)
                            throw;
                        else
                            headerSite = String.Empty;
                    }
                    // Move past the list headers
                    MovePastListHeaders(sr);
                    // Read the items of the list
                    if (headerSite.Length != 0)
                        ReadListItems(sr, listType, headerLocal, ref sendCollection, ref receiveCollection);
                }
            }
        }
    }
}
