
CREATE   VIEW [dbo].[vw_AssetAcquisitionTypeAudit]
AS
	SELECT AAT.AssetAcquisitionTypeAuditId  AS PkID,
	AAT.AssetAcquisitionTypeId AS ID,
	AAT.Name as [Acquisition Type],
	AAT.Code as [Acquisition Code],
	AAT.[Memo],
	AAT.SequenceNo as [Sequence No],
	AAT.CreatedBy AS [Created By],
	AAT.CreatedDate AS [Created On],
	AAT.UpdatedBy AS [Updated By],
	AAT.UpdatedDate AS [Updated On],
	AAT.IsActive AS [Is Active],
	AAT.IsDeleted AS [Is Deleted]
	FROM [DBO].AssetAcquisitionTypeAudit AAT WITH (NOLOCK)
GO



GO


