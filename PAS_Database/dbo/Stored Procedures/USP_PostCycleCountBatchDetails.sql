/*************************************************************           
 ** File: [dbo].[USP_PostCycleCountBatchDetails]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used create cycle count batch Details 
 ** Purpose:         
 ** Date:  12/11/2024
 ** PARAMETERS:      
 ** RETURN VALUE:    
 **********************************************************************           
  ** Change History           
 **********************************************************************           
 ** PR   Date				 Author					Change Description            
 ** --   --------			-------				-----------------------
	1    12/11/2024          Moin Bloch          Created   
	2    13/11/2024          Moin Bloch          Added IsReversedJE Flag
	3    19/11/2024          Moin Bloch          Added @AccountingCalendarId,@LedgerId 
	4    20/11/2024          Moin Bloch          Fixe Entry @AccountingCalendarId Wise 
	5    05/12/2024          Moin Bloch          Added @IsAccountByPass Flag
	6    27/12/2024          Moin Bloch          Updated Added LegalEntityId
	7    31/01/2025          AMIT GHEDIYA        Modify(get Distribution based on new settings from stockline level)
	8    28/11/2025          Moin Bloch          Changed Logic For CR/DR
	9    09/July/2026          RAJESH GAMI          [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	10	 07/07/2026	         Moin Bloch          Modify (Added IsBypassAccounting Flag to bypass Accounting Entry PN-16871)
    EXEC [dbo].[USP_PostCycleCountBatchDetails] 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_PostCycleCountBatchDetails]
@CycleCountId BIGINT,
@CycleCountDetailId BIGINT,
@StockLineId BIGINT,
@DifferenceAmount DECIMAL(18,2),
@LegalEntityId  BIGINT,
@LedgerId BIGINT,
@AccountingCalendarId BIGINT,
@UpdatedBy VARCHAR(50),
@MasterCompanyId INT
AS
BEGIN 
	BEGIN TRY
		DECLARE @CodeTypeId AS BIGINT; 
		SET @CodeTypeId = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = 'JOURNALTYPE');		
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @DistributionMasterId BIGINT;    
		DECLARE @DistributionCode VARCHAR(200); 
		DECLARE @StatusId INT;    
		DECLARE @StatusName VARCHAR(200);    
		DECLARE @AccountingPeriod VARCHAR(100);    
		DECLARE @JournalTypeId INT;    
		DECLARE @JournalTypeCode VARCHAR(200);
		DECLARE @JournalBatchHeaderId BIGINT;    
		DECLARE @JournalTypename VARCHAR(200);  
		DECLARE @batch VARCHAR(100);    
		DECLARE @Currentbatch VARCHAR(100);    
		DECLARE @CurrentNumber INT;    
		DECLARE @CurrentPeriodId BIGINT=0; 
		DECLARE @LineNumber INT=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId INT=0
		DECLARE @Distributionname VARCHAR(200) 
		DECLARE @GlAccountId INT
		DECLARE @GlAccountName VARCHAR(200) 
		DECLARE @GlAccountNumber VARCHAR(200) 
		DECLARE @TotalAmount DECIMAL(18,2) = 0;
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(max)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit DECIMAL(18, 2) = 0;
		DECLARE @TotalCredit DECIMAL(18, 2) = 0;
		DECLARE @TotalBalance DECIMAL(18, 2) = 0;
		DECLARE @CRDRType BIGINT = 0;
		DECLARE @ItemMasterId BIGINT=NULL;	
		DECLARE @PartNumber VARCHAR(50) = '';
		DECLARE @CycleCountNumber VARCHAR(50) = '';
		DECLARE @StockLineNumber VARCHAR(50) = '';
		DECLARE @SiteId BIGINT;
		DECLARE @Site VARCHAR(100) ='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse VARCHAR(100) ='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location VARCHAR(100) ='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin VARCHAR(100) ='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf VARCHAR(100) ='';
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @IsBypassAccounting BIT = 0;
		DECLARE @LocalCurrencyCode VARCHAR(20) = '';
		DECLARE @ForeignCurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1
		DECLARE @ReferenceModule VARCHAR(100) = 'CycleCount';
		DECLARE @JEflag BIT = 0;
		DECLARE @InventoryGLAccId BIGINT = 0;
		
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

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
		SELECT @DistributionCode = [DistributionCode] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode]) = UPPER('CYCLECOUNTADJUSTMENT');						

		SET @TotalAmount = @DifferenceAmount; 
		
		DECLARE @IsAccountByPass BIT;
		DECLARE @IsRestrict BIT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdatedBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

		IF(ISNULL(@IsAccountByPass, 0) = 0)
		BEGIN		
			IF(ISNULL(@TotalAmount,0) <> 0)
			BEGIN				
				SELECT @DistributionMasterId = [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode]) = UPPER('CYCLECOUNTADJUSTMENT');						
				SELECT @StatusId = [Id],@StatusName = [name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE UPPER([Name]) = UPPER('Open');			
				SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId;					
				SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;						
				SELECT @JournalTypeCode = [JournalTypeCode],@JournalTypename = [JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK) WHERE [ID] = @JournalTypeId;				
				SELECT @ModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'Stockline'
	
				SELECT @ItemMasterId = CC.[ItemMasterId],
					   @PartNumber = CC.[PartNumber],
					   @StockLineNumber = CC.[StockLineNumber],
					   @CycleCountNumber = CL.[CycleCountNumber],
					   @ManagementStructureId = CC.[ManagementStructureId], 				   	       
					   @SiteId = CC.[SiteId], 
					   @Site= CC.[Site], 
					   @WarehouseId= CC.[WarehouseId], 
					   @Warehouse = CC.[Warehouse],
					   @LocationId = CC.[LocationId], 
					   @Location= CC.[Location],  
					   @BinId= CC.[BinId],
					   @Bin= CC.[Bin], 
					   @ShelfId = CC.[ShelfId], 
					   @Shelf = CC.[Shelf], 		
					   @LastMSLevel = MS.[LastMSLevel],
					   @AllMSlevels = MS.[AllMSlevels]
				 FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)
				 INNER JOIN [dbo].[CycleCount] CL WITH(NOLOCK) ON CC.[CycleCountId] = CL.[CycleCountId]
				 LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ModuleID] = @ModuleID AND MS.[ReferenceID] = CC.StockLineId 
		 		 WHERE CC.[CycleCountDetailId] = @CycleCountDetailId;
				
				INSERT INTO #tmpCodePrefixes ([CodePrefixId],[CodeTypeId],[CurrentNumber],[CodePrefix],[CodeSufix],[StartsFrom]) 
					   SELECT CP.[CodePrefixId],CP.[CodeTypeId],CP.[CurrentNummber],CP.[CodePrefix],CP.[CodeSufix],CP.[StartsFrom]
						FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) 
						JOIN [dbo].[CodeTypes] CT WITH(NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
						WHERE CT.CodeTypeId IN (@CodeTypeId) 
						  AND CP.[MasterCompanyId] = @MasterCompanyId 
						  AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;

				SELECT @AccountingPeriod = [PeriodName] 			         
					 FROM [dbo].[AccountingCalendar] acc WITH(NOLOCK)
					WHERE acc.[AccountingCalendarId] = @AccountingCalendarId AND acc.[MasterCompanyId] = @MasterCompanyId  			     
							
				IF NOT EXISTS(SELECT 1 FROM [dbo].[CycleCountBatchDetails] WITH(NOLOCK) WHERE [ReferenceId] = @CycleCountId AND [MasterCompanyId] = @MasterCompanyId)
				BEGIN
					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
					BEGIN 
						SET @JEflag = 1;
						SELECT @currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
						  FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
						SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					END
					ELSE 
					BEGIN
						SET @JEflag = 1;
						ROLLBACK TRAN;
					END
				END
				ELSE
				BEGIN
						SET @JEflag = 0;
						SELECT TOP 1 @currentNo = [CurrentNumber], @JournalTypeNumber = [JournalTypeNumber], @JournalBatchDetailId = [JournalBatchDetailId]	FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
						 WHERE [ReferenceId] = @CycleCountId AND [ReferenceNumber] = @CycleCountNumber AND [ReferenceModule] = @ReferenceModule AND [MasterCompanyId] = @MasterCompanyId
				END			
				IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId]=@MasterCompanyId AND [AccountingPeriodId] = @AccountingCalendarId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId]=@StatusId)
				BEGIN
					IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
					BEGIN  
						SET @batch ='001'  
						SET @Currentbatch='001' 
					END
					ELSE
					BEGIN 
						SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END   
						  FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId desc  

						IF(CAST(@Currentbatch AS BIGINT) >99)  
						BEGIN
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
											  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) 
										  END   
						END  
						ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
						BEGIN    
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
											  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) 
										  END   
						END
						ELSE
						BEGIN
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
											  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) 
										  END     
						END  
					END
			
					SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)    
				
					SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))  

					INSERT INTO [dbo].[BatchHeader]    
							   ([BatchName],
								[CurrentNumber],
								[EntryDate],
								[AccountingPeriod],
								[AccountingPeriodId],
								[StatusId],[StatusName],
								[JournalTypeId],
								[JournalTypeName],
								[TotalDebit],
								[TotalCredit],
								[TotalBalance],
								[MasterCompanyId],
								[CreatedBy],
								[UpdatedBy],
								[CreatedDate],
								[UpdatedDate],
								[IsActive],
								[IsDeleted],
								[Module])    
						 VALUES    
							   (@batch,
								@CurrentNumber,
								GETUTCDATE(),
								@AccountingPeriod,
								@AccountingCalendarId,
								@StatusId,
								@StatusName,
								@JournalTypeId,
								@JournalTypename,
								0,
								0,
								0,
								@MasterCompanyId,
								@UpdatedBy,
								@UpdatedBy,
								GETUTCDATE(),
								GETUTCDATE(),
								1,
								0,
								'CycleCount');    
                           
					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();   
				
					UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;  			
				END
				ELSE
				BEGIN 
					SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],@CurrentPeriodId = ISNULL([AccountingPeriodId],0) FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [AccountingPeriodId] = @AccountingCalendarId AND [JournalTypeId]= @JournalTypeId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId]=@StatusId   
				
					SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END   
					  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
					 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
					 ORDER BY [JournalBatchDetailId] DESC   
          
					IF(@CurrentPeriodId =0)  
					BEGIN  
					   UPDATE [dbo].[BatchHeader] SET [AccountingPeriodId]=@AccountingCalendarId,[AccountingPeriod]=@AccountingPeriod WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  
					END  

					SET @IsBatchGenerated = 1;
				END
						
				IF NOT EXISTS(SELECT TOP 1 BD.[JournalBatchHeaderId] FROM [dbo].[BatchDetails] BD WITH(NOLOCK) 
				INNER JOIN [dbo].[CommonBatchDetails] CD WITH(NOLOCK) ON BD.[JournalBatchHeaderId] = CD.[JournalBatchHeaderId]
				WHERE BD.[JournalBatchHeaderId] = @JournalBatchHeaderId AND CD.[ReferenceId] = @CycleCountId AND BD.[MasterCompanyId] = @MasterCompanyId)
				BEGIN
					INSERT INTO [dbo].[BatchDetails]
						   ([JournalTypeNumber],
							[CurrentNumber],
							[DistributionSetupId],
							[DistributionName],
							[JournalBatchHeaderId], 
							[LineNumber], 
							[GlAccountId], 
							[GlAccountNumber], 
							[GlAccountName], 
							[TransactionDate], 
							[EntryDate], 
							[JournalTypeId], 
							[JournalTypeName], 
							[IsDebit], 
							[DebitAmount], 
							[CreditAmount], 
							[ManagementStructureId], 
							[ModuleName], 
							[LastMSLevel], 
							[AllMSlevels], 
							[MasterCompanyId], 
							[CreatedBy], 
							[UpdatedBy], 
							[CreatedDate], 
							[UpdatedDate], 
							[IsActive], 
							[IsDeleted],
							[AccountingPeriodId],
							[AccountingPeriod],
							[IsReversedJE])
					 VALUES(@JournalTypeNumber,
							@currentNo,
							0, 
							NULL, 
							@JournalBatchHeaderId, 
							1, 
							0, 
							NULL, 
							NULL, 
							GETUTCDATE(), 
							GETUTCDATE(), 
							@JournalTypeId, 
							@JournalTypename, 
							1, 
							0, 
							0, 
							@ManagementStructureId, 
							'CycleCount', 
							@LastMSLevel, 
							@AllMSlevels, 
							@MasterCompanyId, 
							@UpdatedBy, 
							@UpdatedBy, 
							GETUTCDATE(), 
							GETUTCDATE(), 
							1, 
							0,
							@AccountingCalendarId,
							@AccountingPeriod,
							0
							)
		
					SET @JournalBatchDetailId = SCOPE_IDENTITY();			
				END

				----- COGS-CYCLE COUNT--------

				SELECT TOP 1 @DistributionSetupId = [ID],
							 @DistributionName = [Name],
							 @JournalTypeId = [JournalTypeId], 
							 @CRDRType = [CRDRType],
							 @GlAccountId = [GlAccountId],
							 @GlAccountNumber = [GlAccountNumber],
							 @GlAccountName = [GlAccountName] ,
							 @IsAutoPost = ISNULL(IsAutoPost,0),
							 @IsBypassAccounting = ISNULL(IsBypassAccounting,0)
						FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
						WHERE UPPER([DistributionSetupCode]) = UPPER('COGSCYCLECOUNT') 
						 AND [DistributionMasterId] = @DistributionMasterId;

				IF(@IsBypassAccounting = 0)
				BEGIN
					 
				INSERT INTO [dbo].[CommonBatchDetails]([JournalBatchDetailId],[JournalTypeNumber],
							 [CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],
							 [LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],
							 [EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
							 [ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],
							 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
							 [ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],
							 [ReferenceId],[ReferenceModule])
					  VALUES	
							(@JournalBatchDetailId,@JournalTypeNumber,
							 @currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,
							 1,@GlAccountId,@GlAccountNumber,@GlAccountName,GETUTCDATE(),
							 GETUTCDATE(),@JournalTypeId,@JournalTypename,
							 --CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
							 --CASE WHEN @CRDRType = 1 THEN @TotalAmount ELSE 0 END,
							 --CASE WHEN @CRDRType = 1 THEN 0 ELSE @TotalAmount END,
							 --CASE WHEN @TotalAmount > 0 THEN 1 ELSE 0 END,
							 --CASE WHEN @TotalAmount > 0 THEN @TotalAmount ELSE 0 END,
							 --CASE WHEN @TotalAmount > 0 THEN 0 ELSE ABS(@TotalAmount) END,
							 CASE WHEN @TotalAmount > 0 THEN 0 ELSE 1 END,
							 CASE WHEN @TotalAmount > 0 THEN 0  ELSE ABS(@TotalAmount) END,
							 CASE WHEN @TotalAmount > 0 THEN @TotalAmount ELSE 0 END,
							 @ManagementStructureId,'CycleCount',@LastMSLevel,@AllMSlevels,@MasterCompanyId,
							 @UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,
							 @CycleCountNumber,@StockLineNumber,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,
							 @CycleCountId ,@ReferenceModule)

				SET @CommonBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
			 
				INSERT INTO [dbo].[CycleCountBatchDetails]([JournalBatchHeaderId],[JournalBatchDetailId]
							,[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[ItemMasterId]
							,[PartNumber],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId]
							,[Location],[BinId],[Bin],[ShelfId],[Shelf],[ReferenceId],[ReferenceNumber]
							,[ReferenceDetailId],[MasterCompanyId],[LegalEntityId],[LedgerId],[AccountingCalendarId])
					  VALUES(@JournalBatchHeaderId,@JournalBatchDetailId 
							,@CommonBatchDetailId,@StockLineId,@StockLineNumber,@ItemMasterId
							,@PartNumber,@SiteId,@Site,@WarehouseId,@Warehouse, @LocationId   
							,@Location,@BinId,@Bin,@ShelfId,@Shelf,@CycleCountId,@CycleCountNumber
							,@CycleCountDetailId,@MasterCompanyId,@LegalEntityId,@LedgerId,@AccountingCalendarId);

				END
			 
				----- Inventory - Stock--------		  	 

				SELECT TOP 1 @DistributionSetupId = [ID],
							 @DistributionName = [Name],
							 @JournalTypeId = [JournalTypeId], 
							 @CRDRType = [CRDRType],
							 @GlAccountId = [GlAccountId],
							 @GlAccountNumber = [GlAccountNumber],
							 @GlAccountName = [GlAccountName], 
							 @IsBypassAccounting = ISNULL(IsBypassAccounting,0)
						FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
						WHERE UPPER([DistributionSetupCode]) = UPPER('INVENTORYCYCLECOUNT') 
						 AND [DistributionMasterId] = @DistributionMasterId;

				 --GET STOCKLINE GLACCOUNT.
				 SELECT @InventoryGLAccId = SL.GLAccountId -- For PARTS INVENTORY Distribution.
				    FROM [dbo].[Stockline] SL WITH(NOLOCK)					 
				    WHERE SL.[StockLineId] = @StocklineId;
				 
				 --GET GL Accounting Data from GLAccout based on stockline
				 SELECT @GlAccountId = [GLAccountId],
				 	    @GlAccountNumber = [AccountCode],
				 	    @GlAccountName = [AccountName]
				 FROM [dbo].[GLAccount] WITH(NOLOCK)
				 WHERE [GLAccountId] = @InventoryGLAccId
				 AND [MasterCompanyId] = @MasterCompanyId; 

				 IF(@IsBypassAccounting = 0)
				 BEGIN

				 INSERT INTO [dbo].[CommonBatchDetails]([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],
							 [DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],
							 [GlAccountId],[GlAccountNumber],[GlAccountName],[TransactionDate],[EntryDate],
							 [JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount],[CreditAmount],
							 [ManagementStructureId],[ModuleName],[LastMSLevel],[AllMSlevels],[MasterCompanyId],
							 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
							 [ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],
							 [ReferenceId],[ReferenceModule])
					  VALUES	
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,
							 @DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1,
							 @GlAccountId,@GlAccountNumber,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
							 @JournalTypeId,@JournalTypename,						
							 --CASE WHEN @TotalAmount > 0 THEN 0 ELSE 1 END,
							 --CASE WHEN @TotalAmount > 0 THEN 0 ELSE ABS(@TotalAmount) END,
							 --CASE WHEN @TotalAmount > 0 THEN @TotalAmount ELSE 0 END,	
							 CASE WHEN @TotalAmount > 0 THEN 1 ELSE 0 END,
							 CASE WHEN @TotalAmount > 0 THEN @TotalAmount ELSE 0 END,
							 CASE WHEN @TotalAmount > 0 THEN 0 ELSE ABS(@TotalAmount) END,
							 @ManagementStructureId,'CycleCount',@LastMSLevel,@AllMSlevels,@MasterCompanyId,
							 @UpdatedBy,@UpdatedBy, GETUTCDATE(),GETUTCDATE(),1,0,
							 @CycleCountNumber,@StockLineNumber,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,
							 @CycleCountId ,@ReferenceModule)

				 SET @CommonBatchDetailId = SCOPE_IDENTITY()
			 		
				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@AccountMSModuleId,1; 
			
				INSERT INTO [dbo].[CycleCountBatchDetails]([JournalBatchHeaderId],[JournalBatchDetailId]
							,[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[ItemMasterId]
							,[PartNumber],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId]
							,[Location],[BinId],[Bin],[ShelfId],[Shelf],[ReferenceId],[ReferenceNumber]
							,[ReferenceDetailId],[MasterCompanyId],[LegalEntityId],[LedgerId],[AccountingCalendarId])
					  VALUES(@JournalBatchHeaderId,@JournalBatchDetailId 
							,@CommonBatchDetailId,@StockLineId,@StockLineNumber,@ItemMasterId
							,@PartNumber,@SiteId,@Site,@WarehouseId,@Warehouse, @LocationId   
							,@Location,@BinId,@Bin,@ShelfId,@Shelf,@CycleCountId,@CycleCountNumber
							,@CycleCountDetailId,@MasterCompanyId,@LegalEntityId,@LedgerId,@AccountingCalendarId);

				 END
						
				 -----Inventory - Stock--------

				SET @TotalDebit = 0;
				SET @TotalCredit = 0;

				SELECT @TotalDebit = ISNULL(SUM([DebitAmount]),0),
					   @TotalCredit = ISNULL(SUM([CreditAmount]),0) 
				  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
				 WHERE [JournalBatchDetailId] = @JournalBatchDetailId GROUP BY [JournalBatchDetailId];

				UPDATE [dbo].[BatchDetails] 
				   SET [DebitAmount] = @TotalDebit,
					   [CreditAmount] = @TotalCredit,
					   [UpdatedDate] = GETUTCDATE(),
					   [UpdatedBy] = @UpdatedBy
				 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;
			END
				
			SELECT @TotalDebit = ISNULL(SUM([DebitAmount]),0),
				   @TotalCredit = ISNULL(SUM([CreditAmount]),0) 
			  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
			 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [IsDeleted] = 0 

			SET @TotalBalance = (@TotalDebit - @TotalCredit);
		
			IF(@JEflag = 1)
			BEGIN
				UPDATE [dbo].[CodePrefixes] 
				   SET [CurrentNummber] = @currentNo 
				 WHERE [CodeTypeId] = @CodeTypeId 
				   AND [MasterCompanyId] = @MasterCompanyId;		
			END

			UPDATE [dbo].[BatchHeader] 
			   SET [TotalDebit] = @TotalDebit,
				   [TotalCredit] = @TotalCredit,
				   [TotalBalance] = @TotalBalance,
				   [UpdatedDate] = GETUTCDATE(),
				   [UpdatedBy] = @UpdatedBy 
			 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;
		END
		 ----AutoPost Batch
		 --IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
		 --BEGIN
			-- EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdatedBy;
		 --END
		 --IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
		 --BEGIN
			-- EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdatedBy,@AccountingCalendarId,@AccountingPeriod;
		 --END
		 		 
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_PostCycleCountBatchDetails'               
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CycleCountId, '') AS VARCHAR(100))  
        , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END