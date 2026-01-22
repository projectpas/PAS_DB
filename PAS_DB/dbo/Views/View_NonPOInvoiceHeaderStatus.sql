

CREATE  VIEW [dbo].[View_NonPOInvoiceHeaderStatus]
AS
	SELECT [NonPOInvoiceHeaderStatusId]
          ,[Description]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[CreatedDate]
          ,[UpdatedBy]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
      FROM [dbo].[NonPOInvoiceHeaderStatus] WITH(NOLOCK) 
	 WHERE [Description] NOT IN ('Pending','Fulfilling','Closed')