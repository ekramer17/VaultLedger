﻿//------------------------------------------------------------------------------
// <autogenerated>
//     This code was generated by a tool.
//     Runtime Version: 1.1.4322.2032
//
//     Changes to this file may cause incorrect behavior and will be lost if 
//     the code is regenerated.
// </autogenerated>
//------------------------------------------------------------------------------

namespace Bandl.VaultLedger.Web.Printing {
    using System;
    using System.Data;
    using System.Xml;
    using System.Runtime.Serialization;
    
    
    [Serializable()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Diagnostics.DebuggerStepThrough()]
    [System.ComponentModel.ToolboxItem(true)]
    public class dsVaultDiscrepancy : DataSet {
        
        private HeaderLogoDataTable tableHeaderLogo;
        
        private VaultDiscrepancyDataTable tableVaultDiscrepancy;
        
        public dsVaultDiscrepancy() {
            this.InitClass();
            System.ComponentModel.CollectionChangeEventHandler schemaChangedHandler = new System.ComponentModel.CollectionChangeEventHandler(this.SchemaChanged);
            this.Tables.CollectionChanged += schemaChangedHandler;
            this.Relations.CollectionChanged += schemaChangedHandler;
        }
        
        protected dsVaultDiscrepancy(SerializationInfo info, StreamingContext context) {
            string strSchema = ((string)(info.GetValue("XmlSchema", typeof(string))));
            if ((strSchema != null)) {
                DataSet ds = new DataSet();
                ds.ReadXmlSchema(new XmlTextReader(new System.IO.StringReader(strSchema)));
                if ((ds.Tables["HeaderLogo"] != null)) {
                    this.Tables.Add(new HeaderLogoDataTable(ds.Tables["HeaderLogo"]));
                }
                if ((ds.Tables["VaultDiscrepancy"] != null)) {
                    this.Tables.Add(new VaultDiscrepancyDataTable(ds.Tables["VaultDiscrepancy"]));
                }
                this.DataSetName = ds.DataSetName;
                this.Prefix = ds.Prefix;
                this.Namespace = ds.Namespace;
                this.Locale = ds.Locale;
                this.CaseSensitive = ds.CaseSensitive;
                this.EnforceConstraints = ds.EnforceConstraints;
                this.Merge(ds, false, System.Data.MissingSchemaAction.Add);
                this.InitVars();
            }
            else {
                this.InitClass();
            }
            this.GetSerializationData(info, context);
            System.ComponentModel.CollectionChangeEventHandler schemaChangedHandler = new System.ComponentModel.CollectionChangeEventHandler(this.SchemaChanged);
            this.Tables.CollectionChanged += schemaChangedHandler;
            this.Relations.CollectionChanged += schemaChangedHandler;
        }
        
        [System.ComponentModel.Browsable(false)]
        [System.ComponentModel.DesignerSerializationVisibilityAttribute(System.ComponentModel.DesignerSerializationVisibility.Content)]
        public HeaderLogoDataTable HeaderLogo {
            get {
                return this.tableHeaderLogo;
            }
        }
        
        [System.ComponentModel.Browsable(false)]
        [System.ComponentModel.DesignerSerializationVisibilityAttribute(System.ComponentModel.DesignerSerializationVisibility.Content)]
        public VaultDiscrepancyDataTable VaultDiscrepancy {
            get {
                return this.tableVaultDiscrepancy;
            }
        }
        
        public override DataSet Clone() {
            dsVaultDiscrepancy cln = ((dsVaultDiscrepancy)(base.Clone()));
            cln.InitVars();
            return cln;
        }
        
        protected override bool ShouldSerializeTables() {
            return false;
        }
        
        protected override bool ShouldSerializeRelations() {
            return false;
        }
        
        protected override void ReadXmlSerializable(XmlReader reader) {
            this.Reset();
            DataSet ds = new DataSet();
            ds.ReadXml(reader);
            if ((ds.Tables["HeaderLogo"] != null)) {
                this.Tables.Add(new HeaderLogoDataTable(ds.Tables["HeaderLogo"]));
            }
            if ((ds.Tables["VaultDiscrepancy"] != null)) {
                this.Tables.Add(new VaultDiscrepancyDataTable(ds.Tables["VaultDiscrepancy"]));
            }
            this.DataSetName = ds.DataSetName;
            this.Prefix = ds.Prefix;
            this.Namespace = ds.Namespace;
            this.Locale = ds.Locale;
            this.CaseSensitive = ds.CaseSensitive;
            this.EnforceConstraints = ds.EnforceConstraints;
            this.Merge(ds, false, System.Data.MissingSchemaAction.Add);
            this.InitVars();
        }
        
        protected override System.Xml.Schema.XmlSchema GetSchemaSerializable() {
            System.IO.MemoryStream stream = new System.IO.MemoryStream();
            this.WriteXmlSchema(new XmlTextWriter(stream, null));
            stream.Position = 0;
            return System.Xml.Schema.XmlSchema.Read(new XmlTextReader(stream), null);
        }
        
        internal void InitVars() {
            this.tableHeaderLogo = ((HeaderLogoDataTable)(this.Tables["HeaderLogo"]));
            if ((this.tableHeaderLogo != null)) {
                this.tableHeaderLogo.InitVars();
            }
            this.tableVaultDiscrepancy = ((VaultDiscrepancyDataTable)(this.Tables["VaultDiscrepancy"]));
            if ((this.tableVaultDiscrepancy != null)) {
                this.tableVaultDiscrepancy.InitVars();
            }
        }
        
        private void InitClass() {
            this.DataSetName = "dsVaultDiscrepancy";
            this.Prefix = "";
            this.Namespace = "http://tempuri.org/dsVaultDiscrepancy.xsd";
            this.Locale = new System.Globalization.CultureInfo("en-US");
            this.CaseSensitive = false;
            this.EnforceConstraints = true;
            this.tableHeaderLogo = new HeaderLogoDataTable();
            this.Tables.Add(this.tableHeaderLogo);
            this.tableVaultDiscrepancy = new VaultDiscrepancyDataTable();
            this.Tables.Add(this.tableVaultDiscrepancy);
        }
        
        private bool ShouldSerializeHeaderLogo() {
            return false;
        }
        
        private bool ShouldSerializeVaultDiscrepancy() {
            return false;
        }
        
        private void SchemaChanged(object sender, System.ComponentModel.CollectionChangeEventArgs e) {
            if ((e.Action == System.ComponentModel.CollectionChangeAction.Remove)) {
                this.InitVars();
            }
        }
        
        public delegate void HeaderLogoRowChangeEventHandler(object sender, HeaderLogoRowChangeEvent e);
        
        public delegate void VaultDiscrepancyRowChangeEventHandler(object sender, VaultDiscrepancyRowChangeEvent e);
        
        [System.Diagnostics.DebuggerStepThrough()]
        public class HeaderLogoDataTable : DataTable, System.Collections.IEnumerable {
            
            private DataColumn columnCompanyLogo;
            
            private DataColumn columnProductLogo;
            
            private DataColumn columnReportTitle;
            
            internal HeaderLogoDataTable() : 
                    base("HeaderLogo") {
                this.InitClass();
            }
            
            internal HeaderLogoDataTable(DataTable table) : 
                    base(table.TableName) {
                if ((table.CaseSensitive != table.DataSet.CaseSensitive)) {
                    this.CaseSensitive = table.CaseSensitive;
                }
                if ((table.Locale.ToString() != table.DataSet.Locale.ToString())) {
                    this.Locale = table.Locale;
                }
                if ((table.Namespace != table.DataSet.Namespace)) {
                    this.Namespace = table.Namespace;
                }
                this.Prefix = table.Prefix;
                this.MinimumCapacity = table.MinimumCapacity;
                this.DisplayExpression = table.DisplayExpression;
            }
            
            [System.ComponentModel.Browsable(false)]
            public int Count {
                get {
                    return this.Rows.Count;
                }
            }
            
            internal DataColumn CompanyLogoColumn {
                get {
                    return this.columnCompanyLogo;
                }
            }
            
            internal DataColumn ProductLogoColumn {
                get {
                    return this.columnProductLogo;
                }
            }
            
            internal DataColumn ReportTitleColumn {
                get {
                    return this.columnReportTitle;
                }
            }
            
            public HeaderLogoRow this[int index] {
                get {
                    return ((HeaderLogoRow)(this.Rows[index]));
                }
            }
            
            public event HeaderLogoRowChangeEventHandler HeaderLogoRowChanged;
            
            public event HeaderLogoRowChangeEventHandler HeaderLogoRowChanging;
            
            public event HeaderLogoRowChangeEventHandler HeaderLogoRowDeleted;
            
            public event HeaderLogoRowChangeEventHandler HeaderLogoRowDeleting;
            
            public void AddHeaderLogoRow(HeaderLogoRow row) {
                this.Rows.Add(row);
            }
            
            public HeaderLogoRow AddHeaderLogoRow(System.Byte[] CompanyLogo, System.Byte[] ProductLogo, string ReportTitle) {
                HeaderLogoRow rowHeaderLogoRow = ((HeaderLogoRow)(this.NewRow()));
                rowHeaderLogoRow.ItemArray = new object[] {
                        CompanyLogo,
                        ProductLogo,
                        ReportTitle};
                this.Rows.Add(rowHeaderLogoRow);
                return rowHeaderLogoRow;
            }
            
            public System.Collections.IEnumerator GetEnumerator() {
                return this.Rows.GetEnumerator();
            }
            
            public override DataTable Clone() {
                HeaderLogoDataTable cln = ((HeaderLogoDataTable)(base.Clone()));
                cln.InitVars();
                return cln;
            }
            
            protected override DataTable CreateInstance() {
                return new HeaderLogoDataTable();
            }
            
            internal void InitVars() {
                this.columnCompanyLogo = this.Columns["CompanyLogo"];
                this.columnProductLogo = this.Columns["ProductLogo"];
                this.columnReportTitle = this.Columns["ReportTitle"];
            }
            
            private void InitClass() {
                this.columnCompanyLogo = new DataColumn("CompanyLogo", typeof(System.Byte[]), null, System.Data.MappingType.Element);
                this.Columns.Add(this.columnCompanyLogo);
                this.columnProductLogo = new DataColumn("ProductLogo", typeof(System.Byte[]), null, System.Data.MappingType.Element);
                this.Columns.Add(this.columnProductLogo);
                this.columnReportTitle = new DataColumn("ReportTitle", typeof(string), null, System.Data.MappingType.Element);
                this.Columns.Add(this.columnReportTitle);
            }
            
            public HeaderLogoRow NewHeaderLogoRow() {
                return ((HeaderLogoRow)(this.NewRow()));
            }
            
            protected override DataRow NewRowFromBuilder(DataRowBuilder builder) {
                return new HeaderLogoRow(builder);
            }
            
            protected override System.Type GetRowType() {
                return typeof(HeaderLogoRow);
            }
            
            protected override void OnRowChanged(DataRowChangeEventArgs e) {
                base.OnRowChanged(e);
                if ((this.HeaderLogoRowChanged != null)) {
                    this.HeaderLogoRowChanged(this, new HeaderLogoRowChangeEvent(((HeaderLogoRow)(e.Row)), e.Action));
                }
            }
            
            protected override void OnRowChanging(DataRowChangeEventArgs e) {
                base.OnRowChanging(e);
                if ((this.HeaderLogoRowChanging != null)) {
                    this.HeaderLogoRowChanging(this, new HeaderLogoRowChangeEvent(((HeaderLogoRow)(e.Row)), e.Action));
                }
            }
            
            protected override void OnRowDeleted(DataRowChangeEventArgs e) {
                base.OnRowDeleted(e);
                if ((this.HeaderLogoRowDeleted != null)) {
                    this.HeaderLogoRowDeleted(this, new HeaderLogoRowChangeEvent(((HeaderLogoRow)(e.Row)), e.Action));
                }
            }
            
            protected override void OnRowDeleting(DataRowChangeEventArgs e) {
                base.OnRowDeleting(e);
                if ((this.HeaderLogoRowDeleting != null)) {
                    this.HeaderLogoRowDeleting(this, new HeaderLogoRowChangeEvent(((HeaderLogoRow)(e.Row)), e.Action));
                }
            }
            
            public void RemoveHeaderLogoRow(HeaderLogoRow row) {
                this.Rows.Remove(row);
            }
        }
        
        [System.Diagnostics.DebuggerStepThrough()]
        public class HeaderLogoRow : DataRow {
            
            private HeaderLogoDataTable tableHeaderLogo;
            
            internal HeaderLogoRow(DataRowBuilder rb) : 
                    base(rb) {
                this.tableHeaderLogo = ((HeaderLogoDataTable)(this.Table));
            }
            
            public System.Byte[] CompanyLogo {
                get {
                    try {
                        return ((System.Byte[])(this[this.tableHeaderLogo.CompanyLogoColumn]));
                    }
                    catch (InvalidCastException e) {
                        throw new StrongTypingException("Cannot get value because it is DBNull.", e);
                    }
                }
                set {
                    this[this.tableHeaderLogo.CompanyLogoColumn] = value;
                }
            }
            
            public System.Byte[] ProductLogo {
                get {
                    try {
                        return ((System.Byte[])(this[this.tableHeaderLogo.ProductLogoColumn]));
                    }
                    catch (InvalidCastException e) {
                        throw new StrongTypingException("Cannot get value because it is DBNull.", e);
                    }
                }
                set {
                    this[this.tableHeaderLogo.ProductLogoColumn] = value;
                }
            }
            
            public string ReportTitle {
                get {
                    try {
                        return ((string)(this[this.tableHeaderLogo.ReportTitleColumn]));
                    }
                    catch (InvalidCastException e) {
                        throw new StrongTypingException("Cannot get value because it is DBNull.", e);
                    }
                }
                set {
                    this[this.tableHeaderLogo.ReportTitleColumn] = value;
                }
            }
            
            public bool IsCompanyLogoNull() {
                return this.IsNull(this.tableHeaderLogo.CompanyLogoColumn);
            }
            
            public void SetCompanyLogoNull() {
                this[this.tableHeaderLogo.CompanyLogoColumn] = System.Convert.DBNull;
            }
            
            public bool IsProductLogoNull() {
                return this.IsNull(this.tableHeaderLogo.ProductLogoColumn);
            }
            
            public void SetProductLogoNull() {
                this[this.tableHeaderLogo.ProductLogoColumn] = System.Convert.DBNull;
            }
            
            public bool IsReportTitleNull() {
                return this.IsNull(this.tableHeaderLogo.ReportTitleColumn);
            }
            
            public void SetReportTitleNull() {
                this[this.tableHeaderLogo.ReportTitleColumn] = System.Convert.DBNull;
            }
        }
        
        [System.Diagnostics.DebuggerStepThrough()]
        public class HeaderLogoRowChangeEvent : EventArgs {
            
            private HeaderLogoRow eventRow;
            
            private DataRowAction eventAction;
            
            public HeaderLogoRowChangeEvent(HeaderLogoRow row, DataRowAction action) {
                this.eventRow = row;
                this.eventAction = action;
            }
            
            public HeaderLogoRow Row {
                get {
                    return this.eventRow;
                }
            }
            
            public DataRowAction Action {
                get {
                    return this.eventAction;
                }
            }
        }
        
        [System.Diagnostics.DebuggerStepThrough()]
        public class VaultDiscrepancyDataTable : DataTable, System.Collections.IEnumerable {
            
            private DataColumn columnSerialNo;
            
            private DataColumn columnRecordedDate;
            
            private DataColumn columnDetails;
            
            internal VaultDiscrepancyDataTable() : 
                    base("VaultDiscrepancy") {
                this.InitClass();
            }
            
            internal VaultDiscrepancyDataTable(DataTable table) : 
                    base(table.TableName) {
                if ((table.CaseSensitive != table.DataSet.CaseSensitive)) {
                    this.CaseSensitive = table.CaseSensitive;
                }
                if ((table.Locale.ToString() != table.DataSet.Locale.ToString())) {
                    this.Locale = table.Locale;
                }
                if ((table.Namespace != table.DataSet.Namespace)) {
                    this.Namespace = table.Namespace;
                }
                this.Prefix = table.Prefix;
                this.MinimumCapacity = table.MinimumCapacity;
                this.DisplayExpression = table.DisplayExpression;
            }
            
            [System.ComponentModel.Browsable(false)]
            public int Count {
                get {
                    return this.Rows.Count;
                }
            }
            
            internal DataColumn SerialNoColumn {
                get {
                    return this.columnSerialNo;
                }
            }
            
            internal DataColumn RecordedDateColumn {
                get {
                    return this.columnRecordedDate;
                }
            }
            
            internal DataColumn DetailsColumn {
                get {
                    return this.columnDetails;
                }
            }
            
            public VaultDiscrepancyRow this[int index] {
                get {
                    return ((VaultDiscrepancyRow)(this.Rows[index]));
                }
            }
            
            public event VaultDiscrepancyRowChangeEventHandler VaultDiscrepancyRowChanged;
            
            public event VaultDiscrepancyRowChangeEventHandler VaultDiscrepancyRowChanging;
            
            public event VaultDiscrepancyRowChangeEventHandler VaultDiscrepancyRowDeleted;
            
            public event VaultDiscrepancyRowChangeEventHandler VaultDiscrepancyRowDeleting;
            
            public void AddVaultDiscrepancyRow(VaultDiscrepancyRow row) {
                this.Rows.Add(row);
            }
            
            public VaultDiscrepancyRow AddVaultDiscrepancyRow(string SerialNo, string RecordedDate, string Details) {
                VaultDiscrepancyRow rowVaultDiscrepancyRow = ((VaultDiscrepancyRow)(this.NewRow()));
                rowVaultDiscrepancyRow.ItemArray = new object[] {
                        SerialNo,
                        RecordedDate,
                        Details};
                this.Rows.Add(rowVaultDiscrepancyRow);
                return rowVaultDiscrepancyRow;
            }
            
            public System.Collections.IEnumerator GetEnumerator() {
                return this.Rows.GetEnumerator();
            }
            
            public override DataTable Clone() {
                VaultDiscrepancyDataTable cln = ((VaultDiscrepancyDataTable)(base.Clone()));
                cln.InitVars();
                return cln;
            }
            
            protected override DataTable CreateInstance() {
                return new VaultDiscrepancyDataTable();
            }
            
            internal void InitVars() {
                this.columnSerialNo = this.Columns["SerialNo"];
                this.columnRecordedDate = this.Columns["RecordedDate"];
                this.columnDetails = this.Columns["Details"];
            }
            
            private void InitClass() {
                this.columnSerialNo = new DataColumn("SerialNo", typeof(string), null, System.Data.MappingType.Element);
                this.Columns.Add(this.columnSerialNo);
                this.columnRecordedDate = new DataColumn("RecordedDate", typeof(string), null, System.Data.MappingType.Element);
                this.Columns.Add(this.columnRecordedDate);
                this.columnDetails = new DataColumn("Details", typeof(string), null, System.Data.MappingType.Element);
                this.Columns.Add(this.columnDetails);
            }
            
            public VaultDiscrepancyRow NewVaultDiscrepancyRow() {
                return ((VaultDiscrepancyRow)(this.NewRow()));
            }
            
            protected override DataRow NewRowFromBuilder(DataRowBuilder builder) {
                return new VaultDiscrepancyRow(builder);
            }
            
            protected override System.Type GetRowType() {
                return typeof(VaultDiscrepancyRow);
            }
            
            protected override void OnRowChanged(DataRowChangeEventArgs e) {
                base.OnRowChanged(e);
                if ((this.VaultDiscrepancyRowChanged != null)) {
                    this.VaultDiscrepancyRowChanged(this, new VaultDiscrepancyRowChangeEvent(((VaultDiscrepancyRow)(e.Row)), e.Action));
                }
            }
            
            protected override void OnRowChanging(DataRowChangeEventArgs e) {
                base.OnRowChanging(e);
                if ((this.VaultDiscrepancyRowChanging != null)) {
                    this.VaultDiscrepancyRowChanging(this, new VaultDiscrepancyRowChangeEvent(((VaultDiscrepancyRow)(e.Row)), e.Action));
                }
            }
            
            protected override void OnRowDeleted(DataRowChangeEventArgs e) {
                base.OnRowDeleted(e);
                if ((this.VaultDiscrepancyRowDeleted != null)) {
                    this.VaultDiscrepancyRowDeleted(this, new VaultDiscrepancyRowChangeEvent(((VaultDiscrepancyRow)(e.Row)), e.Action));
                }
            }
            
            protected override void OnRowDeleting(DataRowChangeEventArgs e) {
                base.OnRowDeleting(e);
                if ((this.VaultDiscrepancyRowDeleting != null)) {
                    this.VaultDiscrepancyRowDeleting(this, new VaultDiscrepancyRowChangeEvent(((VaultDiscrepancyRow)(e.Row)), e.Action));
                }
            }
            
            public void RemoveVaultDiscrepancyRow(VaultDiscrepancyRow row) {
                this.Rows.Remove(row);
            }
        }
        
        [System.Diagnostics.DebuggerStepThrough()]
        public class VaultDiscrepancyRow : DataRow {
            
            private VaultDiscrepancyDataTable tableVaultDiscrepancy;
            
            internal VaultDiscrepancyRow(DataRowBuilder rb) : 
                    base(rb) {
                this.tableVaultDiscrepancy = ((VaultDiscrepancyDataTable)(this.Table));
            }
            
            public string SerialNo {
                get {
                    try {
                        return ((string)(this[this.tableVaultDiscrepancy.SerialNoColumn]));
                    }
                    catch (InvalidCastException e) {
                        throw new StrongTypingException("Cannot get value because it is DBNull.", e);
                    }
                }
                set {
                    this[this.tableVaultDiscrepancy.SerialNoColumn] = value;
                }
            }
            
            public string RecordedDate {
                get {
                    try {
                        return ((string)(this[this.tableVaultDiscrepancy.RecordedDateColumn]));
                    }
                    catch (InvalidCastException e) {
                        throw new StrongTypingException("Cannot get value because it is DBNull.", e);
                    }
                }
                set {
                    this[this.tableVaultDiscrepancy.RecordedDateColumn] = value;
                }
            }
            
            public string Details {
                get {
                    try {
                        return ((string)(this[this.tableVaultDiscrepancy.DetailsColumn]));
                    }
                    catch (InvalidCastException e) {
                        throw new StrongTypingException("Cannot get value because it is DBNull.", e);
                    }
                }
                set {
                    this[this.tableVaultDiscrepancy.DetailsColumn] = value;
                }
            }
            
            public bool IsSerialNoNull() {
                return this.IsNull(this.tableVaultDiscrepancy.SerialNoColumn);
            }
            
            public void SetSerialNoNull() {
                this[this.tableVaultDiscrepancy.SerialNoColumn] = System.Convert.DBNull;
            }
            
            public bool IsRecordedDateNull() {
                return this.IsNull(this.tableVaultDiscrepancy.RecordedDateColumn);
            }
            
            public void SetRecordedDateNull() {
                this[this.tableVaultDiscrepancy.RecordedDateColumn] = System.Convert.DBNull;
            }
            
            public bool IsDetailsNull() {
                return this.IsNull(this.tableVaultDiscrepancy.DetailsColumn);
            }
            
            public void SetDetailsNull() {
                this[this.tableVaultDiscrepancy.DetailsColumn] = System.Convert.DBNull;
            }
        }
        
        [System.Diagnostics.DebuggerStepThrough()]
        public class VaultDiscrepancyRowChangeEvent : EventArgs {
            
            private VaultDiscrepancyRow eventRow;
            
            private DataRowAction eventAction;
            
            public VaultDiscrepancyRowChangeEvent(VaultDiscrepancyRow row, DataRowAction action) {
                this.eventRow = row;
                this.eventAction = action;
            }
            
            public VaultDiscrepancyRow Row {
                get {
                    return this.eventRow;
                }
            }
            
            public DataRowAction Action {
                get {
                    return this.eventAction;
                }
            }
        }
    }
}
