using System;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for ObjectComparer.
    /// </summary>
    public class ObjectComparer : IComparer
    {
        private string propertyName;

        /// <summary>
        /// Provides Comparison operations.
        /// </summary>
        /// <param name="propertyName">The property to compare</param>
        public ObjectComparer() : this(String.Empty) {}
        public ObjectComparer(string _propertyName) {propertyName = _propertyName;}
        /// <summary>
        /// Compares two objects by their properties, given on the constructor
        /// </summary>
        /// <param name="x">First object to compare</param>
        /// <param name="y">Second object to compare</param>
        /// <returns></returns>
        public int Compare(object x, object y)
        {
            object a = null;
            object b = null;
            // Assign the property if we have a property name, otherwise
            // use the objects themselves.
            if (propertyName.Length != 0)
            {
                a = x.GetType().GetProperty(propertyName).GetValue(x, null);
                b = y.GetType().GetProperty(propertyName).GetValue(y, null);
            }
            else
            {
                a = x;
                b = x;
            }
            // If one (or both) is null, return accordingly.  Otherwise
            // compare the two objects.
            if ( a != null && b == null )
            {
                return 1;
            }
            else if ( a == null && b != null )
            {
                return -1;
            }
            else if ( a == null && b == null )
            {
                return 0;
            }
            else
            {
                return ((IComparable)a).CompareTo(b);
            }
        }
	}
}
