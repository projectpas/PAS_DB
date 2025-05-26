/*************************************************************
 ** File:   [USP_GetExchangeQuoteHistoryByExchangeSalesOrderId]
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeQuoteHistoryByExchangeSalesOrderId
 ** Purpose:
 ** Date:   05/20/2025
    
 ** PARAMETERS: @ExchangeSalesOrderId BIGINT, @EmployeeId BIGINT

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------   
	1    05/20/2025   EKTA CHANDEGRA	Created
	

exec dbo.USP_GetExchangeQuoteHistoryByExchangeSalesOrderId @ExchangeSalesOrderId=156 , @EmployeeId=223
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteHistoryByExchangeSalesOrderId]
    @ExchangeSalesOrderId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

		-- Main query
		SELECT 
			q.AuditExchangeSalesOrderId,
			q.ExchangeSalesOrderId,
			q.ExchangeQuoteId,
			q.ExchangeSalesOrderNumber,
			ISNULL(q.ExchangeQuoteNumber,'') AS ExchangeQuoteNumber,
			q.OpenDate,
			q.CustomerId,
			q.CustomerName,
			q.CustomerCode,
			stat.Name AS Status,
			q.Version,
			(Cast(DBO.ConvertUTCtoLocal(q.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(q.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS UpdatedDate,
			q.StatusId,
			q.CustomerReference,
			ISNULL(q.SalesPersonName,'') AS SalesPerson,
			q.UpdatedBy,
			q.CreatedBy,
			ISNULL(q.IsDeleted,0) AS IsDeleted
		FROM [dbo].[ExchangeSalesOrderAudit] q WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeStatus] stat WITH(NOLOCK) ON q.StatusId = stat.ExchangeStatusId
		WHERE q.ExchangeSalesOrderId = @ExchangeSalesOrderId
		ORDER BY q.AuditExchangeSalesOrderId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteHistoryByExchangeSalesOrderId'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@ExchangeSalesOrderId AS varchar(10)) ,'') +''',
												 @Parameter2 = ' + ISNULL(CAST(@EmployeeId AS varchar(10)) ,'') +''

        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END;