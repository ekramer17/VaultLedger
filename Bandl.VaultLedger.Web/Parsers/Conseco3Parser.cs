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
	/// Summary description for Conseco3Parser.
	/// </summary>
	public class Conseco3Parser : Parser, IParserObject
	{
        int pos1 = -1;
        int pos2 = -1;
        int pos3 = -1;
        int pos4 = -1;
        int len1 = -1;
        int len2 = -1;
        int len3 = -1;
        int len4 = -1;

        public Conseco3Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader sr)
        {
            string fileLine = null;

            while ((fileLine = sr.ReadLine()) != null)
            {
                // Make it uppercase
                fileLine = fileLine.ToUpper();
                // Check for headers
                if ((pos1 = fileLine.IndexOf("SERIAL")) != -1)
                {
                    len1 = fileLine.IndexOf("SLOT") - pos1;
                    // 
                    if ((pos2 = fileLine.IndexOf("MOVE")) != -1)
                    {
                        pos2 -= 1;   // offset
                        len2 = fileLine.IndexOf("POLICY") - pos2;
                        //
                        if ((pos3 = fileLine.IndexOf("LOCATION")) != -1)
                        {
                            len3 = fileLine.LastIndexOf("DATE") - pos3;
                            //
                            if ((pos4 = fileLine.LastIndexOf("LOCATION")) != -1)
                            {
                                len4 = fileLine.LastIndexOf("MOVE") - 1 - pos4;
                                //
                                return pos3 != pos4;
                            }
                        }
                    }
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
        private void ReadListItems(StreamReader r, ref SendListItemCollection si, ref ReceiveListItemCollection ri, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string fileLine = null;
            char[] c = new char[] {'/', '-'};
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().Length == 0)
                {
                    continue;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("TOTAL VOLUMES") == 0)
                {
                    break;
                }
                else
                {
                    bool b1 = false;
                    bool b2 = false;
                    string accountName = String.Empty;
                    string sn = fileLine.Substring(pos1,len1).Trim();
                    string nm = fileLine.Substring(pos2,len2).Trim();
                    string l1 = fileLine.Substring(pos3,len3).Trim();
                    string l2 = fileLine.Substring(pos4,len4).Trim();
                    // Resolve the source site
                    try
                    {
                        b1 = SiteIsEnterprise(l1);
                        accountName = GetAccountName(l1);
                    }
                    catch (ExternalSiteException)
                    {
                        l1 = String.Empty;
                        if (false == IgnoreUnknownSite) throw;
                    }
                    // Destination site
                    try
                    {
                        if (l2 == "*NONE") l2 = String.Empty;
                        if (l2 != String.Empty) b2 = SiteIsEnterprise(l2);
                    }
                    catch
                    {
                        l2 = String.Empty;
                        if (false == IgnoreUnknownSite) throw;
                    }
                    // If both are empty, ignore entry.  Otherwise, if one empty, set it to 
                    // opposite of other.  If both resolve to same, ignore entry.
                    if (l1.Length == 0 && l2.Length == 0)
                    {
                        b1 = b2;    // will be ignored, move directly to account dictation
                    }
                    else if (l1.Length == 0)
                    {
                        b1 = !b2;
                    }
                    else if (l2.Length == 0)
                    {
                        b2 = !b1;
                    }
                    // Create the list entry
                    if (b1 != b2)
                    {
                        if (b1 == false)
                        {
                            ri.Add(new ReceiveListItemDetails(sn, String.Empty));
                        }
                        else
                        {
                            // Get the return date
                            string rdate = String.Empty;
                            if (EmployReturnDate && nm.Trim().Length != 0)
                            {
                                string[] x = nm.Trim().Split(c);
                                int y = Int32.Parse(x[2]) < 80 ? Int32.Parse(x[2]) + 2000 : Int32.Parse(x[2]) + 1900;
                                rdate = String.Format("{0}-{1}-{2}", y, x[0].PadLeft(2,'0'), x[1].PadLeft(2,'0'));
                            }
                            // Add the item to the collection
                            si.Add(new SendListItemDetails(sn, rdate, String.Empty, String.Empty));
                        }
                    }
                    // Add account number and location to array list if we have an account number
                    if (accountName.Length != 0)
                    {
                        s.Add(sn);
                        a.Add(accountName);
                        l.Add(b1 == true ? Locations.Enterprise : Locations.Vault);
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
        public override void Parse(byte[] fileText, out SendListItemCollection sl, out ReceiveListItemCollection rl, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader r = new StreamReader(ms))
            {
                // Move past the list headers
                if (MovePastListHeaders(r))
                {
                    ReadListItems(r, ref sl, ref rl, ref s, ref a, ref l);
                }
            }
        }
    }
}
