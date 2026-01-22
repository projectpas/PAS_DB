CREATE   VIEW [dbo].[vw_ShippingVia]
AS
SELECT  sv.[CarrierId],sv.[ShippingViaId],sv.[Name],sv.[Memo],sv.[CreatedBy],sv.[UpdatedBy],sv.[CreatedDate],sv.[UpdatedDate],sv.[IsActive],sv.[IsDeleted],
		sv.[Description],ca.[Code],sv.[MasterCompanyId]
FROM	[dbo].ShippingVia sv
		LEFT JOIN dbo.Carrier ca WITH(NOLOCK) ON sv.CarrierId = ca.CarrierId