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
	/// Summary description for BCBS1.
	/// </summary>
	public class BCBS1Parser : Parser, IParserObject
	{
        int[] serialLen = {-1,-1,-1};   // Three volumes per line
        int[] serialPos = {-1,-1,-1};

        public BCBS1Parser() {}

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
                if (fileLine.ToUpper().IndexOf("VOLUMES TO BE MOVED FROM LOCATION") != -1)
                {
                    int x = fileLine.IndexOf("FROM LOCATION");
                    int y = fileLine.IndexOf("TO LOCATION");
                    source = fileLine.Substring(x + 14, y - (x + 14)).Trim();
                    destination = fileLine.Substring(y + 12).Trim();
                    // Source may contain PAGE.  If it does, trim it there.
                    if ((x = destination.IndexOf("PAGE")) != -1)
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
            string nextHeader;
            int[] nextPos = {-1,-1,-1};

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("OWNER") != -1 && fileLine.IndexOf("RACK") != -1 && fileLine.IndexOf("MEDIANAME") != -1)
                {
                    if (fileLine.IndexOf("BIN") > fileLine.IndexOf("RACK"))
                        nextHeader = "BIN";
                    else
                        nextHeader = "RACK";

                    serialPos[0] = fileLine.IndexOf("VOLUME");
                    serialPos[1] = fileLine.IndexOf("VOLUME", serialPos[0] + 1);
                    serialPos[2] = fileLine.IndexOf("VOLUME", serialPos[1] + 1);
                    nextPos[0] = fileLine.IndexOf(nextHeader);
                    nextPos[1] = fileLine.IndexOf(nextHeader, nextPos[0] + 1);
                    nextPos[2] = fileLine.IndexOf(nextHeader, nextPos[1] + 1);
                    serialLen[0] = nextPos[0] - serialPos[0];
                    serialLen[1] = nextPos[1] - serialPos[1];
                    serialLen[2] = nextPos[2] - serialPos[2];
                    // Skip line of hyphens
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
            string[] serialNo = {String.Empty, String.Empty, String.Empty};

            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If we've reached a blank line, exit
                if (fileLine.Trim() == String.Empty)
                {
                    break;
                }
                // If we have no list collection, then we're skipping the
                // content section; just move along
                if (itemCollection == null)
                {
                    continue;
                }
                // Get the serial numbers
                for (int i = 0; i < 3; i++)
                {
                    if (fileLine.Length < serialPos[i])
                    {
                        break;
                    }
                    else
                    {
                        if ((serialNo[i] = fileLine.Substring(serialPos[i], serialLen[i]).Trim()) != String.Empty)
                        {
                            // Construct an item of the correct type and fill it
                            if (itemCollection is ReceiveListItemCollection)
                            {
                                ReceiveListItemDetails newItem = new ReceiveListItemDetails(serialNo[i], String.Empty);
                                // Add the item to the collection
                                itemCollection.Add(newItem);
                            }
                            else
                            {
                                // Create a new send list item - no expiration dates on this report
                                SendListItemDetails newItem = new SendListItemDetails(serialNo[i], String.Empty, String.Empty, String.Empty);
                                // Add the item to the collection
                                itemCollection.Add(newItem);
                            }
                        }
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
