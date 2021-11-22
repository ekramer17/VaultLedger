using System;
using System.Data;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Collections
{
    /// <summary>
    /// Collection of InventoryConflictDetails objects
    /// </summary>
    [Serializable]
    public class InventoryConflictCollection : BaseCollection
    {
        public InventoryConflictCollection() : base() {}
        public InventoryConflictCollection(ICollection c) : base(c) {}
        public InventoryConflictCollection(IDataReader r) : base(r) {}

        // Indexer
        public InventoryConflictDetails this [int index]
        {
            get
            {
                if (index < 0 || index > InnerList.Count - 1)
                {
                    throw new ArgumentOutOfRangeException();
                }
                else
                {
                    return (InventoryConflictDetails)InnerList[index];
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
                this.Add(new InventoryConflictDetails(r));
            }
        }

        public InventoryConflictDetails Find(int id)
        {
            foreach(InventoryConflictDetails c in this)
            {
                if (id == c.Id)
                {
                    return(c);
                }
            }
            // not found
            return null;
        }

        public void Remove(int id)
        {
            foreach(InventoryConflictDetails c in this)
            {
                if (id == c.Id)
                {
                    Remove(c);
                    return;
                }
            }
        }

//        public InventoryConflictDetails Find(string serialNo)
//        {
//            foreach(InventoryConflictDetails c in this)
//            {
//                if (serialNo == c.SerialNo)
//                {
//                    return(c);
//                }
//            }
//            // not found
//            return null;
//        }
//
//        public void Remove(string serialNo)
//        {
//            foreach(VaultDiscrepancyDetails v in this)
//            {
//                if (serialNo == v.SerialNo)
//                {
//                    Remove(v);
//                    return;
//                }
//            }
//        }
    }
}
