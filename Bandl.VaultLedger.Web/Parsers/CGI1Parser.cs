using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for CGIParser.
	/// </summary>
	public class CGI1Parser : VeritasParser, IParserObject
	{
        private int c1 = -1;  // column containing serial number (zero based)
        private int c2 = -1;  // column containing expiration date (zero based)
        private ArrayList h2 = new ArrayList();  // position of first character on each line of extra headers

        public CGI1Parser() {}

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
        protected override bool MovePastListHeaders(StreamReader sr, out ListTypes listType)
        {
            bool b1 = false;
            string fileLine = null;
            listType = ListTypes.Receive;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if ((fileLine = fileLine.ToUpper()).IndexOf("MEDIA") != -1 && (fileLine.IndexOf("IMAGES") != -1 || fileLine.IndexOf("REQUESTED") != -1))
                {
                    b1 = true;
                    fileLine = fileLine.Replace('\t', ' ');
                    // Get the column number for medium and (if possible) expiration
                    while (fileLine.IndexOf("  ") != -1) fileLine = fileLine.Replace("  ", " ");
                    string[] x = fileLine.Trim().Split(new char[] {' '});
                    // Run through the array, getting column numbers for serial number and expiration date
                    for (int i = 0; i < x.Length; i++)
                    {
                        if (x[i] == "MEDIA")
                        {
                            c1 = i;
                        }
                        else if (x[i] == "EXPIRATION")
                        {
                            c2 = i;
                        }
                    }
                    // If we have an expiration, it's a send list, else it's a receive list
                    if (c2 != -1)
                    {
                        listType = ListTypes.Send;
                    }
                    else
                    {
                        listType = ListTypes.Receive;
                    }
                }
                else if (b1 == true)
                {
                    if (fileLine.Trim().Length != 0)
                    {
                        this.h2.Add(fileLine.IndexOf(fileLine.Trim()[0]));
                    }
                    else
                    {
                        return true;
                    }
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
            string fileLine;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim() == String.Empty)
                {
                    continue;
                }
                else if (fileLine.ToUpper().IndexOf("CGI OFFSITE REPORT") != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("TOTALS") == 0)
                {
                    break;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("NUMBER OF") == 0 && fileLine.IndexOf(':') != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("IMAGE COUNT ON") == 0 && fileLine.IndexOf(':') != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().Trim().IndexOf("BYTES FOR THIS SESSION") != -1)
                {
                    break;
                }
                else
                {
                    bool b1 = true;
                    // Replace tabs with spaces
                    fileLine = fileLine.Replace('\t', ' ');
                    // Where is the first non-whitespace character?
                    int i1 = fileLine.IndexOf(fileLine.Trim()[0]);
                    // Is the line valid?
                    for (int c1 = 0; c1 < this.h2.Count; c1 += 1)
                    {
                        if (i1 == (int)this.h2[c1])
                        {
                            b1 = false;
                            break;
                        }
                    }
                    // Should we process the line?
                    if (b1 == false) continue;
                    // Eliminate all double spaces
                    while (fileLine.IndexOf("  ") != -1)
                    {
                        fileLine = fileLine.Replace("  ", " ");
                    }
                    // Split the line
                    string[] x1 = fileLine.Trim().Split(new char[] {' '});
                    // If we have a receive list item collection, we're all set.  If send list item collection, may need return date
                    if (li is ReceiveListItemCollection)
                    {
                        li.Add(new ReceiveListItemDetails(x1[c1], String.Empty));
                    }
                    else if (!this.EmployReturnDate || c2 == -1)
                    {
                        li.Add(new SendListItemDetails(x1[c1], String.Empty, String.Empty, String.Empty));
                    }
                    else
                    {
                        string r1 = DateTime.ParseExact(x1[c2], "MM/dd/yyyy", null).ToString("yyyy-MM-dd");
                        li.Add(new SendListItemDetails(x1[c1], r1, String.Empty, String.Empty));
                    }
                }
            }
        }

        /// <summary>
        /// Parses the given text array and returns send list items and receive list items
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
