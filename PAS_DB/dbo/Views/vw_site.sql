
CREATE VIEW [dbo].[vw_site]
AS
SELECT        S.SiteId, S.Name, S.Memo, S.MasterCompanyId, S.CreatedBy, S.UpdatedBy, S.CreatedDate, S.UpdatedDate, 
			  S.IsActive, S.IsDeleted, S.LegalEntityId,C.nice_name AS Country, AD.Line1, AD.Line2, AD.Line3, 
			  AD.City, AD.StateOrProvince, AD.PostalCode, AD.AddressId, AD.CountryId,ISNULL(LE.Name,'') AS LegalEntity
FROM          [Address] AD 
			  INNER JOIN dbo.Countries C ON AD.CountryId = C.countries_id 
			  INNER JOIN dbo.Site S ON AD.AddressId = S.AddressId
			  LEFT JOIN LegalEntity LE ON S.LegalEntityId=LE.LegalEntityId