using System;
using System.Data;
using System.IO;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
    public enum LicenseTypes
    {
        Operators = 1,
        Media = 2,
        Days = 3,
        RFID = 7,
		Autoloader = 8
}

    /// <summary>
    /// Summary description for ProductLicenseDetails.
    /// </summary>
	[Serializable]
	public class ProductLicenseDetails
	{
		// License types aren't enumerated because the enumeration is serialized as
		// starting at zero, where our licenses start at 1.  So we'll just use the 
		// integer value until we feel the need to write custom serialization code:
		//
		// 1: Operators
		// 2: Media
		// 3: Days
		// 4: Reserved for Bandl service password
		// 5: Reserved for Recall service password
		// 6: Reserved for number of failures
		// 7: RFID
		// 8: List autoloader service
		public int Units;
		public int LicenseType;
		public DateTime IssueDate;
		public DateTime ExpireDate;

		public ProductLicenseDetails() {}

		public ProductLicenseDetails(int licenseType, int units, DateTime expireDate) 
		{
			// Verify that we have a legal license type
			try
			{
				LicenseTypes l = (LicenseTypes)Enum.ToObject(typeof(LicenseTypes), licenseType);
			}
			catch
			{
				throw new ArgumentException("Unknown license type");
			}
			// Set the fields
			Units = units;
			IssueDate = DateTime.Today;
			ExpireDate = expireDate;
			LicenseType = licenseType;
		}

		public ProductLicenseDetails(int licenseType, int units, DateTime issueDate, DateTime expireDate) 
		{
			// Verify that we have a legal license type
			try
			{
				LicenseTypes l = (LicenseTypes)Enum.ToObject(typeof(LicenseTypes), licenseType);
			}
			catch
			{
				throw new ArgumentException("Unknown license type");
			}
			// Set the fields
			Units = units;
			IssueDate = issueDate;
			ExpireDate = expireDate;
			LicenseType = licenseType;
		}

		public ProductLicenseDetails(IDataReader reader)
		{
			LicenseType = reader.GetInt32(0);
			Units = reader.GetInt32(1);
			IssueDate = reader.GetDateTime(2);
			ExpireDate = reader.GetDateTime(3);
			// Verify that we have a legal license type
			try
			{
				LicenseTypes l = (LicenseTypes)Enum.ToObject(typeof(LicenseTypes), LicenseType);
			}
			catch
			{
				throw new ApplicationException("Unknown license type");
			}
		}

		public static ProductLicenseDetails DoDefault(int licenseType) 
		{
			switch (licenseType)
			{
				case 7:
				case 8:
					return new ProductLicenseDetails(licenseType, 0, new DateTime(9999, 1, 1));
				default:
					return null;
			}
		}
	}
}
