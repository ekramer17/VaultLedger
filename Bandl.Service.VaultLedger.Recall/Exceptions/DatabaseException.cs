using System;
using System.Runtime.Serialization;

namespace Bandl.Service.VaultLedger.Recall.Exceptions
{
    /// <summary>
    /// Summary description for DatabaseException.
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
