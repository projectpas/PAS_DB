
CREATE VIEW [dbo].[view_CustomerVendorCompanyList] AS
SELECT CustomerId AS ReferenceId, [Name] AS RefName, MasterCompanyId, IsActive, IsDeleted
FROM DBO.Customer WITH (NOLOCK)
UNION
SELECT VendorId AS ReferenceId, [VendorName] AS RefName, MasterCompanyId, IsActive, IsDeleted
FROM DBO.Vendor WITH (NOLOCK)
UNION
SELECT LegalEntityId AS ReferenceId, [Name] AS RefName, MasterCompanyId, IsActive, IsDeleted
FROM DBO.LegalEntity WITH (NOLOCK)