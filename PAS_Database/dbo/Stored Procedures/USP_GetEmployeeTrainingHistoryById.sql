/***************************************************************************************          
 ** File:   [USP_GetEmployeeTrainingHistoryById]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get Employee Training history List
 ** Purpose:           
 ** Date:   04-11-2025   
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-11-2025    Bhargav Saliya		Created 
	2    14-APR-2026   Sahdev Saliya        Added TrainingName, ProviderId, ProviderType, IsRecurring, DurationHours, DurationMinutes (PN-15932)
	3    03-May-2026   Sahdev Saliya        Added CategoryId, CategoryType, CurrencyId, CurrencyCode (PN-16203)

	exec [USP_GetEmployeeTrainingHistoryById]  @EmployeeTrainingId = 20 , @EmployeeId = 2
********************************************************************************/   
CREATE   PROCEDURE [dbo].[USP_GetEmployeeTrainingHistoryById]    
@EmployeeTrainingId bigint,
@EmployeeId bigint
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY      
 
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

   BEGIN   
		SELECT ETA.[EmployeeTrainingId]
			,ETA.EmployeeId
			,ETP.[TrainingType] as TrainingType
			,AFT.[Description] as AircraftManufacturer
			,STRING_AGG(A.ModelName, ', ') as AircraftModel
			,ETA.[Provider]
			,ETA.[IndustryCode]
			,FT.[FrequencyName] as FrequencyofTraining
			,ETA.[Cost] as EstimatedCost
			,CAST(ETA.DurationHours AS VARCHAR(max)) + ' : ' + RIGHT('00' + CAST(ETA.DurationMinutes AS VARCHAR(2)), 2) AS Duration
			,ETA.[ScheduleDate]
			,ETA.[CompletionDate]
			,ETA.[ExpirationDate]
			,ETA.InternalReference
			,ETA.Memo
			,ETA.[CreatedBy] 
			,ETA.[UpdatedBy]  
			,CASE WHEN CAST(ETA.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(ETA.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate]
			,ETA.MasterCompanyId
			,ETA.[IsActive]  
			,ETA.[IsDeleted] 
			,TN.[Name] as TrainingName
			,ETA.ProviderId
			,ETA.ProviderType
			,ETA.IsRecurring
			,ETA.CategoryId
			,ETA.CategoryType
			,ETA.CurrencyId
			,CR.[Code] as CurrencyCode
		FROM [dbo].[EmployeeTrainingAudit] ETA WITH(NOLOCK)  
		LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ETA.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
		LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ETA.AircraftManufacturerId = AFT.AircraftTypeId
		LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON ETA.EmployeeId = EAMP.EmployeeId
		LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
		LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ETA.FrequencyOfTrainingId = FT.FrequencyOfTrainingId
	    LEFT JOIN dbo.TrainingName TN WITH (NOLOCK) ON ETA.TrainingNameId = TN.TrainingNameId
		LEFT JOIN dbo.Currency CR WITH (NOLOCK) ON ETA.CurrencyId = CR.CurrencyId
		WHERE ETA.[EmployeeTrainingId] = @EmployeeTrainingId 
		GROUP BY ETA.EmployeeTrainingId,ETA.EmployeeId,ETP.[TrainingType],AFT.[Description],ETA.[Provider],ETA.[IndustryCode],FT.[FrequencyName],ETA.[Cost],
			ETA.[DurationHours],ETA.[DurationMinutes],ETA.[ScheduleDate],ETA.[CompletionDate],ETA.[ExpirationDate],ETA.InternalReference,ETA.Memo,ETA.[IsActive],ETA.[IsDeleted],ETA.[CreatedBy],ETA.[UpdatedBy],ETA.[UpdatedDate],ETA.[MasterCompanyId],TN.[Name],ETA.[ProviderId],ETA.[ProviderType],ETA.[IsRecurring],ETA.[CategoryId],ETA.[CategoryType],ETA.[CurrencyId],CR.[Code]
	order by ETA.[EmployeeTrainingId] desc	
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeTrainingHistoryById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeTrainingId, '') + ''    
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