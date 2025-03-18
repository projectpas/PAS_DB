/*************************************************************               
 ** File:   [CheckAlternatePartExists]               
 ** Author:  Abhishek Jirawla
 ** Description:  This Store Procedure use to get recent activity logs of a user/employee.   
 ** Purpose:             
 ** Date:   17/03/2025
              
 ** RETURN VALUE:               
 **********************************************************              
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    17/03/2025  	Abhishek Jirawla	Created     
 
 EXEC [CheckAlternatePartExists] 
********************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_GetEmployeeActivityHistoryData]
@EmployeeId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
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
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

			SELECT TOP 100
				EMP.UserActivityLogId,
                EMP.Request,
                EMP.Payload,
                EMP.EmployeeId,
                EMP.EmployeeName,
                EMP.URL,
                EMP.IpAddress,
                EMP.MasterCompanyId,
                EMP.IsActive,
                EMP.IsDeleted,
				case when CAST(EMP.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(EMP.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
                EMP.CreatedBy,
                EMP.UpdatedBy,
				case when CAST(EMP.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(EMP.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
			FROM dbo.UserActivityLog EMP WITH(NOLOCK)
			WHERE EMP.EmployeeId = @EmployeeId 
			ORDER BY EMP.UserActivityLogId DESC;
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetEmployeeActivityHistoryData' 
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@EmployeeId AS varchar(20)) ,'') +''
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