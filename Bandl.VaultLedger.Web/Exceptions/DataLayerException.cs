using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Summary description for DataLayerException.
    /// </summary>
    [Serializable]
    public class DataLayerException : ApplicationException
    {
        // Default constructor
        public DataLayerException() : base()
        {
        }

        // Constructor with exception message
        public DataLayerException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public DataLayerException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected DataLayerException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
