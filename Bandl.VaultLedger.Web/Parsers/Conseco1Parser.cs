using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for ConsecoParser.
	/// </summary>
	public class Conseco1Parser : Parser, IParserObject
	{
        int sCol = -1;
        int i = -1;

        public Conseco1Parser() {}

        /// <summary>
        /// Gets the source site
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// Name of the source site
        /// </returns>
        private string GetSource(string[] fileLines)
        {
            for (i += 1; i < fileLines.Length; i++)
            {
                if (fileLines[i].ToUpper().IndexOf("FROM LOCATION") != -1)
                {
                    if (fileLines[i].ToUpper().IndexOf("TO LOCATION") != -1)
                    {
                        return fileLines[i].Substring(fileLines[i].IndexOf(':') + 1, fileLines[i].ToUpper().IndexOf("TO LOCATION") - fileLines[i].IndexOf(':') - 1).Trim();
                    }
                    else
                    {
                        return fileLines[i].Substring(fileLines[i].IndexOf(':') + 1).Trim();
                    }
                }
            }
            // Source not found
            return String.Empty;
        }

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="sr">
        /// Stream reader reading the report file
        /// </param>
        private void MovePastListHeaders(string[] fileLines)
        {
            int x = 0;

            for (i += 1; i < fileLines.Length; i++)
            {
                // Look for headers.  When found, get the column number of the volume
                if ((fileLines[i] = fileLines[i].ToUpper()).IndexOf("VOLUME") != -1)
                {
                    if (fileLines[i].IndexOf("FROM CTN") != -1 && fileLines[i].IndexOf("TO CTN") != -1)
                    {
                        // Eliminate the space in the headers with spaces so that we can split the line into fields
                        fileLines[i] = fileLines[i].Replace("TO CTN", "TOCTN").Replace("FROM CTN", "FROMCTN");
                        // Split the line
                        string[] c = fileLines[i].Trim().Split(new char[] {' ', '\t'});
                        // Count to the volume column
                        for (int j = 0; j < c.Length; j++)
                        {
                            if (c[j].Length != 0)
                            {
                                if (c[j] != "VOLUME")
                                {
                                    x += 1;
                                }
                                else
                                {
                                    sCol = x;
                                    break;
                                }
                            }
                        }
                        // Move to the last blank line
                        while (fileLines[i+1].Trim() == String.Empty) i += 1;
                        // Headers found
                        break;
                    }
                }
            }
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
        private void ReadListItems(string[] fileLines, ref IList itemCollection)
        {
            for (i += 1; i < fileLines.Length; i++)
            {
                // Reset the column count
                int c = 0;
                // Break on blank line or "TOTAL:"
                if ((fileLines[i] = fileLines[i].Trim()).Length == 0) 
                {
                    break;
                }
                else if (fileLines[i].Trim().ToUpper().Substring(0,6) == "TOTAL:")
                {
                    break;
                }
                // Split the line
                string[] fields = fileLines[i].Split(new char[] {' ', '\t'});
                // Run through the fields and get the serial number
                for (int j = 0; j < fields.Length; j++)
                {
                    if (fields[j].Length != 0)
                    {
                        if (c != sCol)
                        {
                            c += 1;
                        }
                        else if (itemCollection is ReceiveListItemCollection)
                        {
                            itemCollection.Add(new ReceiveListItemDetails(fields[j], String.Empty));
                            break;
                        }
                        else if (itemCollection is SendListItemCollection)
                        {
                            itemCollection.Add(new SendListItemDetails(fields[j], String.Empty, String.Empty, String.Empty));
                            break;
                        }
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
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            IList listCollection;
            // Create the new collections
            sendCollection = new SendListItemCollection();
            receiveCollection = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the file, collecting items.  If the destination
            // site resolves to the enterprise, then the item will be a receive
            // list item.  If the destination resolves to the vault, then the
            // item will be a send list item.
            bool doSend;
            string sourceName = null;
            string[] fileLines = null;
            // Read the file into its lines
            using (StreamReader sr = new StreamReader(ms))
                fileLines = sr.ReadToEnd().Split(new char[] {'\n'});

            while ((sourceName = GetSource(fileLines)).Length != 0)
            {
                doSend = SiteIsEnterprise(sourceName);
                // Move past the list headers
                MovePastListHeaders(fileLines);
                // Read the list items
                if (doSend == false)
                {
                    listCollection = (IList)receiveCollection;
                    ReadListItems(fileLines, ref listCollection);
                }
                else
                {
                    listCollection = (IList)sendCollection;
                    ReadListItems(fileLines, ref listCollection);
                }
            }
        }
	}
}
