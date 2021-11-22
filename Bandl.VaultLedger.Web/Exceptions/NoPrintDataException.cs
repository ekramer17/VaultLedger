using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Generic data access layer exception
    /// </summary>
    [Serializable]
    public class NoPrintDataException : ApplicationException
    {
        // Default constructor
        public NoPrintDataException() : base()
        {
        }

        // Constructor with exception message
        public NoPrintDataException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public NoPrintDataException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected NoPrintDataException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
