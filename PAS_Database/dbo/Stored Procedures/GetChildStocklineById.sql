
/***************************************************************  
 ** File:   [GetChildStocklineById]             
 ** Author:   Ayushi Patel
 ** Description: This stored procedure is used to Get ChildStockline Data
 ** Date:  14-Aug-2025
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1	 14-Aug-2025		Ayushi Patel			Created
**************************************************************/
CREATE   PROCEDURE GetChildStocklineById
    @StocklineId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
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
        sl.StockLineId,
        sl.StockLineNumber,
        sl.ControlNumber,
        sl.IdNumber,
        sl.ItemMasterId,
        im.PartNumber,
        im.PartDescription,
        sl.QuantityAvailable,
        sl.QuantityOnHand,
        sl.QuantityIssued,
        sl.QuantityReserved,
        sl.ModuleName,
        sl.ReferenceName,
        sl.SubModuleName,
        sl.SubReferenceName,
        sl.CreatedBy,
		--sl.CreatedDate,
		(Cast(DBO.ConvertUTCtoLocal(sl.CreatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) CreatedDate,
		--sl.UpdatedDate,
		(Cast(DBO.ConvertUTCtoLocal(sl.UpdatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) UpdatedDate,
        sl.UpdatedBy
    FROM 
        dbo.ChildStockLine sl WITH(NOLOCK)
    INNER JOIN 
        dbo.ItemMaster im WITH(NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
    WHERE 
        sl.ParentId = @StocklineId;
	COMMIT TRANSACTION
	 
	END TRY    
	BEGIN CATCH    
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'GetChildStocklineById',    
			@ProcedureParameters varchar(3000) = '',    
			@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
			EXEC spLogException @DatabaseName = @DatabaseName,    
				@AdhocComments = @AdhocComments,    
				@ProcedureParameters = @ProcedureParameters,    
				@ApplicationName = @ApplicationName,    
				@ErrorLogID = @ErrorLogID OUTPUT;    
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH 
END