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
    public class CanadaDefenseParser : Parser, IParserObject
    {
        string fileLine = null;

        public CanadaDefenseParser() {}

        private void MovePastHeaders(StreamReader r, out ListTypes listType)
        {
            // Get the list type
            if (r.ReadLine().ToUpper().IndexOf("R E T R I E V E") != -1)
            {
                listType = ListTypes.Receive;
            }
            else
            {
                listType = ListTypes.Send;
            }
            // Move past the headers
            while (null != (fileLine = r.ReadLine()))
            {
                if (0 == fileLine.Replace("=", "").Trim().Length)
                {
                    break;
                }
            }
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
        private void ReadListItems(StreamReader r, String accountName, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string serialNo = null;
            string accountNo = null;

            while ((fileLine = r.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length > 10)
                {
                    // Split into columns
                    string[] x = fileLine.Split(new char[] {' '});
                    // Serial number in third column, account number in first
                    serialNo = x[2];
                    accountNo = x[0];
                    // Construct an item of the correct type and fill it
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(serialNo, String.Empty));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(serialNo, String.Empty, String.Empty, String.Empty));
                    }
                    // Add account number and location to array list if we have an account number
                    s.Add(serialNo);
                    a.Add(accountName.Length != 0 ? accountName : accountNo);
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
                // Get the list type
                MovePastHeaders(r, out listType);
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
