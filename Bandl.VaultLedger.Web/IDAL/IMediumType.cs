using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the MediumType DAL
    /// </summary>
    public interface IMediumType
    {
        /// <summary>
        /// Gets the number of medium types in the database
        /// </summary>
        /// <param name="container">
        /// Whether to get count for container types (true) or non-container 
        /// types (false)
        /// </param>
        /// <returns>
        /// Number of types in the database
        /// </returns>
        int GetMediumTypeCount(bool container);

        /// <summary>
        /// Get a medium type from the data source based on the unique name
        /// </summary>
        /// <param name="name">Unique identifier for a medium type</param>
        /// <returns>Medium type information</returns>
        MediumTypeDetails GetMediumType(string name);

        /// <summary>
        /// Get a medium type from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for a medium type</param>
        /// <returns>Medium type information</returns>
        MediumTypeDetails GetMediumType(int id);

        /// <summary>
        /// Returns a collection of all the medium types
        /// </summary>
        /// <returns>Collection of all the medium types</returns>
        MediumTypeCollection GetMediumTypes();

        /// <summary>
        /// Returns the contents of the MediumType table, containers or non-containers only
        /// </summary>
        /// <param name="containerTypes">
        /// Returns container types if true, non-container types if false
        /// </param>
        /// <returns>
        /// Returns all of the appropriate medium types known to the system
        /// </returns>
        MediumTypeCollection GetMediumTypes(bool containerTypes);

        /// <summary>
        /// Inserts a new medium type into the system
        /// </summary>
        /// <param name="type">
        /// Medium type to insert
        /// </param>
        void Insert(MediumTypeDetails type);

        /// <summary>
        /// Updates an existing medium type
        /// </summary>
        /// <param name="type">
        /// Medium type to update
        /// </param>
        void Update(MediumTypeDetails type);

        /// <summary>
        /// Deletes an existing medium type
        /// </summary>
        /// <param name="type">
        /// Medium type to delete
        /// </param>
        void Delete(MediumTypeDetails type);
    }
}
