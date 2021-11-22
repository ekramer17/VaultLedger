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
	/// Summary description for Conseco4Parser.
	/// </summary>
	public class Conseco4Parser : VeritasParser, IParserObject
	{
        protected int p1 = -1;   // serial position
        protected int p2 = -1;   // date position
        private string siteName = String.Empty;
        
        public Conseco4Parser() {}

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
        protected override bool MovePastListHeaders(StreamReader r, out ListTypes listType)
        {
            string fileLine;
            listType = ListTypes.Receive;

            while ((fileLine = r.ReadLine()) != null)
            {
                // Get a reference to an upper case of the file line
                fileLine = fileLine.ToUpper();
                // Get the site name and the list type
                if (fileLine.IndexOf("ROBOT:") != -1 && fileLine.IndexOf("PROFILE:") != -1)
                {
                    siteName = fileLine.Substring(fileLine.LastIndexOf(':') + 1).Trim();
                }
                else if (fileLine.IndexOf("SLOTID") != -1 && fileLine.IndexOf("CATEGORY") != -1)
                {
                    // Get the serial number
                    p1 = fileLine.IndexOf("MEDIA");
                    // Get the expiration date if it is present
                    p2 = fileLine.IndexOf("EXPIRATION");
                    // If we have an expiration, it's a send list, else it's a receive list
                    listType = p2 != -1 ? ListTypes.Send : ListTypes.Receive;
                    // Return true
                    return true;
                }
            }
            // No more data
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
        private void ReadListItems(StreamReader r, string accountName, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string fileLine, serialNo;
            string dateString = String.Empty;
            Regex dateMatch = new Regex("^[01][0-9]/[0123][0-9]/2[0-9]{3}$");
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim() == String.Empty)
                {
                    continue;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("TOTALS") == 0)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("CONSECO VAULT REPORTS") != -1)
                {
                    break;
                }
                // Get the serial number
                serialNo = Trim(fileLine.Substring(p1));
                // If we have a receive list item collection, we're all set.  If send list item collection, may need return date
                if (il is ReceiveListItemCollection)
                {
                    il.Add(new ReceiveListItemDetails(serialNo, String.Empty));
                }
                else if (!this.EmployReturnDate)
                {
                    il.Add(new SendListItemDetails(serialNo, String.Empty, String.Empty, String.Empty));
                }
                else
                {

                    string d = DateTime.ParseExact(Trim(fileLine.Substring(p2)), "MM/dd/yyyy", null).ToString("yyyy-MM-dd");
                    il.Add(new SendListItemDetails(serialNo, d, String.Empty, String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sl, out ReceiveListItemCollection rl, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            ListTypes listType;
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Reset the account name
                string accountName = String.Empty;
                // Move past the list headers (site name is obtained within)
                while (MovePastListHeaders(r, out listType))
                {
                    // Get the account name
                    accountName = GetAccountName(siteName);
                    // Parse the list
                    if (listType == ListTypes.Receive)
                    {
                        IList li = (IList)rl;
                        ReadListItems(r, accountName, ref li, ref s, ref a, ref l);
                    }
                    else
                    {
                        IList li = (IList)sl;
                        ReadListItems(r, accountName, ref li, ref s, ref a, ref l);
                    }
                }
            }
        }
    }
}
