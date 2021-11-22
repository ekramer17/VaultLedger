using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Collections;
using System.Security.Cryptography;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.DALFactory;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for RQMMInventoryParser.
	/// </summary>
	public class RQMMInventoryParser : InventoryParser
	{
        public RQMMInventoryParser() {}

        private string GetAccount(string s1)
        {
            s1 = s1.Substring("INVENTORY LIST FOR ".Length).Trim();
            s1 = s1.IndexOf(' ') == -1 ? s1 : s1.Substring(0, s1.IndexOf(' '));
            return s1.Replace("#", String.Empty);
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
            string fileLine;
            // Create arraylists for the serial number, accounts
            ArrayList serialLists = new ArrayList();
            ArrayList accountList = new ArrayList();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader r = new StreamReader(ms))
            {
                // Header line
                serialLists.Add(new ArrayList());
                accountList.Add(GetAccount(r.ReadLine()));
                // Read through the file
                while((fileLine = r.ReadLine()) != null) 
                {
                    // Skip blank lines
                    if (fileLine.Trim().Length == 0)
                    {
                        continue;
                    }
                    // Remove double spaces
                    while (fileLine.IndexOf("  ") != -1)
                    {
                        fileLine = fileLine.Replace("  ", " ");
                    }
                    // Split the line
                    string[] x1 = fileLine.Trim().Split(new char[] {' '});
                    // Serial at 1st or 3rd
                    if (x1.Length > 2)
                    {
                        ((ArrayList)serialLists[0]).Add(x1[2]);
                    }
                    else
                    {
                        ((ArrayList)serialLists[0]).Add(x1[0]);
                    }
                }
            }
            // Convert account number arraylist to string array
            this.myAccounts = (string[])accountList.ToArray(typeof(string));
            // Convert serial number arraylist to array of arraylists
            this.mySerials = (ArrayList[])serialLists.ToArray(typeof(ArrayList));
        }
	}
}
