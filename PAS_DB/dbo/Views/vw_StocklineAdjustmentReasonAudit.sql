CREATE   VIEW [dbo].[vw_StocklineAdjustmentReasonAudit]
AS
	SELECT ipor.AdjustmentReasonAuditId  AS PkID, ipor.AdjustmentReasonId AS ID	,ipor.Description, 0 [Sequence No]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].StocklineAdjustmentReasonAudit ipor WITH (NOLOCK)