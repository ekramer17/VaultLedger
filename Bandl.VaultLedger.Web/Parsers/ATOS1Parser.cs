using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
//using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
//using System.Text.RegularExpressions;
using System.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    public class ATOS1Parser : Parser, IParserObject
    {
        private ListTypes listType;
        private String accountName = String.Empty;

        public ATOS1Parser() { this.listType = ListTypes.Send; }

        /// Moves the position of the streamreader past the list headers, to just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r1)
        {
            r1.ReadLine();  // Skip first line
            // Second line holds list type
            var s = r1.ReadLine().ToUpper();

            if (s.IndexOf("VAULTING LIST") != -1)
                listType = ListTypes.Send;
            else if (s.IndexOf("RECALL LIST") != -1)
                listType = ListTypes.Receive;
            else
                throw new ApplicationException("Unable to determine list type");

            // Third line -- if send list, get account from site maps
            s = r1.ReadLine().ToUpper();
            if (listType == ListTypes.Send)
            {
                int i = s.ToUpper().IndexOf(" VAULTING LIST");
                accountName = GetAccountName(s.Substring(0, i).Trim());
                if (String.IsNullOrWhiteSpace(accountName))
                    throw new ApplicationException("No site map found with which to determine account assignment");
            }

            // Return
            return true;
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
        private void ReadListItems(StreamReader r, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string line;
//            var formats = PatternDefaultMediumFactory.Create().GetPatternDefaults();
            // Read through the file, collecting items
            while ((line = r.ReadLine()) != null)
            {
                if ((line = line.Trim()) == String.Empty)
                {
                    continue;
                }

                // Remove double spaces
                while (line.IndexOf("  ") != -1)
                    line = line.Replace("  ", " ");

                // Split
                var fields = line.Split(new char[] { ' ' });

                // Get the serial number
                var serial = fields[0];

                // Get the item
                if (il is ReceiveListItemCollection)
                {

//                    string account_name = "";
                    il.Add(new ReceiveListItemDetails(serial, ""));

                    //foreach (PatternDefaultMediumDetails f in formats)
                    //{

                    //    if (Regex.IsMatch(serial, f.Pattern))
                    //    {
                    //        account_name = f.Account;
                    //        break;
                    //    }
                    //}

                    //if (account_name == "")
                    //    throw new ApplicationException("No default bar code pattern could be found for medium: " + serial);

                    s.Add(serial);
                    a.Add(String.Empty);
                    l.Add(Locations.Vault);

                }
                else 
                {
                    if (!this.EmployReturnDate)
                        il.Add(new SendListItemDetails(serial, "", "", ""));
                    else
                        il.Add(new SendListItemDetails(serial, DateTime.ParseExact(fields[1], "MM/dd/yyyy", null).ToString("yyyy-MM-dd"), "", ""));

                    if (this.accountName.Length != 0)
                    {
                        s.Add(serial);
                        a.Add(this.accountName);
                        l.Add(Locations.Enterprise);
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
        public override void Parse(byte[] t1, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s1, out ArrayList a1, out ArrayList l1)
        {
            IList x1 = null;
            s1 = new ArrayList();
            a1 = new ArrayList();
            l1 = new ArrayList();
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Read through the file, collecting items
            using (StreamReader r1 = new StreamReader(new MemoryStream(t1)))
            {
                MovePastListHeaders(r1);

                if (this.listType == ListTypes.Receive)
                {
                    x1 = (IList)rli;
                    ReadListItems(r1, ref x1, ref s1, ref a1, ref l1);
                }
                else if (this.listType == ListTypes.Send)
                {
                    x1 = (IList)sli;
                    ReadListItems(r1, ref x1, ref s1, ref a1, ref l1);
                }

            }
        }
    }
}
