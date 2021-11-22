using System;
using System.IO;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.IParser;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ACS2.
    /// </summary>
    public class IBM1Parser : Parser, IParserObject
    {
        string fileLine;
        ListTypes listType;
        string accountName = String.Empty;

        public IBM1Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim().ToUpper().StartsWith("BELL "))
                {
                    if (fileLine.Trim().ToUpper().EndsWith(" INCOMING"))
                    {
                        accountName = fileLine.ToUpper().Replace("BELL ", String.Empty).Replace(" INCOMING", String.Empty).Trim();
                        listType = ListTypes.Receive;
                        return true;
                    }
                    else if (fileLine.Trim().ToUpper().EndsWith(" OUTGOING"))
                    {
                        accountName = fileLine.ToUpper().Replace("BELL ", String.Empty).Replace(" OUTGOING", String.Empty).Trim();
                        listType = ListTypes.Send;
                        return true;
                    }
                }
            }
            // return false
            return false;
        }
        
        /// <summary>
        /// Reads the items of the report
        /// </summary>
        /// <param name="sr">
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
            UTF8Encoding encoder = new UTF8Encoding();
            // Read through the file, collecting items
            while ((fileLine = r.ReadLine()) != null)
            {
                // If we've reached a blank line then break
                if (fileLine.Trim() == String.Empty)
                {
                    break;
                }
                else if (encoder.GetBytes(fileLine.Trim())[0] < 32)
                {
                    continue;
                }
                else
                {
                    string itemNote = String.Empty;
                    // Replace all the double spaces with single spaces
                    while (fileLine.IndexOf("  ") != -1)
                    {
                        fileLine = fileLine.Replace("  ", " ");
                    }
                    // Split on the single spaces
                    string[] fields = fileLine.Split(new char[] {' '});
                    // First field is the serial number, last is the note
                    string serialNo = fields[0];
                    // Data set as note, if necessary
                    if (this.DataSetNoteAction != "NO ACTION" && fields.Length > 1)
                    {
                        itemNote = fields[fields.Length - 1];
                    }
                    // Construct an item of the correct type and fill it
                    if (il is ReceiveListItemCollection)
                    {
                        il.Add(new ReceiveListItemDetails(serialNo, itemNote));
                    }
                    else
                    {
                        il.Add(new SendListItemDetails(serialNo, String.Empty, itemNote, String.Empty));
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
            // Create the new collections
            sli = new SendListItemCollection();
            rli = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader r = new StreamReader(ms))
            {
                if (MovePastListHeaders(r) == false)
                {
                    throw new ApplicationException("Unable to determine list type.");
                }
                else
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
