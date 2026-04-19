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
	2    17-APR-2026		Divyesh Kathiriya	Handle Boolean Issuse AND Other Change [PN-16047]
    
 -- EXEC [RPT_GetEmployeeTrainingListById] @EmployeeId= 374, @MasterCompanyId = 1
**************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetEmployeeTrainingListById]
@EmployeeId BIGINT,
@MasterCompanyId BIGINT 
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		SELECT
			E.[FirstName] + ' ' + E.[LastName] AS [EmployeeName],
			ETN.[Name] AS [TrainingName],
			ET.[Provider],
			ETP.[TrainingType],				
			CASE 
				WHEN ET.[IsRecurring] IS NULL THEN ''
				WHEN ET.[IsRecurring] = 1 THEN 'Yes'
				ELSE 'No'
			END AS [Recurring],			
			CASE 
				WHEN ET.[DurationHours] IS NULL OR ET.[DurationMinutes] IS NULL THEN NULL
				ELSE CONCAT(FORMAT(ET.[DurationHours], '00'), ':', FORMAT(ET.[DurationMinutes], '00'))
			END AS [Duration],
			ET.[ScheduleDate],			
			ET.[CompletionDate],			
			ET.[ExpirationDate]			
		FROM [DBO].[EmployeeTraining] ET WITH(NOLOCK)
		LEFT JOIN [DBO].[TrainingName] ETN WITH(NOLOCK) ON ET.[TrainingNameId] = ETN.[TrainingNameId]
		LEFT JOIN [DBO].[EmployeeTrainingType] ETP WITH(NOLOCK) ON ET.[EmployeeTrainingTypeId] = ETP.[EmployeeTrainingTypeId]		
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