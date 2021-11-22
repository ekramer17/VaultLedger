using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
	/// <summary>
	/// Summary description for BusinessLogicException.
	/// </summary>
	[Serializable]
	public class BusinessLogicException : ApplicationException
	{
        // Default constructor
        public BusinessLogicException() : base()
        {
        }

        // Constructor with exception message
        public BusinessLogicException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public BusinessLogicException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected BusinessLogicException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
