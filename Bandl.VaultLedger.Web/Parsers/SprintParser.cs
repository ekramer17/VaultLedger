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
    /// Parses a CA25 report
    /// </summary>
    public class SprintParser : Parser, IParserObject
    {
        int serialLen = -1;
        int serialPos = -1;
        int caseLen = -1;
        int casePos = -1;
        int dataLen = -1;
        int dataPos = -1;
        int dateLen = -1;
        int datePos = -1;

        public SprintParser() {}

        /// <summary>
        /// Finds the next list source and destinations site mentioned in the report.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if both source and destination were found, else false
        /// </returns>
        private bool FindNextSites(StreamReader sr, out string source, out string destination)
        {
            string fileLine;
            source = String.Empty;
            destination = String.Empty;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("From location . . .") != -1 && fileLine.IndexOf("To location . . .") != -1)
                {
                    destination = fileLine.Substring(fileLine.LastIndexOf(':') + 1).Trim();
                    string s = fileLine.Substring(fileLine.IndexOf(':') + 1).Trim();
                    source = s.Substring(0, s.IndexOf("To location")).Trim();
                    return true;
                }
            }
            // Return unsuccessful
            return false;
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
                if (fileLine.IndexOf("Expir") != -1 && fileLine.IndexOf("Creation") != -1)
                {
                    datePos = fileLine.IndexOf("Expir");
                    dateLen = 10;
                }
                else if (fileLine.IndexOf("Serial") != -1 && fileLine.IndexOf("Slot") != -1 && fileLine.IndexOf("Container") != -1)
                {
                    serialPos = fileLine.IndexOf("Serial");
                    serialLen = 7;
                    casePos = fileLine.IndexOf("Container");
                    caseLen = 10;
                    dataPos = fileLine.IndexOf("Policy");
                    dataLen = 10;
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
        private void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            string fileLine;
            string serialNo;
            string noteText = String.Empty;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If we've reached the "Total volumes" line, then break
                if (fileLine.IndexOf("Total volumes . .") != -1)
                {
                    break;
                }
                // Blank line?
                if (fileLine.Trim() == "")
                {
                    continue;
                }
                // If we have no list collection, then we're skipping the
                // content section; just move along
                if (itemCollection == null)
                {
                    continue;
                }
                // Get the serial number
                serialNo = fileLine.Substring(serialPos, serialLen).Trim();
                // Get the notes (data set) if we need them
                if (this.DataSetNoteAction != "NO ACTION")
                    noteText = fileLine.Substring(dataPos, dataLen).Trim();
                // Construct an item of the correct type and fill it
                if (itemCollection is ReceiveListItemCollection)
                {
                    ReceiveListItemDetails newItem = new ReceiveListItemDetails(serialNo, noteText);
                    // Add the item to the collection
                    itemCollection.Add(newItem);
                }
                else
                {
                    string caseName = String.Empty;
                    string returnDate = String.Empty;
                    string reportDate = String.Empty;
                    // Get the case name if there is one
                    if (fileLine.Substring(casePos,5) != "*NONE")
                        caseName = fileLine.Substring(casePos, caseLen).Trim();
                    // If we're getting the expiration date to use as the 
                    // return date, we need to do a little extra work.
                    if (EmployReturnDate && (reportDate = fileLine.Substring(datePos, dateLen).Trim()).Length != 0)
                    {
                        // Get month, day, year
                        int monthNo = Convert.ToInt32(reportDate.Substring(0, reportDate.IndexOf("/")));
                        int yearNo = Convert.ToInt32(reportDate.Substring(reportDate.LastIndexOf("/") + 1));
                        int dayNo = Convert.ToInt32(reportDate.Substring(reportDate.IndexOf("/") + 1, 2));
                        returnDate = new DateTime(yearNo + 2000, monthNo, dayNo).ToString("yyyy-MM-dd");
                    }
                    // Add the item to the collection
                    itemCollection.Add(new SendListItemDetails(serialNo, returnDate, noteText, caseName));
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
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            bool srcResolve = false;
            bool desResolve = false;
            string source = String.Empty;
            string fileLine = String.Empty;
            string destination = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while (FindNextSites(sr, out source, out destination))
                {
                    // Destination site
                    try
                    {
                        desResolve = SiteIsEnterprise(destination);
                    }
                    catch (ExternalSiteException)
                    {
                        if (this.IgnoreUnknownSite == true)
                            destination = String.Empty;
                        else
                            throw;
                    }
                    // Source site
                    try
                    {
                        srcResolve = SiteIsEnterprise(source);
                    }
                    catch (ExternalSiteException)
                    {
                        if (this.IgnoreUnknownSite == true)
                            source = String.Empty;
                        else
                            throw;
                    }
                    // Move past the list headers
                    MovePastListHeaders(sr);
                    // Read the items of the list
                    if (destination.Length != 0 || source.Length != 0)
                    {
                        // If one site was unknown, set it to the opposite of the other site
                        if (source.Length == 0)
                        {
                            srcResolve = !desResolve;
                        }
                        else if (destination.Length == 0)
                        {
                            desResolve = !srcResolve;
                        }

                        if (desResolve == srcResolve)
                        {
                            listCollection = null;
                            ReadListItems(sr, ref listCollection);
                        }
                        else if (desResolve == true)
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
    }
}
