/*************************************************************           
 ** File:		[dbo].[USP_DeleteKitPart]          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Delete Kit Part
 ** Purpose:         
 ** Date:   01-12-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	01-12-2025           Nakul Chandigra     Created 
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_DeleteKitPart]
@kitItemMasterMappingId BIGINT,
@updatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @DeleteKitCode NVARCHAR(100) = 'DeleteItemKit';
		DECLARE @DeleteKitMsg NVARCHAR(100) = 'Part Deleted';
		DECLARE @StatusCode NVARCHAR(100) = 'DeleteKit';
		DECLARE @PartNumber NVARCHAR(100);
		DECLARE @MasterCompanyId BIGINT;
		DECLARE @ItemMasterId BIGINT;
		DECLARE @TemplateBody NVARCHAR(MAX);
		DECLARE @ReplaceContent NVARCHAR(MAX);
		DECLARE @ModuleId BIGINT;
		DECLARE @SubModuleId BIGINT;
		DECLARE @CurrentDate DATETIME2 = GETUTCDATE()

		UPDATE dbo.KitItemMasterMapping
		SET 
			IsDeleted = 1,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = @UpdatedBy
		WHERE KitItemMasterMappingId = @KitItemMasterMappingId;

		SELECT 
			@PartNumber = PartNumber,
			@MasterCompanyId = MasterCompanyId,
			@ItemMasterId = ItemMasterId
		FROM dbo.KitItemMasterMapping WITH(NOLOCK)
		WHERE KitItemMasterMappingId = @KitItemMasterMappingId;

		SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @DeleteKitCode;

		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'KitMaster';
		SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'ItemMaster';

		SET @ReplaceContent = REPLACE(@TemplateBody, '##Part##', @PartNumber);

		--Add History details
		EXEC [dbo].[USP_History] @ModuleId,@KitItemMasterMappingId,@SubModuleId,@ItemMasterId,'',@DeleteKitMsg,@ReplaceContent,@StatusCode,@MasterCompanyId,@UpdatedBy,@CurrentDate,@UpdatedBy,@CurrentDate

    END TRY
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_DeleteKitPart]'
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
	END CATCH
END