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
    /// Parses a Viacom report
    /// </summary>
    public class ViacomParser : Parser, IParserObject
    {
        public ViacomParser() {}

        /// <summary>
        /// Finds the next listed site
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if site was found, else false
        /// </returns>
        private bool FindNextSite(StreamReader sr, out string siteName)
        {
            string fileLine;
            siteName = String.Empty;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.IndexOf("Account:") != -1)
                {
                    siteName = fileLine.Substring(fileLine.IndexOf(':') + 1).Trim();
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
                if (fileLine.ToUpper().IndexOf("RETURN DATE:") != -1)
                {
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
        private void ReadListItems(StreamReader sr, ref ReceiveListItemCollection itemCollection)
        {
            string fileLine;
            string serialNo;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If line contains first header line, break
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine.Substring(0,10).IndexOf(":") != -1)
                {
                    break;
                }
                else if (fileLine.IndexOf(' ') == -1)
                {
                    break;
                }
                else
                {
                    serialNo = fileLine.Substring(0, fileLine.IndexOf(' ')).Trim();
                    itemCollection.Add(new ReceiveListItemDetails(serialNo, String.Empty));
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
            string siteName = null;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while (FindNextSite(sr, out siteName))
                {
                    if (!this.IsAccount(siteName))
                    {
                        throw new ParserException("'" + siteName + "' is not an account name.");
                    }
                    else
                    {
                        MovePastListHeaders(sr);
                        // All reports from Viacom are to be receiving lists
                        ReadListItems(sr, ref receiveCollection);
                    }
                }
            }
        }
    }
}
