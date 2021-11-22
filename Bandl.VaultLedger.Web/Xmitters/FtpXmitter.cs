using System;
using Rebex.Net;
using System.IO;
using System.Text;
using Renci.SshNet;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;

namespace Bandl.Library.VaultLedger.Xmitters
{
    /// <summary>
    /// Summary description for FTP.
    /// </summary>
    public class FtpXmitter : BaseXmitter, IXmitter
    {
        public FtpXmitter() {}

        /// <summary>
        /// Retrieves the ftp profile to be used for transmission
        /// </summary>
        /// <param name="accountNo">
        /// Account number for which to retrieve profile
        /// </param>
        private FtpProfileDetails RetrieveProfile(string accountNo)
        {
            // Get the profile
            FtpProfileDetails x = FtpProfileFactory.Create().GetProfileByAccount(accountNo);
            // If no profile, throw an exception
            if (x == null)
                throw new ApplicationException("Account " + accountNo + " does not have an FTP profile associated with it.");
            // Return the profile
            return x;
        }
        
        /// <summary>
        /// Method that instantiates and FTP object and uses it to actually transmit the file
        /// </summary>
        /// <param name="fileName">
        /// File to transmit via FTP
        /// </param>
        private void TransmitFile(FtpProfileDetails ftpProfile, Stream fileStream, string fileName)
        {
            if (ftpProfile == null)
            {
                throw new ApplicationException("Cannot transmit file when FTP profile object is null.");
            }
            else if (ftpProfile.Secure)
            {
                TransmitSFTP(ftpProfile, fileStream, fileName);
            }
            else
            {
                TransmitFTP(ftpProfile, fileStream, fileName);
            }
        }

        /// <summary>
        /// Method that instantiates and FTP object and uses it to actually transmit the file
        /// </summary>
        /// <param name="fileName">
        /// File to transmit via FTP
        /// </param>
        private void TransmitSFTP(FtpProfileDetails ftpProfile, Stream fileStream, string fileName)
        {
            using (SftpClient c = new SftpClient(ftpProfile.Server, 22, ftpProfile.Login, ftpProfile.Password))
            {
                c.Connect();
                // Change directory?
                if (ftpProfile.FilePath != "" && ftpProfile.FilePath != "/")
                {
                    string remoteDir = ftpProfile.FilePath;
                    if (remoteDir.EndsWith("/"))
                        remoteDir = remoteDir.Substring(0, remoteDir.Length - 1);
                    c.ChangeDirectory(remoteDir);
                }
                // Upload
                c.BufferSize = 4 * 1024;
                c.UploadFile(fileStream, fileName);
            }
        }

        /// <summary>
        /// Method that instantiates and FTP object and uses it to actually transmit the file
        /// </summary>
        /// <param name="fileName">
        /// File to transmit via FTP
        /// </param>
        private void TransmitFTP(FtpProfileDetails ftpProfile, Stream fileStream, string fileName)
        {
            try
            {
                // Connect to the ftp server, login, and set the transfer type
                Rebex.Net.Ftp ftpObject = new Rebex.Net.Ftp();
                ftpObject.Connect(ftpProfile.Server);
                ftpObject.Login(ftpProfile.Login, ftpProfile.Password);
                ftpObject.SetTransferType(FtpTransferType.Ascii);
                ftpObject.Passive = ftpProfile.Passive;
                // Change directories
                if (ftpProfile.FilePath == "/")
                {
                    ; // Do nothing
                }
                else if (ftpProfile.FilePath.EndsWith("/") == false)
                {
                    ftpObject.ChangeDirectory(ftpProfile.FilePath);
                }
                else
                {
                    ftpObject.ChangeDirectory(ftpProfile.FilePath.Substring(0, ftpProfile.FilePath.Length - 1));
                }
                // Put the file on the remote system
                ftpObject.PutFile(fileStream, fileName);
                // Disconnect from ftp server
                ftpObject.Disconnect();
            }
            catch (FtpException ex)
            {
                throw new ApplicationException(String.Format("[{0}]{1}", ex.Status.ToString(), ex.Message), ex);
            }
        }

        /// <summary>
        /// Transmits a send list
        /// </summary>
        /// <param name="sendList">
        /// Discrete send list to transmit
        /// </param>
        public override void Transmit(SendListDetails sl)
        {
            if (sl.IsComposite)
            {
                throw new ApplicationException("Transmitter cannot transmit a composite list");
            }
            else
            {
                // Retrieve the ftp profile
                FtpProfileDetails ftp = this.RetrieveProfile(sl.Account);
                // Create the formatter and file writer objects
                IFileWriter fileObject = FileWriterFactory.Create(ftp);
                IFormatter formatObject = FormatterFactory.Create(ftp);
                // Hand over to formatter, which will format the list and return a string.  The
                // string will be the future contents of the file.
                string fileContents = formatObject.Format(sl);
                // Lock the transmitter
                if (this.GrabLock(this.NormalTimeout) == false)
                {
                    throw new ApplicationException("Unable to obtain list transmission lock before timeout.");
                }
                else
                {
                    try
                    {
                        // Get the file name
                        string fileName = fileObject.GetFileName(sl);
                        // Transmit the list
                        this.TransmitFile(ftp, new MemoryStream(Encoding.UTF8.GetBytes(fileContents)), fileName);
                        // Instruct file object to update next file name
                        fileObject.SetNextFileName(sl, fileName);
                    }
                    finally
                    {
                        this.ReleaseLock();
                    }
                }
            }
        }
        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="sendList">
        /// Discrete receive list to transmit
        /// </param>
        public override void Transmit(ReceiveListDetails rl)
        {
            if (rl.IsComposite)
            {
                throw new ApplicationException("Transmitter cannot transmit a composite list");
            }
            else
            {
                // Retrieve the ftp profile
                FtpProfileDetails ftp = this.RetrieveProfile(rl.Account);
                // Create the formatter and file writer objects
                IFileWriter fileObject = FileWriterFactory.Create(ftp);
                IFormatter formatObject = FormatterFactory.Create(ftp);
                // Hand over to formatter, which will format the list and return a string.  The
                // string will be the future contents of the file.
                string fileContents = formatObject.Format(rl);
                // Lock the transmitter
                if (this.GrabLock(this.NormalTimeout) == false)
                {
                    throw new ApplicationException("Unable to obtain list transmission lock before timeout.");
                }
                else
                {
                    try
                    {
                        // Get the file name
                        string fileName = fileObject.GetFileName(rl);
                        // Transmit the list
                        this.TransmitFile(ftp, new MemoryStream(Encoding.UTF8.GetBytes(fileContents)), fileName);
                        // Instruct file object to update next file name
                        fileObject.SetNextFileName(rl, fileName);
                    }
                    finally
                    {
                        this.ReleaseLock();
                    }
                }
            }
        }
        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="sendList">
        /// Discrete disaster code list to transmit
        /// </param>
        public override void Transmit(DisasterCodeListDetails dl)
        {
            if (dl.IsComposite)
            {
                throw new ApplicationException("Transmitter cannot transmit a composite list");
            }
            else
            {
                // Retrieve the ftp profile
                FtpProfileDetails ftp = this.RetrieveProfile(dl.Account);
                // Create the formatter and file writer objects
                IFileWriter fileObject = FileWriterFactory.Create(ftp);
                IFormatter formatObject = FormatterFactory.Create(ftp);
                // Hand over to formatter, which will format the list and return a string.  The
                // string will be the future contents of the file.
                string fileContents = formatObject.Format(dl);
                // Lock the transmitter
                if (this.GrabLock(this.NormalTimeout) == false)
                {
                    throw new ApplicationException("Unable to obtain list transmission lock before timeout.");
                }
                else
                {
                    try
                    {
                        // Get the file name
                        string fileName = fileObject.GetFileName(dl);
                        // Transmit the list
                        this.TransmitFile(ftp, new MemoryStream(Encoding.UTF8.GetBytes(fileContents)), fileName);
                        // Instruct file object to update next file name
                        fileObject.SetNextFileName(dl, fileName);
                    }
                    finally
                    {
                        this.ReleaseLock();
                    }
                }
            }
        }
    }
}
