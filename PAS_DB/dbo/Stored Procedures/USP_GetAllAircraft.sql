/*************************************************************           
 ** File:		 [USP_GetAllAircraft]           
 ** Author:		 Amit Ghediya
 ** Description: This Stored Procedure Is Used To Get USP_GetAllAircraft By MasterCompany.
 ** Purpose:         
 ** Date:   04-10-2026
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    04-10-2026			Amit Ghediya			Created
    
 -- EXEC [USP_GetAllAircraft] @MasterCompanyId=1
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetAllAircraft]
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	
		SELECT
			m.[AircraftTypeId],
			m.[Description] AS [Name],
			ISNULL(m.[memo], '') AS Comments,
			ISNULL(m.[IsActive], 0) AS IsActive,
			ISNULL(m.[IsDeleted], 0) AS IsDeleted,
			m.[MasterCompanyId]
		FROM [DBO].[aircrafttype] AS m WITH (NOLOCK)
		WHERE ISNULL(m.[IsDeleted], 0) = 0 AND m.[MasterCompanyId] = @MasterCompanyId
		ORDER BY m.[AircraftTypeId] DESC;
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAllAircraft'
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