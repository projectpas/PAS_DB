
/***************************************************************************************          
 ** File:   [USP_GetEmployeeTrainingHistoryById]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get Employee Training List
 ** Purpose:           
 ** Date:  04-09-2025  
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-09-2025    Bhargav Saliya		Created  

	--EXEC [usp_GetEmployeeTrainingList] @EmployeeId= 243, @MasterCompanyId = 1 , @IsdeleteStatus = 0
********************************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_GetEmployeeTrainingList]  
@EmployeeId BIGINT,
@MasterCompanyId BIGINT,  
@IsdeleteStatus BIT = 0  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY   
   
   ;WITH rptCTE (TotalRecordsCount, EmployeeTrainingId,EmployeeId,TrainingType, AircraftManufacturer, AircraftModel, Provider, IndustryCode, FrequencyofTraining, EstimatedCost,
				 Duration, ScheduleDate, CompletionDate,ExpirationDate,InternalReference,MEMO,IsActive,IsDeleted,
				 MasterCompanyId) 
				 AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount
			 ,ET.EmployeeTrainingId
			 ,ET.EmployeeId
			 ,ETP.[TrainingType] as TrainingType
			 ,AFT.[Description] as AircraftManufacturer
			 ,STRING_AGG(A.ModelName, ', ') as AircraftModel
			 --,(SELECT STRING_AGG(am.ModelName, ',') FROM EmployeeTraining e
				--INNER JOIN EmployeeAircraftModelMapping eam ON e.EmployeeId = eam.EmployeeId
				--INNER JOIN AircraftModel am ON eam.AircraftModelId = am.AircraftModelId
			 -- WHERE e.EmployeeId = @EmployeeId
			 -- ) AS AircraftModel
			 ,ET.[Provider]
			 ,ET.[IndustryCode]
			 ,FT.[FrequencyName] as FrequencyofTraining
			 ,ET.[Cost] as EstimatedCost
			 ,ET.[Duration]
			 ,ET.[ScheduleDate]
			 ,ET.[CompletionDate]
			 ,ET.[ExpirationDate]
			 ,ET.InternalReference
			 ,ET.Memo
			 ,ET.[IsActive]
			 ,ET.[IsDeleted]
			 ,ET.[MasterCompanyId]
      FROM DBO.EmployeeTraining ET WITH (NOLOCK)
		--LEFT JOIN dbo.EmployeeTraining ET WITH (NOLOCK) ON E.EmployeeId = ET.EmployeeId
		LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ET.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
		LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ET.AircraftManufacturerId = AFT.AircraftTypeId
		LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON ET.EmployeeId = EAMP.EmployeeId
		LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
		LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ET.FrequencyOfTrainingId = FT.FrequencyOfTrainingId

      WHERE ET.EmployeeId = @EmployeeId AND ET.MasterCompanyId = @MasterCompanyId AND ET.IsDeleted = @IsdeleteStatus 
			
			GROUP BY ET.EmployeeTrainingId,ET.EmployeeId,ETP.[TrainingType],AFT.[Description],ET.[Provider],ET.[IndustryCode],FT.[FrequencyName],ET.[Cost],
			ET.[Duration],ET.[ScheduleDate],ET.[CompletionDate],ET.[ExpirationDate],ET.InternalReference,ET.Memo,ET.[IsActive],ET.[IsDeleted],ET.[MasterCompanyId]
			)
			,FinalCTE(TotalRecordsCount, EmployeeTrainingId,EmployeeId,TrainingType, AircraftManufacturer, AircraftModel, Provider, IndustryCode, FrequencyofTraining, EstimatedCost,
				 Duration, ScheduleDate, CompletionDate,ExpirationDate,InternalReference,MEMO,IsActive,IsDeleted,MasterCompanyId) 

			  AS (SELECT DISTINCT TotalRecordsCount, EmployeeTrainingId,EmployeeId,TrainingType, AircraftManufacturer, AircraftModel, Provider, IndustryCode, FrequencyofTraining, EstimatedCost,
				 Duration, ScheduleDate, CompletionDate,ExpirationDate,InternalReference,MEMO,IsActive,IsDeleted,MasterCompanyId FROM rptCTE)
			
		    SELECT COUNT(2) OVER () AS TotalRecordsCount, EmployeeTrainingId,EmployeeId,TrainingType, AircraftManufacturer, AircraftModel, Provider, IndustryCode, FrequencyofTraining, EstimatedCost,
				 Duration, ScheduleDate, CompletionDate,ExpirationDate,InternalReference,MEMO,IsActive,IsDeleted,
				 MasterCompanyId
		    FROM FinalCTE FC

			ORDER BY EmployeeId DESC
  END TRY  
  
  BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'usp_GetEmployeeTrainingList',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) +    
            '@Parameter3 = ''' + CAST(ISNULL(@IsdeleteStatus, '') AS varchar(max)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END