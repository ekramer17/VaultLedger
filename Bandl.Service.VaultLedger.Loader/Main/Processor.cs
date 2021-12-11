using System;
using System.IO;
using System.Web;
using System.Net;
using System.Text;
using System.Collections.Generic;

namespace Bandl.Service.VaultLedger.Loader
{
    /// <summary>
    /// Summary description for Processor.
    /// </summary>
    public class Processor
    {
        private string myFile = null;
        private CookieContainer myCookies = new CookieContainer();

        public List<string> TraceMessages = new List<string>();

        // Constructor
        public Processor(string filename)
        {
            this.myFile = filename;
        }
        /// <summary>
        /// Takes the inner content of span tag, parses error
        /// </summary>
        /// <param name="s1">innerHTML of span tag</param>
        /// <returns></returns>
        private string ParseSpan(string s1)
        {
            int i1, i2;
            
            if ((i1 = s1.IndexOf("<font")) == -1)
            {
                return s1;
            }
            else
            {
                i1 = s1.IndexOf(">", i1) + 1;
                i2 = s1.IndexOf("</font>", i1);
                return s1.Substring(i1, i2 - i1);
            }
        }
		/// <summary>
		/// Creates requestm, attaches cookie and autoloader header
		/// </summary>
		/// <param name="url">request url</param>
		/// <returns></returns>
		private HttpWebRequest CreateRequest(string url)
		{
			HttpWebRequest q1 = (HttpWebRequest)WebRequest.Create(url);
			q1.Headers.Add("AutoLoader", "true");
			q1.CookieContainer = myCookies;
			return q1;
		}
        /// <summary>
        /// Logs in to the application
        /// </summary>
        private void DoLogin(string login, string password)
        {
			string url = Configurator.BaseUrl + "login.aspx";
			string view1 = null; // viewstate
            HttpWebResponse r1 = null;

            HttpWebRequest q1 = CreateRequest(url);

            using (r1 = (HttpWebResponse)q1.GetResponse())
            {
                using (StreamReader r2 = new StreamReader(r1.GetResponseStream()))
                {
                    string x1 = r2.ReadToEnd();
                    // Get the viewstate
                    x1 = x1.Substring(x1.IndexOf("__VIEWSTATE"));
                    x1 = x1.Substring(x1.IndexOf("value=") + 7);
                    view1 = x1.Substring(0, x1.IndexOf('"'));
                }
            }

            StringBuilder b1 = new StringBuilder();
			b1.Append("__VIEWSTATE=");
            b1.Append(HttpUtility.UrlEncode(view1));
            b1.Append("&txtLogin=");
            b1.Append(HttpUtility.UrlEncode(login));
            b1.Append("&txtPassword=");
            b1.Append(HttpUtility.UrlEncode(password));
            b1.Append("&btnAuthenticate=Login&javaTester=true&localTime=");
			string a1 = b1.ToString();

			q1 = CreateRequest(url);
            q1.Referer = url;
            q1.Method = "POST";
            q1.ContentType = "application/x-www-form-urlencoded";
            q1.ContentLength = Encoding.UTF8.GetBytes(a1).Length;
            using (StreamWriter w = new StreamWriter(q1.GetRequestStream())) w.Write(a1);

            // Get the response - check error
            using (r1 = (HttpWebResponse)q1.GetResponse())
            {
                using (StreamReader r2 = new StreamReader(r1.GetResponseStream()))
                {
                    int i1, i2;
                    string x1 = r2.ReadToEnd();

                    if ((i1 = x1.IndexOf("id=\"lblError2\"")) != -1)
                    {
                        // Boundaries
                        x1 = x1.Substring(i1);
                        i1 = x1.IndexOf(">") + 1;
                        i2 = x1.IndexOf("</span>", i1);
                        // Any error?
                        if (i2 != i1)
                        {
                            throw new ApplicationException(ParseSpan(x1.Substring(i1, i2 - i1)));
                        }
                    }
                }
            }
        }
        /// <summary>
        /// Uploads file to application
        /// </summary>
        public void ProcessFile()
        {
            byte[] f1 = null;   // file content
            string view1 = null;
            HttpWebResponse r1 = null;
            string url = Configurator.BaseUrl + "lists/new-list-tms-file.aspx?src=auto";
            string c1 = "--" + DateTime.Now.Ticks.ToString("x");

            TraceMessages.Clear();

            // Querystring for auto transmit?
            if (Configurator.AutoXmit != String.Empty)
                url += "&xmit=" + Configurator.AutoXmit;

			// Log in to application
			DoLogin(Configurator.Login, Configurator.Password);
            TraceMessages.Add("[DIAG]Logged in");

            // We've logged in, navigate to page
            HttpWebRequest q1 = CreateRequest(url);
            TraceMessages.Add("[DIAG]Request created");

            // Get the viewstate
            using (r1 = (HttpWebResponse)q1.GetResponse())
            {
                TraceMessages.Add("[DIAG]Response retrieved");
                using (StreamReader r2 = new StreamReader(r1.GetResponseStream()))
                {
                    TraceMessages.Add("[DIAG]Stream extracted");
                    string x1 = r2.ReadToEnd();
                    x1 = x1.Substring(x1.IndexOf("__VIEWSTATE"));
                    x1 = x1.Substring(x1.IndexOf("value=") + 7);
                    view1 = x1.Substring(0, x1.IndexOf('"'));
                }
            }

            // Post data header
            StringBuilder b1 = new StringBuilder();
            b1.Append("--");
            b1.Append(c1);
            b1.Append("\r\n");
            b1.Append("Content-Disposition: form-data; name=\"__VIEWSTATE\"");
            b1.Append("\r\n");
            b1.Append("\r\n");
            b1.Append(view1);
            b1.Append("\r\n");
            b1.Append("--");
            b1.Append(c1);
            b1.Append("\r\n");
            b1.Append("Content-Disposition: form-data; name=\"File1\"; filename=\"");
            b1.Append(this.myFile);
            b1.Append("\"");
            b1.Append("\r\n");
            b1.Append("Content-Type: text/plain");
            b1.Append("\r\n");
            b1.Append("\r\n");            

            // Post data trailer
            StringBuilder b2 = new StringBuilder();
            b2.Append("--");
            b2.Append(c1);
            b2.Append("\r\n");
            b2.Append("Content-Disposition: form-data; name=\"btnOK\"");
            b2.Append("\r\n");
            b2.Append("\r\n");
            b2.Append("OK");
            b2.Append("\r\n");
            b2.Append("--");
            b2.Append(c1);
            b2.Append("--");
            b2.Append("\r\n");

            byte[] y1 = Encoding.ASCII.GetBytes(b1.ToString());
            byte[] y2 = Encoding.ASCII.GetBytes(b2.ToString());

            TraceMessages.Add("[DIAG]Opening file");

            using (StreamReader x1 = new StreamReader(this.myFile))
            {
                TraceMessages.Add("[DIAG]Reading file");
                string x2 = x1.ReadToEnd();
                if (x2.Trim() == String.Empty) return;
                if (!x2.EndsWith("\r\n")) x2 += "\r\n";
                f1 = Encoding.ASCII.GetBytes(x2);
                TraceMessages.Add("[DIAG]File read");
            }

            q1 = CreateRequest(url);
            q1.ContentType = "multipart/form-data; boundary=" + c1;
            q1.Method = "POST";
            q1.Referer = url;
            q1.ContentLength = y1.Length + f1.Length + y2.Length;

            using (Stream s2 = q1.GetRequestStream())
            {
                // Write out our post header
                s2.Write(y1, 0, y1.Length);
                // Write out our file contents
                s2.Write(f1, 0, f1.Length);
                // Write out our post trailer
                s2.Write(y2, 0, y2.Length);
            }

            TraceMessages.Add("[DIAG]Request created");

            // Get the response - check error
            using (r1 = (HttpWebResponse)q1.GetResponse())
            {
                TraceMessages.Add("[DIAG]Response retrieved");
                using (StreamReader r2 = new StreamReader(r1.GetResponseStream()))
                {
                    TraceMessages.Add("[DIAG]Stream extracted");
                    int i1 = 0;
                    int i2 = 0;
                    string x1 = r2.ReadToEnd();

                    if ((i1 = x1.IndexOf("The following error(s) have occurred:")) != -1)
                    {
                        if (x1.IndexOf("No valid serial numbers were found in the report") == -1)
                        {
                            // Boundaries
                            x1 = x1.Substring(x1.IndexOf("<span", i1));
                            i1 = x1.IndexOf(">") + 1;
                            i2 = x1.IndexOf("</span>", i1);
                            // Any error?
                            if (i2 != i1)
                            {
                                string e1 = ParseSpan(x1.Substring(i1, i2 - i1));
                                if (e1.StartsWith("* ")) e1 = e1.Substring(2);
                                throw new ApplicationException(e1);
                            }
                        }
                    }
                }
            }

            TraceMessages.Add("[DIAG]Complete");
        }
    }
}
