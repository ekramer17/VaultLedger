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
    /// Parses a Fox report
    /// </summary>
    public class ADP1Parser : Parser, IParserObject
    {
        public ADP1Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader sr, out string s, out string d)
        {
            bool b = false;
            string fileLine;
            // Set the source and destination to empty strings
            s = String.Empty;
            d = String.Empty;
            // Find the last header row
            while ((fileLine = sr.ReadLine()) != null)
            {
                // Uppercase the line
                fileLine = fileLine.ToUpper();
                // Check the line
                if (b == false && fileLine.IndexOf("OPERATION RESULTS") != -1)
                {
                    b = true;
                }
                else if (b == true && fileLine.IndexOf(" TO ") != -1)
                {
                    fileLine = fileLine.Substring(0, fileLine.LastIndexOf('-') - 1).Trim().Replace(" TO ", ":");
                    s = fileLine.Substring(0, fileLine.IndexOf(':'));
                    d = fileLine.Substring(fileLine.IndexOf(':') + 1);
                }
                else if (b == true && d.Length != 0 && fileLine.Replace("-",String.Empty).Trim().Length == 0)
                {
                    return true;
                }
            }
            // No more headers found
            return false;
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
        private void ReadListItems(StreamReader sr, ref IList il)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("SPECIFIED COMMAND") != -1)
                {
                    break;
                }
                else if (il != null)
                {
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(fileLine.Trim(),String.Empty));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(fileLine.Trim(),String.Empty,String.Empty,String.Empty));
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
            IList il = null;
            string s = String.Empty; // Source site
            string d = String.Empty; // Destination site
            bool r1 = false, r2 = false;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                if (MovePastListHeaders(r, out s, out d))
                {
                    // Resolve the destination
                    try
                    {
                        r1 = SiteIsEnterprise(d);
                    }
                    catch (ExternalSiteException)
                    {
                        if (IgnoreUnknownSite == true)
                            d = String.Empty;
                        else
                            throw;
                    }
                    // Resolve the source site
                    try
                    {
                        r2 = SiteIsEnterprise(s);
                    }
                    catch (ExternalSiteException)
                    {
                        if (IgnoreUnknownSite == true)
                            s = String.Empty;
                        else
                            throw;
                    }
                    // If only one site known, set it to opposite of other site
                    if (s.Length == 0 || d.Length == 0)
                    {
                        if (s.Length == 0)
                            r2 = !r1;
                        else if (d.Length == 0)
                            r1 = !r2;
                    }
                    // Determine list type
                    if (r1 == r2)
                    {
                        il = null;
                        ReadListItems(r, ref il);
                    }
                    else if (r1 == true) // destination is enterprise
                    {
                        il = receiveCollection;
                        ReadListItems(r, ref il);
                    }
                    else if (r2 == true)
                    {
                        il = sendCollection;
                        ReadListItems(r, ref il);
                    }
                }
            }
        }
    }
}
