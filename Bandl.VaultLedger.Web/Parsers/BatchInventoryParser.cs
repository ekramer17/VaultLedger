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
	public class BatchInventoryParser : InventoryParser
	{
        public BatchInventoryParser() {}
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
            int accountIndex;
            // Create arraylists for the serial number and accounts
            ArrayList s = new ArrayList();
            ArrayList a = new ArrayList();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader sr = new StreamReader(ms))
            {
                // Skip the first two lines; they're headers
                sr.ReadLine();
                sr.ReadLine();
                // Next line should contain an account number
                fileLine = sr.ReadLine();
                if (fileLine.Substring(0,2) != "$A")
                {
                    throw new ParserException("Account number not found on third line of batch scanner inventory file.");
                }
                else
                {
                    accountIndex = 0;
                    s.Add(new ArrayList());
                    a.Add(fileLine.Substring(2));
                }
                // Read through the rest of the file.  If the line begins with
                // $A, then it represents a new account number.  Otherwise the
                // line contains a serial number.
                while((fileLine = sr.ReadLine()) != null) 
                {
                    if (fileLine.Substring(0,2) != "$A")
                    {
                        ((ArrayList)s[accountIndex]).Add(fileLine.Trim());
                    }
                    else
                    {
                        accountIndex = -1;
                        // If the account is already in the list, then set the index
                        // to that of the correct account.
                        string nextAccount = fileLine.Substring(2);
                        for (int i = 0; i < a.Count; i++)
                        {
                            if (nextAccount.CompareTo((string)a[i]) == 0)
                            {
                                accountIndex = i;
                                break;
                            }
                        }
                        // If we did not find the account already in the list,
                        // add the new account to the account list and set the index.
                        // Also create a new arraylist in the serial number array
                        // of arraylists.
                        if (accountIndex == -1)
                        {
                            a.Add(nextAccount);
                            s.Add(new ArrayList());
                            accountIndex = a.Count - 1;
                        }
                    }
                }
            }
            // Convert serial number arraylist to array of arraylists
            this.mySerials = (ArrayList[])s.ToArray(typeof(ArrayList));
            // Convert account number arraylist to string array
            this.myAccounts = (string[])a.ToArray(typeof(string));
        }
	}
}
