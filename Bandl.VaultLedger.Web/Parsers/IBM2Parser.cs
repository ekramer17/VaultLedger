using System;
using System.IO;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for IBM2Parser.
	/// </summary>
	public class IBM2Parser : Parser, IParserObject
	{
        string site1 = String.Empty;
        string site2 = String.Empty;

        public IBM2Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        /// <returns>
        /// True if headers were found, else false
        /// </returns>
        private void MovePastListHeaders(StreamReader r)
        {
            string fileLine = r.ReadLine().ToUpper().Trim().Replace("FROM ", String.Empty).Replace(" TO ", " ");
            site1 = fileLine.Substring(0, fileLine.IndexOf(' '));
            site2 = fileLine.Substring(fileLine.IndexOf(' ') + 1);
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
            string fileLine = null;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim() == String.Empty)
                {
                    continue;
                }
                else if (fileLine[0] < 33)
                {
                    continue;
                }
                // If we have a receive list item collection, we're all set.  If send list item collection, may need return date
                if (il is ReceiveListItemCollection)
                {
                    il.Add(new ReceiveListItemDetails(fileLine, String.Empty));
                }
                else
                {
                    il.Add(new SendListItemDetails(fileLine, String.Empty, String.Empty, String.Empty));
                }
                // Add account number and location to array list if we have an account number
                if (accountName.Length != 0)
                {
                    s.Add(fileLine);
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
        /// <param name="sl">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="rl">
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection sl, out ReceiveListItemCollection rl, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Site booleans
            bool b1 = false;
            bool b2 = false;
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Move past the list headers
                MovePastListHeaders(r);
                // Destination site
                try
                {
                    b2 = SiteIsEnterprise(site2);
                }
                catch (ExternalSiteException)
                {
                    if (IgnoreUnknownSite)
                    {
                        site2 = String.Empty;
                    }
                    else
                    {
                        throw;
                    }
                }
                // Source site
                try
                {
                    b1 = SiteIsEnterprise(site1);
                }
                catch (ExternalSiteException)
                {
                    if (IgnoreUnknownSite)
                    {
                        site1 = String.Empty;
                    }
                    else
                    {
                        throw;
                    }
                }
                // Autoresolution?
                if (site1.Length != 0 || site2.Length != 0)
                {
                    if (site1 == String.Empty)
                    {
                        b1 = !b2;
                    }
                    else if (site2 == String.Empty)
                    {
                        b2 = !b1;
                    }
                    // Send or receive?
                    if (b1 == true)
                    {
                        IList li = (IList)sl;
                        ReadListItems(r, String.Empty, ref li, ref s, ref a, ref l);
                    }
                    else
                    {
                        IList li = (IList)rl;
                        ReadListItems(r, String.Empty, ref li, ref s, ref a, ref l);
                    }
                }
            }
        }
    }
}
