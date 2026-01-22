/*************************************************************             
 ** File:   [USP_ManualJournalBackgroundProcess]             
 ** Author:   
 ** Description: This stored procedure is used to create manual JE while job run
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    10/07/2023   Satish Gohil  Modify(added IsRecursiveDone flag and auto post while create if acc period is open and change as per effective date)
	2    13/07/2023   Satish Gohil  Modify(Add Approval Data and change for creating batch)
	3    01/09/2023   MOIN BLOCH    Modify(commented Reversing Entry from job)
	4    05/09/2023   MOIN BLOCH    Modify(commented Recurring Entry from job)
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_ManualJournalBackgroundProcess]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	DECLARE @ManualJournalHeaderId bigint;
	DECLARE @IsRecuring int;
	DECLARE @LegalEntityId bigint;
	DECLARE @MasterCompanyId int;
	DECLARE @StatusId INT;

	--IF(CURSOR_STATUS('global','db_cursor') >= -1)
	--BEGIN
	--	DEALLOCATE db_cursor
	--END

	--SELECT @StatusId = ManualJournalStatusId FROM ManualJournalStatus WHERE Name = 'Approved'

--	DECLARE db_cursor CURSOR FOR
----	select ManualJournalHeaderId,IsRecuring,LedgerId as LegalEntityId,MasterCompanyId from ManualJournalHeader where (MONTH(DATEADD(MONTH, 0, ReversingDate)) = MONTH(DATEADD(MONTH, -1, CURRENT_TIMESTAMP)) AND Day(DATEADD(Day, 0, ReversingDate)) = Day(DATEADD
----(Day, 0, CURRENT_TIMESTAMP))) OR (MONTH(DATEADD(MONTH, 0, EffectiveDate)) = MONTH(DATEADD(MONTH, -1, CURRENT_TIMESTAMP)) AND Day(DATEADD(Day, 0, EffectiveDate)) = Day(DATEADD(Day, 0, CURRENT_TIMESTAMP)) AND ReversingStatusId=1);
--	select ManualJournalHeaderId,IsRecuring,LedgerId as LegalEntityId,MasterCompanyId from ManualJournalHeader where
--	EffectiveDate <= CURRENT_TIMESTAMP AND ReversingStatusId=1 AND IsRecursiveDone = 0
--	AND ManualJournalStatusId = (select ManualJournalStatusId from dbo.ManualJournalStatus with(NOLOCK) where Name = 'Posted');

--	OPEN db_cursor  
--	FETCH NEXT FROM db_cursor INTO @ManualJournalHeaderId,@IsRecuring,@LegalEntityId,@MasterCompanyId
--	WHILE @@FETCH_STATUS = 0  
--	BEGIN  
--	      --print @ManualJournalHeaderId
--		  --print @IsRecuring
--		  --print @LegalEntityId
--		  DECLARE @AccountingCalendarId bigint;
--		  DECLARE @CodeTypeId AS BIGINT = 75;
--		  DECLARE @currentNo AS BIGINT = 0;
--		  DECLARE @JournalNumber varchar(100);
--		  DECLARE @EffectiveDate datetime;
--		  DECLARE @ReversingDate datetime;
--		  DECLARE @IsRecursiveDone BIT;
--		  DECLARE @AccountStatus BIT;
--		  DECLARE @ReversingStatusId INT;
--		  DECLARE @NewManualJournalHeaderId bigint;
--		  DECLARE @NewManualJournalDetailsId bigint;
--		  DECLARE @ManualJournalDetailsId bigint;
--		  DECLARE @MinId BIGINT = 1;      
--		  DECLARE @TotalRecord int = 0; 
--		  DECLARE @FromDate DateTime;
--		  DECLARE @ToDate DateTime;
--		  DECLARE @NextAccountingCalendarId bigint;

--		  --select DISTINCT @AccountingCalendarId=AC.AccountingCalendarId, @AccountStatus = ISNULL(AC.isaccStatusName,0) from dbo.EntityStructureSetup ESS WITH(NOLOCK)
--		  --inner join dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
--		  --inner join dbo.AccountingCalendar AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
--		  --where AC.LegalEntityId = @LegalEntityId
--		  --AND (CAST(GETUTCDATE() as date) BETWEEN AC.FromDate AND AC.ToDate)
--		  --AND AC.IsDeleted = 0 AND AC.FiscalYear=YEAR(GETUTCDATE()) order by AC.AccountingCalendarId;


--		  IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
--		  BEGIN
--		  DROP TABLE #tmpCodePrefixes
--		  END

--		  IF OBJECT_ID(N'tempdb..#tmpTbl') IS NOT NULL        
--		  BEGIN        
--			DROP TABLE #tmpTbl        
--		  END 

--		  CREATE TABLE #tmpTbl(        
--			[rowId] [bigint] IDENTITY ,    
--			ManualJournalHeaderId BIGINT,
--			ManualJournalDetailsId BIGINT
--		  ) 
		  
--		  CREATE TABLE #tmpCodePrefixes
--		  (
--		  	 ID BIGINT NOT NULL IDENTITY, 
--		  	 CodePrefixId BIGINT NULL,
--		  	 CodeTypeId BIGINT NULL,
--		  	 CurrentNumber BIGINT NULL,
--		  	 CodePrefix VARCHAR(50) NULL,
--		  	 CodeSufix VARCHAR(50) NULL,
--		  	 StartsFrom BIGINT NULL,
--		  )
		  
--		  INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
--		  SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
--		  FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
--		  WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
		  
--		  IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
--		  BEGIN 
--		  	SELECT 
--		  		@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
--		  			ELSE CAST(StartsFrom AS BIGINT) + 1 END 
--		  	FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
		  
--		  	SET @JournalNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
--		  END
--		  ELSE 
--		  BEGIN
--		  	ROLLBACK TRAN;
--		  END

--		  IF(@IsRecuring = 1)
--		  BEGIN

--			SELECT @EffectiveDate = EffectiveDate,@IsRecursiveDone = ISNULL(IsRecursiveDone,0) FROM DBO.ManualJournalHeader WHERE ManualJournalHeaderId = @ManualJournalHeaderId

--			select DISTINCT @NextAccountingCalendarId=AC.AccountingCalendarId,@AccountStatus = ISNULL(AC.isaccStatusName,0),@FromDate = FromDate,@ToDate = ToDate
--				from dbo.EntityStructureSetup ESS WITH(NOLOCK)
--			  inner join dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
--			  inner join dbo.AccountingCalendar AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
--			  where AC.LegalEntityId = @LegalEntityId
--			  AND (CAST(DATEADD(MONTH, 1, @EffectiveDate) as date) BETWEEN AC.FromDate AND AC.ToDate)
--			  AND AC.IsDeleted = 0 AND AC.FiscalYear=YEAR(DATEADD(MONTH, 1, @EffectiveDate)) order by AC.AccountingCalendarId;

--			IF((CAST(DATEADD(MONTH, 1, @EffectiveDate) as date)) <= (CAST(CURRENT_TIMESTAMP as date))  AND @IsRecursiveDone = 0 AND @FromDate IS NOT NULL)
--			BEGIN
--				print '1';
--				INSERT INTO [dbo].[ManualJournalHeader](
--						LedgerId,JournalNumber,JournalDescription,ManualJournalTypeId,ManualJournalBalanceTypeId,EntryDate,EffectiveDate,AccountingPeriodId,ManualJournalStatusId,IsRecuring,ReversingDate,ReversingaccountingPeriodId
--						,ReversingStatusId,FunctionalCurrencyId,ReportingCurrencyId,ConversionCurrencyDate,ConvertionTypeId,ConversionRate,ManagementStructureId,EmployeeId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate
--						,IsActive,IsDeleted,IsEnforce,EnforceEffectiveDate,IsRecursiveDone
--				)
--				SELECT LedgerId,@JournalNumber,JournalDescription,ManualJournalTypeId,ManualJournalBalanceTypeId,GETUTCDATE(),@FromDate,@NextAccountingCalendarId ,@StatusId,IsRecuring,ReversingDate,ReversingaccountingPeriodId
--						,ReversingStatusId,FunctionalCurrencyId,ReportingCurrencyId,ConversionCurrencyDate,ConvertionTypeId,ConversionRate,ManagementStructureId,EmployeeId,MasterCompanyId,CreatedBy,UpdatedBy,GETUTCDATE(),GETUTCDATE()
--						,1,0,IsEnforce,EnforceEffectiveDate,0
--						FROM ManualJournalHeader WHERE ManualJournalHeaderId=@ManualJournalHeaderId

--				--DECLARE @NewManualJournalHeaderId bigint;
--				--SET  @NewManualJournalHeaderId = @@IDENTITY;
--				print '@ManualJournalHeaderId'
--				print @ManualJournalHeaderId
--				SELECT @NewManualJournalHeaderId = SCOPE_IDENTITY();

--				UPDATE dbo.ManualJournalHeader SET IsRecursiveDone = 1 WHERE ManualJournalHeaderId = @ManualJournalHeaderId

--				INSERT INTO #tmpTbl(ManualJournalHeaderId,ManualJournalDetailsId)
--				SELECT ManualJournalHeaderId,ManualJournalDetailsId 
--				FROM dbo.ManualJournalDetails WHERE ManualJournalHeaderId = @ManualJournalHeaderId
				
--				SELECT @TotalRecord = COUNT(*), @MinId = MIN(rowid) FROM #tmpTbl 
--				print(@MinId)
--				print(@TotalRecord)

--				WHILE @MinId <= @TotalRecord   
--				BEGIN
--				print '22'
--					SELECT @ManualJournalDetailsId = ManualJournalDetailsId FROM #tmpTbl WHERE rowId = @MinId

--					print 'print @ManualJournalHeaderId'
--					print @NewManualJournalHeaderId
--					print @ManualJournalDetailsId
					


--					INSERT INTO [dbo].[ManualJournalDetails] 
--						(ManualJournalHeaderId,GlAccountId,Debit,Credit,Description,ManagementStructureId,LastMSLevel,AllMSlevels,MasterCompanyId,
--						CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted)
--					SELECT @NewManualJournalHeaderId,GlAccountId,Debit,Credit,Description,ManagementStructureId,LastMSLevel,AllMSlevels,MasterCompanyId,
--						CreatedBy,UpdatedBy,GETUTCDATE(),UpdatedDate,IsActive,IsDeleted 
--					FROM dbo.ManualJournalDetails WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND ManualJournalDetailsId = @ManualJournalDetailsId

--					SET @NewManualJournalDetailsId = SCOPE_IDENTITY();

--					INSERT INTO [dbo].[ManualJournalApproval](ManualJournalHeaderId,ManualJournalDetailsId,Memo,SentDate,ApprovedDate,ApprovedById,ApprovedByName,RejectedDate,RejectedBy,RejectedByName,
--					StatusId,StatusName,ActionId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,InternalSentToId,InternalSentToName,InternalSentById)
--					SELECT 
--						@NewManualJournalHeaderId,@NewManualJournalDetailsId,Memo,SentDate,ApprovedDate,ApprovedById,ApprovedByName,RejectedDate,RejectedBy,RejectedByName
--						,StatusId,StatusName,ActionId,MasterCompanyId,CreatedBy,UpdatedBy,GETUTCDATE(),GETUTCDATE(),IsActive,IsDeleted,InternalSentToId,InternalSentToName,InternalSentById
--						FROM dbo.[ManualJournalApproval] WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND ManualJournalDetailsId = @ManualJournalDetailsId

--					SET @MinId = @MinId + 1;
--				END


--				INSERT INTO [dbo].[AccountingManagementStructureDetails](
--					ModuleID,ReferenceID,EntityMSID,Level1Id,Level1Name,Level2Id
--					,Level2Name
--					,Level3Id
--					,Level3Name
--					,Level4Id
--					,Level4Name
--					,Level5Id
--					,Level5Name
--					,Level6Id
--					,Level6Name
--					,Level7Id
--					,Level7Name
--					,Level8Id
--					,Level8Name
--					,Level9Id
--					,Level9Name
--					,Level10Id
--					,Level10Name
--					,MasterCompanyId
--					,CreatedBy
--					,UpdatedBy
--					,CreatedDate
--					,UpdatedDate
--				)
--				SELECT ModuleID,@NewManualJournalHeaderId,EntityMSID,Level1Id,Level1Name,Level2Id
--					,Level2Name
--					,Level3Id
--					,Level3Name
--					,Level4Id
--					,Level4Name
--					,Level5Id
--					,Level5Name
--					,Level6Id
--					,Level6Name
--					,Level7Id
--					,Level7Name
--					,Level8Id
--					,Level8Name
--					,Level9Id
--					,Level9Name
--					,Level10Id
--					,Level10Name
--					,MasterCompanyId
--					,CreatedBy
--					,UpdatedBy
--					,CreatedDate
--					,UpdatedDate
--					FROM AccountingManagementStructureDetails WHERE ModuleID=64 AND ReferenceID=@ManualJournalHeaderId


--				IF(ISNULL(@AccountStatus,0) = 1)
--				BEGIN
--					UPDATE ManualJournalHeader SET ManualJournalStatusId=(select ManualJournalStatusId from dbo.ManualJournalStatus with(NOLOCK) where Name = 'Posted')
--					WHERE ManualJournalHeaderId=@NewManualJournalHeaderId
--				END
				
--				 UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
--			 END
--		  END
--		 -- IF(@IsRecuring = 2)
--		 -- BEGIN
--			--SELECT @ReversingDate = ReversingDate,@ReversingStatusId = ISNULL(ReversingStatusId,0) FROM DBO.ManualJournalHeader WHERE ManualJournalHeaderId = @ManualJournalHeaderId

--			--select DISTINCT @AccountingCalendarId=AC.AccountingCalendarId, @AccountStatus = ISNULL(AC.isaccStatusName,0)
--			--	from dbo.EntityStructureSetup ESS WITH(NOLOCK)
--			--  inner join dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
--			--  inner join dbo.AccountingCalendar AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
--			--  where AC.LegalEntityId = @LegalEntityId
--			--  AND (CAST(@ReversingDate as date) BETWEEN AC.FromDate AND AC.ToDate)
--			--  AND AC.IsDeleted = 0 AND AC.FiscalYear=YEAR(@ReversingDate) order by AC.AccountingCalendarId;

--			-- select DISTINCT @NextAccountingCalendarId=AC.AccountingCalendarId,@FromDate = FromDate,@ToDate = ToDate
--			--	from dbo.EntityStructureSetup ESS WITH(NOLOCK)
--			--  inner join dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
--			--  inner join dbo.AccountingCalendar AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
--			--  where AC.LegalEntityId = @LegalEntityId
--			--  AND (CAST(DATEADD(MONTH, 1, @ReversingDate) as date) BETWEEN AC.FromDate AND AC.ToDate)
--			--  AND AC.IsDeleted = 0 AND AC.FiscalYear=YEAR(DATEADD(MONTH, 1, @ReversingDate)) order by AC.AccountingCalendarId;

--			--IF(@ReversingDate <= CURRENT_TIMESTAMP AND @ReversingStatusId = 1 AND @FromDate IS NOT NULL)
--			--BEGIN
--			--	INSERT INTO [dbo].[ManualJournalHeader](
--			--		LedgerId,JournalNumber,JournalDescription,ManualJournalTypeId,ManualJournalBalanceTypeId,EntryDate,EffectiveDate,AccountingPeriodId,ManualJournalStatusId,IsRecuring,ReversingDate,ReversingaccountingPeriodId
--			--		,ReversingStatusId,FunctionalCurrencyId,ReportingCurrencyId,ConversionCurrencyDate,ConvertionTypeId,ConversionRate,ManagementStructureId,EmployeeId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate
--			--		,IsActive,IsDeleted,IsEnforce,EnforceEffectiveDate
--			--	)
--			--	SELECT LedgerId,@JournalNumber,JournalDescription,ManualJournalTypeId,ManualJournalBalanceTypeId,GETUTCDATE(),@ReversingDate,@AccountingCalendarId,@StatusId,IsRecuring,@FromDate,@NextAccountingCalendarId
--			--			,ReversingStatusId,FunctionalCurrencyId,ReportingCurrencyId,ConversionCurrencyDate,ConvertionTypeId,ConversionRate,ManagementStructureId,EmployeeId,MasterCompanyId,CreatedBy,UpdatedBy,GETUTCDATE(),GETUTCDATE()
--			--			,1,0,IsEnforce,EnforceEffectiveDate
--			--			FROM ManualJournalHeader WHERE ManualJournalHeaderId=@ManualJournalHeaderId

--			--	SELECT @NewManualJournalHeaderId = SCOPE_IDENTITY(); 

--			--	---- NEXT REVERSING DAE-----

--			--	INSERT INTO #tmpTbl(ManualJournalHeaderId,ManualJournalDetailsId)
--			--	SELECT ManualJournalHeaderId,ManualJournalDetailsId 
--			--	FROM dbo.ManualJournalDetails WHERE ManualJournalHeaderId = @ManualJournalHeaderId
				
--			--	SELECT @TotalRecord = COUNT(*), @MinId = MIN(rowid) FROM #tmpTbl 
				
--			--	WHILE @MinId <= @TotalRecord   
--			--	BEGIN
--			--		SELECT @ManualJournalDetailsId = ManualJournalDetailsId FROM #tmpTbl WHERE rowId = @MinId
--			--		INSERT INTO [dbo].[ManualJournalDetails] 
--			--			(ManualJournalHeaderId,GlAccountId,Debit,Credit,Description,ManagementStructureId,LastMSLevel,AllMSlevels,MasterCompanyId,
--			--			CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted)
--			--		SELECT @NewManualJournalHeaderId,GlAccountId,Credit,Debit,Description,ManagementStructureId,LastMSLevel,AllMSlevels,MasterCompanyId,
--			--			CreatedBy,UpdatedBy,GETUTCDATE(),UpdatedDate,IsActive,IsDeleted 
--			--		FROM dbo.ManualJournalDetails WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND ManualJournalDetailsId = @ManualJournalDetailsId

--			--		SET @NewManualJournalDetailsId = SCOPE_IDENTITY();

--			--		INSERT INTO [dbo].[ManualJournalApproval](ManualJournalHeaderId,ManualJournalDetailsId,Memo,SentDate,ApprovedDate,ApprovedById,ApprovedByName,RejectedDate,RejectedBy,RejectedByName,
--			--		StatusId,StatusName,ActionId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,InternalSentToId,InternalSentToName,InternalSentById)
--			--		SELECT 
--			--			@NewManualJournalHeaderId,@NewManualJournalDetailsId,Memo,SentDate,ApprovedDate,ApprovedById,ApprovedByName,RejectedDate,RejectedBy,RejectedByName
--			--			,StatusId,StatusName,ActionId,MasterCompanyId,CreatedBy,UpdatedBy,GETUTCDATE(),GETUTCDATE(),IsActive,IsDeleted,InternalSentToId,InternalSentToName,InternalSentById
--			--			FROM dbo.[ManualJournalApproval] WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND ManualJournalDetailsId = @ManualJournalDetailsId

--			--		SET @MinId = @MinId + 1;
--			--	END

--			--	UPDATE ManualJournalHeader SET ReversingStatusId=2 WHERE ManualJournalHeaderId=@ManualJournalHeaderId
--			--	UPDATE ManualJournalHeader SET ReversingStatusId=2 WHERE ManualJournalHeaderId=@NewManualJournalHeaderId
--			--	--SET  @NewManualJournalHeaderId = @@IDENTITY;

--			--	INSERT INTO [dbo].[AccountingManagementStructureDetails](
--			--			ModuleID,ReferenceID,EntityMSID,Level1Id,Level1Name,Level2Id
--			--			,Level2Name
--			--			,Level3Id
--			--			,Level3Name
--			--			,Level4Id
--			--			,Level4Name
--			--			,Level5Id
--			--			,Level5Name
--			--			,Level6Id
--			--			,Level6Name
--			--			,Level7Id
--			--			,Level7Name
--			--			,Level8Id
--			--			,Level8Name
--			--			,Level9Id
--			--			,Level9Name
--			--			,Level10Id
--			--			,Level10Name
--			--			,MasterCompanyId
--			--			,CreatedBy
--			--			,UpdatedBy
--			--			,CreatedDate
--			--			,UpdatedDate
--			--	)
--			--	SELECT ModuleID,@NewManualJournalHeaderId,EntityMSID,Level1Id,Level1Name,Level2Id
--			--			,Level2Name
--			--			,Level3Id
--			--			,Level3Name
--			--			,Level4Id
--			--			,Level4Name
--			--			,Level5Id
--			--			,Level5Name
--			--			,Level6Id
--			--			,Level6Name
--			--			,Level7Id
--			--			,Level7Name
--			--			,Level8Id
--			--			,Level8Name
--			--			,Level9Id
--			--			,Level9Name
--			--			,Level10Id
--			--			,Level10Name
--			--			,MasterCompanyId
--			--			,CreatedBy
--			--			,UpdatedBy
--			--			,CreatedDate
--			--			,UpdatedDate
--			--			FROM AccountingManagementStructureDetails WHERE ModuleID=64 AND ReferenceID=@ManualJournalHeaderId

--			--	IF(@AccountStatus = 1)
--			--	BEGIN
--			--		UPDATE ManualJournalHeader SET ManualJournalStatusId=(select ManualJournalStatusId from dbo.ManualJournalStatus with(NOLOCK) where Name = 'Posted'),ReversingStatusId=2
--			--		WHERE ManualJournalHeaderId=@NewManualJournalHeaderId
--			--	END
				

--			--	UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId

--			--END

			 
--		 -- END

	
--	      FETCH NEXT FROM db_cursor INTO @ManualJournalHeaderId,@IsRecuring,@LegalEntityId,@MasterCompanyId
--	END
--	CLOSE db_cursor
--	DEALLOCATE db_cursor
	
	END TRY    
	BEGIN CATCH   
		ROLLBACK TRAN;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_ManualJournalBackgroundProcess' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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