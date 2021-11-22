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
	/// Summary description for CoverallParser.
	/// </summary>
	public class CoverallParser : Parser, IParserObject
	{
		public CoverallParser()
		{
			//
			// TODO: Add constructor logic here
			//
		}
		/// <summary>
		/// Reads the items of the report
		/// </summary>
		private void ReadListItems(StreamReader r, ref IList x1)
		{
			String s1 = null;

			while ((s1 = r.ReadLine()) != null)
			{
				if ((s1 = s1.Trim()).Length != 0)
				{
					// Remove double spaces
					while (s1.IndexOf("  ") != -1) s1 = s1.Replace("  ", " ");
					// Split
					String[] s2 = s1.Split(new char[] {' '});
					// Get the serial number and the note
					String n1 = s2[2];
					String n2 = String.Empty;
					for (int i1 = 3; i1 < s2.Length; i1 += 1)
					{
						n2 += s2[i1];
					}
					// Ship or receive?
					if (x1 is SendListItemCollection)
					{
						x1.Add(new SendListItemDetails(n1, String.Empty, n2, String.Empty));
					}
					else
					{
						x1.Add(new ReceiveListItemDetails(n1, n2));
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
		public override void Parse(byte[] b1, out SendListItemCollection s1, out ReceiveListItemCollection r1)
		{
			IList il = null;
			// Create the new collections
			s1 = new SendListItemCollection();
			r1 = new ReceiveListItemCollection();
			// Create a new memory stream
			MemoryStream ms = new MemoryStream(b1);
			// Read through the parser and obtain the items
			using (StreamReader r = new StreamReader(ms))
			{
				// Read the first line, get the correct collection
				il = r.ReadLine().ToUpper()[0] == 'S' ? (IList)s1 : (IList)r1;
				// These reports are always receive lists
				ReadListItems(r, ref il);
			}
		}
	}
}
