/************************************************************************************           
 ** File:   [GetPOApprovalList]           
 ** Author: 
 ** Description: This stored procedure is used to get PO Approval List.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    4-01-2025			Amit Ghediya			Created

	 EXEC [dbo].[GetPOApprovalList] 6709,1
****************************************************************************************/
CREATE    PROCEDURE [dbo].[GetPOApprovalList]
	@PurchaseOrderId BIGINT,
	@IsInternalApprove BIT = 0
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

			DECLARE @ApprovalStatusPending INT = 1,
					@SentForInternalApproval INT = 1,
					@SubmitInternalApproval INT = 2,
					@Rejected INT = 3;
				
			SELECT 
				POP.partNumber,
				POP.partDescription,
				POP.itemType,
				POP.stockType,
				POP.QuantityOrdered AS qty,
				POP.unitCost,
				POP.ExtendedCost AS extCost,
				ISNULL(POA.ApprovedDate, GETUTCDATE()) AS approvedDate,
				ISNULL(POA.SentDate, GETUTCDATE()) AS sentDate,
				POA.ApprovedByName AS approvedBy,
				ISNULL(POA.RejectedDate, GETUTCDATE()) AS rejectedDate,
				POA.RejectedByName AS rejectedBy,
				POP.purchaseOrderId,
				POP.PurchaseOrderPartRecordId AS purchaseOrderPartId,
				ISNULL(POA.PurchaseOrderApprovalId, 0) AS purchaseOrderApprovalId,
				POP.masterCompanyId,
				ISNULL(POA.ApprovedById, 0) AS approvedById,
				ISNULL(POA.Memo, '') AS memo,
				ISNULL(POA.CreatedBy, POP.CreatedBy) AS createdBy,
				ISNULL(POA.CreatedDate, GETUTCDATE()) AS createdDate,
				ISNULL(POA.UpdatedBy, '') AS updatedBy,
				ISNULL(POA.UpdatedDate, GETUTCDATE()) AS updatedDate,
				1 AS isActive,
				0 AS isDeleted,
				CASE 
					WHEN @IsInternalApprove = 0 AND POA.PurchaseOrderApprovalId IS NULL THEN CAST(@SentForInternalApproval AS INT)
					ELSE ISNULL(POA.ActionId, CAST(@SentForInternalApproval AS INT))
				END AS actionId,
				CASE 
					WHEN @IsInternalApprove = 0 AND POA.PurchaseOrderApprovalId IS NULL THEN 'Send for Approval'
					WHEN POA.PurchaseOrderApprovalId IS NULL THEN 'Send for Approval'
					WHEN POA.ActionId = @SentForInternalApproval AND POA.StatusId = @Rejected THEN 'Returned to Requisitioner'
					WHEN POA.ActionId = @SentForInternalApproval THEN 'Send for Approval'
					WHEN POA.ActionId = @SubmitInternalApproval THEN 'Submit Approval' ELSE 'Approved'
				END AS actionStatus,
				ISNULL(POA.StatusId, @ApprovalStatusPending) AS statusId,
				POA.StatusName AS status,
				@IsInternalApprove AS isInternalApprove,
				POP.isParent AS isParent,
				POP.parentId,
				POP.altEquiPartNumberId,
				POP.altEquiPartNumber,
				POP.altEquiPartDescription,
				ISNULL(POA.InternalSentToId, 0) AS internalSentToId,
				ISNULL(POA.InternalSentToName, '') AS internalSentToName,
				ISNULL(POA.InternalSentById, 0) AS internalSentById,
				PO.purchaseOrderNumber
			FROM [DBO].[PurchaseOrderPart] POP WITH(NOLOCK)
			INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
			LEFT JOIN [DBO].[PurchaseOrderApproval] POA WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = POA.PurchaseOrderPartId
			WHERE 
				POP.PurchaseOrderId = @PurchaseOrderId
				AND POP.isParent = 1
				AND POP.IsActive = 1
				AND POP.IsDeleted = 0
				AND POP.QuantityOrdered > 0;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPOApprovalList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END