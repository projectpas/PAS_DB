
CREATE     VIEW [dbo].[vw_legalEntity]
AS
SELECT        l.Name, l.MasterCompanyId, l.CreatedBy, l.UpdatedBy, l.CreatedDate, l.UpdatedDate, 
			  l.IsActive, l.IsDeleted, l.LegalEntityId,C.nice_name AS Country, AD.Line1, AD.Line2, AD.Line3, 
			  AD.City, AD.StateOrProvince, AD.PostalCode, AD.AddressId, AD.CountryId,ISNULL(LE.Name,'') AS LegalEntity
FROM          [Address] AD 
			  INNER JOIN dbo.Countries C ON AD.CountryId = C.countries_id 
			  INNER JOIN dbo.LegalEntity l ON AD.AddressId = l.AddressId
			  LEFT JOIN LegalEntity LE ON l.LegalEntityId=LE.LegalEntityId