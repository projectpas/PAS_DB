/*************************************************************               
 ** File:   [USP_GetPOHistory]              
 ** Author:   Ayushi Patel      
 ** Description: Get PurchaseOrder history details by PurchaseOrderId  
 ** Purpose:             
 ** Date:   03-April-2025           
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 **  S NO   Date         Author    Change Description                
 **  --   --------      --------  --------------------------------              
      1  03-April-2025   Ayushi   created      
  
**************************************************************/    
CREATE   PROCEDURE [dbo].[USP_GetPOHistory]
    @PurchaseOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT 
            po.PurchaseOrderAuditId,
            po.PurchaseOrderId,
            po.PurchaseOrderNumber,
            po.OpenDate,
            po.ClosedDate,
            po.NeedByDate,
            po.Priority,
            po.VendorName,
            po.VendorCode,
            po.VendorContact,
            po.VendorContactPhone AS ContactPhone,
            po.Terms AS CreditTerms,
            po.CreditLimit,
            po.DateApproved,
            po.Resale,
            po.DeferredReceiver,
            po.Status,
            po.Requisitioner AS RequestedBy,
            po.ApprovedBy,
            po.CreatedBy,
            po.CreatedDate,
            po.UpdatedBy,
            po.UpdatedDate,
            po.IsActive,
            po.IsDeleted
        FROM dbo.PurchaseOrderAudit po WITH (NOLOCK)
        WHERE po.PurchaseOrderId = @PurchaseOrderId
        ORDER BY po.PurchaseOrderAuditId DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetPOHistory',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH;
END