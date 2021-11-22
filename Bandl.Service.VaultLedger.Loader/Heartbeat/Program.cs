using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

namespace Heartbeat
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main()
        {
            String[] s = Environment.GetCommandLineArgs();

            if (s.Length > 1)
            {
                if (s[1] == "/i")
                {
                    Installer.DoInstall();
                }
                else if (s[1] == "/u")
                {
                    Installer.DoUninstall();
                }
            }
            else
            {
                ServiceBase[] ServicesToRun;
                ServicesToRun = new ServiceBase[] { new Service1() };
                ServiceBase.Run(ServicesToRun);
            }
        }
    }
}
