
CREATE   VIEW [dbo].[vw_CurrencyAudit]
AS
	SELECT ca.CurrencyAuditId  AS PkID, ca.CurrencyId AS ID	,ca.Code,ca.Symbol ,ca.DisplayName [Display ame]
	,ca.CreatedBy AS [Created By],
	ca.CreatedDate AS [Created Date], ca.UpdatedBy AS [Updated By], ca.UpdatedDate AS [Updated Date], ca.IsActive AS [Is Active], ca.IsDeleted AS [Is Deleted]
	FROM [DBO].CurrencyAudit ca WITH (NOLOCK)