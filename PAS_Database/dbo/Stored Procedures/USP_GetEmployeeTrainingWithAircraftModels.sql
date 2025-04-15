/***************************************************************************************          
 ** File:   [USP_GetEmployeeTrainingWithAircraftModels]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get Employee Training records by ID
 ** Purpose:           
 ** Date:  04-15-2025  
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-15-2025    Bhargav Saliya		Created  

	--EXEC [USP_GetEmployeeTrainingWithAircraftModels] @EmployeeId= 232, @EmployeeTrainingId = 39
********************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEmployeeTrainingWithAircraftModels]
    @EmployeeId INT,
    @EmployeeTrainingId INT
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY  
		SELECT 
			ET.AircraftManufacturerId
			,AFT.[Description] as AircraftManufacturerName
			,ET.AircraftModelId
			,(	SELECT STRING_AGG(A.AircraftModelId, ', ') as AircraftModel
				FROM EmployeeTraining e WITH (NOLOCK)
					LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON e.EmployeeId = EAMP.EmployeeId and e.AircraftManufacturerId = EAMP.AircraftManufacturerId
					LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
				WHERE ET.EmployeeTrainingId = e.EmployeeTrainingId
			) AS AircraftModelIds

			,(	SELECT STRING_AGG(A.ModelName, ', ') as AircraftModel
				FROM EmployeeTraining e WITH (NOLOCK)
					LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON e.EmployeeId = EAMP.EmployeeId and e.AircraftManufacturerId = EAMP.AircraftManufacturerId
					LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
				WHERE ET.EmployeeTrainingId = e.EmployeeTrainingId
			) AS AircraftModelName
			,ET.CompletionDate
			,ET.Cost as EstimatedCost
			,ET.CreatedBy
			,ET.CreatedDate
			,ET.Duration
			,ET.DurationTypeId
			,ET.EmployeeId
			,ET.EmployeeTrainingId
			,ET.EmployeeTrainingTypeId
			,ETP.[TrainingType] as EmployeeTrainingTypeName
			,ET.ExpirationDate
			,ET.FrequencyOfTrainingId
			,FT.[FrequencyName] as FrequencyOfTrainingName
			,ET.IndustryCode
			,ET.InternalReference
			,ET.IsActive
			,ET.IsDeleted
			,ET.MasterCompanyId
			,ET.Memo
			,ET.Provider
			,ET.ScheduleDate
			,ET.UpdatedBy
			,ET.UpdatedDate
		FROM EmployeeTraining ET WITH (NOLOCK)
			LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ET.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
			LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ET.AircraftManufacturerId = AFT.AircraftTypeId
			LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ET.FrequencyOfTrainingId = FT.FrequencyOfTrainingId
		WHERE et.EmployeeId = @EmployeeId
		  AND et.EmployeeTrainingId = @EmployeeTrainingId;
	END TRY 
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetEmployeeTrainingWithAircraftModels',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@EmployeeTrainingId, '') AS varchar(100)),  
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