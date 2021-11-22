using System;
using System.IO;
using System.Text;
using Bandl.Service.VaultLedger.Recall.Model;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
	/// <summary>
	/// Summary description for SendListFile.
	/// </summary>
	public class SendListFile : ActionListFile
	{
        public static string Write(RMMSendListDetails sendList)
        {
            string lastClient = String.Empty;
            string lastMediaCode = String.Empty;
            string lastDRPCode = "Ain't no way this is the DRP code";;
            string lastDescription = "Ain't no way this is the description";
            string lastReturnDate = String.Empty;
            string lastCreateDate = String.Empty;
            string returnDate;

            // Get the name of the file
            string fileName = GetFileName(ListType.Send, sendList.Account);
            // Open the new file
            try
            {
                using (StreamWriter sw = File.CreateText(fileName))
                {
                    // Write each item to the file
                    foreach(RMMSendItem item in sendList.Items)
                    {
                        StringBuilder sb = new StringBuilder();
                        // Client (Account)
                        if (lastClient != sendList.Account) 
                        {
                            sb.AppendFormat("%C{0}", sendList.Account.PadRight(5,' '));
                            lastClient = sendList.Account;
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
                        if (lastDRPCode != item.DrpCode) 
                        {
                            sb.AppendFormat("%P{0}", item.DrpCode);
                            lastDRPCode = item.DrpCode;
                        }
                        // Description
                        if (lastDescription != item.Description) 
                        {
                            string x = item.Description.Replace("\r",String.Empty).Replace("\n"," ");
                            sb.AppendFormat("%D{0}", x);
                            lastDescription = x;
                        }
                        // Return date
                        if (item.ReturnDate == String.Empty)
                            returnDate = "01/01/2999";
                        else
                            returnDate = Convert.ToDateTime(item.ReturnDate).ToString("MM/dd/yyyy");
                        if (lastReturnDate != returnDate) 
                        {
                            sb.AppendFormat("%E{0}", returnDate);
                            lastReturnDate = returnDate;
                        }
                        // Create date
                        if (lastCreateDate != sendList.CreateDate)  
                        {
                            sb.AppendFormat("%X{0}", Convert.ToDateTime(sendList.CreateDate).ToString("MM/dd/yyyy"));
                            lastCreateDate = sendList.CreateDate;
                        }
                        // Write the line
                        sw.WriteLine(sb.ToString());
                    }
                    // Write the quantity (number of tapes in the file)
                    sw.WriteLine(String.Format("%#{0}",sendList.Items.Length));
                }
                // Write the next number to a file
                WriteNextNumber(sendList.Account, fileName);
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
