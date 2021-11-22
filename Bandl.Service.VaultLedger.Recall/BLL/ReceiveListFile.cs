using System;
using System.IO;
using System.Text;
using Bandl.Service.VaultLedger.Recall.Model;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
    /// <summary>
    /// Summary description for ReceiveListFile.
    /// </summary>
    public class ReceiveListFile : ActionListFile
    {
        public static string Write(RMMReceiveListDetails receiveList)
        {
            string lastClient = String.Empty;
            string lastMediaCode = String.Empty;
            // Get the name of the file
            string fileName = GetFileName(ListType.Receive, receiveList.Account);
            // Open the new file
            try
            {
                using (StreamWriter sw = File.CreateText(fileName))
                {
                    // Write each item to the file
                    foreach(RMMReceiveItem item in receiveList.Items)
                    {
                        StringBuilder sb = new StringBuilder();
                        // Client (Account)
                        if (lastClient != receiveList.Account) 
                        {
                            sb.AppendFormat("%C{0}", receiveList.Account.PadRight(5,' '));
                            lastClient = receiveList.Account;
                        }
                        // Media code
                        if (lastMediaCode != item.MediaCode) 
                        {
                            sb.AppendFormat("%M{0}", item.MediaCode);
                            lastMediaCode = item.MediaCode;
                        }
                        // Serial number (will always be different)
                        sb.AppendFormat("%V{0}", item.SerialNo);
                        // Write the line
                        sw.WriteLine(sb.ToString());
                    }
                    // Write the quantity (number of tapes in the file)
                    sw.WriteLine(String.Format("%#{0}",receiveList.Items.Length));
                }
                // Write the next number to a file
                WriteNextNumber(receiveList.Account, fileName);
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
