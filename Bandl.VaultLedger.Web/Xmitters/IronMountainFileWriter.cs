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
    public class IronMountainFileWriter : BaseFileWriter, IFileWriter
    {
        public IronMountainFileWriter() : base() {}

        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="sl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(SendListDetails sl)
        {
            string c = ActionListFactory.Create().GetListFileChar(ListTypes.Send, Vendors.IronMountain);
            return String.Format("{0}_{1}_{2}.IM", sl.Account, c, DateTime.UtcNow.ToString("yyyyMMddHHmm"));
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="rl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(ReceiveListDetails rl)
        {
            string c = ActionListFactory.Create().GetListFileChar(ListTypes.Receive, Vendors.IronMountain);
            return String.Format("{0}_{1}_{2}.IM", rl.Account, c, DateTime.UtcNow.ToString("yyyyMMddHHmm"));
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="dl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(DisasterCodeListDetails dl)
        {
            string c = ActionListFactory.Create().GetListFileChar(ListTypes.DisasterCode, Vendors.IronMountain);
            return String.Format("{0}_{1}_{2}.IM", dl.Account, c, DateTime.UtcNow.ToString("yyyyMMddHHmm"));
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
            // Get the character just before the last underscore
            char c = fileName[fileName.LastIndexOf('_') - 1];
            // Set the next letter
            c = (c == 'Z' ? 'A' : (char)((int)c + 1));
            // Update the letter in the database
            ActionListFactory.Create().UpdateListFileChar(ListTypes.Send, Vendors.IronMountain, c);
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
            // Get the character just before the last underscore
            char c = fileName[fileName.LastIndexOf('_') - 1];
            // Set the next letter
            c = (c == 'Z' ? 'A' : (char)((int)c + 1));
            // Update the letter in the database
            ActionListFactory.Create().UpdateListFileChar(ListTypes.Receive, Vendors.IronMountain, c);
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
            // Get the character just before the last underscore
            char c = fileName[fileName.LastIndexOf('_') - 1];
            // Set the next letter
            c = (c == 'Z' ? 'A' : (char)((int)c + 1));
            // Update the letter in the database
            ActionListFactory.Create().UpdateListFileChar(ListTypes.DisasterCode, Vendors.IronMountain, c);
        }
    }
}
