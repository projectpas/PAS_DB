
CREATE VIEW [dbo].[vw_customer_contact_ata_list]
AS
SELECT        dbo.CustomerContactATAMapping.ATAChapterName, dbo.Contact.FirstName + ' ' + dbo.Contact.LastName AS ContactName, dbo.CustomerContactATAMapping.ATASubChapterDescription, dbo.Contact.ContactId, 
                         dbo.CustomerContactATAMapping.CustomerId, dbo.CustomerContactATAMapping.CustomerContactId
FROM            dbo.CustomerContactATAMapping INNER JOIN
                         dbo.CustomerContact ON dbo.CustomerContactATAMapping.CustomerContactId = dbo.CustomerContact.CustomerContactId INNER JOIN
                         dbo.Contact ON dbo.CustomerContact.ContactId = dbo.Contact.ContactId