using System;
using System.IO;
using System.Web;
using System.Net.Mail;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Router;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for EmailServer.
	/// </summary>
	public class EmailServer
	{
        /// <summary>Gets the email server</summary>
        /// <param name="serverName">Name of the email server</param>
        /// <param name="eAddress">The 'from' address for sent emails</param>
        /// <returns>Email group</returns>
        public static void GetServer(ref string serverName, ref string eAddress)
        {
            if (Configurator.Router)
            {
                RouterDb.GetEmail(ref serverName, ref eAddress);
            }
            else
            {
                EmailServerFactory.Create().GetServer(ref serverName, ref eAddress);
            }
        }

        /// <summary>Updates the email server</summary>
        /// <param name="serverName">Name of the email server</param>
        /// <param name="eAddress">The 'from' address for sent emails</param>
        /// <returns>Email group</returns>
        public static void Update(string serverName, string eAddress)
        {
            if (Configurator.Router)
            {
                RouterDb.UpdateEmail(serverName, eAddress);
            }
            else
            {
                EmailServerFactory.Create().Update(serverName, eAddress);
            }
        }

        #region SendEmail() Overloads
        /// <summary>Sends an email</summary>
        public static void SendEmail(string[] recipients, string body)
        {
            SendEmail(Configurator.ProductName + " Email Alert", MailPriority.Normal, recipients, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(string recipient, string body)
        {
            SendEmail(Configurator.ProductName + " Email Alert", MailPriority.Normal, new string[] {recipient}, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(MailPriority priority, string[] recipients, string body)
        {
            SendEmail(Configurator.ProductName + " Email Alert", priority, recipients, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(MailPriority priority, string recipient, string body)
        {
            SendEmail(Configurator.ProductName + " Email Alert", priority, new string[] {recipient}, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(string subject, string[] recipients, string body)
        {
            SendEmail(subject, MailPriority.Normal, recipients, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(string subject, string recipient, string body)
        {
            SendEmail(subject, MailPriority.Normal, recipient, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(string subject, MailPriority priority, string recipient, string body)
        {
            SendEmail(subject, priority, new string[] {recipient}, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(string subject, MailPriority priority, string[] recipients, string body)
        {
            string sender = null;
            string serverName = null;
            GetServer(ref serverName, ref sender);
            SendEmail(serverName, sender, subject, priority, recipients, body);
        }
            
        /// <summary>Sends an email</summary>
        public static void SendEmail(string server, string sender, string subject, MailPriority priority, string recipient, string body)
        {
            SendEmail(server, sender, subject, priority, new string[] {recipient}, body);
        }

        /// <summary>Sends an email</summary>
        public static void SendEmail(string server, string sender, string subject, MailPriority priority, string[] recipients, string body)
        {
            // If no server name, just return
            if (server.Length == 0) return;

            MailMessage x1 = new MailMessage();
            x1.From = new MailAddress(sender);
            x1.Priority = priority;
            x1.IsBodyHtml = false;
            x1.Subject = subject;
            x1.Body = body;
            // Recipients
            foreach (String r1 in recipients) x1.To.Add(r1);
            // Send the message
            new SmtpClient(server).Send(x1);
        }
        #endregion
    }
}
