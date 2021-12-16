using System;
using System.Collections.Generic;
using System.Text;
using System.Web;
using System.Net;
using System.Net.Mail;
using System.Net.Mime;

namespace Bandl.Service.VaultLedger.Loader
{
	/// <summary>
	/// Summary description for Email.
	/// </summary>
	public class Email
	{
        public static void Send(String filename, String message)
        {
            try
            {
                var recipients = Configurator
                    .EmailRecipients
                    .Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);

                if (recipients.Length != 0)
                {
                    using (MailMessage mail = new MailMessage())
                    {
                        mail.From = new MailAddress("autoloader@na1.vaultledger.com", "VaultLedger AutoLoader");
                        mail.Priority = MailPriority.High;
                        mail.Subject = String.Format("{0} Autoloader Failure", Configurator.ProductName);
                        // Recipients
                        foreach (String recipient in recipients)
                            mail.To.Add(new MailAddress(recipient));
                        // Create message
                        mail.Body = String.Format("An error has occurred in processing the attached report:\r\n\r\n{0}", message);
                        mail.Attachments.Add(new Attachment(filename));
                        // Send the message
                        using (var s = new SmtpClient(Configurator.EmailServer))
                            s.Send(mail);
                    }
                }
            }
            catch (Exception e1)
            {
                Tracer.Trace("MAIL EXCEPTION:[" + filename + "]" + e1.Message);
            }
        }

        public static void Test(String server, String port, String uid, String pwd, String recipient, String family, String size)
        {
            try
            {
                using (MailMessage mail = new MailMessage())
                {
                    mail.To.Add(new MailAddress(recipient));
                    mail.From = new MailAddress("autoloader@vaultledger.net", "VaultLedger");
                    mail.Subject = "TEST EMAIL FROM VAULTLEDGER AUTOLOADER";
                    // Multipart/alternative Body
                    StringBuilder b1 = new StringBuilder();
                    b1.Append("This is a test email from VaultLedger Autoloader. You have received it successfully.");
                    mail.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(b1.ToString(), null, MediaTypeNames.Text.Plain));
                    mail.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(WrapHtml(b1, family, size), null, MediaTypeNames.Text.Html));
                    // SMTP Client
                    using (var s = new SmtpClient(server))
                    {
                        if (port != String.Empty)
                            s.Port = Convert.ToInt32(port);
                        // Credentials?
                        if (uid != String.Empty)
                            s.Credentials = new NetworkCredential(uid, pwd);
                        // Send
                        s.Send(mail);
                    }
                }
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
            if (String.IsNullOrWhiteSpace(size))
                size = "10pt";
            // Family
            if (String.IsNullOrWhiteSpace(family))
                family = "Verdana;Tahoma;Arial";
            // Format
            return String.Format("<html><div style=\"font-family:{0};font-size:{1}\">{2}</div></html>", family, size, html.ToString());
        }
    }
}
