using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Represents a collection of ProductLicenseDetails objects
    /// </summary>
    [Serializable]
    public class ProductLicenseCollection : BaseCollection
    {
		public ProductLicenseCollection() : base() {}
		public ProductLicenseCollection(ICollection c) : base(c) {}
		public ProductLicenseCollection(IDataReader r) : base(r) {}

		// Indexer
		public ProductLicenseDetails this [int index]
		{
			get
			{
				if (index < 0 || index > InnerList.Count - 1)
				{
					throw new ArgumentOutOfRangeException();
				}
				else
				{
					return (ProductLicenseDetails)InnerList[index];
				}
			}
            set
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    InnerList[index] = value;
                }
            }
        }

        public override void Fill(IDataReader r)
        {
			while(r.Read() == true) 
			{
				this.Add(new ProductLicenseDetails(r));
			}
        }

        public void Remove(LicenseTypes _licenseType)
        {
            foreach(ProductLicenseDetails p in this)
            {
                if (_licenseType == p.LicenseType)
                {
                    Remove(p);
                    return;
                }
            }
        }

        public ProductLicenseDetails Find(LicenseTypes _licenseType)
        {
			foreach(ProductLicenseDetails p in this)
			{
				if (_licenseType == p.LicenseType)
				{
					return p;
				}
			}
            // Not found
            return null;
        }
    }
}
