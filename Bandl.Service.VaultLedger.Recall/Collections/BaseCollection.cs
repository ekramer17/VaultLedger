using System;
using System.Data;
using System.Collections;

namespace Bandl.Service.VaultLedger.Recall.Collections
{
    /// <summary>
    /// Summary description for Collection.
    /// </summary>
    [Serializable]
    public class BaseCollection : CollectionBase
    {
        public bool HasErrors;

        public BaseCollection() 
        {
            HasErrors = false;
        }

        public BaseCollection(IDataReader r) : base()
        {
            this.Fill(r);
        }

        public BaseCollection(ICollection c) : this()
        {
            if (c != null)
            {
                object[] newArray = new object[c.Count];
                c.CopyTo(newArray,0);
                foreach(object x in newArray)
                {
                    Add(x);
                }
            }
        }

        public virtual int Add(object o)
        {
            if (o == null)
            {
                return -1;
            }
            else
            {
                int index = InnerList.IndexOf(o);
                return index != -1 ? index : InnerList.Add(o);
            }
        }

        /// <summary>
        /// Add a collection of items to this collection
        /// </summary>
        /// <param name="c">
        /// Collection of items to add
        /// </param>
        /// <returns>
        /// Number of items actually added to this collection, which may be 
        /// less than the number passed in if one or more items already
        /// exists in this collection.
        /// </returns>
        public virtual int Add(ICollection c)
        {
            if (c == null)
            {
                return 0;
            }
            else
            {
                int totalAdded = 0;

                object[] newArray = new object[c.Count];
                c.CopyTo(newArray,0);
                foreach(object o in newArray)
                {
                    if (Add(o) != -1)
                    {
                        totalAdded++;
                    }
                }
                // Return number of items actually added
                return totalAdded;
            }
        }

        public virtual void Fill(IDataReader r)
        {
            // Do nothing
        }

        public virtual void Insert(int index, object o)
        {
            if (InnerList.IndexOf(o) == -1) 
            {
                InnerList.Insert(index, o);
            }
        }

        public virtual void Remove(object o)
        {
            if (InnerList.IndexOf(o) != -1)
            {
                InnerList.Remove(o);
            }
        }

        /// <summary>
        /// Replaces an object in the collection with another object.  Not advised
        /// for use within a foreach loop, as the enumeration of the collection
        /// will be affected and will cause an exception.
        /// </summary>
        /// <param name="oldObject">
        /// Object to replace
        /// </param>
        /// <param name="newObject">
        /// Object to take place of oldObject
        /// </param>
        public virtual void Replace(object oldObject, object newObject)
        {
            // Verify that new object isn't already in the collection
            if (InnerList.IndexOf(newObject) != -1)
            {
                throw new ApplicationException("New object is already in collection.");
            }
            else if (InnerList.IndexOf(oldObject) == -1)
            {
                throw new ApplicationException("Object to replace is not in collection.");
            }
            else
            {
                InnerList[InnerList.IndexOf(oldObject)] = newObject;
            }
        }

        public virtual object Find(object o)
        {
            foreach(object myObject in this)
            {
                if (o == myObject)
                {
                    return(myObject);
                }
            }
            // object not found
            return null;
        }

        public virtual void Sort(IComparer iComparer)
        {
            this.InnerList.Sort(iComparer);
        }
    }
}
