using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.IParser;
using System.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a standard Recall report.  We defined the standard.
    /// </summary>
    public class BMCParser : Parser, IParserObject
    {
        int serialPos = -1;
        int sourceLen = -1;

        public BMCParser() {}

        /// <summary>
        /// Finds the next list source and destinations site mentioned in the report.
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if destination was found, else false
        /// </returns>
        private bool FindNextDestination(StreamReader sr, out string destination)
        {
            string fileLine;
            destination = String.Empty;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("FROM LOCATION:") != -1)
                {
                    destination = fileLine.Substring(fileLine.IndexOf(':') + 1).Trim();
                    // Retun true;
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

                if (fileLine.IndexOf("TO ") != -1 && fileLine.IndexOf("VOLSER") != -1)
                {
                    serialPos = fileLine.IndexOf("VOLSER");
                    sourceLen = serialPos;
                    // Skip the next two lines
                    sr.ReadLine();
                    sr.ReadLine();
                    // Exit loop
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
            string sourceSite;

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If we've reached a blank line, exit
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine[0] == '1')
                {
                    break;
                }
                // If we have no list collection, then we're skipping the
                // content section; just move along
                if (itemCollection == null)
                {
                    continue;
                }
                // Get the serial number and the source site
                serialNo = fileLine.Substring(serialPos).Trim();
                sourceSite = fileLine.Substring(0, sourceLen).Trim();
                // Determine whether the destination is vault or enterprise
                bool sourceVault = false;
                bool destinationVault = itemCollection is SendListItemCollection;
                // Resolve the source site
                try
                {
                    sourceVault = !SiteIsEnterprise(sourceSite);
                }
                catch (ExternalSiteException)
                {
                    if (this.IgnoreUnknownSite == false)
                    {
                        throw;
                    }
                    else
                    {
                        sourceVault = destinationVault;
                    }
                }
                // If the source is different than the destination, add the item
                // to the collection.
                if (sourceVault != destinationVault)
                {
                    if (itemCollection is ReceiveListItemCollection)
                    {
                        ReceiveListItemDetails newItem = new ReceiveListItemDetails(serialNo, String.Empty);
                        itemCollection.Add(newItem);
                    }
                    else
                    {
                        SendListItemDetails newItem = new SendListItemDetails(serialNo, String.Empty, String.Empty, String.Empty);
                        itemCollection.Add(newItem);
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
            int destinationVault;
            string fileLine = String.Empty;
            string destination = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while (FindNextDestination(sr, out destination))
                {
                    try
                    {
                        destinationVault = !SiteIsEnterprise(destination) ? 1 : 0;
                    }
                    catch (ExternalSiteException)
                    {
                        if (this.IgnoreUnknownSite == false)
                        {
                            throw;
                        }
                        else
                        {
                            destinationVault = -1;
                        }
                    }
                    // Move past the list headers
                    MovePastListHeaders(sr);
                    // If source and destination locations are different, then
                    // create the list type as indicated.  Otherwise, ignore the
                    // list items.
                    switch (destinationVault)
                    {
                        case -1:
                            listCollection = null;
                            ReadListItems(sr, ref listCollection);
                            break;
                        case  0:
                            listCollection = (IList)receiveCollection;
                            ReadListItems(sr, ref listCollection);
                            break;
                        case  1:
                            listCollection = (IList)sendCollection;
                            ReadListItems(sr, ref listCollection);
                            break;
                    }
                }
            }
        }
    }
}
