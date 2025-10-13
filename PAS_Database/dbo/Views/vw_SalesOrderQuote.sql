
CREATE   VIEW [dbo].[vw_SalesOrderQuote]
AS
	SELECT 
		SalesOrderQuoteNumber AS ReferenceNumber, 
		SalesOrderQuoteId as ReferenceId, 
		MasterCompanyId, 
		IsActive, 
		IsDeleted
	FROM [dbo].[SalesOrderQuote] WITH (NOLOCK)