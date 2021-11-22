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
    public class IronMountainInventoryParser : InventoryParser
    {
        public IronMountainInventoryParser() {}
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
            // Create arraylists for the serial number and accounts
            ArrayList serialLists = new ArrayList();
            ArrayList accountList = new ArrayList();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the file
                while((fileLine = sr.ReadLine()) != null) 
                {
                    int i = -1;
                    // Replace all the double spaces with single
                    while (fileLine.IndexOf("  ") != -1)
                        fileLine = fileLine.Replace("  ", " ");
                    // Split the line
                    string[] x = fileLine.Split(new char[] {' '});
                    // Account is at the first field
                    string accountName = x[0];
                    // Find the account in the list
                    for (int j = 0; j < accountList.Count && i == -1; j++)
                        if (accountName == (string)accountList[j])
                            i = j;
                    // If i = -1, add the account to the list
                    if (i == -1) 
                    {
                        serialLists.Add(new ArrayList());
                        accountList.Add(accountName);
                        i = accountList.Count - 1;
                    }
                    // Add the serial number to the correct serial number array list
                    ((ArrayList)serialLists[i]).Add(x[1]);
                }
            }
            // Convert account number arraylist to string array
            this.myAccounts = (string[])accountList.ToArray(typeof(string));
            // Convert serial number arraylist to array of arraylists
            this.mySerials = (ArrayList[])serialLists.ToArray(typeof(ArrayList));
        }
    }
}
