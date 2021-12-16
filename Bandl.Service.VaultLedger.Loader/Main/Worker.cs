using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Windows.Forms;
using System.Threading;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Worker
    {
        private readonly Random _random = new Random(); 
        
        
        private bool stop;
        private readonly object queueLock = new object();
        private Queue<string> queue;
        private string _success;
        private string _failure;

        private const int MAX_ATTEMPTS = 5;
        private const int RETRY_PAUSE = 5000;  // milliseconds
        private static readonly string[] RETRY_EXCEPTIONS = new string[] {
            "timeout period elapsed",
            "being used by another process",
            "underlying connection was closed",
            "Login failed for user 'BLOperator'"
        };

        public Worker(string startupPath)
        {
            stop = false;
            queue = new Queue<string>();

            // Form names of Success and Failed directories
            _success = Path.Combine(startupPath, "Success");
            _failure = Path.Combine(startupPath, "Failure");

            // Create directories if they do not exist
            Directory.CreateDirectory(_success);
            Directory.CreateDirectory(_failure);

            // Get the initial set of files in directory
            foreach (string s in Directory.GetFiles(startupPath))
                Enqueue(s);
        }


        public void Enqueue(string filepath)
        {
            if (!Ignore(filepath))
            {
                lock (queueLock)
                {
                    queue.Enqueue(filepath);
                    Tracer.Trace("Enqueued: " + Path.GetFileName(filepath));
                }
            }
        }


        public void Stop()
        {
            stop = true;
        }


        public void Run()
        {
            string filepath;

            while (!stop)
            {
                // Anything in queue?
                if ((filepath = Dequeue()) == null)
                {
                    Thread.Sleep(5000);
                    continue;
                }

                Tracer.Trace("Dequeued: " + Path.GetFileName(filepath));

                // Get exclusive lock and process
                if (GetExclusiveLock(filepath))
                    ProcessFile(filepath);
            }

            Thread.CurrentThread.Abort();
        }


        private string Dequeue()
        {
            try
            {
                lock (queueLock)
                {
                    return queue.Dequeue();
                }
            }
            catch
            {
                return null;
            }
        }


        private bool Ignore(string filepath)
        {
            string name = Path.GetFileName(filepath).ToLower();
            
            if (Configurator.Ignores.Contains(name + ";"))
                return true;
            else
                return false;
        }


        private bool GetExclusiveLock(string filepath)
        {
            while (!stop)
            {
                try
                {
                    using (File.Open(filepath, FileMode.Open, FileAccess.Read, FileShare.None))
                    {
                        Tracer.Trace("Exclusive lock obtained: " + filepath);
                        return true;   // Do nothing; just checking lock to make sure transfer is complete
                    }
                }
                catch (FileNotFoundException)
                {
                    Tracer.Trace("File not found: " + filepath);
                    return false;
                }
                catch
                {
                    Thread.Sleep(1000);
                }
            }

            return false;
        }


        private void MoveFile(string source, bool success)
        {
            var time = DateTime.Now;
            var name = time.ToString("yyyyMMdd.HHmmss") + "." + Path.GetFileName(source);
            var target = Path.Combine((success ? _success : _failure), name);
    
            while (!stop)
            {
                try
                {
                    File.Move(source, target);
                    break;
                }
                catch
                {
                    GC.Collect();
                    Thread.Sleep(2000);
                }
            }
        }


        //private void MoveFile(String source, String target)
        //{
        //    while (!stop)
        //    {
        //        try
        //        {
        //            File.Move(source, target);
        //            break;
        //        }
        //        catch
        //        {
        //            GC.Collect();
        //            Thread.Sleep(2000);
        //        }
        //    }
        //}

        private bool ProcessFile(string path)
        {
            var attempt = 1;
            var name = Path.GetFileName(path);

            while (!stop)
            {
                var p = new Processor(path);

                try
                {
                    p.ProcessFile();
                    Logger.Write("SUCCESS : " + name);
                    MoveFile(path, true);
                    return true;
                }
                catch (Exception e)
                {
                    if (attempt < MAX_ATTEMPTS && RETRY_EXCEPTIONS.Any(s => e.Message.Contains(s)))
                    {
                        Logger.Write(String.Format("RETRY {0}: {1} : {2}", attempt, name, e.Message));
                        Thread.Sleep(RETRY_PAUSE);
                        attempt += 1;
                    }
                    else
                    {
                        Tracer.Trace(e);
                        Logger.Write("FAILED : " + name + " : " + e.Message);
                        // Trace
                        for (int i = 0; i < p.TraceMessages.Count; ++i)
                            Tracer.Trace(p.TraceMessages[i]);
                        // Email
                        Email.Send(path, e.Message);
                        // Move to failure directory
                        MoveFile(path, false);
                        return false;
                    }
                }
            }

            return false;
        }
    }
}
