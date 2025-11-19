/*************************************************************           
 ** File:		 [USP_EmployeeUploadList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get List of Employee Upload from Excel File.
 ** Purpose:         
 ** Date:   03-Nov-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    03-Nov-2025		Divyesh Kathiriya	Created
	2    19-Nov-2025		Devendra Shekh		Added MasterCompanyId for AspNetUsers
    
 -- EXEC [USP_EmployeeUploadList] @MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_EmployeeUploadList]
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY		
		
		SELECT 
			[EM].[EmployeeId], 
			[EM].[UserName],
			[EM].[FirstName],
			[EM].[LastName],
			[EM].[Email],
			[EM].[ManagementStructureId],
			[EM].[MasterCompanyId]
		FROM [DBO].[Employee] EM WITH(NOLOCK)
		LEFT JOIN [DBO].[AspNetUsers] ASP WITH(NOLOCK) ON [EM].[EmployeeId] = [ASP].[EmployeeId] AND [EM].[MasterCompanyId] = [ASP].[MasterCompanyId]
		WHERE [ASP].[EmployeeId] IS NULL AND [EM].[IsUploadEmployee]  = 1 AND [EM].[MasterCompanyId] = @MasterCompanyId;
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_EmployeeUploadList'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
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