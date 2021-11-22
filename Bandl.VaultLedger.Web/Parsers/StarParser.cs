using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a STAR-1100 report
    /// </summary>
    public class StarParser : Parser, IParserObject
    {
        int serialLen = 7;
        int serialPos = 0;
        int siteLen = -1;
        int sitePos = -1;
        int dataLen = -1;
        int dataPos = -1;
        int datePos = -1;

        public StarParser() {}

        private bool IgnorePickingLists(byte[] fileText)
        {
            // Create a momeory stream over the file text
            MemoryStream memoryStream = new MemoryStream(fileText);
            // Run through the list, looking for at least one distribution
            // report.  If one is found, then we should ignore all pick lists.
            using (StreamReader streamReader = new StreamReader(memoryStream))
            {
                string fileLine;
                while ((fileLine = streamReader.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("DISTRIBUTION LIST FOR VAULT") != -1)
                    {
                        return true;
                    }
                }
            }
            // No distribution lists found; process the pick lists
            return false;
        }

        /// <summary>
        /// Finds the next list in the CA25 report and returns the name of its site
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Site on success, empty string if no more lists found in report
        /// </returns>
        private string FindNextListSite(StreamReader sr, out ReportType reportType)
        {
            string fileLine;
            reportType = ReportType.Distribution;
            // Read down the file until we find a distribution list.  When
            // we find one, get the destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("DISTRIBUTION LIST FOR VAULT") != -1)
                {
                    reportType = ReportType.Distribution;
                }
                else if (fileLine.IndexOf("PICKING LIST FOR VAULT") != -1)
                {
                    reportType = ReportType.Picking;
                }
                else
                {
                    continue;
                }
                // Get the site name
                string d = fileLine.Substring(fileLine.IndexOf('(') + 1);
                return d.Substring(0, d.IndexOf(')')).Trim();
            }
            // No more distribution lists found
            return String.Empty;
        }

        
        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader sr, ReportType reportType)
        {
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf(" QUALIFIER ") != -1 && fileLine.IndexOf(" FNAME ") != -1)
                {
                    dataPos = fileLine.IndexOf("FNAME");
                    dataLen = fileLine.IndexOf("SEQ") - dataPos;
                    datePos = fileLine.IndexOf("EXPDAT");
                    // Site depends on report type
                    if (reportType == ReportType.Picking)
                    {
                        sitePos = fileLine.IndexOf("VAULT");
                        siteLen = fileLine.IndexOf("SLOT") - sitePos;
                    }
                    else
                    {
                        sitePos = fileLine.LastIndexOf("VAULT");
                        siteLen = fileLine.LastIndexOf("SLOT") - sitePos;
                    }
                    // Leave loop
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
        private void ReadListItems(StreamReader sr, ReportType reportType, bool destinationEnterprise, ref SendListItemCollection sendCollection, ref ReceiveListItemCollection receiveCollection)
        {
            string fileLine;
            string serialNo;
            string dateString;
            int realDate = -1;
            bool isReceive = false;
            string noteText = String.Empty;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    continue;
                }
                else if (fileLine.IndexOf("STAR-1100 VAULT MANAGEMENT SUBSYSTEM") != -1)
                {
                    break;
                }
                // Check the resolution of the source site.  Go to the next entry if the source is the same
                // as the destination or if the source is unrecognized and we are ignoring unknown sites.
                // If the source cannot be resolved and we are not ignoring unknown sites, throw an exception.
                try
                {
                    bool sourceEnterprise;
                    // Resolve the source site
                    if (fileLine.Length < sitePos + siteLen)
                        sourceEnterprise = SiteIsEnterprise(fileLine.Substring(sitePos).Trim());
                    else
                        sourceEnterprise = SiteIsEnterprise(fileLine.Substring(sitePos, siteLen).Trim());
                    // If the source resolves to the same as the destination, go to the next record
                    if (sourceEnterprise == destinationEnterprise)
                        continue;
                }
                catch (ExternalSiteException)
                {
                    if (this.IgnoreUnknownSite == false)
                        throw;
                    else
                        continue;
                }
                // Get the serial number
                serialNo = fileLine.Substring(serialPos, serialLen).Trim();
                // Get the notes (data set) if we need them
                if (this.DataSetNoteAction != "NO ACTION")
                    noteText = fileLine.Substring(dataPos, dataLen).Trim();
                // Determine whether we are creating receive list items or send list items                
                if (destinationEnterprise == true)
                    isReceive = reportType != ReportType.Picking;
                else
                    isReceive = reportType != ReportType.Distribution;
                // Construct an item of the correct type and fill it
                if (isReceive == true)
                {
                    receiveCollection.Add(new ReceiveListItemDetails(serialNo, noteText));
                }
                else
                {
                    string returnDate = String.Empty;
                    // If we're getting the expiration date to use as the 
                    // return date, we need to do a little extra work.
                    if (this.EmployReturnDate == true)
                    {
                        int yearNo = 0;
                        string dayString = String.Empty;
                        string monthString = String.Empty;
                        // Find where the date really begins
                        if (realDate == -1)
                            for (realDate = datePos; fileLine[realDate-1] != ' '; )
                                realDate -= 1;
                        // Get the date string
                        if ((dateString = fileLine.Substring(realDate, fileLine.IndexOf(' ', realDate) - realDate)).Trim().Length != 0)
                        {
                            // Date may be of different formats
                            if (dateString.Length == 6)
                            {
                                monthString = dateString.Substring(0,2);
                                dayString = dateString.Substring(2,2);
                                yearNo = Int32.Parse(dateString.Substring(4,2)) + 2000;
                            }
                            else if (dateString.Length == 8)
                            {
                                if (dateString[0] == '2')
                                {
                                    monthString = dateString.Substring(4,2);
                                    dayString = dateString.Substring(6,2);
                                    yearNo = Int32.Parse(dateString.Substring(0,4));
                                }
                                else
                                {
                                    monthString = dateString.Substring(0,2);
                                    dayString = dateString.Substring(2,2);
                                    yearNo = Int32.Parse(dateString.Substring(4,4));
                                }
                            }
                            // Set the return date
                            returnDate = String.Format("{0}/{1}/{2}", yearNo, monthString, dayString);
                        }
                    }
                    // Add the item to the collection
                    sendCollection.Add(new SendListItemDetails(serialNo, returnDate, noteText, String.Empty));
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
            // See if we should ignore the picking lists
            bool ignorePicking = this.IgnorePickingLists(fileText);
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            ReportType reportType;
            string fileLine = String.Empty;
            string destination = String.Empty;
            bool destinationEnterprise = false;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while ((destination = FindNextListSite(sr, out reportType)) != String.Empty) 
                {
                    if (ignorePicking == false || reportType != ReportType.Picking)
                    {
                        // Resolve the destination site
                        try
                        {
                            destinationEnterprise = SiteIsEnterprise(destination);
                        }
                        catch (ExternalSiteException)
                        {
                            if (this.IgnoreUnknownSite == false)
                            {
                                throw;
                            }
                            else
                            {
                                destination = String.Empty;
                            }
                        }
                        // Move past the list headers
                        MovePastListHeaders(sr, reportType);
                        // Read the items of the list
                        if (destination.Length != 0)
                            ReadListItems(sr, reportType, destinationEnterprise, ref sendCollection, ref receiveCollection);
                    }
                }
            }
        }
    }
}
