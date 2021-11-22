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
	/// Summary description for CGI2Parser.
	/// </summary>
	public class CGI2Parser : Parser, IParserObject
	{
        public CGI2Parser() {}

        private void ReadTopLine(StreamReader r, out string accountNo, out ListTypes listType)
        {
            // Get the header line, just after the account number and trim the DATE: field off as well
            string fileLine = r.ReadLine().ToUpper();
            fileLine = fileLine.Substring(fileLine.IndexOf('#') + 1);
            fileLine = fileLine.Substring(0, fileLine.LastIndexOf("DATE:")).Trim();
            // Get the list type
            listType = fileLine[fileLine.Length-1] != 'R' ? ListTypes.Send : ListTypes.Receive;
            // Get the account number
            accountNo = fileLine.Substring(0, fileLine.IndexOf(' '));
        }

        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="r">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="il">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadListItems(StreamReader r, string accountName, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string fileLine = null;
            string serialNo = null;
            string dataText = String.Empty;

            while ((fileLine = r.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length != 0)
                {
                    // Replace dousble spaces with single
                    while (fileLine.IndexOf("  ") != -1)
                    {
                        fileLine = fileLine.Replace("  ", " ");
                    }
                    // Split into columns
                    string[] x = fileLine.Split(new char[] {' '});
                    // Third column contains serial number, fourth contains data text
                    serialNo = x[2];
                    dataText = DataSetNoteAction != "NO ACTION" ? x[3] : String.Empty;
                    // Construct an item of the correct type and fill it
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(serialNo, dataText));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(serialNo, String.Empty, dataText, String.Empty));
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
            // Account name and list type
            string accountName = String.Empty;
            ListTypes listType = ListTypes.Send;
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Read the top line
                ReadTopLine(r, out accountName, out listType);
                // Read the list items
                if (listType == ListTypes.Send)
                {
                    il = (IList)sli;
                    ReadListItems(r, accountName, ref il, ref s, ref a, ref l);
                }
                else
                {
                    il = (IList)rli;
                    ReadListItems(r, accountName, ref il, ref s, ref a, ref l);
                }
            }
        }
    }
}
