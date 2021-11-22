using System;
using System.Configuration;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
	/// <summary>
	/// Summary description for Configurator.
	/// </summary>
	public class Configurator
	{
        public static int OperatorUnits
        {
            get 
            {
                return Convert.ToInt32(ConfigurationSettings.AppSettings["operatorUnits"]);
            }
        }

        public static int MediumUnits
        {
            get 
            {
                return Convert.ToInt32(ConfigurationSettings.AppSettings["mediumUnits"]);
            }
        }

        public static int DaysUnits
        {
            get 
            {
                return Convert.ToInt32(ConfigurationSettings.AppSettings["daysUnits"]);
            }
        }

        public static void GetHelpParameters(int accountType, ref string engine, ref string project, ref string window)
        {
            // Help parameters depend on account type
            switch (accountType)
            {
                case 1: // Recall
                    engine  = ConfigurationSettings.AppSettings["RecallHelpEngine"];
                    project = ConfigurationSettings.AppSettings["RecallHelpProject"];
                    window  = ConfigurationSettings.AppSettings["RecallHelpWindow"];
                    break;
                default:
                    engine  = ConfigurationSettings.AppSettings["BandlHelpEngine"];
                    project = ConfigurationSettings.AppSettings["BandlHelpProject"];
                    window  = ConfigurationSettings.AppSettings["BandlHelpWindow"];
                    break;
            }
        }
    }
}
