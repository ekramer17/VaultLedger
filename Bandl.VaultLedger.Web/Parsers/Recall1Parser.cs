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
    /// Parses a standard Recall report.  We defined the standard.
    /// </summary>
    public class Recall1Parser : Parser, IParserObject
    {
        int serialLen = -1;
        int serialPos = -1;
        int dataLen = -1;
        int dataPos = -1;
        int dateLen = -1;
        int datePos = -1;

        public Recall1Parser() {}

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
                if (fileLine.ToUpper().IndexOf("SOURCE SITE:") != -1)
                {
                    source = fileLine.Substring(fileLine.IndexOf(':') + 1).Trim();
                }
                else if (fileLine.ToUpper().IndexOf("DESTINATION SITE:") != -1)
                {
                    destination = fileLine.Substring(fileLine.IndexOf(':') + 1).Trim();
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

                if (fileLine.IndexOf("EXPIR") != -1)
                {
                    datePos = fileLine.IndexOf("EXPIR");
                }
                else if (fileLine.IndexOf("ACCT") != -1 && fileLine.IndexOf("TYPE") != -1)
                {
                    if (fileLine.IndexOf("DATA SET") != -1 &&  fileLine.IndexOf("SERIAL") != -1)
                    {
                        // Get return date and data
                        serialPos = fileLine.ToUpper().IndexOf("SERIAL");
                        dataPos = fileLine.ToUpper().IndexOf("DATA SET");
                        // Go to the next line
                        fileLine = sr.ReadLine();
                        // Get the lengths
                        serialLen = fileLine.Substring(serialPos).Split(new char[] {' '})[0].Length;
                        dataLen = fileLine.Substring(dataPos).Split(new char[] {' '})[0].Length;
                        dateLen = fileLine.Substring(datePos).Split(new char[] {' '})[0].Length;
                        // Break the loop
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
        private void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            string fileLine;
            string serialNo;
            string noteText = String.Empty;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If we've reached a blank line, exit
                if (fileLine.Trim().Length == 0)
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
                    int m, d, y;
                    string reportDate = null;
                    string returnDate = String.Empty;
                    // If we're getting the expiration date to use as the 
                    // return date, we need to do a little extra work.
                    if (datePos != -1 && this.EmployReturnDate == true)
                    {
                        if ((reportDate = fileLine.Substring(datePos, dateLen).Trim()).Length != 0)
                        {
                            y = Convert.ToInt32(reportDate.Substring(0, 4));
                            m = Convert.ToInt32(reportDate.Substring(reportDate.IndexOf('/') != -1 ? 5 : 4, 2));
                            d = Convert.ToInt32(reportDate.Substring(reportDate.IndexOf('/') != -1 ? 8 : 6, 2));
                            returnDate = new DateTime(y, m, d).ToString("yyyy-MM-dd");
                        }
                    }
                    // Add the list item
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
                    // Source site (allow no source if we have a destination)
                    try
                    {
                        if (source.Length == 0 && destination.Length != 0)
                            srcResolve = !desResolve;
                        else
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
