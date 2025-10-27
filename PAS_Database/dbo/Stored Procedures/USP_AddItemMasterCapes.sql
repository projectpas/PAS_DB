/*************************************************************           
 ** File:   [USP_AddItemMasterCapes]           
 ** Author:  Amit Ghediya
 ** Description: This stored Procedure is used to Create the ItemMasterCaps
 ** Date:   27-OCT-2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				 Author				 Change Description            
 ** --   --------			---------			--------------------------------          
    1   27-OCT-2025			Amit Ghediya		 Created
   
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_AddItemMasterCapes]
	@ItemMasterCapesList AS dbo.ItemMasterCapesType READONLY
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

			DECLARE @TotalCounts INT,
					@count INT,
					@ModuleId BIGINT = 0,
					@ItemMasterId BIGINT = 0,
					@ItemMasterCapesId BIGINT = 0, 
					@ManagementStructureId BIGINT = 0,
					@CapabilityTypeId BIGINT = 0,
					@MasterCompanyId BIGINT = 0,
					@UpdatedBy VARCHAR(256),
					@IsDuplicate INT = 0;

			SET @count = 1;

			SELECT @ModuleId = [ManagementStructureModuleId] FROM DBO.ManagementStructureModule WITH(NOLOCK) WHERE [ModuleName] = 'ItemMasterCapes';

		 -- Temporary table to hold exploded ManagementStructureIds
			DECLARE @Expanded TABLE
			(
				ItemMasterCapesId BIGINT NULL,
				ItemMasterId BIGINT NULL,
				CapabilityTypeId INT NULL,
				ManagementStructureId BIGINT NULL,
				IsVerified BIT NULL,
				VerifiedById BIGINT NULL,
				VerifiedDate DATETIME NULL,
				AddedDate DATETIME NULL,
				Memo NVARCHAR(MAX) NULL,
				PartNumber NVARCHAR(100) NULL,
				PartDescription NVARCHAR(500) NULL,
				CapabilityType NVARCHAR(200) NULL,
				VerifiedBy NVARCHAR(200) NULL,
				CreatedBy NVARCHAR(100) NULL,
				CreatedDate DATETIME NULL,
				UpdatedBy NVARCHAR(100) NULL,
				UpdatedDate DATETIME NULL,
				IsActive BIT NULL,
				IsDeleted BIT NULL,
				MasterCompanyId BIGINT NULL,
				EntityStructureId BIGINT NULL,
				Level1 NVARCHAR(200) NULL,
				Level2 NVARCHAR(200) NULL,
				Level3 NVARCHAR(200) NULL,
				Level4 NVARCHAR(200) NULL
			);

			-- Split ManagementStructureIds and expand
			INSERT INTO @Expanded
			SELECT
				I.ItemMasterCapesId,
				I.ItemMasterId,
				I.CapabilityTypeId,
				TRY_CAST(value AS BIGINT) AS ManagementStructureId,
				I.IsVerified,
				I.VerifiedById,
				I.VerifiedDate,
				I.AddedDate,
				I.Memo,
				I.PartNumber,
				I.PartDescription,
				I.CapabilityType,
				I.VerifiedBy,
				I.CreatedBy,
				I.CreatedDate,
				I.UpdatedBy,
				I.UpdatedDate,
				I.IsActive,
				I.IsDeleted,
				I.MasterCompanyId,
				I.EntityStructureId,
				I.Level1,
				I.Level2,
				I.Level3,
				I.Level4
			FROM @ItemMasterCapesList I
			CROSS APPLY STRING_SPLIT(I.ManagementStructureIds, ',');

			IF OBJECT_ID(N'tempdb..#ItemMasterCapes') IS NOT NULL  
			BEGIN  
				DROP TABLE #ItemMasterCapes  
			END
		
			-- For inernal used
			CREATE TABLE #ItemMasterCapes   
			(  
			    ID BIGINT NOT NULL IDENTITY,   
			    ItemMasterId BIGINT,
				CapabilityTypeId INT,
				ManagementStructureId BIGINT NULL,
				ManagementStructureIds NVARCHAR(MAX),
				IsVerified BIT NULL,
				VerifiedById BIGINT NULL,
				VerifiedDate DATETIME NULL,
				AddedDate DATETIME NULL,
				Memo NVARCHAR(MAX) NULL,
				PartNumber NVARCHAR(100) NULL,
				PartDescription NVARCHAR(500) NULL,
				CapabilityType NVARCHAR(200) NULL,
				VerifiedBy NVARCHAR(200) NULL,
				CreatedBy NVARCHAR(100) NULL,
				CreatedDate DATETIME NULL,
				UpdatedBy NVARCHAR(100) NULL,
				UpdatedDate DATETIME NULL,
				IsActive BIT,
				IsDeleted BIT,
				MasterCompanyId BIGINT,
				EntityStructureId BIGINT NULL,
				Level1 NVARCHAR(200) NULL,
				Level2 NVARCHAR(200) NULL,
				Level3 NVARCHAR(200) NULL,
				Level4 NVARCHAR(200) NULL
			);

			INSERT INTO #ItemMasterCapes (ItemMasterId,CapabilityTypeId,ManagementStructureId,IsVerified,VerifiedById,VerifiedDate,
										  AddedDate,Memo,PartNumber,PartDescription,CapabilityType,VerifiedBy,CreatedBy,CreatedDate,
										  UpdatedBy,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,Level1,Level2,Level3,Level4)  
			SELECT ItemMasterId,CapabilityTypeId,ManagementStructureId,IsVerified,VerifiedById,VerifiedDate,
										  AddedDate,Memo,PartNumber,PartDescription,CapabilityType,VerifiedBy,CreatedBy,CreatedDate,
										  UpdatedBy,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,Level1,Level2,Level3,Level4
			FROM @Expanded;

			SELECT @TotalCounts = COUNT(ID) FROM #ItemMasterCapes;
			WHILE @count <= @TotalCounts
			BEGIN
				SELECT @ManagementStructureId = [ManagementStructureId], 
					   @MasterCompanyId = MasterCompanyId ,
					   @ItemMasterId = ItemMasterId,
					   @CapabilityTypeId = CapabilityTypeId,
					   @UpdatedBy = [UpdatedBy]  
				FROM #ItemMasterCapes imc WHERE imc.ID = @count;

				IF NOT EXISTS(SELECT TOP 1 ItemMasterCapesId FROM DBO.ItemMasterCapes WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId 
							 AND ManagementStructureId = @ManagementStructureId AND CapabilityTypeId = @CapabilityTypeId AND MasterCompanyId = @MasterCompanyId)
				BEGIN
					 INSERT INTO dbo.ItemMasterCapes
					 (
				 		 ItemMasterId,CapabilityTypeId,ManagementStructureId,IsVerified,VerifiedById,VerifiedDate,
				 		 AddedDate,Memo,PartNumber,PartDescription,CapabilityType,VerifiedBy,CreatedBy,
				 		 CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,
				 		 Level1,Level2,Level3,Level4
					 )
					 SELECT ItemMasterId,CapabilityTypeId,ManagementStructureId,IsVerified,VerifiedById,VerifiedDate,
				 		 AddedDate,Memo,PartNumber,PartDescription,CapabilityType,VerifiedBy,CreatedBy,
				 		 CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,MasterCompanyId,
				 		 Level1,Level2,Level3,Level4
					 FROM #ItemMasterCapes imc WHERE imc.ID = @count;
				 
					 SELECT @ItemMasterCapesId = SCOPE_IDENTITY();

					 DECLARE @MSDetailsId BIGINT;

					 --Added in MS Details
					 EXEC DBO.USP_SaveItemMaserMSDetails @ModuleId,@ItemMasterCapesId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@MSDetailsId OUTPUT;
				END
				ELSE
				BEGIN
					 SET @IsDuplicate = 1;
				END				 

				 SET @count = @count + 1;
			END

			--UpdateItemMasterCapsDetails 
			EXEC [dbo].[UpdateItemMasterCapsDetail] @ItemMasterId;

			SELECT @IsDuplicate AS Isduplicate;

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = 'dbo.USP_AddItemMasterCapes' 
				, @ProcedureParameters VARCHAR(3000) =  '@SourceBy = ' + ''
				, @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName           = @DatabaseName
			, @AdhocComments          = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName        =  @ApplicationName
			, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END