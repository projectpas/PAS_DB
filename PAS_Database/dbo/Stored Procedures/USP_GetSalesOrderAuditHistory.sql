/***************************************************************  
 ** File:   [USP_GetSalesOrderAuditHistory]             
 ** Author:   Shrey Chandegara
 ** Description: Get SalesOrder History
 ** Date:  01-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-04-2025		Shrey Chandegara		Created  	
		
	exec dbo.USP_GetSalesOrderAuditHistory 760,228
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalesOrderAuditHistory]
@SalesOrderId BIGINT,
@EmployeeId BIGINT

AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				)
			FROM
				dbo.Employee E WITH (NOLOCK)
			LEFT JOIN
				dbo.TimeZone ETZ WITH (NOLOCK)
				ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN
				dbo.LegalEntity LE WITH (NOLOCK)
				ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN
				dbo.TimeZone LTZ WITH (NOLOCK)
				ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
		SELECT 
			q.AuditSalesOrderId,
			q.SalesOrderId,
			soq.SalesOrderQuoteNumber,
			q.SalesOrderQuoteId,
			q.SalesOrderNumber,
			q.OpenDate,
			c.CustomerId,
			c.Name AS CustomerName,
			c.CustomerCode,
			s.Name AS Status,
			q.Version,
			COALESCE(emp.FirstName + ' ' + emp.LastName, '') AS Employee,
			COALESCE(custContactName.FirstName + ' ' + custContactName.LastName, '') AS Contact,
			(Cast(DBO.ConvertUTCtoLocal(q.CreatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(q.UpdatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) UpdatedDate,
			q.StatusId,
			q.CustomerReference,
			COALESCE(sp.FirstName + ' ' + sp.LastName, '') AS SalesPerson,
			ct.CustomerTypeName AS CustomerType,
			q.UpdatedBy,
			q.CreatedBy,
			'' AS Priority,
			q.IsDeleted,
			CASE 
				WHEN EXISTS (SELECT 1 FROM [dbo].[SalesOrderPartCost] WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId) 
				THEN (SELECT SUM(NetSaleAmount) FROM [dbo].[SalesOrderPartCost] WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId) + ISNULL(so.TotalCharges, 0)
				ELSE 0
			END AS Revenue
		FROM [dbo].[SalesOrderAudit] q WITH(NOLOCK)
		LEFT JOIN [dbo].[MasterSalesOrderQuoteStatus] s WITH(NOLOCK) ON q.StatusId = s.Id
		LEFT JOIN [dbo].[Customer] c WITH(NOLOCK) ON q.CustomerId = c.CustomerId
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON q.EmployeeId = emp.EmployeeId
		LEFT JOIN [dbo].[Employee] sp WITH(NOLOCK) ON q.SalesPersonId = sp.EmployeeId
		LEFT JOIN [dbo].[CustomerType] ct WITH(NOLOCK) ON q.AccountTypeId = ct.CustomerTypeId
		LEFT JOIN [dbo].[CustomerContact] custContact WITH(NOLOCK) ON q.CustomerContactId = custContact.CustomerContactId
		LEFT JOIN [dbo].[Contact] custContactName WITH(NOLOCK) ON custContact.ContactId = custContactName.ContactId
		LEFT JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON q.SalesOrderId = so.SalesOrderId
		LEFT JOIN [dbo].[SalesOrderQuote] soq WITH(NOLOCK) ON so.SalesOrderQuoteId = soq.SalesOrderQuoteId
		WHERE q.SalesOrderId = @SalesOrderId
		ORDER BY q.AuditSalesOrderId DESC;
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSalesOrderAuditHistory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END