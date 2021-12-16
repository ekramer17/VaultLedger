using System;
using System.IO;
using System.Threading;
using System.Windows.Forms;
using System.ServiceProcess;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Service1 : System.ServiceProcess.ServiceBase
    {
		private Worker myWorker = null;
		private Thread workerThread = null;
        private FileSystemWatcher myWatcher = null;

        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.Container components = null;

        public Service1()
        {
            // This call is required by the Windows.Forms Component Designer.
            InitializeComponent();
        }

        // The main entry point for the process
        static void Main()
        {
            string[] args = Environment.GetCommandLineArgs();

            if (args.Length > 1)
            {
                try
                {
                    if (args[1] == "/i")
                    {
                        Installer.Install();
                    }
                    else if (args[1] == "/u")
                    {
                        Installer.Uninstall();
                    }
                    else if (args[1] == "/p")
                    {
                        Configurator.Password = args[2];
                    }
                    else if (args[1] == "/t")
                    {
                        Email.Test("localhost", "", "P2399579\\usr221050", "jo2-Libx", "ekramer@bandl.com", "", "");
                    }
                }
                catch (Exception x1)
                {
                    MessageBox.Show(x1.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                }
            }
            else
            {
                ServiceBase.Run(new Service1());
            }
        }

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            this.ServiceName = "Service1";
        }

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        protected override void Dispose( bool disposing )
        {
            if( disposing )
            {
                if (components != null) 
                {
                    components.Dispose();
                }
            }
            base.Dispose( disposing );
        }

        /// <summary>
        /// Set things in motion so your service can do its work.
        /// </summary>
        protected override void OnStart(string[] args)
        {
			Tracer.Trace("SERVICE STARTING");

			// Create new worker
			myWorker = new Worker(Application.StartupPath);

			// Start worker on new thread
			ThreadStart st = new ThreadStart(myWorker.Run);
			workerThread = new Thread(st);
			workerThread.Start();

			// Create file watcher (must do after thread start)
			myWatcher = new FileSystemWatcher(Application.StartupPath);
			myWatcher.Created += new FileSystemEventHandler(OnCreated);
			myWatcher.EnableRaisingEvents = true;
		}

		/// <summary>
		/// Stop this service
		/// </summary>
		protected override void OnStop()
        {
			Tracer.Trace("SERVICE STOPPING");

			myWatcher.EnableRaisingEvents = false;
			myWorker.Stop();

			// Give a little time to finish any pending work
			workerThread.Join(new TimeSpan(0, 2, 0));

			Tracer.Trace("SERVICE STOPPED");
		}

		// Define the event handler
		private void OnCreated(object source, FileSystemEventArgs e)
        {
			myWorker.Enqueue(e.FullPath);
		}
    }
}
