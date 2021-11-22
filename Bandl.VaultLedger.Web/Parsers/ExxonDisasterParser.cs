using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for ExxonDisasterParser.
    /// </summary>
    public class ExxonDisasterParser : Parser, IParserObject
    {
        int reportType = 1;
        int startHere = -1;
        int endHere = -1;

        public ExxonDisasterParser() {}

        private bool MovePastListHeaders(StreamReader r)
        {
            string fileLine;
            // Read past the headers
            while((fileLine = r.ReadLine()) != null) 
            {
                if (fileLine.ToUpper().IndexOf("EXXONMOBIL") != -1)
                {
                    if (r.ReadLine().ToUpper().Trim().EndsWith("DR LIST"))
                    {
                        reportType = 1;
                        return true;
                    }
                }
                else if (fileLine.ToUpper().IndexOf("D A T A S E T") != -1)
                {
                    while ((fileLine = r.ReadLine()) != null)
                    {
                        if (fileLine.IndexOf('-') != -1 && fileLine.Replace('-', ' ').Trim() == String.Empty)
                        {
                            reportType = 2;
                            startHere = fileLine.IndexOf('-');
                            endHere = fileLine.IndexOf(' ', startHere);
                            return true;
                        }
                    }
                    // Break the outer loop
                    break;
                }
            }
            // No headers found
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
        private void ReadListItems(StreamReader r, ref DisasterCodeListItemCollection c)
        {
            string fileLine;

            while ((fileLine = r.ReadLine()) != null)
            {
                if (fileLine.Trim() == String.Empty)
                {
                    break;
                }
                else if (reportType == 1)
                {
                    if (fileLine.Trim().Length != 0)
                    {
                        string[] fields = fileLine.Trim().Split(new char[] {' ','\t'});
                        c.Add(new DisasterCodeListItemDetails(fields[0], String.Empty, String.Empty));
                    }
                }
                else if (reportType == 2)
                {
                    if (fileLine[startHere] == ' ')
                    {
                        break;
                    }
                    else if (fileLine.ToUpper().Trim().StartsWith("TOTAL OF"))
                    {
                        break;
                    }
                    else
                    {
                        c.Add(new DisasterCodeListItemDetails(fileLine.Substring(startHere, endHere - startHere), String.Empty, String.Empty));
                    }
                }
            }
        }
        /// <summary>
        /// Parses the given text array and returns a collection of 
        /// DisasterCodeListItemDetails objects.  Use this overload when
        /// creating a new disaster code list from a stream.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="listItems">
        /// Receptacle for returned disaster code list items
        /// </param>
        public override void Parse(byte[] fileText, out DisasterCodeListItemCollection li)
        {
            // Create a new disaster code list collection
            li = new DisasterCodeListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                while(MovePastListHeaders(r))
                {
                    ReadListItems(r, ref li);
                }
            }
        }
    }
}
