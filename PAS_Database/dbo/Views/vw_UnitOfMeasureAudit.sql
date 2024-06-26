--DROP VIEW [dbo].[vw_UnitOfMeasureAudit]
CREATE VIEW [dbo].[vw_UnitOfMeasureAudit]
AS
	SELECT ipor.UnitOfMeasureAuditId  AS PkID, ipor.UnitOfMeasureId AS ID	,ipor.Description ,ipor.ShortName , ipor.StandardName , ipor.SequenceNo
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].UnitOfMeasureAudit ipor WITH (NOLOCK)