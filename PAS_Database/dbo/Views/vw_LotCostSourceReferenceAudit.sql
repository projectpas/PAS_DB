CREATE VIEW [dbo].[vw_LotCostSourceReferenceAudit]
AS
	SELECT ipor.LotSourceAuditId  AS PkID, ipor.LotSourceId AS ID,ipor.SourceName , ipor.Code , ipor.MasterCompanyId , ipor.SequenceNo
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].LotCostSourceReferenceAudit ipor WITH (NOLOCK)