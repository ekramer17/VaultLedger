using System;
using System.IO;
using System.Web;
using System.Collections;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for Tracer.
	/// </summary>
	public class Tracer
	{
		public static void Trace(string message)
		{
            try
            {
                using (StreamWriter w1 = new StreamWriter(Path.Combine(HttpRuntime.AppDomainAppPath, "trace.log"), true))
                {
                    w1.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " : " + message);
                }
            }
            catch
            {
                ;
            }
		}
	}
}
