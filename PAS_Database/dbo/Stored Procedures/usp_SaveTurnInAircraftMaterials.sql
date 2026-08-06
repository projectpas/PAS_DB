/*************************************************************     
** Author:  <Amit Ghediya>    
** Create date: <08/04/2026>    
** Description: <This Proc Is used to Same Turn In Aircraft Materials Stockline>    
    
Exec [usp_SaveTurnInAircraftMaterials]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
   1    08/04/2026  Amit Ghediya		Created  
   2	07/05/2026  Nakul Chandigra		Added two new field in stockline Save (PN-16315)
   3	07/05/2026  Nakul Chandigra		Changed Size of two new field  (PN-16315)
   4	21/05/2026  Abhishek Jirawla	Added stockline Id to AircraftRegistryHeader  (PN-16523)
   5	22/05/2026  Abhishek Jirawla	Added @IsCustomer Stock based on customer
   6	26/05/2026  Priyansh Patel	    Added new field 'TTSN, TCSN '(PN-16477)
	7    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************/   
CREATE     PROCEDURE [dbo].[usp_SaveTurnInAircraftMaterials]  
	@IsCustomerStock BIT = 0,  
	@IsCustomerstockType BIT,  
	@ItemMasterId BIGINT,  
	@UnitOfMeasureId BIGINT,  
	@ConditionId BIGINT,  
	@Quantity DECIMAL(18,6),  
	@IsSerialized BIT,  
	@SerialNumber VARCHAR(50),  
	@CustomerId BIGINT = NULL,  
	@ObtainFromTypeId INT = NULL,  
	@ObtainFrom BIGINT = NULL,  
	@ObtainFromName VARCHAR(500) = NULL,  
	@OwnerTypeId INT = NULL,  
	@Owner BIGINT = NULL,  
	@OwnerName VARCHAR(500) = NULL,  
	@TraceableToTypeId INT = NULL,  
	@TraceableTo BIGINT = NULL,  
	@TraceableToName VARCHAR(500) = NULL,  
	@Memo VARCHAR(MAX),  
	@AircraftRegistryId BIGINT,
	@AircraftInstalledPartDetailsId BIGINT,
	@ManufacturerId BIGINT,  
	@InspectedById BIGINT = NULL,  
	@InspectedDate DATETIME2(7) = NULL,  
	@ReceiverNumber VARCHAR(500),  
	@ReceivedDate DATETIME2(7),  
	@ManagementStructureId BIGINT,  
	@SiteId BIGINT,  
	@WarehouseId BIGINT = NULL,  
	@LocationId BIGINT = NULL,  
	@ShelfId BIGINT = NULL,  
	@BinId BIGINT = NULL,  
	@MasterCompanyId BIGINT,  
	@UpdatedBy VARCHAR(100),  
	@IsKitType BIT = 0,  
	@Unitcost [decimal](18,6) = 0,
	@ProvisionId INT =0, 
	@EvidenceId INT = NULL,
	@AircraftTail VARCHAR(400) = NULL,  
	@AircraftSN VARCHAR(30) = NULL,
	@TotalTSN DECIMAL(18,2) = NULL,
	@TotalCSN DECIMAL(18,2) = NULL,
	@TotalTSNMM DECIMAL(18,6) = NULL,
	@TotalCSNMM DECIMAL(18,6) = NULL

AS  
BEGIN  
   
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

  
	 DECLARE @PartNumber VARCHAR(500),
			 @SLCurrentNummber BIGINT,  
			 @StockLineNumber VARCHAR(50),  
			 @CNCurrentNummber BIGINT, 
			 @ControlNumber VARCHAR(50),
			 @IDCurrentNummber BIGINT,   
			 @IDNumber VARCHAR(50),  
			 @StockLineId BIGINT,  
			 @MSModuleID INT = 2, -- Stockline Module ID  
			 @IsPMA BIT = 0,  
			 @IsDER BIT = 0,  
			 @IsOemPNId BIGINT,
			 @IsOEM BIT = 0,  
			 @OEMPNNumber VARCHAR(500),  
			 @ReferenceId BIGINT,   
			 @SubReferenceId BIGINT,
			 @IsSerialised BIT,
			 @ModuleId BIGINT,  
			 @SubModuleId BIGINT,  
			 @stockLineQty DECIMAL(18,6),
			 @stockLineQtyAvailable DECIMAL(18,6),
			 @GLAccountId INT,  
			 @IsTimeLife BIT, 
			 @StockUOMId  BIGINT = @UnitOfMeasureId, 
			 @PurchaseUOMId BIGINT, 
			 @ConsumeUOMId BIGINT,  
			 @AircraftRegistryNumber VARCHAR(50),
			 @ActionId INT = 0,
			 @ItemClassificationId BIGINT = 0,
			 @IntegrationPortal VARCHAR(50),
			 @HistoryModuleId INT = 0,
			 @currentNo AS BIGINT,
			 @stockLineCurrentNo AS BIGINT;
   -- #STEP 1 CREATE STOCKLINE  
   BEGIN TRY 
   BEGIN TRANSACTION  
    BEGIN 

		IF @IsCustomerStock IS NULL OR @IsCustomerStock = 0
		BEGIN
			SELECT @IsCustomerStock = (CASE WHEN CustomerAffiliationId = 2 THEN 1 ELSE 0 END) FROM dbo.Customer WITH(NOLOCK) where CustomerId = @CustomerId
		END
		 

		 SET @TraceableTo = CASE WHEN @TraceableTo = 0 THEN NULL ELSE @TraceableTo END	 
		 SET @InspectedById = CASE WHEN @InspectedById = 0 THEN NULL ELSE @InspectedById END	 
		 SET @WarehouseId = CASE WHEN @WarehouseId = 0 THEN NULL ELSE @WarehouseId END
		 SET @LocationId = CASE WHEN @LocationId = 0 THEN NULL ELSE @LocationId END
		 SET @ShelfId = CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END
		 SET @BinId = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END	
	 
		 SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'StockLine'; -- For Stockline Module   
		 SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'AircraftRegistry'; -- For Aircraft Registry Materials Module  

		 IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL  
		 BEGIN  
			  DROP TABLE #tmpCodePrefixes_Parent  
		 END  
      
		 CREATE TABLE #tmpCodePrefixes_Parent  
		 (  
		   [ID] BIGINT NOT NULL IDENTITY,   
		   [CodePrefixId] BIGINT NULL,  
		   [CodeTypeId] BIGINT NULL,  
		   [CurrentNummber] BIGINT NULL,  
		   [CodePrefix] VARCHAR(50) NULL,  
		   [CodeSufix] VARCHAR(50) NULL,  
		   [StartsFrom] BIGINT NULL,  
		 )  
  
		 /* PN Manufacturer Combination Stockline logic */  
		 CREATE TABLE #tmpPNManufacturer  
		 (  
		   [ID] BIGINT NOT NULL IDENTITY,   
		   [ItemMasterId] BIGINT NULL,  
		   [ManufacturerId] BIGINT NULL,  
		   [StockLineNumber] VARCHAR(100) NULL,  
		   [CurrentStlNo] BIGINT NULL,  
		   [isSerialized] BIT NULL  
		 )  
  
		 ;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS  
		 (  
			  SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId  
			  FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1 CROSS JOIN  
			   (SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2 LEFT JOIN  
			   DBO.Stockline ac WITH (NOLOCK)  
			   ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
			  WHERE ac.MasterCompanyId = @MasterCompanyId  
			  GROUP BY ac.ItemMasterId, ac.ManufacturerId  
			  HAVING COUNT(ac.ItemMasterId) > 0  
		 )  
  
		 INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)  
		 SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized  
		 FROM CTE_Stockline CSTL INNER JOIN DBO.Stockline STL WITH (NOLOCK)   
		 INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId  
		 ON CSTL.StockLineId = STL.StockLineId  
  
		  WHERE ISNULL(IM.IsNonStock,0) = 0
SELECT @PurchaseUOMId = PurchaseUnitOfMeasureId, @PartNumber = partnumber, @IsPMA = IsPMA, @IsDER = IsDER, @IsOemPNId = IsOemPNId, @IsOEM = IsOEM, @OEMPNNumber = OEMPN,@GLAccountId=GLAccountId, @IsTimeLife = isTimeLife, @ItemClassificationId = [ItemClassificationId]   FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;  
     
		 SELECT @AircraftRegistryNumber = [AircraftRegistryNumber] FROM [dbo].[AircraftRegistryHeader] WITH(NOLOCK) WHERE [AircraftRegistryId] = @AircraftRegistryId 

		 INSERT INTO #tmpCodePrefixes_Parent (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom)   
		 SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
		 FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
		 WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
  
		 SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId  
  
		 IF (@currentNo <> 0)  
		 BEGIN  
			  SET @stockLineCurrentNo = @currentNo + 1  
		 END  
		 ELSE  
		 BEGIN  
		      SET @stockLineCurrentNo = 1  
		 END  
  
		 IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE [CodeTypeId] = 30))  
		 BEGIN   
		      SET @StockLineNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@stockLineCurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30)))  
      
		      UPDATE [dbo].[ItemMaster] SET [CurrentStlNo] = @stockLineCurrentNo WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId  
		 END  
		 ELSE   
		 BEGIN  
			  ROLLBACK TRAN;  
		 END  
  
		 IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9))  
		 BEGIN   
			  SELECT   
			   @CNCurrentNummber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1   
				ELSE CAST(StartsFrom AS BIGINT) + 1 END   
			  FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9  
  
		     SET @ControlNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@CNCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9)))  
		 END  
		 ELSE   
		 BEGIN  
		      ROLLBACK TRAN;  
		 END  
  
		 IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17))  
		 BEGIN   
			  SET @IDCurrentNummber = 1;  
		      SET @IDNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@IDCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17)))  
		 END  
		 ELSE   
		 BEGIN  
			  ROLLBACK TRAN;  
		 END    
		
			SELECT @IntegrationPortal = STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',')
			FROM dbo.ItemMaster iM WITH(NOLOCK)
			LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
			LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
			WHERE iM.ItemMasterId = @ItemMasterId AND iM.MasterCompanyId = @MasterCompanyId AND mp.IntegrationPortalId IS NOT NULL
			 AND ISNULL(iM.IsNonStock,0) = 0
			GROUP BY iM.ItemMasterId

		 INSERT INTO [dbo].[Stockline](StockLineNumber, ControlNumber, IDNumber, IsCustomerStock,IsCustomerstockType,ItemMasterId,PartNumber, PurchaseUnitOfMeasureId,ConditionId,Quantity,   
		   QuantityAvailable, QuantityOnHand,QuantityTurnIn,IsSerialized,SerialNumber, CustomerId, ObtainFromType, ObtainFrom, ObtainFromName, OwnerType, [Owner], OwnerName, TraceableToType,   
		   TraceableTo, TraceableToName, Memo, WorkOrderId, WorkOrderNumber, ManufacturerId, InspectionBy, InspectionDate, ReceiverNumber, IsParent, LotCost, ParentId,  
		   QuantityIssued, QuantityReserved,QuantityToReceive,RepairOrderExtendedCost, SubWOPartNoId,SubWorkOrderId, WorkOrderExtendedCost, WorkOrderPartNoId,  
		   ReceivedDate, ManagementStructureId, SiteId, WarehouseId, LocationId, ShelfId, BinId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,isActive, isDeleted, MasterCompanyId, IsTurnIn,  
		   [OEM],IsPMA, IsDER,IsOemPNId, OEMPNNumber,GLAccountId,[IsStkTimeLife],[EvidenceId], [IntegrationPortal], StockUnitOfMeasureId, ConsumeUnitOfMeasureId,AircraftInstalledPartDetailsId, AircraftTailNumber, AircraftSN,TotalTSN, TotalCSN, TotalTSNMM, TotalCSNMM
		 ) VALUES(@StockLineNumber, @ControlNumber, @IDNumber, @IsCustomerStock,@IsCustomerstockType,@ItemMasterId,@PartNumber,@PurchaseUOMId,@ConditionId,@Quantity, @Quantity, @Quantity, @Quantity,  
		   @IsSerialized,@SerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName, @TraceableToTypeId,   
		   @TraceableTo, @TraceableToName, @Memo, NULL, NULL, @ManufacturerId, @InspectedById, @InspectedDate, @ReceiverNumber, 1, 0,0,0,0,0,0,0,0,0,0,  
		   @ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),GETUTCDATE(),1,0, @MasterCompanyId, 1,  
		   @IsOEM,@IsPMA, @IsDER,@IsOemPNId, @OEMPNNumber,@GLAccountId, @IsTimeLife,@EvidenceId, @IntegrationPortal, @StockUOMId, @ConsumeUOMId,@AircraftInstalledPartDetailsId, @AircraftTail, @AircraftSN, @TotalTSN, @TotalCSN, @TotalTSNMM,@TotalCSNMM );  
       
		 SELECT @StockLineId = SCOPE_IDENTITY()  
  
		 UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @SLCurrentNummber WHERE [CodeTypeId] = 30 AND [MasterCompanyId] = @MasterCompanyId --(30,17,9)  
  
		 UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNummber WHERE [CodeTypeId] = 9 AND [MasterCompanyId] = @MasterCompanyId  
  
		 EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @StockLineId  
       
		 UPDATE [dbo].[Stockline] SET Memo = 'This Stockline is created using turn-in from ' + @AircraftRegistryNumber,Unitcost= @Unitcost WHERE [StockLineId] = @StockLineId  
		 
		 UPDATE [dbo].[AircraftRegistryHeader] SET StockLineId = @StockLineId WHERE [AircraftRegistryId] = @AircraftRegistryId;
	 
		 UPDATE [dbo].[AircraftInstalledPartDetails] SET StockLineId = @StockLineId,ConditionId = @ConditionId,Quantity = @Quantity WHERE [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId;
	 
		 SELECT @ActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type] = 'Tendered'
		 
		 SELECT @HistoryModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'AircraftRegistry';

		 EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @AircraftInstalledPartDetailsId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @Quantity, @UpdatedBy = @UpdatedBy;

		 --Add SL Managment Structure Details   
		 EXEC USP_SaveSLMSDetails @MSModuleID, @StockLineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy  
  
		 IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL  
		 BEGIN  
			  DROP TABLE #tmpCodePrefixes_Parent   
		 END  
  
		 IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
		 BEGIN  
			  DROP TABLE #tmpPNManufacturer   
		 END  

		 SELECT @StockLineId as StockLineId
    END  
   COMMIT  TRANSACTION 
    END TRY        
 BEGIN CATCH
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'usp_SaveTurnInAircraftMaterials'     
			, @ProcedureParameters VARCHAR(3000) = '@AircraftInstalledPartDetailsId = ''' + CAST(ISNULL(@AircraftInstalledPartDetailsId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
 END CATCH    
END