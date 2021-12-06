
CREATE VIEW [dbo].[vw_vendor_list_main]
AS
SELECT        dbo.Vendor.VendorId, dbo.Vendor.VendorName, dbo.Vendor.VendorCode, dbo.Vendor.VendorTypeId, dbo.Vendor.VendorPhone, dbo.Vendor.VendorEmail, dbo.Contact.FirstName + ' ' + dbo.Contact.LastName AS ContactName, 
                         dbo.Address.City, dbo.Address.StateOrProvince, dbo.Vendor.IsActive, dbo.VendorType.Description AS VendorType
FROM            dbo.Vendor INNER JOIN
                         dbo.VendorContact ON dbo.Vendor.VendorId = dbo.VendorContact.VendorId INNER JOIN
                         dbo.Contact ON dbo.VendorContact.ContactId = dbo.Contact.ContactId INNER JOIN
                         dbo.Address ON dbo.Vendor.AddressId = dbo.Address.AddressId INNER JOIN
                         dbo.VendorType ON dbo.Vendor.VendorTypeId = dbo.VendorType.VendorTypeId
WHERE        (dbo.VendorContact.IsDefaultContact = 1) AND (dbo.Vendor.IsDeleted = 0)