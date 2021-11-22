namespace Bandl.Utility.VaultLedger.DbUpdater
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.GroupBox1 = new System.Windows.Forms.GroupBox();
            this.GetButton1 = new System.Windows.Forms.Button();
            this.GroupBox2 = new System.Windows.Forms.GroupBox();
            this.CheckBox1 = new System.Windows.Forms.CheckBox();
            this.TextBox2 = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.TextBox1 = new System.Windows.Forms.TextBox();
            this.Label2 = new System.Windows.Forms.Label();
            this.ComboBox1 = new System.Windows.Forms.ComboBox();
            this.label1 = new System.Windows.Forms.Label();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.GetButton2 = new System.Windows.Forms.Button();
            this.ComboBox2 = new System.Windows.Forms.ComboBox();
            this.label4 = new System.Windows.Forms.Label();
            this.Message1 = new System.Windows.Forms.Label();
            this.Message2 = new System.Windows.Forms.Label();
            this.UpdateButton = new System.Windows.Forms.Button();
            this.PictureBox1 = new System.Windows.Forms.PictureBox();
            this.GroupBox1.SuspendLayout();
            this.GroupBox2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.PictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // GroupBox1
            // 
            this.GroupBox1.Controls.Add(this.GetButton1);
            this.GroupBox1.Controls.Add(this.GroupBox2);
            this.GroupBox1.Controls.Add(this.ComboBox1);
            this.GroupBox1.Controls.Add(this.label1);
            this.GroupBox1.Location = new System.Drawing.Point(12, 12);
            this.GroupBox1.Name = "GroupBox1";
            this.GroupBox1.Size = new System.Drawing.Size(404, 186);
            this.GroupBox1.TabIndex = 1;
            this.GroupBox1.TabStop = false;
            this.GroupBox1.Text = "SQL Server";
            // 
            // GetButton1
            // 
            this.GetButton1.Location = new System.Drawing.Point(343, 26);
            this.GetButton1.Name = "GetButton1";
            this.GetButton1.Size = new System.Drawing.Size(42, 23);
            this.GetButton1.TabIndex = 4;
            this.GetButton1.Text = "Get";
            this.GetButton1.UseVisualStyleBackColor = true;
            this.GetButton1.Click += new System.EventHandler(this.GetButton1_Click);
            // 
            // GroupBox2
            // 
            this.GroupBox2.Controls.Add(this.CheckBox1);
            this.GroupBox2.Controls.Add(this.TextBox2);
            this.GroupBox2.Controls.Add(this.label3);
            this.GroupBox2.Controls.Add(this.TextBox1);
            this.GroupBox2.Controls.Add(this.Label2);
            this.GroupBox2.Location = new System.Drawing.Point(17, 59);
            this.GroupBox2.Name = "GroupBox2";
            this.GroupBox2.Size = new System.Drawing.Size(371, 111);
            this.GroupBox2.TabIndex = 5;
            this.GroupBox2.TabStop = false;
            this.GroupBox2.Text = "Security";
            // 
            // CheckBox1
            // 
            this.CheckBox1.Location = new System.Drawing.Point(9, 86);
            this.CheckBox1.Name = "CheckBox1";
            this.CheckBox1.Size = new System.Drawing.Size(243, 17);
            this.CheckBox1.TabIndex = 10;
            this.CheckBox1.Text = "Use &Trusted Authentication";
            this.CheckBox1.UseVisualStyleBackColor = true;
            this.CheckBox1.CheckedChanged += new System.EventHandler(this.CheckBox1_CheckedChanged);
            // 
            // TextBox2
            // 
            this.TextBox2.Location = new System.Drawing.Point(94, 51);
            this.TextBox2.Name = "TextBox2";
            this.TextBox2.PasswordChar = 'X';
            this.TextBox2.Size = new System.Drawing.Size(261, 20);
            this.TextBox2.TabIndex = 9;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(16, 51);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(60, 14);
            this.label3.TabIndex = 8;
            this.label3.Text = "&Password:";
            // 
            // TextBox1
            // 
            this.TextBox1.Location = new System.Drawing.Point(94, 23);
            this.TextBox1.Name = "TextBox1";
            this.TextBox1.Size = new System.Drawing.Size(261, 20);
            this.TextBox1.TabIndex = 7;
            this.TextBox1.TextChanged += new System.EventHandler(this.TextBox1_TextChanged);
            // 
            // Label2
            // 
            this.Label2.AutoSize = true;
            this.Label2.Location = new System.Drawing.Point(16, 26);
            this.Label2.Name = "Label2";
            this.Label2.Size = new System.Drawing.Size(45, 14);
            this.Label2.TabIndex = 6;
            this.Label2.Text = "&User ID:";
            // 
            // ComboBox1
            // 
            this.ComboBox1.FormattingEnabled = true;
            this.ComboBox1.Location = new System.Drawing.Point(111, 26);
            this.ComboBox1.Name = "ComboBox1";
            this.ComboBox1.Size = new System.Drawing.Size(225, 22);
            this.ComboBox1.TabIndex = 3;
            this.ComboBox1.TextChanged += new System.EventHandler(this.ComboBox1_TextChanged);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(17, 30);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(67, 14);
            this.label1.TabIndex = 2;
            this.label1.Text = "SQL &Server:";
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.GetButton2);
            this.groupBox3.Controls.Add(this.ComboBox2);
            this.groupBox3.Controls.Add(this.label4);
            this.groupBox3.Location = new System.Drawing.Point(12, 211);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(404, 60);
            this.groupBox3.TabIndex = 11;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "VaultLedger Database";
            // 
            // GetButton2
            // 
            this.GetButton2.Enabled = false;
            this.GetButton2.Location = new System.Drawing.Point(343, 24);
            this.GetButton2.Name = "GetButton2";
            this.GetButton2.Size = new System.Drawing.Size(42, 23);
            this.GetButton2.TabIndex = 14;
            this.GetButton2.Text = "Get";
            this.GetButton2.UseVisualStyleBackColor = true;
            this.GetButton2.Click += new System.EventHandler(this.GetButton2_Click);
            // 
            // ComboBox2
            // 
            this.ComboBox2.FormattingEnabled = true;
            this.ComboBox2.Location = new System.Drawing.Point(111, 24);
            this.ComboBox2.Name = "ComboBox2";
            this.ComboBox2.Size = new System.Drawing.Size(225, 22);
            this.ComboBox2.TabIndex = 13;
            this.ComboBox2.TextChanged += new System.EventHandler(this.ComboBox2_TextChanged);
            this.ComboBox2.Enter += new System.EventHandler(this.ComboBox2_Enter);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(17, 28);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(56, 14);
            this.label4.TabIndex = 12;
            this.label4.Text = "&Database:";
            // 
            // Message1
            // 
            this.Message1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.Message1.BackColor = System.Drawing.Color.Transparent;
            this.Message1.Location = new System.Drawing.Point(12, 281);
            this.Message1.Name = "Message1";
            this.Message1.Size = new System.Drawing.Size(404, 14);
            this.Message1.TabIndex = 2;
            this.Message1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // Message2
            // 
            this.Message2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.Message2.BackColor = System.Drawing.Color.Transparent;
            this.Message2.Location = new System.Drawing.Point(12, 323);
            this.Message2.Name = "Message2";
            this.Message2.Size = new System.Drawing.Size(404, 14);
            this.Message2.TabIndex = 3;
            this.Message2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // UpdateButton
            // 
            this.UpdateButton.Enabled = false;
            this.UpdateButton.Location = new System.Drawing.Point(177, 332);
            this.UpdateButton.Name = "UpdateButton";
            this.UpdateButton.Size = new System.Drawing.Size(75, 23);
            this.UpdateButton.TabIndex = 16;
            this.UpdateButton.Text = "Update";
            this.UpdateButton.UseVisualStyleBackColor = true;
            this.UpdateButton.Click += new System.EventHandler(this.UpdateButton_Click);
            // 
            // PictureBox1
            // 
            this.PictureBox1.Location = new System.Drawing.Point(12, 298);
            this.PictureBox1.Name = "PictureBox1";
            this.PictureBox1.Size = new System.Drawing.Size(404, 24);
            this.PictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.CenterImage;
            this.PictureBox1.TabIndex = 5;
            this.PictureBox1.TabStop = false;
            this.PictureBox1.Visible = false;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 14F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(428, 365);
            this.Controls.Add(this.PictureBox1);
            this.Controls.Add(this.UpdateButton);
            this.Controls.Add(this.Message2);
            this.Controls.Add(this.Message1);
            this.Controls.Add(this.groupBox3);
            this.Controls.Add(this.GroupBox1);
            this.Font = new System.Drawing.Font("Arial", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.Name = "Form1";
            this.Text = "VaultLedger Database Updater";
            this.GroupBox1.ResumeLayout(false);
            this.GroupBox1.PerformLayout();
            this.GroupBox2.ResumeLayout(false);
            this.GroupBox2.PerformLayout();
            this.groupBox3.ResumeLayout(false);
            this.groupBox3.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.PictureBox1)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.GroupBox GroupBox1;
        private System.Windows.Forms.GroupBox GroupBox2;
        private System.Windows.Forms.TextBox TextBox1;
        private System.Windows.Forms.Label Label2;
        private System.Windows.Forms.ComboBox ComboBox1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.CheckBox CheckBox1;
        private System.Windows.Forms.TextBox TextBox2;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Button GetButton2;
        private System.Windows.Forms.ComboBox ComboBox2;
        private System.Windows.Forms.Label Message1;
        private System.Windows.Forms.Label Message2;
        private System.Windows.Forms.Button UpdateButton;
        private System.Windows.Forms.PictureBox PictureBox1;
        private System.Windows.Forms.Button GetButton1;

    }
}