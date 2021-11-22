using System;
using System.Data;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
	/// <summary>
	/// Summary description for MediumTypeDetails.
	/// </summary>
    [Serializable]
    public class MediumTypeDetails
    {
        public string TypeName;
        public bool TwoSided; 
        public bool Container;
 
        public MediumTypeDetails()
        {
            TypeName = String.Empty;
            TwoSided = false;
            Container = false;
        }

        public MediumTypeDetails(IDataReader reader)
        {
            TypeName = reader.GetString(1);
            TwoSided = reader.GetBoolean(2);
            Container = reader.GetBoolean(3);
        }
    }
}
