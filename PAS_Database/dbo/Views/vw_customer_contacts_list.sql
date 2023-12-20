
CREATE VIEW [dbo].[vw_customer_contacts_list]
AS
SELECT        dbo.Contact.ContactId, dbo.Contact.FirstName, dbo.Contact.LastName, dbo.Contact.Tag, dbo.Contact.MiddleName, dbo.Contact.ContactTitle, dbo.Contact.WorkPhone, dbo.Contact.MobilePhone, dbo.Contact.Fax, 
                         dbo.Contact.Email, dbo.Contact.WorkPhoneExtn, dbo.CustomerContact.IsDefaultContact, dbo.CustomerContact.CustomerId, dbo.CustomerContact.IsActive, dbo.CustomerContact.IsDeleted
FROM            dbo.Contact INNER JOIN
                         dbo.CustomerContact ON dbo.Contact.ContactId = dbo.CustomerContact.ContactId