using System;
using System.IO;
using System.Collections;
using System.Security.Cryptography;
using Bandl.Service.VaultLedger.Recall.DAL;
using Bandl.Service.VaultLedger.Recall.Model;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
    /// <summary>
    /// Summary description for InventoryFile.
    /// </summary>
    public class InventoryFile
    {
        /// <summary>
        /// Gets the hash of the inventory file
        /// </summary>
        /// <param name="account">
        /// Account for which to get hash
        /// </param>
        /// <returns></returns>
        public static byte[] GetFileHash(string account)
        {
            // Get the name of the file
            string fileName = GetFileName(account);
            // See if a file exists in the directory with that name.  If 
            // not, return null.
            if (File.Exists(fileName) == false)
                return null;
            else 
            {
                using (StreamReader r = new StreamReader(fileName))
                {
                    using (HashAlgorithm hashAlg = HashAlgorithm.Create("SHA-256")) 
                    {
                        return hashAlg.ComputeHash(r.BaseStream);
                    }
                }
            }        
        }

        /// <summary>
        /// Reads the inventory file for the given account
        /// </summary>
        /// <param name="account">
        /// Account for which to read inventory file
        /// </param>
        /// <returns>
        /// Inventory for the given account in an InventoryDetails object
        /// </returns>
        public static InventoryDetails Read(string account)
        {
            // Get the name of the file
            string fileName = GetFileName(account);
            // See if a file exists in the directory with that name  If not,
            // throw an exception.
            if (File.Exists(fileName) == false)
                throw new FileNotFoundException("Inventory file not found");
            // Create an arraylist to hold the items
            ArrayList itemList = new ArrayList();
            // Read through the file, adding each item to the array list
            using (StreamReader sr = new StreamReader(fileName))
            {
                string fileLine;
                string[] lineTokens;
                string lastType = String.Empty;
                string lastReturn = String.Empty;
                string lastDescription = String.Empty;
                while ((fileLine = sr.ReadLine()) != null)
                {
                    lineTokens = fileLine.Split(new char[] {'%'});
                    InventoryItem i = new InventoryItem();
                    // Initialize the type code because not every 
                    // line will have one.  If it is absent, it is
                    // intended to use the same type code as the
                    // prior entry in the inventory file.
                    i.TypeCode = lastType;
                    // Ditto for the description field
                    i.Description = lastDescription;
                    // Ditto for the return date
                    i.ReturnDate = lastReturn;
                    // Loop through the fields in the line, looking for
                    // the serial number and, possibly, the type code and
                    // description.
                    foreach(string s in lineTokens)
                    {
                        if (s != String.Empty)
                        {
                            // First letter 'V' means serial number.  First 
                            // letter 'M' means medium type, which we can use
                            // to determine whether or not the item is a case.
                            // First letter 'D' means description, what we call
                            // a note.
                            switch (s[0])
                            {
                                case 'V':
                                    i.SerialNo = s.Substring(1);
                                    break;
                                case 'E':
                                    i.ReturnDate = GetReturnDate(s.Substring(1));
                                    lastReturn = i.ReturnDate;
                                    break;
                                case 'M':
                                    i.TypeCode = s.Substring(1);
                                    lastType = i.TypeCode;
                                    break;
                                case 'D':
                                    i.Description = s.Length > 1 ? s.Substring(1) : String.Empty;
                                    lastDescription = i.Description;
                                    break;
                            }
                        }
                    }
                    // If the serial number of the item is not empty string, add item to array list.
                    if (i.SerialNo != String.Empty) itemList.Add(i);
                }
            }
            // Create an inventory details object and add the items to it
            InventoryItem[] items = (InventoryItem[])itemList.ToArray(typeof(InventoryItem));
            return new InventoryDetails(account, File.GetLastWriteTime(fileName), GetFileHash(account), items);
        }

        /// <summary>
        /// Gets the name of the inventory file
        /// </summary>
        /// <param name="account">
        /// Account for which to receive inventory
        /// </param>
        /// <returns>
        /// Name of the inventory file
        /// </returns>
        private static string GetFileName(string account)
        {
            string filePath;
            // Get the file path from the database
            if ((filePath = SQLServer.RetrieveFilePath(account)) == String.Empty)
                throw new ApplicationException("Inventory file path not found");
            else 
            {
                // Verify that there is a trailing separator
                if (false == filePath.EndsWith(Convert.ToString(System.IO.Path.DirectorySeparatorChar)))
                    filePath += Convert.ToString(System.IO.Path.DirectorySeparatorChar);
                // Make sure the directory exists
                if (false == Directory.Exists(filePath))
                    throw new ApplicationException("File cache directory not found");
            }
            // return the name of the file
            return Path.Combine(filePath, String.Format("I{0}.fil", account));
        }

        /// <summary>
        /// Gets the return date from the inventory file
        /// </summary>
        /// <param name="dateString">Date as it appears in inventory file</param>
        /// <returns>Date in MM-dd-yyyy format</returns>
        private static string GetReturnDate(string dateString)
        {
            int m = Int32.Parse(dateString.Substring(0,2));
            int d = Int32.Parse(dateString.Substring(3,2));
            int y = Int32.Parse(dateString.Substring(6,4));
            return y != 2999 ? new DateTime(y,m,d).ToString("MM/dd/yyyy") : String.Empty;
        }
    }
}
