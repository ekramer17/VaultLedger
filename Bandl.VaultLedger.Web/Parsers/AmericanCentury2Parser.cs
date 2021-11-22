using System;
using System.IO;
using System.Collections;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for AmericanCenturyParser.
    /// </summary>
    public class AmericanCentury2Parser : Parser, IParserObject
    {
        int e1 = -1;    // position of expiration date
		int s1 = -1;    // position of serial number
		int d1 = -1;    // position of data set note
		string fileLine = null;
        string sourceSite = null;
        string targetSite = null;

        public AmericanCentury2Parser() {}

        /// <summary>
        /// Moves the position of the streamreader past the list headers, to
        /// just before the line containing the first item of the list.
        /// </summary>
        /// <param name="r">
        /// Stream reader reading the report file
        /// </param>
        private bool MovePastListHeaders(StreamReader r)
        {
            int p1 = 0;
            // Look for the next set of headers
            while ((fileLine = r.ReadLine()) != null)
            {
				if ((p1 = fileLine.ToUpper().IndexOf("FROM LOCATION")) != -1)
				{
					int p2 = fileLine.ToUpper().IndexOf("TO LOCATION");
					int p3 = fileLine.ToUpper().LastIndexOf("DATE");
					// Get the source and destination sites
					if (p2 > p1)
					{
						sourceSite = fileLine.Substring(p1 + 13, p2 - p1 - 13).Trim();
						targetSite = fileLine.Substring(p2 + 11, p3 - p2 - 11).Trim();
					}
					else
					{
						sourceSite = fileLine.Substring(p1 + 13, p3 - p1 - 13).Trim();
						targetSite = fileLine.Substring(p2 + 11, p1 - p2 - 11).Trim();
					}
				}
				else if (fileLine.ToUpper().IndexOf("EXPIRATION") != -1)
				{
					e1 = fileLine.ToUpper().IndexOf("EXPIRATION");
				}
				else if (fileLine.ToUpper().IndexOf("DATA SET") != -1 && fileLine.ToUpper().IndexOf("SERIAL") != -1)
				{
					s1 = fileLine.ToUpper().IndexOf("SERIAL");
					d1 = fileLine.ToUpper().IndexOf("DATA SET");
				}
				else if (0 == fileLine.Replace("-", String.Empty).Trim().Length)
				{
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
        private void ReadListItems(StreamReader r, ref IList il)
        {
            while ((fileLine = r.ReadLine()) != null)
            {
                // If line contains first header line, break
                if (fileLine.Trim() == String.Empty)
                {
                    break;
                }
                else if (fileLine[0] == '1')
                {
                    break;
                }
                else if (fileLine[0] == '-')
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("END OF REPORT") != -1)
                {
                    break;
                }
                else if (fileLine.ToUpper().IndexOf("MOVEMENT REPORT") != -1)
                {
                    break;
                }
                else
                {
                    // Initialize
                    string serialNo = null;
                    string dataNote = null;
                    // Get the other information
                    serialNo = fileLine.Substring(s1);
                    dataNote = DataSetNoteAction != "NO ACTION" ? fileLine.Substring(d1) : " ";
					// Chop each at first space
					serialNo = serialNo.Substring(0, serialNo.IndexOf(' '));
					dataNote = dataNote.Substring(0, dataNote.IndexOf(' '));
					// Add to the item collection
                    if (il is ReceiveListItemCollection)
                    {
						il.Add(new ReceiveListItemDetails(serialNo, dataNote));
                    }
                    else
                    {
						string r1 = String.Empty;
						// Get the return date
						if (EmployReturnDate && e1 != -1)
						{
							r1 = fileLine.Substring(e1);
							r1 = r1.Substring(0, r1.IndexOf(' '));
							// Julian date?
							if (new Regex("^(19|20)[0-9]{2}/[0-9]{1,3}$").IsMatch(r1))
							{
								int year = Convert.ToInt32(r1.Substring(0,4));
								int day = Convert.ToInt32(r1.Substring(5).Trim());
								r1 = new DateTime(year, 1, 1).AddDays(day - 1).ToString("yyyy-MM-dd");
							}

						}
						// Add to the collection
						il.Add(new SendListItemDetails(serialNo, r1, dataNote, String.Empty));
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
        /// <param name="sli">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="rli">
        /// Receptacle for returned receive list item collection
        /// </param>
        public override void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli)
        {
            IList il = null;
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
                    // Site flags
                    bool x = false, y = false;
                    // Destination site
                    try
                    {
                        x = SiteIsEnterprise(targetSite);
                    }
                    catch (ExternalSiteException)
                    {
                        if (this.IsAccount(targetSite))
                        {
                            x = false;
                        }
                        else if (!this.IgnoreUnknownSite)
                        {
                            throw;
                        }
                        else
                        {
                            targetSite = String.Empty;
                        }
                    }
                    // Source site
                    try
                    {
                        y = SiteIsEnterprise(sourceSite);
                    }
                    catch (ExternalSiteException)
                    {   
                        if (this.IsAccount(sourceSite))
                        {
                            y = false;
                        }
                        else if (!this.IgnoreUnknownSite)
                        {
                            throw;
                        }
                        else
                        {
                            sourceSite = String.Empty;
                        }
                    }
                    // Read the items of the list
                    if (targetSite.Length != 0 || sourceSite.Length != 0)
                    {
                        // If one site was unknown, set it to the opposite of the other site
                        if (sourceSite.Length == 0)
                        {
                            y = !x;
                        }
                        else if (targetSite.Length == 0)
                        {
                            x = !y;
                        }
                        // Get the items if the destination does not match the source.  If they
                        // match, just move to the next set of headers.
                        if (x == y)
                        {
                            ;
                        }
                        else if (x == true)
                        {
                            il = (IList)rli;
                            ReadListItems(r, ref il);
                        }
                        else 
                        {
                            il = (IList)sli;
                            ReadListItems(r, ref il);
                        }
                    }
                }
            }
        }
    }
}
