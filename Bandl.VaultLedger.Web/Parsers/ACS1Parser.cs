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
    /// Parses a Veritas report
    /// </summary>
    public class ACS1Parser : Parser, IParserObject
    {
        public ACS1Parser() {}

        /// <summary>
        /// Get the source and desitnation sites
        /// </summary>
        private void GetSiteNames(StreamReader sr, out string source, out string destination)
        {
            string fileLine = sr.ReadLine();
            int pos1 = fileLine.IndexOf(':');
            int pos2 = fileLine.ToUpper().IndexOf(" TO "); 
            int pos3;

            source = fileLine.Substring(pos1 + 1, pos2 - (pos1 + 1)).Trim();
            destination = fileLine.Substring(pos2 + 4).Trim();
            if ((pos3 = destination.IndexOf(' ')) != -1)
                destination = destination.Substring(0, pos3).Trim();
            else if ((pos3 = destination.IndexOf('(')) != -1)
                destination = destination.Substring(0, pos3).Trim();
        }

        
        /// <summary>
        /// Reads the items on the report.  Stream reader should be positioned 
        /// before the first item of the list upon entry.
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        private void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim() != String.Empty)
                {
                    if (itemCollection is ReceiveListItemCollection)
                    {
                        itemCollection.Add(new ReceiveListItemDetails(fileLine.Trim(), String.Empty));
                    }
                    else
                    {
                        itemCollection.Add(new SendListItemDetails(fileLine.Trim(), String.Empty, String.Empty, String.Empty));
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
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            IList listCollection;
            string source;
            string destination;
            bool x, y, z;
            // Initialize
            x = y = z = false;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader sr = new StreamReader(ms))
            {
                GetSiteNames(sr, out source, out destination);
                // Resolve the source
                try
                {
                    x = SiteIsEnterprise(source);
                    z = true;
                }
                catch (ExternalSiteException)
                {
                    if (IgnoreUnknownSite == false)
                        throw;
                }
                // Resolve destination
                try
                {
                    y = SiteIsEnterprise(destination);
                    if (z == false) x = !y;
                }
                catch (ExternalSiteException)
                {
                    if (IgnoreUnknownSite == false)
                    {
                        throw;
                    }
                    else if (z == false) // Neither site could be resolved
                    {
                        throw new ApplicationException("Neither site on report could be resolved using external site maps");
                    }
                    else
                    {
                        y = !x;
                    }
                }
                // If sites resolve to same location, throw exception
                if (x == y)
                {
                    throw new ApplicationException("Source and destination site resolve to same location; no list produced");
                }
                else if (y == true)
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
