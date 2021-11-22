using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.Net.Mail;
using System.Net.Mime;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
    internal class Mailer
    {
        public static void SendOverdueListAlert(ListTypes listType, String[] listNames, String recipients)
        {
            StringBuilder text = new StringBuilder();
            StringBuilder html = new StringBuilder();
            // List type
            String typeString = listType == ListTypes.Send ? "Shipping" : (listType == ListTypes.Receive ? "Receiving" : "Disaster Code");
            // Create text body
            text.AppendLine("This is an alert regarding overdue " + typeString.ToUpper() + " lists.");
            text.AppendLine(String.Empty);
            text.AppendLine(String.Empty);
            text.AppendLine("The following " + listNames.Length.ToString() + " list(s) have not yet been processed and are currently overdue:");
            text.AppendLine(String.Empty);
            foreach(String n in listNames)
                text.AppendLine("-->  " + n);
            text.AppendLine(String.Empty);
            text.AppendLine("Please attend to these lists at your earliest convenience.  Thank you!");
            text.AppendLine(String.Empty);
            text.AppendLine(String.Empty);
            text.AppendLine("Regards,");
            text.AppendLine("VaultLedger");
            // Create html body
            html.Append("<h2>This is an alert regarding overdue " + typeString.ToUpper() + " lists.</h2>");
            html.Append("<p>The following " + listNames.Length.ToString() + " list(s) have not yet been processed and are currently overdue:</p>");
            html.Append("<p><ul>");
            foreach (String n in listNames)
                html.AppendLine("<li>" + n + "</li>");
            html.Append("</ul></p>");
            html.Append("<p>Please attend to these lists at your earliest convenience.  Thank you!</p>");
            html.Append("<p>Regards,<br />VaultLedger</p>");
            // Send message
            Mailer.Send(recipients, "VaultLedger Overdue List Alert", text.ToString(), WrapHtml(html));
        }

        #region P R I V A T E   S T A T I C   M E T H O D S
        private static void Send(String recipients, String subject, String text, String html)
        {
            Send(recipients, subject, text, html, MailPriority.Normal);
        }

        private static void Send(String recipients, String subject, String text, String html, MailPriority priority)
        {
            try
            {
                SmtpClient smtp = null;
                // Message
                MailMessage mail = new MailMessage();
                mail.From = new MailAddress(Configurator.EmailSender, "VaultLedger");
                mail.Priority = priority;
                mail.Subject = subject;
                // Recipients
                foreach (String recipient in recipients.Split(new char[] { ';' }))
                {
                    mail.To.Add(new MailAddress(recipient));
                }
                // Multipart/alternative Body
                if (text != null) mail.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(text, null, MediaTypeNames.Text.Plain));
                if (html != null) mail.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(html, null, MediaTypeNames.Text.Html));
                // SMTP Client
                if (Configurator.EmailServer.IndexOf(',') == -1)
                {
                    smtp = new SmtpClient(Configurator.EmailServer);
                }
                else
                {
                    String[] server = Configurator.EmailServer.Split(new char[] { ',' });
                    smtp = new SmtpClient(server[0], Convert.ToInt32(server[1]));
                }
                // Credentials?
                if (Configurator.EmailLogin != String.Empty)
                {
                    smtp.Credentials = new NetworkCredential(Configurator.EmailLogin, Configurator.EmailPassword);
                }
                // Send
                smtp.Send(mail);
            }
            catch (Exception abc1)
            {
                throw abc1.GetBaseException();
            }
        }

        private static String WrapHtml(StringBuilder html)
        {
            return WrapHtml(html, null, null);
        }

        private static String WrapHtml(StringBuilder html, String family, String size)
        {
            // Size
            if (String.IsNullOrEmpty(size))
                size = Configurator.EmailFontSize;
            // Family
            if (String.IsNullOrEmpty(family))
                family = Configurator.EmailFontFamily;
            // Format
            return String.Format("<html><div style=\"font-family:{0};font-size:{1}\">{2}</div></html>", family, size, html.ToString());
        }
        #endregion
    }
}
