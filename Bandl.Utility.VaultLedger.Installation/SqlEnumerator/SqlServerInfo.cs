using System;
using System.Collections;
using System.Collections.Specialized;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Data;
using System.Data.OleDb;
using System.Text;

namespace Bandl.Utility.VaultLedger.Installation.SqlEnumerator
{
	/// <summary>
	/// Summary description for SqlServerInfo.
	/// </summary>
	public class SqlServerInfo
	{
		#region Fields
		private string oServerName;
		private string oInstanceName;
		private bool oIsClustered;
		private string oVersion;
		private int otcpPort;
		private string oNp;
		private string oRpc;
		private IPAddress oIP;
		private StringCollection oCatalogs;
		private string oUserId;
		private string oPassword;
		private bool oIntegratedSecurity = true;
		private int oTimeOut=2;
		#endregion

		#region Constructors
		/// <summary>
		/// Initializes a new instance of the <see cref="SqlServerInfo"/> class.
		/// </summary>
		private SqlServerInfo()
		{

		}

		/// <summary>
		/// Initializes a new instance of the <see cref="SqlServerInfo"/> class.
		/// </summary>
		/// <param name="ip">The ip.</param>
		/// <param name="info">The info.</param>
		public SqlServerInfo(IPAddress ip, byte[] info)
			: this(ip, System.Text.ASCIIEncoding.ASCII.GetString(info, 3, BitConverter.ToInt16(info, 1)))
		{ }

		/// <summary>
		/// Initializes a new instance of the <see cref="SqlServerInfo"/> class.
		/// </summary>
		/// <param name="ip">The ip address.</param>
		/// <param name="info">The info.</param>
		public SqlServerInfo(IPAddress ip, string info)
		{
			oIP = ip;
			string[] nvs = info.Split(';');
			for (int i = 0; i < nvs.Length; i += 2)
			{
				switch (nvs[i].ToLower())
				{
					case "servername":
						this.oServerName = nvs[i + 1];
						break;

					case "instancename":
						this.oInstanceName = nvs[i + 1];
						break;

					case "isclustered":
						this.oIsClustered = (nvs[i + 1].ToLower() == "yes");   //bool.Parse(nvs[i+1]);
						break;

					case "version":
						this.oVersion = nvs[i + 1];
						break;

					case "tcp":
						this.otcpPort = int.Parse(nvs[i + 1]);
						break;

					case "np":
						this.oNp = nvs[i + 1];
						break;

					case "rpc":
						this.oRpc = nvs[i + 1];
						break;

				}
			}
		}

		#endregion

		#region Public Properties

		/// <summary>
		/// Gets the IP address.
		/// </summary>
		/// <value>The address.</value>
		/// <remarks>Presently, this is not implemented and will always return null,</remarks>
		public IPAddress Address
		{
			get
			{
				return oIP;
			}
		}
		/// <summary>
		/// Gets the name of the server.
		/// </summary>
		/// <value>The name of the server.</value>
		public string ServerName
		{
			get
			{
				return oServerName;
			}
		}

		/// <summary>
		/// Gets the name of the instance.
		/// </summary>
		/// <value>The name of the instance.</value>
		public string InstanceName
		{
			get
			{
				return oInstanceName;
			}
		}
		/// <summary>
		/// Gets a value indicating whether this instance is clustered.
		/// </summary>
		/// <value>
		/// 	<see langword="true"/> if this instance is clustered; otherwise, <see langword="false"/>.
		/// </value>
		public bool IsClustered
		{
			get
			{
				return oIsClustered;
			}
		}
		/// <summary>
		/// Gets the version.
		/// </summary>
		/// <value>The version.</value>
		public string Version
		{
			get
			{
				return oVersion;
			}
		}
		/// <summary>
		/// Gets the TCP port.
		/// </summary>
		/// <value>The TCP port.</value>
		public int TcpPort
		{
			get
			{
				return otcpPort;
			}
		}
		/// <summary>
		/// Gets the named pipe.
		/// </summary>
		/// <value>The named pipe.</value>
		public string NamedPipe
		{
			get
			{
				return oNp;
			}
		}

		/// <summary>
		/// Gets the catalogs.
		/// </summary>
		/// <value>The catalogs.</value>
		public StringCollection Catalogs
		{
			get
			{
				if (oCatalogs == null)
				{
					oCatalogs = GetCatalogs();
				}
				return oCatalogs;
			}
		}

		/// <summary>
		/// Gets or sets the user id.
		/// </summary>
		/// <value>The user id.</value>
		public string UserId
		{
			get { return oUserId; }
			set
			{
				oUserId = value;
				oIntegratedSecurity = false;
			}
		}

		/// <summary>
		/// Gets or sets the password.
		/// </summary>
		/// <value>The password.</value>
		public string Password
		{
			get { return oPassword; }
			set
			{
				oPassword = value;
				oIntegratedSecurity = false;
			}
		}

		/// <summary>
		/// Gets or sets a value indicating whether [integrated security].
		/// </summary>
		/// <value>
		/// 	<see langword="true"/> if [integrated security]; otherwise, <see langword="false"/>.
		/// </value>
		public bool IntegratedSecurity
		{
			get { return oIntegratedSecurity; }
			set { oIntegratedSecurity = value; }
		}

		/// <summary>
		/// Gets or sets the time out.
		/// </summary>
		/// <value>The time out.</value>
		public int TimeOut
		{
			get { return oTimeOut; }
			set { oTimeOut = value; }
		}

		#endregion

		#region Public Methods
		/// <summary>
		/// Tests the connection.
		/// </summary>
		/// <returns></returns>
		public bool TestConnection()
		{
			OleDbConnection conn = this.GetConnection();
			bool success = false;
			try
			{
				conn.Open();
				conn.Close();
				success = true;
			}
			catch{}
			return success;				
		}


		/// <summary>
		/// Returns a <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>.
		/// </summary>
		/// <returns>
		/// A <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>.
		/// </returns>
		public override string ToString()
		{
			if (this.InstanceName == null || this.InstanceName == "MSSQLSERVER")
				return this.ServerName;
			else
				return this.ServerName + "\\" + this.InstanceName;
		}
		#endregion

		#region Private Methods
		private StringCollection GetCatalogs()
		{
			StringCollection catalogs = new StringCollection();

			try
			{
				OleDbConnection myConnection = this.GetConnection();
				myConnection.Open();
				DataTable schemaTable = myConnection.GetOleDbSchemaTable(OleDbSchemaGuid.Catalogs,
					null);
				myConnection.Close();
				foreach (DataRow dr in schemaTable.Rows)
				{
					catalogs.Add(dr[0] as string);
				}
			}
			catch
			{
				;//				System.Windows.Forms.MessageBox.Show(ex.Message);
			}
			return catalogs;
		}

		private OleDbConnection GetConnection()
		{
			string myConnString = this.IntegratedSecurity ?
				String.Format("Provider=SQLOLEDB;Data Source={0};Integrated Security=SSPI;Connect Timeout={1}", this, this.TimeOut)
				: String.Format("Provider=SQLOLEDB;Data Source={0};User Id={1};Password={2};Connect Timeout={3}",
				this, this.UserId, this.Password,this.TimeOut);

			return new OleDbConnection(myConnString);
		}

		#endregion

		#region Public Static Method - Seek
		/// <summary>
		/// Seeks SQL servers on this network.
		/// </summary>
		/// <returns>An array of SqlServerInfo objects describing Sql Servers on this network</returns>
		static public SqlServerInfo[] Seek()
		{
			Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);

			socket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.Broadcast, 1);
			socket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReceiveTimeout, 3000);

			//  For .Net v 2.0 it's a bit simpler
			//  socket.EnableBroadcast = true;	// for .Net v2.0
			//  socket.ReceiveTimeout = 3000;	// for .Net v2.0

			ArrayList servers = new ArrayList();
			try
			{
				byte[] msg = new byte[] { 0x02 };
				IPEndPoint ep = new IPEndPoint(IPAddress.Broadcast, 1434);
				socket.SendTo(msg, ep);

				int cnt = 0;
				byte[] bytBuffer = new byte[1024];
				do
				{
					cnt = socket.Receive(bytBuffer);
					// *** MODIFIED ************************************************
					string reply = ASCIIEncoding.ASCII.GetString(bytBuffer, 3, BitConverter.ToInt16(bytBuffer, 1));
					int p;
					int startIndex = 0;
					do 
					{
						p = reply.IndexOf(";;", startIndex);
						if (p > startIndex) 
						{
							servers.Add(new SqlServerInfo(null, reply.Substring(startIndex, p - startIndex)));
							startIndex = p + 2;
						}
					} while (p >= 0);
					socket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReceiveTimeout, 300);
				} while (cnt != 0);
				// ***************************************************
//					servers.Add(new SqlServerInfo(null, bytBuffer));
//					socket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReceiveTimeout, 300);
//				} while (cnt != 0);
			}
			catch (SocketException socex)
			{
				const int WSAETIMEDOUT = 10060;		// Connection timed out. 
				const int WSAEHOSTUNREACH = 10065;	// No route to host. 

				// Re-throw if it's not a timeout.
				if (socex.ErrorCode == WSAETIMEDOUT || socex.ErrorCode == WSAEHOSTUNREACH)
				{ 
					// DO nothing......
				}
				else
				{
					//					Console.WriteLine("{0} {1}", socex.ErrorCode, socex.Message);
					throw;
				}
			}
			finally
			{
				socket.Close();
			}

			// Copy from the untyped but expandable ArrayList, to a
			// type-safe but fixed array of SqlServerInfos.

			SqlServerInfo[] aServers = new SqlServerInfo[servers.Count];
			servers.CopyTo(aServers);
			return aServers;
		}
		#endregion

	}
}
