
/************************************************************************/

CREATE  VIEW [dbo].[View_VendorProformaInvoiceHeaderStatus]
AS
	SELECT [VendorProformaInvoiceHeaderStatusId]
          ,[Description]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[CreatedDate]
          ,[UpdatedBy]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
      FROM [dbo].[VendorProformaInvoiceHeaderStatus] WITH(NOLOCK) 
	 WHERE [Description] NOT IN ('Pending','Fulfilling','Closed')