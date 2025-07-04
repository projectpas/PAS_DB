/*************************************************************           
 ** File:   [USP_GetExchangeSalesOrderSettingsAuditById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderSettingsAuditById
 ** Purpose:         
 ** Date:   07/04/2025      
          
 ** PARAMETERS:  @ExchangeSalesOrderSettingsAuditId INT,   @EmployeeId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/04/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeSalesOrderSettingsAuditById @ExchangeSalesOrderSettingsAuditId = 1, @EmployeeId = 237

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderSettingsAuditById]
    @ExchangeSalesOrderSettingsAuditId BIGINT,
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

		-- Select audit records
		SELECT 
			esa.AuditExchangeSalesOrderSettingId,
			esa.ExchangeSalesOrderSettingId,
			esa.TypeId,
			et.Name AS TypeName,
			esa.Prefix,
			esa.Sufix,
			esa.StartCode,
			esa.CurrentNumber,
			esa.DefaultStatusId,
			es.Name AS DefaultStatusName,
			es.Name AS SODefaultStatusName,
			esa.DefaultPriorityId,
			p.Description AS DefaultPriorityName,
			ISNULL(esa.IsActive,0) AS IsActive,
			ISNULL(esa.IsDeleted,0) AS IsDeleted,
			esa.CreatedBy,
			esa.UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(esa.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) AS CreatedDate,
			(Cast(DBO.ConvertUTCtoLocal(esa.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) AS UpdatedDate,
			esa.EffectiveDate
		FROM [dbo].[ExchangeSalesOrderSettingsAudit] esa WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeType] et WITH(NOLOCK) ON esa.TypeId = et.Id
		INNER JOIN [dbo].[ExchangeStatus] es WITH(NOLOCK) ON esa.DefaultStatusId = es.ExchangeStatusId
		INNER JOIN [dbo].[Priority] p WITH(NOLOCK) ON esa.DefaultPriorityId = p.PriorityId
		WHERE ISNULL(esa.IsDeleted,0) = 0 AND ISNULL(esa.IsActive,0) = 1
		ORDER BY esa.AuditExchangeSalesOrderSettingId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderSettingsAuditById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderSettingsAuditId = ''' + CAST(ISNULL(@ExchangeSalesOrderSettingsAuditId, '') AS VARCHAR(100)) + ''','+
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