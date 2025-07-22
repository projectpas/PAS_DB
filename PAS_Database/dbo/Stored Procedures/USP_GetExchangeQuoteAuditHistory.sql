/*************************************************************           
 ** File:   [USP_GetExchangeQuoteAuditHistory]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteAuditHistory
 ** Purpose:         
 ** Date:   07/17/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT,   @EmployeeId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/17/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeQuoteAuditHistory @ExchangeQuoteId = 10119, @EmployeeId = 237

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteAuditHistory]
    @ExchangeQuoteId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
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
				E.EmployeeId = @EmployeeId;

		SELECT 
			q.AuditExchangeQuoteId,
			q.ExchangeQuoteId,
			q.ExchangeQuoteNumber,
			q.OpenDate,
			q.CustomerId,
			q.CustomerName,
			q.CustomerCode,
			stat.Name AS Status,
			q.Version,
			q.CustomerContactName,
			(Cast(DBO.ConvertUTCtoLocal(q.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) AS CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(q.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) AS UpdatedDate,
			q.StatusId,
			q.QuoteExpireDate,
			q.CustomerReference,
			q.SalesPersonName,
			q.UpdatedBy,
			q.CreatedBy,
			ISNULL(q.IsDeleted,0) AS IsDeleted
		FROM [dbo].[ExchangeQuoteAudit] q WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeStatus] stat WITH(NOLOCK) ON q.StatusId = stat.ExchangeStatusId
		WHERE q.ExchangeQuoteId = @ExchangeQuoteId
		ORDER BY q.AuditExchangeQuoteId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteAuditHistory'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteId = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100)) + ''','+
												   '@EmployeeId = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END