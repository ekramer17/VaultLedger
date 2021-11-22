using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Summary description for DataLayerException.
    /// </summary>
    [Serializable]
    public class DatabaseException : ApplicationException
    {
        // Default constructor
        public DatabaseException() : base()
        {
        }

        // Constructor with exception message
        public DatabaseException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public DatabaseException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected DatabaseException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
