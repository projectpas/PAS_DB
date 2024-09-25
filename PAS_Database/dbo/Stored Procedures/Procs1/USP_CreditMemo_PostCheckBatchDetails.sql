/*************************************************************           
 ** File:   [USP_CreditMemo_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used insert account report in batch from CreditMemo.
 ** Purpose:         
 ** Date:   08/09/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    08/09/2023   Amit Ghediya		Created	
	2    08/13/2023   Amit Ghediya		Update SO Selection condition.	
	3    08/21/2023   Moin Bloch		Modify(Added Accounting MS Entry)
	4    08/23/2023   Amit Ghediya		Modify for restrict entry when amount is 0.	
	5    08/24/2023   Amit Ghediya		Add new column for 'InvoiceReferenceId' in CreditMemoPaymentBatchDetails.
	6	 09/18/2023   AMIT GHEDIYA	    Update status to Approved after post batch.
	7    10/16/2023   Moin Bloch		Modify(Added Posted Status Insted of Closed Credit Memo Status)
	8    11/21/2023   HEMANT SALIYA		Updated Journal Type Id and Name in Batch Details
	9    11/23/2023   Moin Bloch		Modify(LastMSLevel,AllMSlevels Issue Resolved)
	10   02/21/2023   Devendra Shekh	added if condtion with @IsRestrict and CM post issue resolved
	11   04/05/2024   HEMANT SALIYA		Updated for Accounting Entry Changes
	12   04/19/2024   Devendra Shekh	added changes for exchange and saving MSId For [CreditMemoPaymentBatchDetails]
	13   04/22/2024   Devendra Shekh	modified to manage module Data InvoiceTypeId Wise
	14   20/09/2024	  AMIT GHEDIYA		Added for AutoPost Batch

	EXEC USP_CreditMemo_PostCheckBatchDetails 179
     
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_CreditMemo_PostCheckBatchDetails]
@CreditMemoHeaderId BIGINT
AS
BEGIN 
	BEGIN TRY
		DECLARE @CodeTypeId AS BIGINT;
		DECLARE @MasterCompanyId BIGINT=0;   
		DECLARE @UpdateBy VARCHAR(100);
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @DistributionMasterId BIGINT;    
		DECLARE @DistributionCode VARCHAR(200); 
		DECLARE @CurrentManagementStructureId BIGINT=0; 
		DECLARE @StatusId INT;   
		DECLARE @StatusName VARCHAR(200);   
		DECLARE @ApprovedStatusId INT;
		DECLARE @ApprovedStatusName VARCHAR(50);
		DECLARE @AccountingPeriod VARCHAR(100);    
		DECLARE @AccountingPeriodId BIGINT=0;   
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
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(MAX)
		DECLARE @TotalDebit DECIMAL(18, 2) =0;
		DECLARE @TotalCredit DECIMAL(18, 2) =0;
		DECLARE @TotalBalance DECIMAL(18, 2) =0;
		DECLARE @DocumentNumber VARCHAR(20);
		DECLARE @ExtDate DATETIME;
		DECLARE @DistributionCodeName VARCHAR(100);
		DECLARE @CrDrType INT=0;
		DECLARE @CodePrefix VARCHAR(50);
		DECLARE @IsWorkOrder INT;
		DECLARE @MasterLoopID AS INT;
		DECLARE @InvoiceReferenceId BIGINT;
		DECLARE @AccountMSModuleId INT = 0;
		DECLARE @AppModuleId INT = 0;
		DECLARE @CreditMemoDetailId BIGINT;
		DECLARE @temptotaldebitcount DECIMAL(18,2)=0;
		DECLARE @temptotalcreditcount DECIMAL(18,2)=0;
		DECLARE @IsExchange BIT = 0;
		DECLARE @InvoiceTypeId INT = 0;

		Declare @WOInvoiceTypeId INT = 0;
		Declare @SOInvoiceTypeId INT = 0;
		Declare @ExchangeInvoiceTypeId INT = 0;
		DECLARE @IsAutoPost INT = 0;
		DECLARE @IsBatchGenerated INT = 0;

		SELECT @WOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'WORKORDER';
		SELECT @SOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'SALESORDER';
		SELECT @ExchangeInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'EXCHANGE';
		
		SELECT @ApprovedStatusId = Id, @ApprovedStatusName = Name FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE Name = 'Posted';
		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
		SELECT @CodeTypeId = CodeTypeId FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE CodeType = 'JournalType';

		--TMPCODEPREFIXES TABLE.
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

		--READING MANAGEMENTSTRUCTUREID FROM CONDITION BASE.
		SELECT @UpdateBy = CreatedBy, @IsWorkOrder = ISNULL(IsWorkOrder, 0), @DocumentNumber = CreditMemoNumber , @MasterCompanyId = MasterCompanyId, @InvoiceTypeId = ISNULL(InvoiceTypeId, 0) FROM [DBO].[CreditMemo] WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;
		SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode) = UPPER('CMDISACC');
		SELECT @StatusId = Id, @StatusName = [name] FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE [Name] = 'Open'
		SELECT @JournalTypeId = ID, @JournalTypeCode = JournalTypeCode, @JournalTypename = JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE JournalTypeCode = 'CMDA';
		SELECT @JournalBatchHeaderId = JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId AND StatusId = @StatusId
		SELECT @CurrentManagementStructureId = ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) AND MasterCompanyId = @MasterCompanyId
		
		DECLARE @IsRestrict INT;
		DECLARE @IsAccountByPass BIT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;
		
		IF(ISNULL(@IsAccountByPass, 0) = 0)
		BEGIN

			INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
			SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
			FROM [DBO].[CodePrefixes] CP WITH(NOLOCK) JOIN [DBO].[CodeTypes] CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
			WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
		
			SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
			FROM [DBO].[EntityStructureSetup] est WITH(NOLOCK) 
			INNER JOIN [DBO].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			INNER JOIN [DBO].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
			WHERE est.EntityStructureId=@CurrentManagementStructureId AND acc.MasterCompanyId=@MasterCompanyId  
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

	--------------------------------------------------------------------------------------------------------------------------
			--tmpCommonJournalBatchDetail table.
			IF OBJECT_ID(N'tempdb..#tmpCommonJournalBatchDetail') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCommonJournalBatchDetail
			END

			--tmpCommonJournalBatchDetail table create
			CREATE TABLE #tmpCommonJournalBatchDetail
			(
				ID BIGINT NOT NULL IDENTITY, 
				CreditMemoHeaderId BIGINT NULL,
				CreditMemoDetailId BIGINT NULL,
			)

			--#TMPCOMMONBATCHDETAILS TABLE.
			IF OBJECT_ID(N'tempdb..#tmpCommonBatchDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCommonBatchDetails
			END

			CREATE TABLE #tmpCommonBatchDetails
			(
				ID BIGINT NOT NULL IDENTITY, 
				GlAccountId BIGINT NULL,
				GlAccountNumber VARCHAR(100) NULL,
				GlAccountName VARCHAR(100) NULL,
				IsDebit INT NULL,
				DebitAmount DECIMAL(18,2) NULL,
				CreditAmount DECIMAL(18,2) NULL,
				ManagementStructureId BIGINT NULL,
				JournalTypeId BIGINT NULL,
				JournalTypeName VARCHAR(100) NULL,
				DistributionSetupId BIGINT NULL,
				DistributionName VARCHAR(100) NULL,
				BillingInvoicingItemId BIGINT NULL,
				InvoiceReferenceId BIGINT NULL,
				LastMSLevel VARCHAR(MAX) NULL,
				AllMSlevels VARCHAR(MAX) NULL
			)

			--INSERT RECORDS IN #TMPCOMMONJOURNALBATCHDETAIL IF RECORDS ARE AVAILABLES.
			IF(@InvoiceTypeId IN (@SOInvoiceTypeId,@ExchangeInvoiceTypeId))
			BEGIN
				SELECT @AppModuleId = ManagementStructureModuleId FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='Stockline';
			END
			ELSE IF(@InvoiceTypeId = @WOInvoiceTypeId)
			BEGIN
				SELECT @AppModuleId = ManagementStructureModuleId FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='WorkOrderMPN';
			END

			INSERT INTO #tmpCommonJournalBatchDetail(CreditMemoHeaderId, CreditMemoDetailId)
			SELECT CreditMemoHeaderId, CreditMemoDetailId FROM [DBO].[CreditMemoDetails] WHERE CreditMemoHeaderId = @CreditMemoHeaderId;

			--SELECT * FROM #tmpCommonJournalBatchDetail

			--CHECK RECORDS ARE AVAILABLES.
			IF EXISTS(SELECT * FROM #tmpCommonJournalBatchDetail)
			BEGIN
				SELECT  @MasterLoopID = MAX(ID) FROM #tmpCommonJournalBatchDetail
				WHILE(@MasterLoopID > 0)
				BEGIN
					DECLARE @ARTAmount DECIMAL(18,2) = 0;
					DECLARE @ARTRESTOCKINGFEESAmount DECIMAL(18,2) = 0;
					DECLARE @COGSPARTSAmount DECIMAL(18,2) = 0;
					DECLARE @COGSLABORAmount DECIMAL(18,2) = 0;
					DECLARE @COGSOHAmount DECIMAL(18,2) = 0;
					DECLARE @INVTOBILLAmount DECIMAL(18,2) = 0;
					DECLARE @REVENUEAmount DECIMAL(18,2) = 0;
					DECLARE @REVENUEMISCCHARGEAmount DECIMAL(18,2) = 0;
					DECLARE @REVRESTOCKINGFEESAmount DECIMAL(18,2) = 0;
					DECLARE @REVENUEFREIGHTAmount DECIMAL(18,2) = 0;
					DECLARE @SALESTAXAmount DECIMAL(18,2) = 0;
					DECLARE @OTHERTAXAmount DECIMAL(18,2) = 0;
					DECLARE @BillingInvoicingItemId BIGINT = NULL;

					SELECT @CreditMemoDetailId = CreditMemoDetailId FROM #tmpCommonJournalBatchDetail
					WHERE ID  = @MasterLoopID;

					SELECT @ARTAmount = ABS(ISNULL(UnitPrice, 0)), @ARTRESTOCKINGFEESAmount = ABS(ISNULL(RestockingFee, 0)), @COGSPARTSAmount = ABS(ISNULL(CogsParts, 0)), 
						   @COGSLABORAmount = Abs(ISNULL(CogsLabor, 0)), @COGSOHAmount = Abs(ISNULL(CogsOverHeadCost, 0)), @INVTOBILLAmount = ABS(ISNULL(CogsInventory, 0)), 
						   @REVENUEAmount = (ABS(ISNULL(UnitPrice, 0)) - ABS((ISNULL(MiscRevenue, 0) + ISNULL(FreightRevenue, 0) + ISNULL(SalesTax, 0) + ISNULL(OtherTax, 0)))),
						   @REVENUEMISCCHARGEAmount = ABS(ISNULL(MiscRevenue, 0)), @REVENUEFREIGHTAmount = ABS(ISNULL(FreightRevenue, 0)), @SALESTAXAmount = ABS(ISNULL(SalesTax, 0)),
						   @OTHERTAXAmount = ABS(ISNULL(OtherTax, 0)), @REVRESTOCKINGFEESAmount = ABS(ISNULL(RestockingFee, 0)), @BillingInvoicingItemId = BillingInvoicingItemId
					FROM [DBO].[CreditMemoDetails] WITH(NOLOCK)
					WHERE CreditMemoDetailId = @CreditMemoDetailId; 

					IF(@InvoiceTypeId = @SOInvoiceTypeId)
					BEGIN
						SELECT @InvoiceReferenceId = SL.StockLineId, @ManagementStructureId = SL.ManagementStructureId  
						FROM [dbo].[SalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK) 
							JOIN [dbo].[SalesOrderPart] SOP ON SOP.SalesOrderPartId = SOBII.SalesOrderPartId
							JOIN [dbo].[Stockline] SL ON SOBII.StockLineId = SL.StockLineId
						WHERE SOBillingInvoicingItemId = @BillingInvoicingItemId;

						SELECT @LastMSLevel = (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
						SELECT @AllMSlevels = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
					END
					ELSE IF(@InvoiceTypeId = @WOInvoiceTypeId)
					BEGIN
						SELECT @InvoiceReferenceId = WorkOrderPartId, @ManagementStructureId = WOP.ManagementStructureId  
						FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) 
							JOIN [dbo].[WorkOrderPartNumber]  WOP ON WOP.ID = WOBII.WorkOrderPartId
						WHERE WOBillingInvoicingItemId = @BillingInvoicingItemId;

						SELECT @LastMSLevel = (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
						SELECT @AllMSlevels = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
					END
					ELSE IF(@InvoiceTypeId = @ExchangeInvoiceTypeId)
					BEGIN
						SELECT @InvoiceReferenceId = ESOPN.StockLineId, @ManagementStructureId = SL.ManagementStructureId  --ESO.ManagementStructureId  
						FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] ESOBII WITH(NOLOCK) 
							JOIN [dbo].[ExchangeSalesOrderPart]  ESOPN ON ESOPN.ExchangeSalesOrderPartId = ESOBII.ExchangeSalesOrderPartId
							JOIN [dbo].[Stockline] SL ON ESOPN.StockLineId = SL.StockLineId
							--JOIN [dbo].[ExchangeSalesOrder]  ESO ON ESO.ExchangeSalesOrderId = ESOPN.ExchangeSalesOrderId
						WHERE ExchangeSOBillingInvoicingItemId = @BillingInvoicingItemId;

						SELECT @LastMSLevel = (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
						SELECT @AllMSlevels = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
					END

					-----START Account Recevable Trade--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType =  0,@IsAutoPost = ISNULL(IsAutoPost,0) --CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMART' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId
					IF(ISNULL(@ARTAmount,0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @ARTAmount ELSE 0 END As DebitAmount, CASE WHEN @CrDrType = 1 THEN 0 ELSE @ARTAmount END As CreditAmount,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----END Account Recevable--------

					-----RESTOCKING FEES Account Recevable Trade--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = 1--CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMART' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@ARTRESTOCKINGFEESAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @ARTRESTOCKINGFEESAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @ARTRESTOCKINGFEESAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----RESTOCKING FEES Account Recevable--------

					-----COGS - PARTS--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMCOGSPARTS' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@COGSPARTSAmount, 0) != 0)
					BEGIN
					INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @COGSPARTSAmount ELSE 0 END, 
							   CASE WHEN @CrDrType = 1 THEN 0 ELSE @COGSPARTSAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----COGS - PARTS--------

					-----COGS - DIRECT LABOR--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMCOGSLABOR' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@COGSLABORAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @COGSLABORAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @COGSLABORAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----COGS - DIRECT LABOR--------

					-----COGS - OVERHEAD--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMCOGSOH' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@COGSOHAmount, 0) != 0)
					BEGIN
					INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @COGSOHAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @COGSOHAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----COGS - OVERHEAD--------

					-----INVENTORY TO BILL--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMINVBL' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@INVTOBILLAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @INVTOBILLAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @INVTOBILLAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----INVENTORY TO BILL--------

					-----REVENUE - WO/SO--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMREVENUE' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@REVENUEAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @REVENUEAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @REVENUEAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----REVENUE - WO/SO--------

					-----REVENUE - MISC CHARGE--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMREVENUEMC' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@REVENUEMISCCHARGEAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @REVENUEMISCCHARGEAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @REVENUEMISCCHARGEAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----REVENUE - MISC CHARGE--------

					-----MISC REVENUE - RESTOCKING FEES--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMRESFEES' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@REVRESTOCKINGFEESAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @REVRESTOCKINGFEESAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @REVRESTOCKINGFEESAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----MISC REVENUE - RESTOCKING FEES--------

					-----REVENUE - FREIGHT--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMREVENUEFRE' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@REVENUEFREIGHTAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @REVENUEFREIGHTAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @REVENUEFREIGHTAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----REVENUE - FREIGHT--------

					-----SALES TAX PAYABLE--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMSALESTAX' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@SALESTAXAmount, 0) != 0)
					BEGIN
						INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @SALESTAXAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @SALESTAXAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----SALES TAX PAYABLE--------

					-----TAX PAYABLE - OTHER--------
					SELECT TOP 1 @DistributionSetupId = ID, @DistributionName = Name, @JournalTypeId = JournalTypeId, @GlAccountId = GlAccountId, 
								 @GlAccountNumber = GlAccountNumber, @GlAccountName = GlAccountName , @CrDrType = CASE WHEN ISNULL(CRDRType,0) = 1 THEN 1 ELSE 0 END 
					FROM [DBO].[DistributionSetup] WITH(NOLOCK)  
					WHERE DistributionSetupCode = 'CMOTHERTAX' AND MasterCompanyId = @MasterCompanyId AND DistributionMasterId = @DistributionMasterId

					IF(ISNULL(@OTHERTAXAmount, 0) != 0)
					BEGIN
					INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,InvoiceReferenceId,ManagementStructureId,LastMSLevel,AllMSlevels,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName, BillingInvoicingItemId)
						SELECT @GlAccountId,@GlAccountNumber,@GlAccountName,@CrDrType,
							   CASE WHEN @CrDrType = 1 THEN @OTHERTAXAmount ELSE 0 END, CASE WHEN @CrDrType = 1 THEN 0 ELSE @OTHERTAXAmount END,
							   @InvoiceReferenceId, @ManagementStructureId, @LastMSLevel, @AllMSlevels, @JournalTypeId, @JournalTypename, @DistributionSetupId, @DistributionName, @BillingInvoicingItemId
					END
					-----TAX PAYABLE - OTHER--------

					SET @MasterLoopID = @MasterLoopID - 1;
				END
			END
				
			SELECT @temptotaldebitcount = SUM(ISNULL(DebitAmount,0)), @temptotalcreditcount = SUM(ISNULL(CreditAmount,0))  
			FROM #tmpCommonBatchDetails;

			--SELECT * FROM #tmpCommonBatchDetails
					
			IF(@temptotaldebitcount > 0 OR @temptotalcreditcount > 0)
			BEGIN
		
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
					  @JournalTypeId,@JournalTypename,0,0,0,@MasterCompanyId,
					  @UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,@JournalTypeCode);    
                           
					SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()    
					UPDATE [dbo].[BatchHeader] set CurrentNumber=@CurrentNumber WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
				END
				ELSE
				BEGIN 
					SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId   
					   SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END   
							 FROM [DBO].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  ORDER BY JournalBatchDetailId DESC   
          
					IF(@CurrentPeriodId =0)  
					BEGIN  
					   Update [DBO].[BatchHeader] SET AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod  WHERE JournalBatchHeaderId= @JournalBatchHeaderId  
					END 
					
					SET @IsBatchGenerated = 1;
				END

				INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
				[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
				@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
				NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
		
				SET @JournalBatchDetailId = SCOPE_IDENTITY();

				--REDING DATA FROM EXISTING GL DATA & INSERT FOR CREDITMEMO
				SELECT  @MasterLoopID = MAX(ID) FROM #tmpCommonBatchDetails
				WHILE(@MasterLoopID > 0)
				BEGIN			
					
					SELECT @ManagementStructureId = ManagementStructureId, @LastMSLevel = LastMSLevel, @AllMSlevels = AllMSlevels , @BillingInvoicingItemId = BillingInvoicingItemId, 
						   @InvoiceReferenceId = InvoiceReferenceId
					FROM #tmpCommonBatchDetails WHERE ID  = @MasterLoopID;

					INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
							[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
							[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					SELECT  @JournalBatchDetailId,@JournalTypeNumber,@currentNo,DistributionSetupId,DistributionName,@JournalBatchHeaderId,1 
							,GlAccountId ,GlAccountNumber ,GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							--CASE WHEN IsDebit = 0 THEN 1 ELSE 0 END,
							IsDebit,
							DebitAmount,
							CreditAmount,
							ManagementStructureId ,'CreditMemo',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
							@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0
					FROM #tmpCommonBatchDetails WHERE ID  = @MasterLoopID;

					SET @CommonBatchDetailId = SCOPE_IDENTITY();

					-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
				
					INSERT INTO [dbo].[CreditMemoPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,ModuleId,CheckDate,CommonJournalBatchDetailId,InvoiceReferenceId,ManagementStructureId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@CreditMemoHeaderId,@DocumentNumber,@AppModuleId,@ExtDate,@CommonBatchDetailId,@InvoiceReferenceId,@ManagementStructureId);

					SET @MasterLoopID = @MasterLoopID - 1;
				END
			
				--------------------------------------------------------------------------------------------------------------------------
			
				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit = SUM(DebitAmount), @TotalCredit = SUM(CreditAmount) FROM [DBO].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
				UPDATE [dbo].[BatchDetails] SET DebitAmount = @TotalDebit, CreditAmount = @TotalCredit, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdateBy  WHERE JournalBatchDetailId = @JournalBatchDetailId

				SELECT @TotalDebit = SUM(DebitAmount), @TotalCredit = SUM(CreditAmount) FROM [DBO].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND IsDeleted=0 

				SET @TotalBalance = ISNULL(@TotalDebit, 0) - ISNULL(@TotalCredit,0)

				UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
				UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						
			END
		END

		--Update status to Approved after all postbatch.
		UPDATE [dbo].[CreditMemo] SET StatusId = @ApprovedStatusId, Status = @ApprovedStatusName WHERE CreditMemoHeaderId = @CreditMemoHeaderId;

		--AutoPost Batch
		IF(@IsAutoPost = 1 AND @IsBatchGenerated = 0)
		BEGIN
			EXEC [dbo].[UpdateToPostFullBatch] @JournalBatchHeaderId,@UpdateBy;
		END
		IF(@IsAutoPost = 1 AND @IsBatchGenerated = 1)
		BEGIN
			EXEC [dbo].[USP_UpdateCommonBatchStatus] @JournalBatchDetailId,@UpdateBy,@AccountingPeriodId,@AccountingPeriod;
		END

		--Return CreditMemoHeaderId
		SELECT @CreditMemoHeaderId AS CreditMemoHeaderId;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreditMemo_PostCheckBatchDetails' 
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