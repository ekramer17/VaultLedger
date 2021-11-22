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
    public class McDonaldsParser : Parser, IParserObject
    {
        int pSerial = -1;
        int pData = -1;

        public McDonaldsParser() {}

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
            string d = String.Empty;
            string s = String.Empty;
            bool returnValue = false;
            // Read down the file until we find a destination.
            while (returnValue == false && (fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("TO LOCATION") != -1)
                {
                    d = fileLine.Substring(fileLine.IndexOf('-') + 1).Trim();
                    d = d.IndexOf('-') == -1 ? d : d.Substring(0, d.IndexOf('-')).Trim();
                    d = d.LastIndexOf(')') == -1 ? d : d.Substring(0, d.LastIndexOf(')')).Trim();
                }
                else if (fileLine.IndexOf("FROM LOCATION") != -1)
                {
                    s = fileLine.Substring(fileLine.IndexOf('-') + 1).Trim();
                    s = s.IndexOf('-') == -1 ? s : s.Substring(0, s.IndexOf('-')).Trim();
                    s = s.LastIndexOf(')') == -1 ? s : s.Substring(0, s.LastIndexOf(')')).Trim();
                }
                // If we have both a source and a destination, return
                returnValue = s.Length != 0 && d.Length != 0;
            }
            // Set the output strings
            source = s;
            destination = d;
            // Return
            return returnValue;
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
            const string ds1 = "DATA SET NAME";
            const string ds2 = "DATASET NAME";
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("SERIAL") != -1 && (fileLine.IndexOf(ds1) != -1 || fileLine.IndexOf(ds2) != -1))
                {
                    pSerial = fileLine.IndexOf("SERIAL");
                    pData = fileLine.IndexOf(ds1) != -1 ? fileLine.IndexOf(ds1) : fileLine.IndexOf(ds2);
                    // Skip the next line (dashes underneath headers)
                    sr.ReadLine();
                    // Break the loop
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
        private void ReadListItems(StreamReader r, string accountName, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string fileLine;
            string serialNo;
            string dataNote = String.Empty;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // If line contains first header line, break
                if (fileLine.IndexOf("The SAS System") != -1)
                {
                    break;
                }
                else if (fileLine.IndexOf("MCDONALDS CORPORATION") != -1)
                {
                    break;
                }
                // If we have no list collection, then we're skipping the
                // content section; just move along.  Also, line must start
                // with a left parenthesis, be of miminum length, and have
                // information in the serial number field.
                if (il == null)
                {
                    continue;
                }
                else if (fileLine[0] != '(')
                {
                    continue;
                }
                else if (fileLine.Length <= pData)
                {
                    continue;
                }
                else if (0 == fileLine[pSerial].ToString().Trim().Length)
                {
                    continue; 
                }
                else
                {
                    // Serial number
                    serialNo = (serialNo = fileLine.Substring(pSerial)).Substring(0, serialNo.IndexOf(' '));
                    // Data set, if necessary
                    if (this.DataSetNoteAction != "NO ACTION")
                    {
                        dataNote = fileLine.Substring(pData).Replace(")'", String.Empty).Trim();
                        if (dataNote.IndexOf(' ') != -1) dataNote = dataNote.Substring(0, dataNote.IndexOf(' '));
                    }
                    // Construct an item of the correct type and fill it
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(serialNo, dataNote));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(serialNo, String.Empty, dataNote, String.Empty));
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
            string source = String.Empty;
            string fileLine = String.Empty;
            string destination = String.Empty;
            using (StreamReader r = new StreamReader(ms))
            {
                bool x = false, y = false;
                string accountName = String.Empty;
                // Read through the stream
                while (FindNextSites(r, out source, out destination))
                {
                    // Destination site
                    try
                    {
                        x = SiteIsEnterprise(destination, out accountName);
                        // Only seek account name if we don't have one
                        if (accountName.Length == 0)
                        {
                            if (this.IsAccount(destination))
                            {
                                accountName = destination;
                            }
                        }
                    }
                    catch (ExternalSiteException)
                    {
                        if (this.IsAccount(destination))
                        {
                            x = false;
                            accountName = destination;
                        }
                        else if (!this.IgnoreUnknownSite)
                        {
                            throw;
                        }
                        else
                        {
                            destination = String.Empty;
                        }
                    }
                    // Source site
                    try
                    {
                        string a2 = String.Empty;
                        y = SiteIsEnterprise(source, out a2);
                        // Only seek account name if we don't have one
                        if (accountName.Length == 0) 
                        {
                            if (a2.Length != 0)
                            {
                                accountName = a2;
                            }
                            else if (this.IsAccount(source))
                            {
                                accountName = source;
                            }
                        }
                    }
                    catch (ExternalSiteException)
                    {   
                        if (this.IsAccount(source))
                        {
                            y = false;
                            // Account name?
                            if (accountName.Length == 0)
                            {
                                accountName = source;
                            }
                        }
                        else if (!this.IgnoreUnknownSite)
                        {
                            throw;
                        }
                        else
                        {
                            source = String.Empty;
                        }
                    }
                    // Move past the list headers
                    MovePastListHeaders(r);
                    // Read the items of the list
                    if (destination.Length != 0 || source.Length != 0)
                    {
                        // If one site was unknown, set it to the opposite of the other site
                        if (source.Length == 0)
                        {
                            y = !x;
                        }
                        else if (destination.Length == 0)
                        {
                            x = !y;
                        }
                        // Get the items if the destination does not match the source.  If they
                        // match, supply a null collection -- we'll move forward through the
                        // report without collecting any items.
                        if (x == y)
                        {
                            il = null;
                            ReadListItems(r, accountName, ref il, ref s, ref a, ref l);
                        }
                        else if (x == true)
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
