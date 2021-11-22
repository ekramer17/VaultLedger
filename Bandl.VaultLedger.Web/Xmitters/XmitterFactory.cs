using System;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for XmitterFactory.
	/// </summary>
	public class XmitterFactory
	{
        public static IXmitter Create()
        {	
            // Recall only supports RECALLSERVICE transmission
            if (Configurator.ProductType == "RECALL" && Configurator.XmitMethod != "RECALLSERVICE")
            {
                throw new ApplicationException("Recall Corporation only supports information exchange through its web service");
            }
            // RECALLSERVICE transmission may only be performed by ReQuest Media Manager implementations
            else if (Configurator.ProductType != "RECALL" && Configurator.XmitMethod == "RECALLSERVICE")
            {
                throw new ApplicationException("Only systems of Recall type may exchange information through the Recall web service");
            }
            else
            {
                // Create the proper type of transmission object
                switch (Configurator.XmitMethod)
                {
                    case "RECALLSERVICE":
                        return new RecallService();
                    case "FTP":
                        return new FtpXmitter();
                    default:
                        return new BaseXmitter();
                }
            }
        }
	}
}
