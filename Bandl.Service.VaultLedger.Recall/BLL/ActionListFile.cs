using System;
using System.IO;
using System.Web;
using System.Text;
using System.Collections;
using System.Configuration;
using System.Text.RegularExpressions;
using Bandl.Service.VaultLedger.Recall.DAL;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
	/// <summary>
	/// Abstract class from which all classes representing list files
	/// are derived.
	/// </summary>
	public abstract class ActionListFile
	{
        protected enum ListType
        {
            Send = 1,           // client to vault
            Receive = 2,        // vault to client
            DisasterCode = 3
        }

        #region Number File Methods
        private static string GetNumberFile(string accountNo, char fileType)
        {
            // Get the application path
            string appPath = HttpRuntime.AppDomainAppPath;
            if (appPath[appPath.Length-1] != Path.DirectorySeparatorChar)
                appPath = String.Format("{0}{1}", appPath, Path.DirectorySeparatorChar);
            // Get the next number directory
            string folderName = String.Format("{0}nextLists{1}", appPath, Path.DirectorySeparatorChar);
            // If the directory doesn't exist, then add it
            if (Directory.Exists(folderName) == false)
                Directory.CreateDirectory(folderName);
            // Get the name of the file
            return String.Format("{0}{1}{2}", folderName, accountNo, fileType);
        }

        /// <summary>
        /// Reads the number of the next file from the number file for the given account number
        /// </summary>
        /// <param name="accountNo">Account number</param>
        /// <returns>Number of next file if found, else -1</returns>
        private static int ReadNextNumber(string accountNo, char fileType)
        {
            string fileName = GetNumberFile(accountNo, fileType);
            // If the number file doesn't exist, return -1
            if (File.Exists(fileName) == false)
            {
                return -1;
            }
            else
            {
                using (StreamReader streamReader = new StreamReader(fileName))
                {
                    try
                    {
                        return Convert.ToInt32(streamReader.ReadLine());
                    }
                    catch
                    {
                        return -1;
                    }
                }
            }
        }

        /// <summary>
        /// Writes the number of the next file to the number holding file for the given account
        /// </summary>
        /// <param name="accountNo">Account number</param>
        /// <returns>Number of next file if found, else -1</returns>
        protected static void WriteNextNumber(string accountNo, string fileName)
        {
            int i = fileName.LastIndexOf(Path.DirectorySeparatorChar);
            string nameOnly = i != -1 ? fileName.Substring(i + 1) : fileName;
            // Get the index where the account portion occurs as well as the list type
            int p = nameOnly.IndexOf(accountNo);
            char fileType = nameOnly[p-1];
            // Write the next number to the file
            using (StreamWriter w = new StreamWriter(GetNumberFile(accountNo, fileType), false))
                w.WriteLine("{0}", (Convert.ToInt32(nameOnly.Substring(p).Replace(".fil", String.Empty).Replace(accountNo, String.Empty)) + 1) % 100);
        }
        #endregion

        /// <summary>
        /// Gets the name of the file to write
        /// </summary>
        /// <param name="listType">
        /// Type of list for which to get the file name
        /// </param>
        /// <param name="account">
        /// Account on list to be written
        /// </param>
        /// <returns>
        /// Name of the new file
        /// </returns>
        protected static string GetFileName(ListType listType, string account)
        {
            int nextNumber;
            string filePath;
            string filePrefix;
            // Get the directory from the configuration file
            switch (listType) 
            {
                case ListType.Send:
                    filePrefix = "R" + account;
                    break;
                case ListType.Receive:
                    filePrefix = "P" + account;
                    break;
                case ListType.DisasterCode:
                    filePrefix = "D" + account;
                    break;
                default:
                    return null;
            }
            // Get the file path from the database
            if ((filePath = SQLServer.RetrieveFilePath(account)) == String.Empty)
                throw new ApplicationException("Account not found");
            else
            {
                // Verify that is a trailing separator
                if (false == filePath.EndsWith(Convert.ToString(Path.DirectorySeparatorChar)))
                    filePath += Convert.ToString(Path.DirectorySeparatorChar);
                // Make sure the directory exists
                if (false == Directory.Exists(filePath))
                    throw new ApplicationException("File cache directory not found");
            }
            // See if the number file exists.  If it does, get the next file 
            // number.  If not, see if we have any files in the directory.
            if ((nextNumber = ReadNextNumber(account, filePrefix[0])) == -1)
            {
                nextNumber = 0;
                // Get the files in the directory for the given account number
                string[] files = Directory.GetFiles(filePath, filePrefix + "*.fil");
                // Run through the file listing, finding the largest number
                for (int i = 0; i < files.Length; i++)
                {
                    try
                    {
                        int x = Convert.ToInt32(files[i].Replace(filePath + filePrefix, String.Empty).Replace(".fil", String.Empty)) + 1;
                        if (x > nextNumber) nextNumber = x;
                    }
                    catch
                    {
                        ;
                    }
                }
                // If next number is 100, reset to zero
                if (nextNumber == 100) nextNumber = 0;
            }
            // Return the file name
            return String.Format("{0}{1}{2}.fil", filePath, filePrefix, nextNumber);
        }
	}
}
