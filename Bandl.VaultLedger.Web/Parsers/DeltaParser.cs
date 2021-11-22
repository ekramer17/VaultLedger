using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.IParser;
using System.Text.RegularExpressions;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a Delta Dental report
    /// </summary>
    public class DeltaParser : Parser, IParserObject
    {
        int[] y1 = new int[3] {-1, -1, -1};
        int[] y2 = new int[3] {-1, -1, -1};

        public DeltaParser() {}

        protected bool DoPick(byte[] x1)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(x1)))
            {
                return r1.ReadToEnd().IndexOf("DISTRIBUTION LIST FOR") == -1;
            }
        }

        /// <summary>
        /// Finds the next list in the CA25 report and returns the name of its site
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Site on success, empty string if no more lists found in report
        /// </returns>
        protected ReportType GetNextType(StreamReader r1)
        {
            String s1 = null;
            ReportType x1 = ReportType.Unknown;
            // Read down the file until we find a site
            while (x1 == ReportType.Unknown && (s1 = r1.ReadLine()) != null)
            {
                if (s1.IndexOf(" LIST FOR ") != -1)
                {
                    if (s1.IndexOf("TO BE RETURNED FROM VAULT") != -1)
                    {
                        x1 = ReportType.Picking;
                    }
                    else if (s1.IndexOf("TO BE SENT TO VAULT") != -1)
                    {
                        x1 = ReportType.Distribution;
                    }
                }
            }
            // Return
            return x1;
        }
        
        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(StreamReader r1)
        {
            String s1;
            // LOOP
            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.IndexOf("VOLUME") != -1 && s1.IndexOf("EXPIRATION") != -1 && s1.IndexOf("RECORDING") != -1)
                {
                    // EXPIRATION
                    y1[2] = s1.IndexOf("EXPIRATION");
                    y2[2] = s1.IndexOf("LBL") - y1[2];
                }
                else if (s1.IndexOf("SERIAL") != -1 && s1.IndexOf("DATA SET NAME") != -1)
                {
                    // SERIAL
                    y1[0] = 0;
                    y2[0] = s1.IndexOf("NUMBER");
                    // DATA SET
                    y1[1] = s1.IndexOf("DATA SET NAME");
                    y2[1] = s1.IndexOf("SEQ") - y1[1];
                    // DONE
                    break;
                }
            }
        }

        private void ReadListItems(StreamReader r1, ref IList x1)
        {
            String s1 = null;
            Regex m1 = new Regex("^[0-9]{1,2}/[0-9]{2}/[0-9]{4}$");
            // LOOP
            while ((s1 = r1.ReadLine()) != null)
            {
                if (s1.Trim().Length == 0)
                {
                    continue;
                }
                else if (s1.IndexOf("DELTANET INC") != -1 || s1.IndexOf("TOTAL TAPES TO BE") != -1)
                {
                    break;
                }
                else
                {
                    // Get fields
                    String b1 = s1.Substring(y1[0], y2[0]).Trim(); // serial
                    String b2 = (this.DataSetNoteAction != "NO ACTION" ? s1.Substring(y1[1], y2[1]).Trim() : String.Empty); // data set
                    String b3 = s1.Substring(y1[2], y2[2]).Trim();  // expiration
                    // Need expiration?
                    if (x1 is ReceiveListItemCollection)
                    {
                        x1.Add(new ReceiveListItemDetails(b1, b2));
                    }
                    else if (this.EmployReturnDate && m1.IsMatch(b3))
                    {
                        DateTime e1 = DateTime.ParseExact(b3, new String[] {"MM/dd/yyyy", "M/dd/yyyy"}, DateTimeFormatInfo.InvariantInfo, DateTimeStyles.AllowWhiteSpaces);
                        x1.Add(new SendListItemDetails(b1, e1.ToString("yyyy-MM-dd"), b2, String.Empty));
                    }
                    else
                    {
                        x1.Add(new SendListItemDetails(b1, String.Empty, b2, String.Empty));
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
        /// Receptacle for returned receive list item collection</param>
        public override void Parse(byte[] fileText, out SendListItemCollection c1, out ReceiveListItemCollection c2)
        {
            IList i1;
            ReportType t1;
            // Create the new collections
            c1 = new SendListItemCollection();
            c2 = new ReceiveListItemCollection();
            // See if we should ignore the picking lists
            bool doPick = this.DoPick(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                while ((t1 = GetNextType(r1)) != ReportType.Unknown)
                {
                    MovePastListHeaders(r1);
                    // Type?
                    if (t1 == ReportType.Distribution)
                    {
                        i1 = (IList)c1;
                    }
                    else
                    {
                        i1 = (IList)c2;
                    }
                    // Read
                    ReadListItems(r1, ref i1);
                }
            }
        }
    }
}
