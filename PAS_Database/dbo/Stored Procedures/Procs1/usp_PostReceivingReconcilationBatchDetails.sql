/*************************************************************             
 ** File:   [usp_PostReceivingReconcilationBatchDetails]             
 ** Author:   
 ** Description: This stored procedure is used to Posting Reconsilation to Batch
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    30/05/2023   Satish Gohil        Modify (Gl Account Id Nullable Error fixed)
	2    05/06/2023   Satish Gohil        Modify (Add amount > 0 condition while insert record in commonbatchdetails table)
	3    14/08/2023	  Satish Gohil        Modify (Formatted and Change batch entry value)
	4    18/08/2023   Moin Bloch          Modify(Added Accounting MS Entry)
	5    08/09/2023   Moin Bloch          Modify(Added InvoicedQty Insted OF ReceivedQty)
	6    09/10/2023   Moin Bloch          Modify(COMMENTED UPDATE UNIT COST SECTION)
	7    09/10/2023   Moin Bloch          Modify(Added Freight Charges Tax Accounting Entry)
	8    19/10/2023   Moin Bloch          Modify(Misc Accounting Entry Changes)
	9    20/10/2023   Moin Bloch          Modify(Misc Accounting GL Account Number Changes)
	10	 23/10/2023	  Ayesha Sultana      Changes added - [ReferenceId] & @ReceivingReconciliationId 
	11	 06/11/2023	  Moin Bloch          Modify(Makes Freight and Tax Sepret SP)
	12   08/11/2023	  Moin Bloch          Modify(Added ReferenceId)
	13   17/11/2023	  Moin Bloch          Modify(Added Charges Accounting Entry)
	14   09/01/2024   Moin Bloch          Modify(Replace Invocedate instead of GETUTCDATE() in Invoice)
	15   02/20/2024	  HEMANT SALIYA		  Updated for Restrict Accounting Entry by Master Company
	16   03/09/2024   Moin Bloch          Modify(wrong account payble entry in ReconciliationRO)
	17   20/09/2024	  AMIT GHEDIYA		  Added for AutoPost Batch
	18	 09/10/2024	  Devendra Shekh	  Added new fields for [CommonBatchDetails]
	19	 04/11/2024   Devendra Shekh      Added ReferenceModule For [CommonBatchDetails]
	20	 18/12/2024   Devendra Shekh      Modify (Handling Qty/Unit Cost Adjustment Separately For Accounting Entry) And Changed QuantityAvailable to QuantityOnHand
	21	 30/12/2024   Devendra Shekh      Modify (Same JE for Post Batch, StockType wise)
	22	 08/01/2025   HEMANT SALIYA		  Updated for Reduce Vendor Proforma Amoinut
	23	 20/01/2025   RAJESH GAMI		  Commented the [UpdateStocklineBatchDetailsColumnsWithId] execution due to performance
	24	 20/01/2025   RAJESH GAMI		  UnCommented the [UpdateStocklineBatchDetailsColumnsWithId] SP
	25	 30/01/2025   HEMANT SALIYA		  Resolved Performa Accounting Entry in PO adn RO Partial Payment Handle
	26	 19/02/2026   HEMANT SALIYA		  Resolved RO Batch Post when Stl Qty is 0 and RO cost is 0
	27   03/09/2024   Moin Bloch          Batch: Duplicate JE Number generated for multiple entries on same day PN-15921
	28   03/09/2024   Moin Bloch          Batch: Duplicate JE Number generated for multiple entries on same day PN-15921
	29   12/06/2026   Priyansh Patel      UOM conversion issue for @InvoicedQty PN-16941

**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_PostReceivingReconcilationBatchDetails]
@tbl_PostRRBatchType PostRRBatchType READONLY,
@MasterCompanyId int
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	BEGIN TRY
		--BEGIN TRANSACTION
		BEGIN
			DECLARE @StocklineId bigint = 0;
			DECLARE @InvoicedQty  decimal(18, 6) = 0;
			DECLARE @InvoicedUnitCost decimal(18, 6) = 0;
			DECLARE @JournalTypeName varchar(256) = 0;
			DECLARE @CreatedBy varchar(256) = 0;
			DECLARE @Module varchar(256) = 0;
			DECLARE @JournalBatchHeaderId bigint = 0;
			DECLARE @StockType varchar(256)	 = 0;
			DECLARE @OLD_StockType varchar(256)	 = 0;
			DECLARE @IsStockTypeChange BIT= 0;
			DECLARE @Packagingid int = 0;
			DECLARE @EmployeeId BIGINT
			DECLARE @id bigint = 0;
			DECLARE @ReceivingReconciliationDetailId bigint = 0;

			DECLARE @currentNo AS BIGINT = 0;
			DECLARE @CodeTypeId AS BIGINT = 74;
			DECLARE @JournalTypeNumber varchar(100);
			DECLARE @JournalBatchDetailId BIGINT=0;
			DECLARE @UpdateBy varchar(100);
			DECLARE @JlBatchHeaderId bigint=0;
			DECLARE @TotalDebit decimal(18, 6) =0;
			DECLARE @TotalCredit decimal(18, 6) =0;
			DECLARE @TotalBalance decimal(18, 6) =0;
			DECLARE @INPUTMethod varchar(100);
			DECLARE @jlTypeId BIGINT;
			DECLARE @jlTypeName varchar(100);
			DECLARE @TotalAmt DECIMAL(18,6);
			DECLARE @batch VARCHAR(100)
			DECLARE @AccountingPeriod VARCHAR(100)
			DECLARE @AccountingPeriodId BIGINT=0
			DECLARE @CurrentManagementStructureId BIGINT=0		
			DECLARE @DistributionMasterId BIGINT;
			DECLARE @DistributionCode VARCHAR(200)
			DECLARE @StatusId INT
			DECLARE @StatusName VARCHAR(200)
			DECLARE @JournalTypeId INT
			DECLARE @JournalTypeCode VARCHAR(200) 
			DECLARE @Currentbatch varchar(100);  
			DECLARE @CurrentNumber int;
			DECLARE @CurrentPeriodId bigint=0;  
		    DECLARE @LineNumber int=1; 
			DECLARE @DisCode varchar(100);
			DECLARE @ReceivingReconciliationId BIGINT = 0
			DECLARE @updatedByName VARCHAR(100)
			DECLARE @AccountMSModuleId INT = 0;
			DECLARE @Freight INT = 1;
			DECLARE @Misc INT = 2;
			DECLARE @Tax INT = 3;
			DECLARE @TransactionDate DATETIME2(7)
			DECLARE @ReceivingReconciliationNumber VARCHAR(50)='';
			DECLARE @IsAutoPost INT = 0;
			DECLARE @IsBatchGenerated INT = 0;
			DECLARE @LocalCurrencyCode VARCHAR(20) = '';
			DECLARE @ForeignCurrencyCode VARCHAR(20) = '';
			DECLARE @JournalNumber VARCHAR(100) = '';
			DECLARE @FXRate DECIMAL(9,2) = 1;	--Default Value set to : 1
			DECLARE @ReferenceModule VARCHAR(100) = 'RECONCILIATION';
			DECLARE @RecordId BIGINT = 0;
			DECLARE @MinRecordId BIGINT;
			DECLARE @MaxRecordId BIGINT;
			DECLARE @count INT = 0;		
			DECLARE @TotalCounts INT = 0;
			DECLARE @VendorProformaStatusId INT = 0;

			SELECT @VendorProformaStatusId = VendorProformaInvoiceHeaderStatusId FROM dbo.VendorProformaInvoiceHeaderStatus WITH(NOLOCK) WHERE UPPER([Description]) = 'CLOSED'		

			IF OBJECT_ID(N'tempdb..#RRPostType') IS NOT NULL    
			BEGIN    
				DROP TABLE #RRPostType  
			END        
			CREATE TABLE #RRPostType  
			(    
				[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
				[StocklineId] [bigint] NOT NULL,
				[InvoicedQty] [decimal](18, 6) NULL,
				[InvoicedUnitCost] [decimal](18, 6) NULL,
				[JournalTypeName] [varchar](256) NULL,
				[CreatedBy] [varchar](256) NULL,
				[Module] [varchar](256) NULL,
				[JournalBatchHeaderId] [bigint] NULL,
				[StockType] [varchar](256) NULL,
				[Packagingid] [int] NULL,
				[EmployeeId] [bigint] NOT NULL,
				[id] [bigint] NOT NULL,
				[ReceivingReconciliationDetailId] [bigint] NOT NULL
			) 

			INSERT INTO #RRPostType ([StocklineId],[InvoicedQty],[InvoicedUnitCost],[JournalTypeName],[CreatedBy],[Module],[JournalBatchHeaderId],[StockType],
				[Packagingid],[EmployeeId],[id],[ReceivingReconciliationDetailId])    
			SELECT [StocklineId],[InvoicedQty],[InvoicedUnitCost],[JournalTypeName],[CreatedBy],[Module],[JournalBatchHeaderId],[StockType],
				[Packagingid],[EmployeeId],[id],[ReceivingReconciliationDetailId] FROM @tbl_PostRRBatchType ORDER BY [StockType] DESC

			IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
			BEGIN
			DROP TABLE #tmpCodePrefixes
			END

			IF OBJECT_ID(N'tempdb..#TMPCommonBatchDetail') IS NOT NULL
			BEGIN
			DROP TABLE #TMPCommonBatchDetail
			END

			CREATE TABLE #TMPCommonBatchDetail (
				[TMPBatchId] [bigint] IDENTITY(1,1) NOT NULL,
				[JournalBatchHeaderId] [bigint] NULL,
				[JournalBatchDetailId] [bigint] NULL,
				[LineNumber] [int] NULL,
				[GlAccountId] [bigint] NULL,
				[GlAccountNumber] [varchar](200) NULL,
				[GlAccountName] [varchar](200) NULL,
				[TransactionDate] [datetime] NULL,
				[EntryDate] [datetime] NULL,
				[JournalTypeId] [bigint] NULL,
				[JournalTypeName] [varchar](200) NULL,
				[IsDebit] [bit] NULL,
				[DebitAmount] [decimal](18, 6) NULL,
				[CreditAmount] [decimal](18, 6) NULL,
				[ManagementStructureId] [bigint] NULL,
				[ModuleName] [varchar](200) NULL,
				[MasterCompanyId] [int] NULL,
				[CreatedBy] [varchar](256) NULL,
				[UpdatedBy] [varchar](256) NULL,
				[CreatedDate] [datetime2](7) NULL,
				[UpdatedDate] [datetime2](7) NULL,
				[IsActive] [bit] NULL,
				[IsDeleted] [bit] NULL,
				[LastMSLevel] [varchar](200) NULL,
				[AllMSlevels] [varchar](max) NULL,
				[IsManualEntry] [bit] NULL,
				[DistributionSetupId] [int] NULL,
				[DistributionName] [varchar](200) NULL,
				[JournalTypeNumber] [varchar](50) NULL,
				[CurrentNumber] [bigint] NULL,
				[IsYearEnd] [bit] NULL,
				[IsVersionIncrease] [bit] NULL,
				[ReferenceId] [bigint] NULL,
				[LotId] [bigint] NULL,
				[LotNumber] [varchar](50) NULL,
				[IsUpdated] [bit] NULL,
				[ReferenceNumber] [varchar](150) NULL,
				[ReferenceName] [varchar](256) NULL,
				[LocalCurrency] [varchar](20) NULL,
				[FXRate] [decimal](18, 2) NULL,
				[ForeignCurrency] [varchar](20) NULL,
				[ReferenceModule] [varchar](100) NULL,

				[VendorId] [bigint] NULL,
				[VendorName] [varchar](100) NULL,
				[ItemMasterId] [bigint] NULL,
				[PartId] [bigint] NULL,
				[PartNumber] [nvarchar](100) NULL,
				[PoId] [bigint] NULL,
				[PONum] [varchar](50) NULL,
				[RoId] [bigint] NULL,
				[RONum] [varchar](50) NULL,
				[StocklineId] [bigint] NULL,
				[StocklineNumber] [varchar](50) NULL,
				[Consignment] [varchar](50) NULL,
				[Description] [varchar](max) NULL,
				[SiteId] [bigint] NULL,
				[Site] [varchar](100) NULL,
				[WarehouseId] [bigint] NULL,
				[Warehouse] [varchar](100) NULL,
				[LocationId] [bigint] NULL,
				[Location] [varchar](100) NULL,
				[BinId] [bigint] NULL,
				[Bin] [varchar](100) NULL,
				[ShelfId] [bigint] NULL,
				[Shelf] [varchar](100) NULL,
				[StockType] [varchar](50) NULL,
				[CommonJournalBatchDetailId] [bigint] NULL,
				[ReferenceTypeId] [int] NULL,
			)
					  
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
			FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
			BEGIN 
				SELECT 
					@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
						ELSE CAST(StartsFROM AS BIGINT) + 1 END 
				FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  
				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes 
				WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END

			SET @JlBatchHeaderId = (SELECT TOP 1 JournalBatchHeaderId FROM @tbl_PostRRBatchType)
		
			SELECT @TotalAmt = SUM(ISNULL(InvoicedQty,0)) * SUM(ISNULL(InvoicedUnitCost,0)) FROM #RRPostType

			SELECT TOP 1 @ReceivingReconciliationId = [id],@EmployeeId = EmployeeId FROM #RRPostType

			SELECT @CurrentManagementStructureId = ManagementStructureId, @UpdateBy = CONCAT(TRIM(FirstName),' ',TRIM(LastName)) FROM dbo.Employee 
			WITH(NOLOCK)  WHERE EmployeeId = @EmployeeId and MasterCompanyId=@MasterCompanyId

			SET @DisCode = (select top 1 CASE WHEN [Type] =1 THEN 'ReconciliationPO'			    
				WHEN [Type] = 2 THEN 'ReconciliationRO' ELSE '' END
			FROM DBO.ReceivingReconciliationDetails WITH(NOLOCK) WHERE ReceivingReconciliationId = @ReceivingReconciliationId) 

			SELECT @TransactionDate = [InvoiceDate],
			       @ReceivingReconciliationNumber = [ReceivingReconciliationNumber],
				   @LocalCurrencyCode = ISNULL(CU.Code,''),
				   @ForeignCurrencyCode = ISNULL(CU.Code,'')
			FROM [dbo].[ReceivingReconciliationHeader] RRH WITH(NOLOCK)
			LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.CurrencyId = RRH.CurrencyId
			WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;

			SELECT @DistributionMasterId =ID, @DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK)  
			WHERE UPPER(DistributionCode)= UPPER(@DisCode)

			SET @INPUTMethod = @DisCode
			
			SELECT @StatusId =Id,@StatusName=name FROM dbo.BatchStatus WITH(NOLOCK)  WHERE Name= 'Open'
			SELECT TOP 1 @JournalTypeId =JournalTypeId,@jlTypeId = JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK)  WHERE DistributionMasterId =@DistributionMasterId
			SELECT @JournalBatchHeaderId =JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId = @StatusId
			SELECT @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName,@jlTypeName = JournalTypeName FROM dbo.JournalType WITH(NOLOCK)  WHERE ID= @JournalTypeId
			SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

			DECLARE @IsRestrict BIT;
			DECLARE @IsAccountByPass BIT;
			EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;
			IF(ISNULL(@TotalAmt,0) > 0 AND ISNULL(@IsAccountByPass, 0) = 0 AND (@DisCode = 'ReconciliationPO' OR @DisCode = 'ReconciliationRO'))
			BEGIN
				PRINT '1.1' 
				PRINT GETUTCDATE();
				SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName FROM dbo.EntityStructureSetup est WITH(NOLOCK) 
				INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
				INNER JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
				WHERE est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(GETUTCDATE() as date)   >= CAST(FromDate as date) and  CAST(GETUTCDATE() as date) <= CAST(ToDate as date)

				IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and MasterCompanyId=@MasterCompanyId and CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE) and StatusId=@StatusId AND IsDeleted =0)
				BEGIN
					IF NOT EXISTS(SELECT JournalBatchHeaderId FROM dbo.BatchHeader WITH(NOLOCK))
					BEGIN
						SET @batch ='001'
						SET @Currentbatch='001'
					END
					ELSE
					BEGIN
						SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
								ELSE  1 END 
						FROM dbo.BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

						IF(CAST(@Currentbatch AS BIGINT) >99)
						BEGIN
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
							   		ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
						END
						ELSE IF(CAST(@Currentbatch AS BIGINT) >9)
						BEGIN

							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
							   		ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
						END
						ELSE
						BEGIN
							SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as VARCHAR(100))
							   		ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

						END
					END
					SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
					SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as VARCHAR(100)) as VARCHAR(100))

					INSERT INTO [dbo].[BatchHeader]
						([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
					VALUES
						(@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);
            				          
					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
					SELECT @JlBatchHeaderId = SCOPE_IDENTITY()
					UPDATE dbo.BatchHeader set CurrentNumber=@CurrentNumber  WHERE JournalBatchHeaderId= @JournalBatchHeaderId
				END
				ELSE
				BEGIN
					SELECT @JlBatchHeaderId=JournalBatchHeaderId,@JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM BatchHeader WITH(NOLOCK) 
					WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId AND CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)
					
					SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
						FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc
						
					IF(@CurrentPeriodId =0)
					BEGIN
						Update dbo.BatchHeader SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   WHERE JournalBatchHeaderId= @JournalBatchHeaderId
					END

					SET @IsBatchGenerated = 1;
				END

				UPDATE #RRPostType SET 
				[JournalTypeName] = @JournalTypename,
				[CreatedBy] = @UpdateBy,
				[Module] = CASE WHEN @DisCode = 'ReconciliationPO' THEN 'ReconciliationPO' ELSE 'ReconciliationRO' END,
				[JournalBatchHeaderId] = @JournalBatchHeaderId

					SELECT @TotalCounts = COUNT(RecordId) FROM #RRPostType;

					WHILE @count <= @TotalCounts
					BEGIN
						PRINT '1.3' 
						PRINT GETUTCDATE();
						SELECT @StocklineId = [StocklineId],
								@InvoicedQty  = [InvoicedQty], 
								@InvoicedUnitCost = [InvoicedUnitCost],
								@JournalTypeName = [JournalTypeName],
								@CreatedBy = [CreatedBy],
								@Module = [Module],
								@JournalBatchHeaderId = [JournalBatchHeaderId],
								@StockType = [StockType],
								@Packagingid = [Packagingid],
								@EmployeeId = [EmployeeId],
								@id = [id],
								@ReceivingReconciliationDetailId = [ReceivingReconciliationDetailId],
								@RecordId = [RecordId] 
						FROM #RRPostType WHERE RecordId = @count

						DECLARE @PieceItemmasterId bigint=0;
						DECLARE @PiecePNId bigint=0;
						DECLARE @PiecePN varchar(200);
						DECLARE @DistributionSetupId int=0;
						DECLARE @Distributionname varchar(200);
						DECLARE @GlAccountId int;
						DECLARE @GlAccountNumber varchar(200);
						DECLARE @GlAccountName varchar(200);
						DECLARE @WorkOrderNumber varchar(200);
						DECLARE @partId bigint=0;
						DECLARE @ItemMasterId bigint=NULL;
						DECLARE @ManagementStructureId bigint;
						DECLARE @LastMSLevel varchar(200);
						DECLARE @AllMSlevels varchar(max);
						DECLARE @PurchaseOrderId BIGINT=0;
						DECLARE @PurchaseOrderNumber varchar(50) ='';
						DECLARE @RepairOrderId BIGINT=0;
						DECLARE @RepairOrderNumber varchar(50) ='';
						DECLARE @StocklineNumber varchar(50) ='';
						DECLARE @SiteId BIGINT;
						DECLARE @Site varchar(100) ='';
						DECLARE @WarehouseId BIGINT;
						DECLARE @Warehouse varchar(100) ='';
						DECLARE @LocationId BIGINT;
						DECLARE @Location varchar(100) ='';
						DECLARE @BinId BIGINT;
						DECLARE @Bin varchar(100) ='';
						DECLARE @ShelfId BIGINT;
						DECLARE @Shelf varchar(100) ='';
						DECLARE @MPNName varchar(200);
						DECLARE @Desc varchar(100);
						DECLARE @VendorId bigint;
						DECLARE @VendorName varchar(50);
						DECLARE @STKMSModuleID bigint=2;
						DECLARE @EMPMSModuleID bigint=47;
						DECLARE @ReceivedQty DECIMAL(18, 6) =0;
						DECLARE @StocklineQtyOH DECIMAL(18, 6) =0;
						DECLARE @StocklineQtyAvail DECIMAL(18, 6) =0;
						DECLARE @StocklineQtyreserved DECIMAL(18, 6) =0;
						DECLARE @POStocklineUnitPrice DECIMAL(18, 6) =0;
						DECLARE @ROStocklineUnitPrice DECIMAL(18, 6) =0;
						DECLARE @StocklineUnitPrice DECIMAL(18, 6) =0;
						DECLARE @POROUnitPrice DECIMAL(18,6) =0;
						DECLARE @RRUnitPrice DECIMAL(18, 6) =0;
						DECLARE @APTotalPrice DECIMAL(18,6) =0;
						DECLARE @Amount DECIMAL(18,6) =0;
						DECLARE @Qty  DECIMAL(18,6) = 0;
						DECLARE @RRId BIGINT=0;
						DECLARE @CommonJournalBatchDetailId BIGINT=0;
						DECLARE @ModuleName VARCHAR(256);
						DECLARE @CrDrType BIGINT

						DECLARE @MiscGLId BIGINT
						DECLARE @MiscGlAccountNumber VARCHAR(200);
						DECLARE @MiscGlAccountName VARCHAR(200);

						DECLARE @FreightAdjustment DECIMAL(18,6) =0;
						DECLARE @TaxAdjustment DECIMAL(18,6) =0;
						DECLARE @FreightAdjustmentPerUnit DECIMAL(18,6) =0;
						DECLARE @TaxAdjustmentPerUnit DECIMAL(18,6) =0;

						DECLARE @QtyVariance DECIMAL(18,6) = 0;
						DECLARE @PriceVariance DECIMAL(18,6) = 0;

						SET @IsStockTypeChange = CASE WHEN @RecordId = 1 THEN 1 ELSE CASE WHEN @OLD_StockType != @StockType THEN 1 ELSE 0 END END;

						SET @OLD_StockType = @StockType;

						SELECT @POROUnitPrice = ISNULL([POUnitCost], 0), 
						       @ReceivedQty = ISNULL([InvoicedQty], 0), 
						       @RRUnitPrice = ISNULL([InvoicedUnitCost], 0),
						       @GlAccountId = [GlAccountId], 
							   @MiscGLId = [GlAccountId], 
							   @GlAccountNumber = [GlAccountNumber], 
							   @MiscGlAccountNumber = [GlAccountNumber], 
							   @GlAccountName = [GlAccountName],
							   @MiscGlAccountName = [GlAccountName],
							   @FreightAdjustment = [FreightAdjustment],	
							   @TaxAdjustment = [TaxAdjustment],
							   @FreightAdjustmentPerUnit = [FreightAdjustmentPerUnit],	
							   @TaxAdjustmentPerUnit = [TaxAdjustmentPerUnit],
							   @QtyVariance = ISNULL([QtyVariance], 0),
							   @PriceVariance = ISNULL([PriceVariance], 0)
						FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK)
					   WHERE [ReceivingReconciliationDetailId] = @ReceivingReconciliationDetailId;
					   				
						SET @Amount = @InvoicedUnitCost;
						SET @Qty = @InvoicedQty;
						SET @RRId = @id;
						SET @ModuleName = @Module;

						IF(ISNULL(@PackagingId,0) = 0)
						BEGIN
						IF(UPPER(@ModuleName) = UPPER('ReconciliationPO'))
						BEGIN
							SELECT TOP 1 @IsAutoPost = ISNULL(IsAutoPost,0)
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') 
									AND DistributionMasterId=@DistributionMasterId 
									AND MasterCompanyId = @MasterCompanyId;
							
							IF(ISNULL(@IsStockTypeChange, 0) = 1)
							BEGIN
								INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate],
									[EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
									[AccountingPeriodId],[AccountingPeriod])
								VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JlBatchHeaderId, 1, 0, NULL, NULL,@TransactionDate, GETUTCDATE(), @jlTypeId, @jlTypeName, 1, 0, 0, 0, @INPUTMethod,
									@JournalTypeId ,@JournalTypename, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
									@AccountingPeriodId,@AccountingPeriod)
								SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('ReconciliationPO');

							IF(UPPER(@StockType) = 'STOCK')
							BEGIN
								SELECT @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@PieceItemmasterId=ItemMasterId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
										@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse]
										,@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
										@VendorId=VendorId,@POStocklineUnitPrice=ISNULL(PurchaseOrderUnitCost,0),@ROStocklineUnitPrice=ISNULL(RepairOrderUnitCost,0),
										@StocklineQtyAvail=ISNULL(QuantityOnHand,0)
								FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId;
												  
							END

							IF(UPPER(@StockType) = 'NONSTOCK')
							BEGIN
								SELECT @WorkOrderNumber=NonStockInventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
										@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=NonStockInventoryNumber,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],
										@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
										@VendorId=VendorId,@POStocklineUnitPrice=ISNULL(UnitCost,0),@ROStocklineUnitPrice=ISNULL(UnitCost,0),@StocklineQtyAvail=QuantityOnHand 
								FROM dbo.NonStockInventory WITH(NOLOCK) WHERE NonStockInventoryId=@StocklineId;
												  
								SELECT @PieceItemmasterId=MasterPartId FROM dbo.NonStockInventory WITH(NOLOCK)  WHERE NonStockInventoryId=@StocklineId

							END
							IF(UPPER(@StockType) = 'ASSET')
							BEGIN
									SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
									@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
									,@SiteId=[SiteId],@Site=SiteName,@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=BinName,@ShelfId=[ShelfId],@Shelf=ShelfName,
									@POStocklineUnitPrice=ISNULL(UnitCost,0),@ROStocklineUnitPrice=ISNULL(UnitCost,0),@StocklineQtyAvail=1 FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
												  
									SELECT @PurchaseOrderNumber=PurchaseOrderNumber,@VendorId=VendorId FROM dbo.PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
									SELECT @PieceItemmasterId=MasterPartId FROM dbo.AssetInventory WITH(NOLOCK)  WHERE AssetInventoryId=@StocklineId

							END

							SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId;
							SELECT @VendorName =VendorName FROM dbo.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
							SELECT @PurchaseOrderNumber=PurchaseOrderNumber FROM dbo.PurchaseOrder WITH(NOLOCK)  WHERE PurchaseOrderId= @PurchaseOrderId;
							SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
							
								-- Reconciliation PO
							SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;

							SET @Desc='Receiving PO-'+@PurchaseOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
							SET @Amount=(ISNULL(@StocklineQtyAvail, 0) * @Amount);

							PRINT '1.4' 
							PRINT GETUTCDATE();

							IF(ISNULL(@StocklineQtyAvail, 0) = ISNULL(@ReceivedQty, 0) AND @POROUnitPrice=ISNULL(@RRUnitPrice, 0))
							BEGIN 							
									------- Goods Received Not Invoiced (GRNI)-------
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
												 @GlAccountId=GlAccountId,
									             @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') 
									AND DistributionMasterId=@DistributionMasterId 
									AND MasterCompanyId = @MasterCompanyId
									IF(ISNULL(@Amount,0) > 0)
									BEGIN

										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)

										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Goods Received Not Invoiced (GRNI)-------

									------- Accounts Payable --------

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber,
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId
									
									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename , 
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Accounts Payable --------

							END
							ELSE IF(ISNULL(@StocklineQtyAvail, 0) = ISNULL(@ReceivedQty, 0) AND @POROUnitPrice <> ISNULL(@RRUnitPrice, 0))
							BEGIN					
									------- Stock - Inventory -----
									SET @Amount = ISNULL(((@RRUnitPrice - @POROUnitPrice) * ISNULL(@StocklineQtyAvail, 0)), 0);
									SET @APTotalPrice = @APTotalPrice + @Amount

									-- RECPOSTKINV --

									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0) and ISNULL(@StocklineQtyAvail, 0)>0)
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@ROStocklineUnitPrice
										END

										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId,
													 @CrDrType= CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOSTKINV') 
										  AND DistributionMasterId=@DistributionMasterId 
										  AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,
										             @GlAccountNumber=GL.AccountCode,
													 @GlAccountName=GL.AccountName 
											   FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId 
										WHERE SL.StockLineId=@StocklineId
									END

									IF(UPPER(@StockType) = 'NONSTOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.NonStockInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE NonStockInventoryId=@StocklineId
										END

										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType= CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPONONSTKINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.NonStockInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.NonStockInventoryId=@StocklineId
									END

									IF(UPPER(@StockType) = 'ASSET')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, @DistributionName=Name, @JournalTypeId=JournalTypeId,@CrDrType= CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOASSETINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId;
										
										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;
									END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											       ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											        [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										    VALUES
											       (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											        CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											        CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											        CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											       ,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()
										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									IF(ISNULL(@Amount,0) < 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											       ([JournalBatchDetailId],[JournalTypeNumber],[CurrentNumber],[DistributionSetupId],[DistributionName],[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											        [IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										    VALUES
											       (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											        0,
											        0,
											        ABS(@Amount),
											        @ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Stock - Inventory -----

									PRINT '1.5' 
									PRINT GETUTCDATE();

									------- Goods Received Not Invoiced (GRNI)------
									SET @Amount=(@ReceivedQty * @POROUnitPrice);
									SET @APTotalPrice=@APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
												 @GlAccountId=GlAccountId,
									             @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') 
									  AND DistributionMasterId=@DistributionMasterId 
									  AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
										[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
										CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
										CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
										CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
										@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Goods Received Not Invoiced (GRNI)------

									------- Accounts Payable ------
									SET @Amount = @APTotalPrice;
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType= CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') 
									  AND DistributionMasterId=@DistributionMasterId 
									  AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Accounts Payable -------
							END
							ELSE IF(ISNULL(@StocklineQtyAvail, 0) <> ISNULL(@ReceivedQty, 0))
							BEGIN		
									PRINT '1.7' 
									PRINT GETUTCDATE();
									------- Stock - Inventory ---
									SET @Amount = (ISNULL(@RRUnitPrice, 0) - ISNULL(@POROUnitPrice, 0)) * ISNULL(@StocklineQtyAvail, 0);
									IF(@Amount = 0)
									BEGIN 
										SET @Amount = ((@RRUnitPrice - @POROUnitPrice) * ISNULL(@ReceivedQty, 0));
									END
									SET @APTotalPrice = ISNULL(@APTotalPrice, 0) + ISNULL(@Amount, 0)
									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0) AND ISNULL(@StocklineQtyAvail, 0) > 0)
										BEGIN
											SET @StocklineUnitPrice = ISNULL(@RRUnitPrice, 0) + ISNULL(@ROStocklineUnitPrice, 0)
										END

										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId, 
													 @GlAccountId=GlAccountId, 
													 @GlAccountNumber=GlAccountNumber, 
													 @GlAccountName=GlAccountName,
													 @CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOSTKINV') 
										  AND DistributionMasterId=@DistributionMasterId 
										  AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,
										             @GlAccountNumber=GL.AccountCode,
													 @GlAccountName=GL.AccountName 
											   FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId 
										WHERE SL.StockLineId=@StocklineId

									END
									IF(UPPER(@StockType) = 'NONSTOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.NonStockInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE NonStockInventoryId=@StocklineId
										END
										
										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId,
													 @CrDrType=CRDRType
										        FROM dbo.DistributionSetup WITH(NOLOCK)
										       WHERE UPPER(DistributionSetupCode)=UPPER('RECPONONSTKINV') 
											   AND DistributionMasterId=@DistributionMasterId 
											   AND MasterCompanyId = @MasterCompanyId;

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,
										             @GlAccountNumber=GL.AccountCode,
													 @GlAccountName=GL.AccountName 
												FROM DBO.NonStockInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId 
										WHERE SL.NonStockInventoryId=@StocklineId
									END
									IF(UPPER(@StockType) = 'ASSET')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId,
													 @CrDrType = CRDRType
										        FROM dbo.DistributionSetup WITH(NOLOCK)
										        WHERE UPPER(DistributionSetupCode)=UPPER('RECPOASSETINV') 
												AND DistributionMasterId=@DistributionMasterId 
												AND MasterCompanyId = @MasterCompanyId;
										
										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,
										             @GlAccountNumber=GL.AccountCode,
													 @GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;
									END

									PRINT '1.8' 
									PRINT GETUTCDATE();

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									IF(ISNULL(@Amount,0) < 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											0,
											0,
											ABS(@Amount),
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									PRINT '1.9' 
									PRINT GETUTCDATE();
									------- Stock - Inventory -------
									------- VAR - Cost/Qty - COGS ------
																		
									SET @Amount= ISNULL(((@ReceivedQty - ISNULL(@StocklineQtyAvail, 0)) * (@RRUnitPrice - @POROUnitPrice)), 0);
									--SET @APTotalPrice = (@APTotalPrice + @Amount);
																								
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
												 @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOVARCOGS') 
									  AND DistributionMasterId=@DistributionMasterId 
									  AND MasterCompanyId = @MasterCompanyId;									

									IF(ABS(@QtyVariance) > 0)
									BEGIN
										SET @APTotalPrice = (@APTotalPrice + (@QtyVariance));
											
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @QtyVariance > 0 THEN 1 ELSE 0 END,
											CASE WHEN @QtyVariance > 0 THEN ABS(@QtyVariance) ELSE 0 END,
											CASE WHEN @QtyVariance > 0 THEN 0 ELSE ABS(@QtyVariance) END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									IF(ABS(@PriceVariance) > 0)
									BEGIN	
										SET @APTotalPrice = (@APTotalPrice + (@PriceVariance));

										SELECT TOP 1 @DistributionSetupId=ID, 
									            @DistributionName=Name, 
												@JournalTypeId=JournalTypeId, 
												@GlAccountId=GlAccountId, 
												@GlAccountNumber=GlAccountNumber, 
												@GlAccountName=GlAccountName
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECPOVARCOGSUNITCOST') 
											AND DistributionMasterId=@DistributionMasterId 
											AND MasterCompanyId = @MasterCompanyId;
											
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @PriceVariance > 0 THEN 1 ELSE 0 END,
											CASE WHEN @PriceVariance > 0 THEN ABS(@PriceVariance) ELSE 0 END,
											CASE WHEN @PriceVariance > 0 THEN 0 ELSE ABS(@PriceVariance) END,
											--1,ABS(@PriceVariance),0,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									PRINT '1.10' 
									PRINT GETUTCDATE();

									------- VAR - Cost/Qty - COGS -------

									------- Goods Received Not Invoiced (GRNI)-------
									SET @Amount = (@ReceivedQty * @POROUnitPrice);
									SET @APTotalPrice = @APTotalPrice+@Amount

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId,
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOGRNI') 
									  AND DistributionMasterId=@DistributionMasterId 
									  AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Goods Received Not Invoiced (GRNI)-------
									------- Accounts Payable ------
									SET @Amount = @APTotalPrice;
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									FROM dbo.DistributionSetup WITH(NOLOCK)
									WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') 
									  AND DistributionMasterId=@DistributionMasterId 
									  AND MasterCompanyId = @MasterCompanyId;

									  PRINT '1.11' 
									  PRINT GETUTCDATE();

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									PRINT '1.12' 
									PRINT GETUTCDATE();
									------- Accounts Payable ------
								END
								PRINT '1.13' 
								PRINT GETUTCDATE();
							/***** Commented here due to performance issue, It's shifted to after the cursor ******/
							--EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId		
						END
						ELSE IF(UPPER(@ModuleName)=UPPER('ReconciliationRO'))
						BEGIN
							--SELECT 'ReconciliationRO'
							SELECT TOP 1 @IsAutoPost = ISNULL(IsAutoPost,0)
									        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
									        WHERE UPPER(DistributionSetupCode)=UPPER('RECROGRNI') 
											  AND DistributionMasterId=@DistributionMasterId 
											  AND MasterCompanyId = @MasterCompanyId;

							IF(ISNULL(@IsStockTypeChange, 0) = 1)
							BEGIN
								INSERT INTO [dbo].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate],
									[EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
									[AccountingPeriodId],[AccountingPeriod])
								VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JlBatchHeaderId, 1, 0, NULL, NULL, @TransactionDate, GETUTCDATE(), @jlTypeId, @jlTypeName, 1, 0, 0, 0, @INPUTMethod,
									@JournalTypeId, @JournalTypename, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
									@AccountingPeriodId,@AccountingPeriod)

								SET @JournalBatchDetailId=SCOPE_IDENTITY()
							END

							SELECT @DistributionMasterId =ID,@DistributionCode = DistributionCode from dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('ReconciliationRO');
							IF(UPPER(@StockType) = 'STOCK')
							BEGIN
								SELECT @WorkOrderNumber=StockLineNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
								@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=StocklineNumber
								,@SiteId=[SiteId],@Site=[Site],@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=[Bin],@ShelfId=[ShelfId],@Shelf=[Shelf],
								@VendorId=VendorId,@StocklineQtyAvail=ISNULL(QuantityOnHand,0),@POStocklineUnitPrice=ISNULL(PurchaseOrderUnitCost,0),@ROStocklineUnitPrice=ISNULL(RepairOrderUnitCost,0)  
								FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId;
															  
								SELECT @PieceItemmasterId=ItemMasterId FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId=@StocklineId
							END
							IF(UPPER(@StockType) = 'ASSET')
							BEGIN
								SELECT @WorkOrderNumber=InventoryNumber,@partId=PurchaseOrderPartRecordId,@ItemMasterId=MasterPartId,@ManagementStructureId=ManagementStructureId,@MasterCompanyId=MasterCompanyId,
								@PurchaseOrderId=PurchaseOrderId,@RepairOrderId=RepairOrderId,@StocklineNumber=InventoryNumber
								,@SiteId=[SiteId],@Site=SiteName,@WarehouseId=[WarehouseId],@Warehouse=[Warehouse],@LocationId=[LocationId],@Location=[Location],@BinId=[BinId],@Bin=BinName,@ShelfId=[ShelfId],@Shelf=ShelfName,
								@POStocklineUnitPrice=ISNULL(UnitCost,0),@ROStocklineUnitPrice=ISNULL(UnitCost,0),@StocklineQtyAvail=1 
								FROM AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId;
															  
								SELECT @RepairOrderNumber=RepairOrderNumber,@VendorId=VendorId FROM dbo.RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;
								SELECT @PieceItemmasterId=MasterPartId  FROM dbo.AssetInventory WITH(NOLOCK) WHERE AssetInventoryId=@StocklineId
							END

							SELECT @MPNName = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@ItemmasterId;
							SELECT @VendorName =VendorName FROM dbo.Vendor WITH(NOLOCK)  WHERE VendorId= @VendorId;
							SELECT @RepairOrderNumber=RepairOrderNumber FROM dbo.RepairOrder WITH(NOLOCK)  WHERE RepairOrderId= @RepairOrderId;

							SELECT @PieceItemmasterId=ItemMasterId FROM dbo.Stockline  WHERE StockLineId=@StocklineId
							SELECT @PiecePN = partnumber FROM dbo.ItemMaster WITH(NOLOCK)  WHERE ItemMasterId=@PieceItemmasterId 
								
							SELECT @LastMSLevel=LastMSLevel, @AllMSlevels=AllMSlevels FROM dbo.StocklineManagementStructureDetails WITH(NOLOCK) WHERE ReferenceID=@StockLineId AND ModuleID=@STKMSModuleID;

							SET @Desc='Receiving RO-'+@RepairOrderNumber+'  PN-'+@MPNName+'  SL-'+@StocklineNumber
							SET @Amount=(ISNULL(@StocklineQtyAvail, 0)* @Amount);
									
							IF(ISNULL(@StocklineQtyAvail, 0) = ISNULL(@ReceivedQty, 0) AND @POROUnitPrice = ISNULL(@RRUnitPrice, 0))
							BEGIN
									------- Goods Received Not Invoiced (GRNI)------
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
												 @GlAccountId=GlAccountId, 
									             @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
									        WHERE UPPER(DistributionSetupCode)=UPPER('RECROGRNI') 
											  AND DistributionMasterId=@DistributionMasterId 
											  AND MasterCompanyId = @MasterCompanyId;

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Goods Received Not Invoiced (GRNI)------

									------- Accounts Payable -------
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId,
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType=CRDRType
									        FROM dbo.DistributionSetup WITH(NOLOCK)
									       WHERE UPPER(DistributionSetupCode)=UPPER('RECROACCPAYABLE') 
										     AND DistributionMasterId=@DistributionMasterId 
											 AND MasterCompanyId = @MasterCompanyId
									
									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
															 
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----
										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Accounts Payable -------

							END
							ELSE IF(ISNULL(@StocklineQtyAvail, 0) = ISNULL(@ReceivedQty, 0) AND @POROUnitPrice <> ISNULL(@RRUnitPrice, 0))
							BEGIN
									------- Stock - Inventory ---
									SET @Amount = ISNULL(((@RRUnitPrice - @POROUnitPrice) * ISNULL(@StocklineQtyAvail, 0)), 0);
									SET @APTotalPrice = @APTotalPrice + @Amount

									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0) and ISNULL(@StocklineQtyAvail, 0) >0)
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@POStocklineUnitPrice
										END
										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId,
													 @CrDrType=CRDRType
										        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
										        WHERE UPPER(DistributionSetupCode) = UPPER('RECROSTKINV') 
												AND DistributionMasterId=@DistributionMasterId 
												AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.GLAccountId,
										            @GlAccountNumber=GL.AccountCode,
													@GlAccountName=GL.AccountName 
											   FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId 
										WHERE SL.StockLineId=@StocklineId
									END
									IF(UPPER(@StockType) = 'ASSET')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE dbo.AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId,
													 @CrDrType=CRDRType
										        FROM dbo.DistributionSetup WITH(NOLOCK)
										       WHERE UPPER(DistributionSetupCode)=UPPER('RECROASSETINV') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;
									END

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									IF(ISNULL(@Amount,0) < 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											 0,
											 0,
											 ABS(@Amount),
											 @ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId = SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									------- Goods Received Not Invoiced (GRNI)-------
									SET @Amount= ISNULL((@ReceivedQty * @POROUnitPrice), 0);
									SET @APTotalPrice = @APTotalPrice + @Amount

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber,
												 @GlAccountName=GlAccountName,
												 @CrDrType=CRDRType
									        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
									        WHERE UPPER(DistributionSetupCode) = UPPER('RECROGRNI') 
											  AND DistributionMasterId = @DistributionMasterId 
											  AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Goods Received Not Invoiced (GRNI)-------

									------- Accounts Payable ------
									
									SET @Amount = @APTotalPrice

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType=CRDRType
									        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
									        WHERE UPPER(DistributionSetupCode)=UPPER('RECROACCPAYABLE') 
											AND DistributionMasterId=@DistributionMasterId 
											AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN 
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END
									------- Accounts Payable ------
							END
							ELSE IF(ISNULL(@StocklineQtyAvail, 0) <> ISNULL(@ReceivedQty, 0))
							BEGIN
									------- Stock - Inventory -----
									SET @Amount = ((@RRUnitPrice - @POROUnitPrice)* ISNULL(@StocklineQtyAvail, 0));
									IF(@Amount = 0)
									BEGIN 
										SET @Amount = ((@RRUnitPrice - @POROUnitPrice) * ISNULL(@ReceivedQty, 0));
									END
									SET @APTotalPrice = @APTotalPrice + @Amount

									IF(UPPER(@StockType) = 'STOCK')
									BEGIN
										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice+@POStocklineUnitPrice
										END

										SELECT TOP 1 @DistributionSetupId = ID, 
										             @DistributionName = [Name], 
													 @JournalTypeId = JournalTypeId,
													 @CrDrType = CRDRType
										        FROM dbo.DistributionSetup WITH(NOLOCK)
										        WHERE UPPER(DistributionSetupCode)=UPPER('RECROSTKINV') 
												AND DistributionMasterId=@DistributionMasterId 
												AND MasterCompanyId = @MasterCompanyId
										SELECT TOP 1 @GlAccountId=SL.GLAccountId,@GlAccountNumber=GL.AccountCode,@GlAccountName=GL.AccountName FROM DBO.Stockline SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId=GL.GLAccountId WHERE SL.StockLineId=@StocklineId

									END			     
									IF(UPPER(@StockType) = 'ASSET')
									BEGIN

										IF(@POROUnitPrice !=ISNULL(@RRUnitPrice, 0))
										BEGIN
											SET @StocklineUnitPrice=@RRUnitPrice
											UPDATE AssetInventory
											SET  UnitCost=@StocklineUnitPrice
											WHERE AssetInventoryId=@StocklineId
										END
														     
										SELECT TOP 1 @DistributionSetupId=ID, 
										             @DistributionName=Name, 
													 @JournalTypeId=JournalTypeId,
													 @CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECROASSETINV') 
										AND DistributionMasterId=@DistributionMasterId 
										AND MasterCompanyId = @MasterCompanyId

										SELECT TOP 1 @GlAccountId=SL.AcquiredGLAccountId,
										             @GlAccountNumber=GL.AccountCode
													 ,@GlAccountName=GL.AccountName 
										FROM DBO.AssetInventory SL WITH(NOLOCK)
										INNER JOIN DBO.GLAccount GL WITH(NOLOCK) ON SL.AcquiredGLAccountId=GL.GLAccountId 
										WHERE AssetInventoryId=@StocklineId;

									END
									IF(ISNULL(@Amount,0) > 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									IF(ISNULL(@Amount,0) < 0)
									BEGIN
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											 0,
											 0,
											 ABS(@Amount),
											 @ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									------- Stock - Inventory -----

									------- VAR - Cost/Qty - COGS ------
									SET @Amount=((@RRUnitPrice - @POROUnitPrice) * (@ReceivedQty - ISNULL(@StocklineQtyAvail, 0)));									
									
									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType=CRDRType
									        FROM dbo.DistributionSetup WITH(NOLOCK)
									       WHERE UPPER(DistributionSetupCode)=UPPER('RECROVARCOGS') 
										   AND DistributionMasterId=@DistributionMasterId 
										   AND MasterCompanyId = @MasterCompanyId								

									IF(ABS(@QtyVariance) > 0)
									BEGIN
										SET @APTotalPrice = @APTotalPrice + (@QtyVariance);

										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @QtyVariance > 0 THEN 1 ELSE 0 END,
											CASE WHEN @QtyVariance > 0 THEN ABS(@QtyVariance) ELSE 0 END,
											CASE WHEN @QtyVariance > 0 THEN 0 ELSE ABS(@QtyVariance) END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

									END

									IF(ABS(@PriceVariance) > 0)
									BEGIN
										SET @APTotalPrice = @APTotalPrice + (@PriceVariance);

										SELECT TOP 1 @DistributionSetupId=ID, 
									            @DistributionName=Name, 
												@JournalTypeId=JournalTypeId, 
												@GlAccountId=GlAccountId, 
												@GlAccountNumber=GlAccountNumber, 
												@GlAccountName=GlAccountName,
												@CrDrType=CRDRType
										FROM dbo.DistributionSetup WITH(NOLOCK)
										WHERE UPPER(DistributionSetupCode)=UPPER('RECROVARCOGSUNITCOST') 
											AND DistributionMasterId=@DistributionMasterId 
											AND MasterCompanyId = @MasterCompanyId;

										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @PriceVariance > 0 THEN 1 ELSE 0 END,
											CASE WHEN @PriceVariance > 0 THEN ABS(@PriceVariance) ELSE 0 END,
											CASE WHEN @PriceVariance > 0 THEN 0 ELSE ABS(@PriceVariance) END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----
										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

										--INSERT INTO dbo.[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber,
										--	Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
										--VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber,
										--	'', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber)
									END
									
									------- VAR - Cost/Qty - COGS ------

									 ------- Goods Received Not Invoiced (GRNI)------
									SET @Amount = ISNULL((@ReceivedQty * @POROUnitPrice), 0);

									SET @APTotalPrice = @APTotalPrice + @Amount

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId,
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType = CRDRType
									        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
									        WHERE UPPER(DistributionSetupCode) = UPPER('RECROGRNI') 
											AND DistributionMasterId=@DistributionMasterId 
											AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN 
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END
											,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										--EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

										--INSERT INTO [StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
										--VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber)
									END
									
									------- Goods Received Not Invoiced (GRNI)-----
									
									------- Accounts Payable ------
									
									SET @Amount = @APTotalPrice

									SELECT TOP 1 @DistributionSetupId=ID, 
									             @DistributionName=Name, 
												 @JournalTypeId=JournalTypeId, 
									             @GlAccountId=GlAccountId, 
												 @GlAccountNumber=GlAccountNumber, 
												 @GlAccountName=GlAccountName,
												 @CrDrType=CRDRType
									        FROM [dbo].[DistributionSetup] WITH(NOLOCK)
									        WHERE UPPER(DistributionSetupCode)=UPPER('RECROACCPAYABLE') 
											AND DistributionMasterId=@DistributionMasterId 
											AND MasterCompanyId = @MasterCompanyId

									IF(ISNULL(@Amount,0) > 0)
									BEGIN 
										INSERT INTO #TMPCommonBatchDetail
											(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
											[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
										VALUES
											(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,ISNULL(@GlAccountId,0) ,@GlAccountNumber ,@GlAccountName,@TransactionDate,GETUTCDATE(),@JournalTypeId ,@JournalTypename ,
											CASE WHEN @CrDrType = 1 THEN 1 ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN @Amount ELSE 0 END,
											CASE WHEN @CrDrType = 1 THEN 0 ELSE @Amount END,
											@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@ReceivingReconciliationId,@ReceivingReconciliationNumber,@VendorName,@LocalCurrencyCode,@FXRate,@ForeignCurrencyCode,@ReferenceModule)
																  
										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

										-----  Accounting MS Entry  -----

										--EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
										UPDATE #TMPCommonBatchDetail
										SET 
											VendorId = @VendorId,
											VendorName = @VendorName,
											ItemMasterId = @ItemMasterId,
											PartId = @PartId,
											PartNumber = @MPNName,
											PoId = @PurchaseOrderId,
											PONum = @PurchaseOrderNumber,
											RoId = @RepairOrderId,
											RONum = @RepairOrderNumber,
											StocklineId = @StocklineId,
											StocklineNumber = @StocklineNumber,
											Consignment = '',
											[Description] = @Desc,
											[SiteId] = @SiteId,
											[Site] = @Site,
											[WarehouseId] = @WarehouseId,
											[Warehouse] = @Warehouse,
											[LocationId] = @LocationId,
											[Location] = @Location,
											[BinId] = @BinId,
											[Bin] = @Bin,
											[ShelfId] = @ShelfId,
											[Shelf] = @Shelf,
											[StockType] = @StockType,
											[CommonJournalBatchDetailId] = @CommonJournalBatchDetailId,
											[ReferenceId] = @ReceivingReconciliationId,
											[ReferenceTypeId] = 1
										WHERE TMPBatchId = @CommonJournalBatchDetailId;

										--INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
										--VALUES(@JournalBatchDetailId, @JournalBatchHeaderId, @VendorId, @VendorName, @ItemMasterId, @partId, @MPNName, @PurchaseOrderId, @PurchaseOrderNumber, @RepairOrderId, @RepairOrderNumber, @StocklineId, @StocklineNumber, '', @Desc, @SiteId, @Site, @WarehouseId, @Warehouse, @LocationId, @Location, @BinId, @Bin, @ShelfId, @Shelf, @StockType,@CommonJournalBatchDetailId,@ReceivingReconciliationId,1,@ReceivingReconciliationNumber)
									END
									------- Accounts Payable ------
								END
															
							--EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId							
						END

						PRINT '1.14' 
						PRINT GETUTCDATE();
																	   						 
						IF(ISNULL(@RecordId, 0) = 1) -- AND @RecordId != 1)
						BEGIN
							UPDATE [dbo].[CodePrefixes] 
							   SET [CurrentNummber] = @currentNo
							 WHERE [CodeTypeId] = @CodeTypeId 
							   AND [MasterCompanyId] = @MasterCompanyId    
						
							--SET @currentNo = @currentNo + 1

							--SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes
							--WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
						END
						PRINT '1.15' 
						PRINT GETUTCDATE();
						END
						PRINT '1.16' 
						PRINT GETUTCDATE();

						SET @count = @count + 1;

						PRINT 'END Main Loop' 
						PRINT GETUTCDATE();
					END

				--		FETCH NEXT FROM @PostRRBatchCursor INTO @StocklineId,@InvoicedQty,@InvoicedUnitCost,@JournalTypeName,@CreatedBy,@Module,@JournalBatchHeaderId,@StockType,@Packagingid,@EmployeeId,@id,@ReceivingReconciliationDetailId,@RecordId;
				--		PRINT '1.17' 
				--	END
				--CLOSE @PostRRBatchCursor
				--DEALLOCATE @PostRRBatchCursor

				--SELECT '#TMPCommonBatchDetail'
				--SELECT * FROM #TMPCommonBatchDetail

				PRINT 'Start Next Item' 
				PRINT GETUTCDATE();

				IF OBJECT_ID(N'tempdb..#TMPVendorProformaInv') IS NOT NULL
				BEGIN
				DROP TABLE #TMPVendorProformaInv
				END

				IF OBJECT_ID(N'tempdb..#TMPBatchFinalResult') IS NOT NULL
				BEGIN
				DROP TABLE #TMPBatchFinalResult
				END

				CREATE TABLE #TMPBatchFinalResult (
					[BatchId] [bigint] IDENTITY(1,1) NOT NULL,
					[JournalBatchHeaderId] [bigint] NULL,
					[JournalBatchDetailId] [bigint] NULL,
					[LineNumber] [int] NULL,
					[GlAccountId] [bigint] NULL,
					[GlAccountNumber] [varchar](200) NULL,
					[GlAccountName] [varchar](200) NULL,
					[TransactionDate] [datetime] NULL,
					[EntryDate] [datetime] NULL,
					[JournalTypeId] [bigint] NULL,
					[JournalTypeName] [varchar](200) NULL,
					[IsDebit] [bit] NULL,
					[DebitAmount] [decimal](18, 6) NULL,
					[CreditAmount] [decimal](18, 6) NULL,
					[ManagementStructureId] [bigint] NULL,
					[ModuleName] [varchar](200) NULL,
					[MasterCompanyId] [int] NULL,
					[CreatedBy] [varchar](256) NULL,
					[UpdatedBy] [varchar](256) NULL,
					[CreatedDate] [datetime2](7) NULL,
					[UpdatedDate] [datetime2](7) NULL,
					[IsActive] [bit] NULL,
					[IsDeleted] [bit] NULL,
					[LastMSLevel] [varchar](200) NULL,
					[AllMSlevels] [varchar](max) NULL,
					[IsManualEntry] [bit] NULL,
					[DistributionSetupId] [int] NULL,
					[DistributionName] [varchar](200) NULL,
					[JournalTypeNumber] [varchar](50) NULL,
					[CurrentNumber] [bigint] NULL,
					[IsYearEnd] [bit] NULL,
					[IsVersionIncrease] [bit] NULL,
					[ReferenceId] [bigint] NULL,
					[LotId] [bigint] NULL,
					[LotNumber] [varchar](50) NULL,
					[IsUpdated] [bit] NULL,
					[ReferenceNumber] [varchar](150) NULL,
					[ReferenceName] [varchar](256) NULL,
					[LocalCurrency] [varchar](20) NULL,
					[FXRate] [decimal](18, 2) NULL,
					[ForeignCurrency] [varchar](20) NULL,
					[ReferenceModule] [varchar](100) NULL,
					[TMPBatchId] [bigint] NULL,
					[PoId] [bigint] NULL,
					[RoId] [bigint] NULL,
					[StockType] [varchar](150) NULL,
				)

				CREATE TABLE #TMPVendorProformaInv (
					[RecordId] [bigint] IDENTITY(1,1) NOT NULL,
					[VendorProformaInvoiceId] [bigint] NULL,
					[ReferenceId] [bigint] NULL,
					[ProformaAmount] [decimal](18, 6) NULL,
					[StockType] [varchar](150) NULL,
					[Type] [int] NULL,
				)

				DECLARE @TMPCommonBatchId BIGINT = 0, @TotalBatchRecords BIGINT = 0, @CurrentRecordId BIGINT = 0;

				INSERT INTO #TMPVendorProformaInv (VendorProformaInvoiceId, ProformaAmount, ReferenceId, StockType, [Type])
				SELECT DISTINCT VPH.VendorProformaInvoiceId, RCD.VendorProformaAmount, PO.PurchaseOrderId, RCD.StockType, 1 
				FROM [DBO].[ReceivingReconciliationDetails] RCD WITH(NOLOCK)
				JOIN #RRPostType RRCT ON RRCT.ReceivingReconciliationDetailId = RCD.ReceivingReconciliationDetailId 
				LEFT JOIN PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = RCD.PurchaseOrderId AND [Type] = 1 AND PO.MasterCompanyId = @MasterCompanyId
				LEFT JOIN VendorProformaInvoiceHeader VPH WITH(NOLOCK) ON VPH.ReferenceId = PO.PurchaseOrderId AND ISNULL(VPH.IsPurchaseOrder, 0) = 1 AND VPH.MasterCompanyId = PO.MasterCompanyId
				WHERE PO.MasterCompanyId = @MasterCompanyId

				PRINT '1.18' 
				PRINT GETUTCDATE();

				INSERT INTO #TMPVendorProformaInv (VendorProformaInvoiceId, ProformaAmount, ReferenceId, StockType, [Type])
				SELECT DISTINCT VPH.VendorProformaInvoiceId, RCD.VendorProformaAmount, RO.RepairOrderId, RCD.StockType, 2 FROM [DBO].[ReceivingReconciliationDetails] RCD WITH(NOLOCK)
				JOIN #RRPostType RRCT ON RRCT.ReceivingReconciliationDetailId = RCD.ReceivingReconciliationDetailId 
				LEFT JOIN RepairOrder RO WITH(NOLOCK) ON RO.RepairOrderId = RCD.PurchaseOrderId AND [Type] = 2 AND RO.MasterCompanyId = @MasterCompanyId
				LEFT JOIN VendorProformaInvoiceHeader VPH WITH(NOLOCK) ON VPH.ReferenceId = RO.RepairOrderId AND ISNULL(VPH.IsPurchaseOrder, 0) = 0 AND VPH.MasterCompanyId = RO.MasterCompanyId
				WHERE RO.MasterCompanyId = @MasterCompanyId

				--Select * from #TMPVendorProformaInv

				IF((SELECT COUNT(1) FROM #TMPVendorProformaInv) > 0)
				BEGIN
					DECLARE @ProformaDistributionMasterId BIGINT;
					SELECT @ProformaDistributionMasterId =ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('VendorProformaInvoice') 

					SELECT TOP 1 @DistributionSetupId=ID, 
								 @DistributionName=Name, 
								 @JournalTypeId=JournalTypeId, 
								 @GlAccountId=GlAccountId, 
								 @GlAccountNumber=GlAccountNumber, 
								 @GlAccountName=GlAccountName,
								 @CrDrType=CRDRType
					  FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					  WHERE UPPER(DistributionSetupCode)=UPPER('VPI-DEPOSIT') 
						AND DistributionMasterId=@ProformaDistributionMasterId 
						AND MasterCompanyId = @MasterCompanyId

					INSERT INTO #TMPCommonBatchDetail
						([JournalBatchHeaderId],JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[GlAccountId],[GlAccountNumber],[GlAccountName] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[ReferenceId],[ReferenceNumber],[ReferenceName],
						[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule], LineNumber, TransactionDate, EntryDate, [CreatedBy],[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT TOP 1 MAX(TMPCB.[JournalBatchHeaderId]), MAX(TMPCB.[JournalBatchDetailId]), JournalTypeNumber, CurrentNumber, @DistributionSetupId, @DistributionName,   
								@GlAccountId, @GlAccountNumber, @GlAccountName, @JournalTypeId, [JournalTypeName], 
								0, 0, MAX(ISNULL(PO.[DepositAmount], 0)) [CreditAmount], VPIPD.[ManagementStructureId], [ModuleName], VPIPD.LastMSLevel, VPIPD.AllMSlevels, VPIPD.[MasterCompanyId], TMPCB.[ReferenceId], TMPCB.[ReferenceNumber], TMPCB.[ReferenceName], 
								[LocalCurrency],TMPCB.[FXRate],[ForeignCurrency],@ReferenceModule, LineNumber, MAX([TransactionDate]), MAX(TMPCB.[EntryDate]), TMPCB.[CreatedBy],TMPCB.[UpdatedBy], GETUTCDATE(),GETUTCDATE(),1,0
					FROM dbo.VendorProformaInvoicePartDetails VPIPD  WITH(NOLOCK)
						JOIN dbo.PurchaseOrder PO WITH(NOLOCK) ON PO.VendorProformaInvoiceId = VPIPD.VendorProformaInvoiceId
						JOIN #TMPVendorProformaInv TMPVP ON VPIPD.VendorProformaInvoiceId = TMPVP.VendorProformaInvoiceId 
						JOIN GLAccount GL WITH(NOLOCK) ON VPIPD.GlAccountId = GL.GLAccountId
						JOIN #TMPCommonBatchDetail TMPCB  ON TMPCB.PoId = TMPVP.ReferenceId AND [Type] = 1
					GROUP BY JournalTypeNumber, CurrentNumber, [JournalTypeName], VPIPD.[GlAccountId], GL.[AccountCode], GL.[AccountName], [JournalTypeName],VPIPD.[ManagementStructureId], 
							[ModuleName], VPIPD.LastMSLevel, VPIPD.AllMSlevels, VPIPD.[MasterCompanyId], TMPCB.[ReferenceId], TMPCB.[ReferenceNumber], TMPCB.[ReferenceName], [LocalCurrency],
							TMPCB.[FXRate],[ForeignCurrency], LineNumber, TMPCB.[CreatedBy],TMPCB.[UpdatedBy]

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY();
								
					--PRINT '@CommonJournalBatchDetailId : #TMPCommonBatchDetail 1.0'
					--PRINT @CommonJournalBatchDetailId

					UPDATE #TMPCommonBatchDetail
					SET 
						VendorId = GROUPtmp.VendorId,
						VendorName = GROUPtmp.VendorName,
						ItemMasterId = GROUPtmp.ItemMasterId,
						PartId = GROUPtmp.PartId,
						PartNumber = GROUPtmp.PartNumber,
						PoId = GROUPtmp.PoId,
						PONum = GROUPtmp.PONum,
						RoId = GROUPtmp.RoId,
						RONum = GROUPtmp.RONum,
						StocklineId = GROUPtmp.StocklineId,
						StocklineNumber = GROUPtmp.StocklineNumber,
						Consignment = '',
						[Description] = GROUPtmp.[Description],
						[SiteId] = GROUPtmp.SiteId,
						[Site] = GROUPtmp.Site,
						[WarehouseId] = GROUPtmp.WarehouseId,
						[Warehouse] = GROUPtmp.Warehouse,
						[LocationId] = GROUPtmp.LocationId,
						[Location] = GROUPtmp.Location,
						[BinId] = GROUPtmp.BinId,
						[Bin] = GROUPtmp.Bin,
						[ShelfId] = GROUPtmp.ShelfId,
						[Shelf] = GROUPtmp.Shelf,
						[StockType] = GROUPtmp.StockType,
						[CommonJournalBatchDetailId] = GROUPtmp.CommonJournalBatchDetailId,
						[ReferenceId] = @ReceivingReconciliationId,
						[ReferenceTypeId] = 1
					FROM ( SELECT TOP 1 VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
								[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],TMPCB.[StockType],[CommonJournalBatchDetailId],
								TMPCB.[ReferenceId],[ReferenceTypeId]
							FROM #TMPCommonBatchDetail TMPCB
							JOIN #TMPVendorProformaInv TMPVP ON TMPCB.PoId = TMPVP.ReferenceId AND [Type] = 1
						) GROUPtmp 
					WHERE TMPBatchId = @CommonJournalBatchDetailId;

					INSERT INTO #TMPCommonBatchDetail
						([JournalBatchHeaderId],JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[GlAccountId],[GlAccountNumber],[GlAccountName] ,[JournalTypeId],[JournalTypeName],
						[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[ReferenceId],[ReferenceNumber],[ReferenceName],
						[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule], LineNumber, TransactionDate, EntryDate, [CreatedBy],[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT TOP 1 MAX(TMPCB.[JournalBatchHeaderId]), MAX(TMPCB.[JournalBatchDetailId]), JournalTypeNumber, CurrentNumber, @DistributionSetupId, @DistributionName,   
								@GlAccountId, @GlAccountNumber, @GlAccountName, MAX([JournalTypeId]), [JournalTypeName], 
								0, 0, MAX(ISNULL(RO.[DepositAmount],0)) [CreditAmount], VPIPD.[ManagementStructureId], [ModuleName], VPIPD.LastMSLevel, VPIPD.AllMSlevels, VPIPD.[MasterCompanyId], TMPCB.[ReferenceId], TMPCB.[ReferenceNumber], TMPCB.[ReferenceName], 
								[LocalCurrency],TMPCB.[FXRate],[ForeignCurrency],@ReferenceModule, LineNumber, MAX([TransactionDate]), MAX(TMPCB.[EntryDate]), TMPCB.[CreatedBy],TMPCB.[UpdatedBy], GETUTCDATE(),GETUTCDATE(),1,0
					FROM dbo.VendorProformaInvoicePartDetails VPIPD  WITH(NOLOCK)
						JOIN dbo.RepairOrder RO WITH(NOLOCK) ON RO.VendorProformaInvoiceId = VPIPD.VendorProformaInvoiceId
						JOIN #TMPVendorProformaInv TMPVP ON VPIPD.VendorProformaInvoiceId = TMPVP.VendorProformaInvoiceId 
						JOIN GLAccount GL  WITH(NOLOCK) ON VPIPD.GlAccountId = GL.GLAccountId
						JOIN #TMPCommonBatchDetail TMPCB  ON TMPCB.RoId = TMPVP.ReferenceId AND [Type] = 2
					GROUP BY JournalTypeNumber, CurrentNumber, [JournalTypeName], VPIPD.[GlAccountId], GL.[AccountCode], GL.[AccountName], [JournalTypeName],VPIPD.[ManagementStructureId], 
							[ModuleName], VPIPD.LastMSLevel, VPIPD.AllMSlevels, VPIPD.[MasterCompanyId], TMPCB.[ReferenceId], TMPCB.[ReferenceNumber], TMPCB.[ReferenceName], [LocalCurrency],
							TMPCB.[FXRate],[ForeignCurrency], LineNumber, TMPCB.[CreatedBy],TMPCB.[UpdatedBy]
				
					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY();

					--PRINT '@CommonJournalBatchDetailId : #TMPCommonBatchDetail'
					--PRINT @CommonJournalBatchDetailId

					--SELECT '@CommonJournalBatchDetailId : #TMPCommonBatchDetail'
					--SELECT * FROM #TMPCommonBatchDetail

					UPDATE #TMPCommonBatchDetail
					SET 
						VendorId = GROUPtmp.VendorId,
						VendorName = GROUPtmp.VendorName,
						ItemMasterId = GROUPtmp.ItemMasterId,
						PartId = GROUPtmp.PartId,
						PartNumber = GROUPtmp.PartNumber,
						PoId = GROUPtmp.PoId,
						PONum = GROUPtmp.PONum,
						RoId = GROUPtmp.RoId,
						RONum = GROUPtmp.RONum,
						StocklineId = GROUPtmp.StocklineId,
						StocklineNumber = GROUPtmp.StocklineNumber,
						Consignment = '',
						[Description] = GROUPtmp.[Description],
						[SiteId] = GROUPtmp.SiteId,
						[Site] = GROUPtmp.Site,
						[WarehouseId] = GROUPtmp.WarehouseId,
						[Warehouse] = GROUPtmp.Warehouse,
						[LocationId] = GROUPtmp.LocationId,
						[Location] = GROUPtmp.Location,
						[BinId] = GROUPtmp.BinId,
						[Bin] = GROUPtmp.Bin,
						[ShelfId] = GROUPtmp.ShelfId,
						[Shelf] = GROUPtmp.Shelf,
						[StockType] = GROUPtmp.StockType,
						[CommonJournalBatchDetailId] = GROUPtmp.CommonJournalBatchDetailId,
						[ReferenceId] = @ReceivingReconciliationId,
						[ReferenceTypeId] = 1
					FROM ( SELECT TOP 1 VendorId,VendorName,ItemMasterId,PartId,PartNumber,PoId,PONum,RoId,RONum,StocklineId,StocklineNumber,Consignment,[Description],
								[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],[Location],[BinId],[Bin],[ShelfId],[Shelf],TMPCB.[StockType],[CommonJournalBatchDetailId],
								TMPCB.[ReferenceId],[ReferenceTypeId]
							FROM #TMPCommonBatchDetail TMPCB
							JOIN #TMPVendorProformaInv TMPVP ON TMPCB.RoId = TMPVP.ReferenceId AND [Type] = 2
						) GROUPtmp 
					WHERE TMPBatchId = @CommonJournalBatchDetailId;
				
				END

				PRINT '1.18.1'
				PRINT GETUTCDATE();
				INSERT INTO #TMPBatchFinalResult ([TMPBatchId], JournalBatchDetailId, JournalTypeNumber, CurrentNumber, DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], 
						[GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], 
						[IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy],
						[UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ReferenceId], [ReferenceNumber], [ReferenceName], 
						[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule], PoId, RoId, StockType)
				SELECT	MAX([TMPBatchId]), JournalBatchDetailId, JournalTypeNumber, CurrentNumber, DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], 
						[GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], MAX([EntryDate]), [JournalTypeId], [JournalTypeName], 
						[IsDebit], SUM([DebitAmount]) [DebitAmount], SUM([CreditAmount]) [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy],
						[UpdatedBy], MAX([CreatedDate]), MAX([UpdatedDate]), [IsActive], [IsDeleted], [ReferenceId], [ReferenceNumber], [ReferenceName], 
						[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule], PoId, RoId, StockType
				FROM #TMPCommonBatchDetail
				GROUP BY 
						JournalBatchDetailId, JournalTypeNumber, CurrentNumber, DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], 
						[GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate],  [JournalTypeId], [JournalTypeName], 
						[IsDebit], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy],
						[UpdatedBy], [IsActive], [IsDeleted], [ReferenceId], [ReferenceNumber], [ReferenceName], 
						[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule], PoId, RoId, StockType

				PRINT '1.18.2' 
				PRINT GETUTCDATE();
				--SELECT * From #TMPBatchFinalResult

			
				IF((SELECT COUNT(1) FROM #TMPVendorProformaInv) > 0)
				BEGIN
					DECLARE @PayblePODistributionSetupId BIGINT;
					DECLARE @PaybleRODistributionSetupId BIGINT;
					DECLARE @DistributionSetupCode VARCHAR(100);
					DECLARE @DistributionCodeName VARCHAR(100);

					SET @DistributionSetupCode ='VPI-DEPOSIT';
					SET @DistributionCodeName  = 'VendorProformaInvoice';

					--GET Vendor Proforma GL Account Details
					SELECT TOP 1 @DistributionSetupId = ID
					FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE UPPER([DistributionSetupCode]) = UPPER(@DistributionSetupCode) 
						AND DistributionMasterId = (SELECT TOP 1 ID FROM dbo.DistributionMaster WITH(NOLOCK) WHERE DistributionCode = @DistributionCodeName)
						AND MasterCompanyId = @MasterCompanyId

					--GET PAYBLE ID to reduce payble amt
					SELECT TOP 1 @PayblePODistributionSetupId = ID
					FROM dbo.DistributionSetup WITH(NOLOCK)
					WHERE UPPER(DistributionSetupCode)=UPPER('RECPOACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @ManagementStructureId

					SELECT TOP 1 @PaybleRODistributionSetupId = ID
					FROM dbo.DistributionSetup WITH(NOLOCK)
					WHERE UPPER(DistributionSetupCode)=UPPER('RECROACCPAYABLE') AND DistributionMasterId=@DistributionMasterId AND MasterCompanyId = @ManagementStructureId

					UPDATE #TMPBatchFinalResult SET CreditAmount = CreditAmount - ProformaAmount
					FROM (
						SELECT SUM([ProformaAmount]) AS ProformaAmount, TMPVP.StockType, TMPVP.ReferenceId, [Type] 
						FROM #TMPVendorProformaInv TMPVP
						JOIN #TMPCommonBatchDetail TMPCB  ON TMPCB.PoId = TMPVP.ReferenceId 
						WHERE DistributionSetupId = @DistributionSetupId AND TMPVP.[Type] = 1
						GROUP BY TMPVP.StockType, TMPVP.ReferenceId, [Type] 
					) GroupTmp WHERE GroupTmp.StockType = #TMPBatchFinalResult.StockType 
						AND #TMPBatchFinalResult.PoId = GroupTmp.ReferenceId 
						AND #TMPBatchFinalResult.DistributionSetupId = @PayblePODistributionSetupId

					UPDATE #TMPBatchFinalResult SET CreditAmount = CreditAmount - ProformaAmount
					FROM (
						SELECT SUM([ProformaAmount]) AS ProformaAmount, TMPVP.StockType, TMPVP.ReferenceId, [Type] 
						FROM #TMPVendorProformaInv TMPVP
						JOIN #TMPCommonBatchDetail TMPCB  ON TMPCB.RoId = TMPVP.ReferenceId 
						WHERE DistributionSetupId = @DistributionSetupId AND TMPVP.[Type] = 2
						GROUP BY TMPVP.StockType, TMPVP.ReferenceId, [Type] 
					) GroupTmp WHERE GroupTmp.StockType = #TMPBatchFinalResult.StockType 
						AND #TMPBatchFinalResult.RoId = GroupTmp.ReferenceId 
						AND #TMPBatchFinalResult.DistributionSetupId = @PaybleRODistributionSetupId

						--SELECT * From #TMPBatchFinalResult

				END

				PRINT '1.18.3' 
				PRINT GETUTCDATE();

				--SELECT * From #TMPBatchFinalResult

				SELECT @TotalBatchRecords = MAX(BatchId), @CurrentRecordId = MIN(BatchId) FROM #TMPBatchFinalResult;

				WHILE(ISNULL(@CurrentRecordId, 0) <= ISNULL(@TotalBatchRecords, 0))
				BEGIN
					PRINT '1.18.4' 
					PRINT GETUTCDATE();
					PRINT @CurrentRecordId

					PRINT 'CommonJournalBatchDetailId : Insert Start'
					INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
					[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted],[ReferenceId],[ReferenceNumber],[ReferenceName],[LocalCurrency],[FXRate],[ForeignCurrency],[ReferenceModule])
					SELECT		JournalBatchDetailId, JournalTypeNumber, CurrentNumber, DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], 
								[GlAccountId], [GlAccountNumber], [GlAccountName], [TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], 
								[IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], [CreatedBy],
								[UpdatedBy], GETUTCDATE(), GETUTCDATE(), [IsActive], [IsDeleted], [ReferenceId], [ReferenceNumber], [ReferenceName], 
								[LocalCurrency],[FXRate],[ForeignCurrency], [ReferenceModule]
					FROM #TMPBatchFinalResult WHERE BatchId = @CurrentRecordId;
			
					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()
					--PRINT 'CommonJournalBatchDetailId : Insert End'
					--PRINT @CommonJournalBatchDetailId
					--PRINT GETUTCDATE();

					PRINT '1.18.4.1' 

					SELECT	@JournalBatchDetailId = JournalBatchDetailId, @UpdateBy = UpdatedBy,
							@ManagementStructureId = ManagementStructureId, @MasterCompanyId = MasterCompanyId
					FROM #TMPBatchFinalResult WHERE BatchId = @CurrentRecordId ;
						-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonJournalBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 

					PRINT '1.18.4.2'
					INSERT INTO [dbo].[StocklineBatchDetails](JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, PoId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], [StockType],[CommonJournalBatchDetailId],[ReferenceId],[ReferenceTypeId],[ReferenceNumber])
					SELECT TMPF.JournalBatchDetailId, TMPF.JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId, PartNumber, TMPC.PoId, PONum, TMPC.RoId, RONum, StocklineId, StocklineNumber, Consignment, [Description], [SiteId], [Site], [WarehouseId], [Warehouse], [LocationId], [Location], [BinId], [Bin], [ShelfId], [Shelf], TMPF.[StockType],@CommonJournalBatchDetailId,TMPF.[ReferenceId],[ReferenceTypeId],TMPF.[ReferenceNumber]
					FROM #TMPBatchFinalResult TMPF
					JOIN #TMPCommonBatchDetail TMPC ON TMPC.[TMPBatchId] = TMPF.[TMPBatchId]
					WHERE BatchId = @CurrentRecordId;

					SELECT @StocklineId = StocklineId FROM #TMPBatchFinalResult TMPF
					JOIN #TMPCommonBatchDetail TMPC ON TMPC.[TMPBatchId] = TMPF.[TMPBatchId]
					WHERE BatchId = @CurrentRecordId;

					PRINT '1.18.4.3'

					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId		

					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit = SUM(ISNULL(DebitAmount,0)),
						    @TotalCredit= SUM(ISNULL(CreditAmount,0)) 
						FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
						WHERE [JournalBatchDetailId] = @JournalBatchDetailId 
						GROUP BY JournalBatchDetailId
						
					UPDATE [dbo].[BatchDetails] 
						SET [DebitAmount] = @TotalDebit,
						    [CreditAmount] = @TotalCredit,
							[UpdatedDate] = GETUTCDATE(),
							[UpdatedBy] = @UpdateBy   
						WHERE [JournalBatchDetailId] = @JournalBatchDetailId

					SET @CurrentRecordId += 1;
					PRINT '1.18.5' 
					PRINT GETUTCDATE();
				END

				PRINT '1.18.6' 
				PRINT GETUTCDATE();
				/**************START: DO NOT DELETE BELOW CODE:  Update Stk Batch Detail Columns with Id by StocklineId : RAJESH GAMI **********/
				SELECT @MinRecordId = MIN(RecordId), @MaxRecordId = MAX(RecordId) FROM #RRPostType;
				WHILE @MinRecordId <= @MaxRecordId
				BEGIN
					PRINT @MinRecordId
					SELECT @StocklineId = StocklineId FROM #RRPostType	WHERE RecordId = @MinRecordId;
					EXEC [DBO].[UpdateStocklineBatchDetailsColumnsWithId] @StocklineId;
					SET @MinRecordId += 1;
				END;
				/**************END: Update Stk Batch Detail Columns with Id by StocklineId **********/

				-- FREIGHT AND TAX BATCH DETAIL --
				DECLARE @TotalFreight DECIMAL(18,6) = 0;
				DECLARE @TotalTax DECIMAL(18,6) = 0;
				DECLARE @TotalMisc DECIMAL(18,6) = 0;
				
				----- Total Freight -----
				SELECT @TotalFreight = SUM(ISNULL([InvoicedUnitCost],0)) FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId AND [IsManual] = 1 AND [PackagingId] = 1;			
				----- Total Tax -----
				SELECT @TotalTax = SUM(ISNULL([InvoicedUnitCost],0)) FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId AND [IsManual] = 1 AND [PackagingId] =  3;
		
				SELECT @TotalMisc = SUM(ISNULL([InvoicedUnitCost],0)) FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId AND [IsManual] = 1 AND [PackagingId] =  2;
				
				PRINT '1.18.7' 
				PRINT GETUTCDATE();
				IF(@TotalFreight > 0 OR @TotalTax > 0 OR @TotalMisc > 0)
				BEGIN
					EXEC [dbo].[USP_PostReceivingReconcilationFreightAndTaxBatchDetails] @ReceivingReconciliationId,@JournalBatchHeaderId,@JournalTypename,@jlTypeId,@jlTypeName,@INPUTMethod,@DisCode,@ModuleName,@AccountingPeriodId,@AccountingPeriod,@EmployeeId,@UpdateBy,@MasterCompanyId,@JournalTypeNumber,@currentNo;
				END
				PRINT '1.18.8' 
				PRINT GETUTCDATE();
				PRINT @JlBatchHeaderId
				
				SELECT @TotalDebit = SUM(ISNULL([DebitAmount],0)),
				       @TotalCredit = SUM(ISNULL([CreditAmount],0)) 
				FROM dbo.BatchDetails WITH(NOLOCK) 
				WHERE [JournalBatchHeaderId]=@JlBatchHeaderId and [IsDeleted]=0 
				--GROUP BY JournalBatchHeaderId
			   	       
				SET @TotalBalance = @TotalDebit - @TotalCredit

				PRINT '1.18.8.1' 
				
				UPDATE dbo.BatchHeader 
				  SET [TotalDebit] = @TotalDebit,
				      [TotalCredit] = @TotalCredit,
					  [TotalBalance] = @TotalBalance,
					  [UpdatedDate]=GETUTCDATE(),
					  [UpdatedBy]=@UpdateBy 
				 WHERE [JournalBatchHeaderId] = @JlBatchHeaderId

				 PRINT '1.18.9' 
				 PRINT GETUTCDATE();

				 --UPDATE PO/RO Deposite Amount based on PO RO
				 UPDATE PO SET DepositAmount = CASE WHEN ISNULL(DepositAmount, 0) >= ISNULL(ProformaAmount, 0) THEN  ISNULL(DepositAmount, 0) - ISNULL(ProformaAmount, 0) ELSE 0 END FROM dbo.PurchaseOrder PO WITH(NOLOCK) JOIN #TMPVendorProformaInv TMPVP  ON TMPVP.ReferenceId = PO.PurchaseOrderId WHERE TMPVP.[Type] = 1
				 UPDATE RO SET DepositAmount = CASE WHEN ISNULL(DepositAmount, 0) >= ISNULL(ProformaAmount, 0) THEN  ISNULL(DepositAmount, 0) - ISNULL(ProformaAmount, 0) ELSE 0 END FROM dbo.RepairOrder RO WITH(NOLOCK) JOIN #TMPVendorProformaInv TMPVP  ON TMPVP.ReferenceId = RO.RepairOrderId WHERE TMPVP.[Type] = 2
				 
				 IF((SELECT COUNT(1) FROM #TMPVendorProformaInv) > 0)
				 BEGIN
					UPDATE VendorProformaInvoiceHeader SET StatusId = @VendorProformaStatusId, UpdatedDate = GETUTCDATE() WHERE VendorProformaInvoiceId IN (SELECT VendorProformaInvoiceId FROM #TMPVendorProformaInv)
				 END
				 
				 --AutoPost Batch
				 IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
				 BEGIN
				 	EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
				 END
				 IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
				 BEGIN
				 	EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
				 END
				 PRINT '1.18.10' 
				 PRINT GETUTCDATE();

				IF OBJECT_ID(N'tempdb..#RRPostType') IS NOT NULL
				BEGIN
					DROP TABLE #RRPostType 
				END
				IF OBJECT_ID(N'tempdb..#TMPVendorProformaInv') IS NOT NULL
				BEGIN
				DROP TABLE #TMPVendorProformaInv
				END

				IF OBJECT_ID(N'tempdb..#TMPBatchFinalResult') IS NOT NULL
				BEGIN
				DROP TABLE #TMPBatchFinalResult
				END

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
				DROP TABLE #tmpCodePrefixes
				END

				IF OBJECT_ID(N'tempdb..#TMPCommonBatchDetail') IS NOT NULL
				BEGIN
				DROP TABLE #TMPCommonBatchDetail
				END
				END
		END 			
		--COMMIT TRANSACTION
		--ROLLBACK TRAN;
	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		--ROLLBACK TRAN;
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_STATE() AS ErrorState,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_PostCreateStocklineBatchDetails' 
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