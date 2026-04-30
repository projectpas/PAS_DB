/*************************************************************           
 ** File:		 [USP_GetImportModuleList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Import Module List.
 ** Purpose:         
 ** Date:   28-April-2026 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    28-APR-2026		Divyesh Kathiriya	Created [PN-16139]
    
 -- EXEC [USP_GetImportModuleList]
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetImportModuleList]
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY		
		
		SELECT
			[ImportModuleId],
			[ModuleName],
			[ReferenceTable],
			[ReferenceColumnName],
			ISNULL([ModuleParentTable], '') AS ModuleParentTable,
			ISNULL([ParentPrimaryColumnName], '') AS ParentPrimaryColumnName,
			ISNULL([ChildTable], '') AS ChildTable,
			ISNULL([CodeTypeId], 0) AS CodeTypeId,
			ISNULL([Description], '') AS Description,
			[MasterCompanyId],
			[CreatedBy],
			[CreatedDate],
			[UpdatedBy],
			[UpdatedDate],
			[IsActive],
			[IsDeleted],
			[DisplayModuleName]
		FROM [dbo].[ImportModule] WITH(NOLOCK)	  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetImportModuleList'			  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments			
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END