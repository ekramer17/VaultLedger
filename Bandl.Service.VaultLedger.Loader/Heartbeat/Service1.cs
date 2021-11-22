using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Threading;

namespace Heartbeat
{
    public partial class Service1 : ServiceBase
    {
        private Heartbeat heartbeat;
        private Thread thread;

        public Service1()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            heartbeat = new Heartbeat();
            thread = new Thread(new ThreadStart(heartbeat.Run));
            thread.Start();
        }

        protected override void OnStop()
        {
            if (heartbeat != null)
            {
                heartbeat.Stop();
            }

            if (thread != null)
            {
                try
                {
                    thread.Interrupt();
                }
                finally
                {
                    thread.Join();
                }
            }
        }
    }
}
