/*************************************************************           
 ** File:		 [USP_GetSitesByManagementStructrue]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Sites By Management Structrue List.
 ** Purpose:         
 ** Date:   24-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    24-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetSitesByManagementStructrue] @ManagementStructureId=1, @MasterCompanyId=1
**************************************************************/
CREATE PROCEDURE [DBO].[USP_GetSitesByManagementStructrue]
@ManagementStructureId BIGINT = Null,
@MasterCompanyId INT = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	

		SELECT DISTINCT
			S.[SiteId] AS OriginSiteId,
			S.[Name] AS OriginName,
			A.[Line1] AS OriginAddress1,
			ISNULL(A.[Line2], '') AS OriginAddress2,
			A.[City] AS OriginCity,
			A.[StateOrProvince] AS OriginState,
			A.[PostalCode] AS OriginZip,
			A.[CountryId] AS OriginCountryId,
			C.[nice_name] AS OriginCountryName,
			ISNULL(S.[IsDefault], 0) AS IsDefault
		FROM [DBO].[ManagementSite] MS WITH(NOLOCK)
		INNER JOIN [DBO].[Site] S WITH(NOLOCK) ON MS.[SiteId] = S.[SiteId]
		INNER JOIN [DBO].[Address] A WITH(NOLOCK) ON S.[AddressId] = A.[AddressId]
		INNER JOIN [DBO].[Countries] C WITH(NOLOCK) ON A.[CountryId] = C.[countries_id]
		WHERE 
			S.[IsActive] = 1 AND 
			S.[IsDeleted] = 0 AND
			MS.[MasterCompanyId] = @MasterCompanyId AND
			MS.[ManagementStructureId] = @ManagementStructureId				
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSitesByManagementStructrue'
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