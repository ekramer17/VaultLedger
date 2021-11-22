using System;
using System.IO;
using System.Web;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for TextLogger.
	/// </summary>
	public class MessageLogger
	{
        private string fileName;
        private static object oLock = new object();

        public MessageLogger() {fileName = Path.Combine(HttpRuntime.AppDomainAppPath, "vaultLedger.log");}

		public void Log(string message)
		{
            if (Configurator.Trace)
                lock (oLock)
                    using (StreamWriter w = new StreamWriter(fileName, true))
                        w.WriteLine(DateTime.UtcNow.ToString("yyyy-MM-dd hh:mm:ss.fff") + ": " + message);
		}
	}
}
