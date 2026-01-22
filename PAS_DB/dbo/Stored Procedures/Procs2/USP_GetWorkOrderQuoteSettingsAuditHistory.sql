/*************************************************************           
** File:   [USP_GetWorkOrderQuoteSettingsAuditHistory]        
** Author:  Ayushi Patel
** Description: Retrieves the audit history of WorkOrderQuoteSettings, with timezone-adjusted UpdatedDate.
** Purpose: To track changes and show timestamps in employee's local timezone
** Date:   24/04/2025     
        
** PARAMETERS: 
    @WorkOrderQuoteSettingId BIGINT,
    @EmployeeId BIGINT
        
** RETURN VALUE: List of WorkOrderQuoteSettings audit history details       
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    24/04/2025  Ayushi Patel     Created
   2    09/05/2025	Devendra Shekh	 Added IsPrintCorrectiveAction to select
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderQuoteSettingsAuditHistory]
    @WorkOrderQuoteSettingId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

        SELECT 
            wos.WorkOrderQuoteSettingId,
            wos.WorkOrderTypeId,
            wos.Prefix,
            wos.Sufix,
            wos.StartCode,
            wot.Description AS WorkOrderType,
            wos.ValidDays,
            wos.MasterCompanyId,
            wos.IsActive,
            wos.CreatedBy,
            wos.CreatedDate,
            wos.UpdatedBy,
			      case when CAST(wos.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(wos.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate,
			      wos.EffectiveDate,
            ISNULL(wos.IsApprovalRule, 0) AS IsApprovalRule,  
            ISNULL(wos.IsFlatRate, 0) AS IsFlatRate,
			 ISNULL(wos.IsPrintCorrectiveAction, 0) AS IsPrintCorrectiveAction
        FROM dbo.WorkOrderQuoteSettingsAudit wos WITH (NOLOCK)
        INNER JOIN dbo.WorkOrderType wot WITH (NOLOCK) ON wos.WorkOrderTypeId = wot.Id
        WHERE wos.WorkOrderQuoteSettingId = @WorkOrderQuoteSettingId
        ORDER BY wos.UpdatedDate DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetWorkOrderQuoteSettingsAuditHistory',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected error occurred. Contact support with error number: %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END