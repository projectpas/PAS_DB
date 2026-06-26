/*************************************************************           
 ** File:   [USP_GetRepairOrderPartApprovals]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get RepairOrder Part Approvals List By RepairOrder Id
 ** Date:   30/03/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    30/03/2023   Rajesh Gami     Created
	2    14-04-2025   Shrey Chandegara Updated Due to change Actionstatus ( @SentForCustomerApproval --> @SentForInternalApprovalId as per LINQ code)
	3    22/06/2026   Abhishek Jirawla	Adding IsPiecePart condition in RepairOrderPart table 
**************************************************************
exec USP_GetRepairOrderPartApprovals @RepairOrderId=2553,@IsInternalApprove=0
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetRepairOrderPartApprovals] 
	@RepairOrderId BIGINT,
    @IsInternalApprove BIT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY			  
			DECLARE @SentForInternalApprovalId INT = (SELECT TOP 1 ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE NAME ='SentForInternalApproval');
			DECLARE @SubmitInternalApproval INT = (SELECT TOP 1 ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE NAME ='SubmitInternalApproval');
			DECLARE @SentForCustomerApproval INT = (SELECT TOP 1 ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE NAME ='SentForCustomerApproval');
			DECLARE @SubmitCustomerApproval INT = (SELECT TOP 1 ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE NAME ='SubmitCustomerApproval');
			DECLARE @Approved INT = (SELECT TOP 1 ApprovalProcessId FROM DBO.ApprovalProcess WITH(NOLOCK) WHERE NAME ='Approved');
			DECLARE @RejectStatusId INT = (SELECT TOP 1 ApprovalStatusId FROM DBO.ApprovalStatus WITH(NOLOCK) WHERE NAME ='Rejected');
			DECLARE @PendingStatusId INT = (SELECT TOP 1 ApprovalStatusId FROM DBO.ApprovalStatus WITH(NOLOCK) WHERE NAME ='Pending');
			DECLARE @SendforApprovalStr VARCHAR(50) = 'Send for Approval',@ReturnedtoRequisitionerStr VARCHAR(50) = 'Returned to Requisitioner',@SubmitApprovalStr VARCHAR(50) = 'Submit Approval',@ApprovedStr VARCHAR(50) = 'Approved';
			
			SELECT DISTINCT
				rop.PartNumber,
				rop.PartDescription,
				rop.ItemType,
				rop.StockType,
				rop.QuantityOrdered AS Qty,
				ISNULL(rop.UnitCost,0)UnitCost,
				CONVERT(DECIMAL(18,2),(CASE 
					WHEN ISNULL(rop.ExtendedCost,0) > 0 THEN ISNULL(rop.ExtendedCost,0)
					ELSE 0
				END)) AS ExtCost,
				ISNULL(roa.ApprovedDate, GETDATE()) AS ApprovedDate,
				ISNULL(roa.SentDate, GETDATE()) AS SentDate,
				ISNULL(roa.ApprovedByName, '') AS ApprovedBy,
				ISNULL(roa.RejectedDate, GETDATE()) AS RejectedDate,
				ISNULL(roa.RejectedByName, '') AS RejectedBy,
				rop.RepairOrderId,
				rop.RepairOrderPartRecordId AS RepairOrderPartId,
				ISNULL(roa.RepairOrderApprovalId, 0) AS RepairOrderApprovalId,
				rop.MasterCompanyId,
				ISNULL(roa.ApprovedById, 0) AS ApprovedById,
				ISNULL(roa.Memo, '') AS Memo,
				ISNULL(roa.CreatedBy, rop.CreatedBy) AS CreatedBy,
				ISNULL(roa.CreatedDate, GETDATE()) AS CreatedDate,
				ISNULL(roa.UpdatedBy, '') AS UpdatedBy,
				ISNULL(roa.UpdatedDate, GETDATE()) AS UpdatedDate,
				1 AS IsActive,
				0 AS IsDeleted,
				CASE 
					WHEN @IsInternalApprove = 0 AND roa.RepairOrderApprovalId IS NULL THEN @SentForInternalApprovalId 
					WHEN roa.RepairOrderApprovalId IS NULL THEN @SentForInternalApprovalId 
					ELSE roa.ActionId
				END AS ActionId,
				CASE 
					WHEN @IsInternalApprove = 0 AND roa.RepairOrderApprovalId IS NULL THEN @SendforApprovalStr
					WHEN roa.RepairOrderApprovalId IS NULL THEN @SendforApprovalStr
					WHEN roa.ActionId = @SentForInternalApprovalId AND roa.StatusId = @RejectStatusId THEN @ReturnedtoRequisitionerStr -- Rejected
					WHEN roa.ActionId = @SentForInternalApprovalId THEN @SendforApprovalStr
					WHEN roa.ActionId = @SubmitInternalApproval THEN @SubmitApprovalStr
					ELSE @ApprovedStr
				END AS ActionStatus,
				ISNULL(roa.StatusId,@PendingStatusId) AS StatusId,
				ISNULL(roa.StatusName, '') AS [Status],
				@IsInternalApprove AS IsInternalApprove,
				ISNULL(rop.IsParent,0)IsParent,
				ISNULL(rop.ParentId,0)ParentId,
				rop.AltEquiPartNumberId,
				rop.AltEquiPartNumber,
				rop.AltEquiPartDescription,
				ISNULL(roa.InternalSentToId, 0) AS InternalSentToId,
				ISNULL(roa.InternalSentToName, '') AS InternalSentToName,
				ISNULL(roa.InternalSentById, 0) AS InternalSentById,
				ro.RepairOrderNumber
			FROM dbo.RepairOrderPart rop WITH(NOLOCK)
			INNER JOIN dbo.RepairOrder ro WITH(NOLOCK) ON rop.RepairOrderId = ro.RepairOrderId
			LEFT JOIN dbo.RepairOrderApproval roa WITH(NOLOCK) ON rop.RepairOrderPartRecordId = roa.RepairOrderPartId
			WHERE 
				rop.RepairOrderId = @RepairOrderId 	AND ISNULL(rop.IsDeleted,0) = 0	AND ISNULL(rop.IsParent,0) = 1	AND ISNULL(rop.QuantityOrdered,0) > 0
				AND ISNULL(ROP.[IsPiecePart], 0) = 0
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetRepairOrderPartApprovals]',
            @ProcedureParameters varchar(3000) = '@RepairOrderId = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END