using System;
using System.IO;
using System.Text;
using Bandl.Service.VaultLedger.Recall.Model;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
    /// <summary>
    /// Summary description for DisasterCodeListFile.
    /// </summary>
    public class DisasterCodeListFile : ActionListFile
    {
        public static string Write(RMMDisasterCodeListDetails disasterList)
        {
            string lastClient = String.Empty;
            string lastMediaCode = String.Empty;
            string lastDisasterCode = String.Empty;
            // Get the name of the file
            string fileName = GetFileName(ListType.DisasterCode, disasterList.Account);
            // Open the new file
            try
            {
                using (StreamWriter sw = File.CreateText(fileName))
                {
                    // Write each item to the file
                    foreach(RMMDisasterCodeItem item in disasterList.Items)
                    {
                        StringBuilder sb = new StringBuilder();
                        // Client (Account)
                        if (lastClient != disasterList.Account) 
                        {
                            sb.AppendFormat("%C{0}", disasterList.Account.PadRight(5,' '));
                            lastClient = disasterList.Account;
                        }
                        // Media code
                        if (lastMediaCode != item.MediaCode) 
                        {
                            sb.AppendFormat("%M{0}", item.MediaCode);
                            lastMediaCode = item.MediaCode;
                        }
                        // Serial number (will always be different)
                        sb.AppendFormat("%V{0}", item.SerialNo);
                        // Disaster code
                        if (lastDisasterCode != item.DrpCode) 
                        {
                            sb.AppendFormat("%P{0}", item.DrpCode);
                            lastDisasterCode = item.DrpCode;
                        }
                        // Write the line
                        sw.WriteLine(sb.ToString());
                    }
                    // Write the quantity (number of tapes in the file)
                    sw.WriteLine(String.Format("%#{0}",disasterList.Items.Length));
                }
                // Write the next number to a file
                WriteNextNumber(disasterList.Account, fileName);
                // Return the file name
                return fileName;
            }
            catch
            {
                File.Delete(fileName);
                throw;
            }
        }
    }
}
