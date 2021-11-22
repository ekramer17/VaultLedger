using System;
using System.IO;
using System.Web;
using System.Text;
using System.Collections;
using System.Configuration;
using Bandl.Service.VaultLedger.Recall.DAL;
using Bandl.Service.VaultLedger.Recall.Model;
using Bandl.Service.VaultLedger.Recall.Exceptions;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
	/// <summary>
	/// Summary description for AccountFile.
	/// </summary>
	public class AccountFile
	{
        private static string FileName
        {
            get
            {
                // Get the path of the file
                string appPath = HttpRuntime.AppDomainAppPath;
                string dirSeparator = Path.DirectorySeparatorChar.ToString();
                string fileName = String.Format("{0}{1}Accounts.config", appPath, appPath.EndsWith(dirSeparator) ? "" : dirSeparator);
                // Verify that file exists
                if (false == File.Exists(fileName))
                {
                    throw new ApplicationException("Account file not found.");
                }
                else                    
                {
                    return fileName;
                }
            }
        }

        /// <summary>
        /// Gets the file path for a given global account
        /// </summary>
        /// <param name="globalAccount">
        /// Global account for which to geet file path
        /// </param>
        /// <returns>
        /// File path on success, null if account not found
        /// </returns>
        public static string GetFilePath(string globalAccount)
        {
            string fileLine;
            // Read through the file, looking for the account
            using(StreamReader sr = new StreamReader(FileName))
            {
                while((fileLine = sr.ReadLine()) != null )
                {
                    // Split the string into fields.  If the first field
                    // is equal to the account number, then return true
                    string[] fields = fileLine.Split(new char[] {','});
                    if (fields.Length > 0)
                        if (globalAccount == fields[1].Trim()) 
                            return fields[fields.Length-1].Trim();
                }
            }
            // Global account was not found
            return null;
        }

        /// <summary>
        /// Get the accounts for the given global account from the 
        /// accounts.txt file
        /// </summary>
        /// <param name="globalAccount">
        /// Global account for which to retrieve all account information
        /// </param>
        /// <returns>
        /// Array of account objects
        /// </returns>
        public static AccountDetails[] RetrieveAccounts(string globalAccount)
        {
            // Read through the file, adding accounts with the given global account
            using(StreamReader sr = new StreamReader(FileName))
            {
                string fileLine;
                string[] fields;
                string name, address1, address2, city, state, zipCode;
                string country, contact, phoneNo, email, filePath;
                bool global;
                // Create the collection
                ArrayList al = new ArrayList();
                ArrayList secAccounts = new ArrayList();
                // Read through the file
                while((fileLine = sr.ReadLine()) != null )
                {
                    // Make sure there is something in the line
                    if (fileLine.Trim().Length != 0)
                    {
                        // Split the string into fields.  
                        fields = fileLine.Split(new char[] {','});
                        // A global account must have 12 fields.  A service account
                        // only needs eleven.
                        if ((fields[0].Trim() == fields[1].Trim() && fields.Length != 12) || fields.Length < 11)
                            throw new InvalidFieldCountException("Line with illegal number of fields found in account file.  Please contact Recall Corporation immediately.");
                        // If the second field is the given global account, 
                        // create a new account with the information on
                        // the rest of the line
                        if (globalAccount == fields[1].Trim()) 
                        {
                            name = fields[0].Trim();
                            address1 = fields[2].Trim();
                            address2 = fields[3].Trim();
                            city = fields[4].Trim();
                            state = fields[5].Trim();
                            country = fields[6].Trim();
                            zipCode = fields[7].Trim();
                            contact = fields[8].Trim();
                            phoneNo = fields[9].Trim();
                            email = fields[10].Trim();
                            global = (name == globalAccount);
                            filePath = global ? fields[11].Trim() : String.Empty;
                            // Add account details to collection
                            al.Add(new AccountDetails(name, global, address1, address2, city, state, zipCode, country, contact, phoneNo, email, filePath));
                            // If the account is a secondary account, add it to the database
                            if (global == false) secAccounts.Add(name);
                        }
                    }
                }
                // Update the database with the secondary accounts
                SQLServer.UpdateSecondaryAccounts(globalAccount,(string[])secAccounts.ToArray(typeof(string)));
                // Return the array
                return (AccountDetails[])al.ToArray(typeof(AccountDetails));
            }
        }   // end RetrieveAccounts
	}
}
