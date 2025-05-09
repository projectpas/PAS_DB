/*************************************************************           
 ** File:   [USP_GetWorkFlowWorkOrderQuoteList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get WorkFlow WorkOrder Quote List
 ** Purpose:         
 ** Date:   08-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    08-05-2025    Sahdev Saliya       Created  

-- EXEX USP_GetWorkFlowWorkOrderQuoteList 8543, 8806
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetWorkFlowWorkOrderQuoteList]
    @wfwoId BIGINT,
    @workOrderId BIGINT 
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		 BEGIN TRY
		     SELECT
			        wq.WorkOrderQuoteId,
					wq.WorkOrderId,
					wq.QuoteNumber,
					wq.OpenDate,
					wq.QuoteDueDate,
					wq.ValidForDays,
					wq.ExpirationDate,
					wq.QuoteStatusId,
					wq.DSO,
					wq.VersionNo,
					wq.QuoteParentId,
					wq.IsVersionIncrease,
					'' AS CustomerReference,
					wo.WorkOrderTypeId,
					wq.MasterCompanyId,
					wq.CreatedBy,
					wq.CreatedDate,
					wq.UpdatedBy,
					wq.UpdatedDate,
					wq.IsActive,
					wq.IsDeleted,
				    wo.WorkOrderNum AS WorkOrderNumber,
					cur.Symbol AS CurrencyName,
					cur.Code AS CurrencyCode,
					wq.CustomerName,
					wq.CustomerContact,
					cust.CustomerCode,
					cust.Email AS CustomerEmail,
					cust.CustomerPhone,
					ISNULL(csr.FirstName, '') AS CSRName,
					wq.CreditLimit,
					wq.CreditTerms AS CreditTerm,
					wo.CreditTermId,
					ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS SalesPersonName,
					ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS EmployeeName,
					wq.Warnings,
					wq.Memo,
					wq.AccountsReceivableBalance,
					ISNULL(qd.BuildMethodId, 0) AS BuildMethodId,
					wq.CustomerId,
					wq.EmployeeId,
					wq.SalesPersonId,
					ISNULL(qd.WorkOrderQuoteDetailsId, 0) AS QuoteDetailId,
					wq.ApprovedDate,
					wq.SentDate,
					wq.IsApprovalBypass,
					wq.Notes,
					wq.CurrencyId,
					wq.ReportCurrencyId,
					wq.ForeignExchangeRate
				FROM [dbo].WorkOrderQuote wq WITH(NOLOCK)
				INNER JOIN [dbo].WorkOrder wo WITH(NOLOCK) ON wq.WorkOrderId = wo.WorkOrderId
				INNER JOIN [dbo].Customer cust WITH(NOLOCK) ON wq.CustomerId = cust.CustomerId
				INNER JOIN [dbo].Currency cur WITH(NOLOCK) ON wq.CurrencyId = cur.CurrencyId
				LEFT JOIN [dbo].Employee emp WITH(NOLOCK) ON wq.EmployeeId = emp.EmployeeId
				LEFT JOIN [dbo].Employee sp WITH(NOLOCK) ON wq.SalesPersonId = sp.EmployeeId
				LEFT JOIN [dbo].Employee csr WITH(NOLOCK) ON wo.CSRId = csr.EmployeeId
				LEFT JOIN [dbo].WorkOrderQuoteDetails qd WITH(NOLOCK) ON wq.WorkOrderQuoteId = qd.WorkOrderQuoteId AND qd.IsVersionIncrease = 0
				WHERE wq.WorkOrderId = @workOrderId
				  AND ISNULL(wq.IsDeleted,0) = 0
				  AND ISNULL(wq.IsVersionIncrease,0) = 0;
		END TRY    
	BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkFlowWorkOrderQuoteList' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@wfwoId, '') + ''',  
                    @Parameter2 = ' + ISNULL(@workOrderId ,'') 
			 
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