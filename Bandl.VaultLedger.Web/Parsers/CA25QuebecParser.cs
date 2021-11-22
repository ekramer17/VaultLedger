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
	/// Summary description for CA25QuebecParser.
	/// </summary>
	public class CA25QuebecParser : CA25Parser, IParserObject
	{
		int v1 = -1;

		public CA25QuebecParser() {}

		/// <summary>
		/// Moves the position of the streamreader past the list headers, to
		/// just before the line containing the first item of the list.
		/// </summary>
		/// <param name="sr">
		/// Stream reader reading the report file
		/// </param>
		private void MovePastListHeaders(StreamReader r)
		{
			int c = 0;
			string myline;

			while ((myline = r.ReadLine()) != null)
			{
				if (myline.IndexOf('-') != -1 && String.Empty == myline.Trim().Replace("-",String.Empty))
				{
					if (++c == 2) return;
				}
				else if (c == 1 && myline.IndexOf("VOLSER") != -1)
				{
					v1 = myline.IndexOf("VOLSER");
				}
			}
		}

		/// <summary>
		/// Reads the items for a single distribution list in the CA25 report.
		/// Stream reader should be positioned before the first item of the 
		/// list upon entry.
		/// </summary>
		/// <param name="sr">
		/// Streamreader attached to the CA25 report file
		/// </param>
		private void ReadListItems(StreamReader r, ReportType t1, bool b1, ref SendListItemCollection s1, ref ReceiveListItemCollection r1)
		{
			string myline;
			bool snd1 = false;

			while ((myline = r.ReadLine()) != null)
			{
				// Break conditions
				if (myline.Trim().Length == 0)
				{
					break;
				}
				else if (v1 != 0 && myline[0] == '1')
				{
					break;
				}
				// Determine whether we are creating receive list items or send list items                
				if (b1 == true)
				{
					snd1 = t1 != ReportType.Distribution;
				}
				else
				{
					snd1 = t1 != ReportType.Picking;
				}
				// Construct an item of the correct type and fill it
				if (snd1 == false)
				{
					r1.Add(new ReceiveListItemDetails(myline.Substring(v1).Trim(), String.Empty));
				}
				else
				{
					s1.Add(new SendListItemDetails(myline.Substring(v1).Trim(), String.Empty, String.Empty, String.Empty));
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
		public override void Parse(byte[] t1, out SendListItemCollection s1, out ReceiveListItemCollection r1)
		{
			ReportType reportType;
			string site1 = String.Empty;
			// Create the new collections
			s1 = new SendListItemCollection();
			r1 = new ReceiveListItemCollection();
			// See if we should ignore the picking lists
			bool nopick = this.IgnorePickingLists(t1);
			// Read through the file, collecting items
			using (StreamReader r = new StreamReader(new MemoryStream(t1)))
			{
				while ((site1 = FindNextListSite(r, out reportType)) != String.Empty) 
				{
					if (nopick == false || reportType != ReportType.Picking)
					{
						bool b1 = SiteIsEnterprise(site1);
						// Move past the list headers
						MovePastListHeaders(r);
						// Read the items of the list
						if (site1.Length != 0)
						{
							ReadListItems(r, reportType, b1, ref s1, ref r1);
						}
					}
				}
			}
		}
	}
}
