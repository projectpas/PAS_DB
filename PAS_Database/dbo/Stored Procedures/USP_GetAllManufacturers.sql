/*************************************************************           
 ** File:		 [USP_GetAllManufacturers]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get AllManufacturers By MasterCompany.
 ** Purpose:         
 ** Date:   25-August-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    25-August-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetAllManufacturers] @MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetAllManufacturers]
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	
		SELECT
			m.[ManufacturerId],
			m.[Name],
			ISNULL(m.[Comments], '') AS Comments,
			ISNULL(m.[IsActive], 0) AS IsActive,
			ISNULL(m.[IsDeleted], 0) AS IsDeleted,
			m.[MasterCompanyId]
		FROM [DBO].[Manufacturer] AS m WITH (NOLOCK)
		WHERE m.[IsDeleted] = 0 AND m.[MasterCompanyId] = @MasterCompanyId
		ORDER BY m.[ManufacturerId] DESC;
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAllManufacturers'
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