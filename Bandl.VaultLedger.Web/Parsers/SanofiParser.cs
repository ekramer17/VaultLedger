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
	public class SanofiParser : Parser, IParserObject
	{
		string s1 = null;
		ListTypes x1 = ListTypes.Send;

		public SanofiParser() {}

		/// <summary>
		/// Moves the position of the streamreader past the list headers, to
		/// just before the line containing the first item of the list.
		/// </summary>
		/// <param name="sr">
		/// Stream reader reading the report file
		/// </param>
		private void MovePastListHeaders(StreamReader r)
		{
			if (r.ReadLine().ToUpper().IndexOf("INBOUND") != -1)
			{
				x1 = ListTypes.Receive;
			}
			else
			{
				x1 = ListTypes.Send;
			}
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
		private void ReadListItems(StreamReader r, ref IList i1)
		{
			while ((s1 = r.ReadLine()) != null)
			{
				if (s1.Trim() == String.Empty)
				{
					continue;
				}
				else if (i1 is SendListItemCollection)
				{
					i1.Add(new SendListItemDetails(s1.Trim(), String.Empty, String.Empty, String.Empty));
				}
				else
				{
					i1.Add(new ReceiveListItemDetails(s1.Trim(), String.Empty));
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
		public override void Parse(byte[] t1, out SendListItemCollection sl, out ReceiveListItemCollection rl)
		{
			// Create the new collections
			sl = new SendListItemCollection();
			rl = new ReceiveListItemCollection();
			// Create a new memory stream
			MemoryStream ms = new MemoryStream(t1);
			// Read through the file, collecting items
			using (StreamReader r = new StreamReader(ms))
			{
				IList il = null;
				MovePastListHeaders(r);
				// Read based on type
				if (x1 == ListTypes.Send)
				{
					il = (IList)sl;
					ReadListItems(r, ref il);
				}
				else
				{
					il = (IList)rl;
					ReadListItems(r, ref il);
				}
			}
		}
	}
}

