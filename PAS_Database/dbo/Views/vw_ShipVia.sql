--DROP VIEW [dbo].[vw_ShipVia]
CREATE   VIEW [dbo].[vw_ShipVia]
AS
	SELECT ipor.AuditShippingViaId  AS PkID, ipor.ShippingViaId AS ID ,ipor.Name
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].ShippingViaAudit ipor WITH (NOLOCK)