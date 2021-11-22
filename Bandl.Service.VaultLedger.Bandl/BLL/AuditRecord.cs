using System;
using System.IO;
using System.Web;
using System.Text;
using Bandl.Service.VaultLedger.Bandl.Model;

namespace Bandl.Service.VaultLedger.Bandl.BLL
{
	/// <summary>
	/// Summary description for AuditRecord.
	/// </summary>
	public class AuditRecord
	{
        private static object lockObject = new object();

        private static string CreateDirectory(string directoryName)
        {
            // Get the current path name
            string filePath = HttpRuntime.AppDomainAppPath;
            if (!filePath.EndsWith(Path.DirectorySeparatorChar.ToString()))
            {
                filePath += Path.DirectorySeparatorChar.ToString();
            }
            // Append audit subdirectory and create if necessary
            filePath += "audits" + Path.DirectorySeparatorChar.ToString();
            if (!Directory.Exists(filePath))
            {
                Directory.CreateDirectory(filePath);
            }
            // Append the given directory name and create if necessary
            string[] fileNodes = directoryName.Split(new char[] {Path.DirectorySeparatorChar});
            foreach (string fileNode in fileNodes)
            {
                if (fileNode.Length != 0)
                {
                    filePath += String.Format("{0}{1}", fileNode, Path.DirectorySeparatorChar);
                    if (!Directory.Exists(filePath))
                    {
                        Directory.CreateDirectory(filePath);
                    }
                }
            }
            // Return the file path
            return filePath;
        }

        private static void WriteHeaders(StreamWriter streamWriter, AuditListXmitDetails.Actions actionType)
        {
            StringBuilder fileLine = new StringBuilder();
            // Write headers if new file
            fileLine.Append("Record Time\t");
            fileLine.Append("Account Type\t");
            fileLine.Append("Account Number\t");
            fileLine.Append("List Name\t");
            fileLine.Append("Action Time\t");
            fileLine.Append("#Items\t");
            fileLine.Append("Status\t");
            // File names and exceptions, exceptions only on sends
            if (actionType == AuditListXmitDetails.Actions.Receive)
                fileLine.Append("File Name or Exception\t");
            else
                fileLine.Append("Exception\t");
            // Write the headers
            streamWriter.WriteLine(fileLine.ToString());
        }

        public static void WriteListXmitRecord(AuditListXmitDetails auditRecord)
        {
            string fileName = null;
            DateTime currentTime = DateTime.Now;
            StringBuilder fileLine = new StringBuilder();
            // Create the record
            fileLine.AppendFormat(String.Format("{0}\t", currentTime.ToString("MM/dd/yyyy hh:mm:ss")));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.AccountType.ToString()));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.AccountNo));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.ListName));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.ActionTime.ToString("MM/dd/yyyy hh:mm:ss")));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.NumItems));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.Result.ToString()));
            fileLine.AppendFormat(String.Format("{0}\t", auditRecord.FileName));
            // Get the file name
            if (auditRecord.ActionType == AuditListXmitDetails.Actions.Send)
            {
                string appendPath = String.Format("xmits{0}send", Path.DirectorySeparatorChar);
                fileName = String.Format("{0}S{1}.txt", CreateDirectory(appendPath), currentTime.ToString("yyyyMMdd"));
            }
            else
            {
                string appendPath = String.Format("xmits{0}receive", Path.DirectorySeparatorChar);
                fileName = String.Format("{0}R{1}.txt", CreateDirectory(appendPath), currentTime.ToString("yyyyMMdd"));
            }

            lock (lockObject)
            {
                // Does the file exist?
                bool fileExists = File.Exists(fileName);
                // Write to the file
                using (StreamWriter streamWriter = new StreamWriter(fileName, true))
                {
                    // Write the headers if the file did not exist
                    if (fileExists == false)
                        WriteHeaders(streamWriter, auditRecord.ActionType);
                    // Write the audit record
                    streamWriter.WriteLine(fileLine.ToString());
                }
            }
        }
	}
}
