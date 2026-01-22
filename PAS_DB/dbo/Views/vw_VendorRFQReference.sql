CREATE   VIEW [dbo].[vw_VendorRFQReference]
AS
	WITH ReferenceResult AS(
		SELECT VendorRFQPurchaseOrderNumber AS ReferenceNumber, VendorRFQPurchaseOrderId as ReferenceId, MasterCompanyId, IsActive, IsDeleted
		FROM [dbo].[VendorRFQPurchaseOrder] WITH (NOLOCK)

		UNION

		SELECT VendorRFQRepairOrderNumber AS ReferenceNumber, VendorRFQRepairOrderId as ReferenceId, MasterCompanyId, IsActive, IsDeleted
		FROM [dbo].[VendorRFQRepairOrder] WITH (NOLOCK)
	),
	Result AS (
		SELECT ReferenceNumber, MAX(ReferenceId) AS ReferenceId, MasterCompanyId, CAST(MAX(CONVERT(INT, IsActive)) AS BIT) AS IsActive, CAST(MAX(CONVERT(INT, IsDeleted)) AS BIT) AS IsDeleted
		FROM ReferenceResult GROUP BY ReferenceNumber, MasterCompanyId
	)
	SELECT * FROM Result