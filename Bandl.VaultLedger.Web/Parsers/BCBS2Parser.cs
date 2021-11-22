using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.IParser;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for BCBS1.
    /// </summary>
    public class BCBS2Parser : Parser, IParserObject
    {
        int serialLen = -1;
        int serialPos = -1;
        int dataLen = -1;
        int dataPos = -1;
        int dateLen = -1;
        int datePos = -1;

        public BCBS2Parser() {}

        /// <summary>
        /// Finds the next list source and destinations site mentioned in the report.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if destination was found, else false
        /// </returns>
        private bool FindNextSites(StreamReader sr, out string source, out string destination)
        {
            string fileLine;
            source = String.Empty;
            destination = String.Empty;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("FROM LOCATION") != -1 && fileLine.ToUpper().IndexOf("TO LOCATION") != -1)
                {
                    fileLine = fileLine.ToUpper();
                    int x = fileLine.IndexOf("FROM LOCATION");
                    int y = fileLine.IndexOf("TO LOCATION");
                    source = fileLine.Substring(x + 14, y - (x + 14)).Trim();
                    destination = fileLine.Substring(y + 12).Trim();
                    // Source may contain DATE.  If it does, trim it there.
                    if ((x = destination.IndexOf("DATE")) != -1)
                        destination = destination.Substring(0, x).Trim();
                    // Return true
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
                fileLine = fileLine.ToUpper();

                if (fileLine.IndexOf("BIN") != -1 && fileLine.IndexOf("CREATE") != -1 && fileLine.IndexOf("EXPIRATION") != -1)
                {
                    datePos = fileLine.IndexOf("EXPIRATION");
                    dateLen = 10;
                    // Next line
                    fileLine = sr.ReadLine().ToUpper();
                    serialPos = fileLine.IndexOf("SERIAL");
                    dataPos = fileLine.IndexOf("DATA SET");
                    dataLen = fileLine.IndexOf("NUMBER") - dataPos;
                    serialLen = dataPos - serialPos;
                    // Skip the hyphen line
                    sr.ReadLine();
                    // Leave the loop
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
                // If we've reached a BLUE CROSS line, then exit
                if (fileLine.IndexOf("BLUE CROSS BLUE SHIELD") != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("END OF REPORT") != -1)
                {
                    break;
                }
                // If we have no list collection, then we're skipping the
                // content section; just move along
                if (itemCollection == null)
                {
                    continue;
                }
                // Get the serial number
                if ((serialNo = fileLine.Substring(serialPos, serialLen).Trim()) == String.Empty)
                {
                    continue;
                }
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
                    string returnDate = String.Empty;
                    // If we're getting the expiration date to use as the 
                    // return date, we need to do a little extra work.
                    if (this.EmployReturnDate == true)
                    {
                        string julianDate = fileLine.Substring(datePos, dateLen).Trim();
                        if (new Regex("^20[0-9]{2}$").IsMatch(julianDate.Substring(0,4)))
                        {
                            int year = Convert.ToInt32(julianDate.Substring(0,4));
                            int day = Convert.ToInt32(julianDate.Substring(5,3));
                            returnDate = new DateTime(year, 1, 1).AddDays(day - 1).ToString("yyyy-MM-dd");
                        }
                    }
                    // Add the item to the collection
                    itemCollection.Add(new SendListItemDetails(serialNo, returnDate, noteText, String.Empty));
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

                        if (desResolve != srcResolve)
                        {
                            if (desResolve == true)
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
}
