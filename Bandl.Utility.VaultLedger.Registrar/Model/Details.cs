using System;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
    // Enumeration for state of object data
    [Serializable]
    public enum ObjectStates {Unmodified = 0, New = 1, Modified = 2, Deleted = 3};

	/// <summary>
	/// Summary description for Details.
	/// </summary>
	public abstract class Details
	{
        private ObjectStates objState;

        public ObjectStates ObjState
        {
            get { return objState; }
            set { objState = value; }
        }
    }
}
