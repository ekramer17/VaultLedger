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
    public class ExxonParser : VeritasParser, IParserObject
    {
        protected int c1 = -1;   // serial column
        protected int c2 = -1;   // expiration column
        //        protected int p1 = -1;   // serial position
        protected int e1 = -1;   // date position

        public ExxonParser() {}

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
            String s1;
            this.c1 = -1;
            this.c2 = -1;
            listType = ListTypes.Receive;

            while ((s1 = r.ReadLine()) != null)
            {
                s1 = s1.ToUpper().Trim();

                if (s1.IndexOf("MEDIA") != -1 && s1.IndexOf("SLOT") != -1)
                {
                    while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                    String[] x1 = s1.Split(new char[] {' '});
                    // Look for media and expiration columns
                    for (int i = 0; i < x1.Length; i += 1)
                    {
                        if (x1[i].StartsWith("MEDIA"))
                        {
                            this.c1 = i;
                        }
                        else if (x1[i].StartsWith("EXPIR"))
                        {
                            this.c2 = i;
                            listType = ListTypes.Send;
                        }
                        // Have both?
                        if (this.c1 != -1 && this.c2 != -1)
                        {
                            break;
                        }
                    }
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
        protected override void ReadListItems(StreamReader sr, ref IList li)
        {
            string s1;
            // Read through the file, collecting items
            while ((s1 = sr.ReadLine()) != null)
            {
                if ((s1 = s1.Trim()) == String.Empty)
                {
                    continue;
                }
                else if (s1.ToUpper().IndexOf("TOTALS") == 0)
                {
                    break;
                }
                else if (s1.ToUpper().IndexOf("PAGE:") != -1)
                {
                    break;
                }
                // Replace double spaces
                while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
                // Split the string
                String[] s2 = s1.Split(new char[] {' '});
                // If we have a receive list item collection, we're all set.  If send list item collection, may need return date
                if (li is ReceiveListItemCollection)
                {
                    li.Add(new ReceiveListItemDetails(s2[this.c1], String.Empty));
                }
                else if (this.EmployReturnDate == false)
                {
                    li.Add(new SendListItemDetails(s2[this.c1], String.Empty, String.Empty, String.Empty));
                }
                else
                {

                    String r = DateTime.ParseExact(s2[this.c2], "MM/dd/yyyy", null).ToString("yyyy-MM-dd");
                    li.Add(new SendListItemDetails(s2[this.c1], r, String.Empty, String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            ListTypes listType;
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
                        IList li = (IList)receiveCollection;
                        ReadListItems(sr, ref li);
                    }
                    else
                    {
                        IList li = (IList)sendCollection;
                        ReadListItems(sr, ref li);
                    }
                }
            }
        }
    }
}
