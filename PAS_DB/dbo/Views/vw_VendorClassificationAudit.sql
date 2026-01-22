CREATE   VIEW [dbo].[vw_VendorClassificationAudit]
AS
	SELECT ipor.VendorClassificationAuditId  AS PkID, ipor.VendorClassificationId AS ID	,ipor.ClassificationName, 0 [Sequence No]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].VendorClassificationAudit ipor WITH (NOLOCK)