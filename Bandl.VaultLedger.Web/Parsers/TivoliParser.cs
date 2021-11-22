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
	/// Summary description for TivoliParser.
	/// </summary>
	public class TivoliParser : Parser, IParserObject
	{
        ReportType reportType;   // Distribution = shipping, Picking = receiving
        string site1; // source site
        string site2; // destination site

        public TivoliParser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            string fileLine = null;
            reportType = ReportType.Unknown;
            site1 = String.Empty;
            site2 = String.Empty;


            while ((fileLine = r.ReadLine()) != null)
            {
                // Change to uppercase
                if (fileLine.ToUpper().IndexOf("TAPES BEING SENT OFFSITE") != -1)
                {
                    reportType = ReportType.Distribution;
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("TAPES GOING TO") != -1)
                {
                    site1 = fileLine.Substring(0, fileLine.IndexOf(' '));
                    site2 = fileLine.Substring(fileLine.LastIndexOf(' ') + 1);
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("FROM OFFSITE STORAGE") != -1)
                {
                    reportType = ReportType.Picking;
                    break;
                }
            }
            // If we have a list, move past the hyphen line
            if (reportType != ReportType.Unknown || site1.Length != 0 || site2.Length != 0)
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("-") != -1)
                    {
                        if (0 == fileLine.Replace("-", String.Empty).Trim().Length)
                        {
                            return true;
                        }
                    }
                }
            }
            // Unable to move past headers
            return false;
        }

        /// <summary>
        /// Reads the items for a single distribution list in the CA25 report.
        /// Stream reader should be positioned before the first item of the 
        /// list upon entry.
        /// </summary>
        private void ReadListItems(StreamReader r, ref IList il)
        {
            int i = -1;
            string fileLine;

            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if ((i = fileLine.IndexOf(' ')) != -1)
                {
                    // Shorten the file line to just the serial number
                    fileLine = fileLine.Substring(0, i);
                    // Create the item and add to the collection
                    if (il is SendListItemCollection)
                    {
                        il.Add(new SendListItemDetails(fileLine, String.Empty, String.Empty, String.Empty));
                    }
                    else
                    {
                        il.Add(new ReceiveListItemDetails(fileLine, String.Empty));
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
        /// <param name="rli">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="sli">
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli)
        {
            IList il = null;
            // Site resolution flags
            bool resolve1 = false;
            bool resolve2 = false;
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                while (MovePastListHeaders(r))
                {
                    if (site1 == String.Empty)
                    {
                        il = (reportType == ReportType.Distribution ? (IList)sli : (IList)rli);
                        ReadListItems(r, ref il);
                    }
                    else
                    {
                        // Source site
                        try
                        {
                            resolve1 = SiteIsEnterprise(site1);
                        }
                        catch (ExternalSiteException)
                        {
                            if (!this.IgnoreUnknownSite)
                            {
                                throw;
                            }
                            else
                            {
                                site1 = String.Empty;
                            }
                        }
                        // Destination site
                        try
                        {
                            resolve2 = SiteIsEnterprise(site2);
                        }
                        catch (ExternalSiteException)
                        {
                            if (!this.IgnoreUnknownSite)
                            {
                                throw;
                            }
                            else
                            {
                                site2 = String.Empty;
                            }
                        }
                        // Read the items of the list
                        if (site1.Length != 0 || site2.Length != 0)
                        {
                            // If one site was unknown, set it to the opposite of the other site
                            if (site1.Length == 0)
                            {
                                resolve1 = !resolve2;
                            }
                            else if (site2.Length == 0)
                            {
                                resolve2 = !resolve1;
                            }
                            // Get the items if the source does not match the destination
                            if (resolve1 != resolve2)
                            {
                                if (resolve1 == true)
                                {
                                    il = (IList)sli;
                                    ReadListItems(r, ref il);
                                }
                                else
                                {
                                    il = (IList)rli;
                                    ReadListItems(r, ref il);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
