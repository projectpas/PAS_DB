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
 ** PR   Date         Author		     Change Description            
 ** --   --------     -------		     --------------------------------          
    1    08/10/2022   Subhash Saliya     Created
	2	 08/12/2023	  Satish Gohil	     Dynamic GlAccount Added for particular distribution
	3	 08/16/2023	  Amit Ghediya	     Updated Fix entry for ACCUMULATEDDEPRECIATION to DR/CR. 
	4    21/08/2023   Moin Bloch         Modify(Added Accounting MS Entry)
	5    1/JAN/2024   AYESHA SULTANA     MODIFY(GETTING @SelectedAccountingPeriodId FROM API)
	7    14/02/2023	  Moin Bloch		 Updated Used Distribution Setup Code Insted of Name 
	8	 23/05/2024   Abhishek Jirawla   Changing UnitCost to Total Cost

-- EXEC USP_BatchTriggerBasedonDistribution 3
   EXEC [dbo].[USP_CreateBatch_Asset_inventory] 10406,1,'150.00','AssetInventory','admin',1,'AssetWriteOff',0
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_CreateBatch_Asset_inventory]
(
	@AssetInventoryId bigint=NULL,
	@Qty int=0,
	@Amount Decimal(18,2),
	@ModuleName varchar(200),
	@UpdateBy varchar(200),
	@MasterCompanyId bigint,
	@StockType varchar(100),
	@BatchId BIGINT OUTPUT,
	@SelectedAccountingPeriodId bigint=NULL
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Declare @JournalTypeId int
	    Declare @JournalTypeCode varchar(200) 
	    Declare @JournalBatchHeaderId bigint
	    Declare @GlAccountId int
	    Declare @StatusId int
	    Declare @StatusName varchar(200)
	    Declare @StartsFROM varchar(200)='00'
	    Declare @CurrentNumber int
	    Declare @GlAccountName varchar(200) 
	    Declare @GlAccountNumber varchar(200) 
	    Declare @JournalTypename varchar(200) 
	    Declare @Distributionname varchar(200) 
	    Declare @ManagementStructureId bigint
        Declare @WorkOrderNumber varchar(200) 
        Declare @MPNName varchar(200) 
	    Declare @PiecePNId bigint
        Declare @PiecePN varchar(200) 
	    Declare @PieceItemmasterId bigint
	    Declare @CustRefNumber varchar(200)
	    declare @LineNumber int=1
	    declare @TotalDebit decimal(18,2)=0
	    declare @TotalCredit decimal(18,2)=0
	    declare @TotalBalance decimal(18,2)=0
	    declare @UnitPrice decimal(18,2)=0
	    declare @LaborHrs decimal(18,2)=0
	    declare @DirectLaborCost decimal(18,2)=0
	    declare @OverheadCost decimal(18,2)=0
	    declare @partId bigint=0
		declare @batch varchar(100)
		declare @AccountingPeriod varchar(100)
		declare @AccountingPeriodId bigint=0
		declare @CurrentPeriodId bigint=0
		declare @Currentbatch varchar(100)
	    declare @LastMSLevel varchar(200)
		declare @AllMSlevels varchar(max)
		declare @DistributionSetupId int=0
		declare @IsAccountByPass bit=0
		declare @DistributionCode varchar(200)
		declare @InvoiceTotalCost decimal(18,2)=0
	    declare @MaterialCost decimal(18,2)=0
	    declare @LaborOverHeadCost decimal(18,2)=0
	    declare @FreightCost decimal(18,2)=0
		declare @SalesTax decimal(18,2)=0
		declare @InvoiceNo varchar(100)
		declare @MiscChargesCost decimal(18,2)=0
		declare @LaborCost decimal(18,2)=0
		declare @InvoiceLaborCost decimal(18,2)=0
		declare @RevenuWO decimal(18,2)=0
		declare @CurrentManagementStructureId bigint=0

		DECLARE @DistributionMasterId bigint;
		Declare @VendorId bigint;
		Declare @VendorName varchar(50);
		DECLARE @ReferenceId bigint=NULL;
		DECLARE @ItemMasterId bigint=NULL;
		DECLARE @STKMSModuleID bigint=2;
		DECLARE @NONStockMSModuleID bigint=11;
		DECLARE @AssetMSModuleID bigint=42;
		DECLARE @ReferencePartId BIGINT=0;
		DECLARE @ReferencePieceId BIGINT=0;
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @PurchaseOrderId BIGINT=0;
		DECLARE @PurchaseOrderNumber varchar(50)='';
		DECLARE @RepairOrderId BIGINT=0;
		DECLARE @RepairOrderNumber varchar(50)='';
		DECLARE @StocklineNumber varchar(50)='';
		DECLARE @SiteId BIGINT;
		DECLARE @Site varchar(100)='';
		DECLARE @WarehouseId BIGINT;
		DECLARE @Warehouse varchar(100)='';
		DECLARE @LocationId BIGINT;
		DECLARE @Location varchar(100)='';
		DECLARE @BinId BIGINT;
		DECLARE @Bin varchar(100)='';
		DECLARE @ShelfId BIGINT;
		DECLARE @Shelf varchar(100)='';
		DECLARE @Desc varchar(100);
		DECLARE @AssetInventoryName varchar(100);
		DECLARE @AssetName varchar(100);

		DECLARE @DeprFrequency varchar(50);
        DECLARE @AssetCreateDate Datetime2(7);
        DECLARE @ExistStatus varchar(50);
        DECLARE @DATEDIFF int=0;
        DECLARE @YearDIFF bigint=0;
        DECLARE @MonthDIFF bigint=0;
        DECLARE @DividedDaysDIFF int=0;
        DECLARE @AssetLife int;
		DECLARE @AssetTotalPrice decimal(18,2)=0;
		DECLARE @ResidualPercentage decimal(18,2)=0;
		DECLARE @DepreciationAmount decimal(18,2)=0;
		DECLARE @PercentageAmount decimal(18,2)=0;
		DECLARE @MonthlyDepAmount decimal(18,2)=0;
		DECLARE @ARCaseAmount decimal(18,2)=0;
        DECLARE @TangibleClassId int;
		DECLARE @StocktypeAsset varchar(50)='ASSET';
		declare @CommonJournalBatchDetailId bigint=0;
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @JournalTypeNumber varchar(100);
		DECLARE @AcquiredGLAccountId AS BIGINT = 0;
		DECLARE @DeprExpenseGLAccountId AS BIGINT = 0;
		DECLARE @AdDepsGLAccountId AS BIGINT = 0;
		DECLARE @AssetSaleGLAccountId AS BIGINT = 0;
		DECLARE @AssetWriteOffGLAccountId AS BIGINT = 0;
		DECLARE @AssetWriteDownGLAccountId AS BIGINT = 0;
		DECLARE @IntangibleGLAccountId AS BIGINT = 0;
		DECLARE @AmortExpenseGLAccountId AS BIGINT = 0;
		DECLARE @AccAmortDeprGLAccountId AS BIGINT = 0;
		DECLARE @IntangibleWriteDownGLAccountId AS BIGINT = 0;
		DECLARE @IntangibleWriteOffGLAccountId AS BIGINT = 0;
		DECLARE @CrDrType int=0;

		DECLARE @AccountMSModuleId INT = 0
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @DistributionMasterId =ID FROM DBO.DistributionMaster WITH(NOLOCK)  WHERE UPPER(DistributionCode)= UPPER('AssetInventory')

		SELECT @IsAccountByPass =IsAccountByPass FROM DBO.MasterCompany WITH(NOLOCK)  WHERE MasterCompanyId= @MasterCompanyId
		SELECT @DistributionCode =DistributionCode FROM DBO.DistributionMaster WITH(NOLOCK)  WHERE ID= @DistributionMasterId
		SELECT @StatusId =Id,@StatusName=name FROM DBO.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
		SELECT top 1 @JournalTypeId =JournalTypeId FROM DBO.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
		SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM DBO.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
		SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM DBO.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
		SELECT @CurrentManagementStructureId =ManagementStructureId FROM DBO.AssetInventory WITH(NOLOCK)  WHERE AssetInventoryId=@AssetInventoryId and MasterCompanyId=@MasterCompanyId

		SELECT @AcquiredGLAccountId= AcquiredGLAccountId,@DeprExpenseGLAccountId= DeprExpenseGLAccountId,@AdDepsGLAccountId= AdDepsGLAccountId,
		@AssetSaleGLAccountId=AssetSaleGLAccountId,@AssetWriteOffGLAccountId=AssetWriteOffGLAccountId,@AssetWriteDownGLAccountId=AssetWriteDownGLAccountId,
		@IntangibleGLAccountId=IntangibleGLAccountId,@AmortExpenseGLAccountId=AmortExpenseGLAccountId,@AccAmortDeprGLAccountId=AccAmortDeprGLAccountId,
		@IntangibleWriteDownGLAccountId=IntangibleWriteDownGLAccountId,@IntangibleWriteOffGLAccountId=IntangibleWriteOffGLAccountId 
		FROM DBO.AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@AssetInventoryId;

		SELECT @AssetTotalPrice=isnull(AI.TotalCost,0),@TangibleClassId=Asset.TangibleClassId,@DeprFrequency=AI.DepreciationFrequencyName,
		@AssetLife=Isnull(AI.AssetLife,0),@AssetCreateDate=AI.EntryDate,@ResidualPercentage=Isnull(AI.ResidualPercentage,0) 
		FROM DBO.AssetInventory AI WITH(NOLOCK)
        INNER JOIN DBO.Asset WITH(NOLOCK) on Asset.AssetRecordId=AI.AssetRecordId
		WHERE AI.AssetInventoryId= @AssetInventoryId
        Print @DeprFrequency
		SET @PercentageAmount = ISNULL((ISNULL(@ResidualPercentage,0) * ISNULL(@AssetTotalPrice,0) /100),0)
		SET @MonthlyDepAmount = ISNULL((ISNULL(@AssetTotalPrice,0)-ISNULL(@PercentageAmount,0)) / ISNULL(@AssetLife,0),0)

		IF(UPPER(@DeprFrequency)='MTHLY' OR UPPER(@DeprFrequency)='MONTHLY')
        BEGIN
            SET @DATEDIFF= DATEDIFF(day, CAST(@AssetCreateDate as date),CAST(getdate() as date))
            SET @MonthDIFF= DATEDIFF(month, CAST(@AssetCreateDate as date),CAST(getdate() as date))
            SET @DividedDaysDIFF=isnull((isnull(@DATEDIFF,1)/30),0)
            SET @ExistStatus=case when (@DividedDaysDIFF%1)= 0 then 'Even' else 'Odd' end
            Print @ExistStatus
			IF (@MonthDIFF <=@AssetLife)
            BEGIN
				SET @DepreciationAmount = ISNULL(@MonthlyDepAmount,0)
            END
        END
		IF(UPPER(@DeprFrequency)='QTLY' OR UPPER(@DeprFrequency)='QUATERLY')
        BEGIN
            SET @DATEDIFF= DATEDIFF(day, CAST(@AssetCreateDate as date),CAST(getdate() as date))
            SET @MonthDIFF= DATEDIFF(month, CAST(@AssetCreateDate as date),CAST(getdate() as date))
            SET @DividedDaysDIFF=isnull((isnull(@DATEDIFF,1)/90),0)
            SET @ExistStatus=case when (@DividedDaysDIFF%1)= 0 then 'Even' else 'Odd' end
            Print @ExistStatus
			IF(@MonthDIFF <=@AssetLife)
            BEGIN
				SET @DepreciationAmount = (ISNULL(@MonthlyDepAmount,0) * 3)
            END
        END
		IF(UPPER(@DeprFrequency)='YRLY' OR UPPER(@DeprFrequency)='YEARLY')
        BEGIN
            SET @DATEDIFF= DATEDIFF(day, CAST(@AssetCreateDate as date),CAST(getdate() as date))
            SET @MonthDIFF= DATEDIFF(month, CAST(@AssetCreateDate as date),CAST(getdate() as date))
            SET @DividedDaysDIFF=isnull((isnull(@DATEDIFF,1)/365),0)
            SET @ExistStatus=case when (@DividedDaysDIFF%1)= 0 then 'Even' else 'Odd' end
            Print @ExistStatus
			IF(@MonthDIFF <=@AssetLife)
            BEGIN
				SET @DepreciationAmount = (ISNULL(@MonthlyDepAmount,0) * 12)
            END
        END
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
				StartsFROM BIGINT NULL,
		)

		INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFROM) 
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFROM 
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

		IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
		BEGIN 
			SELECT 
				@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
					ELSE CAST(StartsFROM AS BIGINT) + 1 END 
			FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

			SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
		END
		ELSE 
		BEGIN
			ROLLBACK TRAN;
		END

		IF(@SelectedAccountingPeriodId = 0)
		BEGIN
			SET @SelectedAccountingPeriodId = NULL
		END

		IF((@JournalTypeCode ='AST') and @IsAccountByPass=0)
		BEGIN

			IF(@SelectedAccountingPeriodId = NULL)
			BEGIN
				SELECT top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM dbo.EntityStructureSetup est WITH(NOLOCK) 
				INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
				WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(getdate() as date)   >= CAST(FROMDate as date) and  CAST(getdate() as date) <= CAST(ToDate as date)
			END
			ELSE
			BEGIN 
				SELECT top 1  @AccountingPeriodId=ACC.AccountingCalendarId,@AccountingPeriod=ACC.PeriodName 
				FROM AccountingCalendar ACC 
				WHERE ACC.AccountingCalendarId=@SelectedAccountingPeriodId 
			END
			
			IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
            BEGIN
				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
				BEGIN
					set @batch ='001'
					set @Currentbatch='001'
			    END
				ELSE 
				BEGIN
					SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
				   		ELSE  1 END 
				   	FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

					if(CAST(@Currentbatch AS BIGINT) >99)
					begin

						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
					end
					Else if(CAST(@Currentbatch AS BIGINT) >9)
					begin

						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   				ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
					end
					else
					begin
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   				ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

					end
				END
				SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
                SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))

				INSERT INTO [dbo].[BatchHeader]
					([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
                VALUES
					(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'AST');
            	          
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
				Update BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId

			END
			ELSE
			BEGIN
				SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
			    SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   					    FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
				if(@CurrentPeriodId =0)
				begin
					Update dbo.BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				END
			END

			IF(UPPER(@DistributionCode) = UPPER('AssetInventory') AND UPPER(@StockType) = 'AssetPeriodDepreciation')
			BEGIN
				SELECT @ReferenceId=AssetInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
				,@SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],@Shelf=[ShelfName]
				,@AssetInventoryName=InventoryNumber
				FROM dbo.AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@AssetInventoryId;
				
				SELECT @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId FROM dbo.PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
				SELECT @VendorName =VendorName FROM Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
						
				SET @UnitPrice = @DepreciationAmount;
				SET @Amount = isnull(@DepreciationAmount,0);

				IF(@Amount > 0)
				BEGIN

					SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId FROM AssetInventory WHERE AssetInventoryId=@AssetInventoryId;
					SELECT @MPNName = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
					SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM dbo.AssetManagementStructureDetails  WHERE ReferenceID=@AssetInventoryId AND ModuleID=@AssetMSModuleID
					Set @ReferencePartId=@partId	

					SELECT @PieceItemmasterId=MasterPartId FROM AssetInventory  WHERE AssetInventoryId=@AssetInventoryId
					SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 

					------Depreciation Expense -----------

					SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType 
					FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('DEPRECIATIONEXPENSE') 
					AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@DeprExpenseGLAccountId 
					FROM dbo.GLAccount WITH(NOLOCK) WHERE GLAccountId=@DeprExpenseGLAccountId

					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,1,0,0,
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
						VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
							CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
							CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

					------Accumulated Depreciation -----------

					SET @Amount = isnull(@DepreciationAmount,0);
					SELECT TOP 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType
					FROM dbo.DistributionSetup WITH(NOLOCK)  
					WHERE UPPER(DistributionSetupCode) =UPPER('ACCUMULATEDDEPRECIATION') AND 
					DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId
					
					SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId
					FROM DBO.GLAccount WITH(NOLOCK) WHERE GLAccountId=@AdDepsGLAccountId

					INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						   0,0,@Amount,
						   @ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			        Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId


					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @AssetInventoryId
				END
			END

			IF(UPPER(@DistributionCode) = UPPER('AssetInventory') AND (UPPER(@StockType) = 'AssetSale' OR UPPER(@StockType) = 'AssetWriteOff'))
			BEGIN
				SELECT @ReferenceId=AssetInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
				,@SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],@Shelf=[ShelfName]
				,@AssetInventoryName=InventoryNumber
				FROM AssetInventory WHERE AssetInventoryId=@AssetInventoryId;
				SELECT @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId FROM PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
				SELECT @VendorName =VendorName FROM Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
					  
						
				SET @UnitPrice = @Amount;
				SET @Amount = (@ARCaseAmount);

				SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId FROM AssetInventory WHERE AssetInventoryId=@AssetInventoryId;
	            SELECT @MPNName = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
	            SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM AssetManagementStructureDetails  WHERE ReferenceID=@AssetInventoryId AND ModuleID=@AssetMSModuleID
				Set @ReferencePartId=@partId	

				SELECT @PieceItemmasterId=MasterPartId FROM AssetInventory  WHERE AssetInventoryId=@AssetInventoryId
		        SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 

				IF(@JournalBatchDetailId = 0)
				BEGIN
					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()
				END

				------Accounts Receivable (Trade or Other) -----------
				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName,@CrDrType=CRDRType 
				FROM DBO.DistributionSetup WITH(NOLOCK)  
				WHERE UPPER(DistributionSetupCode) =UPPER('ACCOUNTSRECEIVABLE(TRADE)') 
				AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId


				IF(@Amount >0)
				BEGIN
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

					
					SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

				END
				
				------Accounts Receivable (Trade or Other) -----------

				------Accumulated Depreciation -----------
				SET @Amount = (@DepreciationAmount);
				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType 
				FROM dbo.DistributionSetup WITH(NOLOCK) 
				WHERE UPPER(DistributionSetupCode) =UPPER('ACCUMULATEDDEPRECIATION') AND DistributionMasterId=@DistributionMasterId
				 AND MasterCompanyId = @MasterCompanyId

				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AdDepsGLAccountId 
				FROM DBO.GLAccount WHERE GLAccountId=@AdDepsGLAccountId

				IF(@JournalBatchDetailId = 0)
				BEGIN
					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,1,@DepreciationAmount ,0,
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

					SET @JournalBatchDetailId=SCOPE_IDENTITY()
				END

				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
					1,@DepreciationAmount,0,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
					
				SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

				INSERT INTO [StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
					@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

				------Accumulated Depreciation -----------

				------Asset Account -----------
				SET @Amount =  ISNULL((ISNULL(@AssetTotalPrice,0)-ISNULL(@PercentageAmount,0)),0);

				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@CrDrType=CRDRType 
				FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('ASSETACCOUNT') AND
				DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AcquiredGLAccountId 
				FROM GLAccount WHERE GLAccountId=@AssetSaleGLAccountId

				IF(@JournalBatchDetailId = 0)
				BEGIN
					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,0,0 ,Isnull((@Amount -@DepreciationAmount),0),
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
						
					SET @JournalBatchDetailId=SCOPE_IDENTITY()
				END

				INSERT INTO [dbo].[CommonBatchDetails]
                    (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                VALUES
                    (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
					CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN Isnull(@Amount,0) ELSE 0 END,
					CASE WHEN @CrDrType = 1 THEN 0 ELSE Isnull(@Amount,0) END,
					@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

				INSERT INTO [StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
					@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

				------Asset Account -----------

				------Loss/(Gain) on Disposal of Assets -----------
				SET @Amount =  Isnull((@ARCaseAmount+@DepreciationAmount),0)-(ISNULL(@AssetTotalPrice,0)-ISNULL(@PercentageAmount,0));

				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName
				FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('LOSSGAINONDISPOSALOFASSETS') 
				AND DistributionMasterId=@DistributionMasterId  AND MasterCompanyId = @MasterCompanyId
				
				IF(isnull(@Amount,0) >= 0)
				BEGIN

					IF(@JournalBatchDetailId = 0)
					BEGIN
						INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
						VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
						SET @JournalBatchDetailId=SCOPE_IDENTITY()
					END

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						0,0,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				END
				ELSE
				BEGIN
					IF(@JournalBatchDetailId = 0)
					BEGIN
						INSERT INTO [dbo].[BatchDetails]
							(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
							[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
							[ManagementStructureId],[ModuleName],
							LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
                        VALUES
							(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
							@JournalTypeId ,@JournalTypename ,1,@Amount ,0,
							@ManagementStructureId ,@ModuleName,
							@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)
						
						SET @JournalBatchDetailId=SCOPE_IDENTITY()
					END

					INSERT INTO [dbo].[CommonBatchDetails]
						(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES
						(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
						1,ABS(@Amount),0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
				END

				SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

				INSERT INTO [StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
					@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

				------Loss/(Gain) on Disposal of Assets -----------

				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			    Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId

				EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @AssetInventoryId

			END
			
			IF(UPPER(@DistributionCode) = UPPER('AssetInventory') AND UPPER(@StockType) = 'AssetWriteDown')
			BEGIN
				print 'AssetWriteDown'
				SELECT @ReferenceId=AssetInventoryId,@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
				,@SiteId=[SiteId],@Site=[SiteName],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[BinName],@ShelfId=[ShelfId],@Shelf=[ShelfName]
				,@AssetInventoryName=InventoryNumber
				FROM AssetInventory WHERE AssetInventoryId=@AssetInventoryId;

				SELECT @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId FROM PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
				SELECT @VendorName =VendorName FROM Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
						
				SET @UnitPrice = @Amount;
				SET @Amount = (@AssetTotalPrice);

				SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId FROM AssetInventory WHERE AssetInventoryId=@AssetInventoryId;
	            SELECT @MPNName = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId 
	            SELECT @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels FROM AssetManagementStructureDetails  WHERE ReferenceID=@AssetInventoryId AND ModuleID=@AssetMSModuleID
				Set @ReferencePartId=@partId	

				SELECT @PieceItemmasterId=MasterPartId FROM AssetInventory  WHERE AssetInventoryId=@AssetInventoryId
		        SELECT @PiecePN = partnumber FROM ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 

				SET @currentNo = @currentNo+1
				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))

				------Asset Account -----------
				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId 
				FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE UPPER(DistributionSetupCode) =UPPER('ASSETACCOUNT') 
				AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

				SELECT @GlAccountNumber=AccountCode,@GlAccountName=AccountName,@GlAccountId=@AcquiredGLAccountId 
				FROM GLAccount WHERE GLAccountId=@AcquiredGLAccountId

				IF(@JournalBatchDetailId = 0)
				BEGIN
					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)


					SET @JournalBatchDetailId=SCOPE_IDENTITY()
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
					
					SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

					INSERT INTO [StocklineBatchDetails]
						(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
						[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
					VALUES
						(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
						@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

				END
				------Asset Account -----------

				------Loss/(Gain) on Disposal of Assets -----------
				SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,
				@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName
				FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE  UPPER(DistributionSetupCode) =UPPER('LOSSGAINONDISPOSALOFASSETS') AND
				DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

				IF(@JournalBatchDetailId = 0)
				BEGIN
					INSERT INTO [dbo].[BatchDetails]
						(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,
						[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],
						[ManagementStructureId],[ModuleName],
						LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted], [AccountingPeriodId], [AccountingPeriod])
					VALUES
						(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),
						@JournalTypeId ,@JournalTypename ,1,@Amount ,0,
						@ManagementStructureId ,@ModuleName,
						@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@AccountingPeriodId,@AccountingPeriod)

					SET @JournalBatchDetailId=SCOPE_IDENTITY()
				END

				INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
					1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

				SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

				-----  Accounting MS Entry  -----

				EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

				SET @Desc = 'Inventory Num -' + @AssetInventoryName + '  PN-' + @MPNName + '  SL-' + @StocklineNumber

				INSERT INTO [StocklineBatchDetails]
					(JournalBatchDetailId,JournalBatchHeaderId,VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
					[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],[StockType],[CommonJournalBatchDetailId])
				VALUES
					(@JournalBatchDetailId,@JournalBatchHeaderId,@VendorId,@VendorName,@ItemMasterId,@partId,@MPNName,@ReferenceId,@AssetInventoryName,@ReferenceId,@AssetInventoryName,@AssetInventoryId,
					@StocklineNumber,'',@Desc,@SiteId,@Site,@WarehouseId,@Warehouse,@LocationId,@Location,@BinId,@Bin,@ShelfId,@Shelf,@StocktypeAsset,@CommonJournalBatchDetailId)

				------Loss/(Gain) on Disposal of Assets -----------

				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			    UPDATE BatchDetails SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchDetailId=@JournalBatchDetailId
				
				EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @AssetInventoryId

			END

			SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
			SET @TotalBalance =@TotalDebit-@TotalCredit
				         
			Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
			UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
		END

		SET @BatchId = @JournalBatchHeaderId;

	END
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH      
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