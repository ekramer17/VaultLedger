using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.IParser;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses an LA Times report
    /// </summary>
    public class LATimesParser : Parser, IParserObject
    {
        int sitePos = -1;
        int dataPos = -1;
        int returnPos = -1;
        int serialPos = -1;

        public LATimesParser() {}

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


        private int RefineStartPosition(string fileLine, int position)
        {
            // Move backward until we reach the beginning of the line or until we find a space
            while (position > 0 && fileLine[position-1] != ' ')
                position -= 1;
            // Return the start position
            return position;
        }

        private void GetColumnPositions(byte[] fileText)
        {
            string fileLine;
            // Create a momeory stream over the file text
            MemoryStream memoryStream = new MemoryStream(fileText);
            // Run through the list, looking for headers.
            using (StreamReader streamReader = new StreamReader(memoryStream))
            {
                while ((fileLine = streamReader.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("VOLUME CREATED BY") != -1 && fileLine.IndexOf("EXPDT") != -1)
                    {
                        fileLine = streamReader.ReadLine();
                        // Get start positions of the columns
                        serialPos = fileLine.IndexOf("SERIAL");
                        returnPos = fileLine.IndexOf("DATE");
                        dataPos = fileLine.IndexOf("DATA SET");
                        sitePos = fileLine.IndexOf("VAULT");
                        // Skip two lines
                        fileLine = streamReader.ReadLine();
                        fileLine = streamReader.ReadLine();
                        // Refine the start positions of return date and data set
                        returnPos = RefineStartPosition(fileLine, returnPos);
                        dataPos = RefineStartPosition(fileLine, dataPos);
                        // Break the loop
                        break;
                    }
                }
            }
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
        private void MovePastListHeaders(StreamReader sr)
        {
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("VOLUME CREATED BY") != -1 && fileLine.IndexOf("EXPDT") != -1)
                {
                    // Skip two lines
                    sr.ReadLine();
                    sr.ReadLine();
                    // Break the loop
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
            string julianDate;
            string noteText = String.Empty;
            string sourceSite = String.Empty;
            Regex julianMatch = new Regex("^20[0-9]{2}/[0-9]{1,3}$");
            bool receiveItem = false;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine[0] != ' ')
                {
                    break;
                }
                // Check the resolution of the source site.  Go to the next entry if the source is the same
                // as the destination or if the source is unrecognized and we are ignoring unknown sites.
                // If the source cannot be resolved and we are not ignoring unknown sites, throw an exception.
                try
                {
                    sourceSite = fileLine.Substring(sitePos);
                    sourceSite = sourceSite.Substring(0, sourceSite.IndexOf(' '));
                    // If the source resolves to the same as the destination, go to the next record
                    if (SiteIsEnterprise(sourceSite) == destinationEnterprise) 
                        continue;
                }
                catch (ExternalSiteException)
                {
                    if (!this.IgnoreUnknownSite)
                        throw;
                    else
                        continue;
                }
                // Get the serial number
                serialNo = fileLine.Substring(serialPos);
                serialNo = serialNo.Substring(0, serialNo.IndexOf(' '));
                // Get the notes (data set) if we need them
                if (this.DataSetNoteAction != "NO ACTION")
                    noteText = fileLine.Substring(dataPos, sitePos - dataPos).Trim();
                // Determine whether we are creating receive list items or send list items                
                if (destinationEnterprise == true)
                {
                    receiveItem = reportType != ReportType.Picking;
                }
                else
                {
                    receiveItem = reportType != ReportType.Distribution;
                }
                // Construct an item of the correct type and fill it
                if (receiveItem == true)
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
                        julianDate = fileLine.Substring(returnPos);
                        julianDate = julianDate.Substring(0, julianDate.IndexOf(' '));
                        // If the string is a date, use it
                        if (julianMatch.IsMatch(julianDate))
                        {
                            int year = Convert.ToInt32(julianDate.Substring(0,4));
                            int day = Convert.ToInt32(julianDate.Substring(5,3).Trim());
                            returnDate = new DateTime(year, 1, 1).AddDays(day - 1).ToString("yyyy-MM-dd");
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
            // Get column positions
            GetColumnPositions(fileText);
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            ReportType reportType;
            bool desLocal = false;
            string desSite = String.Empty;
            string fileLine = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while ((desSite = FindNextListSite(sr, out reportType)) != String.Empty) 
                {
                    if (ignorePicking == false || reportType != ReportType.Picking)
                    {
                        // Resolve the destination site
                        try
                        {
                            desLocal = SiteIsEnterprise(desSite);
                        }
                        catch (ExternalSiteException)
                        {
                            if (!this.IgnoreUnknownSite)
                            {
                                throw;
                            }
                            else
                            {
                                desSite = String.Empty;
                            }
                        }
                        // Move past the list headers
                        MovePastListHeaders(sr);
                        // Read the items of the list
                        if (desSite.Length != 0)
                            ReadListItems(sr, reportType, desLocal, ref sendCollection, ref receiveCollection);
                    }
                }
            }
        }
    }
}
