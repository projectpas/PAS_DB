﻿
/*************************************************************             
 ** File:   [CreateStocklineForFinishGoodMPN]             
 ** Author:   Hemant Saliya  
 ** Description: This stored procedure is used Create Stockline For Finished Good.      
 ** Purpose:           
 ** Date:   09/09/2021          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    09/09/2021   Hemant Saliya		Created  
	2    28/09/2021   Hemant Saliya		Update for Existing STL & PN  
	3    05/05/2022   Hemant Saliya		Update Existing STL Inactive  
    4    28/11/2022   Subhash Saliya    Delete Scrap Certificate Record.   
	5    23/05/2023   Hemant Saliya		Updated for Internal WO and Teardown WO  
	6    23/05/2023   Hemant Saliya		Updated for Internal WO Cost Need to Update in New Stockline  
	7    06/14/2023	  Devendra Shekh    changed function udfGenerateCodeNumber to [udfGenerateCodeNumberWithOutDash]
	8    07/18/2023	  Vishal Suthar		added new stockline history
	9    26/07/2023   Satish Gohil      Gl Account Condition added for Account
	10   04/08/2023   Satish Gohil	    Seprate Accounting Entry WO Type Wise
	11   18/08/2023   Vishal Suthar	    Added history for old stockline
	12   16/10/2023   Devendra Shekh	timelife issue resolved
	13   30/11/2023   Moin Bloch        Modify(Added LotId in New Stockline)
	14   01/05/2024   Devendra Shekh    Modify(Added LotId in New Stockline)
 ** 15   02/19/2024	  HEMANT SALIYA	    Updated for Restrict Accounting Entry by Master Company
    16   04/19/2024   Moin Bloch        Modify(Added RepairOrderNumber in New Stockline)
	17   05/04/2024	  HEMANT SALIYA	    Updated for Add Existing Customer Details

-- EXEC [CreateStocklineForFinishGoodMPN] 947  
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateStocklineForFinishGoodMPN]
@WorkOrderPartNumberId BIGINT  
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    DECLARE @StocklineId BIGINT;  
    DECLARE @CustomerId BIGINT;  
    DECLARE @IsCustomerStock INT;  
    DECLARE @NewStocklineId BIGINT;  
    DECLARE @RevisedConditionId BIGINT;  
    DECLARE @RevisedPartNoId BIGINT;  
    DECLARE @MasterCompanyId BIGINT;  
    DECLARE @SLCurrentNumber BIGINT;  
    DECLARE @StockLineNumber VARCHAR(50);  
    DECLARE @PreviousStockLineNumber VARCHAR(50); 
	DECLARE @LotId BIGINT;  
    DECLARE @PreviousPartNumber VARCHAR(50);  
    DECLARE @RevisedPartNumber VARCHAR(50);  
    DECLARE @CNCurrentNumber BIGINT;   
    DECLARE @ControlNumber VARCHAR(50);  
    DECLARE @IDNumber VARCHAR(50);  
    DECLARE @ModuleID INT;  
    DECLARE @EntityMSID BIGINT;  
    DECLARE @IsExchangeWO BIT;  
    DECLARE @ReceivingCustomerWorkId BIGINT;  
    DECLARE @WOItemMasterId BIGINT;  
    DECLARE @RevisedItemmasterid BIGINT;  
    DECLARE @WorkOrderId BIGINT;  
    DECLARE @WorkOrderNumber VARCHAR(50);  
    DECLARE @RevisedConditionName VARCHAR(50);  
    DECLARE @RC int  
    DECLARE @DistributionMasterId bigint  
	DECLARE @DistributionCode VARCHAR(50)
    DECLARE @ReferencePartId bigint  
    DECLARE @ReferencePieceId bigint=0  
    DECLARE @InvoiceId bigint=0  
    DECLARE @IssueQty bigint=0  
    DECLARE @laborType varchar(200)='DIRECTLABOR'  
    DECLARE @issued bit=1  
    DECLARE @Amount decimal(18,2)  
    DECLARE @ModuleName varchar(200)='WO'  
    DECLARE @UpdateBy varchar(200)  
    DECLARE @InternalWorkOrderTypeId INT;  
    DECLARE @WorkOrderTypeId INT;  
    DECLARE @MaterialsCost DECIMAL(18,2);  
    DECLARE @LaborCost DECIMAL(18,2); 
	DECLARE @WOTypeId INT= 0;
	DECLARE @CustomerWOTypeId INT= 0;
	DECLARE @InternalWOTypeId INT= 0;
	DECLARE @WOPartSerNumber VARCHAR(200) = '';  

    SET @ModuleID = 2; -- Stockline Module ID  
    SET @InternalWorkOrderTypeId = 2 -- Internal WO  
  
    SELECT @MaterialsCost = ISNULL(PartsCost, 0),  @LaborCost =  ISNULL(LaborCost, 0) FROM dbo.WorkOrderMPNCostDetails WITH(NOLOCK) WHERE WOPartNoId = @WorkOrderPartNumberId  

	SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
	SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'
  
    SELECT @DistributionMasterId = ID , @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('WOSETTLEMENTTAB')  
    SELECT @StocklineId = WOP.StockLineId,         
      @RevisedConditionId = CASE WHEN ISNULL(WOP.RevisedConditionId, 0) > 0 THEN WOP.RevisedConditionId ELSE WOP.ConditionId END,   
      @RevisedPartNoId = CASE WHEN ISNULL(WOS.RevisedPartId, 0) > 0 THEN WOS.RevisedPartId ELSE WOP.ItemMasterId END,  
      @MasterCompanyId  = WOP.MasterCompanyId,  
      @EntityMSID = WOP.ManagementStructureId,  
      @ReceivingCustomerWorkId = WOP.ReceivingCustomerWorkId,  
      @PreviousPartNumber=IM.partnumber,  
      @RevisedPartNumber=WOP.RevisedPartNumber,  
      @WOItemMasterId= WOP.ItemMasterId,  
      @RevisedItemmasterid= ISNULL(WOP.RevisedItemmasterid,0),  
      @WorkOrderId =WOP.WorkOrderId,  
      @RevisedConditionName=WOS.conditionName,  
      @UpdateBy=WOP.UpdatedBy,
	  @WOPartSerNumber = ISNULL(WOP.RevisedSerialNumber, '')
    FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)  
     LEFT JOIN [dbo].WorkOrderSettlementDetails WOS WITH(NOLOCK) ON WOS.workOrderPartNoId = WOP.id AND WOS.WorkOrderSettlementId = 9  
     LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId  
    WHERE WOP.ID = @WorkOrderPartNumberId
  
    SELECT @WorkOrderNumber = WorkOrderNum, @CustomerId = CustomerId, @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId  
    SELECT @ReferencePartId = WorkFlowWorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkOrderPartNoId = @WorkOrderPartNumberId  
    SELECT @IsCustomerStock = CASE WHEN ISNULL(CustomerAffiliationId, 0) = 2 THEN 1 ELSE 0 END FROM dbo.Customer WITH(NOLOCK) WHERE CustomerId = @CustomerId --2 For Customer Stock  
    SELECT @IsExchangeWO = CASE WHEN ISNULL(ExchangeSalesOrderId , 0) > 0 THEN 1 ELSE 0 END  
    FROM dbo.ReceivingCustomerWork WITH(NOLOCK) WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId  
  
    IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
    BEGIN  
    DROP TABLE #tmpCodePrefixes  
    END  
      
    CREATE TABLE #tmpCodePrefixes  
    (  
      ID BIGINT NOT NULL IDENTITY,   
      CodePrefixId BIGINT NULL,  
      CodeTypeId BIGINT NULL,  
      CurrentNumber BIGINT NULL,  
      CodePrefix VARCHAR(50) NULL,  
      CodeSufix VARCHAR(50) NULL,  
      StartsFrom BIGINT NULL,  
    )  
  
    /* PN Manufacturer Combination Stockline logic */  
    CREATE TABLE #tmpPNManufacturer  
    (  
      ID BIGINT NOT NULL IDENTITY,   
      ItemMasterId BIGINT NULL,  
      ManufacturerId BIGINT NULL,  
      StockLineNumber VARCHAR(100) NULL,  
      CurrentStlNo BIGINT NULL,  
      isSerialized BIT NULL  
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
    /* PN Manufacturer Combination Stockline logic */  
  
    INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom)   
    SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
    FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
    WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
  
    DECLARE @currentNo AS BIGINT = 0;  
    DECLARE @stockLineCurrentNo AS BIGINT;  
    DECLARE @ItemMasterId AS BIGINT;  
    DECLARE @ManufacturerId AS BIGINT;  
  
    SELECT @ItemMasterId = CASE WHEN ISNULL(@RevisedPartNoId, 0) > 0 THEN @RevisedPartNoId ELSE ItemMasterId END, 
	       @ManufacturerId = ManufacturerId, 
		   @PreviousStockLineNumber = StockLineNumber		 
	 FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @StocklineId
    
	SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId  
  
    IF (@currentNo <> 0)  
    BEGIN  
     SET @stockLineCurrentNo = @currentNo + 1  
    END  
    ELSE  
    BEGIN  
     SET @stockLineCurrentNo = 1  
    END  
  
    IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 30))  
    BEGIN   
     SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))  
  
     UPDATE DBO.ItemMaster  
     SET CurrentStlNo = @stockLineCurrentNo  
     WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId  
    END  
    ELSE   
    BEGIN  
     ROLLBACK TRAN;  
    END  
  
    IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 9))  
    BEGIN   
     SELECT   
      @CNCurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
       ELSE CAST(StartsFrom AS BIGINT) + 1 END   
     FROM #tmpCodePrefixes WHERE CodeTypeId = 9  
  
     SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 9)))  
    END  
    ELSE   
    BEGIN  
     ROLLBACK TRAN;  
    END  
  
    IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 17))  
    BEGIN   
  
     SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 17)))  
    END  
    ELSE   
    BEGIN  
     ROLLBACK TRAN;  
    END  
  
    INSERT INTO [dbo].[Stockline]  
       ([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId]  
       ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]  
       ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]  
       ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]  
       ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]  
       ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]  
       ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]  
       ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]  
       ,[UnitSalePriceAdjustmentReasonTypeId],[IdNumber],[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]  
       ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],[QuantityRejected],[PurchaseOrderPartRecordId]  
       ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]  
       ,[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved]  
       ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]  
       ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId]  
       ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]  
       ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]  
       ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]  
       ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]  
       ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType]  
       ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType]  
       ,[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],IsFinishGood,[IsStkTimeLife]
	   ,[LotId],[IsLotAssigned],[RepairOrderNumber], [ExistingCustomerId], [ExistingCustomer], IsTurnIn, DaysReceived, ManufacturingDays, TagDays, 
	   OpenDays, ExchangeSalesOrderId, RRQty, SubWorkOrderNumber, IsManualEntry, WorkOrderMaterialsKitId, OriginalCost, POOriginalCost, ROOriginalCost, 
	   Adjustment, FreightAdjustment, TaxAdjustment, SubWorkOrderMaterialsId, SubWorkOrderMaterialsKitId, EvidenceId, IsGenerateReleaseForm)  
    SELECT CASE WHEN ISNULL(@RevisedPartNoId, 0) > 0 THEN (SELECT PartNumber FROM dbo.ItemMaster IM WITH(NOLOCK) WHERE IM.ItemMasterId = @RevisedPartNoId) ELSE [PartNumber] END,  
     @StockLineNumber,[StocklineMatchKey],Stockline.ControlNumber,@ItemMasterId,1,@RevisedConditionId  
       ,[SerialNumber],[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo]  
       ,[ManufacturerId],[Manufacturer],[ManufacturerLotNumber],[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber]  
       ,[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate],[CalibrationMemo],[OrderDate],[PurchaseOrderId]  
       ,[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate],[ReceiverNumber]  
       ,[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER]  
       ,[OEM],[Memo],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE()  
       ,[isSerialized],[ShelfId],[BinId],[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId]  
       ,[UnitSalePriceAdjustmentReasonTypeId],IDNumber,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace]  
       ,[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber],0,[PurchaseOrderPartRecordId]  
       ,[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId],[WorkOrderMaterialsId]  
       ,0,0,0,1,1,0,[QtyReserved]  
       ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId]  
       ,[isActive],[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],   
        CASE WHEN @IsExchangeWO = 1 THEN 0 ELSE @IsCustomerStock END  
       ,[EntryDate],[LotCost],[NHAItemMasterId]  
       ,[TLAItemMasterId],[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate]  
       ,[VendorId],[IsParent],[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId]  
       ,[PurchaseUnitOfMeasureId],[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition]  
       ,[GlAccountName],[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber]  
       ,[NHAPartNumber],[TLAPartDescription],[NHAPartDescription],[itemType],CASE WHEN @IsExchangeWO = 1 THEN NULL ELSE [CustomerId] END  
       ,CASE WHEN @IsExchangeWO = 1 THEN NULL ELSE [CustomerName] END,CASE WHEN @IsExchangeWO = 1 THEN 0 ELSE [isCustomerstockType] END   
       ,[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber],[TaggedBy],[TaggedByName],  
       CASE WHEN @InternalWorkOrderTypeId = @WorkOrderTypeId THEN [UnitCost] + @MaterialsCost + @LaborCost ELSE [UnitCost] END,  
       [TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[TagTypeId],1,[IsStkTimeLife],
	   [LotId],[IsLotAssigned],[RepairOrderNumber], [ExistingCustomerId], [ExistingCustomer], IsTurnIn, DaysReceived, ManufacturingDays, TagDays, 
	   OpenDays, ExchangeSalesOrderId, RRQty, SubWorkOrderNumber, IsManualEntry, WorkOrderMaterialsKitId, OriginalCost, POOriginalCost, ROOriginalCost, 
	   Adjustment, FreightAdjustment, TaxAdjustment, SubWorkOrderMaterialsId, SubWorkOrderMaterialsKitId, EvidenceId, IsGenerateReleaseForm
   FROM [dbo].[Stockline] WITH(NOLOCK)  
   WHERE [StockLineId] = @StocklineId  

    SELECT @NewStocklineId = SCOPE_IDENTITY()  
  
    UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNumber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId  
  
    EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @NewStocklineId  

	DECLARE @IsStkTimeLife BIT
	SELECT @IsStkTimeLife = [IsStkTimeLife] FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @NewStocklineId 
  
	IF(@IsStkTimeLife = 1)
	BEGIN
		INSERT INTO [dbo].[TimeLife]  
		 ([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]  
		 ,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]  
		 ,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]  
		 ,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],[DetailsNotProvided]  
		 ,[RepairOrderId],[RepairOrderPartRecordId])  
		SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair]  
		 ,[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew]  
		 ,[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(), GETUTCDATE()  
		 ,[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],@NewStocklineId,[DetailsNotProvided]  
		 ,[RepairOrderId],[RepairOrderPartRecordId]   
		FROM TimeLife TL WITH (NOLOCK) WHERE TL.StockLineId = @StocklineId  
	END
  
    UPDATE [dbo].[WorkOrderPartNumber] SET StockLineId = @NewStocklineId WHERE ID = @WorkOrderPartNumberId;  
  
    if(@RevisedItemmasterid > 0 and @RevisedItemmasterid != @WOItemMasterId)  
    BEGIN  
       UPDATE [dbo].[Stockline] SET Memo = 'This PN has been modified. Previous PN: ' + @PreviousPartNumber + ' has been Revised to PN: ' + @RevisedPartNumber + 'WO Num:' + @WorkOrderNumber + ' Date: '+ FORMAT (GETUTCDATE(), 'dd/MM/yyyy ')  
     WHERE StockLineId = @NewStocklineId  
    END  
    ELSE  
    BEGIN  
     UPDATE [dbo].[Stockline] SET Memo = 'This Stockline has been modified. Previous stockline is: ' + @PreviousStockLineNumber + '. In WO Num:' + @WorkOrderNumber + ' Date: '+ FORMAT (GETUTCDATE(), 'dd/MM/yyyy ')  
     WHERE StockLineId = @NewStocklineId  
    END  

	IF(ISNULL(@WOPartSerNumber, '') != '')
	BEGIN
		UPDATE [dbo].[Stockline] 
		SET [SerialNumber] = @WOPartSerNumber, isSerialized = 1
		WHERE StockLineId = @NewStocklineId  
	END
  
	DECLARE @ActionId INT = 0;

    UPDATE [dbo].[Stockline] SET Quantity=0, QuantityOnHand = 0, QuantityAvailable = 0, isActive = 0,QuantityReserved=0,QuantityIssued=0,   
     Memo = 'This stockline has been repaired. Repaired stockline is: ' + @StockLineNumber + ' and Control Number is: ' + ControlNumber  
       WHERE StockLineId = @StocklineId  

	DECLARE @HistoryModuleId INT = 15;
	SET @ActionId = 6; -- RemoveOnHand
	EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = 1, @UpdatedBy = @UpdateBy;
  
    if(UPPER(@RevisedConditionName) !='SCRAPPED')  
    BEGIN  
        Delete FROM dbo.ScrapCertificate   
        WHERE workOrderPartNoId = @WorkOrderPartNumberId and WorkOrderId=@WorkOrderId  
    END  
  
	SET @ActionId = 11; -- Add-From-Module
	EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = 1, @UpdatedBy = @UpdateBy;

    EXEC USP_SaveSLMSDetails @ModuleID, @NewStocklineId, @EntityMSID, @MasterCompanyId, 'WO Close Job'  
    
	SELECT TOP 1 @WOTypeId =WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @WorkOrderId

	DECLARE @IsRestrict BIT;
	DECLARE @IsAccountByPass BIT;

	EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

	IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
		BEGIN

			EXEC [dbo].[USP_BatchTriggerBasedonDistribution]   
			@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy  

		END
	END

	IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
		BEGIN

			EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]  
			@DistributionMasterId,@WorkOrderId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy  

		END
	END
  
    IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
    BEGIN  
     DROP TABLE #tmpCodePrefixes   
    END  
  
    IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
    BEGIN  
     DROP TABLE #tmpPNManufacturer   
    END    
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'CreateStocklineForFinishGoodMPN'                
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderPartNumberId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END