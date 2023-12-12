/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonDistributionForInternalWO]
 ** Author:  Satish Gohil
 ** Description: This stored procedure is used to Accounting entry for Internal WO
 ** Purpose:         
 ** Date:   04/08/2023
         
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1	 04/08/2023  Satish Gohil   Created
	2    17/08/2023  Moin Bloch     Modify(Added Accounting MS Entry)
	3    25/08/2023  Moin Bloch     Modify(Added IsWorkorder Falg)
	4    30/11/2023  Moin Bloch     Modify(Added LotId And Lot Number in CommonBatchDetails)
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO]
@DistributionMasterId bigint=NULL,
@ReferenceId bigint=NULL,
@ReferencePartId bigint=NULL,
@ReferencePieceId bigint=NULL,
@InvoiceId bigint=NULL,
@StocklineId bigint=NULL,
@Qty int=0,
@laborType varchar(200)=NULL,
@issued  bit=0,
@Amount Decimal(18,2)=0,
@ModuleName varchar(200)=NULL,
@MasterCompanyId Int=0,
@UpdateBy varchar(200)=NULL
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
        DECLARE @WorkOrderNumber varchar(200) 
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

		SELECT @IsAccountByPass =IsAccountByPass FROM MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
	    SELECT @DistributionCode =DistributionCode FROM DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
	    SELECT @StatusId =Id,@StatusName=name FROM BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
	    SELECT top 1 @JournalTypeId =JournalTypeId FROM DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
	    SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
	    SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
	    SELECT @WopJounralTypeid =ID FROM JournalType WITH(NOLOCK)  WHERE JournalTypeCode= 'WIP'
		SELECT @CurrentManagementStructureId =isnull(ManagementStructureId,0) FROM Employee WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @CrDrType int=0
		DECLARE @ValidDistribution BIT = 1;
		DECLARE @LotId BIGINT = 0;
		DECLARE @LotNumber VARCHAR(50) = '';

		IF((@JournalTypeCode ='WIP' or @JournalTypeCode ='WOI' or @JournalTypeCode ='MRO-WO' or @JournalTypeCode ='FGI') and @IsAccountByPass=0)
		BEGIN 
			SELECT @WorkOrderNumber = WorkOrderNum,@CustomerId=CustomerId,@CustomerName= CustomerName FROM dbo.WorkOrder WITH(NOLOCK)  WHERE WorkOrderId=@ReferenceId
		              
			IF(@ReferencePartId =0)
			BEGIN
				SELECT top 1 @partId = WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkOrderId=@ReferenceId
			END
			ELSE 
			BEGIN
				SELECT @partId=WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId=@ReferencePartId
			END
					  
	        SELECT @ManagementStructureId = WOP.[ManagementStructureId],
			       @ItemmasterId = WOP.[ItemMasterId],
				   @CustRefNumber = WOP.[CustomerReference], 
			       @LotId = STL.[LotId],
				   @LotNumber = LO.[LotNumber]		
			FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)  
			LEFT JOIN [dbo].[Stockline] STL WITH(NOLOCK)  ON STL.[StockLineId] = WOP.[StockLineId]
			LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK)  ON LO.[LotId] = STL.[LotId]				
			WHERE WOP.[WorkOrderId] = @ReferenceId AND WOP.ID = @partId;

	        SELECT @MPNName = partnumber FROM 
			[dbo].[ItemMaster] WITH(NOLOCK) 
			WHERE ItemMasterId=@ItemmasterId 

	        SELECT @LastMSLevel=LastMSLevel,
			       @AllMSlevels=AllMSlevels 
			  FROM [dbo].[WorkOrderManagementStructureDetails] WITH(NOLOCK) 
			  WHERE ReferenceID=@partId

			IF(@CurrentManagementStructureId =0)
			BEGIN
				SET @CurrentManagementStructureId=@ManagementStructureId
			END

			SELECT top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM EntityStructureSetup est WITH(NOLOCK) 
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
			INNER JOIN AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)
		    SET @ReferencePartId=@partId	

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
				SELECT @PieceItemmasterId= WOM.ItemMasterId,
				       @UnitPrice= WOM.UnitCost,
					   @Amount=isnull((@Qty * WOM.UnitCost),0),
					   @LotId = STL.[LotId],
				       @LotNumber = LO.[LotNumber]	
				FROM [dbo].[WorkOrderMaterialStockLine] WOM WITH(NOLOCK) 
				LEFT JOIN [dbo].[Stockline] STL ON STL.[StockLineId] = WOM.[StockLineId]
				LEFT JOIN [dbo].[Lot] LO ON LO.[LotId] = STL.[LotId]		
				 WHERE WOM.StockLineId=@StocklineId

		        SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId
				
				SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
				FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPPARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

				IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF EXISTS(SELECT 1 FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(@issued =1 and @Amount > 0 AND @ValidDistribution = 1)
				BEGIN					
					IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
					BEGIN
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
						BEGIN	
							SET @batch ='001'
							SET @Currentbatch='001'
						END
						ELSE
						BEGIN
							SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   			FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
						
						Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

					END
					ELSE
					BEGIN
						SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
						SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   								FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
						IF(@CurrentPeriodId =0)
						BEGIN
							Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						END
					END
					
					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId]
						,[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
						@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										
					INSERT INTO [dbo].[WorkOrderBatchDetails]
						(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,StocklineId,StocklineNumber,IsWorkOrder)
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)


					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType from DistributionSetup 
							WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYPARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

					SELECT @GlAccountId=GlAccountId from Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId
					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName from GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

					SET @GlAccountId = ISNULL(@GlAccountId,0) 

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
						CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					INSERT INTO [dbo].[WorkOrderBatchDetails]
						(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,StocklineId,StocklineNumber ,IsWorkOrder)
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					UPDATE BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

				END
				ELSE
				BEGIN
					IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF EXISTS(SELECT 1 FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END
					
					IF(@Amount  > 0 AND @ValidDistribution = 1)
					BEGIN
						
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							print @CurrentNumber
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
						END

						INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],
						[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

						SET @JournalBatchDetailId=SCOPE_IDENTITY()

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,StocklineId,StocklineNumber ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber,1)

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType = CRDRType from DistributionSetup WITH(NOLOCK)  
						WHERE UPPER(DistributionSetupCode) =UPPER('INVENTORYPARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
						
						SELECT @GlAccountId=GlAccountId from Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId
						SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName from GLAccount WITH(NOLOCK) WHERE GLAccountId=@GlAccountId

						SET @GlAccountId = isnull(@GlAccountId,0) 
					
						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,
							[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,StocklineId,StocklineNumber,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@StocklineId,@StocklineNumber ,1)

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						
						UPDATE BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					END
				END

				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
			    SET @TotalBalance =@TotalDebit-@TotalCredit
				         
			    Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
	            UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId

			END

			IF(UPPER(@DistributionCode) = UPPER('WOLABORTAB'))
			BEGIN
				SET @Batchtype = 2
				DECLARE @Hours DECIMAL(18,2)
                DECLARE @Hourspay DECIMAL(18,2)
                DECLARE @LaborRate MONEY
				DECLARE @burdentRate MONEY

		        SELECT @LaborHrs=Isnull(AdjustedHours,0),@Hours=ISNULL(AdjustedHours,0),@DirectLaborCost=TotalCost,@OverheadCost=DirectLaborOHCost,@LaborRate=Isnull(DirectLaborOHCost,0),@burdentRate=Isnull(BurdenRateAmount,0) 
				FROM WorkOrderLabor WITH(NOLOCK)  WHERE WorkOrderLaborId=@ReferencePieceId
				SET @Qty=0;

				IF(@laborType='DIRECTLABOR')
				BEGIN
					SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@LaborRate,0)
					SET @DirectLaborCost=@Amount
					SET @OverheadCost=0
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
					FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPDIRECTLABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
				END

				IF NOT EXISTS(SELECT woB.WorkOrderBatchId from WorkOrderBatchDetails woB WITH(NOLOCK)  WHERE PiecePNId= @ReferencePieceId and Batchtype=@Batchtype and DistributionSetupId=@DistributionSetupId)
				BEGIN
					 IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
					 BEGIN
						SET @ValidDistribution = 0;
					 END

					
					 IF(@issued =1 and @Amount >0 AND @ValidDistribution = 1)
					 BEGIN

						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							print @CurrentNumber
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
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
							[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

						IF(@laborType='DIRECTLABOR')
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
						END

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

						-----------------LABOROVERHEAD --------------------------
						SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
						SET @OverheadCost=@Amount
						SET @DirectLaborCost=0
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId,1)

						----------OVERHEADP&LOFFSET--------------------

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

					 END
					 ELSE
					 BEGIN
						IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						 BEGIN
							SET @ValidDistribution = 0;
						 END

						IF(@Amount >0 AND @ValidDistribution = 1)
						BEGIN

							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								print @CurrentNumber
				          
								INSERT INTO [dbo].[BatchHeader]
											([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
								VALUES
											(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
								Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END
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
								[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

							IF(@laborType='DIRECTLABOR')
							BEGIN
								SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
								from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
							END

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END,
								@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

							-----------------LABOROVERHEAD --------------------------
							SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
							SET @OverheadCost=@Amount
							SET @DirectLaborCost=0
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

							----------OVERHEADP&LOFFSET--------------------

							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @Amount ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @Amount END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
								Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId  ,IsWorkOrder)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
								@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

							SET @TotalDebit=0;
							SET @TotalCredit=0;
							SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
							Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

						END
					 END
					
					 SET @TotalDebit=0;
					 SET @TotalCredit=0;
					 SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					 Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId
				END
				ELSE
				BEGIN
					IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
					BEGIN
						SET @ValidDistribution = 0;
					END

					IF(@issued =0 and @Amount >0 AND @ValidDistribution = 1)
					BEGIN
						
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							print @CurrentNumber
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
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
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId  ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

						IF(@laborType='DIRECTLABOR')
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DIRECTLABORP&LOFFSET') and DistributionMasterId =@DistributionMasterId  AND MasterCompanyId=@MasterCompanyId
						END

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
							@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId  ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId ,1)

						-----------------LABOROVERHEAD --------------------------
						SET @Amount=Isnull((CAST(@Hours AS INT) + (@Hours - CAST(@Hours AS INT))/.6)*@burdentRate,0)
						SET @OverheadCost=@Amount
						SET @DirectLaborCost=0
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WIPOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId , 1)

						----------OVERHEADP&LOFFSET--------------------

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType  
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('OVERHEADP&LOFFSET') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,
							Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,Batchtype,DistributionSetupId  ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,
							@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@Batchtype,@DistributionSetupId , 1)

						SET @TotalDebit=0;
						SET @TotalCredit=0;
						SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
						Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId		

					END

				END

				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	                   
			    SET @TotalBalance =@TotalDebit-@TotalCredit
				                   
			    Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
			END

			IF(UPPER(@DistributionCode) = UPPER('WOSETTLEMENTTAB'))
			BEGIN
				SELECT @MaterialCost=PartsCost,@LaborCost=(Isnull(WOPN.LaborCost,0)-Isnull(WOPN.OverHeadCost,0)),@LaborOverHeadCost=(Isnull(WOPN.OverHeadCost,0)) from WorkOrderMPNCostDetails  WOPN WITH(NOLOCK)
                        WHERE WOPN.WOPartNoId=@partId 
					 
				SET @FinishGoodAmount=Isnull((@MaterialCost+@LaborCost+@LaborOverHeadCost),0)

				IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				
				IF(@issued = 1 AND @ValidDistribution = 1)
				BEGIN
					-----Finish Goods------
					IF(@FinishGoodAmount >0 )
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FGINVENTROY') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
				        
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							print @CurrentNumber
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
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
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					    
						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId , IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
					    
						IF(@MaterialCost > 0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-PARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
					    
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN @MaterialCost ELSE 0 END,
								CASE WHEN @CrDrType = 1 THEN 0 ELSE @MaterialCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					    
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,IsWorkOrder)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
					    END
					END

					-----WIPDIRECTLABOR------

					IF(@LaborCost > 0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-LABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @LaborCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0,@CommonJournalBatchDetailId,1)

					END

					-----WIPOVERHEAD------
					IF(@LaborOverHeadCost >0)
					BEGIN

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-OVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId


						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @LaborOverHeadCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborOverHeadCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost,@CommonJournalBatchDetailId,1)


					END

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					          
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId 	          
					SET @TotalBalance =@TotalDebit-@TotalCredit
					UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

				END
				
				IF(@issued = 0 AND @ValidDistribution = 1)
				BEGIN
					-----Finish Goods------
					IF(@FinishGoodAmount >0 )
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FGINVENTROY') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
				        
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							print @CurrentNumber
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
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
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN @FinishGoodAmount ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN 0 ELSE @FinishGoodAmount END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					    
						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId ,1)
					    
						IF(@MaterialCost > 0)
						BEGIN
							SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
							FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-PARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId
					    
							INSERT INTO [dbo].[CommonBatchDetails]
								(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN @MaterialCost ELSE 0 END,
								CASE WHEN @CrDrType = 0 THEN 0 ELSE @MaterialCost END
								,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					    
							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							-----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					    
							INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
							VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
					    END
					END

					-----WIPDIRECTLABOR------

					IF(@LaborCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-LABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN @LaborCost ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN 0 ELSE @LaborCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0,@CommonJournalBatchDetailId ,1)

					END

					-----WIPOVERHEAD------
					IF(@LaborOverHeadCost >0)
					BEGIN

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('FG-WIP-OVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId


						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 0 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN @LaborOverHeadCost ELSE 0 END,
							CASE WHEN @CrDrType = 0 THEN 0 ELSE @LaborOverHeadCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost,@CommonJournalBatchDetailId,1)


					END

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

					          
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId 	          
					SET @TotalBalance =@TotalDebit-@TotalCredit
					UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

				END

				
				
			END

			IF(UPPER(@DistributionCode) = UPPER('MROWOSHIPMENT'))
			BEGIN				
				SELECT @MaterialCost=SUM(Isnull(WOPN.PartsCost,0)),@LaborCost=(SUM(Isnull(WOPN.LaborCost,0))-SUM(Isnull(WOPN.OverHeadCost,0))),@LaborOverHeadCost=SUM(Isnull(WOPN.OverHeadCost,0)) from WorkOrderMPNCostDetails  WOPN 
                INNER JOIN WorkOrderShippingItem WOBIT on WOPN.WOPartNoId= WOBIT.WorkOrderPartNumId
                WHERE WorkOrderShippingId=@InvoiceId and WOBIT.IsDeleted=0   group by WorkOrderShippingId
								
				SELECT @LotId = STL.[LotId],
				       @LotNumber = LO.[LotNumber]		
				FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)  
				LEFT JOIN [dbo].[Stockline] STL WITH(NOLOCK)  ON STL.[StockLineId] = WOP.[StockLineId]
				LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK)  ON LO.[LotId] = STL.[LotId]				
				WHERE WOP.ID = @ReferencePartId;
														
				SET @FinishGoodAmount=Isnull((@MaterialCost+@LaborCost+@LaborOverHeadCost),0)

				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
				FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('MROWOINVENTORYTOBILL') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

				IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(@ValidDistribution = 1)
				BEGIN
					IF NOT EXISTS(SELECT woB.WorkOrderBatchId from WorkOrderBatchDetails woB WITH(NOLOCK)  WHERE PiecePNId= @ReferencePieceId and DistributionSetupId=@DistributionSetupId)
					BEGIN
						IF(@FinishGoodAmount > 0)
						BEGIN
							
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
							BEGIN
								IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
								BEGIN	
									SET @batch ='001'
									SET @Currentbatch='001'
								END
								ELSE
								BEGIN
									SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
								print @CurrentNumber
				          
								INSERT INTO [dbo].[BatchHeader]
											([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
								VALUES
											(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
								SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
								Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

							END
							ELSE
							BEGIN
								SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
								SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   										FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
								IF(@CurrentPeriodId =0)
								BEGIN
									Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
								END
							END

							-----Inventory to Bill ------
							INSERT INTO [dbo].[BatchDetails]
								(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],
								[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[AccountingPeriodId],[AccountingPeriod])
							VALUES
								(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
								1,0,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
							 
							 SET @JournalBatchDetailId=SCOPE_IDENTITY()

							 INSERT INTO [dbo].[CommonBatchDetails]
								 (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								 [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							 VALUES
								 (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								 CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								 CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
								 CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
								 ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							 SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

							 -----  Accounting MS Entry  -----

							EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							 INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,DistributionSetupId, IsWorkOrder)
							 VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@DistributionSetupId, 1)


							 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
							 FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('MROWOFGINVENTROY') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

							  INSERT INTO [dbo].[CommonBatchDetails]
								  (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
								  [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
							  VALUES
								  (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
								  CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
								  CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
								  CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
								 ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

							  SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

							  -----  Accounting MS Entry  -----

							  EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

							  INSERT INTO [dbo].[WorkOrderBatchDetails]
								(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId,DistributionSetupId  ,IsWorkOrder)
							  VALUES
								(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,@DistributionSetupId,1)

							 SET @TotalDebit=0;
							 SET @TotalCredit=0;
							 SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
							 Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

						END
					END

					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
					SET @TotalBalance =@TotalDebit-@TotalCredit
					UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
					Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				END
			END
			
			IF(UPPER(@DistributionCode) = UPPER('WOINVOICINGTAB'))
	        BEGIN
				SELECT @InvoiceNo=InvoiceNo,@InvoiceTotalCost=Isnull(GrandTotal,0),@MaterialCost=Isnull(MaterialCost,0),
					@FreightCost=isnull(FreightCost,0),@SalesTax=isnull(SalesTax,0),@OtherTax = isnull(OtherTax,0),@MiscChargesCost=isnull(MiscChargesCost,0) from WorkOrderBillingInvoicing 
					WHERE BillingInvoicingId=@InvoiceId         
				SELECT top 1 @Qty=NoofPieces from WorkOrderBillingInvoicingItem   WHERE BillingInvoicingId=@InvoiceId 

				SELECT @LaborCost=(SUM(Isnull(WOPN.LaborCost,0))-SUM(Isnull(WOPN.OverHeadCost,0))),@LaborOverHeadCost=SUM(Isnull(WOPN.OverHeadCost,0)) from WorkOrderMPNCostDetails  WOPN 
                INNER JOIN WorkOrderBillingInvoicingItem WOBIT on WOPN.WOPartNoId= WOBIT.WorkOrderPartId
                WHERE BillingInvoicingId=@InvoiceId and IsVersionIncrease=0   group by BillingInvoicingId
					 
				SET @RevenuWO=@InvoiceTotalCost-(@FreightCost+@MiscChargesCost+@SalesTax+@OtherTax)
				SET @FinishGoodAmount=Isnull((@MaterialCost+@LaborCost+@LaborOverHeadCost),0)

				SELECT @LotId = STL.[LotId],
				       @LotNumber = LO.[LotNumber]		
				FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)  
				LEFT JOIN [dbo].[Stockline] STL WITH(NOLOCK)  ON STL.[StockLineId] = WOP.[StockLineId]
				LEFT JOIN [dbo].[Lot] LO WITH(NOLOCK)  ON LO.[LotId] = STL.[LotId]				
				WHERE WOP.ID = @ReferencePartId;

				IF EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
				BEGIN
					SET @ValidDistribution = 0;
				END

				IF(@issued =1 AND @ValidDistribution = 1)
				BEGIN
					-----ACCOUNTSRECEIVABLETRADE------
					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
					FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WOIACCRECVINTERCO') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

					 IF(@InvoiceTotalCost >0)
					 BEGIN						
						IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
						BEGIN
							IF NOT EXISTS(SELECT JournalBatchHeaderId FROM BatchHeader WITH(NOLOCK))
							BEGIN	
								SET @batch ='001'
								SET @Currentbatch='001'
							END
							ELSE
							BEGIN
								SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END 
				   				FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

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
							print @CurrentNumber
				          
							INSERT INTO [dbo].[BatchHeader]
										([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
							VALUES
										(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ModuleName);
            	          
							SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
							Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

						END
						ELSE
						BEGIN
							SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
							SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   									FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
							IF(@CurrentPeriodId =0)
							BEGIN
								Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
							END
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
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @InvoiceTotalCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @InvoiceTotalCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

					 END

					 -----COGSPARTS------
					 IF(@MaterialCost >0)
					 BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSPARTS') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @MaterialCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @MaterialCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId,1)
					  		
					END

					-----COGSDIRECTLABOR------
					IF(@LaborCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSDIRECTLABOR') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @LaborCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0,@CommonJournalBatchDetailId ,1)
					  		
					END

					-----COGSOVERHEAD------
					IF(@LaborOverHeadCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('COGSOVERHEAD') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @LaborOverHeadCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @LaborOverHeadCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost,@CommonJournalBatchDetailId ,1)
					  		
					END

					-----Inventory to Bill-----
					IF(@FinishGoodAmount >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType 
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WOIINVENTORYTOBILL') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
						  (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						  [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
						  (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
						  CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
						  CASE WHEN @CrDrType = 1 THEN @FinishGoodAmount ELSE 0 END,
						  CASE WHEN @CrDrType = 1 THEN 0 ELSE @FinishGoodAmount END
						  ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost,@CommonJournalBatchDetailId ,1)
					 
					END

					IF(@MiscChargesCost >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType = CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEMISCCHARGE') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @MiscChargesCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @MiscChargesCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						  
						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId ,1)

					END

					-----REVENUEFREIGHT------

					IF(@FreightCost >0)
					BEGIN

						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('REVENUEFREIGHT') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
							,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @FreightCost ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @FreightCost END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						  
						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

					END

					-----SALESTAXPAYABLEWOI------
					IF(@SalesTax >0)
					BEGIN
						
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
						from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('SALESTAXPAYABLEWOI') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
							,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename
							,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @SalesTax ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @SalesTax END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						    
						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

					END

					-----OTHERTAXPAYABLEWOI------
					IF(@OtherTax >0)
					BEGIN
						
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
						from DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WOIOTHERTAX') And DistributionMasterId=@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName]
							,[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename
							,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @OtherTax ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @OtherTax END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)
						    
						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					    INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
                        VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId,1)

					END

					-----REVENUEWO------
					IF(@RevenuWO >0)
					BEGIN
						SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType
						FROM DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('WOIREVENUEINTERCO') and DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId

						INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[LotId],[LotNumber])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename
							,CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @RevenuWO ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @RevenuWO END
							,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@LotId,@LotNumber)

						SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

						-----  Accounting MS Entry  -----

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

						INSERT INTO [dbo].[WorkOrderBatchDetails]
							(JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost,CommonJournalBatchDetailId  ,IsWorkOrder)
						VALUES
							(@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,@InvoiceId ,@InvoiceNo,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0,@CommonJournalBatchDetailId ,1)
							                    
					END

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
					
					UPDATE BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchDetailId=@JournalBatchDetailId

				END

				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
			    SET @TotalBalance =@TotalDebit-@TotalCredit
				
				UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
			    
				UPDATE BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId

			END
			
			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefixes 
			END

			--SET @ValidEntry = @ValidDistribution

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
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonDistribution' 
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