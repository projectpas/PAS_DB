-- =============================================
-- Author:		Ekta Chandegra
-- Create date: 09/01/2024
-- Description:	This stored procedure is used to retrieve unit sales price history.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    09/01/2024   Ekta Chandegra		Created
	2    20/02/2025   Ayushi Patel    converted the date into utc (created , updated) , Added a case to get timeZone
	EXEC [GetUnitSalePriceHistoryById] 163178

**************************************************************/

CREATE   PROC [dbo].[SP_GetUnitSalePriceHistoryById]
@StocklineId bigint,
@EmployeeId bigint


AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
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


		SELECT StockLineNumber,UnitSalesPrice,SalesPriceExpiryDate,
		--CreatedDate,
		--UpdatedDate,
		case when CAST(CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc) as Date))end CreatedDate,
		case when CAST(UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) as Date))end UpdatedDate,
		UpdatedBy
		FROM [dbo].[UnitSalePriceHistoryAudit] WITH (NOLOCK)
		WHERE StocklineId = @StocklineId
		
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetUnitSalePriceHistoryById' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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