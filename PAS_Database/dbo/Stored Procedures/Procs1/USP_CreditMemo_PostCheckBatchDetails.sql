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

	EXEC USP_CreditMemo_PostCheckBatchDetails 216
     
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
		DECLARE @StartsFrom VARCHAR(200)='00'
		DECLARE @GlAccountName VARCHAR(200) 
		DECLARE @GlAccountNumber VARCHAR(200) 
		DECLARE @ExtAmount DECIMAL(18,2)
		DECLARE @BankId INT =0;
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(MAX)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit DECIMAL(18, 2) =0;
		DECLARE @TotalCredit DECIMAL(18, 2) =0;
		DECLARE @TotalBalance DECIMAL(18, 2) =0;
		DECLARE @ExtNumber VARCHAR(20);
		DECLARE @VendorName VARCHAR(50);
		DECLARE @ExtDate DATETIME;
		DECLARE @stklineId BIGINT;
		DECLARE @DistributionCodeName VARCHAR(100);
		DECLARE @CrDrType INT=0;
		DECLARE @CodePrefix VARCHAR(50);
		DECLARE @FinalSaleAsset DECIMAL(18,2)=0;
		DECLARE @BenifitAmount DECIMAL(18,2)=0;
		DECLARE @IsSaleAssetDRCR INT = 0;
		DECLARE @SaleAssetDRCR INT = 1;
		DECLARE @AssetInventoryName VARCHAR(100);
		DECLARE @IsWorkOrder INT;
		DECLARE @InvoiceNumber VARCHAR(100);
		DECLARE @MasterLoopID AS INT;
		DECLARE @CommonJournalBatchDetailId BIGINT;
		DECLARE @InvoiceReferenceId BIGINT;
		DECLARE @IsWorkOrdermnt INT;
		DECLARE @InvoiceNumbermnt VARCHAR(100);
		DECLARE @JournalBatchDetailIdmnt BIGINT;
		DECLARE @AccountMSModuleId INT = 0;
		DECLARE @AppModuleId INT = 0;
		DECLARE @InvoiceId BIGINT;
		DECLARE @WorkFlowWorkOrderId  BIGINT;
		DECLARE  @temptotaldebitcount DECIMAL(18,2)=0,@temptotalcreditcount DECIMAL(18,2)=0;
		
		SELECT @ApprovedStatusId = Id, @ApprovedStatusName = Name FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE Name = 'Posted';

		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SET @DistributionCodeName = 'CMDA';

		SELECT @CodeTypeId = CodeTypeId FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE CodeType = 'JournalType';

		--tmpCodePrefixes table.
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

		--Reading ManagementStructureId from condition base.
		SELECT @UpdateBy = CreatedBy,@InvoiceNumbermnt = InvoiceNumber,@IsWorkOrdermnt = IsWorkOrder,
		      @MasterCompanyId = MasterCompanyId 
		FROM [DBO].[CreditMemo] WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;
		
		IF(@IsWorkOrdermnt = 0)
		BEGIN 
			--PRINT 'SO'
			SELECT TOP 1 @JournalBatchDetailIdmnt = JournalBatchDetailId FROM [DBO].[SalesOrderBatchDetails] WITH(NOLOCK) 
			WHERE DocumentNumber = @InvoiceNumbermnt;

			SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM [DBO].[CommonBatchDetails] WITH(NOLOCK) 
			WHERE JournalBatchDetailId = @JournalBatchDetailIdmnt;

			SELECT @LastMSLevel = (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
			SELECT @AllMSlevels = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
		END
		ELSE IF(@IsWorkOrdermnt = 1)
		BEGIN
			--PRINT 'WO'
			SELECT TOP 1 @JournalBatchDetailIdmnt = JournalBatchDetailId FROM [DBO].[WorkOrderBatchDetails] WITH(NOLOCK) 
			WHERE InvoiceName = @InvoiceNumbermnt;

			SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM [DBO].[CommonBatchDetails] WITH(NOLOCK) 
			WHERE JournalBatchDetailId = @JournalBatchDetailIdmnt;

			SELECT @LastMSLevel = (SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
			SELECT @AllMSlevels = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@ManagementStructureId))
		END

		SELECT @DistributionMasterId =ID,@DistributionCode =DistributionCode FROM [DBO].DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('CMDISACC');
		SELECT @StatusId =Id,@StatusName=name FROM [DBO].[BatchStatus] WITH(NOLOCK)  WHERE Name= 'Open'
		SELECT @JournalTypeId = ID, @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName FROM [DBO].[JournalType] WITH(NOLOCK)  WHERE JournalTypeCode = 'CMDA';
		SELECT @JournalBatchHeaderId = JournalBatchHeaderId FROM [DBO].[BatchHeader] WITH(NOLOCK)  WHERE JournalTypeId= @JournalTypeId and StatusId=@StatusId
		SELECT @CurrentManagementStructureId =ManagementStructureId FROM [DBO].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
		
		DECLARE @IsRestrict INT;

		EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT;
		
		IF(ISNULL(@IsRestrict, 0) = 0)
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
		
			--Get BatchDetails from tables.
			SELECT @IsWorkOrder = IsWorkOrder, @InvoiceNumber = InvoiceNumber, @InvoiceId = InvoiceId FROM [DBO].[CreditMemo] WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;
		
			--tmpCommonJournalBatchDetail table.
			IF OBJECT_ID(N'tempdb..#tmpCommonJournalBatchDetail') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCommonJournalBatchDetail
			END

			--tmpCommonJournalBatchDetail table create
			CREATE TABLE #tmpCommonJournalBatchDetail
			(
				ID BIGINT NOT NULL IDENTITY, 
				CommonJournalBatchDetailId BIGINT NULL,
				InvoiceReferenceId BIGINT NULL,
			)

			--tmpCommonBatchDetails table.
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
				DistributionName VARCHAR(100) NULL
			)

			--insert records in tmpCommonJournalBatchDetail if records are availables.
			IF(@IsWorkOrder = 0)
			BEGIN
				SELECT @AppModuleId = ManagementStructureModuleId FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='SalesOrder';

				INSERT INTO #tmpCommonJournalBatchDetail(CommonJournalBatchDetailId,InvoiceReferenceId)
				SELECT CommonJournalBatchDetailId,SalesOrderId FROM [DBO].[SalesOrderBatchDetails] WITH(NOLOCK) WHERE DocumentNumber = @InvoiceNumber;
			END
			ELSE IF(@IsWorkOrder = 1)
			BEGIN
				SELECT @AppModuleId = ManagementStructureModuleId FROM [DBO].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='WorkOrderMPN';

				INSERT INTO #tmpCommonJournalBatchDetail(CommonJournalBatchDetailId,InvoiceReferenceId)
				SELECT CommonJournalBatchDetailId,ReferenceId FROM [DBO].[WorkOrderBatchDetails] WITH(NOLOCK) WHERE InvoiceName = @InvoiceNumber;
			END
			print 1

			--Check records are availables.
			IF EXISTS(SELECT * FROM #tmpCommonJournalBatchDetail)
			BEGIN
				SELECT  @MasterLoopID = MAX(ID) FROM #tmpCommonJournalBatchDetail
				WHILE(@MasterLoopID > 0)
				BEGIN
					SELECT @CommonJournalBatchDetailId = CommonJournalBatchDetailId , @InvoiceReferenceId = InvoiceReferenceId FROM #tmpCommonJournalBatchDetail
					WHERE ID  = @MasterLoopID;

					INSERT INTO #tmpCommonBatchDetails(GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,ManagementStructureId,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName)
					SELECT GlAccountId,GlAccountNumber,GlAccountName,IsDebit,DebitAmount,CreditAmount,ManagementStructureId,JournalTypeId,JournalTypeName,DistributionSetupId,DistributionName
						FROM [DBO].[CommonBatchDetails] WITH(NOLOCK)
					WHERE CommonJournalBatchDetailId = @CommonJournalBatchDetailId; 

					SET @MasterLoopID = @MasterLoopID - 1;
				END
			END
				
			SELECT @temptotaldebitcount =SUM(ISNULL(DebitAmount,0)),@temptotalcreditcount =SUM(ISNULL(CreditAmount,0))  
				FROM #tmpCommonBatchDetails;
					
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
				END

				INSERT INTO [DBO].[BatchDetails](JournalTypeNumber,CurrentNumber,DistributionSetupId, DistributionName, [JournalBatchHeaderId], [LineNumber], [GlAccountId], [GlAccountNumber], [GlAccountName], 
				[TransactionDate], [EntryDate], [JournalTypeId], [JournalTypeName], [IsDebit], [DebitAmount], [CreditAmount], [ManagementStructureId], [ModuleName], LastMSLevel, AllMSlevels, [MasterCompanyId], 
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES(@JournalTypeNumber,@currentNo,0, NULL, @JournalBatchHeaderId, 1, 0, NULL, NULL, GETUTCDATE(), GETUTCDATE(), 
				@JournalTypeId, @JournalTypename, 1, 0, 0, @ManagementStructureId, @DistributionCodeName, 
				NULL, NULL, @MasterCompanyId, @UpdateBy, @UpdateBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
		
				SET @JournalBatchDetailId = SCOPE_IDENTITY();

				--Reding data from existing gl data & insert for creditmemo
				SELECT  @MasterLoopID = MAX(ID) FROM #tmpCommonBatchDetails
				WHILE(@MasterLoopID > 0)
				BEGIN			
					SELECT @ManagementStructureId = ManagementStructureId FROM #tmpCommonBatchDetails WHERE ID  = @MasterLoopID;

					INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],
							[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],
							[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],
							[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					SELECT  @JournalBatchDetailId,@JournalTypeNumber,@currentNo,DistributionSetupId,DistributionName,@JournalBatchHeaderId,1 
							,GlAccountId ,GlAccountNumber ,GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename,
							CASE WHEN IsDebit = 0 THEN 1 ELSE 0 END,
							CreditAmount,
							DebitAmount,
							ManagementStructureId ,'CreditMemo',@LastMSLevel,@AllMSlevels ,@MasterCompanyId,
							@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0
					FROM #tmpCommonBatchDetails WHERE ID  = @MasterLoopID;

					SET @CommonBatchDetailId = SCOPE_IDENTITY();

				-----  Accounting MS Entry  -----

					EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
				
					IF(@IsWorkOrder = 1) -- For get Workorder partnumber for refrenceId
					BEGIN
						SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId  FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK) WHERE BillingInvoicingId = @InvoiceId;
						SELECT @InvoiceReferenceId = WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
					END

					INSERT INTO [dbo].[CreditMemoPaymentBatchDetails](JournalBatchHeaderId,JournalBatchDetailId,ReferenceId,DocumentNo,ModuleId,CheckDate,CommonJournalBatchDetailId,InvoiceReferenceId)
					VALUES(@JournalBatchHeaderId,@JournalBatchDetailId,@CreditMemoHeaderId,@ExtNumber,@AppModuleId,@ExtDate,@CommonBatchDetailId,@InvoiceReferenceId);

					SET @MasterLoopID = @MasterLoopID - 1;
				END
			
	--------------------------------------------------------------------------------------------------------------------------
			
				SET @TotalDebit=0;
				SET @TotalCredit=0;
				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [DBO].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@JournalBatchDetailId GROUP BY JournalBatchDetailId
				Update [dbo].[BatchDetails] SET DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy  WHERE JournalBatchDetailId=@JournalBatchDetailId

				SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM [DBO].[BatchDetails] 
				WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 
				SET @TotalBalance =@TotalDebit-@TotalCredit

				UPDATE [DBO].[CodePrefixes] SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
				UPDATE [DBO].[BatchHeader] SET TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy WHERE JournalBatchHeaderId= @JournalBatchHeaderId
						
			END
		END

		--Update status to Approved after all postbatch.
		UPDATE [dbo].[CreditMemo] SET StatusId = @ApprovedStatusId, Status = @ApprovedStatusName WHERE CreditMemoHeaderId = @CreditMemoHeaderId;

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