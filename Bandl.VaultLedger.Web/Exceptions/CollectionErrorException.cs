using System;
using System.Collections;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
	/// <summary>
	/// Thrown when at least one details object within a collection object 
	/// passed to the BLL has a error.
	/// </summary>
	[Serializable]
	public class CollectionErrorException : BLLException
	{
        private CollectionBase collection;

        public CollectionBase Collection
        {
            get {return collection;}
        }

        // Default constructor
        public CollectionErrorException() : base()
        {
        }

        // Constructor with exception message
        public CollectionErrorException(string message) : base(message)
        {
        }

        // Default constructor
        public CollectionErrorException(CollectionBase _collection) : base()
        {
            collection = _collection;
        }

        // Default constructor
        public CollectionErrorException(CollectionBase _collection, string message) : base(message)
        {
            collection = _collection;
        }

        // Constructor with message and inner exception
        public CollectionErrorException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected CollectionErrorException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
