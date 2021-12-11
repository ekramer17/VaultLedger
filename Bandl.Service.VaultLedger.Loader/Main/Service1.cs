using System;
using System.Threading;
using System.Reflection;
using System.Windows.Forms;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Service1 : System.ServiceProcess.ServiceBase
    {
		private const int TIMER_INTERVAL = 60000;
        private static string _name = "VaultLedger Autoloader" + Configurator.Suffix;
		private System.Timers.Timer _timer;
		private Worker _worker = null;

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
            string[] c1 = Environment.GetCommandLineArgs();

            if (c1.Length > 1)
            {
                try
                {
                    if (c1[1] == "/i")
                    {
                        new MyInstaller().DoInstall();
                        // Display success message box
                        MessageBox.Show("Service installed successfully", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else if (c1[1] == "/u")
                    {
                        new MyInstaller().DoUninstall();
                        // Display success message box
                        MessageBox.Show("Service uninstalled successfully", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else if (c1[1] == "/p")
                    {
                        Configurator.Password = c1[2];
                        // Display success message box
                        MessageBox.Show("Password encrypted successfully", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else if (c1[1] == "/t")
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
                System.ServiceProcess.ServiceBase[] ServicesToRun;
                ServicesToRun = new System.ServiceProcess.ServiceBase[] { new Service1() };
                System.ServiceProcess.ServiceBase.Run(ServicesToRun);
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
			// Create worker
			_worker = new Worker(Application.StartupPath);

			// Initialize and start timer
			_timer = new System.Timers.Timer(1000);
			_timer.Elapsed += new System.Timers.ElapsedEventHandler(OnTimerEvent);
			_timer.AutoReset = false;
			_timer.Start();

			Tracer.Trace("SERVICE STARTED");
		}

		/// <summary>
		/// Stop this service
		/// </summary>
		protected override void OnStop()
		{
			_timer.Stop();
			_worker.Stop();

			while (_worker.IsWorking)
				Thread.Sleep(5000);

			Tracer.Trace("SERVICE STOPPED");
		}


		protected void OnTimerEvent(object source, System.Timers.ElapsedEventArgs e)
		{
			Tracer.Trace("TIMER EVENT SIGNALLED");
			// Stop timer
			_timer.Stop();
			Tracer.Trace("Timer stopped");

			// Work through uploaded files
			try
			{
				_worker.ProcessFiles();
				Tracer.Trace("Files processed (if any present)");
			}
			catch (Exception ex)
			{
				Tracer.Trace("Exception caught in timer event handler");
				Tracer.Trace(ex);
			}
			finally
			{
				// Set timer to wake up after specified interval
				_timer.Interval = TIMER_INTERVAL;
				_timer.Start();
				Tracer.Trace("Timer restarted");
			}
		}


		private class MyInstaller
        {
            public MyInstaller() {}

            #region Installation Methods
			/// <summary>
			/// Installs the service
			/// </summary>
			public bool DoInstall()
			{
				IntPtr managerHandle = IntPtr.Zero;
				IntPtr serviceHandle = IntPtr.Zero;
				Int64 e = 0;

				// Open control manager
				if (IntPtr.Zero == (managerHandle = Win32.OpenSCManager(null, null, Win32.SC_MANAGER_ALL_ACCESS))) 
				{
					throw new ApplicationException("Unable to open service control manager");
				}
				else
				{
					Console.WriteLine("--> Service manager opened");
				}
				// Get the service handle
				serviceHandle = Win32.CreateService(managerHandle,
													_name,
													_name,
													Win32.SERVICE_ALL_ACCESS,
													Win32.SERVICE_WIN32_OWN_PROCESS | Win32.SERVICE_INTERACTIVE_PROCESS,
													Win32.SERVICE_AUTO_START,
													Win32.SERVICE_ERROR_NORMAL,
													Assembly.GetExecutingAssembly().GetFiles()[0].Name,
													null,
													0,
													null,
													null,
													null);
				// Open the service
				if (serviceHandle == IntPtr.Zero) 
				{
					if ((e = Win32.GetLastError()) != Win32.ERROR_SERVICE_EXISTS)
					{
						Win32.CloseServiceHandle(managerHandle);
						Console.WriteLine("--> Service already exists");
						return true;
					}
					else 
					{
						Win32.CloseServiceHandle(managerHandle);
						throw new ApplicationException("An error occurred during service install: " + e.ToString());
					}
				}
				else
				{
					Console.WriteLine("--> Service handle acquired");
				}
				// Add description
				Win32.SERVICE_DESCRIPTION x1;
				x1.description = "Automatically detects new lists and uploads them to VaultLedger";
				Win32.ChangeServiceConfig2(serviceHandle, Win32.SERVICE_CONFIG_DESCRIPTION, ref x1);
				Console.WriteLine("--> Service description added");
				// Close handles
				Win32.CloseServiceHandle(serviceHandle);
				Win32.CloseServiceHandle(managerHandle);
				// Attempt to start
				try
				{
					DoStart();
					Console.WriteLine("--> Service started");
				}
				catch
				{
					Console.WriteLine("--> Unable to start service");
				}
				// Success
				Console.WriteLine("--> Service installed successfully");
				// Return
				return true;
			}
			/// <summary>
			/// Starts the service
			/// </summary>
			private bool DoStart()
			{
				Win32.SERVICE_STATUS serviceStatus;
				IntPtr managerHandle = IntPtr.Zero;
				IntPtr serviceHandle = IntPtr.Zero;

				if (IntPtr.Zero == (managerHandle = Win32.OpenSCManager(null, null, Win32.SC_MANAGER_ALL_ACCESS))) 
				{
					return false;
				}
				// Open the service
				if (IntPtr.Zero == (serviceHandle = Win32.OpenService(managerHandle, _name, Win32.SERVICE_QUERY_STATUS | Win32.SERVICE_START)))
				{
					Win32.CloseServiceHandle(managerHandle);
					return false;
				}
				// Query the service status and start it if not already running
				if (0 == Win32.QueryServiceStatus(serviceHandle, out serviceStatus))
				{
					Win32.CloseServiceHandle(serviceHandle);
					Win32.CloseServiceHandle(managerHandle);
					return false;
				}
				else if (serviceStatus.currentState != Win32.SERVICE_STOPPED)   // already running
				{
					Win32.CloseServiceHandle(serviceHandle);
					Win32.CloseServiceHandle(managerHandle);
					return true;
				}
				else if (0 == Win32.StartService(serviceHandle, 0, null))
				{
					Win32.CloseServiceHandle(serviceHandle);
					Win32.CloseServiceHandle(managerHandle);
					return false;
				}
				else
				{
					Win32.CloseServiceHandle(serviceHandle);
					Win32.CloseServiceHandle(managerHandle);
					return true;
				}
			}
			/// <summary>
			/// Stops the service
			/// </summary>
			private bool DoStop()
			{
				Int64 e1 = 0;
				Win32.SERVICE_STATUS serviceStatus;
				IntPtr managerHandle = IntPtr.Zero;
				IntPtr serviceHandle = IntPtr.Zero;

				if (IntPtr.Zero == (managerHandle = Win32.OpenSCManager(null, null, Win32.SC_MANAGER_ALL_ACCESS))) 
				{
					return false;
				}
				// Open the service
				if (IntPtr.Zero == (serviceHandle = Win32.OpenService(managerHandle, _name, Win32.SERVICE_QUERY_STATUS | Win32.SERVICE_STOP)))
				{
					if ((e1 = Win32.GetLastError()) == Win32.ERROR_SERVICE_DOES_NOT_EXIST)
					{
						Win32.CloseServiceHandle(managerHandle);
						return true;
					}
					else 
					{
						Win32.CloseServiceHandle(managerHandle);
						throw new ApplicationException("An error occurred during service stop attempt: " + e1.ToString());
					}
				}
				// Query the service status
				if (0 == Win32.QueryServiceStatus(serviceHandle, out serviceStatus))
				{
					Win32.CloseServiceHandle(serviceHandle);
					Win32.CloseServiceHandle(managerHandle);
					return false;
				}
				// Check the status of the service
				switch(serviceStatus.currentState)
				{
					case Win32.SERVICE_STOP_PENDING:
						break;
					case Win32.SERVICE_STOPPED:
						Win32.CloseServiceHandle(serviceHandle);
						Win32.CloseServiceHandle(managerHandle);
						return true;
					default:
						if (0 == Win32.ControlService(serviceHandle, Win32.SERVICE_CONTROL_STOP, out serviceStatus))
						{
							Win32.CloseServiceHandle(serviceHandle);
							Win32.CloseServiceHandle(managerHandle);
							return false;
						}
						else
						{
							Console.WriteLine("--> Stopping service");
							break;
						}
				}
				// Get timeout boundary
				DateTime t1 = DateTime.Now.AddSeconds(20);
				// Wait while serice is pending stop
				while (serviceStatus.currentState != Win32.SERVICE_STOPPED)
				{
					// Sleep for half a second
					Thread.Sleep(500);
					// Query the service status
					if (0 == Win32.QueryServiceStatus(serviceHandle, out serviceStatus))
					{
						Win32.CloseServiceHandle(serviceHandle);
						Win32.CloseServiceHandle(managerHandle);
						return false;
					}
					else if (DateTime.Now > t1)  // 20 second timeout
					{
						throw new ApplicationException("Timeout occurred while attempting to stop the service");
					}
				}
				// Close handles
				Win32.CloseServiceHandle(serviceHandle);
				Win32.CloseServiceHandle(managerHandle);
				// Success
				Console.WriteLine("--> Service stopped");
				// Return
				return true;
			}
			/// <summary>
			/// Uninstalls the service
			/// </summary>
			public bool DoUninstall()
			{
				IntPtr managerHandle = IntPtr.Zero;
				IntPtr serviceHandle = IntPtr.Zero;
				Int64 e = 0;

				// Stop service
				if (!DoStop()) return false;
				// Open control manager
				if (IntPtr.Zero == (managerHandle = Win32.OpenSCManager(null, null, Win32.SC_MANAGER_ALL_ACCESS))) 
				{
					throw new ApplicationException("Unable to open service control manager");
				}
				else
				{
					Console.WriteLine("--> Service manager opened");
				}
				// Open service
				if (IntPtr.Zero == (serviceHandle = Win32.OpenService(managerHandle, _name, Win32.SERVICE_ALL_ACCESS))) 
				{
					if ((e = Win32.GetLastError()) == Win32.ERROR_SERVICE_DOES_NOT_EXIST)
					{
						Win32.CloseServiceHandle(managerHandle);
						return true;
					}
					else 
					{
						Win32.CloseServiceHandle(managerHandle);
						throw new ApplicationException("An error occurred during service uninstall: " + e.ToString());
					}
				}
				else
				{
					Console.WriteLine("--> Service handle acquired");
				}
				// Delete service
				if (0 == Win32.DeleteService(serviceHandle)) 
				{
					if ((e = Win32.GetLastError()) == Win32.ERROR_SERVICE_MARKED_FOR_DELETE)
					{
						Console.WriteLine("Service previously marked for deletion");
						Win32.CloseServiceHandle(serviceHandle);
						Win32.CloseServiceHandle(managerHandle);
						return true;
					}
					else
					{
						Win32.CloseServiceHandle(serviceHandle);
						Win32.CloseServiceHandle(managerHandle);
						throw new ApplicationException("An error occurred during service uninstall: " + e.ToString());
					}
				}
				else
				{
					Console.WriteLine("--> Service deleted");
				}
				// Close handles
				Win32.CloseServiceHandle(serviceHandle);
				Win32.CloseServiceHandle(managerHandle);
				// Success
				Console.WriteLine("--> Service uninstalled successfully");
				// Return
				return true;
			}
			#endregion
        }
    }
}
