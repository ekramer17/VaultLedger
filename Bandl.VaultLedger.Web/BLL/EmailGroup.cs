using System;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage email groups
    /// The Bandl.Library.VaultLedger.Model.OperatorDetails is used in most 
    /// methods and is used to store serializable information about an operator
    /// </summary>
    public class EmailGroup
    {
        /// <summary>Gets an email group</summary>
        /// <param name="name">Name of the group to retrieve</param>
        /// <returns>Email group</returns>
        public static EmailGroupDetails GetEmailGroup(string name)
        {
            return EmailGroupFactory.Create().GetEmailGroup(name);
        }

        /// <summary>Gets all the email groups in the system</summary>
        /// <returns>Email group collection</returns>
        public static EmailGroupCollection GetEmailGroups()
        {
            return EmailGroupFactory.Create().GetEmailGroups();
        }

        /// <summary>Gets the operators within an email group</summary>
        /// <param name="groupId">Id of the email group</param>
        /// <returns>Operator collection</returns>
        public static OperatorCollection GetOperators(EmailGroupDetails e)
        {
            return EmailGroupFactory.Create().GetOperators(e.Id);
        }

        /// <summary>
        /// Deletes email groups from the system
        /// </summary>
        public static void Delete(EmailGroupCollection ec)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that we have data
            if (ec == null || ec.Count == 0) return;
            // Delete the email groups
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                ec.ResetErrors();
                c.BeginTran("delete email group");
                IEmailGroup dal = EmailGroupFactory.Create(c);
                // Run through the objects, deleting them from the database
                foreach (EmailGroupDetails e in ec)
                {
                    try
                    {
                        if (e.ObjState != ObjectStates.Unmodified)
                        {
                            throw new ObjectStateException("Only an email group marked as unmodified may be deleted.");
                        }
                        else
                        {
                            dal.Delete(e);
                        }
                    }
                    catch (Exception ex)
                    {
                        c.RollbackTran();
                        ec.HasErrors = true;
                        e.RowError = ex.Message;
                        throw new CollectionErrorException(ec);
                    }
                }
                // Commit the transaction
                c.CommitTran();
            }
        }
 
        /// <summary>
        /// Creates a new email group
        /// </summary>
        /// <param name="e">
        /// Email group to create
        /// </param>
        /// <param name="o">
        /// Operators to add
        /// </param>
        public static void Create(EmailGroupDetails e, OperatorCollection o)
        {
            if (o == null || o.Count == 0)
                throw new ApplicationException("Group must contain at least one operator");
            else
                EmailGroupFactory.Create().Create(e, o);
        }
        
        /// <summary>
        /// Deletes email group operators from the system
        /// </summary>
        public static void EditOperators(EmailGroupDetails e, OperatorCollection o, bool[] isMember)
        {
            OperatorCollection oi = new OperatorCollection();    // inserts
            OperatorCollection od = new OperatorCollection();    // deletes
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the operator collection has the same number of elements
            // as the isMember array
            if (o.Count != isMember.Length)
                throw new ApplicationException("Member array should have same number of elements as operator collection");
            // Separate into inserts and deletes
            for (int i = 0; i < o.Count; i++)
            {
                if (isMember[i] == true)
                    oi.Add(o[i]);
                else
                    od.Add(o[i]);
            }
            // Insert and delete operators as necessary
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                IEmailGroup dal = EmailGroupFactory.Create(c);
                // Begin the transaction
                c.BeginTran();
                // Manipulate operators
                try
                {
                    // Run through the inserts
                    for (int i = 0; i < oi.Count; i++)
                        dal.InsertOperator(e, oi[i]);
                    // Run through the deletes
                    for (int i = 0; i < od.Count; i++)
                        dal.DeleteOperator(e, od[i]);
                }
                catch (Exception ex)
                {
                    c.RollbackTran();
                    throw new ApplicationException(ex.Message);
                }
                // Commit the transaction
                c.CommitTran();
           }
        }
    }
}