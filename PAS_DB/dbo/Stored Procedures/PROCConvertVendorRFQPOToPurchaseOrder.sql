/*************************************************************               
 ** File:   [PROCConvertVendorRFQPOToPurchaseOrder]               
 ** Author:  Moin Bloch    
 ** Description: This stored procedure is used to convert vendor RFQ PO to Purchase Order      
 ** Purpose:             
 ** Date:   04/01/2022            
              
 ** PARAMETERS: @VendorRFQPurchaseOrderId bigint,@VendorRFQPOPartRecordId bigint,@PurchaseOrderId bigint,@MasterCompanyId int,@CodeTypeId int,@Opr int    
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author		 Change Description                
 ** --   --------     -------		 --------------------------------              
    1    04/01/2022  Moin Bloch        Created    
    2    05/22/2023  Satish Gohil	   Remove Automatic (-)  
	3    01/12/2023  Amit Ghediya      Modify(Added Traceable & Tagged fields)
         
-- EXEC [PROCConvertVendorRFQPOToPurchaseOrder] 13,0,0,2,22,3,0    
************************************************************************/    
    
CREATE    PROCEDURE [dbo].[PROCConvertVendorRFQPOToPurchaseOrder]    
@VendorRFQPurchaseOrderId bigint,    
@VendorRFQPOPartRecordId bigint,    
@PurchaseOrderId bigint,    
@MasterCompanyId int,    
@CodeTypeId int,    
@Opr int,    
@Result int OUTPUT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 DECLARE @CurrentNummber bigint;    
 DECLARE @CodePrefix VARCHAR(50);    
 DECLARE @CodeSufix VARCHAR(50);     
 DECLARE @PurchaseOrderNumber VARCHAR(250);    
 DECLARE @IsEnforceApproval bit;    
 DECLARE @AttRFQPOModuleID int;    
 DECLARE @AttPOModuleID int;    
 DECLARE @PONumber VARCHAR(250);    
 BEGIN TRY    
 BEGIN TRANSACTION    
 BEGIN    
  DECLARE @MCID INT=0;    
  DECLARE @MSID BIGINT=0;    
  DECLARE @CreateBy VARCHAR(100)='';    
  DECLARE @UpdateBy VARCHAR(100)='';    
  DECLARE @PID BIGINT=0;    
  DECLARE @MSCID INT=0;    
  DECLARE @MSSID BIGINT=0;    
  DECLARE @CreatBy VARCHAR(100)='';    
  DECLARE @UpdatBy VARCHAR(100)='';    
  DECLARE @POPID BIGINT=0;    
  DECLARE @id int;    
  IF(@Opr = 1)    
  BEGIN    
   IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrder WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId )    
   BEGIN       
    SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM dbo.CodePrefixes WITH(NOLOCK)    
      WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;    
    
    SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM dbo.PurchaseOrderSettingMaster WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;    
    
    SELECT TOP 1 @AttRFQPOModuleID = [AttachmentModuleId] FROM dbo.AttachmentModule WITH(NOLOCK) WHERE [Name] ='VendorRFQPurchaseOrder';    
    SELECT TOP 1 @AttPOModuleID = [AttachmentModuleId] FROM dbo.AttachmentModule WITH(NOLOCK) WHERE [Name] ='PurchaseOrder';    
             
    IF(@CurrentNummber!='' OR @CurrentNummber!=NULL)    
    BEGIN    
     SET @PurchaseOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));    
    
     INSERT INTO [dbo].[PurchaseOrder]([PurchaseOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
                [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],[RequestedBy],    
          [Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],[ApproverId],[ApprovedBy],    
          [DateApproved],[POMemo],[Notes],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
          [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsEnforce],[PDFPath],[VendorRFQPurchaseOrderId])    
           SELECT @PurchaseOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
               [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],[RequestedBy],    
         [Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],NULL,NULL,    
         NULL,[Memo],[Notes],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
         [CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,0,@IsEnforceApproval,NULL,@VendorRFQPurchaseOrderId    
        FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId=@VendorRFQPurchaseOrderId;    
    
     --DECLARE @MCID INT=0;    
     --DECLARE @MSID BIGINT=0;    
     --DECLARE @CreateBy VARCHAR(100)='';    
     --DECLARE @UpdateBy VARCHAR(100)='';    
     --DECLARE @PID BIGINT=0;    
     SET @PID=IDENT_CURRENT('PurchaseOrder');    
     SELECT @MSID=[ManagementStructureId],@MCID=[MasterCompanyId],    
         @CreateBy=[CreatedBy],@UpdateBy=[UpdatedBy]    
        FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId=@VendorRFQPurchaseOrderId;    
            
     EXEC [DBO].[PROCAddPOMSData] @PID,@MSID,@MCID,@CreateBy,@UpdateBy,4,1,0    
    
     INSERT INTO [dbo].[PurchaseOrderPart]([PurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[AltEquiPartNumberId],[AltEquiPartNumber],    
         [AltEquiPartDescription],[StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[ConditionId],    
         [Condition],[QuantityOrdered],[QuantityBackOrdered],[QuantityRejected],[VendorListPrice],[DiscountPercent],[DiscountPerUnit],    
         [DiscountAmount],[UnitCost],[ExtendedCost],    
         [FunctionalCurrencyId],[FunctionalCurrency],[ForeignExchangeRate],    
         [ReportCurrencyId],[ReportCurrency],    
         [WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[RepairOrderId],[ReapairOrderNo],[SalesOrderId],[SalesOrderNo],    
         [ItemTypeId],[ItemType],    
         [GlAccountId],[GLAccount],    
         [UOMId],[UnitOfMeasure],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[ParentId],[isParent],[Memo],    
         [POPartSplitUserTypeId],[POPartSplitUserType],[POPartSplitUserId],[POPartSplitUser],[POPartSplitSiteId],[POPartSplitSiteName],    
         [POPartSplitAddressId],[POPartSplitAddress1],[POPartSplitAddress2],[POPartSplitAddress3],[POPartSplitCity],[POPartSplitState],    
         [POPartSplitPostalCode],[POPartSplitCountryId],[POPartSplitCountryName],[MasterCompanyId],[CreatedBy],[UpdatedBy],    
         [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[DiscountPercentValue],[EstDeliveryDate],[VendorRFQPOPartRecordId],
		 [TraceableTo],[TraceableToName],[TraceableToType],[TagTypeId],[TaggedByType],[TaggedBy],[TaggedByName],[TaggedByTypeName],[TagDate])    
        SELECT IDENT_CURRENT('PurchaseOrder'),VRFQP.[ItemMasterId],VRFQP.[PartNumber],VRFQP.[PartDescription],NULL,NULL,    
         NULL,VRFQP.[StockType],VRFQP.[ManufacturerId],VRFQP.[Manufacturer],VRFQP.[PriorityId],VRFQP.[Priority],VRFQP.[NeedByDate],VRFQP.[ConditionId],    
         VRFQP.[Condition],VRFQP.[QuantityOrdered],VRFQP.[QuantityOrdered],0,    
         CASE WHEN (SELECT ISNULL(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]) > 0 THEN     
         (SELECT ISNULL(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]) ELSE 0     
         END,    
         --(SELECT TOP 1 COALESCE(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]),    
         0,0,    
         0,VRFQP.[UnitCost],VRFQP.[ExtendedCost],    
        -- (SELECT TOP 1 L.FunctionalCurrencyId FROM dbo.ManagementStructure M WITH(NOLOCK) INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        --(SELECT TOP 1 FC.Code FROM dbo.ManagementStructure M WITH(NOLOCK)     
        --   INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        --   INNER JOIN dbo.Currency FC WITH(NOLOCK) ON L.FunctionalCurrencyId = FC.CurrencyId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),1,    
        --(SELECT TOP 1 L.ReportingCurrencyId FROM dbo.ManagementStructure M WITH(NOLOCK) INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        --(SELECT TOP 1 RC.Code FROM dbo.ManagementStructure M WITH(NOLOCK)     
        --   INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        --   INNER JOIN dbo.Currency RC WITH(NOLOCK) ON L.ReportingCurrencyId = RC.CurrencyId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        (SELECT TOP 1 FC.CurrencyId FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         (SELECT TOP 1 FC.Code FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),1,    
         (SELECT TOP 1 RC.CurrencyId FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         (SELECT TOP 1 RC.Code FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         VRFQP.[WorkOrderId],VRFQP.[WorkOrderNo],VRFQP.[SubWorkOrderId],VRFQP.[SubWorkOrderNo],NULL,NULL,VRFQP.[SalesOrderId],VRFQP.[SalesOrderNo],    
         1,'Stock',    
         (SELECT TOP 1 I.GLAccountId FROM dbo.ItemMaster I WITH(NOLOCK) WHERE I.ItemMasterId = VRFQP.[ItemMasterId]),NULL,    
         VRFQP.[UOMId],VRFQP.[UnitOfMeasure],VRFQP.[ManagementStructureId],VRFQP.[Level1],VRFQP.[Level2],VRFQP.[Level3],VRFQP.[Level4],NULL,1,VRFQP.[Memo],    
         NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,    
         VRFQP.[MasterCompanyId],VRFQP.[CreatedBy],VRFQP.[UpdatedBy],    
         VRFQP.[CreatedDate],VRFQP.[UpdatedDate],VRFQP.[IsActive],VRFQP.[IsDeleted],NULL,VRFQP.[PromisedDate],VRFQP.VendorRFQPOPartRecordId,
		 VRFQP.[TraceableTo], VRFQP.[TraceableToName], VRFQP.[TraceableToType], VRFQP.[TagTypeId], VRFQP.[TaggedByType], VRFQP.[TaggedBy], VRFQP.[TaggedByName], VRFQP.[TaggedByTypeName], VRFQP.[TagDate]
                            FROM dbo.VendorRFQPurchaseOrderPart VRFQP WITH(NOLOCK) WHERE VRFQP.[VendorRFQPurchaseOrderId]=@VendorRFQPurchaseOrderId;  
							

    
     UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;    
        
        UPDATE dbo.VendorRFQPurchaseOrder SET StatusId=3,[Status] = 'Closed' WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;     
    
     UPDATE dbo.VendorRFQPurchaseOrderPart SET [PurchaseOrderId] = IDENT_CURRENT('PurchaseOrder'),[PurchaseOrderNumber] = @PurchaseOrderNumber     
                WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId; 
				

	 INSERT INTO [dbo].[PurchaseOrderPartReference]([PurchaseOrderId],[PurchaseOrderPartId],[ModuleId],[ReferenceId],[Qty],[RequestedQty],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
	 SELECT PART.PurchaseOrderId,PART.PurchaseOrderPartRecordId,VRFQ.ModuleId,VRFQ.ReferenceId,VRFQ.Qty,VRFQ.RequestedQty,VRFQ.MasterCompanyId,VRFQ.CreatedBy,VRFQ.UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0
	 FROM DBO.VendorRFQPurchaseOrderPartReference VRFQ INNER JOIN dbo.[PurchaseOrderPart] PART ON VRFQ.VendorRFQPOPartRecordId = PART.VendorRFQPOPartRecordId 
		WHERE VRFQ.[VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId
		
         
     IF OBJECT_ID(N'tempdb..#tblPurchaseOrderPart') IS NOT NULL    
     BEGIN    
     DROP TABLE #tblPurchaseOrderPart     
     END    
     CREATE TABLE #tblPurchaseOrderPart    
     (    
      ID BIGINT NOT NULL IDENTITY,     
      VendorRFQPOPartRecordId BIGINT NULL,    
      VendorRFQPurchaseOrderId BIGINT NULL,    
      ManagementStructureId BIGINT NULL,    
      MasterCompanyId INT NULL,    
      CreatedBy VARCHAR(256) NULL,    
      UpdatedBy VARCHAR(256) NULL,    
     )    
    
     INSERT INTO #tblPurchaseOrderPart(VendorRFQPOPartRecordId, VendorRFQPurchaseOrderId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy)    
     SELECT PurchaseOrderPartRecordId,PurchaseOrderId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy FROM PurchaseOrderPart     
     WITH(NOLOCK) WHERE PurchaseOrderId = @PID;    
    
     --DECLARE @id int;    
     SELECT @ID =1;    
     WHILE @ID <= (SELECT MAX(ID) FROM #tblPurchaseOrderPart)         
     BEGIN    
      --DECLARE @MSCID INT=0;    
      --DECLARE @MSSID BIGINT=0;    
      --DECLARE @CreatBy VARCHAR(100)='';    
      --DECLARE @UpdatBy VARCHAR(100)='';    
      --DECLARE @POPID BIGINT=0;    
      --SET @PID = IDENT_CURRENT('PurchaseOrder');    
      SELECT @POPID=[VendorRFQPOPartRecordId],@MSSID=[ManagementStructureId],@MSCID=[MasterCompanyId],    
         @CreatBy=[CreatedBy],@UpdatBy=[UpdatedBy]    
        FROM #tblPurchaseOrderPart WITH(NOLOCK) WHERE ID=@ID;    
            
      EXEC [DBO].[PROCAddPOMSData] @POPID,@MSSID,@MSCID,@CreatBy,@UpdatBy,5,3,0    
     --increment the step variable so that the condition will eventually be false    
     SET @ID = @ID + 1    
     END    
    
     IF EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31)    
           BEGIN    
                 INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
           [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
           [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
           [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
          SELECT IDENT_CURRENT('PurchaseOrder'),13,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
           [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
           [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
           [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]    
         FROM [dbo].[AllAddress] WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31;    
    
     INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
           [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,    
           [IsActive] ,[IsDeleted])    
         SELECT IDENT_CURRENT('PurchaseOrder'),13,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
          [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE() ,    
          1,0     
        FROM [dbo].[AllShipVia] WHERE [ReferenceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31;    
     END     
         

     SELECT @Result = IDENT_CURRENT('PurchaseOrder');             
    END    
    ELSE    
    BEGIN         
     SELECT @Result = -1;    
    END    
   END    
  ELSE    
  BEGIN       
   SELECT @Result = -2;    
  END    
  END    
  IF(@Opr = 2)    
  BEGIN    
   IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrder WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId)    
   BEGIN    
    SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM dbo.CodePrefixes WITH(NOLOCK)    
      WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;    
    
    SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM dbo.PurchaseOrderSettingMaster WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;    
         
    IF(@CurrentNummber!='' OR @CurrentNummber!=NULL)    
    BEGIN    
     SET @PurchaseOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));    
    
     INSERT INTO [dbo].[PurchaseOrder]([PurchaseOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
                [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],[RequestedBy],    
          [Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],[ApproverId],[ApprovedBy],    
          [DateApproved],[POMemo],[Notes],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
          [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsEnforce],[PDFPath],[VendorRFQPurchaseOrderId])    
           SELECT @PurchaseOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],    
               [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],[RequestedBy],    
         [Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],NULL,NULL,    
         NULL,[Memo],[Notes],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],    
         [CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,0,@IsEnforceApproval,NULL,@VendorRFQPurchaseOrderId    
        FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId=@VendorRFQPurchaseOrderId;    
              
     SET @PID=IDENT_CURRENT('PurchaseOrder');   
	 
     SELECT @MSID=[ManagementStructureId],@MCID=[MasterCompanyId],    
         @CreateBy=[CreatedBy],@UpdateBy=[UpdatedBy]    
        FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId=@VendorRFQPurchaseOrderId;    
            
     EXEC [DBO].[PROCAddPOMSData] @PID,@MSID,@MCID,@CreateBy,@UpdateBy,4,1,0    
    
     INSERT INTO [dbo].[PurchaseOrderPart]([PurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[AltEquiPartNumberId],[AltEquiPartNumber],    
         [AltEquiPartDescription],[StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[ConditionId],    
         [Condition],[QuantityOrdered],[QuantityBackOrdered],[QuantityRejected],[VendorListPrice],[DiscountPercent],[DiscountPerUnit],    
         [DiscountAmount],[UnitCost],[ExtendedCost],    
         [FunctionalCurrencyId],[FunctionalCurrency],[ForeignExchangeRate],    
         [ReportCurrencyId],[ReportCurrency],    
         [WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[RepairOrderId],[ReapairOrderNo],[SalesOrderId],[SalesOrderNo],    
         [ItemTypeId],[ItemType],    
         [GlAccountId],[GLAccount],    
         [UOMId],[UnitOfMeasure],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[ParentId],[isParent],[Memo],    
         [POPartSplitUserTypeId],[POPartSplitUserType],[POPartSplitUserId],[POPartSplitUser],[POPartSplitSiteId],[POPartSplitSiteName],    
         [POPartSplitAddressId],[POPartSplitAddress1],[POPartSplitAddress2],[POPartSplitAddress3],[POPartSplitCity],[POPartSplitState],    
         [POPartSplitPostalCode],[POPartSplitCountryId],[POPartSplitCountryName],[MasterCompanyId],[CreatedBy],[UpdatedBy],    
         [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[DiscountPercentValue],[EstDeliveryDate],[VendorRFQPOPartRecordId],
		 [TraceableTo],[TraceableToName],[TraceableToType],[TagTypeId],[TaggedByType],[TaggedBy],[TaggedByName],[TaggedByTypeName],[TagDate])    
        SELECT IDENT_CURRENT('PurchaseOrder'),VRFQP.[ItemMasterId],VRFQP.[PartNumber],VRFQP.[PartDescription],NULL,NULL,    
         NULL,VRFQP.[StockType],VRFQP.[ManufacturerId],VRFQP.[Manufacturer],VRFQP.[PriorityId],VRFQP.[Priority],VRFQP.[NeedByDate],VRFQP.[ConditionId],    
         VRFQP.[Condition],VRFQP.[QuantityOrdered],VRFQP.[QuantityOrdered],0,    
         CASE WHEN (SELECT ISNULL(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]) > 0 THEN     
         (SELECT ISNULL(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]) ELSE 0     
         END,    
        --(SELECT TOP 1 COALESCE(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]),    
         0,0,    
         0,VRFQP.[UnitCost],VRFQP.[ExtendedCost],    
        -- (SELECT TOP 1 L.FunctionalCurrencyId FROM dbo.ManagementStructure M WITH(NOLOCK) INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        --(SELECT TOP 1 FC.Code FROM dbo.ManagementStructure M WITH(NOLOCK)     
        --   INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        --   INNER JOIN dbo.Currency FC WITH(NOLOCK) ON L.FunctionalCurrencyId = FC.CurrencyId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),1,    
        --(SELECT TOP 1 L.ReportingCurrencyId FROM dbo.ManagementStructure M WITH(NOLOCK) INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        --(SELECT TOP 1 RC.Code FROM dbo.ManagementStructure M WITH(NOLOCK)     
        --   INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        --   INNER JOIN dbo.Currency RC WITH(NOLOCK) ON L.ReportingCurrencyId = RC.CurrencyId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        (SELECT TOP 1 FC.CurrencyId FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         (SELECT TOP 1 FC.Code FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),1,    
         (SELECT TOP 1 RC.CurrencyId FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         (SELECT TOP 1 RC.Code FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         VRFQP.[WorkOrderId],VRFQP.[WorkOrderNo],VRFQP.[SubWorkOrderId],VRFQP.[SubWorkOrderNo],NULL,NULL,VRFQP.[SalesOrderId],VRFQP.[SalesOrderNo],    
         1,'Stock',    
         (SELECT TOP 1 I.GLAccountId FROM dbo.ItemMaster I WITH(NOLOCK) WHERE I.ItemMasterId = VRFQP.[ItemMasterId]),NULL,    
         VRFQP.[UOMId],VRFQP.[UnitOfMeasure],VRFQP.[ManagementStructureId],VRFQP.[Level1],VRFQP.[Level2],VRFQP.[Level3],VRFQP.[Level4],NULL,1,VRFQP.[Memo],    
         NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,    
         VRFQP.[MasterCompanyId],VRFQP.[CreatedBy],VRFQP.[UpdatedBy],    
         VRFQP.[CreatedDate],VRFQP.[UpdatedDate],VRFQP.[IsActive],VRFQP.[IsDeleted],NULL,VRFQP.[PromisedDate],VRFQP.VendorRFQPOPartRecordId,
		 VRFQP.[TraceableTo], VRFQP.[TraceableToName], VRFQP.[TraceableToType], VRFQP.[TagTypeId], VRFQP.[TaggedByType], VRFQP.[TaggedBy], VRFQP.[TaggedByName], VRFQP.[TaggedByTypeName], VRFQP.[TagDate]
                            FROM dbo.VendorRFQPurchaseOrderPart VRFQP WITH(NOLOCK) WHERE VRFQP.[VendorRFQPOPartRecordId] = @VendorRFQPOPartRecordId;     
    
     UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;             
    
     UPDATE dbo.VendorRFQPurchaseOrderPart SET [PurchaseOrderId] = IDENT_CURRENT('PurchaseOrder'),[PurchaseOrderNumber] = @PurchaseOrderNumber     
                WHERE [VendorRFQPOPartRecordId] = @VendorRFQPOPartRecordId;     
         
     IF EXISTS (SELECT * FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND [PurchaseOrderId] IS NULL)    
     BEGIN    
        UPDATE dbo.VendorRFQPurchaseOrder SET StatusId=2,[Status] = 'Pending' WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;     
     END    
     ELSE    
     BEGIN    
        UPDATE dbo.VendorRFQPurchaseOrder SET StatusId=3,[Status] = 'Closed' WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;     
     END    

	 INSERT INTO [dbo].[PurchaseOrderPartReference]([PurchaseOrderId],[PurchaseOrderPartId],[ModuleId],[ReferenceId],[Qty],[RequestedQty],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
	 SELECT PART.PurchaseOrderId,PART.PurchaseOrderPartRecordId,VRFQ.ModuleId,VRFQ.ReferenceId,VRFQ.Qty,VRFQ.RequestedQty,VRFQ.MasterCompanyId,VRFQ.CreatedBy,VRFQ.UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0
	 FROM DBO.VendorRFQPurchaseOrderPartReference VRFQ INNER JOIN dbo.[PurchaseOrderPart] PART ON VRFQ.VendorRFQPOPartRecordId = PART.VendorRFQPOPartRecordId 
		WHERE VRFQ.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId
			       
     IF OBJECT_ID(N'tempdb..#tblPurchaseOrderPartSingle') IS NOT NULL    
     BEGIN    
		 DROP TABLE #tblPurchaseOrderPartSingle     
     END    
     CREATE TABLE #tblPurchaseOrderPartSingle    
     (    
      ID BIGINT NOT NULL IDENTITY,     
      VendorRFQPOPartRecordId BIGINT NULL,    
      VendorRFQPurchaseOrderId BIGINT NULL,    
      ManagementStructureId BIGINT NULL,    
      MasterCompanyId INT NULL,    
      CreatedBy VARCHAR(256) NULL,    
      UpdatedBy VARCHAR(256) NULL,    
     )    
    
     INSERT INTO #tblPurchaseOrderPartSingle(VendorRFQPOPartRecordId, VendorRFQPurchaseOrderId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy)    
     SELECT PurchaseOrderPartRecordId,PurchaseOrderId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy FROM PurchaseOrderPart     
     WITH(NOLOCK) WHERE PurchaseOrderPartRecordId = IDENT_CURRENT('PurchaseOrderPart');    
    
         
     SELECT @ID =1;    
     WHILE @ID <= (SELECT MAX(ID) FROM #tblPurchaseOrderPartSingle)         
     BEGIN    
      SELECT @POPID=[VendorRFQPOPartRecordId],@MSSID=[ManagementStructureId],@MSCID=[MasterCompanyId],    
         @CreatBy=[CreatedBy],@UpdatBy=[UpdatedBy]    
        FROM #tblPurchaseOrderPartSingle WITH(NOLOCK) WHERE ID=@ID;    
            
      EXEC [DBO].[PROCAddPOMSData] @POPID,@MSSID,@MSCID,@CreatBy,@UpdatBy,5,3,0    
     --increment the step variable so that the condition will eventually be false    
     SET @ID = @ID + 1    
     END    
	 	     
     IF EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31)    
     BEGIN    
                 INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
           [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
           [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
           [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
          SELECT IDENT_CURRENT('PurchaseOrder'),13,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
           [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
           [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
           [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]    
         FROM [dbo].[AllAddress] where [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31;    
    
     INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
           [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,    
           [IsActive] ,[IsDeleted])    
         SELECT IDENT_CURRENT('PurchaseOrder'),13,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
          [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE(),    
          1,0     
        FROM [dbo].[AllShipVia] WHERE [ReferenceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31;    
     END    
    
     SELECT @Result = IDENT_CURRENT('PurchaseOrder');            
    END    
    ELSE    
    BEGIN         
     SELECT @Result = -1;    
    END    
   END    
   ELSE    
   BEGIN  
   

    SELECT TOP 1 @PurchaseOrderId = [PurchaseOrderId],    
              @PONumber = [PurchaseOrderNumber] FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND [PurchaseOrderId] > 0;    
    
    INSERT INTO [dbo].[PurchaseOrderPart]([PurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[AltEquiPartNumberId],[AltEquiPartNumber],    
         [AltEquiPartDescription],[StockType],[ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[ConditionId],    
         [Condition],[QuantityOrdered],[QuantityBackOrdered],[QuantityRejected],[VendorListPrice],[DiscountPercent],[DiscountPerUnit],    
         [DiscountAmount],[UnitCost],[ExtendedCost],    
         [FunctionalCurrencyId],[FunctionalCurrency],[ForeignExchangeRate],    
         [ReportCurrencyId],[ReportCurrency],    
         [WorkOrderId],[WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[RepairOrderId],[ReapairOrderNo],[SalesOrderId],[SalesOrderNo],    
         [ItemTypeId],[ItemType],    
         [GlAccountId],[GLAccount],    
         [UOMId],[UnitOfMeasure],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[ParentId],[isParent],[Memo],    
         [POPartSplitUserTypeId],[POPartSplitUserType],[POPartSplitUserId],[POPartSplitUser],[POPartSplitSiteId],[POPartSplitSiteName],    
         [POPartSplitAddressId],[POPartSplitAddress1],[POPartSplitAddress2],[POPartSplitAddress3],[POPartSplitCity],[POPartSplitState],    
         [POPartSplitPostalCode],[POPartSplitCountryId],[POPartSplitCountryName],[MasterCompanyId],[CreatedBy],[UpdatedBy],    
         [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[DiscountPercentValue],[EstDeliveryDate],[VendorRFQPOPartRecordId],
		 [TraceableTo],[TraceableToName],[TraceableToType],[TagTypeId],[TaggedByType],[TaggedBy],[TaggedByName],[TaggedByTypeName],[TagDate])    
        SELECT @PurchaseOrderId,VRFQP.[ItemMasterId],VRFQP.[PartNumber],VRFQP.[PartDescription],NULL,NULL,    
         NULL,VRFQP.[StockType],VRFQP.[ManufacturerId],VRFQP.[Manufacturer],VRFQP.[PriorityId],VRFQP.[Priority],VRFQP.[NeedByDate],VRFQP.[ConditionId],    
         VRFQP.[Condition],VRFQP.[QuantityOrdered],VRFQP.[QuantityOrdered],0,    
         CASE WHEN (SELECT ISNULL(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]) > 0 THEN     
         (SELECT ISNULL(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]) ELSE 0     
         END,    
         --(SELECT TOP 1 COALESCE(IMP.PP_VendorListPrice,0) FROM dbo.ItemMasterPurchaseSale IMP WITH(NOLOCK) WHERE IMP.ItemMasterId = VRFQP.[ItemMasterId] AND IMP.ConditionId = VRFQP.[ConditionId]),    
         0,0,    
         0,VRFQP.[UnitCost],VRFQP.[ExtendedCost],    
        -- (SELECT TOP 1 L.FunctionalCurrencyId FROM dbo.ManagementStructure M WITH(NOLOCK) INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        --(SELECT TOP 1 FC.Code FROM dbo.ManagementStructure M WITH(NOLOCK)     
        --   INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        --   INNER JOIN dbo.Currency FC WITH(NOLOCK) ON L.FunctionalCurrencyId = FC.CurrencyId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),1,          --(SELECT TOP 1 L.ReportingCurrencyId FROM dbo.ManagementStructure M WITH(NOLOCK) INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        --(SELECT TOP 1 RC.Code FROM dbo.ManagementStructure M WITH(NOLOCK)     
        --   INNER JOIN dbo.LegalEntity L WITH(NOLOCK) ON M.LegalEntityId = L.LegalEntityId    
        --   INNER JOIN dbo.Currency RC WITH(NOLOCK) ON L.ReportingCurrencyId = RC.CurrencyId    
        -- WHERE M.ManagementStructureId = VRFQP.[ManagementStructureId]),    
        (SELECT TOP 1 FC.CurrencyId FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         (SELECT TOP 1 FC.Code FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),1,    
         (SELECT TOP 1 RC.CurrencyId FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         (SELECT TOP 1 RC.Code FROM dbo.EntityStructureSetup EST WITH(NOLOCK)    
         INNER JOIN dbo.ManagementStructureLevel MSL ON EST.Level1Id = MSL.ID    
         INNER JOIN dbo.LegalEntity LE ON LE.LegalEntityId = MSL.LegalEntityId    
         INNER JOIN dbo.Currency FC ON FC.CurrencyId = LE.FunctionalCurrencyId    
         INNER JOIN dbo.Currency RC ON RC.CurrencyId = LE.ReportingCurrencyId    
         WHERE EST.EntityStructureId = VRFQP.[ManagementStructureId]),    
         VRFQP.[WorkOrderId],VRFQP.[WorkOrderNo],VRFQP.[SubWorkOrderId],VRFQP.[SubWorkOrderNo],NULL,NULL,VRFQP.[SalesOrderId],VRFQP.[SalesOrderNo],    
         1,'Stock',    
         (SELECT TOP 1 I.GLAccountId FROM dbo.ItemMaster I WITH(NOLOCK) WHERE I.ItemMasterId = VRFQP.[ItemMasterId]),NULL,    
         VRFQP.[UOMId],VRFQP.[UnitOfMeasure],VRFQP.[ManagementStructureId],VRFQP.[Level1],VRFQP.[Level2],VRFQP.[Level3],VRFQP.[Level4],NULL,1,VRFQP.[Memo],    
         NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,    
         VRFQP.[MasterCompanyId],VRFQP.[CreatedBy],VRFQP.[UpdatedBy],    
         VRFQP.[CreatedDate],VRFQP.[UpdatedDate],VRFQP.[IsActive],VRFQP.[IsDeleted],NULL,VRFQP.[PromisedDate],VRFQP.[VendorRFQPOPartRecordId],
		 VRFQP.[TraceableTo], VRFQP.[TraceableToName], VRFQP.[TraceableToType], VRFQP.[TagTypeId], VRFQP.[TaggedByType], VRFQP.[TaggedBy], VRFQP.[TaggedByName], VRFQP.[TaggedByTypeName], VRFQP.[TagDate]
                            FROM dbo.VendorRFQPurchaseOrderPart VRFQP WITH(NOLOCK) WHERE VRFQP.[VendorRFQPOPartRecordId] = @VendorRFQPOPartRecordId;     
    
    UPDATE dbo.VendorRFQPurchaseOrderPart SET [PurchaseOrderId] = @PurchaseOrderId,[PurchaseOrderNumber] = @PONumber     
                WHERE [VendorRFQPOPartRecordId] = @VendorRFQPOPartRecordId;     
    
    IF EXISTS (SELECT * FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND [PurchaseOrderId] IS NULL)    
    BEGIN    
       UPDATE dbo.VendorRFQPurchaseOrder SET StatusId=2,[Status] = 'Pending' WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;     
    END    
    ELSE    
    BEGIN    
       UPDATE dbo.VendorRFQPurchaseOrder SET StatusId=3,[Status] = 'Closed' WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;     
    END    

	INSERT INTO [dbo].[PurchaseOrderPartReference]([PurchaseOrderId],[PurchaseOrderPartId],[ModuleId],[ReferenceId],[Qty],[RequestedQty],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
	 SELECT PART.PurchaseOrderId,PART.PurchaseOrderPartRecordId,VRFQ.ModuleId,VRFQ.ReferenceId,VRFQ.Qty,VRFQ.RequestedQty,VRFQ.MasterCompanyId,VRFQ.CreatedBy,VRFQ.UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0
	 FROM DBO.VendorRFQPurchaseOrderPartReference VRFQ INNER JOIN dbo.[PurchaseOrderPart] PART ON VRFQ.VendorRFQPOPartRecordId = PART.VendorRFQPOPartRecordId 
		WHERE VRFQ.VendorRFQPOPartRecordId = @VendorRFQPOPartRecordId
        
     IF OBJECT_ID(N'tempdb..#tblPurchaseOrderPartSingleRecord') IS NOT NULL    
     BEGIN    
		DROP TABLE #tblPurchaseOrderPartSingleRecord     
     END  
	 
     CREATE TABLE #tblPurchaseOrderPartSingleRecord    
     (    
      ID BIGINT NOT NULL IDENTITY,     
      VendorRFQPOPartRecordId BIGINT NULL,    
      VendorRFQPurchaseOrderId BIGINT NULL,    
      ManagementStructureId BIGINT NULL,    
      MasterCompanyId INT NULL,    
      CreatedBy VARCHAR(256) NULL,    
      UpdatedBy VARCHAR(256) NULL,    
     )    
    
     INSERT INTO #tblPurchaseOrderPartSingleRecord(VendorRFQPOPartRecordId, VendorRFQPurchaseOrderId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy)    
     SELECT PurchaseOrderPartRecordId,PurchaseOrderId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy FROM PurchaseOrderPart     
     WITH(NOLOCK) WHERE PurchaseOrderPartRecordId = IDENT_CURRENT('PurchaseOrderPart');    
             
     SELECT @ID =1;    
     WHILE @ID <= (SELECT MAX(ID) FROM #tblPurchaseOrderPartSingleRecord)         
     BEGIN    
      SELECT @POPID=[VendorRFQPOPartRecordId],@MSSID=[ManagementStructureId],@MSCID=[MasterCompanyId],    
         @CreatBy=[CreatedBy],@UpdatBy=[UpdatedBy]    
        FROM #tblPurchaseOrderPartSingleRecord WITH(NOLOCK) WHERE ID=@ID;    
            
      EXEC [DBO].[PROCAddPOMSData] @POPID,@MSSID,@MSCID,@CreatBy,@UpdatBy,5,3,0    
     --increment the step variable so that the condition will eventually be false    
     SET @ID = @ID + 1    

     END    
	 	 	           
    IF EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31)    
       BEGIN    
     IF NOT EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @PurchaseOrderId AND ModuleId = 13)    
     BEGIN    
        INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
           [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
           [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
           [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
          SELECT @PurchaseOrderId,13,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
           [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
           [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],    
           [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]    
         FROM [dbo].[AllAddress] where [ReffranceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31;    
     END    
       END    
    
    IF EXISTS (SELECT 1 FROM dbo.AllShipVia WITH(NOLOCK) WHERE [ReferenceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31)    
       BEGIN    
     IF NOT EXISTS (SELECT 1 FROM dbo.AllShipVia WITH(NOLOCK) WHERE [ReferenceId] = @PurchaseOrderId AND ModuleId = 13)    
     BEGIN    
      INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
           [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,    
           [IsActive] ,[IsDeleted])    
         SELECT @PurchaseOrderId,13,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
          [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE(),    
          1,0     
        FROM [dbo].[AllShipVia] WHERE [ReferenceId] = @VendorRFQPurchaseOrderId AND ModuleId = 31;    
    
     END    
    END        
    SELECT @Result = @PurchaseOrderId;    
   END    
  END    
 END    
 COMMIT  TRANSACTION    
 END TRY     
 BEGIN CATCH          
  IF @@trancount > 0    
  PRINT 'ROLLBACK'    
    ROLLBACK TRANSACTION;    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'PROCConvertVendorRFQPOToPurchaseOrder'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQPurchaseOrderId, '') AS varchar(100))    
             + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))     
             + '@Parameter3 = ''' + CAST(ISNULL(@CodeTypeId, '') AS varchar(100))      
              , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
              exec spLogException     
                       @DatabaseName           = @DatabaseName    
                     , @AdhocComments          = @AdhocComments    
                     , @ProcedureParameters    = @ProcedureParameters    
                     , @ApplicationName        =  @ApplicationName    
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
              RETURN(1);    
 END CATCH    
END 