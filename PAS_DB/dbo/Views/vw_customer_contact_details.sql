CREATE VIEW [dbo].[vw_customer_contact_details]
AS
SELECT        dbo.Contact.ContactId, dbo.Contact.Prefix, dbo.Contact.FirstName, dbo.Contact.LastName, dbo.Contact.MiddleName, dbo.Contact.Suffix, dbo.Contact.ContactTitle, dbo.Contact.WorkPhone, dbo.Contact.WorkPhoneExtn, 
                         dbo.Contact.MobilePhone, dbo.Contact.AlternatePhone, dbo.Contact.Fax, dbo.Contact.Email, dbo.Contact.WebsiteURL, dbo.Contact.Notes, dbo.Contact.Tag, dbo.CustomerContact.CustomerId, 
                         dbo.CustomerContact.CustomerContactId, dbo.CustomerContact.IsDefaultContact, dbo.CustomerContact.IsActive
FROM            dbo.Contact LEFT OUTER JOIN
                         dbo.CustomerContact ON dbo.Contact.ContactId = dbo.CustomerContact.ContactId
WHERE        (dbo.CustomerContact.IsDeleted = 0)