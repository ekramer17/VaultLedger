using System;
using System.Web.SessionState;

namespace Bandl.Utility.VaultLedger.Registrar.BLL
{
    /// <summary>
	/// Summary description for IProcessObject.
	/// </summary>
	public interface IProcessObject
	{
        void Execute(HttpSessionState q);
    }
}
