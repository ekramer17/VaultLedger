using System;
using System.IO;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ConsecoParser.
    /// </summary>
    public class Conseco2Parser : Parser, IParserObject
    {
        ListTypes reportType;
        int cTape;
        int cData;
        int cDate;

        public Conseco2Parser() {}

        /// <summary>
        /// Gets the source site
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Name of the source site
        /// </returns>
        private string GetSiteName(StreamReader sr)
        {
            int x, y;
            string fileLine;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("MOVEMENT") != -1)
                {
                    if ((x = fileLine.ToUpper().IndexOf("LOCATION")) != -1)
                    {
                        if ((y = fileLine.ToUpper().IndexOf("PAGE")) != -1)
                        {
                            reportType = fileLine.ToUpper().IndexOf("INCOMING") != -1 ? ListTypes.Send : ListTypes.Receive;
                            return fileLine.Substring(x + 9, y - (x + 9)).Trim();
                        }
                    }
                }
            }
            // Source not found
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
                cTape = fileLine.IndexOf("VOLSER");
                cData = fileLine.IndexOf("DATASET");
                cDate = fileLine.IndexOf("EXPIRATION");
                // If all > -1, return
                if (cTape != -1 && cData != -1 && cDate != -1) break;
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
        private void ReadListItems(StreamReader r, string accountName, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string fileLine, serialNo;
            string noteString = String.Empty;
            string dateString = String.Empty;
            Regex dateMatch = new Regex("^[01][0-9]/[0123][0-9]/2[0-9]{3}$");
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("TOTAL REPORTED") != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("C O N S E C O , I N C") != -1)
                {
                    break;
                }
                // Get the serial number
                serialNo = fileLine.Substring(cTape, fileLine.IndexOf(' ', cTape) - cTape).Trim();
                // Get the notes (data set) if we need them
                if (DataSetNoteAction != "NO ACTION")
                    noteString = fileLine.Substring(cData, cDate - cData).Trim();
                // Construct an item of the correct type and fill it
                if (il is ReceiveListItemCollection)
                {
                    il.Add(new ReceiveListItemDetails(serialNo, noteString));
                }
                else
                {
                    string returnDate = String.Empty;
                    // If we're getting the expiration date to use as the return date, we need to do a little extra work.
                    if (EmployReturnDate && dateMatch.IsMatch((dateString = fileLine.Substring(cDate,10).Trim())))
                    {
                        int m = Int32.Parse(dateString.Substring(0,2));
                        int d = Int32.Parse(dateString.Substring(3,2));
                        int y = Int32.Parse(dateString.Substring(6,4));
                        returnDate = new DateTime(y,m,d).ToString("yyyy-MM-dd");
                    }
                    // Add the item to the collection
                    il.Add(new SendListItemDetails(serialNo, returnDate, noteString, String.Empty));
                }
                // Add account number and location to array list if we have an account number
                if (accountName.Length != 0)
                {
                    s.Add(serialNo);
                    a.Add(accountName);
                    l.Add(il is SendListItemCollection ? Locations.Enterprise : Locations.Vault);
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
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            IList il = null;
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            bool isEnterprise = false;
            string siteName = String.Empty;
            string fileLine = String.Empty;
            using (StreamReader r = new StreamReader(ms))
            {
                string accountName = String.Empty;
                // Read items from list
                while ((siteName = GetSiteName(r)) != String.Empty)
                {
                    // Resolve the source site
                    try
                    {
                        isEnterprise = SiteIsEnterprise(siteName, out accountName);
                    }
                    catch (ExternalSiteException)
                    {
                        if (!IgnoreUnknownSite)
                        {
                            throw;
                        }
                        else
                        {
                            siteName = String.Empty;
                        }
                    }
                    // Move past the list headers
                    MovePastListHeaders(r);
                    // Read the list items
                    if (siteName.Length != 0)
                    {
                        if (reportType == ListTypes.Receive)
                        {
                            il = (IList)rli;
                            ReadListItems(r, accountName, ref il, ref s, ref a, ref l);
                        }
                        else
                        {
                            il = (IList)sli;
                            ReadListItems(r, accountName, ref il, ref s, ref a, ref l);
                        }
                    }
                }
            }
        }
    }
}
