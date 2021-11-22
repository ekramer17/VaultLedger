using System;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for FormatterFactory.
	/// </summary>
	public class FormatterFactory
	{
		public static IFormatter Create(FtpProfileDetails ftpProfile)
		{	
			switch (ftpProfile.Format)
			{
				case FtpProfileDetails.Formats.Recall:
					return new RecallFormatter();
				case FtpProfileDetails.Formats.VitalRecords:
					return new VRIFormatter();
                case FtpProfileDetails.Formats.IronMountain:
                    return new IronMountainFormatter();
                case FtpProfileDetails.Formats.DataSafe:
                    return new DataSafeFormatter();
                default:
					return null;
			}
		}
	}
}
