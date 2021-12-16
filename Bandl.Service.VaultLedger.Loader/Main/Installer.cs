using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

namespace Bandl.Service.VaultLedger.Loader
{
    internal class Installer
    {
		private static string _name = "VaultLedger Autoloader" + Configurator.Suffix;

		public Installer() { }

		#region Installation Methods
		/// <summary>
		/// Installs the service
		/// </summary>
		public static bool Install()
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
			if (IntPtr.Zero == (serviceHandle = Win32.CreateService(managerHandle, _name, _name, Win32.SERVICE_ALL_ACCESS, Win32.SERVICE_WIN32_OWN_PROCESS | Win32.SERVICE_INTERACTIVE_PROCESS, Win32.SERVICE_AUTO_START, Win32.SERVICE_ERROR_NORMAL, p1, null, 0, null, null, null)))
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
				Start();
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
		private static bool Start()
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
		private static bool Stop()
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
			switch (serviceStatus.currentState)
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
		public static bool Uninstall()
		{
			IntPtr managerHandle = IntPtr.Zero;
			IntPtr serviceHandle = IntPtr.Zero;
			Int64 e1 = 0;

			// Stop service
			if (!Stop()) return false;
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
