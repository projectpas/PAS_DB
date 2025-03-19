CREATE   VIEW [dbo].[vw_VendorStatus]
AS
	SELECT 
	VS.[VendorStatusId],
	VS.[Description],
	VS.Memo,
	VS.MasterCompanyId,
	VS.CreatedDate,
	VS.CreatedBy,
	VS.UpdatedDate,
	VS.UpdatedBy,
	VS.IsActive,
	VS.IsDeleted
	FROM [dbo].[VendorStatus] VS WITH (NOLOCK)