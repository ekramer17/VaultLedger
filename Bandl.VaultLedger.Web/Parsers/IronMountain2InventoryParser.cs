using System;
using System.IO;
using System.Collections;
using System.Globalization;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Parser used in conjunction with batch scanner inventory files.  Since
	/// this file only has one format, we don't need to use the IParser 
	/// interface or inherit from the master Parser object.  Those are
	/// used with parsing tape logging reports, e.g. CA-25.
	/// </summary>
	public class IronMountain2InventoryParser : InventoryParser
	{
        private class Field
        {
            public int Pos = -1;
            public int Len = -1;

            public Field (int pos, int len)
            {
                this.Pos = pos;
                this.Len = len;
            }
        }

        string _line;
        Field[] _fields = new Field[3]; // account, serial, description

		public IronMountain2InventoryParser() {}

        private void GetFields(string x1)
        {
            int p1 = 0, p2 = 0;
            char[] a1 = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
            string[] h1 = {"Cust #", "Media #", "Description" };
            // Get the field positions and lengths
            for (int i = 0; i < h1.Length; i += 1)
            {
                p1 = x1.IndexOf(h1[i]);
                p2 = x1.IndexOfAny(a1, p1 + h1[i].Length);
                this._fields[i] = new Field(p1, p2 - p1);
            }
        }

        private void ParseFixed(StreamReader r1, ref ArrayList n1, ref ArrayList s1, ref ArrayList a1)
        {
            while((this._line = r1.ReadLine()) != null) 
            {
                int i = -1;
                // Account
                string accountName = this._line.Substring(this._fields[0].Pos, this._fields[0].Len).Trim();
                // Find the account in the list
                for (int j = 0; j < a1.Count && i == -1; j++)
                    if (accountName == (string)a1[j])
                        i = j;
                // If i = -1, add the account to the list
                if (i == -1) 
                {
                    a1.Add(accountName);
                    s1.Add(new ArrayList());
                    n1.Add(new ArrayList());
                    i = a1.Count - 1;
                }
                // Add the serial number to the correct serial number array list
                ((ArrayList)s1[i]).Add(this._line.Substring(this._fields[1].Pos, this._fields[1].Len).Trim());
                ((ArrayList)n1[i]).Add(this._line.Substring(this._fields[2].Pos, this._fields[2].Len).Trim());
            }
        }

        private void ParseNonFixed(StreamReader r1, ref ArrayList n1, ref ArrayList s1, ref ArrayList a1)
        {
            while((this._line = r1.ReadLine()) != null) 
            {
                int i = -1;
                // Split the line
                string[] x = this._line.Trim().Split(new char[] {','});
                // Account is at the first field
                string accountName = x[0];
                // Find the account in the list
                for (int j = 0; j < a1.Count && i == -1; j++)
                    if (accountName == (string)a1[j])
                        i = j;
                // If i = -1, add the account to the list
                if (i == -1) 
                {
                    a1.Add(accountName);
                    s1.Add(new ArrayList());
                    n1.Add(new ArrayList());
                    i = a1.Count - 1;
                }
                // Add the serial number to the correct serial number array list
                ((ArrayList)s1[i]).Add(x[1]);
                ((ArrayList)n1[i]).Add(x[6]);
            }
        }

		/// <summary>
		/// Parses a byte array of the contents of a batch scanner inventory file
		/// </summary>
		/// <param name="fileText">
		/// Byte array of the contents of the inventory file
		/// </param>
		/// <param name="accounts">
		/// String array of account numbers
		/// </param>
		/// <param name="serials">
		/// Array of arraylists; each arraylist is a list of serial numbers belonging to
		/// the account number contained at the same index of the accounts array.
		/// </param>
		public override void Parse(byte[] fileText)
		{
            ArrayList notesLists  = new ArrayList();
            ArrayList serialLists = new ArrayList();
			ArrayList accountList = new ArrayList();
			// Create a new memory stream
			MemoryStream ms = new MemoryStream(fileText);
			// Read through the stream, collecting items
			using (StreamReader r1 = new StreamReader(ms))
			{
				// Get the header line
				this._line = r1.ReadLine();
                // Does it contain a comma?
                if (this._line.IndexOf(',') != -1)
                {
                    this.ParseNonFixed(r1, ref notesLists, ref serialLists, ref accountList);
                }
                else
                {
                    this.GetFields(this._line);
                    this.ParseFixed(r1, ref notesLists, ref serialLists, ref accountList);
                }

//				// Read through the file
//				while((fileLine = r.ReadLine()) != null) 
//				{
//					int i = -1;
//					// Split the line
//					string[] x = fileLine.Trim().Split(new char[] {','});
//					// Account is at the first field
//					string accountName = x[0];
//					// Find the account in the list
//					for (int j = 0; j < accountList.Count && i == -1; j++)
//						if (accountName == (string)accountList[j])
//							i = j;
//					// If i = -1, add the account to the list
//					if (i == -1) 
//					{
//						serialLists.Add(new ArrayList());
//                        notesLists.Add(new ArrayList());
//                        accountList.Add(accountName);
//                        i = accountList.Count - 1;
//					}
//					// Add the serial number to the correct serial number array list
//					((ArrayList)serialLists[i]).Add(x[1]);
//                    ((ArrayList)notesLists[i]).Add(x[6]);
//                }
            }
            // Convert notes arraylist to array of arraylists
            this.myNotes = (ArrayList[])notesLists.ToArray(typeof(ArrayList));
            // Convert account number arraylist to string array
            this.myAccounts = (string[])accountList.ToArray(typeof(string));
            // Convert serial number arraylist to array of arraylists
            this.mySerials = (ArrayList[])serialLists.ToArray(typeof(ArrayList));
        }
	}
}
