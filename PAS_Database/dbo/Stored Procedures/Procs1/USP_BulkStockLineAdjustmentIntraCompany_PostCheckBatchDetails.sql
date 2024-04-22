/*************************************************************           
 ** File:   [USP_BulkStockLineAdjustmentIntraCompany_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used insert account report in batch from BulkStockLineAdjustment Intra Company.
 ** Purpose:         
 ** Date:   30/10/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    30/10/2023   Amit Ghediya	  Created	
	2    22/11/2023   Moin Bloch	  Modified Added MS Accounting Id	
	3    24/11/2023   Moin Bloch	Modified Added [ReferenceId]
	4	 01/03/2024   Bhargav Saliya Updates "UpdatedDate" and "UpdatedBy" When Update the Stockline
	5    26/03/2024   Abhishek Jirawla Removing Reserved quantity saved at the time of bulk stockline adjustment.
	6	 16/04/2024   Amit Ghediya     Updates memo text.

EXEC USP_BulkStockLineAdjustmentIntraCompany_PostCheckBatchDetails 1,1,'adminUser',2,1
     
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_BulkStockLineAdjustmentIntraCompany_PostCheckBatchDetails]
(
	@BulkStkLineAdjHeaderId BIGINT,
	@MasterCompanyId INT,
	@UpdateBy VARCHAR(100),
	@EmployeeId BIGINT,
	@ManagementStructureIds BIGINT
)
AS
BEGIN 
	BEGIN TRY
		
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @DistributionMasterId bigint;    
		DECLARE @DistributionCode varchar(200); 
		DECLARE @CurrentManagementStructureId bigint=0; 
		DECLARE @StatusId int;    
		DECLARE @StatusName varchar(200);    
		DECLARE @AccountingPeriod varchar(100);    
		DECLARE @AccountingPeriodId bigint=0;   
		DECLARE @JournalTypeId int;    
		DECLARE @JournalTypeCode varchar(200);
		DECLARE @JournalBatchHeaderId bigint;    
		DECLARE @JournalTypename varchar(200);  
		DECLARE @batch varchar(100);    
		DECLARE @Currentbatch varchar(100);    
		DECLARE @CurrentNumber int;    
		DECLARE @CurrentPeriodId bigint=0; 
		DECLARE @LineNumber int=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId int=0;
		DECLARE @Distributionname varchar(200); 
		DECLARE @GlAccountId int;
		DECLARE @StartsFrom varchar(200)='00';
		DECLARE @GlAccountName varchar(200);
		DECLARE @GlAccountNumber varchar(200); 
		DECLARE @ExtAmount DECIMAL(18,2);
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId BIGINT;
		DECLARE @BlkManagementStructureId BIGINT;
		DECLARE @FromManagementStructureId BIGINT;
		DECLARE @ToManagementStructureId BIGINT;
		DECLARE @LastMSLevel varchar(200);
		DECLARE @AllMSlevels varchar(max);
		DECLARE @ModuleId INT;
		DECLARE @TotalDebit decimal(18, 2) =0;
		DECLARE @TotalCredit decimal(18, 2) =0;
		DECLARE @TotalBalance decimal(18, 2) =0;
		DECLARE @ExtNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @ExtDate Datetime;
		DECLARE @stklineId BIGINT;
		DECLARE @DistributionCodeName VARCHAR(100);
		DECLARE @CrDrType int=0;
		DECLARE @CodePrefix VARCHAR(50);
		DECLARE @qtyAdjustment INT;
		DECLARE @newqty INT;
		DECLARE @Amount DECIMAL(18, 2) =0;
		DECLARE @MasterLoopID INT;
		DECLARE @BulkStockLineAdjustmentDetailsId BIGINT;
		DECLARE @AdjustmentAmount DECIMAL(18, 2) =0;
		DECLARE @QuantityOnHand DECIMAL(18,2);
		DECLARE @QuantityReserved DECIMAL(18,2);
		DECLARE @QuantityAvailable DECIMAL(18,2);
		DECLARE @tmpFreightAdjustment DECIMAL(18,2);
		DECLARE @tmpTaxAdjustment DECIMAL(18,2);
		DECLARE @Adjustment DECIMAL(18,2);
		DECLARE @StockLineId BIGINT;
		DECLARE @BulkStatusId int;    
		DECLARE @BulkStatusName varchar(200);  
		DECLARE @BlkModuleID  BIGINT;
		DECLARE @DetailUnitCostAdjustment DECIMAL(18,2);
		DECLARE @Memo VARCHAR(MAX);
	
		SET @DistributionCodeName = 'BulkStockLineAdjustmentINTRACOTRANSDIV';

		SELECT @BlkModuleID = ModuleId FROM Module WHERE CodePrefix='BSTKADJ';
		
		SELECT @BulkStatusId = Id, @BulkStatusName = Name FROM [dbo].[StocklineAdjustmentStatus] WITH(NOLOCK) WHERE Name = 'Posted';
				
	    DECLARE @AccountModuleId INT = 0;
		SELECT @AccountModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		
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
		
		SELECT @Amount = SUM(ISNULL(ABS(AdjustmentAmount),0))
		FROM [DBO].[BulkStockLineAdjustmentDetails] WITH(NOLOCK) 
		WHERE BulkStkLineAdjId = @BulkStkLineAdjHeaderId AND IsActive = 1;

		IF(ISNULL(@Amount,0) <> 0)
		BEGIN 
			SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('BulkStockLineAdjustmentINTRACOTRANSDIV')
			
			SELECT TOP 1 @JournalTypeId =JournalTypeId FROM [DBO].[DistributionSetup] WITH(NOLOCK)
			WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId = @MasterCompanyId AND DistributionSetupCode='INTRACOMPAYINTRACOTRANSDIV';
			
			SELECT @StatusId =Id,@StatusName=name FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @CurrentManagementStructureId =ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
			
			SELECT TOP 1 @ManagementStructureId = ManagementStructureId, @stklineId = StockLineId, @qtyAdjustment = QtyAdjustment FROM [DBO].[BulkStockLineAdjustmentDetails] WITH(NOLOCK) WHERE BulkStkLineAdjId = @BulkStkLineAdjHeaderId;
			SELECT @LastMSLevel = LastMSLevel,@AllMSlevels = AllMSlevels FROM [DBO].[StocklineManagementStructureDetails] WITH(NOLOCK) WHERE ReferenceID = @stklineId;

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM [DBO].[CodePrefixes] CP WITH(NOLOCK) JOIN [DBO].[CodeTypes] CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND  CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
			
			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM [DBO].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [DBO].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [DBO].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			where est.EntityStructureId=@CurrentManagementStructureId AND acc.MasterCompanyId=@MasterCompanyId  
			AND CAST(GETUTCDATE() AS DATE)   >= CAST(FromDate AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST(ToDate AS DATE)
			
			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
					ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM [DBO].[udfGenerateCodeNumber](@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN 	
				ROLLBACK TRAN;
			END
			
			IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
			BEGIN
				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK))
				BEGIN  
					set @batch ='001'  
					set @Currentbatch='001' 
				END
				ELSE
				BEGIN 
					SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1   
					  ELSE  1 END   
					FROM [DBO].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId DESC  
					
					IF(CAST(@Currentbatch AS BIGINT) >99)  
					BEGIN
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
					END  
					ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
					BEGIN    
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END   
					END
					ELSE
					BEGIN
					   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))  
						  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END   
  
					END  
				END
			
				SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)     
							  SET @batch = CAST(@JournalTypeCode +' '+CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))  
					
				INSERT INTO [dbo].[BatchHeader]    
				  ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],
				  [JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],
				  [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])    
				VALUES    
				  (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,
				  @JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,
				  @UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);    
				
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()    
				UPDATE [dbo].[BatchHeader] set CurrentNumber=@CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
			END
			ELSE
			BEGIN 
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId   
				   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
						 FROM [DBO].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC   
          
				IF(@CurrentPeriodId = 0)  
				BEGIN  
				   Update [DBO].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod  WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END  
			END
			
			INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
			[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [AccountingPeriodId], [AccountingPeriod])
			VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
			@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
			NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @AccountingPeriodId, @AccountingPeriod)
		
			SET @JournalBatchDetailId=SCOPE_IDENTITY()
				
				IF OBJECT_ID(N'tempdb..#tmpBulkStockLineAdjustmentDetails') IS NOT NULL
				BEGIN
					DROP TABLE #tmpBulkStockLineAdjustmentDetails
				END
				
				CREATE TABLE #tmpBulkStockLineAdjustmentDetails
				(
					[ID] INT IDENTITY,
					[BulkStockLineAdjustmentDetailsId] [bigint] NULL,
					[BulkStkLineAdjId] [bigint] NOT NULL,
					[StockLineId] [bigint] NULL,
					[Qty] [int] NOT NULL,
					[NewQty] [int] NULL,
					[QtyAdjustment] [int] NULL,
					[UnitCost] [decimal](18,2) NULL,
					[NewUnitCost] [decimal](18,2) NULL,
					[UnitCostAdjustment] [decimal](18,2) NULL,
					[AdjustmentAmount] [decimal](18,2) NULL,
					[FreightAdjustment] [decimal](18,2) NULL,
					[TaxAdjustment] [decimal](18,2) NULL,
					[StockLineAdjustmentTypeId] [int] NOT NULL,
					[ManagementStructureId] [bigint] NULL,
					[FromManagementStructureId] [bigint] NULL,
					[ToManagementStructureId] [bigint] NULL,
					[LastMSLevel] [varchar](200) NULL,
					[AllMSlevels] [varchar](MAX) NULL,
					[IsDeleted] [bit] NOT NULL
				)
				INSERT INTO #tmpBulkStockLineAdjustmentDetails ([BulkStockLineAdjustmentDetailsId],[BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],[IsDeleted],
													 [ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels])
				SELECT [BulkStkLineAdjDetailsId],[BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],[IsDeleted],
													 [ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels] 
				FROM [DBO].[BulkStockLineAdjustmentDetails] WITH(NOLOCK) WHERE BulkStkLineAdjId = @BulkStkLineAdjHeaderId AND AdjustmentAmount <> 0 AND IsActive = 1;

				SELECT  @MasterLoopID = MAX(ID) FROM #tmpBulkStockLineAdjustmentDetails

				WHILE(@MasterLoopID > 0)
				BEGIN
					SELECT @BulkStockLineAdjustmentDetailsId = [BulkStockLineAdjustmentDetailsId],
						   @DetailUnitCostAdjustment = [UnitCostAdjustment],
						   @AdjustmentAmount = [AdjustmentAmount],
						   @newqty = [NewQty],
						   @BlkManagementStructureId = [ManagementStructureId],
						   @FromManagementStructureId = [FromManagementStructureId],
						   @ToManagementStructureId = [ToManagementStructureId],
						   @StockLineId = StockLineId
					FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
					
					SELECT @GlAccountId = GLAccountId FROM [DBO].[Stockline] WITH(NOLOCK) WHERE StockLineId = @StockLineId;
					SELECT @GlAccountNumber = AccountCode,@GlAccountName=AccountName FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE GLAccountId=@GlAccountId;

					--Update Stockline table 
					SELECT @QuantityOnHand = [QuantityOnHand],
						   @QuantityAvailable = [QuantityAvailable], 
						   @QuantityReserved = [QuantityReserved],
						   @Memo = [Memo]
						FROM [DBO].[Stockline] WITH(NOLOCK) 
					WHERE StockLineId = @StockLineId;

					--Update existing stockline
					UPDATE [dbo].[Stockline] SET [QuantityOnHand] = @QuantityOnHand - @newqty,
												 [Memo] =  CASE WHEN ISNULL(@memo,'') = '' THEN '<p> IntraCompany Transfer From Stockline Adjustment </p>' ELSE @memo + '<p> IntraCompany Transfer From Stockline Adjustment </p>' END, 
												 --[QuantityAvailable] = @QuantityAvailable - @newqty,
												 [QuantityReserved] = @QuantityReserved - @newqty,
												 [UpdatedBy] = @UpdateBy,
												 [UpdatedDate] = GETUTCDATE()
					WHERE StockLineId = @StockLineId;

					--Update Existing Stockline 
					DECLARE @OrderModule AS BIGINT = 22;
					DECLARE @remainingQty AS INT;
					SET @remainingQty = @QuantityOnHand - @newqty;
					IF(@remainingQty > 0)
					BEGIN
						EXEC USP_AddUpdateStocklineHistory @StockLineId, @OrderModule, NULL, NULL, NULL, 9, @newqty, @UpdateBy;
					END
					ELSE
					BEGIN
						EXEC USP_AddUpdateStocklineHistory @StockLineId, @OrderModule, NULL, NULL, NULL, 9, @newqty, @UpdateBy;
					END

					DECLARE @Stockline BIGINT;
					--Create New Stockline
					EXEC dbo.USP_CreateStockline_BulkStockLineAdjustment @StockLineId,@BulkStockLineAdjustmentDetailsId,@UpdateBy,@MasterCompanyId,@Stockline OUTPUT;

					-----Inventory-Stock--------
					SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType
					 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'BULKSAINVENTORYSTOCKINTRACOTRANSDIVDR' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

					 INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
						[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
						[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
						VALUES	
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
						,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						CASE WHEN @CrDrType > 0 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType > 0 THEN ABS(@AdjustmentAmount) ELSE 0 END,
						CASE WHEN @CrDrType > 0 THEN 0 ELSE ABS(@AdjustmentAmount) END,
						@ToManagementStructureId ,'BulkStocklineAdjustment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
						@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@BulkStkLineAdjHeaderId)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ToManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountModuleId,1; 
			

					INSERT INTO [dbo].[BulkStocklineAdjPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,CommonJournalBatchDetailId,ModuleId,StockLineId,EmployeeId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ToManagementStructureId,@BulkStkLineAdjHeaderId,@CommonBatchDetailId,@BlkModuleID,@Stockline,@EmployeeId)

					-----Inventory-Stock--------

					-----Inventory-Stock--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'BULKSAINVENTORYSTOCKINTRACOTRANSDIVCR' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 SELECT @GlAccountId = GLAccountId FROM [DBO].[Stockline] WITH(NOLOCK) WHERE StockLineId = @StockLineId;
				 SELECT @GlAccountNumber = AccountCode,@GlAccountName=AccountName FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE GLAccountId=@GlAccountId;

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType > 0 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType > 0 THEN ABS(@AdjustmentAmount) ELSE 0 END,
					CASE WHEN @CrDrType > 0 THEN 0 ELSE ABS(@AdjustmentAmount) END,
					@FromManagementStructureId ,'BulkStocklineAdjustment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@BulkStkLineAdjHeaderId)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()
					
					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@FromManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountModuleId,1; 
			
					INSERT INTO [dbo].[BulkStocklineAdjPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,CommonJournalBatchDetailId,ModuleId,StockLineId,EmployeeId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@FromManagementStructureId,@BulkStkLineAdjHeaderId,@CommonBatchDetailId,@BlkModuleID,@StockLineId,@EmployeeId)
					
				 -----Inventory-Stock--------

				 -----Intercompany Payable--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'INTRACOMPAYINTRACOTRANSDIV' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 SELECT @GlAccountId = GlAccountId FROM [DBO].[DistributionSetup]  WITH(NOLOCK) WHERE [DistributionSetupCode] = 'INTRACOMPAYINTRACOTRANSDIV' AND MasterCompanyId = @MasterCompanyId;
				 SELECT @GlAccountNumber = AccountCode,@GlAccountName=AccountName FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE GLAccountId=@GlAccountId;

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType > 0 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType > 0 THEN ABS(@AdjustmentAmount) ELSE 0 END,
					CASE WHEN @CrDrType > 0 THEN 0 ELSE ABS(@AdjustmentAmount) END,
					@ToManagementStructureId ,'BulkStocklineAdjustment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@BulkStkLineAdjHeaderId)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ToManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountModuleId,1; 
			
					INSERT INTO [dbo].[BulkStocklineAdjPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,CommonJournalBatchDetailId,ModuleId,StockLineId,EmployeeId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@ToManagementStructureId,@BulkStkLineAdjHeaderId,@CommonBatchDetailId,@BlkModuleID,0,@EmployeeId)
					
				 -----Intercompany Payable--------

				 -----Intercompany Receivable--------

				 SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				 @CrDrType = CRDRType
				 FROM [DBO].[DistributionSetup] WITH(NOLOCK)  WHERE DistributionSetupCode = 'INTRACOMRECINTRACOTRANSDIV' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = (SELECT TOP 1 ID FROM [DBO].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)

				 SELECT @GlAccountId = GlAccountId FROM [DBO].[DistributionSetup]  WITH(NOLOCK) WHERE [DistributionSetupCode] = 'INTRACOMRECINTRACOTRANSDIV' AND MasterCompanyId = @MasterCompanyId;
				 SELECT @GlAccountNumber = AccountCode,@GlAccountName=AccountName FROM [DBO].[GLAccount] WITH(NOLOCK) WHERE GLAccountId=@GlAccountId;

				 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
					[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId])
					VALUES	
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 
					,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
					CASE WHEN @CrDrType > 0 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType > 0 THEN ABS(@AdjustmentAmount) ELSE 0 END,
					CASE WHEN @CrDrType > 0 THEN 0 ELSE ABS(@AdjustmentAmount) END,
					@FromManagementStructureId ,'BulkStocklineAdjustment',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
					@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@BulkStkLineAdjHeaderId)

					SET @CommonBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@FromManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountModuleId,1; 
			
					INSERT INTO [dbo].[BulkStocklineAdjPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ManagementStructureId,ReferenceId,CommonJournalBatchDetailId,ModuleId,StockLineId,EmployeeId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@FromManagementStructureId,@BulkStkLineAdjHeaderId,@CommonBatchDetailId,@BlkModuleID,0,@EmployeeId)
					
				 -----Intercompany Receivable--------

				 

					SET @BulkStockLineAdjustmentDetailsId = 0;
					SET @AdjustmentAmount = 0;
					SET @GlAccountId = 0;
					SET @BlkManagementStructureId = 0;
					SET @GlAccountName = NULL;
					SET @GlAccountNumber = 0;

					SET @MasterLoopID = @MasterLoopID - 1;
				END

			SET @TotalDebit=0;
			SET @TotalCredit=0;
			SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
			UPDATE [dbo].[BatchDetails] SET DebitAmount = @TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy  WHERE JournalBatchDetailId=@JournalBatchDetailId
		END

		
		SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [DBO].[BatchDetails] 
		WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
		SET @TotalBalance =@TotalDebit-@TotalCredit

		UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
	    UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId

		--Post the bulkstockline adj.
		UPDATE [dbo].[BulkStockLineAdjustment] SET StatusId = @BulkStatusId, Status = @BulkStatusName WHERE BulkStkLineAdjId = @BulkStkLineAdjHeaderId;

		SELECT	@BulkStkLineAdjHeaderId AS BulkStkLineAdjId;

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_BulkStockLineAdjustmentIntraCompany_PostCheckBatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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