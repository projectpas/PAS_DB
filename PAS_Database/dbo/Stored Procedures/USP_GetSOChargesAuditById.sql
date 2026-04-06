/*************************************************************           
 ** File:   [USP_GetSOChargesAuditById]           
 ** Author:   Vishal Suthar
 ** Description: Get Sales Order Charges Audit By Id
 ** Purpose:         
 ** Date:   04-Apr-2026  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date          Author          Change Description            
 ** --   --------      -------         --------------------------------          
    1    04-Apr-2026   Vishal Suthar   Created
     
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSOChargesAuditById]
    @SalesOrderChargesId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            soc.AuditSalesOrderChargesId,
            soc.SalesOrderChargesId,
            soc.SalesOrderQuoteId,
            soc.SalesOrderPartId,
            soc.SalesOrderId,
            soc.ChargesTypeId,
            ct.ChargeType,
            soc.Description,
            soc.Quantity,
            soc.UnitCost,
            soc.ExtendedCost,
            soc.VendorId,
            ISNULL(v.VendorName, '') AS VendorName,
            soc.HeaderMarkupPercentageId,
            soc.MarkupFixedPrice,
            soc.BillingAmount,
            soc.BillingMethodId,
            soc.HeaderMarkupId,
            soc.BillingRate,
            soc.MarkupPercentageId,
            soc.CreatedBy,
            soc.CreatedDate,
            soc.IsActive,
            soc.IsDeleted,
            soc.MasterCompanyId,
            soc.UpdatedBy,
            soc.UpdatedDate,
            soc.RefNum,
            ISNULL(gl.AccountName, '') AS GLAccountName
        FROM dbo.SalesOrderChargesAudit soc WITH (NOLOCK)
        INNER JOIN dbo.Charge ct     WITH (NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
        LEFT  JOIN dbo.Vendor v      WITH (NOLOCK) ON soc.VendorId = v.VendorId
        LEFT  JOIN dbo.GLAccount gl  WITH (NOLOCK) ON ct.GLAccountId = gl.GLAccountId
        WHERE soc.IsDeleted = 0
          AND soc.SalesOrderChargesId = @SalesOrderChargesId
        ORDER BY soc.AuditSalesOrderChargesId DESC;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID INT
            ,@DatabaseName VARCHAR(100) = db_name()
            ,@AdhocComments VARCHAR(150) = 'USP_GetSOChargesAuditById'
            ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderChargesId, '') AS VARCHAR(100))
            ,@ApplicationName VARCHAR(100) = 'PAS'

        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

        RETURN (1);
    END CATCH
END;