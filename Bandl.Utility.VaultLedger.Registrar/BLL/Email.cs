using System;
using System.Text;
using System.Web.Mail;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.BLL
{
	/// <summary>
	/// Summary description for Email.
	/// </summary>
    public class Email
    {
        /// <summary>
        /// Sends an email to the client, providing him with login information
        /// </summary>
        /// <param name="o">
        /// Owner details object
        /// </param>
        /// <param name="login">
        /// Login that client will use to log in to ReQuest Media Manager
        /// </param>
        /// <param name="password">
        /// Password that client will use to log in to ReQuest Media Manager
        /// </param>
        /// <param name="subscriptionId">
        /// Subscription id used for client identification purposes
        /// </param>
        public static void SendClientEmail(OwnerDetails o, string login, string password)
        {
            try
            {
                MailMessage mailMessage = new MailMessage();
                mailMessage.From = Configurator.EmailFromAddress;
                mailMessage.Subject = Configurator.ProductName + " Registration";
                mailMessage.Priority = MailPriority.High;
                mailMessage.To = o.Email;
                // Construct the body
                StringBuilder s = new StringBuilder();
                s.AppendFormat("Welcome to {0}!", Configurator.ProductName);
                s.Append(Environment.NewLine);
                s.Append(Environment.NewLine);
                s.AppendFormat("To access {0}, please proceed to the application web site at ", Configurator.ProductName);
                s.Append(Configurator.ApplicationUrl);
                s.Append(", and log in using the following parameters:");
                s.Append(Environment.NewLine);
                s.Append(Environment.NewLine);
                s.AppendFormat("Login: {0}", login);
                s.Append(Environment.NewLine);
                s.AppendFormat("Password: {0}", password);
                s.Append(Environment.NewLine);
                s.Append(Environment.NewLine);
                s.Append("After logging in, you should change this usercode and password to something more meaningful.");
                s.Append(Environment.NewLine);
                s.Append(Environment.NewLine);
                s.AppendFormat("Your subscription number is: {0}", o.Subscription);
                s.Append(Environment.NewLine);
                s.Append(Environment.NewLine);
                s.Append("Please store this subscription id in a safe place.  You may need it later for identification purposes.  Should you lose it, you will be able to recover it using the email address provided.");
                mailMessage.Body = s.ToString();
                // Send the message
                SmtpMail.SmtpServer = Configurator.EmailServer;
                SmtpMail.Send(mailMessage);
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while sending email: " + e.Message);
            }
        }

        /// <summary>
        /// Sends a notification that a client has registered for ReQuest Media Manager
        /// </summary>
        /// <param name="o">
        /// The client that has registered
        /// </param>
        /// <param name="c">
        /// The application database that was created for the client
        /// </param>
        public static void SendNotification(OwnerDetails o, string serverName, string dbName, string login, string password)
        {
            MailMessage mailMessage = new MailMessage();
            mailMessage.From = Configurator.EmailFromAddress;
            mailMessage.To = Configurator.EmailNotifyAddress;
            mailMessage.Subject = String.Format("{0} Registration", Configurator.ProductName);
            mailMessage.Priority = MailPriority.High;
            // Construct the body
            StringBuilder s = new StringBuilder();
            s.AppendFormat("A potential client has registered for {0}.", Configurator.ProductName);
            s.Append(Environment.NewLine);
            s.Append(Environment.NewLine);
            s.AppendFormat("Company: {0}{1}", o.Company, Environment.NewLine);
            // Account number only if Recall
            if (Configurator.ProductType == "RECALL")
                s.AppendFormat("Account: {0}{1}", o.AccountNo, Environment.NewLine);
            // Contact, email, and phone for all
            s.AppendFormat("Contact: {0}{1}", o.Contact, Environment.NewLine);
            s.AppendFormat("Email: {0}{1}", o.Email, Environment.NewLine);
            s.AppendFormat("Phone: {0}{1}", o.PhoneNo, Environment.NewLine);
            s.Append(Environment.NewLine);
            s.AppendFormat("The setup information of the application instance created for this potential client is:{0}", Environment.NewLine);
            s.Append(Environment.NewLine);
            s.AppendFormat("Server: {0}{1}", serverName, Environment.NewLine);
            s.AppendFormat("Database: {0}{1}", dbName, Environment.NewLine);
            // Subscription, initial usercode and password to B&L
            if (Configurator.ProductType == "BANDL")
            {
                s.AppendFormat("Login: {0}{1}", login, Environment.NewLine);
                s.AppendFormat("Password: {0}{1}", password, Environment.NewLine);
                s.AppendFormat("Subscription: {0}{1}", o.Subscription, Environment.NewLine);
            }
            mailMessage.Body = s.ToString();
            // Send the message
            SmtpMail.SmtpServer = Configurator.EmailServer;
            SmtpMail.Send(mailMessage);
        }

        /// <summary>
        /// Sends an email to the given address
        /// </summary>
        /// <param name="address">
        /// Email address of client
        /// </param>
        /// <param name="body">
        /// Body of message
        /// </param>
        public static void TestMail(string address, string body)
        {
            try
            {
                MailMessage mailMessage = new MailMessage();
                mailMessage.From = Configurator.EmailFromAddress;
                mailMessage.Subject = String.Format("{0} Registration", Configurator.ProductName);
                mailMessage.Priority = MailPriority.Normal;
                mailMessage.To = address;
                // Construct the body
                mailMessage.Body = body;
                // Send the message
                SmtpMail.SmtpServer = Configurator.EmailServer;
                SmtpMail.Send(mailMessage);
            }
            catch (Exception e)
            {
                string s1 = "";
                Exception e1 = e;
                while (e1 != null) {s1 += e1.Message + ";"; e1 = e1.InnerException;}
                throw new ApplicationException("Error encountered while sending email: " + s1);
            }
        }
    }
}
