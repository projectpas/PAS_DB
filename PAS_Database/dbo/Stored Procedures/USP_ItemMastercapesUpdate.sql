/*************************************************************           
 ** File:        [dbo].[USP_ItemMastercapesUpdate]          
 ** Author:      Nakul Chandigra
 ** Description: This stored procedure is used to Update itemmastercapes
 ** Purpose:       
 ** Date:        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author             Change Description            
 ** --   ----------  -----------------  ----------------------------     
 **  1   26-09-2025   Nakul Chandigra    Created
 ************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ItemMastercapesUpdate] 
@ItemMasterCapesUpdateType ItemMasterCapesUpdateType READONLY,	
@ISExist  VARCHAR(500) OUTPUT
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
BEGIN TRY
BEGIN TRANSACTION;

	DECLARE @ItemMasterId BIGINT;
	DECLARE @CapabilityTypeId BIGINT;
	DECLARE @ManagementStructureId BIGINT;
	DECLARE @MasterCompanyId BIGINT;
	DECLARE @ItemMasterCapesId BIGINT;
	DECLARE @capesData BIGINT;
	DECLARE @ItemMasterCapes BIGINT; 
	DECLARE @UpdatedBy VARCHAR(299);
	
	SELECT @ItemMasterId           = ItemMasterId, 
		   @CapabilityTypeId       = CapabilityTypeId,
		   @ManagementStructureId  = ManagementStructureId,
		   @MasterCompanyId        = MasterCompanyId,
		   @ItemMasterCapesId      = ItemMasterCapesId
	FROM @ItemMasterCapesUpdateType

	IF EXISTS( SELECT 1
				FROM [dbo].ItemMasterCapes WITH (NOLOCK)
				WHERE ItemMasterId = @ItemMasterId
				  AND CapabilityTypeId = @CapabilityTypeId
				  AND ManagementStructureId = @ManagementStructureId
				  AND MasterCompanyId = @MasterCompanyId
				  AND ItemMasterCapesId != @ItemMasterCapesId
	         )
	BEGIN
		SET @ISExist = 'Duplicate Records, Part Number, CapabilityType, Managment Structure, Master Company Atleast one Should Unique';
	END

	ELSE
	BEGIN
	IF EXISTS(SELECT 1 FROM ItemMasterCapes WITH (NOLOCK) WHERE ItemMasterCapesId = @ItemMasterCapesId AND ItemMasterId = @ItemMasterId AND MasterCompanyId = @MasterCompanyId)
	BEGIN
	UPDATE T
		SET	T.ItemMasterId			=	IT.ItemMasterId,
			T.CapabilityTypeId		=	IT.CapabilityTypeId,
			T.ManagementStructureId =	IT.ManagementStructureId,
			T.IsVerified            =	IT.IsVerified,
			T.VerifiedById          =	IT.VerifiedById,
			T.VerifiedDate			=	IT.VerifiedDate,
			T.AddedDate				=	IT.AddedDate,
			T.Memo					=	IT.Memo,
			T.UpdatedBy				=	IT.UpdatedBy,
			T.UpdatedDate			=	IT.UpdatedDate
	FROM [dbo].ItemMasterCapes T
	INNER JOIN @ItemMasterCapesUpdateType IT
	ON T.ItemMasterCapesId =  IT.ItemMasterCapesId

	SELECT @ItemMasterCapes = ManagementStructureModuleId
	FROM [dbo].ManagementStructureModule
	WHERE ModuleName = 'ItemMasterCapes';

	SELECT @UpdatedBy = UpdatedBy		
	FROM [dbo].ItemMasterCapes
	WHERE @ItemMasterCapesId = @ItemMasterCapesId 

	EXEC USP_UpdateItemMasterMSDetails   @ItemMasterCapes , @ItemMasterCapesId , @ManagementStructureId  , @UpdatedBy	;
	EXEC dbo.UpdateItemMasterCapsDetail  @ItemMasterId ;
	
	END
	ELSE
	BEGIN 
		SET @ISExist = 'Record does not exist with these details!';
	END

	PRINT @ISExist
END		

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@trancount > 0
PRINT 'ROLLBACK'
ROLLBACK TRAN;
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = '[dbo].[USP_ItemMastercapesUpdate] ' 
				, @ProcedureParameters VARCHAR(3000)  = ''
				, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			exec spLogException 
					 @DatabaseName         = @DatabaseName
					, @AdhocComments        = @AdhocComments
					, @ProcedureParameters  = @ProcedureParameters
					, @ApplicationName      =  @ApplicationName
					, @ErrorLogID           = @ErrorLogID OUTPUT ; 
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
END CATCH
END