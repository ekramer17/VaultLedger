using System;
using System.IO;
using System.Web;
using System.Reflection;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    public class Tracer
    {
        /// <summary>
        /// Trace flag -- change to true and recompile to enable tracing
        /// </summary>
        private static bool b1 = false;
        private static String f1 = null;
        private static readonly Object o1 = new Object();

        static Tracer()
        {
            f1 = Uri.UnescapeDataString(new UriBuilder(Assembly.GetExecutingAssembly().CodeBase).Path);
            f1 = Path.Combine(Path.GetDirectoryName(f1), "dbupdater.log");
        }

        public static void Trace(String message)
        {
            if (b1)
            {
                lock (o1)
                {
                    try
                    {
                        using (StreamWriter w = new StreamWriter(f1, true))
                        {
                            w.WriteLine(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " : " + message);
                        }
                    }
                    catch
                    {
                        ;
                    }
                }
            }
        }

        public static void Trace(Exception e1)
        {
            Tracer.Trace(e1.Message + " :: " + e1.StackTrace);
        }
    }
}
