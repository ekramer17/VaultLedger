using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Summary description for DataStateException.
    /// </summary>
    [Serializable]
    public class DataStateException : BusinessLogicException
    {
        // Default constructor
        public DataStateException() : base()
        {
        }

        // Constructor with exception message
        public DataStateException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public DataStateException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected DataStateException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
