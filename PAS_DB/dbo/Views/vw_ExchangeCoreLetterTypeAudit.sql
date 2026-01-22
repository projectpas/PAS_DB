CREATE   VIEW [dbo].[vw_ExchangeCoreLetterTypeAudit]
AS
	SELECT EC.ExchangeCoreLetterTypeAuditId  AS PkID,
	EC.ExchangeCoreLetterTypeId AS ID	,
	EC.[Name],
	EC.SequenceNo [Sequence No],
	EC.CreatedBy AS [Created By],
	EC.CreatedDate AS [Created On],
	EC.UpdatedBy AS [Updated By],
	EC.UpdatedDate AS [Updated On],
	EC.IsActive AS [Is Active],
	EC.IsDeleted AS [Is Deleted]
	FROM [DBO].[ExchangeCoreLetterTypeAudit] EC WITH (NOLOCK)