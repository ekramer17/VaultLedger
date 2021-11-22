using System;
using System.IO;
using System.Text;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for RecallFormatter.
	/// </summary>
	public class RecallFileWriter : BaseFileWriter, IFileWriter
	{
        public RecallFileWriter() : base() {}

		#region Private Methods
		/// <summary>
		/// Gets what should be the name of the file to be written
		/// </summary>
		/// <param name="listType">
		/// Type of list to write to file
		/// </param>
		/// <param name="accountNo">
		/// Account of the list
		/// </param>
		/// <returns>
		/// Name of the file
		/// </returns>
        private string GetFileName(ListTypes listType, string accountNo)
        {
            // Get the disaster code list numbers
            int sendNo = 0, receiveNo = 0, disasterNo = 0;
            FtpProfileFactory.Create().GetRecallNumbers(accountNo, out sendNo, out receiveNo, out disasterNo);
            // Discern the first character if the filename based on list type
            switch (listType) 
            {
                case ListTypes.Send:
                    return String.Format("R{0}{1}.fil", accountNo, sendNo);
                case ListTypes.Receive:
                    return String.Format("P{0}{1}.fil", accountNo, receiveNo);
                case ListTypes.DisasterCode:
                    return String.Format("D{0}{1}.fil", accountNo, disasterNo);
                default:
                    throw new ApplicationException("Unable to determine file name");
            }
        }
		/// <summary>
		/// Sets the last file number
		/// </summary>
		/// <param name="accountNo">
		/// Number of the account of the list written to fileName
		/// </param>
		/// <param name="fileName">
		/// Name of the last file written
		/// </param>
		private void SetNextFileNumber(string accountNo, string fileName)
		{
            int sendNo = 0, receiveNo = 0, disasterNo = 0;
            IFtpProfile ftp = FtpProfileFactory.Create();
            // Get the disaster code list numbers
            ftp.GetRecallNumbers(accountNo, out sendNo, out receiveNo, out disasterNo);
            // Get the first character
            string c1 = fileName[0].ToString();
            // Strip everything but the file number
            int fileNo = Int32.Parse(fileName.Replace(".fil", String.Empty).Replace(String.Format("{0}{1}", c1, accountNo), String.Empty));
            fileNo = fileNo >= 99 ? 0 : fileNo + 1;
            // Alter the appropriate number
            switch (c1) 
            {
                case "R":
                    sendNo = fileNo;
                    break;
                case "P":
                    receiveNo = fileNo;
                    break;
                case "D":
                    disasterNo = fileNo;
                    break;
                default:
                    throw new ApplicationException("Unable to determine file name");
            }
            // Update the number
            ftp.SetRecallNumbers(accountNo, sendNo, receiveNo, disasterNo);
		}

		#endregion
		
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="sl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(SendListDetails sl) 
        {
            return GetFileName(ListTypes.Send, sl.Account);
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="rl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(ReceiveListDetails rl)
        {
            return GetFileName(ListTypes.Receive, rl.Account);
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="dl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(DisasterCodeListDetails dl)
        {
            return GetFileName(ListTypes.DisasterCode, dl.Account);
        }
        /// <summary>
		/// Sets the next file name for a send list
		/// </summary>
		/// <param name="sendList">
		/// Send list written to file that was just transmitted
		/// </param>
		/// <param name="fileName">
		/// Name of the file that was just transmitted
		/// </param>
		public override void SetNextFileName(SendListDetails sendList, string fileName)
		{
			this.SetNextFileNumber(sendList.Account, fileName);
		}
		/// <summary>
		/// Sets the next file name for a receive list
		/// </summary>
		/// <param name="receiveList">
		/// Receive list written to file that was just transmitted
		/// </param>
		/// <param name="fileName">
		/// Name of the file that was just transmitted
		/// </param>
		public override void SetNextFileName(ReceiveListDetails receiveList, string fileName)
		{
			this.SetNextFileNumber(receiveList.Account, fileName);
		}
		/// <summary>
		/// Sets the next file name for a disaster code list
		/// </summary>
		/// <param name="disasterList">
		/// Disaster code list written to file that was just transmitted
		/// </param>
		/// <param name="fileName">
		/// Name of the file that was just transmitted
		/// </param>
		public override void SetNextFileName(DisasterCodeListDetails disasterList, string fileName)
		{
			this.SetNextFileNumber(disasterList.Account, fileName);
		}
	}
}
