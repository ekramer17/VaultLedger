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
    /// Parses a CA25 report
    /// </summary>
    public class CA25Parser : Parser, IParserObject
    {
        int cSite = -1;
        int cData = -1;
        int cDate = -1;
        int cTape = -1;
        int createDate = -1;

        public CA25Parser() {}

        protected bool IgnorePickingLists(byte[] fileText)
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
                    if (fileLine.IndexOf("DISTRIBUTION LIST FOR") != -1)
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
        protected string FindNextListSite(StreamReader sr, out ReportType reportType)
        {
            string fileLine;
            reportType = ReportType.Distribution;
            // Read down the file until we find a distribution list.  When
            // we find one, get the destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("DISTRIBUTION LIST FOR") != -1)
                {
                    reportType = ReportType.Distribution;
                }
                else if (fileLine.IndexOf("PICKING LIST FOR") != -1)
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
            int dashedLineCount = 0;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (String.Empty == fileLine.Trim().Replace("-",String.Empty))
                {
                    dashedLineCount += 1;
                    if (2 == dashedLineCount) return;
                }
                else if (dashedLineCount == 1 && fileLine.IndexOf("DATA SET NAME") != -1)
                {
                    // Get header indexes
                    cTape = fileLine.IndexOf("VOLSER");
                    cData = fileLine.IndexOf("DATA SET NAME");
                    cDate = fileLine.IndexOf("EXPIRATION");
                    // Read next line to get date
                    fileLine = sr.ReadLine();
                    cSite = fileLine.IndexOf("VAULT");
                    createDate = fileLine.LastIndexOf("DATE");
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
            string siteName;
            bool isReceive = false;
            string noteText = String.Empty;
            Regex julianMatch = new Regex("^(19|20)[0-9]{2}/[0-9]{1,3}$");

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine.Length < createDate)
                {
                    break;
                }
                else if (julianMatch.IsMatch(fileLine.Substring(createDate, 8)) == false)
                {
                    break;
                }
                // Get the elements
                serialNo = fileLine.Substring(cTape, fileLine.IndexOf(' ', cTape) - cTape).Trim();
                siteName = fileLine.Substring(cSite, fileLine.IndexOf(' ', cSite) - cSite).Trim();
                // Check the resolution of the source site.  Go to the next entry if the source is the same
                // as the destination or if the source is unrecognized and we are ignoring unknown sites.
                // If the source cannot be resolved and we are not ignoring unknown sites, throw an exception.
                try
                {
                    if (SiteIsEnterprise(siteName) == destinationEnterprise)
                    {
                        continue;
                    }
                }
                catch (ExternalSiteException)
                {
                    if (this.IgnoreUnknownSite == false)
                    {
                        throw;
                    }
                    else
                    {
                        continue;
                    }
                }
                // Get the notes (data set) if we need them
                noteText = DataSetNoteAction != "NO ACTION" ? fileLine.Substring(cData, cSite - cData).Trim() : String.Empty;
                // Determine whether we are creating receive list items or send list items                
                if (destinationEnterprise == true)
                {
                    isReceive = reportType != ReportType.Picking;
                }
                else
                {
                    isReceive = reportType != ReportType.Distribution;
                }
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
                        string julianDate = fileLine.Substring(cDate,8).Trim();
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
                        MovePastListHeaders(sr);
                        // Read the items of the list
                        if (destination.Length != 0)
                            ReadListItems(sr, reportType, destinationEnterprise, ref sendCollection, ref receiveCollection);
                    }
                }
            }
        }
    }
}
