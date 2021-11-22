using System;
using System.Threading;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Runtime.Remoting.Messaging;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    public partial class Form1 : Form
    {
        private Dictionary<String, String[]> _dbcache = new Dictionary<String, String[]>();

        public Form1()
        {
            InitializeComponent();
            // Place image in PictureBox
            Assembly a1 = Assembly.GetExecutingAssembly();
            this.PictureBox1.Image = Image.FromStream(a1.GetManifestResourceStream(a1.GetName().Name + ".please.wait.gif"));
            // Initialize
            this.Initialize();
        }

        public void Initialize()
        {
            WebConfigFile f1 = new WebConfigFile();
            String x1 = f1.GetAppSetting("ConnString");
            String x2 = f1.GetAppSetting("ConnVector");
            // Regex
            Regex r1 = new Regex(@"^(SERVER\s*=|DATA SOURCE\s*=)", RegexOptions.IgnoreCase);
            Regex r2 = new Regex(@"^(DATABASE\s*=|INITIAL CATALOG\s*=)", RegexOptions.IgnoreCase);
            Regex r3 = new Regex(@"^(UID\s*=|USER ID\s*=)", RegexOptions.IgnoreCase);
            Regex r4 = new Regex(@"^(PWD\s*=|PASSWORD\s*=)", RegexOptions.IgnoreCase);
            Regex r5 = new Regex(@"^(TRUSTED_CONNECTION\s*=|INTEGRATED SECURITY\s*=)", RegexOptions.IgnoreCase);
            // Decrypt?
            if (!String.IsNullOrEmpty(x1.Trim()) && x1.IndexOf(';') == -1)
            {
                try
                {
                    x1 = Crypto.Decrypt(x1, x2);
                }
                catch
                {
                    ;
                }
            }
            // Split
            foreach (String s1 in x1.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
            {
                if (r1.IsMatch(s1)) // SERVER
                {
                    this.ComboBox1.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r2.IsMatch(s1))    // DATABASE
                {
                    this.ComboBox2.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r3.IsMatch(s1))    // USER ID
                {
                    this.TextBox1.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r4.IsMatch(s1))    // PASSWORD
                {
                    this.TextBox2.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r5.IsMatch(s1))    // TRUSTED
                {
                    String s2 = s1.Substring(s1.IndexOf('=') + 1).Trim().ToUpper();
                    this.CheckBox1.Checked = (s2[0] == 'T' || s2[0] == 'Y' || s2[0] == 'S');
                }
            }
            // Controls
            this.TextBox1.Enabled = !this.CheckBox1.Checked;
            this.TextBox2.Enabled = !this.CheckBox1.Checked;
            this.EnableUpdate();
            this.EnableGet2();
        }

        #region E N A B L I N G   M E T H O D S
        private void EnableControls(Boolean b1)
        {
            this.EnableControls(this, b1);
        }

        private void EnableControls(Control o1, Boolean b1)
        {
            foreach (Control o2 in o1.Controls)
            {
                this.EnableControls(o2, b1);
            }
            // Enable?
            switch (o1.GetType().ToString())
            {
                case "System.Windows.Forms.ComboBox":
                case "System.Windows.Forms.CheckBox":
                case "System.Windows.Forms.TextBox":
                case "System.Windows.Forms.Button":
                    o1.Enabled = b1;
                    break;
                default:
                    break;
            }
            // Form?
            if (b1 && o1.Name == this.Name)
            {
                this.EnableGet2();
                this.EnableUpdate();
            }
        }

        private void EnableUpdate()
        {
            if (String.IsNullOrEmpty(this.ComboBox1.Text.Trim()))
            {
                this.UpdateButton.Enabled = false;
            }
            else if (String.IsNullOrEmpty(this.TextBox1.Text.Trim()) && !this.CheckBox1.Checked)
            {
                this.UpdateButton.Enabled = false;
            }
            else
            {
                this.UpdateButton.Enabled = true;
            }
        }

        private void EnableGet2()
        {
            if (String.IsNullOrEmpty(this.ComboBox1.Text.Trim()))
            {
                this.GetButton2.Enabled = false;
            }
            else if (this.CheckBox1.Checked)
            {
                this.GetButton2.Enabled = true;
            }
            else
            {
                this.GetButton2.Enabled = !String.IsNullOrEmpty(this.TextBox1.Text.Trim());
            }
        }
        #endregion

        #region C O N T R O L   H A N D L E R S
        private void ComboBox1_TextChanged(object sender, EventArgs e)
        {
            this.EnableGet2();
            this.EnableUpdate();
        }

        private void TextBox1_TextChanged(object sender, EventArgs e)
        {
            this.EnableGet2();
            this.EnableUpdate();
        }

        private void CheckBox1_CheckedChanged(object sender, EventArgs e)
        {
            this.TextBox1.Enabled = !this.CheckBox1.Checked;
            this.TextBox2.Enabled = !this.CheckBox1.Checked;
            this.EnableUpdate();
            this.EnableGet2();
        }

        private void ComboBox2_TextChanged(object sender, EventArgs e)
        {
            this.EnableUpdate();
        }

        private void ComboBox2_Enter(object sender, EventArgs e)
        {
            this.ComboBox2.Items.Clear();
            // Have in cache?
            if (this._dbcache.ContainsKey(this.ComboBox1.Text))
            {
                this.ComboBox2.Items.AddRange(this._dbcache[this.ComboBox1.Text]);
            }
        }

        /// <summary>
        /// Discover SQL Server instances
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void GetButton1_Click(object sender, EventArgs e)
        {
            AsyncHelper h1 = new AsyncHelper();
            // Setup
            this.ComboBox1.Items.Clear();
            this.EnableControls(false);
            this.PictureBox1.Visible = true;
            this.Message1.Text = "Please wait while SQL Server instances are discovered";
            // Thread
            new Thread(h1.GetSqlServers).Start();
            // Wait for result
            while (!h1.Complete) Application.DoEvents();
            // Setup
            this.EnableControls(true);
            this.PictureBox1.Visible = false;
            this.Message1.Text = String.Empty;
            // Populate?
            if (h1.Exception == null)
            {
                this.ComboBox1.Items.AddRange((String[])h1.Value);
            }
            else
            {
                MessageBox.Show("SQL Server instance discovery failed.  " + h1.Exception.Message, this.Text, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
            }
        }

        private void GetButton2_Click(object sender, EventArgs e)
        {
            String k1 = this.ComboBox1.Text;
            String u1 = this.TextBox1.Text;
            String p1 = this.TextBox2.Text;
            // Setup
            this.Message1.Text = "Please wait while VaultLedger databases are discovered";
            this.Message2.Text = String.Empty;
            this.PictureBox1.Visible = true;
            this.EnableControls(false);
            // Create helper
            AsyncHelper h1 = new AsyncHelper(this.CheckBox1.Checked ? new SqlServer(k1) : new SqlServer(k1, u1, p1));
            // Thread
            new Thread(h1.GetVaultLedgerDatabases).Start();
            // Wait for result
            while (!h1.Complete)  Application.DoEvents();
            // Reset
            this.Message1.Text = String.Empty;
            this.PictureBox1.Visible = false;
            this.EnableControls(true);
            // Populate?
            if (h1.Exception == null)
            {
                this.ComboBox2.Items.AddRange((String[])h1.Value);
                this._dbcache[k1] = (String[])h1.Value;
            }
            else
            {
                MessageBox.Show("Database discovery failed.\r\n\r\n" + h1.Exception.Message, this.Text, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
            }
        }

        private void UpdateButton_Click(object sender, EventArgs e)
        {
            String k1 = this.ComboBox1.Text;
            String d1 = this.ComboBox2.Text;
            String u1 = this.TextBox1.Text;
            String p1 = this.TextBox2.Text;
            DateTime n1 = DateTime.Now;
            // Initialize
            AsyncHelper h1 = new AsyncHelper(this.CheckBox1.Checked ? new SqlServer(k1, d1) : new SqlServer(k1, d1, u1, p1));
            this.Message1.Text = "Contacting SQL Server";
            this.Message2.Text = "00:00:00";
            this.EnableControls(false);
            // Thread
            new Thread(h1.Update).Start();
            // Wait for result
            while (h1.Complete == false)
            {
                TimeSpan t1 = DateTime.Now - n1;
                Message2.Text = String.Format("{0:00}:{1:00}:{2:00}", t1.Hours, t1.Minutes, t1.Seconds);
                Application.DoEvents();
            }
            // Cleanup
            this.Message1.Text = String.Empty;
            this.Message2.Text = String.Empty;
            this.EnableControls(true);
            // Done
            if (h1.Exception == null)
            {
                MessageBox.Show(String.Format("Database '{0}' updated successfully.", d1), this.Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else
            {
                MessageBox.Show(String.Format("An error occurred while updating database '{0}'.\r\n\r\n{1}", d1, h1.Exception.Message), this.Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        #endregion
    }
}
