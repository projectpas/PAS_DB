/*************************************************************             
 ** File:   [USP_PostReceivingReconcilationFreightAndTaxBatchDetails]             
 ** Author:   
 ** Description: This stored procedure is used to Posting Reconsilation to Batch
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    11/02/2023   Moin Bloch    Created
	2    11/23/2023   Moin Bloch    Added AccountMSModuleId For Accounting Batch Management Structure Details 

	EXEC USP_PostReceivingReconcilationFreightAndTaxBatchDetails 173

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_PostReceivingReconcilationFreightAndTaxBatchDetails]
@ReceivingReconciliationId BIGINT,
@JournalBatchHeaderId BIGINT,
@JournalTypename VARCHAR(50),
@jlTypeId  BIGINT,
@jlTypeName VARCHAR(100),
@INPUTMethod VARCHAR(100),
@DisCode VARCHAR(50),
@ModuleName  VARCHAR(50),
@AccountingPeriodId BIGINT,
@AccountingPeriod  VARCHAR(50),
@EmployeeId BIGINT,
@UpdateBy VARCHAR(50),
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
			DECLARE @TotalRecord int = 0;   
			DECLARE @MinId BIGINT = 1;  
			DECLARE @TotalInvQty INT = 0;  
			DECLARE @TotalStkAvlQty INT = 0;  

			DECLARE @TotalFreight DECIMAL(18,2) = 0
			DECLARE @TotalTax DECIMAL(18,2) = 0 
			DECLARE @TotalMisc DECIMAL(18,2) = 0 
			
			DECLARE @Freight INT  = 1
			DECLARE @Misc INT  = 2
			DECLARE @Tax INT  = 3

			DECLARE @DistributionMasterId BIGINT;			
			DECLARE @JournalBatchDetailId BIGINT=0;
			DECLARE @EMPMSModuleID BIGINT = 47;
			DECLARE @LastMSLevel VARCHAR(200);
			DECLARE @AllMSlevels VARCHAR(MAX);
			DECLARE @AccountMSModuleId INT = 0;
			DECLARE @VendorId BIGINT;
			DECLARE @VendorName VARCHAR(50);
			DECLARE @FreightInvCost DECIMAL(18,2) = 0;
			DECLARE @FreightInvCogs DECIMAL(18,2) = 0;

			DECLARE @TaxInvCost DECIMAL(18,2) = 0;
			DECLARE @TaxInvCogs DECIMAL(18,2) = 0;

			DECLARE @TotalDebit decimal(18, 2) = 0;
			DECLARE @TotalCredit decimal(18, 2) = 0;
			DECLARE @TransactionDate DATETIME2(7)
			DECLARE @currentNo AS BIGINT = 0;
			DECLARE @JournalTypeNumber VARCHAR(50)
			DECLARE @CodeTypeId AS BIGINT = 74;

			DECLARE @StlQtyAvailGlobal INT  = 0
			DECLARE @StlQtyUsedGlobal INT  = 0
			DECLARE @TotalFreightsAmt DECIMAL(18,2) = 0;
			DECLARE @TotalVarCOGS DECIMAL(18,2) = 0;
			DECLARE @ReceivingReconciliationNumber VARCHAR(50)=''
			DECLARE @MiscGLId BIGINT = 0;
			DECLARE @MiscGlAccountNumber VARCHAR(50)=''
		    DECLARE @MISCGlAccountName VARCHAR(50)=''

			SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
					
			SELECT @currentNo = CASE WHEN CP.[CurrentNummber] > 0 THEN CAST(CP.[CurrentNummber] AS BIGINT) + 1 
						             ELSE CAST([StartsFROM] AS BIGINT) + 1 END 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			SET @JournalTypeNumber = 
			(SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,
			(SELECT CodePrefix FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0),
			(SELECT CodeSufix FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0)))
					
			IF OBJECT_ID(N'tempdb..#RRFreightAndTaxPostType') IS NOT NULL    
			BEGIN    
				DROP TABLE #RRFreightAndTaxPostType  
			END        
			CREATE TABLE #RRFreightAndTaxPostType  
			(    
			    [ID] [BIGINT] NOT NULL IDENTITY, 
				[ReceivingReconciliationDetailId] [BIGINT] NOT NULL,
				[StocklineId] [BIGINT] NULL,
				[InvoicedQty] [INT] NULL,
				[InvoicedUnitCost] [DECIMAL](18, 2) NULL,				
				[StockType] [VARCHAR](256) NULL,
				[Packagingid] [INT] NULL,	
				[IsManual] [BIT] NULL,		
				[FreightAdjustment] [DECIMAL](18, 2) NULL,	
				[TaxAdjustment] [DECIMAL](18, 2) NULL,	
				[FreightAdjustmentPerUnit] [DECIMAL](18, 2) NULL,	
				[TaxAdjustmentPerUnit] [DECIMAL](18, 2) NULL,	
			) 

			SELECT [ReceivingReconciliationDetailId],[StocklineId],[InvoicedQty],[InvoicedUnitCost],[StockType],[Packagingid],[IsManual],[FreightAdjustment],[TaxAdjustment],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit]			
			  FROM [dbo].[ReceivingReconciliationDetails] 
			 WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;
						
			INSERT INTO #RRFreightAndTaxPostType ([ReceivingReconciliationDetailId],[StocklineId],[InvoicedQty],[InvoicedUnitCost],[StockType],[Packagingid],[IsManual],[FreightAdjustment],[TaxAdjustment],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit])    
			SELECT [ReceivingReconciliationDetailId],[StocklineId],[InvoicedQty],[InvoicedUnitCost],[StockType],[Packagingid],[IsManual],[FreightAdjustment],[TaxAdjustment],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit]			
			  FROM [dbo].[ReceivingReconciliationDetails] 
			 WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;

			 SELECT @VendorId = [VendorId], 
					@VendorName = [VendorName], 
					@TransactionDate = [InvoiceDate],
					@ReceivingReconciliationNumber = [ReceivingReconciliationNumber]
			   FROM [dbo].[ReceivingReconciliationHeader] WITH(NOLOCK) 
			  WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;

		    SELECT TOP 1 @MiscGLId = [GlAccountId], 
					@MiscGlAccountNumber = [GlAccountNumber], 
					@MISCGlAccountName = [GlAccountName] FROM [dbo].[ReceivingReconciliationDetails] WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId AND [IsManual] = 1 AND [PackagingId] =  @Misc;


			----- Total Freight -----
			SELECT @TotalFreight = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRFreightAndTaxPostType WHERE [IsManual] = 1 AND [PackagingId] = @Freight;			
			----- Total Tax -----
			SELECT @TotalTax = SUM(ISNULL([InvoicedUnitCost],0)) FROM #RRFreightAndTaxPostType WHERE [IsManual] = 1 AND [PackagingId] =  @Tax;
		    ----- Total Misc -----
		    SELECT @TotalMisc = SUM(ISNULL([InvoicedUnitCost],0)) FROM [dbo].[ReceivingReconciliationDetails] WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId AND [IsManual] = 1 AND [PackagingId] =  @Misc;

			SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #RRFreightAndTaxPostType

			SELECT @DistributionMasterId =  [ID]			      
		      FROM [dbo].[DistributionMaster] WITH(NOLOCK)
			  WHERE UPPER([DistributionCode])= UPPER(@DisCode);

			WHILE @MinId <= @TotalRecord
			BEGIN	
				DECLARE @StocklineId BIGINT = 0;
				DECLARE @ReceivingReconciliationDetailId BIGINT = 0;
				DECLARE @Packagingid INT = 0;
				DECLARE @FreightAdjustment DECIMAL(18,2) = 0;
				DECLARE @TaxAdjustment DECIMAL(18,2) = 0;
				DECLARE @FreightAdjustmentPerUnit DECIMAL(18,2) = 0;
				DECLARE @TaxAdjustmentPerUnit DECIMAL(18,2) = 0;
				DECLARE @StockType VARCHAR(50)	 = 0;
				DECLARE @StocklineQtyAvail BIGINT = 0;
				DECLARE @ReceivedQty INT = 0;
				DECLARE @DistributionSetupId INT = 0;
				DECLARE @Distributionname VARCHAR(200);
				DECLARE @GlAccountId INT;
				DECLARE @GlAccountNumber VARCHAR(200);
				DECLARE @GlAccountName VARCHAR(200);
				DECLARE @JournalTypeId INT;
				DECLARE @CrDrType INT;
				DECLARE @ManagementStructureId BIGINT = 0;
				DECLARE @ItemMasterId BIGINT = 0;
				DECLARE @partId BIGINT = 0;
				DECLARE @MPNName varchar(200);
				DECLARE @CommonJournalBatchDetailId BIGINT=0;
				DECLARE @Desc VARCHAR(100);
				DECLARE @PurchaseOrderId BIGINT = 0;
				DECLARE @PurchaseOrderNumber VARCHAR(50) = '';
				DECLARE @StlQtyAvail INT  = 0
			    DECLARE @StlQtyUsed INT  = 0

				SELECT @StocklineId = [StocklineId],	
				       @Packagingid = ISNULL([Packagingid],0),
					   @StockType = [StockType],
					   @ReceivedQty = ISNULL([InvoicedQty], 0),
					   @FreightAdjustment = ISNULL([FreightAdjustment],0),
 					   @FreightAdjustmentPerUnit = ISNULL([FreightAdjustmentPerUnit],0),
					   @TaxAdjustment = ISNULL([TaxAdjustment],0),
					   @TaxAdjustmentPerUnit = ISNULL([TaxAdjustmentPerUnit],0)
				  FROM #RRFreightAndTaxPostType WHERE [ID] = @MinId;

				IF(@Packagingid = 0)
				BEGIN
					IF(UPPER(@StockType) = 'STOCK')
					BEGIN
						SELECT @StocklineQtyAvail = ISNULL(SL.[QuantityAvailable],0) FROM [dbo].[Stockline] SL WITH(NOLOCK) WHERE [StockLineId] = @StocklineId;							
					END
					IF(UPPER(@StockType) = 'NONSTOCK')
					BEGIN
						SELECT @StocklineQtyAvail = ISNULL([QuantityOnHand],0) FROM [dbo].[NonStockInventory] WITH(NOLOCK) WHERE [NonStockInventoryId]=@StocklineId;												  
  					END
					IF(UPPER(@StockType) = 'ASSET')
					BEGIN
						SELECT @StocklineQtyAvail = 1 FROM [dbo].[AssetInventory] WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
					END
												
					IF(@StocklineQtyAvail >= @ReceivedQty)
					BEGIN
						SET @StlQtyAvail = @ReceivedQty;					
					END
					ELSE
					BEGIN						
						SET @StlQtyAvail = @StocklineQtyAvail;	
					END							
					
					SET @FreightInvCost += (ISNULL(@StlQtyAvail, 0) * ISNULL(@FreightAdjustmentPerUnit, 0))
					--SET @FreightInvCogs += ((ISNULL(@ReceivedQty, 0) - ISNULL(@StlQtyAvail, 0) ) * ISNULL(@FreightAdjustmentPerUnit, 0))
					SET @FreightInvCogs += @FreightAdjustment - (ISNULL(@StlQtyAvail, 0) * ISNULL(@FreightAdjustmentPerUnit, 0))
					
					SET @TaxInvCost += (ISNULL(@StlQtyAvail, 0) * ISNULL(@TaxAdjustmentPerUnit, 0))
					SET @TaxInvCogs += @TaxAdjustment - (ISNULL(@StlQtyAvail, 0) * ISNULL(@TaxAdjustmentPerUnit, 0))
				END

				SET @MinId = @MinId + 1;
			END
						
			IF(UPPER(@ModuleName) = UPPER('ReconciliationPO') AND (@TotalFreight > 0 OR @TotalTax > 0 OR @TotalMisc > 0))
			BEGIN
				SELECT @LastMSLevel = [LastMSLevel], 
					   @AllMSlevels = [AllMSlevels],
					   @ManagementStructureId = [EntityMSID]
				 FROM [dbo].[EmployeeManagementStructureDetails] WITH(NOLOCK)
				WHERE [ReferenceID] = @EmployeeId 
				  AND [ModuleID] = @EMPMSModuleID;
			
				INSERT INTO [dbo].[BatchDetails]
				           ([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName], [JournalBatchHeaderId], 
						    [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate],
							[JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], 
							[ModuleName], [LastMSLevel], [AllMSlevels], 
							[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], 
							[UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					 VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 
					        1, 0, NULL, NULL, @TransactionDate, GETUTCDATE(), 
							@jlTypeId, @jlTypeName, 1, 0, 0, @ManagementStructureId, 
							@INPUTMethod,@LastMSLevel ,@AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), 
							GETUTCDATE(), 1, 0,	@AccountingPeriodId, @AccountingPeriod)

				SET @JournalBatchDetailId = SCOPE_IDENTITY();

				----- RECONCILIATION PO ACCPAYABLE -----				

				SELECT TOP 1 @DistributionSetupId = [ID], 
							 @DistributionName = [Name], 
							 @JournalTypeId = [JournalTypeId], 
							 @GlAccountId = [GlAccountId], 
							 @GlAccountNumber = [GlAccountNumber], 
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType]
					   FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					 WHERE UPPER([DistributionSetupCode]) = UPPER('RECPOACCPAYABLE') 
					 AND [DistributionMasterId] = @DistributionMasterId 
					 AND [MasterCompanyId] = @MasterCompanyId;
					 
				IF(@TotalFreight > 0)
				BEGIN
					INSERT INTO [dbo].[CommonBatchDetails]
					           ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
							    [JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
								[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],
								[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
						        @JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0),@GlAccountNumber ,@GlAccountName,@TransactionDate,
								GETUTCDATE(),@JournalTypeId ,@JournalTypename, 
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @TotalFreight ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalFreight END,@ManagementStructureId,
								@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,
								GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
									
				    INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);

					-----  RECONCILIATION PO FREIGHT INV  -----							
					
					IF(@FreightInvCost > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId], 
									 @GlAccountNumber = [GlAccountNumber], 
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER(DistributionSetupCode) = UPPER('RECPOFREIGHTINV') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@FreightInvCost),2)  ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE ROUND((@FreightInvCost),2) END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
									
						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					
					END
					-------  RECONCILIATION VARIABLE COGS  --------

					IF(@FreightInvCogs > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId=[ID], 
									 @DistributionName=[Name], 
									 @JournalTypeId=[JournalTypeId], 
									 @GlAccountId=[GlAccountId], 
									 @GlAccountNumber=[GlAccountNumber], 
									 @GlAccountName=[GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER([DistributionSetupCode])=UPPER('RECPOVARCOGS') 
								AND  [DistributionMasterId] = @DistributionMasterId 
								AND  [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,								
									CASE WHEN @CrDrType = 1 THEN 0 ELSE 1 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE  ROUND((@FreightInvCogs),2) END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@FreightInvCogs),2) ELSE 0 END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);
													
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END			
				END		

				IF(@TotalTax > 0)
				BEGIN 
					SELECT TOP 1 @DistributionSetupId = [ID], 
							 @DistributionName = [Name], 
							 @JournalTypeId = [JournalTypeId], 
							 @GlAccountId = [GlAccountId], 
							 @GlAccountNumber = [GlAccountNumber], 
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType]
					   FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					 WHERE UPPER([DistributionSetupCode]) = UPPER('RECPOACCPAYABLE') 
					 AND [DistributionMasterId] = @DistributionMasterId 
					 AND [MasterCompanyId] = @MasterCompanyId;
					 
					INSERT INTO [dbo].[CommonBatchDetails]
					           ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
							    [JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
								[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],
								[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
						        @JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0),@GlAccountNumber ,@GlAccountName,@TransactionDate,
								GETUTCDATE(),@JournalTypeId ,@JournalTypename, 
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @TotalTax ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalTax END,@ManagementStructureId,
								@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,
								GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);

					-----  RECONCILIATION PO TAX INV  -----	
					
					IF(@TaxInvCost > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId], 
									 @GlAccountNumber = [GlAccountNumber], 
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER(DistributionSetupCode) = UPPER('RECPOTAXINV') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@TaxInvCost),2)  ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE ROUND((@TaxInvCost),2) END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
									
						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END
					
					-------  RECONCILIATION VARIABLE COGS  --------

					IF(@TaxInvCogs > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId=[ID], 
									 @DistributionName=[Name], 
									 @JournalTypeId=[JournalTypeId], 
									 @GlAccountId=[GlAccountId], 
									 @GlAccountNumber=[GlAccountNumber], 
									 @GlAccountName=[GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER([DistributionSetupCode])=UPPER('RECPOVARCOGS') 
								AND  [DistributionMasterId] = @DistributionMasterId 
								AND  [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,								
									CASE WHEN @CrDrType = 1 THEN 0 ELSE 1 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE  ROUND((@TaxInvCogs),2) END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@TaxInvCogs),2) ELSE 0 END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);
													
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END	
				END							   

				IF(@TotalMisc > 0) 
				BEGIN
					SELECT TOP 1 @DistributionSetupId = [ID], 
							 @DistributionName = [Name], 
							 @JournalTypeId = [JournalTypeId], 
							 @GlAccountId = [GlAccountId], 
							 @GlAccountNumber = [GlAccountNumber], 
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType]
					   FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					 WHERE UPPER([DistributionSetupCode]) = UPPER('RECPOACCPAYABLE') 
					 AND [DistributionMasterId] = @DistributionMasterId 
					 AND [MasterCompanyId] = @MasterCompanyId;
					 
					INSERT INTO [dbo].[CommonBatchDetails]
					           ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
							    [JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
								[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],
								[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
						        @JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0),@GlAccountNumber ,@GlAccountName,@TransactionDate,
								GETUTCDATE(),@JournalTypeId ,@JournalTypename, 
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @TotalMisc ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalMisc END,@ManagementStructureId,
								@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,
								GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);

					--- MISC VAR COGS-----
					SELECT TOP 1 @DistributionSetupId=[ID], 
									 @DistributionName=[Name], 
									 @JournalTypeId=[JournalTypeId], 
									 @GlAccountId=[GlAccountId], 
									 @GlAccountNumber=[GlAccountNumber], 
									 @GlAccountName=[GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER([DistributionSetupCode])=UPPER('RECPOVARCOGS') 
								AND  [DistributionMasterId] = @DistributionMasterId 
								AND  [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@MiscGLId,@MiscGlAccountNumber,@MISCGlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,								
									CASE WHEN @CrDrType = 1 THEN 0 ELSE 1 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE  @TotalMisC END,
									CASE WHEN @CrDrType = 1 THEN @TotalMisc ELSE 0 END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);
													
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
				END
							   				 
				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit = SUM([DebitAmount]),
				       @TotalCredit= SUM([CreditAmount]) 
				  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
				 WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
				 GROUP BY JournalBatchDetailId
				
				UPDATE [dbo].[BatchDetails] 
				   SET [DebitAmount] = @TotalDebit,
				       [CreditAmount] = @TotalCredit,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdateBy   
				 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;
				
				UPDATE [dbo].[CodePrefixes] 
				   SET [CurrentNummber] = @currentNo
				 WHERE [CodeTypeId] = @CodeTypeId 
				   AND [MasterCompanyId] = @MasterCompanyId;   
			END

			IF(UPPER(@ModuleName) = UPPER('ReconciliationRO') AND (@TotalFreight > 0 OR @TotalTax > 0 OR @TotalMisc > 0))
			BEGIN
				SELECT @LastMSLevel = [LastMSLevel], 
					   @AllMSlevels = [AllMSlevels],
					   @ManagementStructureId = [EntityMSID]
				 FROM [dbo].[EmployeeManagementStructureDetails] WITH(NOLOCK)
				WHERE [ReferenceID] = @EmployeeId 
				  AND [ModuleID] = @EMPMSModuleID;
			
				INSERT INTO [dbo].[BatchDetails]
				           ([JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName], [JournalBatchHeaderId], 
						    [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate],
							[JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], 
							[ModuleName], [LastMSLevel], [AllMSlevels], 
							[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], 
							[UpdatedDate], [IsActive], [IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					 VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 
					        1, 0, NULL, NULL, @TransactionDate, GETUTCDATE(), 
							@jlTypeId, @jlTypeName, 1, 0, 0, @ManagementStructureId, 
							@INPUTMethod,@LastMSLevel ,@AllMSlevels, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), 
							GETUTCDATE(), 1, 0,	@AccountingPeriodId, @AccountingPeriod)

				SET @JournalBatchDetailId = SCOPE_IDENTITY();

				----- RECONCILIATION RO ACCPAYABLE -----				

				SELECT TOP 1 @DistributionSetupId = [ID], 
							 @DistributionName = [Name], 
							 @JournalTypeId = [JournalTypeId], 
							 @GlAccountId = [GlAccountId], 
							 @GlAccountNumber = [GlAccountNumber], 
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType]
					   FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					 WHERE UPPER([DistributionSetupCode]) = UPPER('RECROACCPAYABLE') 
					 AND [DistributionMasterId] = @DistributionMasterId 
					 AND [MasterCompanyId] = @MasterCompanyId;
					 
				IF(@TotalFreight > 0)
				BEGIN
					INSERT INTO [dbo].[CommonBatchDetails]
					           ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
							    [JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
								[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],
								[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
						        @JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0),@GlAccountNumber ,@GlAccountName,@TransactionDate,
								GETUTCDATE(),@JournalTypeId ,@JournalTypename, 
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @TotalFreight ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalFreight END,@ManagementStructureId,
								@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,
								GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
							
					-----  RECONCILIATION PO FREIGHT INV  -----							
					
					IF(@FreightInvCost > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId], 
									 @GlAccountNumber = [GlAccountNumber], 
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER(DistributionSetupCode) = UPPER('RECROFREIGHTINV') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@FreightInvCost),2)  ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE ROUND((@FreightInvCost),2) END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
									
						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END
					-------  RECONCILIATION VARIABLE COGS  --------

					IF(@FreightInvCogs > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId=[ID], 
									 @DistributionName=[Name], 
									 @JournalTypeId=[JournalTypeId], 
									 @GlAccountId=[GlAccountId], 
									 @GlAccountNumber=[GlAccountNumber], 
									 @GlAccountName=[GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER([DistributionSetupCode])=UPPER('RECROVARCOGS') 
								AND  [DistributionMasterId] = @DistributionMasterId 
								AND  [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,								
									CASE WHEN @CrDrType = 1 THEN 0 ELSE 1 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE  ROUND((@FreightInvCogs),2) END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@FreightInvCogs),2) ELSE 0 END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);
													
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END			
				END		

				IF(@TotalTax > 0)
				BEGIN 
					SELECT TOP 1 @DistributionSetupId = [ID], 
							 @DistributionName = [Name], 
							 @JournalTypeId = [JournalTypeId], 
							 @GlAccountId = [GlAccountId], 
							 @GlAccountNumber = [GlAccountNumber], 
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType]
					   FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					 WHERE UPPER([DistributionSetupCode]) = UPPER('RECROACCPAYABLE') 
					 AND [DistributionMasterId] = @DistributionMasterId 
					 AND [MasterCompanyId] = @MasterCompanyId;

					 INSERT INTO [dbo].[CommonBatchDetails]
					           ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
							    [JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
								[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],
								[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
						        @JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0),@GlAccountNumber ,@GlAccountName,@TransactionDate,
								GETUTCDATE(),@JournalTypeId ,@JournalTypename, 
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @TotalTax ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalTax END,@ManagementStructureId,
								@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,
								GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);

					-----  RECONCILIATION RO TAX INV  -----		

					IF(@TaxInvCost > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId], 
									 @GlAccountNumber = [GlAccountNumber], 
									 @GlAccountName = [GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER(DistributionSetupCode) = UPPER('RECROTAXINV') 
								 AND [DistributionMasterId] = @DistributionMasterId 
								 AND [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,
									CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@TaxInvCost),2)  ELSE 0 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE ROUND((@TaxInvCost),2) END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
									
						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END
					
					-------  RECONCILIATION VARIABLE COGS  --------

					IF(@TaxInvCogs > 0)
					BEGIN
						SELECT TOP 1 @DistributionSetupId=[ID], 
									 @DistributionName=[Name], 
									 @JournalTypeId=[JournalTypeId], 
									 @GlAccountId=[GlAccountId], 
									 @GlAccountNumber=[GlAccountNumber], 
									 @GlAccountName=[GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER([DistributionSetupCode])=UPPER('RECROVARCOGS') 
								AND  [DistributionMasterId] = @DistributionMasterId 
								AND  [MasterCompanyId] = @MasterCompanyId;

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@GlAccountId,@GlAccountNumber,@GlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,								
									CASE WHEN @CrDrType = 1 THEN 0 ELSE 1 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE  ROUND((@TaxInvCogs),2) END,
									CASE WHEN @CrDrType = 1 THEN ROUND((@TaxInvCogs),2) ELSE 0 END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);
													
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
					END	
				END

				IF(@TotalMisc > 0)
				BEGIN
					SELECT TOP 1 @DistributionSetupId = [ID], 
							 @DistributionName = [Name], 
							 @JournalTypeId = [JournalTypeId], 
							 @GlAccountId = [GlAccountId], 
							 @GlAccountNumber = [GlAccountNumber], 
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType]
					   FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					 WHERE UPPER([DistributionSetupCode]) = UPPER('RECROACCPAYABLE') 
					 AND [DistributionMasterId] = @DistributionMasterId 
					 AND [MasterCompanyId] = @MasterCompanyId;

					 INSERT INTO [dbo].[CommonBatchDetails]
					           ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
							    [JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
								[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],[ManagementStructureId],
								[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],[UpdatedBy],
								[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
						        @JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0),@GlAccountNumber ,@GlAccountName,@TransactionDate,
								GETUTCDATE(),@JournalTypeId ,@JournalTypename, 
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @TotalMisc ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalMisc END,@ManagementStructureId,
								@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,
								GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);

				    -------  RECONCILIATION VARIABLE COGS  --------

					SELECT TOP 1 @DistributionSetupId=[ID], 
									 @DistributionName=[Name], 
									 @JournalTypeId=[JournalTypeId], 
									 @GlAccountId=[GlAccountId], 
									 @GlAccountNumber=[GlAccountNumber], 
									 @GlAccountName=[GlAccountName],
									 @CrDrType = [CRDRType]
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
							   WHERE UPPER([DistributionSetupCode])=UPPER('RECROVARCOGS') 
								AND  [DistributionMasterId] = @DistributionMasterId 
								AND  [MasterCompanyId] = @MasterCompanyId;

					INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],
									[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
									[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
									[ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[ReferenceId])
							VALUES (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,
									@JournalBatchHeaderId,1,@MiscGLId,@MiscGlAccountNumber,@MISCGlAccountName,@TransactionDate,										
									GETUTCDATE(),@JournalTypeId,@JournalTypename,								
									CASE WHEN @CrDrType = 1 THEN 0 ELSE 1 END,
									CASE WHEN @CrDrType = 1 THEN 0 ELSE @TotalMisc END,
									CASE WHEN @CrDrType = 1 THEN @TotalMisc ELSE 0 END,
									@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId, @UpdateBy,
									@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId);
													
						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
						
						INSERT INTO [dbo].[StocklineBatchDetails]
					           ([JournalBatchDetailId],[JournalBatchHeaderId],[VendorId],[VendorName],[ItemMasterId],[PartId],[PartNumber]
							   ,[PoId],[PONum],[RoId],[RONum],[StocklineId],[StocklineNumber],[Consignment],[Description],[SiteId]
							   ,[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType]
							   ,[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					     VALUES(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,NULL,NULL,NULL,
						        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
								NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@StockType,
								@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber);
				END

				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit = SUM([DebitAmount]),
				       @TotalCredit= SUM([CreditAmount]) 
				  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
				 WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
				 GROUP BY JournalBatchDetailId
				
				UPDATE [dbo].[BatchDetails] 
				   SET [DebitAmount] = @TotalDebit,
				       [CreditAmount] = @TotalCredit,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdateBy   
				 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;
				
				UPDATE [dbo].[CodePrefixes] 
				   SET [CurrentNummber] = @currentNo
				 WHERE [CodeTypeId] = @CodeTypeId 
				   AND [MasterCompanyId] = @MasterCompanyId;    				
				
			END

			IF OBJECT_ID(N'tempdb..#RRFreightAndTaxPostType') IS NOT NULL
			BEGIN
					DROP TABLE #RRFreightAndTaxPostType 
			END

	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'		
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_PostReceivingReconcilationFreightAndTaxBatchDetails' 		
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReceivingReconciliationId, '') AS VARCHAR(100))  
		, @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		exec spLogException 
		@DatabaseName           = @DatabaseName
		, @AdhocComments          = @AdhocComments
		, @ProcedureParameters = @ProcedureParameters
		, @ApplicationName        =  @ApplicationName
		, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END