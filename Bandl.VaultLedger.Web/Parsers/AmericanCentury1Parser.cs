using System;
using System.IO;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for AmericanCenturyParser.
	/// </summary>
	public class AmericanCentury1Parser : Parser, IParserObject
	{
        ListTypes listType;
        string accountName;

        public AmericanCentury1Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="r">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            string fileLine;
            // Reset the account name
            accountName = String.Empty;
            // Look for the next set of headers
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.ToUpper().IndexOf("AMERICAN CENTURY") != -1)
                {
                    int i = -1;
                    // Get the list type
                    listType = fileLine.ToUpper().IndexOf("TO RECALL") != -1 ? ListTypes.Send : ListTypes.Receive;
                    // Get the account number if present
                    if ((i = fileLine.ToUpper().IndexOf("ACCT:")) != -1)
                    {
                        accountName = fileLine.Substring(i + 5).Trim();
                    }
                    // Return true
                    return true;
                }
            }
            // No more headers
            return false;
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
        private void ReadListItems(StreamReader r, string accountName, ref IList il, ref ArrayList s, ref ArrayList a, ref ArrayList l)
        {
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // If line contains first header line, break
                if ((fileLine = fileLine.Trim()) == String.Empty)
                {
                    break;
                }
                // Eliminate double spaces
                while (fileLine.IndexOf("  ") != -1)
                {
                    fileLine = fileLine.Replace("  ", " ");
                }
                // Split the line into columns
                string[] columnValues = fileLine.Split(new char[] {' '});
                // Only if there is more than two columns, should the line be considered 
                // valid.  Also, the first column must be exactly two characters in length.
                if (columnValues.Length < 2 || columnValues[0].Length != 2)
                {
                    break;
                }
                else if (il is SendListItemCollection)
                {
                    il.Add(new SendListItemDetails(columnValues[1], String.Empty, String.Empty, String.Empty));
                }
                else
                {
                    il.Add(new ReceiveListItemDetails(columnValues[1], String.Empty));
                }
                // Add account number and location to array list if we have an account number
                if (accountName.Length != 0)
                {
                    a.Add(accountName);
                    s.Add(columnValues[1]);
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
        /// <param name="sli">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="rli">
        /// Receptacle for returned receive list item collection
        /// </param>
        /// <param name="s">
        /// Receptacle for returned serial numbers, whose accounts must be assigned to media directly
        /// </param>
        /// <param name="a">
        /// Receptacle for returned accounts, to which the serial numbers in s should be assigned
        /// </param>
        /// <param name="l">
        /// Receptacle for returned locations, where the serial numbers in s should be placed
        /// </param>
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            IList il = null;
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                while (MovePastListHeaders(r))
                {
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
}
