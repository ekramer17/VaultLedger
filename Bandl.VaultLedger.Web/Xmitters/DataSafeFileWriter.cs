using System;
using System.IO;
using System.Text;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;

namespace Bandl.Library.VaultLedger.Xmitters
{
    public class DataSafeFileWriter : BaseFileWriter, IFileWriter
    {
        public DataSafeFileWriter() : base() { }

        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="sl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(SendListDetails sl)
        {
            Int32 i1 = ActionListFactory.Create().GetListFileNumber(Vendors.DataSafe);
            return String.Format("P_{0}_{1}_{2}.txt", sl.Account, DateTime.Now.ToString("yyyyMMdd"), i1);
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="rl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(ReceiveListDetails rl)
        {
            Int32 i1 = ActionListFactory.Create().GetListFileNumber(Vendors.DataSafe);
            return String.Format("D_{0}_{1}_{2}.txt", rl.Account, DateTime.Now.ToString("yyyyMMdd"), i1);
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="dl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(DisasterCodeListDetails dl)
        {
            Int32 i1 = ActionListFactory.Create().GetListFileNumber(Vendors.DataSafe);
            return String.Format("X_{0}_{1}_{2}.txt", dl.Account, DateTime.Now.ToString("yyyyMMdd"), i1);
        }
        /// <summary>
        /// Sets the next file name
        public override void SetNextFileName(SendListDetails sl, string fileName)
        {
            String s1 = fileName.Substring(fileName.LastIndexOf('_') + 1);
            Int32 i1 = Int32.Parse(s1.Substring(0, s1.IndexOf('.')));
            // Update the letter in the database
            ActionListFactory.Create().SetListFileNumber(Vendors.DataSafe, i1 + 1);
        }

        /// <summary>
        /// Sets the next file name
        public override void SetNextFileName(ReceiveListDetails rl, string fileName)
        {
            String s1 = fileName.Substring(fileName.LastIndexOf('_') + 1);
            Int32 i1 = Int32.Parse(s1.Substring(0, s1.IndexOf('.')));
            // Update the letter in the database
            ActionListFactory.Create().SetListFileNumber(Vendors.DataSafe, i1 + 1);
        }

        /// <summary>
        /// Sets the next file name
        public override void SetNextFileName(DisasterCodeListDetails dl, string fileName)
        {
            String s1 = fileName.Substring(fileName.LastIndexOf('_') + 1);
            Int32 i1 = Int32.Parse(s1.Substring(0, s1.IndexOf('.')));
            // Update the letter in the database
            ActionListFactory.Create().SetListFileNumber(Vendors.DataSafe, i1 + 1);
        }
    }
}