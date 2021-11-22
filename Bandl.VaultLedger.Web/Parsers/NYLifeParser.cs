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
    /// Parses a NY Life report
    /// </summary>
    public class NYLifeParser : VeritasParser, IParserObject
    {
        public NYLifeParser() : base() {}

        /// <summary>
        /// Finds the next mention of a site in the report
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Destination site on success, empty string if no more found in report
        /// </returns>
        private string FindNextDestination(StreamReader sr)
        {
            string fileLine;
            int pos1, pos2;
            // Read down the file until we find a distribution list.  When
            // we find one, get the destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf(" LIST FOR ") != -1 && fileLine.ToUpper().IndexOf("RECALL") != -1)
                {
                    if ((pos1 = fileLine.ToUpper().IndexOf(" TO ")) != -1)
                    {
                        if ((pos2 = fileLine.IndexOf(':')) != -1)
                        {
                            return fileLine.Substring(pos1 + 4, pos2 - (pos1 + 4)).Trim();
                        }
                        else
                        {
                            return fileLine.Substring(pos1 + 4).Trim();
                        }
                    }
                }
            }
            // No more distribution lists found
            return String.Empty;
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
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            ListTypes listType;
            bool createReceive = false;
            string fileLine = String.Empty;
            string destination = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while ((destination = FindNextDestination(sr)) != String.Empty) 
                {
                    try
                    {
                        createReceive = SiteIsEnterprise(destination);
                    }
                    catch (ExternalSiteException)
                    {
                        if (!this.IgnoreUnknownSite)
                            throw;
                        else
                            destination = String.Empty;
                    }
                    // Read the list items
                    if (destination != String.Empty && MovePastListHeaders(sr, out listType))
                    {
                        // If the destination resolution does not match the list
                        // type, throw an exception.  Otherwise read the items off the list.
                        if (createReceive != (listType == ListTypes.Receive))
                        {
                            throw new ApplicationException("External site map does not match list type");
                        }
                        else if (listType == ListTypes.Receive)
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
