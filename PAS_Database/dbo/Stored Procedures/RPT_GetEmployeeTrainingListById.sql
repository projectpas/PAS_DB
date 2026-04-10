/*************************************************************           
 ** File:		 [RPT_GetEmployeeTrainingListById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Employee Training List By Id.
 ** Purpose:         
 ** Date:   07-APRIL-2026 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    07-APR-2026		Divyesh Kathiriya	Created [PN-15934]
    
 -- EXEC [RPT_GetEmployeeTrainingListById] @EmployeeId= 374, @MasterCompanyId = 1
**************************************************************/
CREATE   PROCEDURE [DBO].[RPT_GetEmployeeTrainingListById]
@EmployeeId BIGINT,
@MasterCompanyId BIGINT 
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	

		SELECT
			FirstName + ' ' + LastName AS [EmployeeName],		
			AFT.[Description] AS [TrainingName],
			ET.[Provider],
			ETP.[TrainingType],
			FT.[FrequencyName] AS [Recurring],
			ET.[Duration],
			ET.[ScheduleDate],
			ET.[CompletionDate],
			ET.[ExpirationDate]			
		FROM [DBO].[EmployeeTraining] ET WITH(NOLOCK)
		LEFT JOIN [DBO].[EmployeeTrainingType] ETP WITH(NOLOCK) ON ET.[EmployeeTrainingTypeId] = ETP.[EmployeeTrainingTypeId]
		LEFT JOIN [DBO].[AircraftType] AFT WITH(NOLOCK) ON ET.[AircraftManufacturerId] = AFT.[AircraftTypeId]
		LEFT JOIN [DBO].[FrequencyOfTraining] FT WITH(NOLOCK) ON ET.[FrequencyOfTrainingId] = FT.[FrequencyOfTrainingId]
		LEFT JOIN [DBO].[Employee] E WITH(NOLOCK) ON E.[EmployeeId] = @EmployeeId		
		WHERE 
			ET.[EmployeeId] = @EmployeeId
			AND ET.[MasterCompanyId] = @MasterCompanyId
			AND ET.[IsDeleted] = 0
		ORDER BY 
			ET.[EmployeeTrainingId] DESC;
			
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetEmployeeTrainingListById'
			  , @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) +    
              '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END