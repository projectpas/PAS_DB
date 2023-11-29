/*************************************************************             
 ** File:   [USP_PostYearEndBatchDetails]             
 ** Author:  Hemant Saliya
 ** Description: This stored procedure is used to Close Acconting Calendor Year
 ** Purpose:           
 ** Date: 06/09/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    06/09/2023   Hemant Saliya  Created
 ************************************************************** 
 EXEC dbo.USP_ValidateYearEndBatchDetails @StartPeriodId=128,@EndPeriodId=140,@MasterCompanyId=1,@UserName=N'ADMIN User',@LegalEntityIds=N'1',@Memo=N'<p>Run for Demo And SilverXis</p>'
 EXEC dbo.USP_ValidateYearEndBatchDetails @StartPeriodId=127,@EndPeriodId=153,@MasterCompanyId=1,@UserName=N'ADMIN User',@LegalEntityIds=N'1,27,6,3',@Memo=N'<p>Test hem</p>'
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_ValidateYearEndBatchDetails]
(
	@StartPeriodId BIGINT,
	@EndPeriodId INT,
	@MasterCompanyId INT,
	@UserName VARCHAR(100),
	@LegalEntityIds VARCHAR(MAX),
	@Memo VARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			
			DECLARE @CloseAllPeriod BIT = 1;
			DECLARE @IsAccountByPass BIT = 0;
			DECLARE @StartDate DATETIME;
			DECLARE @EndDate DATETIME;
			DECLARE @Amount DECIMAL(18,2);
			DECLARE @FinalTotalRecord AS BIGINT = 0;
			DECLARE @FinalMinId AS BIGINT = 0;
			DECLARE @LegalEntityId BIGINT;
			DECLARE @Year INT;

			DECLARE @IsValid BIT = 0;
			
			IF OBJECT_ID(N'tempdb..#tmpAccountingPeriod') IS NOT NULL
			BEGIN
				DROP TABLE #tmpAccountingPeriod
			END

			CREATE TABLE #tmpAccountingPeriod
			(
				ID BIGINT NOT NULL IDENTITY, 
				AccountPeriodId BIGINT NULL,
				AccountPeriod VARCHAR(50) NULL,
				LegalEntityId BIGINT NULL,
				isAccStatusName BIT NULL,
				isAPStatusName BIT NULL,
				isARStatusName BIT NULL,
				isAssetStatusName BIT NULL,
				isInventoryStatusName BIT NULL,
			)

			IF OBJECT_ID(N'tempdb..#tmpLegalEntity') IS NOT NULL
			BEGIN
				DROP TABLE #tmpLegalEntity
			END

			CREATE TABLE #tmpLegalEntity
			(
				ID BIGINT NOT NULL IDENTITY, 
				LegalEntityId BIGINT NULL,
			)

			SELECT @StartDate = FromDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @StartPeriodId
			SELECT @EndDate = ToDate, @Year = FiscalYear FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @EndPeriodId

			INSERT INTO #tmpLegalEntity(LegalEntityId)
			SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,',')

			INSERT INTO #tmpAccountingPeriod (AccountPeriodId,AccountPeriod,LegalEntityId,isAccStatusName,isAPStatusName,isARStatusName,isAssetStatusName,isInventoryStatusName)
			SELECT AccountingCalendarId,PeriodName,LegalEntityId,ISNULL(isaccStatusName,1),ISNULL(isacpStatusName,1),ISNULL(isacrStatusName,1),ISNULL(isassetStatusName,1),ISNULL(isinventoryStatusName,1)
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,',')) 
					AND	(CAST(FromDate AS date) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE) OR
						 CAST(ToDate AS date) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE))
					AND MasterCompanyId = @MasterCompanyId AND IsActive= 1 AND IsDeleted = 0

			IF EXISTS(SELECT 1 FROM #tmpAccountingPeriod WHERE isAccStatusName = 1 OR isAPStatusName = 1 OR 
							isARStatusName = 1 OR isAssetStatusName = 1 OR isInventoryStatusName  = 1)
			BEGIN
				SET @CloseAllPeriod = 0;
			END

			SELECT @IsAccountByPass = IsAccountByPass FROM dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

			IF(@CloseAllPeriod = 1 AND @IsAccountByPass = 0)
			BEGIN
				DECLARE @TotalDebit decimal(18, 2) =0;
				DECLARE @TotalCredit decimal(18, 2) =0;
				DECLARE @DistributionMasterId BIGINT;
				DECLARE @DistributionCode VARCHAR(200);
				DECLARE @StatusId INT;
				DECLARE @PostedStatusId INT;
				DECLARE @ManualJournalStatusId INT;				
				DECLARE @StatusName VARCHAR(200);
				DECLARE @JournalTypeId INT;
				DECLARE @JournalTypeCode VARCHAR(200);
				DECLARE @Currentbatch varchar(100);  
				DECLARE @CurrentNumber int;
				DECLARE @CurrentPeriodId bigint=0;
				DECLARE @JournalTypeName varchar(256) = 0;
				DECLARE @AccountMSModuleId INT = 0;
				DECLARE @AccountPeriodIds INT = 0;
				DECLARE @PostingEndDate DATETIME = 0;
				DECLARE @batch VARCHAR(100)
				DECLARE @LineNumber int=1; 
				DECLARE @BatchManagementStructureId int;
				DECLARE @PostingPeriod VARCHAR(50);
				DECLARE @RevenueGLAccountTypeId AS BIGINT;
				DECLARE @ExpenseGLAccountTypeId AS BIGINT;
				DECLARE @BatchMSModuleId BIGINT; 
				DECLARE @ManualBatchMSModuleId BIGINT; 

				IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
				BEGIN
					DROP TABLE #TempTable
				END

				IF OBJECT_ID(N'tempdb..#FinalTempTable') IS NOT NULL
				BEGIN
					DROP TABLE #FinalTempTable
				END
				  
				CREATE TABLE #TempTable
				(
					rownumber BIGINT NOT NULL IDENTITY,
					GlAccountId BIGINT NULL,
					GLAccountCode VARCHAR(50) NULL,
					GLAccountName VARCHAR(100) NULL,
					ManagementStructureId BIGINT NULL,
					LegalEntityId BIGINT NULL,
					CreditAmount DECIMAL(18,2),
					DebitAmount DECIMAL(18,2)
				)

				CREATE TABLE #FinalTempTable
				(
					rownumber BIGINT NOT NULL IDENTITY,
					ManagementStructureId BIGINT NULL,
					LegalEntityId BIGINT NULL,
					CreditAmount DECIMAL(18,2),
					DebitAmount DECIMAL(18,2)
				)

				SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('Year End');
				SELECT @StatusId = Id,@StatusName = [name] FROM dbo.BatchStatus WITH(NOLOCK)  WHERE UPPER([Name]) = UPPER('Open')
				SELECT @PostedStatusId = Id FROM dbo.BatchStatus WITH(NOLOCK)  WHERE UPPER([Name]) = UPPER('Posted')
				SELECT @ManualJournalStatusId =  ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE [Name] = 'Posted' -- For Posted Manual Batch Details Only
				SELECT TOP 1 @JournalTypeId = JournalTypeId FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId = @MasterCompanyId 

				SELECT @JournalTypeCode = JournalTypeCode, @JournalTypename = JournalTypeName FROM dbo.JournalType WITH(NOLOCK)  WHERE ID = @JournalTypeId
				SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = UPPER('Accounting');
				SELECT @RevenueGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Revenue' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1
				SELECT @ExpenseGLAccountTypeId = GLAccountClassId FROM dbo.GLAccountClass WITH(NOLOCK) WHERE GLAccountClassName = 'Expense' AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0 AND IsActive = 1

				SET @BatchMSModuleId = 72 -- BATCH MS MODULE ID
				SET @ManualBatchMSModuleId = 73 -- MANUAL BATCH MS MODULE ID

				DECLARE @ID AS int = 0;	
				SELECT @ID = MAX(ID) FROM #tmpLegalEntity 

				WHILE(@ID > 0)
				BEGIN

					SELECT @LegalEntityId = LegalEntityId FROM #tmpLegalEntity WHERE ID = @ID

					INSERT INTO #TempTable(GlAccountId,GLAccountCode,GLAccountName,ManagementStructureId,LegalEntityId,DebitAmount,CreditAmount)
					SELECT CB.GlAccountId,GL.AccountCode,GL.AccountName,
						CB.ManagementStructureId,ML.LegalEntityId,
						SUM(ISNULL(CB.DebitAmount,0)),
						SUM(ISNULL(CB.CreditAmount,0))
					FROM dbo.CommonBatchDetails CB WITH(NOLOCK)
						INNER JOIN dbo.BatchDetails B WITH(NOLOCK) ON B.JournalBatchDetailId = CB.JournalBatchDetailId AND B.StatusId = @PostedStatusId
						INNER JOIN #tmpAccountingPeriod tmp ON B.AccountingPeriodId = tmp.AccountPeriodId
						INNER JOIN dbo.GLAccount GL WITH(NOLOCK) ON CB.GlAccountId = GL.GLAccountId
						INNER JOIN dbo.GLAccountClass GLC WITH(NOLOCK) ON GL.GLAccountTypeId = GLC.GLAccountClassId AND GLC.GLAccountClassId IN (@RevenueGLAccountTypeId, @ExpenseGLAccountTypeId)
						INNER JOIN dbo.AccountingBatchManagementStructureDetails M WITH(NOLOCK) ON CB.CommonJournalBatchDetailId = M.ReferenceId AND ModuleId = @BatchMSModuleId
						INNER JOIN dbo.ManagementStructureLevel ML WITH(NOLOCK) on M.Level1Id = ML.ID AND ML.LegalEntityId = @LegalEntityId
					WHERE CB.IsDeleted = 0 AND CB.MasterCompanyId = @MasterCompanyId AND B.IsDeleted = 0 AND
						CAST(B.PostedDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
					GROUP BY CB.GlAccountId,GL.AccountCode,GL.AccountName,CB.ManagementStructureId,ML.LegalEntityId
					ORDER BY GL.AccountCode

					SELECT @TotalDebit = SUM(ISNULL(DebitAmount,0)), @TotalCredit = SUM(ISNULL(CreditAmount,0)) FROM #TempTable WHERE LegalEntityId = @LegalEntityId

					IF(@TotalDebit > 0 OR @TotalCredit > 0)
					BEGIN
						INSERT INTO #FinalTempTable(ManagementStructureId,LegalEntityId,DebitAmount,CreditAmount)
						SELECT ManagementStructureId,LegalEntityId,SUM(ISNULL(DebitAmount,0)),SUM(ISNULL(CreditAmount,0))
						FROM #TempTable WHERE LegalEntityId = @LegalEntityId
						GROUP BY ManagementStructureId, LegalEntityId

						SELECT @FinalTotalRecord = COUNT(*), @FinalMinId = MIN(rownumber) FROM #FinalTempTable

						WHILE(@FinalMinId <= @FinalTotalRecord)
						BEGIN

							SELECT @Amount = ISNULL(DebitAmount,0) - ISNULL(CreditAmount,0)	FROM #FinalTempTable WHERE rownumber = @FinalMinId

							IF(@Amount <> 0)
							BEGIN
								SET @IsValid = 1;
							END

							SET @FinalMinId = @FinalMinId + 1

						END

					END
					
					SET @ID = @ID - 1
				 END
			END

			SELECT @IsValid AS IsValid
		END
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		---------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_PostYearEndBatchDetails' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
		, @ApplicationName VARCHAR(100) = 'PAS'
		---------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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