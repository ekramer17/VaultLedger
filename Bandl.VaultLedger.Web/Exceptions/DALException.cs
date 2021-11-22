using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Generic data access layer exception
    /// </summary>
    [Serializable]
    public class DALException : BaseException
    {
        // Default constructor
        public DALException() : base()
        {
        }

        // Constructor with exception message
        public DALException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public DALException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected DALException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
