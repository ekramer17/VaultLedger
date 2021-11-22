using System;
using System.IO;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
	/// <summary>
	/// Reprsents the Recall account file
	/// </summary>
	public class AccountFile
	{
        public static bool FindAccount(string accountName)
        {
            try
            {
                using (StreamReader sr = new StreamReader(Configurator.AccountFile))
                {
                    string fileLine;
                    string fileAccount;
                    while ((fileLine = sr.ReadLine()) != null)
                    {
                        fileLine = fileLine.Trim();
                        // If the line contains commas, we'll assume that the file
                        // is in normal Recall account form, i.e. the second field
                        // is the global account number.
                        if (fileLine.IndexOf(',') == -1)
                        {
                            fileAccount = fileLine;
                        }
                        else
                        {
                            int index = fileLine.IndexOf(',') + 1;
                            fileLine = fileLine.Substring(index, fileLine.Length - index).Trim();
                            index = fileLine.IndexOf(',');
                            fileAccount = fileLine.Substring(0, index != -1 ? index : fileLine.Length);
                        }
                        // Test equality
                        if (fileAccount == accountName) 
                        {
                            return true;
                        }
                    }
                }
                // Account not found
                return false;
            }
            catch
            {
                return false;
            }
        }
	}
}
