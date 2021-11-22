using System;
using System.IO;
using System.Web;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
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
                if (Configurator.Trace)
                {
                    using (StreamWriter w1 = new StreamWriter(Path.Combine(HttpRuntime.AppDomainAppPath, "trace.log"), true))
                    {
                        w1.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " : " + message);
                    }
                }
            }
            catch
            {
                ;
            }
        }

        public static void Trace(Exception e1)
        {
            try
            {
                if (Configurator.Trace)
                {
                    using (StreamWriter w1 = new StreamWriter(Path.Combine(HttpRuntime.AppDomainAppPath, "trace.log"), true))
                    {
                        w1.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " : " + e1.Message + "\r\n" + e1.StackTrace);
                    }
                }
            }
            catch
            {
                ;
            }
        }
    }
}
