/*************************************************************             
** File:   [USP_CheckDuplicateStockInventoryParam]             
** Author:   Devendra Shekh
** Description: This stored procedure is USED TO Check Duplicate Stock Inventory Search Params
** Date:   
         
**************************************************************             
** Change History             
**************************************************************             
** PR   Date				Author					Change Description  
** --   --------			-------					--------------------------------
** 1	3rd-DEC-2024		Devendra Shekh			Created
** 2    21-02-2024          Shrey Chandegara        Modifiy due to add column [DisplaySortOrder]

exec USP_GetImportModuleFields_ById 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetImportModuleFields_ById]    
(    
@ModuleId BIGINT
)    
AS    
BEGIN    

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON    

	BEGIN TRY
		BEGIN  
			SELECT	 [ImportModuleFieldMasterId]
					,[ModuleId]
					,[FieldName]
					,[HeaderName]
					,[FieldWidth]
					,[FieldType]
					,[FieldAlign]
					,[FieldSortOrder]
					,ISNULL([FieldExcelWidth], 30) AS FieldExcelWidth
					,[DropdownListType]
					,[DropdownListTable]
					,[DropdownListId]
					,[DropdownListValue]
					,[DropdownListValueId]
					,ISNULL([IsAutoGenerate], 0) AS IsAutoGenerate
					,ISNULL([IsModuleTableColumn], 0) AS IsModuleTableColumn
					,ISNULL([IsMultiValue], 0) AS IsMultiValue
					,ISNULL([IsToolTipShow], 0) AS [IsToolTipShow]
					,ISNULL([IsRequired], 0) AS IsRequired
					,ISNULL([IsEditable], 0) AS IsEditable
					,ISNULL([ParentTableRereneceTypeId], 0) AS ParentTableRereneceTypeId 
					,ISNULL([ChildTableRereneceTypeId], 0) AS ChildTableRereneceTypeId 
					,[MasterCompanyId]
					,[CreatedBy]
					,[CreatedDate]
					,[UpdatedBy]
					,[UpdatedDate]
					,[IsActive]
					,[IsDeleted]	
					,ISNULL([DisplaySortOrder],0) AS DisplaySortOrder
			FROM [dbo].[ImportModuleFieldMaster]
			WHERE [ModuleId] = @ModuleId
		END
	END TRY  
	
BEGIN CATCH      
	IF @@trancount > 0
	PRINT 'ROLLBACK'
	ROLLBACK TRAN;
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	, @AdhocComments     VARCHAR(150)    = 'USP_GetLoginUserMSDetails' 
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ModuleId, '') + ''
	, @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

	exec spLogException 
	@DatabaseName			= @DatabaseName
	, @AdhocComments			= @AdhocComments
	, @ProcedureParameters		= @ProcedureParameters
	, @ApplicationName			= @ApplicationName
	, @ErrorLogID              = @ErrorLogID OUTPUT ;
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
	RETURN(1);
END CATCH
END