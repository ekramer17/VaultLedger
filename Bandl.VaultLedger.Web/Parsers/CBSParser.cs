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
	/// Summary description for CBSParser.
	/// </summary>
	public class CBSParser : Parser, IParserObject
	{
        public CBSParser() {}
	
        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader sr)
        {
            bool b = false;
            string fileLine;

            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.Trim().ToUpper().StartsWith("VOLUME NAME"))
                {
                    b = true;
                }
                else if (b == true && fileLine.Replace('-', ' ').Trim() == String.Empty)
                {
                    return true;
                }
            }
            // No more headers found
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
        private void ReadListItems(StreamReader sr, ref IList il)
        {
            string fileLine = null;
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                if ((fileLine = fileLine.Trim()).Length == 0)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("RETURN CODE WAS") != -1)
                {
                    break;
                }
                else
                {
                    il.Add(new ReceiveListItemDetails(fileLine.Substring(0,fileLine.IndexOf(' ')), String.Empty));
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
        public override void Parse(byte[] fileText, out SendListItemCollection sl, out ReceiveListItemCollection rl)
        {
            IList il;
            // Create the new collections
            sl = new SendListItemCollection();
            rl = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // CBS lists are always receive lists
            using (StreamReader r = new StreamReader(ms))
            {
                if (MovePastListHeaders(r))
                {
                    il = (IList)rl;
                    ReadListItems(r, ref il);
                }
            }
        }
    }
}
