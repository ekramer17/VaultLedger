using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for IronMountainParser.
	/// </summary>
	public class IronMountainParser : Parser, IParserObject
	{
        public IronMountainParser() {}

        /// <summary>
        /// Finds the next list site name
        /// </summary>
        /// <param name="sr">
        /// Stream reader attached to report file stream
        /// </param>
        /// <returns>
        /// True if site was found, else false
        /// </returns>
        private bool FindNextSite(StreamReader sr, out string siteName, out ReportType listType)
        {
            string fileLine;
            siteName = String.Empty;
            listType = ReportType.Picking;
            // Read down the file until we find a destination.
            while ((fileLine = sr.ReadLine()) != null)
            {
                if (fileLine.ToUpper().StartsWith("STARTHEADERTEXT"))
                {
                    // Pick or dist list?
                    if (fileLine.ToUpper().StartsWith("STARTHEADERTEXT~P"))
                    {
                        listType = ReportType.Picking;
                    }
                    else if (fileLine.ToUpper().StartsWith("STARTHEADERTEXT~D"))
                    {
                        listType = ReportType.Distribution;
                    }
                    else
                    {
                        continue;
                    }
                    // Get the site name
                    try
                    {
                        fileLine = fileLine.Substring(0,fileLine.LastIndexOf('~'));
                        siteName = fileLine.Substring(fileLine.LastIndexOf('~') + 1);
                    }
                    catch
                    {
                        throw new ParserException("Unable to read site from header line within report.");
                    }
                    // Return true
                    return true;
                }
            }
            // Return unsuccessful
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
        private void ReadListItems(StreamReader sr, ref IList itemCollection)
        {
            string fileLine;
            string serialNo;
            ArrayList fieldList;
            string returnDate = String.Empty;
            StringBuilder noteText = new StringBuilder();
            Regex  dateExp = new Regex("^(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])(19|20[0-9]{2})$"); // mmddyyyy
            // Read through the file, collecting items
            while ((fileLine = sr.ReadLine()) != null)
            {
                // If we've reached a footer line, then exit
                if (fileLine.ToUpper().IndexOf("STARTFOOTERTEXT~") == 0)
                {
                    break;
                }
                // Split the line
                fieldList = new ArrayList();
                foreach (string s in fileLine.Split(new char[] {' ','\t'}))
                    if (s.Length != 0) 
                        fieldList.Add(s);
                // Serial number is the first field
                serialNo = (string)fieldList[0];
                // Go from the back until we find the date
                for (int i = fieldList.Count - 1; i > -1; i--)
                {
                    if (((string)fieldList[i]).Length != 0)
                    {
                        if (dateExp.IsMatch((string)fieldList[i]) == false)
                        {
                            fieldList[i] = String.Empty;
                        }
                        else
                        {
                            // Get the date if send list collection
                            if (itemCollection is SendListItemCollection)
                                returnDate = DateTime.ParseExact((string)fieldList[i], "MMddyyyy", null).ToString("yyyy-MM-dd");
                            // Blank it out
                            fieldList[i] = String.Empty;
                            // Break the loop
                            break;
                        }
                    }
                }
                // Everything else from 3rd field on is the description
                if (this.DataSetNoteAction != "NO ACTION")
                {
                    noteText = new StringBuilder();
                    for (int i = 2; i < fieldList.Count; i++)
                        if (((string)fieldList[i]).Length != 0)
                            noteText.AppendFormat("{0}{1}", noteText.Length != 0 ? " " : String.Empty, (string)fieldList[i]);
                }
                // Create the list item
                if (itemCollection is ReceiveListItemCollection)
                {
                    ReceiveListItemDetails newItem = new ReceiveListItemDetails(serialNo, noteText.ToString());
                    itemCollection.Add(newItem);
                }
                else
                {
                    SendListItemDetails newItem = new SendListItemDetails(serialNo, returnDate, noteText.ToString(), String.Empty);
                    itemCollection.Add(newItem);
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
            bool siteLocal = false;
            bool createReceive = false;
            string siteName = String.Empty;
            ReportType listType = ReportType.Picking;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the stream
                while (FindNextSite(sr, out siteName, out listType))
                {
                    // Destination site
                    try
                    {
                        siteLocal = SiteIsEnterprise(siteName);
                    }
                    catch (ExternalSiteException)
                    {
                        if (this.IgnoreUnknownSite == true)
                            continue;
                        else
                            throw;
                    }
                    // Determine send or receive list
                    switch (listType)
                    {
                        case ReportType.Picking:
                            createReceive = !siteLocal;
                            break;
                        case ReportType.Distribution:
                            createReceive = siteLocal;
                            break;
                    }
                    // Read the list items
                    if (createReceive == true)
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
