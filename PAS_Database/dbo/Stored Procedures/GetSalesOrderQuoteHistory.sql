/*************************************************************               
 ** File:  [GetSalesOrderQuoteHistory]               
 ** Author:  Ekta Chnadegra 
 ** Description: This stored procedure is used to GetSalesOrderQuoteHistory By Id.    
 ** Purpose:             
 ** Date:   28/02/2025          
              
 ** PARAMETERS: @SalesOrderQuoteFreightId BIGINT    
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    28/02/2025  Ekta Chandegra		Created    
         
-- EXEC GetSalesOrderQuoteHistory 909
************************************************************************/    
CREATE   PROCEDURE [dbo].[GetSalesOrderQuoteHistory] 
	@SalesOrderQuoteId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN	
			 SELECT 
				q.AuditSalesOrderQuoteId,
				q.SalesOrderQuoteId,
				q.SalesOrderQuoteNumber,
				q.OpenDate,
				q.CustomerId,
				q.CustomerName,
				q.CustomerCode,
				stat.Description AS StatusName,
				q.Version,
				q.EmployeeName,
				q.CustomerContactName,
				q.CreatedDate,
				q.UpdatedDate,
				q.IsNewVersionCreated,
				q.StatusId,
				q.QuoteExpireDate,
				q.CustomerReference,
				q.SalesPersonName,
				ct.CustomerTypeName AS CustomerType,
				ISNULL(so.SalesOrderNumber, '') AS SalesOrderNumber,
				q.LeadSourceName,
				q.ProbabilityName,
				q.UpdatedBy,
				q.CreatedBy,
				q.ValidForDays,
				q.IsDeleted
			FROM [dbo].[SalesOrderQuoteAudit] q WITH(NOLOCK)
			LEFT JOIN [dbo].[CustomerType] ct WITH(NOLOCK) ON q.AccountTypeId = ct.CustomerTypeId
			LEFT JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON q.SalesOrderQuoteId = so.SalesOrderQuoteId
			INNER JOIN [dbo].[MasterSalesOrderQuoteStatus] stat WITH(NOLOCK) ON q.StatusId = stat.Id
			WHERE q.SalesOrderQuoteId = @SalesOrderQuoteId
			ORDER BY q.AuditSalesOrderQuoteId DESC;
		END
	END TRY
	BEGIN  CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderQuoteHistory'     
        ,@ProcedureParameters VARCHAR(3000) = '@OldValue = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100))      
        , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
        exec spLogException     
                @DatabaseName           = @DatabaseName    
                , @AdhocComments          = @AdhocComments    
                , @ProcedureParameters = @ProcedureParameters    
                , @ApplicationName        =  @ApplicationName    
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
        RETURN(1); 
	END CATCH
END