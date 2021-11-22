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
    /// Parses a Brightstor TM42 report
    /// </summary>
    public class BrightStorParser : Parser, IParserObject
    {
        string f1;
        int p1 = -1;
        int p2 = -1;
        int p3 = -1;

        public BrightStorParser() {}

        /// <summary>
        /// Finds the next list source and destinations site mentioned in the report.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if both source and destination were found, else false
        /// </returns>
        private bool FindNextSites(StreamReader r, out string s, out string d)
        {
            d = String.Empty;
            s = String.Empty;
            // Read down the file until we find a destination.
            while ((f1 = r.ReadLine()) != null)
            {
                if (f1.Length > 3)
                {
                    // Trim the file line
                    f1 = f1.Substring(1).Trim();
                    // Get source or destination
                    if (f1.StartsWith("TO "))
                    {
                        d = f1.Substring(3).Trim();
                    }
                    else if (f1.IndexOf("FROM ") != -1)
                    {
                        s = f1.Substring(5).Trim();
                    }
                    // If we have both a source and a destination, return
                    if (s.Length != 0 && d.Length != 0)
                    {
                        s = s.Replace("  ", " ");
                        d = d.Replace("  ", " ");
                        return true;
                    }
                }
            }
            // Return
            return false;
        }
        
        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader r)
        {
            while ((f1 = r.ReadLine()) != null)
            {
                if ((p1 = f1.IndexOf("SERIAL")) != -1 && (p2 = f1.IndexOf("DATASET NAME")) != -1)
                {
                    int x1 = f1.IndexOf("I--");
                    int x2 = f1.IndexOf("--I");
                    // Data set length
                    p3 = x2 - x1 + 3;
                    // Skip the next line (dashes underneath headers)
                    r.ReadLine();
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
            string s1 = null;
            string n1 = String.Empty;
            // Read through the file, collecting items
            while ((f1 = r.ReadLine()) != null)
            {
                // End of section?
                if (f1.IndexOf("VOLUMES MOVED") != -1 || f1.IndexOf("VOLUMES TO BE MOVED") != -1) break;
                // If we have no list collection, then we're skipping the content section; just move along.
                if (il == null) continue;
                // Make sure we have data in the line
                if (f1.Length < p2 || f1.Trim().Length == 0) continue;
                // Get the serial number
                s1 = f1.Substring(p1, f1.IndexOf(' ', p1) - p1).Trim();
                // Get the data note
                if (this.DataSetNoteAction != "NO ACTION") n1 = f1.Substring(p2, p3).Trim();
                // Construct an item of the correct type and fill it
                if (il is ReceiveListItemCollection)
                {
                    il.Add(new ReceiveListItemDetails(s1, n1));
                }
                else
                {
                    il.Add(new SendListItemDetails(s1, String.Empty, n1, String.Empty));
                }
                // Add account number and location to array list if we have an account number
                if (accountName.Length != 0)
                {
                    s.Add(s1);
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
            // Initialize sites
            string source = String.Empty;
            string destination = String.Empty;
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
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
