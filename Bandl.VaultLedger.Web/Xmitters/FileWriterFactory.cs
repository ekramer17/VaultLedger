using System;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for FileWriterFactory.
	/// </summary>
	public class FileWriterFactory
	{
		public static IFileWriter Create(FtpProfileDetails ftpProfile)
		{	
			switch (ftpProfile.Format)
			{
				case FtpProfileDetails.Formats.Recall:
					return new RecallFileWriter();
				case FtpProfileDetails.Formats.VitalRecords:
					return new VRIFileWriter();
                case FtpProfileDetails.Formats.IronMountain:
                    return new IronMountainFileWriter();
                case FtpProfileDetails.Formats.DataSafe:
                    return new DataSafeFileWriter();
                default:
					return null;
			}
		}
	}
}
