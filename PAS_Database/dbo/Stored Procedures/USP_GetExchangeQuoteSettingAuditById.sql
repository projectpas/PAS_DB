/*************************************************************           
 ** File:   [USP_GetExchangeQuoteSettingAuditById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteSettingAuditById
 ** Purpose:         
 ** Date:   07/04/2025      
          
 ** PARAMETERS:  @ExchangeQuoteSettingsId BIGINT,   @EmployeeId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/04/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeQuoteSettingAuditById @ExchangeQuoteSettingsId = 1, @EmployeeId = 237

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteSettingAuditById]
    @ExchangeQuoteSettingsId BIGINT,
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

		-- Fetch audit data
		SELECT 
			eqsa.AuditExchangeQuoteSettingId,
			eqsa.ExchangeQuoteSettingId,
			eqsa.Typeid,
			et.Name AS TypeName,
			eqsa.Prefix,
			eqsa.Sufix,
			eqsa.StartCode,
			eqsa.CurrentNumber,
			eqsa.DefaultStatusId,
			es.Name AS DefaultStatusName,
			es.Name AS SODefaultStatusName,
			eqsa.DefaultPriorityId,
			p.Description AS DefaultPriorityName,
			ISNULL(eqsa.IsActive,0) AS IsActive,
			ISNULL(eqsa.IsDeleted,0) AS IsDeleted,
			eqsa.CreatedBy,
			eqsa.UpdatedBy,
			-- Adjusting datetime for employee's timezone
			(Cast(DBO.ConvertUTCtoLocal(eqsa.CreatedDate,@CurrntEmpTimeZoneDesc)as datetime)) AS CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(eqsa.UpdatedDate,@CurrntEmpTimeZoneDesc)as datetime)) AS UpdatedDate
		FROM [dbo].[ExchangeQuoteSettingAudit] eqsa WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeType] et WITH(NOLOCK) ON eqsa.Typeid = et.Id
		INNER JOIN [dbo].[ExchangeStatus] es WITH(NOLOCK) ON eqsa.DefaultStatusId = es.ExchangeStatusId
		INNER JOIN [dbo].[Priority] p WITH(NOLOCK) ON eqsa.DefaultPriorityId = p.PriorityId
		WHERE ISNULL(eqsa.IsDeleted,0) = 0 
			AND ISNULL(eqsa.IsActive,0) = 1
			AND eqsa.ExchangeQuoteSettingId = @ExchangeQuoteSettingsId
		ORDER BY eqsa.AuditExchangeQuoteSettingId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteSettingAuditById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteSettingsId = ''' + CAST(ISNULL(@ExchangeQuoteSettingsId, '') AS VARCHAR(100)) + ''','+
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
END;