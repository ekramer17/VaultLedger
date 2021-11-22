using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Generic data access layer exception
    /// </summary>
    [Serializable]
    public class DataNotFoundException : DALException
    {
        // Default constructor
        public DataNotFoundException() : base()
        {
        }

        // Constructor with exception message
        public DataNotFoundException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public DataNotFoundException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected DataNotFoundException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
