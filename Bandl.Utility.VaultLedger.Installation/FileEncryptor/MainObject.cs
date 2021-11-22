using System;
using System.IO;
using System.Data;
using System.Windows.Forms;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Installation.FileEncryptor
{
	/// <summary>
	/// Summary description for MainObject.
	/// </summary>
    class MainObject
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            string plainText;
            string cipherText;
            string inputName = String.Empty;
            string outputName = String.Empty;
            string encryptionVector = String.Empty;

            try
            {
                ProcessCommandLine(Environment.GetCommandLineArgs(), ref inputName, ref outputName, ref encryptionVector);
                // Read
                using (StreamReader sr = new StreamReader(inputName))
                    plainText = sr.ReadToEnd();
                // Encrypt
                cipherText = Convert.ToBase64String(Balance.Inter(plainText, Convert.FromBase64String(encryptionVector)));
                // Write
                using (StreamWriter sw = new StreamWriter(outputName))
                    sw.Write(cipherText);
                // Message box
                MessageBox.Show("File '" + inputName + "' successfully encrypted as '" + outputName + "'.", "File Encryptor");
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Script Encryption Utility", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        ///
        /// Command line flags: 
        /// /s:serverName
        /// /db:databaseName
        /// /id:loginId
        /// /pwd:password
        /// /f:fileName
        /// /p:productType
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] commandLine, ref string inputName, ref string outputName, ref string encryptionVector)
        {
            try
            {
                for (int i = 1; i < commandLine.Length; i++)
                {
                    int j = commandLine[i].IndexOf(':');
                    // Make sure we have a colon
                    if (j == -1)
                        throw new ApplicationException("Incorrect syntax (" + commandLine[i] + ")");
                    // Split the field on the colon
                    string s = commandLine[i].Substring(j + 1).Trim();
                    // Get the value based on the first half
                    switch (commandLine[i].Substring(0,j).ToLower())
                    {
                        case "/i":
                            inputName = s;
                            break;
                        case "/o":
                            outputName = s;
                            break;
                        case "/v":
                            encryptionVector = s;
                            break;
                        default:
                            throw new ApplicationException(String.Format("Unknown flag ({0})", s[0]));
                    }
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException("Error in command line: " + ex.Message);
            }
            // Make sure the file exists
            if (inputName.Length == 0)
                throw new ApplicationException("No input file supplied.");
            else if (!File.Exists(inputName = Path.GetFullPath(inputName)))
                throw new ApplicationException("File '" + inputName + "' not found.");
            // If no output file, construct the name
            if (outputName.Length == 0)
            {
                if (inputName.EndsWith(".sql"))
                {
                    outputName = inputName.Substring(0, inputName.Length - 4) + ".sqe";
                }
                else
                {
                    outputName = inputName.Substring(0, inputName.LastIndexOf(@"\") + 1) + "cipherText.txt";
                }
            }
        }
    }
}
