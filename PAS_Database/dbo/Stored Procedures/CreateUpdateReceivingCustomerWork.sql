/*************************************************************           
 ** File:   [CreateUpdateReceivingCustomerWork]        
 ** Author:   Abhishek Jirawla
 ** Description: Get work order parts view
 ** Purpose:         
 ** Date:   08-APR-2025  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    08-APR-2025   Abhishek Jirawla		Created
	2	 24-APR-2025   Devendra Shekh		Modify (Added [IsManualText] check for DistributionSetup)
	3	 30-APR-2025   ABHISHEK JIRAWLA		Adding IsPiecePart and IsRepairManagement to the Stockline
    4	 15-MAY-2025   AYUSHI PATEL 		Inserted CustReq Date into table by removing UTCDATE 
	5	 16-JUL-2025   Moin Bloch   		Added IsBatchStock,BatchNumber Flag for Stockline Batch 
	6	 20-JAN-2026   Priyansh Patel  		Added CSN, TSN, CSO, TSO fields
	7	 13-FEB-2026   BHARGAV SALIYA  		Added [CustReqCertTypeId], [CustReqCertType] fields

 EXECUTE [USP_GetWorkOrderPartsView] 1
**************************************************************/ 
CREATE    PROCEDURE [dbo].[CreateUpdateReceivingCustomerWork]  
@ReceivingCustomerWorkId [bigint] NULL,
@MasterCompanyId [int] NULL,
@IsRepairManagement [bit] NULL,
@tbl_ReceivingCustomerWorkType ReceivingCustomerWorkType READONLY      
AS    
BEGIN    
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

  BEGIN TRY    
  BEGIN TRANSACTION    
  BEGIN       
	   DECLARE @CurrentStockLineNumber AS BIGINT;    
	   DECLARE @TotalRecord int = 0;   
	   DECLARE @MinId BIGINT = 1; 
	   DECLARE @CurrentIndex BIGINT, @RCCurrentIndex BIGINT, @CSBCurrentIndex BIGINT
	   DECLARE @StockIdCodeTypeId INT = 0; 
	   DECLARE @IdNumberCodeTypeId INT = 0; 
	   DECLARE @ControlNumberCodeTypeId INT = 0; 
	   DECLARE @IDNumber VARCHAR(50)='',@RCReceiverNumber AS VARCHAR(50)='',@CSBReceiverNumber AS VARCHAR(50)=''
	   DECLARE @ItemtypeId INT = 2; 
	   DECLARE @RCId BIGINT = 0; 
	   DECLARE @ReceivingCustomerModuleId INT = 27
	   DECLARE @NHAMappingType INT = 3;
	   DECLARE @TLAMappingType INT = 4;
	   
	  SELECT @ReceivingCustomerModuleId = [ModuleId] FROM dbo.Module WITH (NOLOCK) WHERE [ModuleName] = 'ReceivingCustomerWork';
	  SELECT @StockIdCodeTypeId = CodeTypeId FROM dbo.CodeTypes WITH (NOLOCK) WHERE CodeType = 'Stock Line';
	  SELECT @IdNumberCodeTypeId = CodeTypeId FROM dbo.CodeTypes WITH (NOLOCK) WHERE CodeType = 'Id Number';
	  SELECT @ControlNumberCodeTypeId = CodeTypeId FROM dbo.CodeTypes WITH (NOLOCK) WHERE CodeType = 'Control Number';
   
       IF OBJECT_ID(N'tempdb..#tmprReceiveCustomer') IS NOT NULL
       BEGIN
			DROP TABLE #tmprReceiveCustomer
	   END
	   			
		CREATE TABLE #tmprReceiveCustomer
		    (
				[ID] BIGINT NOT NULL IDENTITY,
				[ReceivingCustomerWorkId] [bigint] NULL,
				[EmployeeId] [bigint] NULL,
				[CustomerId] [bigint] NULL,
				[ReceivingNumber] [varchar](50) NULL,
				[CustomerContactId] [bigint] NULL,
				[ItemMasterId] [bigint] NULL,				
				[ManufacturerId] [bigint] NULL,
				[RevisePartId] [bigint] NULL,
				[IsSerialized] [bit] NULL,
				[SerialNumber] [varchar](100) NULL,
				[Quantity] [int] NULL,
				[UnitCost] [decimal](18,2) NULL,
				[ExtendedCost] [decimal](18,2) NULL,
				[ConditionId] [bigint] NULL,
				[SiteId] [bigint] NULL,
				[WarehouseId] [bigint] NULL,
				[LocationId] [bigint] NULL,
				[ShelfId] [bigint] NULL,
				[BinId] [bigint] NULL,
				[OwnerTypeId] [int] NULL,
				[Owner] [bigint] NULL,
				[IsCustomerStock] [bit] NULL,
				[TraceableToTypeId] [int] NULL,
				[TraceableTo] [bigint] NULL,
				[ObtainFromTypeId] [int] NULL,
				[ObtainFrom] [bigint] NULL,
				[IsMFGDate] [bit] NULL,
				[MFGDate] [datetime2](7) NULL,
				[MFGTrace] [varchar](100) NULL,
				[MFGLotNo] [varchar](100) NULL,
				[MFGBatchNo] [varchar](100) NULL,
				[IsExpDate] [bit] NULL,
				[ExpDate] [datetime2](7) NULL,
				[IsTimeLife] [bit] NULL,
				[TagDate] [datetime2](7) NULL,
				[TagType] [varchar](8000) NULL,
				[TagTypeId] [bigint] NULL,
				[TimeLifeDate] [datetime2](7) NULL,
				[TimeLifeOrigin] [varchar](MAX) NULL,
				[TimeLifeCyclesId] [bigint] NULL,
				[Memo] [nvarchar](MAX) NULL,
				[PartCertificationNumber] [varchar](30) NULL,
				[ManagementStructureId] [bigint] NULL,
				[GLAccountId] [bigint] NULL,
				[StockLineId] [bigint] NULL,
				[WorkOrderId] [bigint] NULL,
				[MasterCompanyId] [int] NULL,
				[CreatedBy] [varchar](256) NULL,
				[UpdatedBy] [varchar](256) NULL,
				[CreatedDate] [datetime2](7) NULL,
				[UpdatedDate] [datetime2](7) NULL,
				[IsActive] [bit] NULL,
				[IsDeleted] [bit] NULL,
				[IsSkipSerialNo] [bit] NULL,
				[IsSkipTimeLife] [bit] NULL,
				[Reference] [varchar](256) NULL,
				[CertifiedBy] [varchar](256) NULL,
				[ReceivedDate] [datetime2](7) NULL,
				[CustReqDate] [datetime2](7) NULL,
				[Level1] [varchar](200) NULL,
				[Level2] [varchar](200) NULL,
				[Level3] [varchar](200) NULL,
				[Level4] [varchar](200) NULL,
				[EmployeeName] [varchar](256) NULL,
				[CustomerName] [varchar](256) NULL,
				[WorkScopeId] [bigint] NULL,
				[CustomerCode] [varchar](100) NULL,
				[ManufacturerName] [varchar](100) NULL,
				[InspectedById] [bigint] NULL,
				[CertifiedDate] [datetime2](7) NULL,
				[ObtainFromName] [varchar](256) NULL,
				[OwnerName] [varchar](256) NULL,
				[TraceableToName] [varchar](256) NULL,
				[PartNumber] [varchar](250) NULL,
				[WorkScope] [varchar](250) NULL,
				[Condition] [varchar](100) NULL,
				[Site] [varchar](250) NULL,
				[Warehouse] [varchar](250) NULL,
				[Location] [varchar](250) NULL,
				[Shelf] [varchar](250) NULL,
				[Bin] [varchar](250) NULL,
				[InspectedBy] [varchar](100) NULL,
				[InspectedDate] [datetime] NULL,
				[TaggedById] [bigint] NULL,
				[TaggedByName] [varchar](100) NULL,
				[ACTailNum] [nvarchar](500) NULL,
				[TaggedByType] [int] NULL,
				[TaggedByTypeName] [varchar](250) NULL,
				[CertifiedById] [bigint] NULL,
				[CertifiedTypeId] [int] NULL,
				[CertifiedType] [varchar](250) NULL,
				[CertTypeId] [varchar](MAX) NULL,
				[CertType] [varchar](MAX) NULL,
				[RemovalReasonId] [bigint] NULL,
				[RemovalReasons] [varchar](200) NULL,
				[RemovalReasonsMemo] [nvarchar](MAX) NULL,
				[ExchangeSalesOrderId] [bigint] NULL,
				[CustReqTagTypeId] [bigint] NULL,
				[CustReqTagType] [varchar](100) NULL,
				[CustReqCertTypeId] [varchar](MAX) NULL,
				[CustReqCertType] [varchar](MAX) NULL,
				[RepairOrderPartRecordId] [bigint] NULL,
				[IsExchangeBatchEntry] [bit] NULL,
				[ShippingViaId] [bigint] NULL,
				[EngineSerialNumber] [varchar](200) NULL,
				[ShippingAccount] [varchar](200) NULL,
				[ShippingReference] [varchar](200) NULL,
				[TimeLifeDetailsNotProvided] [bit] NULL,
				[PurchaseUnitOfMeasureId] [bigint] NULL,
				[GlAccountName] [varchar](200) NULL,
				[CyclesRemaining] [varchar](20) NULL,	
				[CyclesSinceNew] [varchar](20) NULL,	
				[CyclesSinceOVH] [varchar](20) NULL,	
				[CyclesSinceInspection] [varchar](20) NULL,	
				[CyclesSinceRepair] [varchar](20) NULL,	
				[TimeRemaining] [varchar](20) NULL,	
				[TimeSinceNew] [varchar](20) NULL,	
				[TimeSinceOVH] [varchar](20) NULL,	
				[TimeSinceInspection] [varchar](20) NULL,	
				[TimeSinceRepair] [varchar](20) NULL,	
				[LastSinceNew] [varchar](20) NULL,	
				[LastSinceOVH] [varchar](20) NULL,	
				[LastSinceInspection] [varchar](20) NULL,
				[IsSkipShippingReference] [bit] NULL,
				[IsBatchStock] [bit] NULL,
				[BatchNumber] [varchar](50) NULL,
				[CSN] [varchar](50) NULL,
				[TSN] [varchar](50) NULL,
				[CSO] [varchar](50) NULL,
				[TSO] [varchar](50) NULL
			)
				
		INSERT INTO #tmprReceiveCustomer ([ReceivingCustomerWorkId],[EmployeeId],[CustomerId],[ReceivingNumber],[CustomerContactId],
						[ItemMasterId],[ManufacturerId],[RevisePartId], [IsSerialized],[SerialNumber],[Quantity],[UnitCost],[ExtendedCost],[ConditionId],[SiteId],[WarehouseId],[LocationId],[ShelfId],[BinId],[OwnerTypeId],
						[Owner],[IsCustomerStock],[TraceableToTypeId],[TraceableTo],[ObtainFromTypeId],[ObtainFrom],[IsMFGDate],[MFGDate],[MFGTrace],[MFGLotNo],[MFGBatchNo],[IsExpDate],
						[ExpDate],[IsTimeLife],[TagDate],[TagType],[TagTypeId],[TimeLifeDate],[TimeLifeOrigin],[TimeLifeCyclesId],[Memo],[PartCertificationNumber],[ManagementStructureId],[GLAccountId],
						[StockLineId],[WorkOrderId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsSkipSerialNo],[IsSkipTimeLife],
						[Reference],[CertifiedBy],[ReceivedDate],[CustReqDate],[Level1],[Level2],[Level3],[Level4],[EmployeeName],[CustomerName],[WorkScopeId],	[CustomerCode],
				        [ManufacturerName],[InspectedById],[CertifiedDate],[ObtainFromName],[OwnerName],[TraceableToName],[PartNumber],[WorkScope],[Condition],
				        [Site],[Warehouse],[Location],[Shelf],[Bin],[InspectedBy],[InspectedDate],[TaggedById],[TaggedByName],[ACTailNum],[TaggedByType],[TaggedByTypeName],
						[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[RemovalReasonId],[RemovalReasons],[RemovalReasonsMemo],[ExchangeSalesOrderId],
				        [CustReqTagTypeId],[CustReqTagType],[CustReqCertTypeId],[CustReqCertType],[RepairOrderPartRecordId],[IsExchangeBatchEntry],[ShippingViaId],[EngineSerialNumber],[ShippingAccount],
						[ShippingReference],[TimeLifeDetailsNotProvided],[PurchaseUnitOfMeasureId],[GlAccountName],[CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],
                        [CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[IsSkipShippingReference],[IsBatchStock],[BatchNumber],
						[CSN],[TSN],[CSO],[TSO] )
			     SELECT [ReceivingCustomerWorkId],[EmployeeId],[CustomerId],[ReceivingNumber],[CustomerContactId],
						[ItemMasterId],[ManufacturerId],[RevisePartId],[IsSerialized],[SerialNumber],[Quantity],[UnitCost],[ExtendedCost],[ConditionId],[SiteId],[WarehouseId],[LocationId],[ShelfId],[BinId],[OwnerTypeId],
						[Owner],[IsCustomerStock],[TraceableToTypeId],[TraceableTo],[ObtainFromTypeId],[ObtainFrom],[IsMFGDate],[MFGDate],[MFGTrace],[MFGLotNo],[MFGBatchNo],[IsExpDate],
						[ExpDate],[IsTimeLife],[TagDate],[TagType],[TagTypeId],[TimeLifeDate],[TimeLifeOrigin],[TimeLifeCyclesId],[Memo],[PartCertificationNumber],[ManagementStructureId],[GLAccountId],
						[StockLineId],[WorkOrderId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsSkipSerialNo],[IsSkipTimeLife],
						[Reference],[CertifiedBy],GETUTCDATE(),[CustReqDate],[Level1],[Level2],[Level3],[Level4],[EmployeeName],[CustomerName],[WorkScopeId],	[CustomerCode],
				        [ManufacturerName],[InspectedById],[CertifiedDate],[ObtainFromName],[OwnerName],[TraceableToName],[PartNumber],[WorkScope],[Condition],
				        [Site],[Warehouse],[Location],[Shelf],[Bin],[InspectedBy],[InspectedDate],[TaggedById],[TaggedByName],[ACTailNum],[TaggedByType],[TaggedByTypeName],
						[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType],[RemovalReasonId],[RemovalReasons],[RemovalReasonsMemo],[ExchangeSalesOrderId],
				        [CustReqTagTypeId],[CustReqTagType],[CustReqCertTypeId],[CustReqCertType],[RepairOrderPartRecordId],[IsExchangeBatchEntry],[ShippingViaId],[EngineSerialNumber],[ShippingAccount], 
						[ShippingReference],[TimeLifeDetailsNotProvided],[PurchaseUnitOfMeasureId],[GlAccountName],[CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],
                        [CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],[TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[IsSkipShippingReference],[IsBatchStock],[BatchNumber],
						[CSN],[TSN],[CSO],[TSO]
				   FROM @tbl_ReceivingCustomerWorkType

		SELECT @TotalRecord = MIN(Quantity), @MinId = MIN(ID) FROM #tmprReceiveCustomer    
		
		DECLARE @TotalCount INT = @MinId

		PRINT @TotalRecord + ''

		WHILE @TotalCount <= @TotalRecord
		BEGIN				
				PRINT @TotalCount + ''
				DECLARE @CurrentIdNumber AS BIGINT, @RCCurrentIdNumber AS BIGINT,@CSBCurrentIdNumber AS BIGINT
				DECLARE @ReceiverNumber AS VARCHAR(50),@CreatedBy VARCHAR(250),@UpdatedBy VARCHAR(250)
				DECLARE @IdCodeTypeId BIGINT, @RCIdCodeTypeId BIGINT,@CSBCodeTypeId BIGINT;					
				DECLARE @NHAItemMasterId BIGINT,@TLAItemMasterId BIGINT,@LegalEntityId BIGINT,@ManagementStructureId BIGINT,@RevicedPNId BIGINT,@TimeLifeCyclesId BIGINT, @ConditionId BIGINT
				DECLARE @StockLineNumber VARCHAR(100);
				DECLARE @CNCurrentNumber BIGINT;
				DECLARE @ControlNumber VARCHAR(50);
				DECLARE @StocklineId BIGINT = 0;
				DECLARE @stockLineCurrentNo AS BIGINT;
				DECLARE @currentNo AS BIGINT = 0;
				DECLARE @ItemMasterId AS BIGINT;
				DECLARE @ManufacturerId AS BIGINT
				DECLARE @PreviousStockLineNumber VARCHAR(50);
				DECLARE @Quantity INT = 0;
				DECLARE @ShelfLife BIT,@IsHazardousMaterial BIT,@IsPMA BIT,@IsDER BIT,@OEM BIT,@IsTimeLIfe BIT,@TimeLifeDetailsNotProvided BIT, @GlAccountId BIGINT, @GlAccountName VARCHAR(100)
				DECLARE @IsBatchStock BIT = 0

                SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Stock Line';
				SELECT @RCIdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Receiving Customer Work';
				SELECT @CSBCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'BatchNumber';
  			    
				SELECT @ItemMasterId = [ItemMasterId], 
				       @ManufacturerId = [ManufacturerId], 
					   @StocklineId = ISNULL([StockLineId],0),
					   @ReceivingCustomerWorkId = [ReceivingCustomerWorkId],
					   @TimeLifeCyclesId = [TimeLifeCyclesId],
					   @ManagementStructureId = [ManagementStructureId], 
					   @ConditionId = [ConditionId], 					   
					   @TimeLifeDetailsNotProvided = ISNULL([TimeLifeDetailsNotProvided],0),
					   @CreatedBy = [CreatedBy],
					   @UpdatedBy = [UpdatedBy],
					   @Quantity = ISNULL([Quantity],0),
					   @CreatedBy = [CreatedBy],
					   @IsBatchStock  = ISNULL([IsBatchStock],0)
				 FROM #tmprReceiveCustomer WHERE [ID] = @MinId;

				SELECT @ShelfLife = [ShelfLife], 
					   @IsHazardousMaterial = [IsHazardousMaterial],
					   @IsPMA  = [IsPMA],
					   @IsDER = [IsDER],
					   @OEM = [IsOEM], 
					   @RevicedPNId = [RevisedPartId],	
					   @GlAccountId = [GlAccountId],
					   @IsTimeLife = [IsTimeLife]
				  FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId;

				SELECT 
					   @GlAccountId = im.[GlAccountId],
					   @GlAccountName = gl.[AccountName]
				  FROM [dbo].[ItemMaster] AS im WITH(NOLOCK) 
					INNER JOIN [dbo].[GLAccount] AS gl ON gl.GLAccountId = im.GLAccountId
				 WHERE [ItemMasterId] = @ItemMasterId;

				SELECT TOP 1 @NHAItemMasterId = [MappingItemMasterId]  FROM [dbo].[Nha_Tla_Alt_Equ_ItemMapping] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [MappingType] = @NHAMappingType;
                SELECT TOP 1 @TLAItemMasterId = [MappingItemMasterId]  FROM [dbo].[Nha_Tla_Alt_Equ_ItemMapping] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [MappingType] = @TLAMappingType;                 
				SELECT TOP 1 @LegalEntityId = [LegalEntityId]  FROM [dbo].[ManagementStructure] WITH(NOLOCK) WHERE [ManagementStructureId] = @ManagementStructureId;

				IF(@StocklineId = 0)
				BEGIN
					DECLARE @NewStocklineId BIGINT

					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCodePrefixes
					END
				
					CREATE TABLE #tmpCodePrefixes
					(
						[ID] BIGINT NOT NULL IDENTITY,
						[CodePrefixId] BIGINT NULL,
						[CodeTypeId] BIGINT NULL,
						[CurrentNumber] BIGINT NULL,
						[CodePrefix] VARCHAR(50) NULL,
						[CodeSufix] VARCHAR(50) NULL,
						[StartsFrom] BIGINT NULL,
					)

					INSERT INTO #tmpCodePrefixes([CodePrefixId],[CodeTypeId],[CurrentNumber],[CodePrefix],[CodeSufix],[StartsFrom])
					SELECT [CodePrefixId],CP.[CodeTypeId],[CurrentNummber],[CodePrefix],[CodeSufix],[StartsFrom] 
					FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @IdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
					
					IF OBJECT_ID(N'tempdb..#tmpRCCodePrefixes') IS NOT NULL
					BEGIN
						DROP TABLE #tmpRCCodePrefixes
					END

					CREATE TABLE #tmpRCCodePrefixes
					(
						[ID] BIGINT NOT NULL IDENTITY,
						[CodePrefixId] BIGINT NULL,
						[CodeTypeId] BIGINT NULL,
						[CurrentNumber] BIGINT NULL,
						[CodePrefix] VARCHAR(50) NULL,
						[CodeSufix] VARCHAR(50) NULL,
						[StartsFrom] BIGINT NULL,
					)

					INSERT INTO #tmpRCCodePrefixes([CodePrefixId],[CodeTypeId],[CurrentNumber],[CodePrefix],[CodeSufix],[StartsFrom])
					SELECT [CodePrefixId],CP.[CodeTypeId],[CurrentNummber],[CodePrefix],[CodeSufix],[StartsFrom] 
					FROM dbo.CodePrefixes CP WITH (NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @RCIdCodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
														   					 				  				  
					IF OBJECT_ID(N'tempdb..#tmpCSBCodePrefixes') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCSBCodePrefixes
					END

					CREATE TABLE #tmpCSBCodePrefixes
					(
						[ID] BIGINT NOT NULL IDENTITY,
						[CodePrefixId] BIGINT NULL,
						[CodeTypeId] BIGINT NULL,
						[CurrentNumber] BIGINT NULL,
						[CodePrefix] VARCHAR(50) NULL,
						[CodeSufix] VARCHAR(50) NULL,
						[StartsFrom] BIGINT NULL,
					)

					INSERT INTO #tmpCSBCodePrefixes([CodePrefixId],[CodeTypeId],[CurrentNumber],[CodePrefix],[CodeSufix],[StartsFrom])
					SELECT [CodePrefixId],CP.[CodeTypeId],[CurrentNummber],[CodePrefix],[CodeSufix],[StartsFrom] 
					FROM [dbo].[CodePrefixes] CP WITH (NOLOCK) 
					JOIN [dbo].[CodeTypes] CT WITH (NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
					WHERE CT.[CodeTypeId] = @CSBCodeTypeId AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;
					
					IF (@CurrentIndex = 0)
					BEGIN
						SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END
						FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					END
					ELSE
					BEGIN
						SELECT @CurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END
						FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					END

					SET @ReceiverNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentIdNumber, 'RecNo', (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))

					IF (@RCCurrentIndex = 0)
					BEGIN
						SELECT @RCCurrentIdNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) ELSE CAST([StartsFrom] AS BIGINT) END
						FROM #tmpRCCodePrefixes WHERE [CodeTypeId] = @RCIdCodeTypeId
					END
					ELSE
					BEGIN
						SELECT @RCCurrentIdNumber = CASE WHEN CurrentNumber > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END
						FROM #tmpRCCodePrefixes WHERE [CodeTypeId] = @RCIdCodeTypeId
					END		
					-- Batch Number
					IF(@IsBatchStock = 1)
					BEGIN
						IF (@CSBCurrentIndex = 0)
						BEGIN
							SELECT @CSBCurrentIdNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) ELSE CAST([StartsFrom] AS BIGINT) END
							FROM #tmpCSBCodePrefixes WHERE [CodeTypeId] = @CSBCodeTypeId
						END
						ELSE
						BEGIN
							SELECT @CSBCurrentIdNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END
							FROM #tmpCSBCodePrefixes WHERE [CodeTypeId] = @CSBCodeTypeId
						END   
					END
                    
					IF(@TotalCount = 1 )
					BEGIN
						SET @RCReceiverNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@RCCurrentIdNumber, 'RecNo', (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @RCIdCodeTypeId)))
						IF(@IsBatchStock = 1)
						BEGIN 
							SET @CSBReceiverNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CSBCurrentIdNumber, (SELECT [CodePrefix] FROM #tmpCSBCodePrefixes WHERE [CodeTypeId] = @CSBCodeTypeId), (SELECT [CodeSufix] FROM #tmpCSBCodePrefixes WHERE [CodeTypeId] = @CSBCodeTypeId)))
						END
					END	
                
					IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL                
					BEGIN                    
						DROP TABLE #tmpPNManufacturer                    
					END

					CREATE TABLE #tmpPNManufacturer
					(
						[ID] BIGINT NOT NULL IDENTITY,
						[ItemMasterId] BIGINT NULL,
						[ManufacturerId] BIGINT NULL,
						[StockLineNumber] VARCHAR(100) NULL,
						[CurrentStlNo] BIGINT NULL,
						[isSerialized] BIT NULL
					 );
					 WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId)
					  AS (SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId 
								FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1
									CROSS JOIN (SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2
									LEFT JOIN DBO.Stockline ac WITH (NOLOCK) ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId
								WHERE ac.MasterCompanyId = @MasterCompanyId
								GROUP BY ac.ItemMasterId, ac.ManufacturerId
								HAVING COUNT(ac.ItemMasterId) > 0)

					INSERT INTO #tmpPNManufacturer([ItemMasterId],[ManufacturerId],[StockLineNumber],[CurrentStlNo],[isSerialized])
					SELECT CSTL.[ItemMasterId],CSTL.[ManufacturerId],[StockLineNumber],ISNULL(IM.[CurrentStlNo], 0),IM.[isSerialized]
					FROM CTE_Stockline CSTL
					INNER JOIN dbo.Stockline STL WITH (NOLOCK)
					INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId 
					ON CSTL.StockLineId = STL.StockLineId
                       
					/* PN Manufacturer Combination Stockline logic */

					DELETE FROM #tmpCodePrefixes;

					INSERT INTO #tmpCodePrefixes([CodePrefixId],[CodeTypeId],[CurrentNumber],[CodePrefix],[CodeSufix],[StartsFrom])
					SELECT [CodePrefixId],CP.[CodeTypeId],[CurrentNummber],[CodePrefix],[CodeSufix],[StartsFrom] FROM dbo.CodePrefixes CP WITH (NOLOCK)
					JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId IN ( @StockIdCodeTypeId, @IdNumberCodeTypeId, @ControlNumberCodeTypeId )
					AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
				
					SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

					IF (@currentNo <> 0)
					BEGIN
						SET @stockLineCurrentNo = @currentNo + 1;
					END
					ELSE
					BEGIN
						SET @stockLineCurrentNo = 1;
					END

					IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @StockIdCodeTypeId))
					BEGIN
						SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@stockLineCurrentNo, 
											   (SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @StockIdCodeTypeId),
											   (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @StockIdCodeTypeId)))

						UPDATE [dbo].[ItemMaster] SET [CurrentStlNo] = @stockLineCurrentNo WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId
					END

					IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @ControlNumberCodeTypeId))
					BEGIN
						SELECT @CNCurrentNumber = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END
						FROM #tmpCodePrefixes WHERE [CodeTypeId] = @ControlNumberCodeTypeId;
						SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CNCurrentNumber, 
							(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId),
							(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @ControlNumberCodeTypeId))
						)
					END

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @IdNumberCodeTypeId))  
					BEGIN     
						SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(1,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdNumberCodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdNumberCodeTypeId)))  
					END 			
					
					DECLARE @IntegrationPortal VARCHAR(50)
					SELECT
						@IntegrationPortal = STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',')
					FROM dbo.ItemMaster iM WITH(NOLOCK)
					LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
					LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
					WHERE iM.ItemMasterId = @ItemMasterId AND iM.MasterCompanyId = @MasterCompanyId AND mp.IntegrationPortalId IS NOT NULL
					GROUP BY iM.ItemMasterId

					INSERT INTO [dbo].[Stockline]([PartNumber],[StockLineNumber],[StocklineMatchKey],[ControlNumber],[ItemMasterId],[Quantity],[ConditionId],[SerialNumber]						   
						   ,[ShelfLife],[ShelfLifeExpirationDate],[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],[Manufacturer],[ManufacturerLotNumber]	                       
						   ,[ManufacturingDate],[ManufacturingBatchNumber],[PartCertificationNumber],[CertifiedBy],[CertifiedDate],[TagDate],[TagType],[CertifiedDueDate]						  						  
						   ,[CalibrationMemo],[OrderDate],[PurchaseOrderId],[PurchaseOrderUnitCost],[InventoryUnitCost],[RepairOrderId],[RepairOrderUnitCost],[ReceivedDate]
						   ,[ReceiverNumber],[ReconciliationNumber],[UnitSalesPrice],[CoreUnitCost],[GLAccountId],[AssetId],[IsHazardousMaterial],[IsPMA],[IsDER],[OEM],[Memo] 
						   ,[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[isSerialized],[ShelfId],[BinId]	
						   ,[SiteId],[ObtainFromType],[OwnerType],[TraceableToType],[UnitCostAdjustmentReasonTypeId],[UnitSalePriceAdjustmentReasonTypeId],[IdNumber]   						   
						   ,[QuantityToReceive],[PurchaseOrderExtendedCost],[ManufacturingTrace],[ExpirationDate],[AircraftTailNumber],[ShippingViaId],[EngineSerialNumber]
						   ,[QuantityRejected],[PurchaseOrderPartRecordId],[ShippingAccount],[ShippingReference],[TimeLifeCyclesId],[TimeLifeDetailsNotProvided],[WorkOrderId]	
						   ,[WorkOrderMaterialsId],[QuantityReserved],[QuantityTurnIn],[QuantityIssued],[QuantityOnHand],[QuantityAvailable],[QuantityOnOrder],[QtyReserved]
						   ,[QtyIssued],[BlackListed],[BlackListedReason],[Incident],[IncidentReason],[Accident],[AccidentReason],[RepairOrderPartRecordId],[isActive] 
						   ,[isDeleted],[WorkOrderExtendedCost],[RepairOrderExtendedCost],[IsCustomerStock],[EntryDate],[LotCost],[NHAItemMasterId],[TLAItemMasterId]
	                       ,[ItemTypeId],[AcquistionTypeId],[RequestorId],[LotNumber],[LotDescription],[TagNumber],[InspectionBy],[InspectionDate],[VendorId],[IsParent]							   
						   ,[ParentId],[IsSameDetailsForAllParts],[WorkOrderPartNoId],[SubWorkOrderId],[SubWOPartNoId],[IsOemPNId],[PurchaseUnitOfMeasureId]
						   ,[ObtainFromName],[OwnerName],[TraceableToName],[Level1],[Level2],[Level3],[Level4],[Condition],[GlAccountName]								   
						   ,[Site],[Warehouse],[Location],[Shelf],[Bin],[UnitOfMeasure],[WorkOrderNumber],[itemGroup],[TLAPartNumber],[NHAPartNumber],[TLAPartDescription]							   
						   ,[NHAPartDescription],[itemType],[CustomerId],[CustomerName],[isCustomerstockType],[PNDescription],[RevicedPNId],[RevicedPNNumber],[OEMPNNumber]		
						   ,[TaggedBy],[TaggedByName],[UnitCost],[TaggedByType],[TaggedByTypeName],[CertifiedById],[CertifiedTypeId],[CertifiedType],[CertTypeId],[CertType]
						   ,[TagTypeId],[IsFinishGood],[IsTurnIn],[IsCustomerRMA],[RMADeatilsId],[DaysReceived],[ManufacturingDays],[TagDays],[OpenDays],[ExchangeSalesOrderId]	
						   ,[RRQty],[SubWorkOrderNumber],[IsManualEntry],[WorkOrderMaterialsKitId],[LotId],[IsLotAssigned],[LOTQty],[LOTQtyReserve],[OriginalCost],[POOriginalCost]
						   ,[ROOriginalCost],[VendorRMAId],[VendorRMADetailId],[LotMainStocklineId],[IsFromInitialPO],[LotSourceId],[Adjustment],[SalesOrderPartId]
						   ,[FreightAdjustment],[TaxAdjustment],[IsStkTimeLife],[SalesPriceExpiryDate],[SubWorkOrderMaterialsId],[SubWorkOrderMaterialsKitId],[EvidenceId]
						   ,[IsGenerateReleaseForm],[ExistingCustomerId],[RepairOrderNumber],[ExistingCustomer],[QuickBooksReferenceId],[IsUpdated],[LastSyncDate], [IntegrationPortal], [IsPiecePart], [IsRepairManagement],[IsBatchStock],[BatchNumber])                       
				     SELECT [PartNumber],@StockLineNumber,'',@ControlNumber,[ItemMasterId],1,[ConditionId],ISNULL([SerialNumber],''),						   
						    0,NULL,[WarehouseId],[LocationId],[ObtainFrom],[Owner],[TraceableTo],[ManufacturerId],ISNULL([ManufacturerName],''),ISNULL([MFGLotNo],''),
							[MFGDate],ISNULL([MFGBatchNo],''),ISNULL([PartCertificationNumber],''),ISNULL([CertifiedBy],''),[CertifiedDate],[TagDate],ISNULL([TagType],''),NULL,
							'',GETUTCDATE(),NULL,ISNULL([UnitCost], 0),0,NULL,0,GETUTCDATE(),	
							@ReceiverNumber,'',ISNULL([UnitCost], 0),ISNULL([UnitCost], 0),@GlAccountId,NULL,@IsHazardousMaterial,@IsPMA,@IsDER,@OEM,null,								
						    [ManagementStructureId],@LegalEntityId,[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),ISNULL([IsSerialized],0),[ShelfId],[BinId],							
							[SiteId],[ObtainFromTypeId],[OwnerTypeId],[TraceableToTypeId],NULL,NULL,ISNULL(@IDNumber,''), -- [IdNumber]	
							0,0,ISNULL([MFGTrace],''),[ExpDate],[ACTailNum],ISNULL([ShippingViaId], NULL),ISNULL([EngineSerialNumber],''),								
							0,NULL,ISNULL([ShippingAccount],''),ISNULL([ShippingReference],''),NULL,ISNULL([TimeLifeDetailsNotProvided],0),NULL,
							NULL,0,0,0,1,1,NULL,0,
							0,0,'',0,'',0,'',NULL,1,		
							0,0,0,[IsCustomerStock],GETUTCDATE(),0,@NHAItemMasterId,@TLAItemMasterId,
							NULL,NULL,NULL,'','','',NULL,NULL,NULL,1,
							0,0,NULL,NULL,NULL,NULL,[PurchaseUnitOfMeasureId],
							ISNULL([ObtainFromName],''),ISNULL([OwnerName],''),ISNULL([TraceableToName],''),ISNULL([Level1],''),ISNULL([Level2],''),ISNULL([Level3],''),ISNULL([Level4],''),ISNULL([Condition],''),ISNULL(@GlAccountName,''),
							[Site],[Warehouse],[Location],[Shelf],[Bin],'','','','','','',							
							'','Stock',[CustomerId],ISNULL([CustomerName],''),ISNULL([IsCustomerStock],0),'',@RevicedPNId,'','',
							[TaggedById],ISNULL([TaggedByName],''),ISNULL([UnitCost], 0),[TaggedByType],ISNULL([TaggedByTypeName],''),[CertifiedById],[CertifiedTypeId],ISNULL([CertifiedType],''),ISNULL([CertTypeId],''),ISNULL([CertType],''),
							[TagTypeId],0,0,0,NULL,NULL,NULL,NULL,NULL,[ExchangeSalesOrderId],
							0,'',0,NULL,NULL,NULL,0,0,0,0,
							0,NULL,NULL,NULL,0,NULL,0,NULL,
							0,0,ISNULL([IsTimeLife],0),NULL,NULL,NULL,NULL,
						    0,NULL,Reference,'','',0,GETUTCDATE(), @IntegrationPortal, 0, ISNULL(@IsRepairManagement, 0),@IsBatchStock,@CSBReceiverNumber FROM #tmprReceiveCustomer WHERE ID = @MinId


					SELECT @NewStocklineId = SCOPE_IDENTITY();                                                 
					
					EXEC [dbo].[UpdateStocklineColumnsWithId] @NewStocklineId;

					UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNumber WHERE [CodeTypeId] = @ControlNumberCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

					UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CurrentIdNumber WHERE [CodeTypeId] = @IdCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;					

					DECLARE @StkManagementStructureModuleId BIGINT;
					
					SELECT @StkManagementStructureModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

					EXEC dbo.[USP_SaveSLMSDetails] @StkManagementStructureModuleId, @NewStocklineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy;

					-- Add In Receiving Customer

					INSERT INTO [dbo].[ReceivingCustomerWork] ([EmployeeId] ,[CustomerId] ,[ReceivingNumber] ,[CustomerContactId] ,[ItemMasterId] ,[RevisePartId] 
					           ,[IsSerialized] ,[SerialNumber] ,[Quantity] ,[ConditionId] ,[SiteId] ,[WarehouseId] ,[LocationId] ,[Shelfid] ,[BinId] ,[OwnerTypeId]
							   ,[Owner] ,[IsCustomerStock] ,[TraceableToTypeId] ,[TraceableTo] ,[ObtainFromTypeId] ,[ObtainFrom] ,[IsMFGDate] ,[MFGDate] ,[MFGTrace] 
							   ,[MFGLotNo] ,[IsExpDate] ,[ExpDate] ,[IsTimeLife] ,[TagDate] ,[TagType] ,[TagTypeIds] ,[TimeLifeDate] ,[TimeLifeOrigin] 
							   ,[TimeLifeCyclesId] ,[Memo] ,[PartCertificationNumber] ,[ManagementStructureId] ,[StockLineId] ,[WorkOrderId] ,[MasterCompanyId] 
							   ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted] ,[IsSkipSerialNo] ,[IsSkipTimeLife] ,[Reference] 
							   ,[CertifiedBy] ,[ReceivedDate] ,[CustReqDate] ,[Level1] ,[Level2] ,[Level3] ,[Level4] ,[EmployeeName] ,[CustomerName] ,[WorkScopeId] 
							   ,[CustomerCode] ,[ManufacturerName] ,[InspectedById] ,[CertifiedDate] ,[ObtainFromName] ,[OwnerName] ,[TraceableToName] ,[PartNumber] 
							   ,[WorkScope] ,[Condition] ,[Site] ,[Warehouse] ,[Location] ,[Shelf] ,[Bin] ,[InspectedBy] ,[InspectedDate] ,[TaggedById] ,[TaggedBy] 
							   ,[ACTailNum] ,[TaggedByType] ,[TaggedByTypeName] ,[CertifiedById] ,[CertifiedTypeId] ,[CertifiedType] ,[CertTypeId],[CertType] 
							   ,[RemovalReasonId] ,[RemovalReasons] ,[RemovalReasonsMemo] ,[ExchangeSalesOrderId] ,[CustReqTagTypeId] ,[CustReqTagType] 
							   ,[CustReqCertTypeId] ,[CustReqCertType] ,[RepairOrderPartRecordId] ,[IsExchangeBatchEntry],[IsPiecePart], [IsRepairManagement],[IsSkipShippingReference],
							   [CSN],[TSN],[CSO],[TSO] )
					     SELECT [EmployeeId],[CustomerId],@RCReceiverNumber,[CustomerContactId] ,[ItemMasterId] ,[RevisePartId] 
						       ,[IsSerialized] ,[SerialNumber] ,1 ,[ConditionId] ,[SiteId] ,[WarehouseId] ,[LocationId] ,[ShelfId] ,[BinId] ,[OwnerTypeId]
							   ,[Owner] ,[IsCustomerStock] ,[TraceableToTypeId] ,[TraceableTo] ,[ObtainFromTypeId] ,[ObtainFrom] ,[IsMFGDate] ,[MFGDate] ,[MFGTrace]
							   ,[MFGLotNo] ,[IsExpDate] ,[ExpDate] ,[IsTimeLife] ,[TagDate] ,[TagType] ,[TagTypeId] ,[TimeLifeDate] ,[TimeLifeOrigin] 
							   ,TimeLifeCyclesId ,[Memo] ,[PartCertificationNumber] ,[ManagementStructureId] ,@NewStocklineId ,[WorkOrderId] ,[MasterCompanyId] 
							   ,[CreatedBy] ,[UpdatedBy] ,GETUTCDATE() ,GETUTCDATE() ,1 ,0 ,[IsSkipSerialNo] ,[IsSkipTimeLife] ,[Reference] 
							   ,[CertifiedBy] ,GETUTCDATE() ,[CustReqDate] ,[Level1] ,[Level2] ,[Level3] ,[Level4] ,[EmployeeName] ,[CustomerName] ,[WorkScopeId] 
							   ,[CustomerCode] ,[ManufacturerName] ,[InspectedById] ,[CertifiedDate] ,[ObtainFromName] ,[OwnerName] ,[TraceableToName] ,[PartNumber] 
							   ,[WorkScope] ,[Condition] ,[Site] ,[Warehouse] ,[Location] ,[Shelf] ,[Bin] ,[InspectedBy] ,[InspectedDate] ,[TaggedById] ,[TaggedByName] 
							   ,[ACTailNum] ,[TaggedByType] ,[TaggedByTypeName] ,[CertifiedById] ,[CertifiedTypeId] ,[CertifiedType] ,[CertTypeId],[CertType] 
							   ,[RemovalReasonId] ,[RemovalReasons] ,[RemovalReasonsMemo] ,[ExchangeSalesOrderId] ,[CustReqTagTypeId] ,[CustReqTagType] 
							   ,[CustReqCertTypeId] ,[CustReqCertType] ,[RepairOrderPartRecordId] ,[IsExchangeBatchEntry],0, ISNULL(@IsRepairManagement, 0),[IsSkipShippingReference],
								 [CSN],[TSN],[CSO],[TSO] 
								 FROM #tmprReceiveCustomer WHERE ID = @MinId;	

					SELECT @ReceivingCustomerWorkId = SCOPE_IDENTITY(); 

					EXEC [dbo].[UpdateReceivingCustomerColumnsWithId] @ReceivingCustomerWorkId;

					IF(@TotalCount = 1 )
					BEGIN
						UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @RCCurrentIdNumber WHERE [CodeTypeId] = @RCIdCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;	
					END	
					IF(@TotalCount = 1 AND @IsBatchStock = 1)
					BEGIN
						UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CSBCurrentIdNumber WHERE [CodeTypeId] = @CSBCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;	
					END

					IF (@IsTimeLIfe = 1)
                    BEGIN
						INSERT INTO dbo.TimeLife([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],
												 [TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],
												 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],
												 [DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],[VendorRMAId],[VendorRMADetailId])
                                          SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],
                                                 [TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],@MasterCompanyId,
                                                 @CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,NULL,NULL, @NewStocklineId,0,NULL,NULL,NULL,NULL
										    FROM #tmprReceiveCustomer WHERE ID = @MinId;

						SELECT @TimeLifeCyclesId = SCOPE_IDENTITY(); 

						UPDATE [dbo].[Stockline] SET [TimeLifeCyclesId] = @TimeLifeCyclesId WHERE [StockLineId] = @NewStocklineId  AND [MasterCompanyId] = @MasterCompanyId;

						UPDATE [dbo].[ReceivingCustomerWork] SET [TimeLifeCyclesId] = @TimeLifeCyclesId WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId  AND [MasterCompanyId] = @MasterCompanyId;

					END

					DECLARE @RCManagementStructureModuleId BIGINT;
					
					SELECT @RCManagementStructureModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'RecevingCustomer';
					
					EXEC [dbo].[USP_SaveWOMSDetails] @RCManagementStructureModuleId, @ReceivingCustomerWorkId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy, 1;
				    
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @NewStocklineId,@ReceivingCustomerModuleId,@ReceivingCustomerWorkId,NULL,NULL,11,@Quantity,@CreatedBy;

					DECLARE @ExchangeSalesOrderId BIGINT = 0
					SELECT @ExchangeSalesOrderId = ExchangeSalesOrderId FROM #tmprReceiveCustomer WHERE ID = @MinId

					IF @ExchangeSalesOrderId > 0
					BEGIN
						DECLARE 
							@DistributionCode NVARCHAR(50) = 'EX-CoreReturned',  -- DistributionMasterConstant.EXCoreReturned
							@DistributionMasterId BIGINT,
							@DistributionCodeOut NVARCHAR(50);

						SELECT TOP 1 
							@DistributionMasterId = ID,
							@DistributionCodeOut = DistributionCode
						FROM dbo.DistributionMaster WITH (NOLOCK)
						WHERE DistributionCode = @DistributionCode;

						-- Step 2: Check if matching DistributionSetup exists
						IF NOT EXISTS (
							SELECT 1
							FROM dbo.DistributionSetup WITH (NOLOCK)
							WHERE DistributionMasterId = @DistributionMasterId
							  AND MasterCompanyId = @MasterCompanyId
							  AND GlAccountId = 0
							  AND ISNULL([IsManualText],0) = 0
						)
						BEGIN
							-- Step 3: Prepare and use the "SOBatchTriggerModel"
							-- Replace this with your actual logic (e.g., inserting into a temp table, calling SP, etc.)
    
							DECLARE 
								@ReferenceId BIGINT = @ExchangeSalesOrderId,
								@ReferencePartId BIGINT = 0,
								@ReferencePieceId BIGINT = 0,
								@InvoiceId BIGINT = @ReceivingCustomerWorkId,
								@DistributionStocklineId BIGINT = 0,
								@Qty INT = 0,
								@Amount DECIMAL(18,2) = 0.0,
								@ModuleName NVARCHAR(50) = 'ExchangeSO';  -- DistributionMasterConstant.ExchangeSO


							IF (@DistributionCodeOut IS NULL OR LTRIM(RTRIM(@DistributionCodeOut)) = '')
							BEGIN
								SELECT TOP 1 @DistributionCodeOut = DistributionCode
								FROM dbo.DistributionMaster WITH (NOLOCK)
								WHERE ID = @DistributionMasterId;
							END

							DECLARE 
								@IsRestrict BIT,
								@IsAccountByPass BIT;

							EXEC dbo.USP_GetSubLadgerGLAccountRestriction 
								@DistributionCode = @DistributionCodeOut,
								@MasterCompanyId = @MasterCompanyId,
								@AccountingCalendarId = 0,
								@UpdateBy = @UpdatedBy,
								@IsRestrict = @IsRestrict OUTPUT,
								@IsAccountByPass = @IsAccountByPass OUTPUT;

							IF (@IsAccountByPass != 1)
							BEGIN
								-- Execute the batch trigger based on EXSO invoice
								EXEC dbo.USP_BatchTriggerBasedonEXSOInvoice
									@DistributionMasterId = @DistributionMasterId,
									@ReferenceId = @ReferenceId,
									@ReferencePartId = @ReferencePartId,
									@ReferencePieceId = @ReferencePieceId,
									@InvoiceId = @InvoiceId,
									@StocklineId = @DistributionStocklineId,
									@Qty = @Qty,
									@Amount = @Amount,
									@ModuleName = @ModuleName,
									@MasterCompanyId = @MasterCompanyId,
									@UpdateBy = @UpdatedBy;
							END
						END
					END

				END	
				ELSE 
				BEGIN		
				 	UPDATE ST 
					   SET ST.[PartNumber] = TR.[PartNumber]
						  ,ST.[ItemMasterId] = TR.[ItemMasterId]
						  --,ST.[Quantity] = <Quantity, int,>
						  ,ST.[ConditionId] =  TR.[ConditionId]
						  ,ST.[SerialNumber] = TR.[SerialNumber]						
						  ,ST.[WarehouseId] =  TR.[WarehouseId]	
						  ,ST.[LocationId] = TR.[LocationId]	
						  ,ST.[ObtainFrom] =  TR.[ObtainFrom]
						  ,ST.[Owner] =  TR.[Owner]
						  ,ST.[TraceableTo] =  TR.[TraceableTo]
						  ,ST.[ManufacturerId] =  TR.[ManufacturerId]
						  ,ST.[Manufacturer] = TR.[ManufacturerName]
						  ,ST.[ManufacturerLotNumber] = TR.[MFGLotNo]
						  ,ST.[ManufacturingDate] = TR.[MFGDate]
						  ,ST.[ManufacturingBatchNumber] = TR.[MFGBatchNo]
						  ,ST.[PartCertificationNumber] = TR.[PartCertificationNumber]
						  ,ST.[CertifiedBy] = TR.[CertifiedById]
						  ,ST.[CertifiedDate] = TR.[CertifiedDate]
						  ,ST.[TagDate] = TR.[TagDate]
						  ,ST.[TagType] = TR.[TagType]
						  ,ST.[UnitSalesPrice] = ISNULL(TR.[UnitCost],0)
						  ,ST.[CoreUnitCost] = ISNULL(TR.[UnitCost],0)
						  ,ST.[GLAccountId] = @GlAccountId
						  ,ST.[IsHazardousMaterial] = @IsHazardousMaterial
						  ,ST.[IsPMA] = @IsPMA
						  ,ST.[IsDER] = @IsDER
						  ,ST.[OEM] = @OEM
						  ,ST.[Memo] = NULL
						  ,ST.[ManagementStructureId] = TR.[ManagementStructureId]
						  ,ST.[LegalEntityId] = @LegalEntityId
						  ,ST.[UpdatedBy] = TR.[UpdatedBy]
						  ,ST.[UpdatedDate] = GETUTCDATE()
						  ,ST.[isSerialized] = TR.[isSerialized]
						  ,ST.[ShelfId] = TR.[ShelfId]
						  ,ST.[BinId] = TR.[BinId]
						  ,ST.[SiteId] = TR.[SiteId]
						  ,ST.[ObtainFromType] = TR.[ObtainFromTypeId]
						  ,ST.[OwnerType] = TR.[OwnerTypeId]
						  ,ST.[TraceableToType] = TR.[TraceableToTypeId]
						  ,ST.[ManufacturingTrace] = TR.[MFGTrace]
						  ,ST.[ExpirationDate] = TR.[ExpDate]
						  ,ST.[ShippingViaId] = TR.[ShippingViaId]
						  ,ST.[EngineSerialNumber] = TR.[EngineSerialNumber]
						  ,ST.[ShippingAccount] = TR.[ShippingAccount]
						  ,ST.[ShippingReference] = TR.[ShippingReference]
						  ,ST.[TimeLifeDetailsNotProvided] = ISNULL(TR.[TimeLifeDetailsNotProvided], 0)
						  --,ST.[QuantityOnHand] = <QuantityOnHand, int,>
						  --,ST.[QuantityAvailable] = <QuantityAvailable, int,>
						  --,ST.[QuantityOnOrder] = <QuantityOnOrder, int,>
						  ,ST.[IsCustomerStock] = TR.[IsCustomerStock]
						  ,ST.[NHAItemMasterId] = @NHAItemMasterId
						  ,ST.[TLAItemMasterId] = @TLAItemMasterId
						  ,ST.[IsParent] = 1
						  --,ST.[IsSameDetailsForAllParts] = <IsSameDetailsForAllParts, bit,>
						  ,ST.[PurchaseUnitOfMeasureId] = TR.[PurchaseUnitOfMeasureId]
						  ,ST.[ObtainFromName] = TR.[ObtainFromName]
						  ,ST.[OwnerName] = TR.[OwnerName]
						  ,ST.[TraceableToName] = TR.[TraceableToName]					 
						  ,ST.[Condition] = TR.[Condition]
						  ,ST.[GlAccountName] = @GlAccountName
						  ,ST.[Site] = TR.[Site]
						  ,ST.[Warehouse] = TR.[Warehouse]
						  ,ST.[Location] = TR.[Location]
						  ,ST.[Shelf] = TR.[Shelf]
						  ,ST.[Bin] = TR.[Bin]
						  ,ST.[CustomerId] = TR.[CustomerId]
						  ,ST.[CustomerName] = TR.[CustomerName]
						  ,ST.[isCustomerstockType] = TR.[IsCustomerStock]
						  ,ST.[RevicedPNId] = @RevicedPNId
						  ,ST.[TaggedBy] = TR.[TaggedById]
						  ,ST.[TaggedByName] = TR.[TaggedByName]
						  ,ST.[UnitCost] = ISNULL(TR.[UnitCost], 0)
						  ,ST.[TaggedByType] = TR.[TaggedByType]
						  ,ST.[TaggedByTypeName] = TR.[TaggedByTypeName]
						  ,ST.[CertifiedById] = TR.[CertifiedById]
						  ,ST.[CertifiedTypeId] = TR.[CertifiedTypeId]
						  ,ST.[CertifiedType] = TR.[CertifiedType]
						  ,ST.[CertTypeId] = TR.[CertTypeId]
						  ,ST.[CertType] = TR.[CertType]
						  ,ST.[TagTypeId] = TR.[TagTypeId]
						  ,ST.[IsStkTimeLife] = TR.[IsTimeLife]
						  ,ST.[RepairOrderNumber] = TR.Reference
						  ,ST.[IsUpdated] = 1
						  ,ST.[LastSyncDate] = GETUTCDATE()
					     FROM [dbo].[Stockline] ST WITH(NOLOCK) INNER JOIN #tmprReceiveCustomer TR ON ST.[StockLineId] = TR.[StockLineId]
				     WHERE ST.[StockLineId] = @StocklineId;

					EXEC [dbo].[UpdateStocklineColumnsWithId] @NewStocklineId;

					IF (@IsTimeLIfe = 1)
                    BEGIN
						IF NOT EXISTS(SELECT 1 FROM [dbo].[TimeLife] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId)
						BEGIN
							INSERT INTO [dbo].[TimeLife]([CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],
													 [TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],[MasterCompanyId],
													 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[PurchaseOrderId],[PurchaseOrderPartRecordId],[StockLineId],
													 [DetailsNotProvided],[RepairOrderId],[RepairOrderPartRecordId],[VendorRMAId],[VendorRMADetailId])
											  SELECT [CyclesRemaining],[CyclesSinceNew],[CyclesSinceOVH],[CyclesSinceInspection],[CyclesSinceRepair],[TimeRemaining],[TimeSinceNew],
													 [TimeSinceOVH],[TimeSinceInspection],[TimeSinceRepair],[LastSinceNew],[LastSinceOVH],[LastSinceInspection],@MasterCompanyId,
													 @CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,NULL,NULL, @StocklineId,0,NULL,NULL,NULL,NULL
												FROM #tmprReceiveCustomer WHERE ID = @MinId;

							SELECT @TimeLifeCyclesId = SCOPE_IDENTITY(); 

							UPDATE [dbo].[Stockline] SET [TimeLifeCyclesId] = @TimeLifeCyclesId WHERE [StockLineId] = @StocklineId  AND [MasterCompanyId] = @MasterCompanyId;

							UPDATE [dbo].[ReceivingCustomerWork] SET [TimeLifeCyclesId] = @TimeLifeCyclesId WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId  AND [MasterCompanyId] = @MasterCompanyId;

						END
						ELSE
						BEGIN							
							UPDATE TL
							   SET [CyclesRemaining] = TR.[CyclesRemaining]
								  ,[CyclesSinceNew] = TR.[CyclesSinceNew]
								  ,[CyclesSinceOVH] = TR.[CyclesSinceOVH]
								  ,[CyclesSinceInspection] = TR.[CyclesSinceInspection]
								  ,[CyclesSinceRepair] = TR.[CyclesSinceRepair]
								  ,[TimeRemaining] = TR.[TimeRemaining]
								  ,[TimeSinceNew] = TR.[TimeSinceNew]
								  ,[TimeSinceOVH] = TR.[TimeSinceOVH]
								  ,[TimeSinceInspection] = TR.[TimeSinceInspection]
								  ,[TimeSinceRepair] = TR.[TimeSinceRepair]
								  ,[LastSinceNew] = TR.[LastSinceNew]
								  ,[LastSinceOVH] = TR.[LastSinceOVH]
								  ,[LastSinceInspection] = TR.[LastSinceInspection]
								  ,[UpdatedBy] = TR.[UpdatedBy]
								  ,[UpdatedDate] = GETUTCDATE()
								  ,[DetailsNotProvided] = TL.[DetailsNotProvided]
							  FROM [dbo].[TimeLife] TL WITH(NOLOCK) INNER JOIN #tmprReceiveCustomer TR ON TL.[StockLineId] = TR.[StockLineId]
						  WHERE TL.[StockLineId] = @StocklineId;
						END
					END

					UPDATE RC
					   SET RC.[EmployeeId] = TR.[EmployeeId]
						  ,RC.[CustomerId] = TR.[CustomerId]
						  ,RC.[CustomerContactId] = TR.[CustomerContactId]
						  ,RC.[ItemMasterId] = TR.[ItemMasterId]
						  ,RC.[RevisePartId] = TR.[RevisePartId]
						  ,RC.[IsSerialized] = TR.[IsSerialized]
						  ,RC.[SerialNumber] = TR.[SerialNumber]
						  ,RC.[ConditionId] = TR.[ConditionId]
						  ,RC.[SiteId] = TR.[SiteId]
						  ,RC.[WarehouseId] = TR.[WarehouseId]
						  ,RC.[LocationId] = TR.[LocationId]
						  ,RC.[Shelfid] = TR.[Shelfid]
						  ,RC.[BinId] = TR.[BinId]
						  ,RC.[OwnerTypeId] = TR.[OwnerTypeId]
						  ,RC.[Owner] = TR.[Owner]
						  ,RC.[IsCustomerStock] = TR.[IsCustomerStock]
						  ,RC.[TraceableToTypeId] = TR.[TraceableToTypeId]
						  ,RC.[TraceableTo] = TR.[TraceableTo]
						  ,RC.[ObtainFromTypeId] = TR.[ObtainFromTypeId]
						  ,RC.[ObtainFrom] = TR.[ObtainFrom]
						  ,RC.[IsMFGDate] = TR.[IsMFGDate]
						  ,RC.[MFGDate] = TR.[MFGDate]
						  ,RC.[MFGTrace] = TR.[MFGTrace]
						  ,RC.[MFGLotNo] = TR.[MFGLotNo]
						  ,RC.[IsExpDate] = TR.[IsExpDate]
						  ,RC.[ExpDate] = TR.[ExpDate]
						  ,RC.[IsTimeLife] = TR.[IsTimeLife]
						  ,RC.[TagDate] = TR.[TagDate]
						  ,RC.[TagType] = TR.[TagType]
						  ,RC.[TagTypeIds] = TR.[TagTypeId]
						  ,RC.[TimeLifeDate] = TR.[TimeLifeDate]
						  ,RC.[TimeLifeOrigin] = TR.[TimeLifeOrigin]
						  ,RC.[TimeLifeCyclesId] = TR.TimeLifeCyclesId
						  ,RC.[Memo] = TR.[Memo]
						  ,RC.[PartCertificationNumber] = TR.[PartCertificationNumber]
						  ,RC.[ManagementStructureId] = TR.[ManagementStructureId]
						  ,RC.[StockLineId] = TR.[StockLineId]
						  ,RC.[UpdatedBy] = TR.[UpdatedBy]
						  ,RC.[UpdatedDate] = GETUTCDATE()
						  ,RC.[IsDeleted] = TR.[IsDeleted]
						  ,RC.[IsSkipSerialNo] = TR.[IsSkipSerialNo]
						  ,RC.[IsSkipTimeLife] = TR.[IsSkipTimeLife]
						  ,RC.[Reference] = TR.[Reference]
						  ,RC.[CertifiedBy] = TR.[CertifiedBy]						  
						  ,RC.[EmployeeName] = TR.[EmployeeName]
						  ,RC.[CustomerName] = TR.[CustomerName]
						  ,RC.[WorkScopeId] = TR.[WorkScopeId]
						  ,RC.[CustomerCode] = TR.[CustomerCode]
						  ,RC.[ManufacturerName] = TR.[ManufacturerName]
						  ,RC.[InspectedById] = TR.[InspectedById]
						  ,RC.[CertifiedDate] = TR.[CertifiedDate]
						  ,RC.[ObtainFromName] = TR.[ObtainFromName]
						  ,RC.[OwnerName] = TR.[OwnerName]
						  ,RC.[TraceableToName] = TR.[TraceableToName]
						  ,RC.[PartNumber] = TR.[PartNumber]
						  ,RC.[WorkScope] = TR.[WorkScope]
						  ,RC.[Condition] = TR.[Condition]
						  ,RC.[Site] = TR.[Site]
						  ,RC.[Warehouse] = TR.[Warehouse]
						  ,RC.[Location] = TR.[Location]
						  ,RC.[Shelf] = TR.[Shelf]
						  ,RC.[Bin] = TR.[Bin]
						  ,RC.[InspectedBy] = TR.[InspectedBy]
						  ,RC.[InspectedDate] = TR.[InspectedDate]
						  ,RC.[TaggedById] = TR.[TaggedById]
						  ,RC.[TaggedBy] = TR.[TaggedByName]
						  ,RC.[ACTailNum] = TR.[ACTailNum]
						  ,RC.[TaggedByType] = TR.[TaggedByType]
						  ,RC.[TaggedByTypeName] = TR.[TaggedByTypeName]
						  ,RC.[CertifiedById] = TR.[CertifiedById]
						  ,RC.[CertifiedTypeId] = TR.[CertifiedTypeId]
						  ,RC.[CertifiedType] = TR.[CertifiedType]
						  ,RC.[CertTypeId] = TR.[CertTypeId]
						  ,RC.[CertType] = TR.[CertType]
						  ,RC.[IsExchangeBatchEntry] = 0
						  ,RC.[CSN] = TR.[CSN]
						  ,RC.[TSN] = TR.[TSN]
						  ,RC.[CSO] = TR.[CSO]
						  ,RC.[TSO] = TR.[TSO]
						  ,RC.[CustReqCertTypeId] = TR.[CustReqCertTypeId]
						  ,RC.[CustReqCertType] = TR.[CustReqCertType]
						 FROM [dbo].[ReceivingCustomerWork] RC WITH(NOLOCK) INNER JOIN #tmprReceiveCustomer TR ON RC.[ReceivingCustomerWorkId] = TR.[ReceivingCustomerWorkId]
					 WHERE RC.[ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;

					 EXEC [dbo].[UpdateReceivingCustomerColumnsWithId] @ReceivingCustomerWorkId;

					 DECLARE @RCModuleId BIGINT, @WOMPNModuleId BIGINT;
					
					 SELECT @RCModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'RecevingCustomer';

					 SELECT @WOMPNModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';
					 
					DECLARE @WorkOrderPartNumberId BIGINT

					SELECT TOP 1 @WorkOrderPartNumberId = ID
					FROM WorkOrderPartNumber WITH (NOLOCK)
					WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId

					IF @WorkOrderPartNumberId IS NOT NULL
					BEGIN
						UPDATE WOMPN
						SET 
							WOMPN.WorkOrderScopeId = TR.WorkScopeId,
							WOMPN.CustomerReference = TR.Reference,
							WOMPN.ACTailNum = TR.ACTailNum,
							WOMPN.CurrentSerialNumber = TR.SerialNumber,
							WOMPN.ManagementStructureId = @ManagementStructureId
							FROM  WorkOrderPartNumber WOMPN  INNER JOIN #tmprReceiveCustomer TR ON WOMPN.[ReceivingCustomerWorkId] = TR.[ReceivingCustomerWorkId]
						WHERE WOMPN.ID = @WorkOrderPartNumberId

						EXEC [dbo].[USP_UpdateWOMSDetails] @WOMPNModuleId, @WorkOrderPartNumberId, @ManagementStructureId, @UpdatedBy
					END

					 EXEC [dbo].[USP_UpdateWOMSDetails] @RCModuleId, @ReceivingCustomerWorkId, @ManagementStructureId, @UpdatedBy

					 EXEC [dbo].[UpdatePartAfterWOCreated] @ItemMasterId, @ConditionId, @WorkOrderPartNumberId

					 DECLARE @UpdateExchangeSalesOrderId BIGINT = 0
					SELECT @UpdateExchangeSalesOrderId = ExchangeSalesOrderId FROM #tmprReceiveCustomer WHERE ID = @MinId

					IF @UpdateExchangeSalesOrderId > 0
					BEGIN
						DECLARE 
							@UpdateDistributionCode NVARCHAR(50) = 'EX-CoreReturned',  -- DistributionMasterConstant.EXCoreReturned
							@UpdateDistributionMasterId BIGINT,
							@UpdateDistributionCodeOut NVARCHAR(50);

						SELECT TOP 1 
							@UpdateDistributionMasterId = ID,
							@UpdateDistributionCodeOut = DistributionCode
						FROM dbo.DistributionMaster WITH (NOLOCK)
						WHERE DistributionCode = @UpdateDistributionCode;

						-- Step 2: Check if matching DistributionSetup exists
						IF NOT EXISTS (
							SELECT 1
							FROM dbo.DistributionSetup WITH (NOLOCK)
							WHERE DistributionMasterId = @UpdateDistributionMasterId
							  AND MasterCompanyId = @MasterCompanyId
							  AND GlAccountId = 0
							  AND ISNULL([IsManualText],0) = 0
						)
						BEGIN
							-- Step 3: Prepare and use the "SOBatchTriggerModel"
							-- Replace this with your actual logic (e.g., inserting into a temp table, calling SP, etc.)
    
							DECLARE 
								@UpdateReferenceId BIGINT = @UpdateExchangeSalesOrderId,
								@UpdateReferencePartId BIGINT = 0,
								@UpdateReferencePieceId BIGINT = 0,
								@UpdateInvoiceId BIGINT = @ReceivingCustomerWorkId,
								@UpdateDistributionStocklineId BIGINT = 0,
								@UpdateQty INT = 0,
								@UpdateAmount DECIMAL(18,2) = 0.0,
								@UpdateModuleName NVARCHAR(50) = 'ExchangeSO';  -- DistributionMasterConstant.ExchangeSO


							IF (@UpdateDistributionCodeOut IS NULL OR LTRIM(RTRIM(@UpdateDistributionCodeOut)) = '')
							BEGIN
								SELECT TOP 1 @UpdateDistributionCodeOut = DistributionCode
								FROM dbo.DistributionMaster WITH (NOLOCK)
								WHERE ID = @UpdateDistributionMasterId;
							END

							DECLARE 
								@UpdateIsRestrict BIT,
								@UpdateIsAccountByPass BIT;

							EXEC dbo.USP_GetSubLadgerGLAccountRestriction 
								@DistributionCode = @UpdateDistributionCodeOut,
								@MasterCompanyId = @MasterCompanyId,
								@AccountingCalendarId = 0,
								@UpdateBy = @UpdatedBy,
								@IsRestrict = @UpdateIsRestrict OUTPUT,
								@IsAccountByPass = @UpdateIsAccountByPass OUTPUT;

							IF (@UpdateIsAccountByPass != 1)
							BEGIN
								-- Execute the batch trigger based on EXSO invoice
								EXEC dbo.USP_BatchTriggerBasedonEXSOInvoice
									@DistributionMasterId = @UpdateDistributionMasterId,
									@ReferenceId = @UpdateReferenceId,
									@ReferencePartId = @UpdateReferencePartId,
									@ReferencePieceId = @UpdateReferencePieceId,
									@InvoiceId = @UpdateInvoiceId,
									@StocklineId = @UpdateDistributionStocklineId,
									@Qty = @UpdateQty,
									@Amount = @UpdateAmount,
									@ModuleName = @UpdateModuleName,
									@MasterCompanyId = @MasterCompanyId,
									@UpdateBy = @UpdatedBy;
							END
						END
					END

				END
				
				SET @TotalCount = @TotalCount + 1;
		END	
	
		SELECT [ReceivingCustomerWorkId],[ReceivingNumber] FROM [dbo].[ReceivingCustomerWork] WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;

  
	END    
  COMMIT  TRANSACTION    
 END TRY        
 BEGIN CATCH          
    
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = '[CreateUpdateReceivingCustomerWork]'     
			, @ProcedureParameters VARCHAR(3000) = '@ReceivingCustomerWorkId = ''' + CAST(ISNULL(@ReceivingCustomerWorkId, '') AS VARCHAR(100))  
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