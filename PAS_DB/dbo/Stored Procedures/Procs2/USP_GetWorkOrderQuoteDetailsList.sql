/*************************************************************           
 ** File:   [USP_GetWorkOrderQuoteDetailsList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get WorkOrder Quote Details List
 ** Purpose:         
 ** Date:   05-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    05-05-2025    Sahdev Saliya       Created  

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderQuoteDetailsList] 
    @WorkOrderQuoteId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

			SELECT DISTINCT
				woq.WorkOrderQuoteId,
				wo.WorkOrderId,
				woq.QuoteNumber,
				woq.OpenDate,
				woq.QuoteDueDate,
				woq.ValidForDays,
				woq.ExpirationDate,
				wqs.Description AS QuoteStatus,
				wo.WorkOrderNum,
				cust.Name AS CustomerName,
				cust.CustomerCode,
				ISNULL(con.FirstName, '') AS CustomerContact,
				cust.Email AS CustomerEmail,
				cust.CustomerPhone,
				cust.ContractReference AS CustomerRef,
				woq.AccountsReceivableBalance AS ARBalance,
				ISNULL(cf.CreditLimit, 0) AS CreditLimit,
				ISNULL(ct.Name, '') AS CreditTerms,
				ISNULL(sp.FirstName, '') AS SalesPerson,
				ISNULL(csr.FirstName, '') AS CSR,
				ISNULL(emp.FirstName, '') AS Employee,
				cur.Symbol AS Currency,
				woq.DSO,
				woq.Warnings,
				woq.Memo,
				woq.ApprovedDate,
				woq.SentDate,
				woq.VersionNo
			FROM [dbo].WorkOrderQuote AS woq WITH(NOLOCK)
			INNER JOIN [dbo].WorkOrder AS wo WITH(NOLOCK) ON woq.WorkOrderId = wo.WorkOrderId
			INNER JOIN [dbo].WorkOrderPartNumber AS wop WITH(NOLOCK) ON woq.WorkOrderId = wop.WorkOrderId
			INNER JOIN [dbo].WorkOrderQuoteStatus AS wqs WITH(NOLOCK) ON woq.QuoteStatusId = wqs.WorkOrderQuoteStatusId
			INNER JOIN [dbo].Customer AS cust WITH(NOLOCK) ON woq.CustomerId = cust.CustomerId
			LEFT JOIN [dbo].CustomerSales AS cs WITH(NOLOCK) ON cust.CustomerId = cs.CustomerId
			LEFT JOIN [dbo].CustomerFinancial AS cf WITH(NOLOCK) ON cust.CustomerId = cf.CustomerId
			INNER JOIN [dbo].Currency cur WITH(NOLOCK) ON woq.CurrencyId = cur.CurrencyId
			LEFT JOIN [dbo].CreditTerms AS ct WITH(NOLOCK) ON cf.CreditTermsId = ct.CreditTermsId
			LEFT JOIN [dbo].Employee AS sp WITH(NOLOCK) ON wo.SalesPersonId = sp.EmployeeId
			LEFT JOIN [dbo].Employee AS csr WITH(NOLOCK) ON cs.PrimarySalesPersonId = csr.EmployeeId
			LEFT JOIN [dbo].Employee AS emp WITH(NOLOCK) ON wo.EmployeeId = emp.EmployeeId
            LEFT JOIN [dbo].CustomerContact cc WITH(NOLOCK) ON cust.CustomerId = cc.CustomerId AND cc.IsDefaultContact = 1
			LEFT JOIN [dbo].Contact AS con WITH(NOLOCK) ON cc.ContactId = con.ContactId
			WHERE woq.IsDeleted = 0 
				AND woq.WorkOrderQuoteId = @WorkOrderQuoteId

	END TRY    
	BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderQuoteDetailsList' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteId, '') AS varchar(100)) 
			 
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END