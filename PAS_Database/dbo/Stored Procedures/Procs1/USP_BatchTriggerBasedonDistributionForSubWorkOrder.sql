/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonDistribution]
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used USP_BatchTriggerBasedonDistribution
 ** Purpose:         
 ** Date:   08/10/2022      
          
 ** PARAMETERS: @JournalBatchHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------              
	1    24/08/2023  Moin Bloch     Created
	2    28/08/2023  Moin Bloch     ADDED Labor ACCOUNTING BATCH
	3    25/09/2024	 AMIT GHEDIYA	Added for AutoPost Batch
	4	 08/10/2024	 Devendra Shekh	Added new fields for [CommonBatchDetails]
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_BatchTriggerBasedonDistributionForSubWorkOrder]
@DistributionMasterId BIGINT = NULL,
@ReferenceId BIGINT = NULL,
@ReferencePartId BIGINT = NULL,
@ReferencePieceId BIGINT = NULL,
@InvoiceId BIGINT = NULL,
@StocklineId BIGINT = NULL,
@Qty INT = 0,
@laborType VARCHAR(200) = NULL,
@issued  BIT = 0,
@Amount DECIMAL(18,2) = 0,
@ModuleName VARCHAR(200) = NULL,
@MasterCompanyId INT = 0,
@UpdateBy VARCHAR(200) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @JournalTypeId int
	    DECLARE @JournalTypeCode varchar(200) 
	    DECLARE @JournalBatchHeaderId bigint
	    DECLARE @GlAccountId int
	    DECLARE @StatusId int
	    DECLARE @StatusName varchar(200)
	    DECLARE @StartsFrom varchar(200)='00'
	    DECLARE @CurrentNumber int
	    DECLARE @GlAccountName varchar(200) 
	    DECLARE @GlAccountNumber varchar(200) 
	    DECLARE @JournalTypename varchar(200) 
	    DECLARE @Distributionname varchar(200) 
	    DECLARE @CustomerId bigint
	    DECLARE @ManagementStructureId bigint
	    DECLARE @CustomerName varchar(200)
        DECLARE @SubWorkOrderNumber varchar(200) 
        DECLARE @MPNName varchar(200) 
	    DECLARE @PiecePNId bigint
        DECLARE @PiecePN varchar(200) 
        DECLARE @ItemmasterId bigint
	    DECLARE @PieceItemmasterId bigint
	    DECLARE @CustRefNumber varchar(200)
	    DECLARE @LineNumber int=1
	    DECLARE @TotalDebit decimal(18,2)=0
	    DECLARE @TotalCredit decimal(18,2)=0
	    DECLARE @TotalBalance decimal(18,2)=0
	    DECLARE @UnitPrice decimal(18,2)=0
	    DECLARE @LaborHrs decimal(18,2)=0
	    DECLARE @DirectLaborCost decimal(18,2)=0
	    DECLARE @OverheadCost decimal(18,2)=0
	    DECLARE @partId bigint=0
		DECLARE @Batchtype int=1
		DECLARE @batch varchar(100)
		DECLARE @AccountingPeriod varchar(100)
		DECLARE @AccountingPeriodId bigint=0
		DECLARE @CurrentPeriodId bigint=0
		DECLARE @Currentbatch varchar(100)
	    DECLARE @LastMSLevel varchar(200)
		DECLARE @AllMSlevels varchar(max)
		DECLARE @DistributionSetupId int=0
		DECLARE @IsAccountByPass bit=0
		DECLARE @DistributionCode varchar(200)
		DECLARE @InvoiceTotalCost decimal(18,2)=0
	    DECLARE @MaterialCost decimal(18,2)=0
	    DECLARE @LaborOverHeadCost decimal(18,2)=0
	    DECLARE @FreightCost decimal(18,2)=0
		DECLARE @SalesTax decimal(18,2)=0
		DECLARE @OtherTax decimal(18,2)=0
		DECLARE @InvoiceNo varchar(100)
		DECLARE @MiscChargesCost decimal(18,2)=0
		DECLARE @LaborCost decimal(18,2)=0
		DECLARE @InvoiceLaborCost decimal(18,2)=0
		DECLARE @RevenuWO decimal(18,2)=0
		DECLARE @FinishGoodAmount decimal(18,2)=0
		DECLARE @CurrentManagementStructureId bigint=0
		DECLARE @JournalBatchDetailId bigint=0
		DECLARE @CommonJournalBatchDetailId bigint=0;
		DECLARE @WopJounralTypeid bigint=0;
		DECLARE @StocklineNumber varchar(100)
		DECLARE @UnEarnedAmount decimal(18,2)=0
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @StockLineMSModuleId INT = 0
	    DECLARE @SubWorkOrderStatusId BIGINT;  
		DECLARE @WorkOrderId BIGINT;  
		DECLARE @MSStocklineId BIGINT;
		
		SELECT @IsAccountByPass = [IsAccountByPass] FROM [dbo].[MasterCompany] WITH(NOLOCK)  WHERE [MasterCompanyId] = @MasterCompanyId;
	    SELECT @DistributionCode = [DistributionCode] FROM [dbo].[DistributionMaster] WITH(NOLOCK)  WHERE [ID] = @DistributionMasterId;
	    SELECT @StatusId = [Id], @StatusName= [name] FROM [dbo].[BatchStatus] WITH(NOLOCK)  WHERE [Name] = 'Open'
	    SELECT top 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId;
	    SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;
		SELECT @JournalTypeCode = [JournalTypeCode], @JournalTypename = [JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK)  WHERE ID= @JournalTypeId	  	  
	    SELECT @WopJounralTypeid = ID FROM [dbo].[JournalType] WITH(NOLOCK) WHERE [JournalTypeCode] = 'WIP';
		SELECT @CurrentManagementStructureId = ISNULL([ManagementStructureId],0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM([FirstName]),'',TRIM([LastName])) IN (REPLACE(@UpdateBy, ' ', '')) AND [MasterCompanyId] = @MasterCompanyId;			
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		SELECT @StockLineMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Stockline';
		SELECT @SubWorkOrderStatusId  = Id FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'  
		
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @CrDrType int=0
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;
		DECLARE @CurrencyCode VARCHAR(20) = '';
		DECLARE @FXRate DECIMAL(18,2) = 1;	--Default Value set to : 1

		IF((@JournalTypeCode ='WIP' OR @JournalTypeCode ='WOI' OR @JournalTypeCode ='MRO-WO' OR @JournalTypeCode ='FGI') AND @IsAccountByPass = 0)
		BEGIN 
			SELECT @SubWorkOrderNumber = [SubWorkOrderNo], 
			       @CustomerId = [CustomerId],
				   @CustomerName = [CustomerName] 
			 FROM [dbo].[SubWorkOrder] SWO WITH(NOLOCK) 
			 INNER JOIN [dbo].[WorkOrder] WOD WITH(NOLOCK) ON SWO.[WorkOrderId] = WOD.[WorkOrderId]
			WHERE SWO.[SubWorkOrderId] = @ReferenceId
			
			SET @partId = @ReferencePartId;

			IF(ISNULL(@CustomerId, 0) > 0)
			BEGIN
				SELECT @CurrencyCode = ISNULL(CY.Code, '') FROM [dbo].[Customer] CU WITH(NOLOCK) LEFT JOIN [DBO].[CustomerFinancial] CF WITH(NOLOCK) ON CU.CustomerId = CF.CustomerId LEFT JOIN [DBO].[Currency] CY WITH(NOLOCK) ON CF.CurrencyId = CY.CurrencyId WHERE CU.CustomerId = @CustomerId;
			END

			IF(@ReferencePartId = 0)   -- Need To Discuss
			BEGIN
				SELECT @partId = [SubWOPartNoId] FROM [dbo].[SubWorkOrderMaterials] WITH(NOLOCK) WHERE [SubWorkOrderId] = @ReferenceId AND [SubWorkOrderMaterialsId] = @ReferencePieceId;
			END
								  
	        SELECT --@ManagementStructureId = ManagementStructureId,     -- Need To Discuss
			       @ItemmasterId = SWO.ItemMasterId, 
				   @CustRefNumber = SWO.CustomerReference,
				   @MPNName = ITM.[partnumber],
				   @WorkOrderId = SWO.[WorkOrderId]
			  FROM [dbo].[SubWorkOrderPartNumber] SWO WITH(NOLOCK) 
			  INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SWO.ItemMasterId = ITM.ItemMasterId			  
			  WHERE SWO.[SubWorkOrderId] = @ReferenceId AND SWO.[SubWOPartNoId] = @partId
			  
			IF(UPPER(@DistributionCode) = UPPER('WOMATERIALGRIDTAB'))
			BEGIN
				SELECT @LastMSLevel = [LastMSLevel],
					   @AllMSlevels = [AllMSlevels],
					   @ManagementStructureId = [EntityMSID]
				  FROM [dbo].[StocklineManagementStructureDetails] WITH(NOLOCK) WHERE [ReferenceID] = @StocklineId AND [ModuleID] = @StockLineMSModuleId;
			END
			IF(UPPER(@DistributionCode) = UPPER('WOLABORTAB'))
			BEGIN
				SELECT TOP 1 @MSStocklineId = [StockLineId] FROM [dbo].[WorkOrderPartNumber] WHERE [WorkOrderId] = @WorkOrderId;
				SELECT @LastMSLevel = [LastMSLevel],
					   @AllMSlevels = [AllMSlevels],
					   @ManagementStructureId = [EntityMSID]
				  FROM [dbo].[StocklineManagementStructureDetails] WITH(NOLOCK) WHERE [ReferenceID] = @MSStocklineId AND [ModuleID] = @StockLineMSModuleId;
			END

			IF(@CurrentManagementStructureId = 0)
			BEGIN
				SET @CurrentManagementStructureId = @ManagementStructureId
			END

			SELECT TOP 1  @AccountingPeriodId = acc.[AccountingCalendarId],
			              @AccountingPeriod = acc.[PeriodName] 						  
					FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId AND acc.IsDeleted = 0
			WHERE est.EntityStructureId = @CurrentManagementStructureId AND acc.MasterCompanyId = @MasterCompanyId  
			AND CAST(GETUTCDATE() AS DATE) >= CAST([FromDate] AS DATE) AND  CAST(GETUTCDATE() AS DATE) <= CAST([ToDate] AS DATE)
		   
		   SET @ReferencePartId = @partId	

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

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFrom AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END

			IF(UPPER(@DistributionCode) = UPPER('WOMATERIALGRIDTAB'))
			BEGIN					
				DECLARE @SWOStatusId bigint = 0
				
				SELECT @SWOStatusId = [SubWorkOrderStatusId]
				 FROM [dbo].[SubWorkOrderPartNumber] WITH (NOLOCK) 
				WHERE [SubWorkOrderId] = @ReferenceId 
				  AND [SubWOPartNoId] = @ReferencePartId 
				  AND [SubWorkOrderStatusId] = @SubWorkOrderStatusId;

				IF(@SWOStatusId = @SubWorkOrderStatusId AND @Amount > 0)
				BEGIN
					SELECT TOP 1 @DistributionSetupId = [ID],
				             @DistributionName = [Name],
							 @JournalTypeId = [JournalTypeId],
							 @GlAccountId = [GlAccountId],
							 @GlAccountNumber = [GlAccountNumber],
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType],
							 @IsAutoPost = ISNULL(IsAutoPost,0)
						FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
						WHERE UPPER([DistributionSetupCode]) = UPPER('WIPPARTS') 
						AND [DistributionMasterId] = @DistributionMasterId 
						AND MasterCompanyId=@MasterCompanyId

					IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId AND ISNULL([GlAccountId],0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF(@Amount > 0 AND @ValidDistribution = 1)
					BEGIN						
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
						BEGIN
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE  1 END 
				   				FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by JournalBatchHeaderId desc 

								IF(CAST(@Currentbatch AS BIGINT) >99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
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
											[StatusId],
											[StatusName],
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
											 @AccountingPeriodId,
											 @StatusId,
											 @StatusName,
											 @JournalTypeId,
											 @JournalTypename,
											 0,
											 0,
											 0,
											 @MasterCompanyId,
											 @UpdateBy,
											 @UpdateBy,
											 GETUTCDATE(),
											 GETUTCDATE(),
											 1,
											 0,
											 @ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()

							UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],
								   @CurrentPeriodId = ISNULL(AccountingPeriodId,0) 
							  FROM [dbo].[BatchHeader] WITH(NOLOCK)  
							  WHERE [JournalTypeId] = @JournalTypeId 
								AND [StatusId] = @StatusId;

							SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END 
				   									FROM [dbo].[BatchDetails] WITH(NOLOCK) 
												   WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
												   ORDER BY [JournalBatchDetailId] DESC 				    
							IF(@CurrentPeriodId =0)
							BEGIN
								UPDATE [dbo].[BatchHeader] 
								   SET [AccountingPeriodId] = @AccountingPeriodId,
									   [AccountingPeriod] = @AccountingPeriod   
								 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
							END

							SET @IsBatchGenerated = 1;
						END

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
										[AccountingPeriod])
								 VALUES
										(@JournalTypeNumber,
										 @currentNo,
										 @DistributionSetupId,
										 @DistributionName,
										 @JournalBatchHeaderId,
										 1,
										 @GlAccountId,
										 @GlAccountNumber,
										 @GlAccountName,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 @JournalTypeId,
										 @JournalTypename,
										 1,
										 0,
										 0,
										 @ManagementStructureId,
										 @ModuleName,
										 @LastMSLevel,
										 @AllMSlevels,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 @AccountingPeriodId,
										 @AccountingPeriod)

						SET @JournalBatchDetailId = SCOPE_IDENTITY()

						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
										[JournalTypeNumber],
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
										[IsDeleted]
										,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
								 VALUES
										(@JournalBatchDetailId,
										 @JournalTypeNumber,
										 @currentNo,
										 @DistributionSetupId,
										 @DistributionName,
										 @JournalBatchHeaderId,
										 1 ,
										 @GlAccountId,
										 @GlAccountNumber,
										 @GlAccountName,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 @JournalTypeId,
										 @JournalTypename,
										 CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
										 @ManagementStructureId,
										 @ModuleName,
										 @LastMSLevel,
										 @AllMSlevels,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0
										 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					
						INSERT INTO [dbo].[WorkOrderBatchDetails]
									   ([JournalBatchDetailId],
										[JournalBatchHeaderId],
										[ReferenceId],
										[ReferenceName],
										[MPNPartId],
										[MPNName],
										[PiecePNId],
										[PiecePN],
										[CustomerId],
										[CustomerName],
										[InvoiceId],
										[InvoiceName],
										[ARControlNum],
										[CustRefNumber],
										[Qty],
										[UnitPrice],
										[LaborHrs],
										[DirectLaborCost],
										[OverheadCost],
										[CommonJournalBatchDetailId],
										[StocklineId],
										[StocklineNumber],
										[IsWorkOrder])
								 VALUES
									   (@JournalBatchDetailId,
										@JournalBatchHeaderId,
										@ReferenceId,									
										@SubWorkOrderNumber,
										@ReferencePartId,
										@MPNName,
										@ReferencePieceId,
										@PiecePN,
										@CustomerId,
										@CustomerName,
										NULL,
										NULL,
										NULL,
										@CustRefNumber,
										@Qty,
										@UnitPrice,
										@LaborHrs,
										@DirectLaborCost,
										@OverheadCost,
										@CommonJournalBatchDetailId,
										@StocklineId,
										@StocklineNumber,
										0)

						SELECT TOP 1 @DistributionSetupId = [ID],
										 @DistributionName = [Name],
										 @JournalTypeId = [JournalTypeId],
										 @CrDrType = [CRDRType] 
								  FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
								 WHERE UPPER(DistributionSetupCode) = UPPER('INVENTORYPARTS') 
								   AND [DistributionMasterId] = @DistributionMasterId 
								   AND [MasterCompanyId] = @MasterCompanyId
						
						SELECT @GlAccountId = [GlAccountId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId

						SELECT @GlAccountNumber = [AccountCode], @GlAccountName = [AccountName] FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

						SET @GlAccountId = ISNULL(@GlAccountId,0) 
					
						INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
										[JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName] ,
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
										[IsDeleted]
										,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
								  VALUES
										(@JournalBatchDetailId,
										 @JournalTypeNumber,
										 @currentNo,
										 @DistributionSetupId,
										 @DistributionName,
										 @JournalBatchHeaderId,
										 1 ,
										 @GlAccountId ,
										 @GlAccountNumber ,
										 @GlAccountName,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 @JournalTypeId ,
										 @JournalTypename ,
										 CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
										 @ManagementStructureId ,
										 @ModuleName,
										 @LastMSLevel,
										 @AllMSlevels ,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0
										 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[WorkOrderBatchDetails]
									   ([JournalBatchDetailId],
										[JournalBatchHeaderId],
										[ReferenceId],
										[ReferenceName],
										[MPNPartId],
										[MPNName],
										[PiecePNId],
										[PiecePN],
										[CustomerId],
										[CustomerName],
										[InvoiceId],
										[InvoiceName],
										[ARControlNum],
										[CustRefNumber],
										[Qty],
										[UnitPrice],
										[LaborHrs],
										[DirectLaborCost],
										[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
								 VALUES
										(@JournalBatchDetailId,
										 @JournalBatchHeaderId,
										 @ReferenceId,
										 @SubWorkOrderNumber,
										 @ReferencePartId,
										 @MPNName,
										 @ReferencePieceId,
										 @PiecePN,
										 @CustomerId,
										 @CustomerName,
										 NULL,
										 NULL,
										 NULL,
										 @CustRefNumber,
										 @Qty,
										 @UnitPrice,
										 @LaborHrs,
										 @DirectLaborCost,
										 @OverheadCost,
										 @CommonJournalBatchDetailId,
										 @StocklineId,
										 @StocklineNumber,
										 0)

						SET @TotalDebit=0;
						SET @TotalCredit=0;

						SELECT @TotalDebit = SUM([DebitAmount]),
							   @TotalCredit = SUM([CreditAmount]) 
						  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
						  WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
						  GROUP BY JournalBatchDetailId
						
						UPDATE [dbo].[BatchDetails] 
						   SET [DebitAmount] = @TotalDebit,
							   [CreditAmount] = @TotalCredit,
							   [UpdatedDate] = GETUTCDATE(),
							   [UpdatedBy] = @UpdateBy 
						 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;


						 --AutoPost Batch
						 IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
						 BEGIN
						 	EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
						 END
						 IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
						 BEGIN
						 	EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
						 END
					END
				END
				ELSE
				BEGIN
					SELECT @PieceItemmasterId = SMS.[ItemMasterId],
						   @UnitPrice = SMS.[UnitCost],
						   @Amount = ISNULL((@Qty * SMS.[UnitCost]),0), 
						   @PiecePN = ITM.[partnumber]
					 FROM [dbo].[SubWorkOrderMaterialStockLine] SMS WITH(NOLOCK)
					 INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SMS.[ItemMasterId] = ITM.[ItemMasterId]				 
					 WHERE SMS.[StockLineId] = @StocklineId AND SMS.[SubWorkOrderMaterialsId] = @ReferencePieceId;				
				 				 				 
					SELECT TOP 1 @DistributionSetupId = [ID],
				             @DistributionName = [Name],
							 @JournalTypeId = [JournalTypeId],
							 @GlAccountId = [GlAccountId],
							 @GlAccountNumber = [GlAccountNumber],
							 @GlAccountName = [GlAccountName],
							 @CrDrType = [CRDRType],
							 @IsAutoPost = ISNULL(IsAutoPost,0)
				FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
				WHERE UPPER([DistributionSetupCode]) = UPPER('WIPPARTS') 
				AND [DistributionMasterId] = @DistributionMasterId 
				AND MasterCompanyId=@MasterCompanyId

					IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId AND ISNULL([GlAccountId],0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF(@issued = 1 AND @Amount > 0 AND @ValidDistribution = 1)
					BEGIN					
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId and [MasterCompanyId] = @MasterCompanyId AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
						BEGIN
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT TOP 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE  1 END 
				   				FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by JournalBatchHeaderId desc 

								IF(CAST(@Currentbatch AS BIGINT) > 99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) > 9)
								BEGIN

									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
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
										[StatusId],
										[StatusName],
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
										 @AccountingPeriodId,
										 @StatusId,
										 @StatusName,
										 @JournalTypeId,
										 @JournalTypename,
										 0,
										 0,
										 0,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 @ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();

							UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],@CurrentPeriodId=ISNULL(AccountingPeriodId,0) FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;
						
							SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END 
				   									FROM [dbo].[BatchDetails] WITH(NOLOCK) 
												WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC 
				    
							IF(@CurrentPeriodId = 0)
							BEGIN
								UPDATE [dbo].[BatchHeader] 
								   SET [AccountingPeriodId] = @AccountingPeriodId,
									   [AccountingPeriod] = @AccountingPeriod   
								 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
							END

							SET @IsBatchGenerated = 1;
						END
					
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
									 [AccountingPeriod])
							  VALUES
									(@JournalTypeNumber,
									 @currentNo,
									 @DistributionSetupId,
									 @DistributionName,
									 @JournalBatchHeaderId,
									 1,
									 @GlAccountId,
									 @GlAccountNumber,
									 @GlAccountName,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 @JournalTypeId,
									 @JournalTypename,
									 1,
									 0,
									 0,
									 @ManagementStructureId,
									 @ModuleName,
									 @LastMSLevel,
									 @AllMSlevels,
									 @MasterCompanyId,
									 @UpdateBy,
									 @UpdateBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0,
									 @AccountingPeriodId,
									 @AccountingPeriod)

						SET @JournalBatchDetailId = SCOPE_IDENTITY()

						INSERT INTO [dbo].[CommonBatchDetails]
									([JournalBatchDetailId],
									 [JournalTypeNumber],
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
									 [IsDeleted]
									 ,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
							  VALUES
									(@JournalBatchDetailId,
									 @JournalTypeNumber,
									 @currentNo,
									 @DistributionSetupId,
									 @DistributionName,
									 @JournalBatchHeaderId,
									 1,
									 @GlAccountId,
									 @GlAccountNumber,
									 @GlAccountName,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 @JournalTypeId,
									 @JournalTypename,
									 CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									 CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									 CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									 @ManagementStructureId,
									 @ModuleName,
									 @LastMSLevel,
									 @AllMSlevels,
									 @MasterCompanyId,
									 @UpdateBy,
									 @UpdateBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0
									 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
						INSERT INTO [dbo].[WorkOrderBatchDetails]
								   ([JournalBatchDetailId],
									[JournalBatchHeaderId],
									[ReferenceId],
									[ReferenceName],
									[MPNPartId],
									[MPNName],
									[PiecePNId],
									[PiecePN],
									[CustomerId],
									[CustomerName],
									[InvoiceId],
									[InvoiceName],
									[ARControlNum],
									[CustRefNumber],
									[Qty],
									[UnitPrice],
									[LaborHrs],
									[DirectLaborCost],
									[OverheadCost],
									[CommonJournalBatchDetailId],
									[StocklineId],
									[StocklineNumber],
									[IsWorkOrder])
							 VALUES
									(@JournalBatchDetailId,
									 @JournalBatchHeaderId,
									 @ReferenceId,
									 @SubWorkOrderNumber,
									 @ReferencePartId,
									 @MPNName,
									 @ReferencePieceId,
									 @PiecePN,
									 @CustomerId,
									 @CustomerName,
									 NULL,
									 NULL,
									 NULL,
									 @CustRefNumber,
									 @Qty,
									 @UnitPrice,
									 @LaborHrs,
									 @DirectLaborCost,
									 @OverheadCost,
									 @CommonJournalBatchDetailId,
									 @StocklineId,
									 @StocklineNumber,
									 0);
								 
						SELECT TOP 1 @DistributionSetupId = [ID],
									 @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @CrDrType = [CRDRType] 
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)
								WHERE UPPER([DistributionSetupCode]) = UPPER('INVENTORYPARTS') 
								  AND [DistributionMasterId] = @DistributionMasterId 
								  AND MasterCompanyId=@MasterCompanyId

						SELECT @GlAccountId = [GlAccountId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId;

						SELECT @GlAccountNumber = [AccountCode], @GlAccountName = [AccountName] FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE [GLAccountId] = @GlAccountId;

						SET @GlAccountId = ISNULL(@GlAccountId,0) 

						INSERT INTO [dbo].[CommonBatchDetails]
								   ([JournalBatchDetailId],
									[JournalTypeNumber],
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
									[IsDeleted]
									,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
							 VALUES
									(@JournalBatchDetailId,
									 @JournalTypeNumber,
									 @currentNo,
									 @DistributionSetupId,
									 @DistributionName,
									 @JournalBatchHeaderId,
									 1,
									 @GlAccountId,
									 @GlAccountNumber,
									 @GlAccountName,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 @JournalTypeId,
									 @JournalTypename,
									 CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
									 CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
									 CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
									 @ManagementStructureId,
									 @ModuleName,
									 @LastMSLevel,
									 @AllMSlevels,
									 @MasterCompanyId,
									 @UpdateBy,
									 @UpdateBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0
									 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
					
						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
						INSERT INTO [dbo].[WorkOrderBatchDetails]
								   ([JournalBatchDetailId],
									[JournalBatchHeaderId],
									[ReferenceId],
									[ReferenceName],
									[MPNPartId],
									[MPNName],
									[PiecePNId],
									[PiecePN],
									[CustomerId],
									[CustomerName],
									[InvoiceId],
									[InvoiceName],
									[ARControlNum],
									[CustRefNumber],
									[Qty],
									[UnitPrice],
									[LaborHrs],
									[DirectLaborCost],
									[OverheadCost],
									[CommonJournalBatchDetailId],
									[StocklineId],
									[StocklineNumber],
									[IsWorkOrder])
							 VALUES
									(@JournalBatchDetailId,
									 @JournalBatchHeaderId,
									 @ReferenceId,
									 @SubWorkOrderNumber,
									 @ReferencePartId,
									 @MPNName,
									 @ReferencePieceId,
									 @PiecePN,
									 @CustomerId,
									 @CustomerName,
									 NULL,
									 NULL,
									 NULL,
									 @CustRefNumber,
									 @Qty,
									 @UnitPrice,
									 @LaborHrs,
									 @DirectLaborCost,
									 @OverheadCost,
									 @CommonJournalBatchDetailId,
									 @StocklineId,
									 @StocklineNumber,
									 0)

						SET @TotalDebit = 0;
						SET @TotalCredit = 0;

						SELECT @TotalDebit = SUM([DebitAmount]),
							   @TotalCredit = SUM([CreditAmount]) 
						 FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
						 WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
						 GROUP BY [JournalBatchDetailId]

						UPDATE [dbo].[BatchDetails] 
						   SET [DebitAmount] = @TotalDebit,
							   [CreditAmount] = @TotalCredit,
							   [UpdatedDate] = GETUTCDATE(),
							   [UpdatedBy] = @UpdateBy 
						 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;

					END
					ELSE
					BEGIN
						IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
						BEGIN
							SET @ValidDistribution = 0;
						END

						IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId AND ISNULL([GlAccountId],0) = 0)
						BEGIN
							SET @ValidDistribution = 0;
						END					
						IF(@Amount > 0 AND @ValidDistribution = 1)
						BEGIN						
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
							BEGIN
								IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE  1 END 
				   					FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by JournalBatchHeaderId desc 

									IF(CAST(@Currentbatch AS BIGINT) >99)
									BEGIN
										SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
									END
									ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
									BEGIN
										SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   						ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
									END
									ELSE
									BEGIN
										SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))
				   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
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
											[StatusId],
											[StatusName],
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
											 @AccountingPeriodId,
											 @StatusId,
											 @StatusName,
											 @JournalTypeId,
											 @JournalTypename,
											 0,
											 0,
											 0,
											 @MasterCompanyId,
											 @UpdateBy,
											 @UpdateBy,
											 GETUTCDATE(),
											 GETUTCDATE(),
											 1,
											 0,
											 @ModuleName);
            	          
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()

								UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],
									   @CurrentPeriodId = ISNULL(AccountingPeriodId,0) 
								  FROM [dbo].[BatchHeader] WITH(NOLOCK)  
								  WHERE [JournalTypeId] = @JournalTypeId 
									AND [StatusId] = @StatusId;

								SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END 
				   										FROM [dbo].[BatchDetails] WITH(NOLOCK) 
													   WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
													   ORDER BY [JournalBatchDetailId] DESC 				    
								IF(@CurrentPeriodId =0)
								BEGIN
									UPDATE [dbo].[BatchHeader] 
									   SET [AccountingPeriodId] = @AccountingPeriodId,
										   [AccountingPeriod] = @AccountingPeriod   
									 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId
								END

								SET @IsBatchGenerated = 1;
							END

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
										[AccountingPeriod])
								 VALUES
										(@JournalTypeNumber,
										 @currentNo,
										 @DistributionSetupId,
										 @DistributionName,
										 @JournalBatchHeaderId,
										 1,
										 @GlAccountId,
										 @GlAccountNumber,
										 @GlAccountName,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 @JournalTypeId,
										 @JournalTypename,
										 1,
										 0,
										 0,
										 @ManagementStructureId,
										 @ModuleName,
										 @LastMSLevel,
										 @AllMSlevels,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 @AccountingPeriodId,
										 @AccountingPeriod)

							SET @JournalBatchDetailId = SCOPE_IDENTITY()

							INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
										[JournalTypeNumber],
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
										[IsDeleted]
										,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
								 VALUES
										(@JournalBatchDetailId,
										 @JournalTypeNumber,
										 @currentNo,
										 @DistributionSetupId,
										 @DistributionName,
										 @JournalBatchHeaderId,
										 1 ,
										 @GlAccountId,
										 @GlAccountNumber,
										 @GlAccountName,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 @JournalTypeId,
										 @JournalTypename,
										 CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
										 @ManagementStructureId,
										 @ModuleName,
										 @LastMSLevel,
										 @AllMSlevels,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0
										 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

								  SET @CommonJournalBatchDetailId = SCOPE_IDENTITY();

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					
							INSERT INTO [dbo].[WorkOrderBatchDetails]
									   ([JournalBatchDetailId],
										[JournalBatchHeaderId],
										[ReferenceId],
										[ReferenceName],
										[MPNPartId],
										[MPNName],
										[PiecePNId],
										[PiecePN],
										[CustomerId],
										[CustomerName],
										[InvoiceId],
										[InvoiceName],
										[ARControlNum],
										[CustRefNumber],
										[Qty],
										[UnitPrice],
										[LaborHrs],
										[DirectLaborCost],
										[OverheadCost],
										[CommonJournalBatchDetailId],
										[StocklineId],
										[StocklineNumber],
										[IsWorkOrder])
								 VALUES
									   (@JournalBatchDetailId,
										@JournalBatchHeaderId,
										@ReferenceId,									
										@SubWorkOrderNumber,
										@ReferencePartId,
										@MPNName,
										@ReferencePieceId,
										@PiecePN,
										@CustomerId,
										@CustomerName,
										NULL,
										NULL,
										NULL,
										@CustRefNumber,
										@Qty,
										@UnitPrice,
										@LaborHrs,
										@DirectLaborCost,
										@OverheadCost,
										@CommonJournalBatchDetailId,
										@StocklineId,
										@StocklineNumber,
										0)

							SELECT TOP 1 @DistributionSetupId = [ID],
										 @DistributionName = [Name],
										 @JournalTypeId = [JournalTypeId],
										 @CrDrType = [CRDRType] 
								  FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
								 WHERE UPPER(DistributionSetupCode) = UPPER('INVENTORYPARTS') 
								   AND [DistributionMasterId] = @DistributionMasterId 
								   AND [MasterCompanyId] = @MasterCompanyId
						
							SELECT @GlAccountId = [GlAccountId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StocklineId

							SELECT @GlAccountNumber = [AccountCode], @GlAccountName = [AccountName] FROM [dbo].[GLAccount] WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

							SET @GlAccountId = ISNULL(@GlAccountId,0) 
					
							INSERT INTO [dbo].[CommonBatchDetails]
									   ([JournalBatchDetailId],
										[JournalTypeNumber],
										[CurrentNumber],
										[DistributionSetupId],
										[DistributionName],
										[JournalBatchHeaderId],
										[LineNumber],
										[GlAccountId],
										[GlAccountNumber],
										[GlAccountName] ,
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
										[IsDeleted]
										,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
								  VALUES
										(@JournalBatchDetailId,
										 @JournalTypeNumber,
										 @currentNo,
										 @DistributionSetupId,
										 @DistributionName,
										 @JournalBatchHeaderId,
										 1 ,
										 @GlAccountId ,
										 @GlAccountNumber ,
										 @GlAccountName,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 @JournalTypeId ,
										 @JournalTypename ,
										 CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
										 CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
										 @ManagementStructureId ,
										 @ModuleName,
										 @LastMSLevel,
										 @AllMSlevels ,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0
										 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
							INSERT INTO [dbo].[WorkOrderBatchDetails]
									   ([JournalBatchDetailId],
										[JournalBatchHeaderId],
										[ReferenceId],
										[ReferenceName],
										[MPNPartId],
										[MPNName],
										[PiecePNId],
										[PiecePN],
										[CustomerId],
										[CustomerName],
										[InvoiceId],
										[InvoiceName],
										[ARControlNum],
										[CustRefNumber],
										[Qty],
										[UnitPrice],
										[LaborHrs],
										[DirectLaborCost],
										[OverheadCost],[CommonJournalBatchDetailId],[StocklineId],[StocklineNumber],[IsWorkOrder])
								 VALUES
										(@JournalBatchDetailId,
										 @JournalBatchHeaderId,
										 @ReferenceId,
										 @SubWorkOrderNumber,
										 @ReferencePartId,
										 @MPNName,
										 @ReferencePieceId,
										 @PiecePN,
										 @CustomerId,
										 @CustomerName,
										 NULL,
										 NULL,
										 NULL,
										 @CustRefNumber,
										 @Qty,
										 @UnitPrice,
										 @LaborHrs,
										 @DirectLaborCost,
										 @OverheadCost,
										 @CommonJournalBatchDetailId,
										 @StocklineId,
										 @StocklineNumber,
										 0)

							SET @TotalDebit=0;
							SET @TotalCredit=0;

							SELECT @TotalDebit = SUM([DebitAmount]),
								   @TotalCredit = SUM([CreditAmount]) 
							  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
							  WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
							  GROUP BY JournalBatchDetailId
						
							UPDATE [dbo].[BatchDetails] 
							   SET [DebitAmount] = @TotalDebit,
								   [CreditAmount] = @TotalCredit,
								   [UpdatedDate] = GETUTCDATE(),
								   [UpdatedBy] = @UpdateBy 
							 WHERE [JournalBatchDetailId] = @JournalBatchDetailId;

						END
					END

					SELECT @TotalDebit = SUM([DebitAmount]),
						   @TotalCredit = SUM([CreditAmount]) 
					 FROM [dbo].[BatchDetails] WITH(NOLOCK) 
					 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
					   AND [IsDeleted] = 0 
					  GROUP BY [JournalBatchHeaderId]
			   	         
					SET @TotalBalance = @TotalDebit - @TotalCredit
				         
					UPDATE [dbo].[BatchHeader] 
					   SET [TotalDebit] = @TotalDebit,
						   [TotalCredit] = @TotalCredit,
						   [TotalBalance] = @TotalBalance,
						   [UpdatedDate] = GETUTCDATE(),
						   [UpdatedBy] = @UpdateBy
					 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;
	            
					UPDATE [dbo].[CodePrefixes] 
					   SET [CurrentNummber] = @currentNo 
					 WHERE [CodeTypeId] = @CodeTypeId 
					   AND [MasterCompanyId] = @MasterCompanyId


					 --AutoPost Batch
					 IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
					 BEGIN
					 	EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
					 END
					 IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
					 BEGIN
					 	EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
					 END
				  END

			END			
			
			IF(UPPER(@DistributionCode) = UPPER('WOLABORTAB'))
			BEGIN
				SET @Batchtype = 2
				DECLARE @Hours DECIMAL(18,2)
                DECLARE @Hourspay DECIMAL(18,2)
                DECLARE @LaborRate MONEY
				DECLARE @burdentRate MONEY

		        SELECT @LaborHrs = ISNULL([AdjustedHours],0),
				       @Hours = ISNULL([AdjustedHours],0),
					   @DirectLaborCost = ISNULL([TotalCost],0),
					   @OverheadCost = ISNULL([DirectLaborOHCost],0),
					   @LaborRate = ISNULL(DirectLaborOHCost,0),
					   @burdentRate=ISNULL(BurdenRateAmount,0) 
				FROM [dbo].[SubWorkOrderLabor] WITH(NOLOCK)  WHERE [SubWorkOrderLaborId]=@ReferencePieceId

				SET @Qty = 0;

				IF(@laborType='DIRECTLABOR')
				BEGIN
					SET @Amount = ISNULL((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@LaborRate,0)
					SET @DirectLaborCost = @Amount
					SET @OverheadCost = 0
					SELECT TOP 1 @DistributionSetupId = [ID],
					             @DistributionName = [Name],
								 @JournalTypeId = [JournalTypeId],
								 @GlAccountId = [GlAccountId],
								 @GlAccountNumber = [GlAccountNumber],
								 @GlAccountName = [GlAccountName],
								 @CrDrType = [CRDRType],
								 @IsAutoPost = ISNULL(IsAutoPost,0)
					        FROM [dbo].[DistributionSetup] WITH(NOLOCK) 
							WHERE UPPER([DistributionSetupCode]) = UPPER('WIPDIRECTLABOR') 
							AND [DistributionMasterId] = @DistributionMasterId 
							AND [MasterCompanyId] = @MasterCompanyId
				END

				IF NOT EXISTS(SELECT wob.[WorkOrderBatchId] FROM [dbo].[WorkOrderBatchDetails] wob WITH(NOLOCK) WHERE [PiecePNId] = @ReferencePieceId AND [Batchtype] = @Batchtype AND [DistributionSetupId]=@DistributionSetupId)
				BEGIN
					 IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId AND [MasterCompanyId]=@MasterCompanyId AND ISNULL([GlAccountId],0) = 0)
					 BEGIN
						SET @ValidDistribution = 0;
					 END					
					 IF(@issued = 1 AND @Amount > 0 AND @ValidDistribution = 1)
					 BEGIN
						IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId] = @MasterCompanyId AND  CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId] = @StatusId)
						BEGIN
							IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId DESC 

								IF(CAST(@Currentbatch AS BIGINT) > 99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) > 9)
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
							SET @batch = CAST(@JournalTypeCode +' '+cast(@batch AS VARCHAR(100)) AS VARCHAR(100))							
				          
							INSERT INTO [dbo].[BatchHeader]
									   ([BatchName],
									    [CurrentNumber],
										[EntryDate],
										[AccountingPeriod],
										[AccountingPeriodId],
										[StatusId],
										[StatusName],
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
										 @AccountingPeriodId,
										 @StatusId,
										 @StatusName,
										 @JournalTypeId,
										 @JournalTypename,
										 @Amount,
										 @Amount,
										 0,
										 @MasterCompanyId,
										 @UpdateBy,
										 @UpdateBy,
										 GETUTCDATE(),
										 GETUTCDATE(),
										 1,
										 0,
										 @ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();

							UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber  WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],
							       @CurrentPeriodId = ISNULL(AccountingPeriodId,0) FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE [JournalTypeId]= @JournalTypeId AND StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								UPDATE [dbo].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END

							SET @IsBatchGenerated = 1;
						END
						
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
									[AccountingPeriod])
						     VALUES
						            (@JournalTypeNumber,
									 @currentNo,
									 @DistributionSetupId,
									 @DistributionName,
									 @JournalBatchHeaderId,
									 1 ,
									 @GlAccountId ,
									 @GlAccountNumber,
									 @GlAccountName,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 @JournalTypeId,
									 @JournalTypename,
						             1,
									 0,
									 0,
									 @ManagementStructureId,
									 @ModuleName,
									 @LastMSLevel,
									 @AllMSlevels,
									 @MasterCompanyId,
									 @UpdateBy,
									 @UpdateBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0,
									 @AccountingPeriodId,
									 @AccountingPeriod)
				                
               	        SET @JournalBatchDetailId=SCOPE_IDENTITY()

						INSERT INTO [dbo].[CommonBatchDetails]
							       ([JournalBatchDetailId],
								    [JournalTypeNumber],
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
									[IsDeleted]
									,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						     VALUES
							       (@JournalBatchDetailId,
									@JournalTypeNumber,
									@currentNo,
									@DistributionSetupId,
									@DistributionName,
									@JournalBatchHeaderId,
									1 ,
									@GlAccountId ,
									@GlAccountNumber ,
									@GlAccountName,
									GETUTCDATE(),
									GETUTCDATE(),
									@JournalTypeId ,
									@JournalTypename ,
							        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							        CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							        CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							        @ManagementStructureId ,
									@ModuleName,
									@LastMSLevel,
									@AllMSlevels ,
									@MasterCompanyId,
									@UpdateBy,
									@UpdateBy,
									GETUTCDATE(),
									GETUTCDATE(),
									1,
									0
									,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
						INSERT INTO [dbo].[WorkOrderBatchDetails]
                                   ([JournalBatchDetailId],
								    [JournalBatchHeaderId],
									[ReferenceId],
									[ReferenceName],
									[MPNPartId],
									[MPNName],
									[PiecePNId],
									[PiecePN],
									[CustomerId],
									[CustomerName] ,
									[InvoiceId],
									[InvoiceName],
									[ARControlNum] ,
									[CustRefNumber] ,
									[Qty],
									[UnitPrice],
									[LaborHrs],
									[DirectLaborCost],
									[OverheadCost],
									[CommonJournalBatchDetailId],
									[Batchtype],
									[DistributionSetupId],
									[StocklineId],
									[IsWorkOrder])
                             VALUES
							       (@JournalBatchDetailId,
								    @JournalBatchHeaderId,
									@ReferenceId ,
									@SubWorkOrderNumber,
									@ReferencePartId,
									@MPNName,
									@ReferencePieceId,
									@PiecePN,@CustomerId,
									@CustomerName,
									NULL ,
									NULL,
									NULL,
									@CustRefNumber,
									@Qty,
									@UnitPrice,
									@LaborHrs,
									@DirectLaborCost,
									@OverheadCost,
									@CommonJournalBatchDetailId,
									@Batchtype,
									@DistributionSetupId,
									@MSStocklineId,									
									0)

						IF(@laborType='DIRECTLABOR')
						BEGIN
							SELECT TOP 1 @DistributionSetupId = ID,
							             @DistributionName = [Name],
										 @JournalTypeId = [JournalTypeId],
										 @GlAccountId = [GlAccountId],
										 @GlAccountNumber = [GlAccountNumber],
										 @GlAccountName = [GlAccountName],
										 @CrDrType = [CRDRType],
										 @IsAutoPost = ISNULL(IsAutoPost,0)
							        FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
								   WHERE UPPER([DistributionSetupCode]) = UPPER('DIRECTLABORP&LOFFSET') 
								    AND [DistributionMasterId] = @DistributionMasterId  
									AND [MasterCompanyId] = @MasterCompanyId
						END

						INSERT INTO [dbo].[CommonBatchDetails]
							       ([JournalBatchDetailId],
								    [JournalTypeNumber],
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
									[IsDeleted]
									,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						     VALUES
							        (@JournalBatchDetailId,
									 @JournalTypeNumber,
									 @currentNo,
									 @DistributionSetupId,
									 @DistributionName,
									 @JournalBatchHeaderId,
									 1 ,
									 @GlAccountId ,
									 @GlAccountNumber ,
									 @GlAccountName,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 @JournalTypeId ,
									 @JournalTypename ,
							         CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							         CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							         CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							         @ManagementStructureId ,
									 @ModuleName,
									 @LastMSLevel,
									 @AllMSlevels ,
									 @MasterCompanyId,
									 @UpdateBy,
									 @UpdateBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0
									 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							       ([JournalBatchDetailId],
								    [JournalBatchHeaderId],
									[ReferenceId],
									[ReferenceName],
									[MPNPartId],
									[MPNName],
									[PiecePNId],
									[PiecePN],
									[CustomerId],
									[CustomerName],
									[InvoiceId],
									[InvoiceName],
									[ARControlNum],
									[CustRefNumber] ,
							        [Qty],
									[UnitPrice],
									[LaborHrs],
									[DirectLaborCost],
									[OverheadCost],
									[CommonJournalBatchDetailId],
									[Batchtype],
									[DistributionSetupId],
									[StocklineId],
									[IsWorkOrder])
                             VALUES
							        (@JournalBatchDetailId,
									 @JournalBatchHeaderId,
									 @ReferenceId ,
									 @SubWorkOrderNumber ,
									 @ReferencePartId,
									 @MPNName,
									 @ReferencePieceId,
									 @PiecePN,
									 @CustomerId ,
									 @CustomerName,
									 NULL ,
									 NULL,
									 NULL,
									 @CustRefNumber,
							         @Qty,
									 @UnitPrice,
									 @LaborHrs,
									 @DirectLaborCost,
									 @OverheadCost,
									 @CommonJournalBatchDetailId,
									 @Batchtype,									 
									 @DistributionSetupId,
									 @MSStocklineId,
									 0)

						-----------------LABOR OVERHEAD --------------------------
						SET @Amount = ISNULL((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
						SET @OverheadCost = @Amount
						SET @DirectLaborCost = 0

						SELECT TOP 1 @DistributionSetupId = ID,
						             @DistributionName = [Name],
									 @JournalTypeId =JournalTypeId,
									 @GlAccountId=GlAccountId,
									 @GlAccountNumber=GlAccountNumber,
									 @GlAccountName=GlAccountName,
									 @CrDrType = CRDRType 
						        FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
								WHERE UPPER(DistributionSetupCode) = UPPER('WIPOVERHEAD') 
								  AND [DistributionMasterId] = @DistributionMasterId 
								  AND [MasterCompanyId]=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					    INSERT INTO [dbo].[WorkOrderBatchDetails]
                                   ([JournalBatchDetailId],
								    [JournalBatchHeaderId],
									[ReferenceId],
									[ReferenceName],
									[MPNPartId],
									[MPNName],
									[PiecePNId],
									[PiecePN],
									[CustomerId],
									[CustomerName],
									[InvoiceId],
									[InvoiceName],
									[ARControlNum],
									[CustRefNumber],
							        [Qty],
									[UnitPrice],
									[LaborHrs],
									[DirectLaborCost],
									[OverheadCost],
									[CommonJournalBatchDetailId],
									[Batchtype],
									[DistributionSetupId],
									[StocklineId],
									[IsWorkOrder])
                             VALUES
							       (@JournalBatchDetailId,
								    @JournalBatchHeaderId,
									@ReferenceId ,
									@SubWorkOrderNumber ,
									@ReferencePartId,
									@MPNName,
									@ReferencePieceId,
									@PiecePN,
									@CustomerId ,
									@CustomerName,
									NULL ,
									NULL,
									NULL,
									@CustRefNumber,
							        @Qty,
									@UnitPrice,
									@LaborHrs,
									@DirectLaborCost,
									@OverheadCost,
									@CommonJournalBatchDetailId,
									@Batchtype,
									@DistributionSetupId,
									@MSStocklineId,
									0)

						----------OVERHEADP&LOFFSET--------------------

						SELECT TOP 1 @DistributionSetupId=ID,
						             @DistributionName = [Name],
									 @JournalTypeId = [JournalTypeId],
									 @GlAccountId = [GlAccountId],
									 @GlAccountNumber = [GlAccountNumber],
									 @GlAccountName = [GlAccountName],
									 @CrDrType = CRDRType  
						       FROM [dbo].[DistributionSetup] WITH(NOLOCK)  
							   WHERE UPPER(DistributionSetupCode) = UPPER('OVERHEADP&LOFFSET') 
							    AND [DistributionMasterId] = @DistributionMasterId 
								AND [MasterCompanyId] = @MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							       ([JournalBatchDetailId],
								    [JournalTypeNumber],
									[CurrentNumber],
									[DistributionSetupId],
									[DistributionName],
									[JournalBatchHeaderId],
									[LineNumber],
									[GlAccountId],
									[GlAccountNumber],
									[GlAccountName] ,
									[TransactionDate],
									[EntryDate] ,
									[JournalTypeId],
									[JournalTypeName],
							        [IsDebit],
									[DebitAmount] ,
									[CreditAmount],
									[ManagementStructureId],
									[ModuleName],
									[LastMSLevel],
									[AllMSlevels],
									[MasterCompanyId],
									[CreatedBy],
									[UpdatedBy],
									[CreatedDate],
									[UpdatedDate] ,
									[IsActive] ,
									[IsDeleted]
									,[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						     VALUES
							        (@JournalBatchDetailId,
									 @JournalTypeNumber,
									 @currentNo,
									 @DistributionSetupId,
									 @DistributionName,
									 @JournalBatchHeaderId,
									 1 ,
									 @GlAccountId ,
									 @GlAccountNumber ,
									 @GlAccountName,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 @JournalTypeId ,
									 @JournalTypename ,
							         CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							         CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							         CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							         @ManagementStructureId ,
									 @ModuleName,
									 @LastMSLevel,
									 @AllMSlevels ,
									 @MasterCompanyId,
									 @UpdateBy,
									 @UpdateBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0
									 ,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId,[StocklineId],[IsWorkOrder])
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,@MSStocklineId, 0)

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
						UPDATE [dbo].[BatchDetails] set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

						--AutoPost Batch
						IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
						BEGIN
							EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
						END
						IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
						BEGIN
							EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
						END
					 END
					 ELSE
					 BEGIN
						IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						 BEGIN
							SET @ValidDistribution = 0;
						 END

						IF(@Amount > 0 AND @ValidDistribution = 1)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM [dbo].[BatchHeader] WITH(NOLOCK) Order by JournalBatchHeaderId desc 

									IF(CAST(@Currentbatch AS BIGINT) >99)
									BEGIN
										SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
									END
									ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
									BEGIN

										SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   						ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
									END
									ELSE
									BEGIN
										SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   						ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

									END
								END
								SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
								SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))
												          
								INSERT INTO [dbo].[BatchHeader]
											([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
								VALUES
											(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
								UPDATE [dbo].[BatchHeader] SET CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId = @JournalBatchHeaderId

							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									UPDATE [dbo].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod WHERE JournalBatchHeaderId = @JournalBatchHeaderId
								END

								SET @IsBatchGenerated = 1;
							END
							
							INSERT INTO [dbo].[BatchDetails]
								(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
							VALUES
								(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
				                
               				SET @JournalBatchDetailId=SCOPE_IDENTITY()

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
								[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId , [StocklineId],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,@MSStocklineId ,0)

							IF(@laborType='DIRECTLABOR')
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId , [StocklineId],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,@MSStocklineId, 0)

							-----------------LABOROVERHEAD --------------------------
							SET @Amount=ISNULL((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6) * @burdentRate,0)
							SET @OverheadCost=@Amount
							SET @DirectLaborCost=0
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[StocklineId], [IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId, @MSStocklineId ,0)

							----------OVERHEADP&LOFFSET--------------------

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
							FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

							SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId , [StocklineId],[IsWorkOrder])
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,@MSStocklineId, 0)

							SET @TotalDebit=0;
							SET @TotalCredit=0;
							SELECT @TotalDebit = SUM(DebitAmount), @TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
							Update [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		


							--AutoPost Batch
							IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
							BEGIN
								EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
							END
							IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
							BEGIN
								EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
							END
						END
					 END
					
					 SET @TotalDebit=0;
					 SET @TotalCredit=0;
					 SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
					 UPDATE [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId
				END
				ELSE
				BEGIN
					IF EXISTS(SELECT 1 FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END
					IF(@issued =0 AND @Amount > 0 AND @ValidDistribution = 1)
					BEGIN						
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM [dbo].[BatchHeader] WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId desc 

								IF(CAST(@Currentbatch AS BIGINT) > 99)
								BEGIN
									SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch AS VARCHAR(100))
				   					ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
								END
								ELSE IF(CAST(@Currentbatch AS BIGINT) > 9)
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
							SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))						
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()

							UPDATE [dbo].[BatchHeader] SET CurrentNumber=@CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId;
						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=ISNULL(AccountingPeriodId,0) FROM [dbo].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								UPDATE [dbo].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END

							SET @IsBatchGenerated = 1;
						END

						INSERT INTO [dbo].[BatchDetails]
							(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
						VALUES
							(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
				                 
						SET @JournalBatchDetailId=SCOPE_IDENTITY()

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId , [StocklineId], [IsWorkOrder])
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,@MSStocklineId,  0)

						IF(@laborType='DIRECTLABOR')
						BEGIN
							SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) = UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
						END

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId , [StocklineId],[IsWorkOrder])
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,  @MSStocklineId, 0)

						-----------------LABOROVERHEAD --------------------------
						SET @Amount = ISNULL((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
						SET @OverheadCost=@Amount
						SET @DirectLaborCost=0
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
						FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,[StocklineId],[IsWorkOrder])
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId, @MSStocklineId, 0)

						----------OVERHEADP&LOFFSET--------------------

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
						FROM [dbo].[DistributionSetup] WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@SubWorkOrderNumber,@CustomerName,@CurrencyCode,@FXRate,@CurrencyCode)

						SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId,[StocklineId],[IsWorkOrder])
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@SubWorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,@MSStocklineId, 0)

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						
						SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit = SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
						
						UPDATE [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate = GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

						--AutoPost Batch
						IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
						BEGIN
							EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
						END
						IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
						BEGIN
							EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
						END
					END

				END

				SELECT @TotalDebit = SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND IsDeleted=0 GROUP BY JournalBatchHeaderId
			   	                   
			    SET @TotalBalance = @TotalDebit - @TotalCredit;
				                   
			    UPDATE [dbo].[BatchHeader] SET TotalDebit = @TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
			END
			
			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes 
			END

		END

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonDistributionForSubWorkOrder' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@DistributionMasterId, '') + ''
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