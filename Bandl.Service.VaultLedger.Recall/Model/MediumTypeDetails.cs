using System;

namespace Bandl.Service.VaultLedger.Recall.Model
{
	/// <summary>
	/// Summary description for MediumTypeDetails.
	/// </summary>
	[Serializable]
	public class MediumTypeDetails
	{
        public string TypeName;
        public string RecallCode;
        public bool Container;
        public bool TwoSided;

        public MediumTypeDetails() {}

        public MediumTypeDetails(string _typeName, string _recallCode, int _sideContainer)
        {
            TypeName = _typeName;
            RecallCode = _recallCode;
            switch (_sideContainer)
            {
                case 1:
                    Container = false;
                    TwoSided = false;
                    break;
                case 2:
                    Container = false;
                    TwoSided = true;
                    break;
                case 3:
                    Container = true;
                    TwoSided = false;
                    break;
                default:
                    throw new ApplicationException("Invalid side/container value");
            }
        }
    }
}
