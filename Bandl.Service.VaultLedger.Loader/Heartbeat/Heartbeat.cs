using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Heartbeat
{
    public class Heartbeat
    {
        private Boolean go = true;

        public Heartbeat() { }

        public void Run()
        {
            while (go)
            {
                try
                {
                    foreach (var s in ServiceController.GetServices().Where(s => s.ServiceName.StartsWith("VaultLedger Autoloader")))
                    {
                        if (s.Status == ServiceControllerStatus.Stopped)
                        {
                            new ServiceController(s.ServiceName).Start();
                        }
                    }

                    Thread.Sleep(600000);   // Sleep ten minutes
                }
                catch
                {
                    ;
                }

            }
        }

        public void Stop()
        {
            go = false;
        }
    }
}
