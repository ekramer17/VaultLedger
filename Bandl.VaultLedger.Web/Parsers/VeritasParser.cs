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
    /// Parses a Veritas report
    /// </summary>
    public class VeritasParser : Parser, IParserObject
    {
        protected int posDate;
        protected int posSerial;
        protected ArrayList monthNames;
        protected int colNo = 0;     // Zero-based

        public VeritasParser() 
        {
            posDate = -1;
            posSerial = -1;
            monthNames = new ArrayList(new string[] {"Apr","Aug","Dec","Feb","Jan","Jul","Jun","Mar","May","Nov","Oct","Sep"});
        }

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
        protected virtual bool MovePastListHeaders(StreamReader sr, out ListTypes listType)
        {
            string fileLine;
            posSerial = posDate = -1;
            listType = ListTypes.Receive;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if ((fileLine = fileLine.ToUpper()).IndexOf("MEDIA") != -1 && fileLine.IndexOf("SLOT") != -1)
                {
                    // Get the serial number start character position and field length
                    posSerial = fileLine.IndexOf("MEDIA"); // - 1;
                    if (fileLine[posSerial-1] != '\t') posSerial -= 1;
                    // Get the expiration date start character position and field length
                    posDate = fileLine.IndexOf("EXPIRATION") - 1;
                    listType = posDate > 0 ? ListTypes.Send : ListTypes.Receive;
                    // Get the column number of the volser
                    string x = fileLine.Replace('\t', ' ').Trim();
                    while (x.IndexOf("  ") != -1) x = x.Replace("  ", " ");
                    string[] y = x.Split(new char[] {' '});
                    for (colNo = 0; colNo < y.Length; colNo++)
                        if (y[colNo].IndexOf("MEDIA") != -1 )
                            break;
                    // Return true
                    return true;
                }
            }
            // No more data
            return false;
        }

        
        /// <summary>
        /// Reads the items on the report.  Stream reader should be positioned 
        /// before the first item of the list upon entry.
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        protected virtual void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            string fileLine, serialNo;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim() == String.Empty)
                {
                    continue;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("TOTAL") == 0)
                {
                    break;
                }
                else if (fileLine.IndexOf(':') != -1 && fileLine.IndexOf(':') == fileLine.LastIndexOf(':'))
                {
                    break;
                }
                else if (Convert.ToInt32(fileLine[0]) < 13 && fileLine[0] != '\t')
                {
                    break;
                }
                else if (monthNames.BinarySearch(fileLine.Substring(0,3)) > -1)
                {
                    break;
                }
                else if (itemCollection == null)
                {
                    continue;
                }
                else if (ColumnMatch(fileLine, colNo, serialNo = Trim(fileLine.Substring(posSerial).Trim())) == false)
                {
                    continue;
                }
                else if (PositionMatch(fileLine, serialNo) == false)
                {
                    continue;
                }
                // Construct an item of the correct type and fill it
                if (itemCollection is ReceiveListItemCollection)
                {
                    itemCollection.Add(new ReceiveListItemDetails(serialNo, String.Empty));
                }
                else if (!this.EmployReturnDate || posDate < 0)
                {
                    itemCollection.Add(new SendListItemDetails(serialNo, String.Empty, String.Empty, String.Empty));
                }
                else
                {
                    string mmddyyyy = Trim(fileLine.Substring(posDate).Trim());
                    string returnDate = DateTime.ParseExact(mmddyyyy, "MM/dd/yyyy", null).ToString("yyyy-MM-dd");
                    itemCollection.Add(new SendListItemDetails(serialNo, returnDate, String.Empty, String.Empty));
                }
            }
        }

        /// <summary>
        /// Verified that the contents of a column match the given val parameter.  If the serial number
        /// position is filled but by another column, it should not be logged (the serial is invalid).
        /// </summary>
        protected bool ColumnMatch(string line, int col, string val)
        {
            line = line.Replace('\t', ' ').Trim();
            while (line.IndexOf("  ") != -1) line = line.Replace("  ", " ");
            string[] x = line.Split(new char[] {' '});
            return colNo < x.Length && x[colNo] == val;
        }

        /// <summary>
        /// Serial number should start at serial position or one to either side
        /// </summary>
        protected bool PositionMatch(string fileLine, string serialNo)
        {
            if (fileLine.Substring(posSerial).StartsWith(serialNo))
            {
                return true;
            }
            else if (fileLine.Substring(posSerial + 1).StartsWith(serialNo))
            {
                return true;
            }
            else if (fileLine.Substring(posSerial - 1).StartsWith(serialNo))
            {
                return true;
            }
            else
            {
                return false;
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
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            ListTypes listType;
            IList listCollection;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items
            using (StreamReader sr = new StreamReader(ms))
            {
                while (MovePastListHeaders(sr, out listType))
                {
                    if (listType == ListTypes.Receive)
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
