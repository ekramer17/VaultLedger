using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Email Group DAL
    /// </summary>
    public interface IEmailGroup
    {
        /// <summary>
        /// Gets an email group
        /// </summary>
        /// <param name="name">
        /// Name of the group to retrieve
        /// </param>
        /// <returns>
        /// Email group
        /// </returns>
        EmailGroupDetails GetEmailGroup(string name);
            
        /// <summary>Gets all the email groups in the system</summary>
        /// <returns>Email group collection</returns>
        EmailGroupCollection GetEmailGroups();

        /// <summary>Gets the operators within an email group</summary>
        /// <param name="groupId">Id of the email group</param>
        /// <returns>Operator collection</returns>
        OperatorCollection GetOperators(int groupId);

        /// <summary>
        /// Deletes an existing email group
        /// </summary>
        /// <param name="e">Email group to delete</param>
        void Delete(EmailGroupDetails e);

        /// <summary>
        /// Creates a new email group
        /// </summary>
        /// <param name="e">
        /// Email group to create
        /// </param>
        /// <param name="o">
        /// Operators to add
        /// </param>
        void Create(EmailGroupDetails e, OperatorCollection o);

        /// <summary>
        /// Inserts an operator into an email group
        /// </summary>
        /// <param name="e">
        /// Email group to which to add operator
        /// </param>
        /// <param name="o">
        /// Operator to add
        /// </param>
        void InsertOperator(EmailGroupDetails e, OperatorDetails o);

        /// <summary>
        /// Delete an operator from an email group
        /// </summary>
        /// <param name="e">
        /// Email group from which to delete operator
        /// </param>
        /// <param name="o">
        /// Operator to delete
        /// </param>
        void DeleteOperator(EmailGroupDetails e, OperatorDetails o);
    }
}
