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
	2    14-APR-2026   Sahdev Saliya        Added TrainingName, ProviderId, ProviderType, IsRecurring, DurationHours, DurationMinutes (PN-15932)
	3    16-APR-2026   Sahdev Saliya        Added TrainingNameId
	4    04-May-2026   Sahdev Saliya        Added CategoryId, CategoryType, CurrencyId, CurrencyCode (PN-16203)
	5    06-May-2026   Bhargav Saliya       Rename Field CategoryId to IsCategoryType

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
				FROM dbo.EmployeeTraining e WITH (NOLOCK)
					LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON e.EmployeeId = EAMP.EmployeeId and e.AircraftManufacturerId = EAMP.AircraftManufacturerId
					LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
				WHERE ET.EmployeeTrainingId = e.EmployeeTrainingId
			) AS AircraftModelIds

			,(	SELECT STRING_AGG(A.ModelName, ', ') as AircraftModel
				FROM dbo.EmployeeTraining e WITH (NOLOCK)
					LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON e.EmployeeId = EAMP.EmployeeId and e.AircraftManufacturerId = EAMP.AircraftManufacturerId
					LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
				WHERE ET.EmployeeTrainingId = e.EmployeeTrainingId
			) AS AircraftModelName
			,ET.CompletionDate
			,ET.Cost as EstimatedCost
			,ET.CreatedBy
			,ET.CreatedDate
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
			,ET.TrainingNameId
			,TN.[Name] as TrainingName
			,ET.ProviderId
			,ET.ProviderType
			,ET.IsRecurring
			,ET.DurationHours
			,ET.DurationMinutes
			,ET.IsCategoryType
			,ET.CategoryType
			,ET.CurrencyId
			,CR.[Code] as CurrencyCode
		FROM dbo.EmployeeTraining ET WITH (NOLOCK)
			LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ET.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
			LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ET.AircraftManufacturerId = AFT.AircraftTypeId
			LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ET.FrequencyOfTrainingId = FT.FrequencyOfTrainingId
			LEFT JOIN dbo.TrainingName TN WITH (NOLOCK) ON ET.TrainingNameId = TN.TrainingNameId
			LEFT JOIN dbo.Currency CR WITH (NOLOCK) ON ET.CurrencyId = CR.CurrencyId
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