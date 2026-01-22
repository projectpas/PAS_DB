CREATE   VIEW [dbo].[vw_CustomerClassificationAudit]
AS
	SELECT ipor.CustomerClassificationAuditId  AS PkID, ipor.CustomerClassificationId AS ID	,ipor.Description ,ipor.SequenceNo [Sequence No]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].CustomerClassificationAudit ipor WITH (NOLOCK)