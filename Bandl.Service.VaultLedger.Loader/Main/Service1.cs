using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Reflection;
using System.ComponentModel;
using System.Text.RegularExpressions;
using System.Diagnostics;
using System.Windows.Forms;
using System.ServiceProcess;
using System.Runtime.InteropServices;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Service1 : System.ServiceProcess.ServiceBase
    {
        private static string myName = "VaultLedger Autoloader" + Configurator.Suffix;
        private FileSystemWatcher myWatcher = null;
		private Worker myWorker = null;
		private Thread workerThread = null;
		//private string d1 = null;
		//private string d2 = null;

		//private const int MAX_RETRIES = 5;
		//private const int RETRY_PAUSE = 20000;  // milliseconds
		//private static readonly string[] RETRY_EXCEPTIONS = new string[] {
		//    "timeout period elapsed",
		//    "being used by another process",
		//    "underlying connection was closed",
		//    "Login failed for user 'BLOperator'"
		//};

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
                        //MessageBox.Show("Service installed successfully", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else if (c1[1] == "/u")
                    {
                        new MyInstaller().DoUninstall();
                        // Display success message box
                        //MessageBox.Show("Service uninstalled successfully", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else if (c1[1] == "/p")
                    {
                        Configurator.Password = c1[2];
                        // Display success message box
                        //MessageBox.Show("Password encrypted successfully", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
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

			//// Form names of Processed and Failed directories
			//d1 = Path.Combine(Application.StartupPath, "Success");
			//d2 = Path.Combine(Application.StartupPath, "Failure");

			//// Create the Processed and Failed directories
			//Directory.CreateDirectory(d1);
			//Directory.CreateDirectory(d2);

			// Process any files already in directory
			//foreach (string s1 in Directory.GetFiles(Application.StartupPath))
			//{
			//	DoFile(s1);
			//}
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

		// Define the event handlers
		private void OnCreated(object source, FileSystemEventArgs e)
        {
			myWorker.Enqueue(e.FullPath);
            //DoFile(Directory.GetFiles(Application.StartupPath, e.Name)[0]);
		}

		//// Process file
		//private void DoFile(string s1)
		//{
  //          String s2 = s1.Substring(s1.LastIndexOf('\\') + 1);

  //          // Process file?
  //          if (!Configurator.Ignores.Contains(s2.ToLower() + ";"))
  //          {
  //              int retry_number = 0;

  //              while (true)
  //              {
  //                  // Make sure we can get an exclusive lock on the file
  //                  try
  //                  {
  //                      using (File.Open(s1, FileMode.Open, FileAccess.Read, FileShare.None))
  //                      {
  //                          ;   // Do nothing; just checking lock to make sure transfer is complete
  //                      }
  //                  }
  //                  catch (FileNotFoundException)
  //                  {
  //                      Tracer.Trace("FILE NOT FOUND: " + s1);
  //                      break;
  //                  }
  //                  catch (Exception e)
  //                  {
  //                      Tracer.Trace(e);
  //                      Thread.Sleep(RETRY_PAUSE);
  //                  }

  //                  DateTime n1 = DateTime.Now;
  //                  Processor p1 = new Processor(s1);
  //                  String x1 = String.Format("{0}.{1}.{2}", n1.ToString("yyyyMMdd"), n1.ToString("HHmmss"), s2);

  //                  // Process
  //                  try
  //                  {
  //                      p1.ProcessFile();
  //                      Logger.Write("SUCCESS : " + s2);
  //                      MoveFile(s1, Path.Combine(d1, x1));
  //                      break;
  //                  }
  //                  catch (Exception e)
  //                  {
  //                      if (++retry_number <= MAX_RETRIES && RETRY_EXCEPTIONS.Any(s => e.Message.Contains(s)))
  //                      {
  //                          Logger.Write(String.Format("RETRY {0}: {1} : {2}", retry_number, s2, e.Message));
  //                          Thread.Sleep(RETRY_PAUSE);
  //                      }
  //                      else
  //                      {
  //                          Tracer.Trace(e);
  //                          Logger.Write("FAILED : " + s2 + " : " + e.Message);
  //                          for (int i = 0; i < p1.TraceMessages.Count; ++i)
  //                              Tracer.Trace(p1.TraceMessages[i]);
  //                          Email.Send(s1, e.Message);
  //                          MoveFile(s1, Path.Combine(d2, x1));
  //                          break;
  //                      }
  //                  }
  //              }
		//	}
		//}

  //      private void MoveFile(String s1, String t1)
  //      {
  //          while (true)
  //          {
  //              try
  //              {
  //                  File.Move(s1, t1);
  //                  break;
  //              }
  //              catch
  //              {
  //                  GC.Collect();
  //                  Thread.Sleep(3000);
  //              }
  //          }
  //      }

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
				String p1 = Assembly.GetExecutingAssembly().GetFiles()[0].Name;
				Int64 e1 = 0;

				// Open control manager
				if (IntPtr.Zero == (managerHandle = Win32.OpenSCManager(null, null, Win32.SC_MANAGER_ALL_ACCESS))) 
				{
					throw new ApplicationException("Unable to open service control manager");
				}
				else
				{
					Console.WriteLine("--> Service manager opened");
				}
				// Open the service
				if (IntPtr.Zero == (serviceHandle = Win32.CreateService(managerHandle, myName, myName, Win32.SERVICE_ALL_ACCESS, Win32.SERVICE_WIN32_OWN_PROCESS | Win32.SERVICE_INTERACTIVE_PROCESS, Win32.SERVICE_AUTO_START, Win32.SERVICE_ERROR_NORMAL, p1, null, 0, null, null, null)))
				{
					if ((e1 = Win32.GetLastError()) != Win32.ERROR_SERVICE_EXISTS)
					{
						Win32.CloseServiceHandle(managerHandle);
						Console.WriteLine("--> Service already exists");
						return true;
					}
					else 
					{
						Win32.CloseServiceHandle(managerHandle);
						throw new ApplicationException("An error occurred during service install: " + e1.ToString());
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
				if (IntPtr.Zero == (serviceHandle = Win32.OpenService(managerHandle, myName, Win32.SERVICE_QUERY_STATUS | Win32.SERVICE_START)))
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
				if (IntPtr.Zero == (serviceHandle = Win32.OpenService(managerHandle, myName, Win32.SERVICE_QUERY_STATUS | Win32.SERVICE_STOP)))
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
					System.Threading.Thread.Sleep(500);
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
				Int64 e1 = 0;

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
				if (IntPtr.Zero == (serviceHandle = Win32.OpenService(managerHandle, myName, Win32.SERVICE_ALL_ACCESS))) 
				{
					if ((e1 = Win32.GetLastError()) == Win32.ERROR_SERVICE_DOES_NOT_EXIST)
					{
						Win32.CloseServiceHandle(managerHandle);
						return true;
					}
					else 
					{
						Win32.CloseServiceHandle(managerHandle);
						throw new ApplicationException("An error occurred during service uninstall: " + e1.ToString());
					}
				}
				else
				{
					Console.WriteLine("--> Service handle acquired");
				}
				// Delete service
				if (0 == Win32.DeleteService(serviceHandle)) 
				{
					if ((e1 = Win32.GetLastError()) == Win32.ERROR_SERVICE_MARKED_FOR_DELETE)
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
						throw new ApplicationException("An error occurred during service uninstall: " + e1.ToString());
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
