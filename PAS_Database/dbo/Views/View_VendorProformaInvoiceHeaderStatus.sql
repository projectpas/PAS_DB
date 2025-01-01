
CREATE   VIEW [dbo].[View_VendorProformaInvoiceHeaderStatus]
AS
	SELECT TOP 100 [VendorProformaInvoiceHeaderStatusId]
          ,[Description]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[CreatedDate]
          ,[UpdatedBy]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
      FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) 
	  WHERE [Description] NOT IN ('Pending','Fulfilling') ORDER BY VendorProformaInvoiceHeaderStatusId