using System;
using System.IO;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a CA25 report
    /// </summary>
    public class RMM3Parser : Parser, IParserObject
    {
        int serialLen = -1;
        int serialIndex = -1;
        int dataLen = -1;
        int dataIndex = -1;
        int dateLen = -1;
        int dateIndex = -1;

        public RMM3Parser() {}

        /// <summary>
        /// Protects the field length from going beyond the end of a truncated line
        /// </summary>
        /// <param name="fileLine"></param>
        /// <param name="startIndex"></param>
        /// <param name="expectedLength"></param>
        /// <returns></returns>
        private int GetFieldLength(string fileLine, int startIndex, int expectedLength)
        {
            if (startIndex + expectedLength > fileLine.Length)
                return fileLine.Length - startIndex;
            else
                return expectedLength;
        }

        /// <summary>
        /// Finds the next distribution list in the CA25 report and returns
        /// the name of the destination site.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <param name="sourceSite">
        /// Source site : returned as an out parameter
        /// </param>
        /// <returns>
        /// Destination site on success, empty string if no more distribution
        /// lists found in report.
        /// </returns>
        private string FindNextDestination(StreamReader sr, out string sourceSite)
        {
            int indexTo;
            int indexMove;
            string endLine;
            string fileLine;
            // Read down the file until we find the destination line.  When
            // we find it, get the destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().IndexOf("Report 3") == 0)
                {
                    string upperCase = fileLine.ToUpper();
                    if ((indexMove = upperCase.IndexOf("MOVEMENT: ")) != -1)
                    {
                        indexMove += 10; // Length of "MOVEMENT: "
                        if ((indexTo = upperCase.IndexOf(" TO ")) != -1)
                        {
                            sourceSite = fileLine.Substring(indexMove, indexTo - indexMove);
                            endLine = fileLine.Substring(indexTo + 4); // Length of " TO "
                            return endLine.Substring(0, endLine.IndexOf(' ')).Trim();
                        }
                    }
                }
            }
            // No more distribution lists found
            sourceSite = String.Empty;
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
                if (fileLine.IndexOf("SERIAL") != -1 && fileLine.IndexOf("D A T A S E T") != -1)
                {
                    // Get the indexes
                    dateIndex = fileLine.IndexOf("DATE");
                    serialIndex = fileLine.IndexOf("SERIAL");
                    dataIndex = fileLine.IndexOf("D A T A S E T");
                    // Read the next line
                    fileLine = sr.ReadLine();
                    // Verify that it consists only of hyphens.  If it does, then
                    // derive the field lengths and return.
                    if (fileLine.Replace("-", String.Empty).Trim() == String.Empty)
                    {
                        serialLen = fileLine.IndexOf(" ", serialIndex) - serialIndex;
                        dataLen = fileLine.IndexOf(" ", dataIndex) - dataIndex;
                        if (dateIndex != -1) 
                        {
                            dateLen = fileLine.IndexOf(" ", dateIndex) - dateIndex;
                        }
                        // Return
                        return;
                    }
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
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Number of items added
        /// </returns>
        private int ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            int itemCount = 0;
            int fieldLength;
            string fileLine;
            string serialNo;
            string notes = String.Empty;
            Regex julianEx = new Regex(@"^2[0-9]{3}[/\-\.]{1}[0-9]{2,3}$");
            Regex monthDayEx = new Regex(@"^[0-9]{2}[/\-\.][0-9]{2}[/\-\.]2[0-9]{3}$");

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If the line starts with "Total of" after trimming, or there is
                // a series of 8 spaces beginning with the 2nd character, then break
                if (fileLine.Trim().Substring(0,8) == "Total of")
                {
                    break;
                }
                else if (fileLine.Substring(1,8).Trim() == String.Empty)
                {
                    break;
                }
                // Get the serial number
                fieldLength = GetFieldLength(fileLine, serialIndex, serialLen);
                serialNo = fileLine.Substring(serialIndex, fieldLength).Trim();
                // Get the notes (data set) if we need them
                if (this.DataSetNoteAction != "NO ACTION")
                {
                    fieldLength = GetFieldLength(fileLine, dataIndex, dataLen);
                    notes = fileLine.Substring(dataIndex, fieldLength).Trim();
                }
                // Construct an item of the correct type and fill it
                if (itemCollection is ReceiveListItemCollection)
                {
                    ReceiveListItemDetails newItem = new ReceiveListItemDetails(serialNo, notes);
                    itemCollection.Add(newItem);
                    itemCount++;
                }
                else
                {
                    string returnDate = String.Empty;
                    // If we're getting the expiration date to use as the 
                    // return date, we need to do a little extra work.
                    if (dateIndex != -1 && this.EmployReturnDate == true)
                    {
                        fieldLength = GetFieldLength(fileLine, dateIndex, dateLen);
                        string dateField = fileLine.Substring(dateIndex, fieldLength).Trim();
                        if (julianEx.IsMatch(dateField.Substring(0,5)))
                        {
                            int year = Convert.ToInt32(dateField.Substring(0,4));
                            int day = Convert.ToInt32(dateField.Substring(5,3));
                            returnDate = new DateTime(year, 1, 1).AddDays(day - 1).ToString("yyyy-MM-dd");
                        }
                        else if (monthDayEx.IsMatch(dateField))
                        {
                            int y = Convert.ToInt32(dateField.Substring(6,4));
                            int d = Convert.ToInt32(dateField.Substring(3,2));
                            int m = Convert.ToInt32(dateField.Substring(0,2));
                            returnDate = new DateTime(y, m, d).ToString("yyyy-MM-dd");
                        }
                    }
                    // Add the item to the collection
                    itemCollection.Add(new SendListItemDetails(serialNo, returnDate, notes, String.Empty));
                    itemCount++;
                }
            }
            // Return
            return itemCount;
        }

        /// <summary>
        /// Parses the given text array and returns send list items and 
        /// receive list items.  Use this overload if the stream is a
        /// new TMS send/receive list report.
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
            int totalItems = 0;
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
            string fileLine = String.Empty;
            string sourceSite = String.Empty;
            string destination = String.Empty;
            bool sourceResolve = false;
            bool destResolve = false;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while ((destination = FindNextDestination(sr, out sourceSite)) != String.Empty) 
                {
                    // Destination site
                    try
                    {
                        destResolve = SiteIsEnterprise(destination);
                    }
                    catch
                    {
                        if (!this.IgnoreUnknownSite)
                            throw;
                        else
                            destination = String.Empty;
                    }
                    // Source site
                    try
                    {
                        sourceResolve = SiteIsEnterprise(sourceSite);
                    }
                    catch
                    {
                        if (!this.IgnoreUnknownSite)
                            throw;
                        else
                            sourceSite = String.Empty;
                    }
                    // Move past the list headers
                    MovePastListHeaders(sr);
                    // Read the items of the list
                    if (destination.Length != 0 || sourceSite.Length != 0)
                    {
                        // If one site was unknown, set it to the opposite of the other site
                        if (sourceSite.Length == 0)
                        {
                            sourceResolve = !destResolve;
                        }
                        else if (destination.Length == 0)
                        {
                            destResolve = !sourceResolve;
                        }

                        if (destResolve != sourceResolve)
                        {
                            if (destResolve == true)
                            {
                                listCollection = (IList)receiveCollection;
                                totalItems += ReadListItems(sr, ref listCollection);
                            }
                            else 
                            {
                                listCollection = (IList)sendCollection;
                                totalItems += ReadListItems(sr, ref listCollection);
                            }
                        }
                    }
                }
            }
        }
    }
}
