﻿using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace Bandl.Service.VaultLedger.Loader
{
    public class Worker
    {
        private string _app_path;
        private string _success = null;
        private string _failure = null;
        
        private bool _go = true;
        private bool _working = false;

        private const int MAX_ATTEMPTS = 5;
        private const int RETRY_PAUSE = 10000;  // milliseconds

        private static readonly string[] RETRY_EXCEPTIONS = new string[] {
            "timeout period elapsed",
            "being used by another process",
            "underlying connection was closed",
            "Login failed for user 'BLOperator'"
        };

        public Worker(string app_path)
        {
            _app_path = app_path;
            _success = Path.Combine(app_path, "Success");
            _failure = Path.Combine(app_path, "Failure");
            Directory.CreateDirectory(_success);
            Directory.CreateDirectory(_failure);
        }

        public void Stop()
        {
            _go = false;
        }

        public bool IsWorking
        {
            get { return _working; }
        }

        private bool GetExclusiveLock(string path)
        {
            // Make sure we can get an exclusive lock on the file
            try
            {
                using (File.Open(path, FileMode.Open, FileAccess.Read, FileShare.None))
                {
                    return true;   // just checking lock to make sure transfer is complete
                }
            }
            catch (FileNotFoundException)
            {
                Tracer.Trace("File not found: " + path);
                return false;
            }
            catch
            {
                // No reason to retry if we're polling -- will retry automatically on next iteration
                Tracer.Trace("Currently unable to obtain exclusive lock on: " + path);
                return false;
            }

            //DateTime start = DateTime.Now;
            //// Grab exclusive lock on file
            //while (true)
            //{
            //    // Make sure we can get an exclusive lock on the file
            //    try
            //    {
            //        using (File.Open(path, FileMode.Open, FileAccess.Read, FileShare.None))
            //        {
            //            return true;   // just checking lock to make sure transfer is complete
            //        }
            //    }
            //    catch (FileNotFoundException)
            //    {
            //        Tracer.Trace("File not found: " + path);
            //        return false;
            //    }
            //    catch
            //    {
            //        if (DateTime.Now - start < TimeSpan.FromMinutes(5))
            //        {
            //            Thread.Sleep(5000);
            //        }
            //        else
            //        {
            //            Tracer.Trace("Unable to obtain exclusive lock on: " + path);
            //            return false;
            //        }
            //    }
            //}
        }

        public void ProcessFiles()
        {
            // Set working flag
            _working = true;

            // Get the file list
            var files = Directory.GetFiles(_app_path);

            // Process each file in list
            for (int i = 0; i < files.Length; ++i)
            {
                var full_path = files[i];
                var file_name = full_path.Substring(full_path.LastIndexOf('\\') + 1);

                // Keep going?
                if (_go == false) break;

                // If file in list of ignores, remove it and go to next file
                if (Configurator.Ignores.Contains(file_name, StringComparer.OrdinalIgnoreCase))
                {
                    continue;
                }

                // Verify that we can get an exclusive lock on the file
                if (GetExclusiveLock(full_path) == false)
                {
                    continue;
                }

                // Create a new file processor
                var attempt = 1;
                var time = DateTime.Now;
                var processor = new Processor(full_path);
                var processed_name = String.Format("{0}.{1}.{2}", time.ToString("yyyyMMdd"), time.ToString("hhMMss"), file_name);

                while (true)
                {
                    try
                    {
                        
                        if (_go == false) break;    // Check flag; if stopping no need to retry

                        processor.ProcessFile();
                        Logger.Write("SUCCESS : " + file_name);
                        MoveFile(full_path, Path.Combine(_success, processed_name));
                        break;
                    }
                    catch (Exception e)
                    {
                        if (attempt < MAX_ATTEMPTS && RETRY_EXCEPTIONS.Any(s => e.Message.Contains(s)))
                        {
                            Logger.Write(String.Format("ATTEMPT : {0} : {1}", file_name, e.Message));
                            Thread.Sleep(RETRY_PAUSE);
                            attempt += 1;
                        }
                        else
                        {
                            Tracer.Trace(e);
                            Logger.Write("FAILURE : " + file_name + " : " + e.Message);
                            // Write processor trace messages
                            foreach (var message in processor.TraceMessages)
                                Tracer.Trace(message);
                            // Send email
                            Email.Send(full_path, e.Message);
                            // Move file to failure folder
                            MoveFile(full_path, Path.Combine(_failure, processed_name));
                            // Break loop
                            break;
                        }
                    }
                }
            }

            // Reset working flag
            _working = false;
        }

        private void MoveFile(String s1, String t1)
        {
            while (true)
            {
                try
                {
                    File.Move(s1, t1);
                    break;
                }
                catch
                {
                    GC.Collect();
                    Thread.Sleep(3000);
                }
            }
        }
    }
}