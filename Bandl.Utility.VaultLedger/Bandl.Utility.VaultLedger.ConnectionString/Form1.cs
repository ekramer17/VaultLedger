using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data.SqlClient;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Text.RegularExpressions;

namespace Bandl.Utility.VaultLedger.ConnectionString
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            // Initialize
            this.ComboBox1.SelectedIndex = 0;
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
            Regex r6 = new Regex(@"^(POOLING\s*=)", RegexOptions.IgnoreCase);
            Regex r7 = new Regex(@"^(MIN POOL SIZE\s*=)", RegexOptions.IgnoreCase);
            Regex r8 = new Regex(@"^(MAX POOL SIZE\s*=)", RegexOptions.IgnoreCase);
            // Decrypt?
            if (!String.IsNullOrWhiteSpace(x1) && x1.IndexOf(';') == -1)
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
                    this.TextBox1.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r2.IsMatch(s1))
                {
                    this.TextBox2.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r3.IsMatch(s1))
                {
                    this.TextBox3.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r4.IsMatch(s1))
                {
                    this.TextBox4.Text = s1.Substring(s1.IndexOf('=') + 1).Trim();
                }
                else if (r5.IsMatch(s1))
                {
                    String s2 = s1.Substring(s1.IndexOf('=') + 1).Trim().ToUpper();
                    this.CheckBox1.Checked = (s2[0] == 'T' || s2[0] == 'Y' || s2[0] == 'S');
                }
                else if (r6.IsMatch(s1))
                {
                    String s2 = s1.Substring(s1.IndexOf('=') + 1).Trim().ToUpper();
                    this.ComboBox1.SelectedIndex = (s2[0] == 'F' || s2[0] == 'N' ? 1 : 0);
                }
                else if (r7.IsMatch(s1))
                {
                    this.UpDown1.Value = Decimal.Parse(s1.Substring(s1.IndexOf('=') + 1).Trim());
                }
                else if (r8.IsMatch(s1))
                {
                    this.UpDown2.Value = Decimal.Parse(s1.Substring(s1.IndexOf('=') + 1).Trim());
                }
            }
            // Controls
            this.TextBox3.Enabled = !this.CheckBox1.Checked;
            this.TextBox4.Enabled = !this.CheckBox1.Checked;
            this.UpDown1.Enabled = (this.ComboBox1.SelectedIndex == 0);
            this.UpDown2.Enabled = (this.ComboBox1.SelectedIndex == 0);
        }

        private void EnableButton()
        {
            Boolean b1 = true;
            // Check
            if (String.IsNullOrWhiteSpace(this.TextBox1.Text))
            {
                b1 = false;
            }
            else if (String.IsNullOrWhiteSpace(this.TextBox2.Text))
            {
                b1 = false;
            }
            else if (!CheckBox1.Checked && String.IsNullOrWhiteSpace(this.TextBox3.Text))
            {
                b1 = false;
            }
            // Enable
            this.Button1.Enabled = b1;
            this.Button2.Enabled = b1;
        }

        private void TextBox1_TextChanged(object sender, EventArgs e)
        {
            this.EnableButton();
        }

        private void TextBox2_TextChanged(object sender, EventArgs e)
        {
            this.EnableButton();
        }

        private void TextBox3_TextChanged(object sender, EventArgs e)
        {
            this.EnableButton();
        }

        private void CheckBox1_CheckedChanged(object sender, EventArgs e)
        {
            this.TextBox3.Enabled = !this.CheckBox1.Checked;
            this.TextBox4.Enabled = !this.CheckBox1.Checked;
            this.EnableButton();
        }

        private void UpDown1_ValueChanged(object sender, EventArgs e)
        {
            if (this.UpDown1.Value > this.UpDown2.Value) this.UpDown1.Value = this.UpDown2.Value;
        }

        private void UpDown2_ValueChanged(object sender, EventArgs e)
        {
            if (this.UpDown2.Value < this.UpDown1.Value) this.UpDown2.Value = this.UpDown1.Value;
        }

        private void ComboBox1_SelectedIndexChanged(object sender, EventArgs e)
        {
            this.UpDown1.Enabled = (this.ComboBox1.SelectedIndex == 0);
            this.UpDown2.Enabled = (this.ComboBox1.SelectedIndex == 0);
        }

        private void Button1_Click(object sender, EventArgs e)
        {
            try
            {
                using (SqlConnection c1 = new SqlConnection(CreateString())) { c1.Open(); }
                MessageBox.Show("Connection successful", "VaultLedger Connection String Encryptor", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception e1)
            {
                MessageBox.Show(e1.Message, "VaultLedger Connection String Encryptor", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void Button2_Click(object sender, EventArgs e)
        {
            try
            {
                // Encrypt
                String x2 = Convert.ToBase64String(Crypto.CreateCipher());
                String x1 = Convert.ToBase64String(Crypto.Encrypt(CreateString(), x2));
                // Write to configuration file
                WebConfigFile f1 = new WebConfigFile();
                f1.SetAppSetting("ConnString", x1);
                f1.SetAppSetting("ConnVector", x2);
                // Success
                MessageBox.Show("Connection string successfully encrypted", "VaultLedger Connection String Encryptor", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception e1)
            {
                MessageBox.Show(e1.Message, "VaultLedger Connection String Encryptor", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private String CreateString()
        {
            StringBuilder b1 = new StringBuilder();
            b1.AppendFormat("SERVER={0}", this.TextBox1.Text.Trim());
            b1.AppendFormat(";DATABASE={0}", this.TextBox2.Text.Trim());
            // Trusted?
            if (this.CheckBox1.Checked)
            {
                b1.Append(";TRUSTED_CONNECTION=TRUE");
            }
            else
            {
                b1.AppendFormat(";USER ID={0}", this.TextBox3.Text.Trim());
                // Password?
                if (!String.IsNullOrWhiteSpace(this.TextBox4.Text))
                {
                    b1.AppendFormat(";PASSWORD={0}", this.TextBox4.Text.Trim());
                }
            }
            // Pooling?
            if (this.ComboBox1.SelectedIndex == 1)
            {
                b1.Append(";POOLING=NO");
            }
            else
            {
                b1.Append(";POOLING=YES");
                b1.AppendFormat(";MIN POOL SIZE={0}", (Int32)this.UpDown1.Value);
                b1.AppendFormat(";MAX POOL SIZE={0}", (Int32)this.UpDown2.Value);
            }
            // Multiple result sets
            b1.Append(";MULTIPLEACTIVERESULTSETS=TRUE");
            // Return
            return b1.ToString();
        }
    }
}
