
/*************************************************************             
 ** File:   [USP_ManualJournalRecurringEntry]             
 ** Author:   
 ** Description: This stored procedure is used to create manual JE while Post Recurring Entry
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    09/04/2023   Moin Bloch    Created
	2    09/06/2023   Moin Bloch    Added Posted date for Accounting Batch

	EXEC [dbo].[USP_ManualJournalRecurringEntry] 102,1

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_ManualJournalRecurringEntry]
@ManualJournalHeaderId BIGINT,
@MasterCompanyId INT
AS  
BEGIN   
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON; 

	IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
	BEGIN
		DROP TABLE #tmpCodePrefixes
	END
	IF OBJECT_ID(N'tempdb..#tmpTbl') IS NOT NULL        
	BEGIN        
		DROP TABLE #tmpTbl        
	END 
	
	BEGIN TRY  
		BEGIN TRANSACTION  
        BEGIN

		DECLARE @CodeTypeId AS BIGINT = 0;  
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalNumber varchar(100);
		DECLARE @OldJournalNumber varchar(100);
		DECLARE @IsRecuring int;
		DECLARE @ReversingDate DATETIME;
		DECLARE @ReversingStatusId INT;		  
   	    DECLARE @AccountingCalendarId BIGINT;
		DECLARE @AccountStatus BIT;
		DECLARE @LegalEntityId BIGINT;
		DECLARE @NewManualJournalHeaderId BIGINT;
		DECLARE @NewManualJournalDetailsId BIGINT;		  
		DECLARE @FromDate DATETIME;
		DECLARE @ToDate DATETIME;		  
		DECLARE @NextAccountingCalendarId BIGINT;
		DECLARE @MinId BIGINT = 1;      
		DECLARE @TotalRecord int = 0; 
		DECLARE @ManualJournalDetailsId BIGINT;
		DECLARE @StatusId INT;
		DECLARE @ManualJournalMSModuleId INT;
		DECLARE @EffectiveDate DATETIME;
		DECLARE @IsRecursiveDone BIT;
		DECLARE @RecurringNumberOfPeriod INT;
		DECLARE @ManagementStructureId BIGINT;
		DECLARE @MSModuleId INT = 0		
		DECLARE @UpdatedBy varchar(100);

		SELECT @CodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'ManualJournalType';		
		SELECT @StatusId = [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WITH(NOLOCK) WHERE [Name] = 'Approved';
		SELECT @ManualJournalMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ManualJournal';
		SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';

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
		 
		  
		 INSERT INTO #tmpCodePrefixes ([CodePrefixId],[CodeTypeId],[CurrentNumber], [CodePrefix], [CodeSufix], [StartsFrom]) 
		 SELECT [CodePrefixId], CP.[CodeTypeId], [CurrentNummber], [CodePrefix], [CodeSufix], [StartsFrom] 
		 FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN [dbo].[CodeTypes] CT ON CP.CodeTypeId = CT.CodeTypeId
		 WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;
		  
		  IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
		  BEGIN 
		  	SELECT @currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
		  	  FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId
		  
		  	SET @JournalNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT [CodePrefix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId), (SELECT [CodeSufix] FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId)))
		  END
		  ELSE 
		  BEGIN
		  	ROLLBACK TRAN;
		  END

		  DECLARE @Counter INT 
		  SET @Counter = 1

		  SELECT @ReversingDate = [ReversingDate], 
		         @ReversingStatusId = ISNULL([ReversingStatusId],0), 
				 @LegalEntityId = [LedgerId],
				 @OldJournalNumber = [JournalNumber],
				 @IsRecuring = [IsRecuring],
				 @EffectiveDate = [EffectiveDate],
				 @IsRecursiveDone = ISNULL([IsRecursiveDone],0),
				 @RecurringNumberOfPeriod = [RecurringNumberOfPeriod],
				 @UpdatedBy = [UpdatedBy]
		    FROM [dbo].[ManualJournalHeader] WITH(NOLOCK) 
		   WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;

		   IF(@IsRecuring = 1 AND @IsRecursiveDone <> 1 AND @RecurringNumberOfPeriod > 0)
		   BEGIN
				WHILE (@Counter <= @RecurringNumberOfPeriod)
				BEGIN					
					IF(@Counter > 1)
					BEGIN
						SELECT @currentNo = CASE WHEN CP.[CurrentNummber] > 0 THEN CAST(CP.[CurrentNummber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
		  				FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN [dbo].[CodeTypes] CT ON CP.CodeTypeId = CT.CodeTypeId
						WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0;
		  		  		  				
						SET @JournalNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,
						(SELECT CP.[CodePrefix] FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN [dbo].[CodeTypes] CT ON CP.CodeTypeId = CT.CodeTypeId
						 WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0),
						(SELECT CP.[CodeSufix] FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN [dbo].[CodeTypes] CT ON CP.CodeTypeId = CT.CodeTypeId
						 WHERE CT.[CodeTypeId] IN (@CodeTypeId) AND CP.[MasterCompanyId] = @MasterCompanyId AND CP.[IsActive] = 1 AND CP.[IsDeleted] = 0)))	
					END

					SELECT DISTINCT @NextAccountingCalendarId = AC.[AccountingCalendarId],
				                    @AccountStatus = ISNULL(AC.[isaccStatusName],0),
								    @FromDate = [FromDate],
								    @ToDate = [ToDate]
				               FROM [dbo].[EntityStructureSetup] ESS WITH(NOLOCK)
					     INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON ESS.[Level1Id] = MSL.[ID]
					     INNER JOIN [dbo].[AccountingCalendar] AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
			               WHERE AC.[LegalEntityId] = @LegalEntityId AND [IsAdjustPeriod] = 0
					       AND (CAST(DATEADD(MONTH, @Counter, @EffectiveDate) AS DATE) BETWEEN AC.[FromDate] AND AC.[ToDate])
					       AND AC.[IsDeleted] = 0 AND AC.[FiscalYear] = YEAR(DATEADD(MONTH, @Counter, @EffectiveDate)) ORDER BY AC.AccountingCalendarId;

					INSERT INTO [dbo].[ManualJournalHeader]
			                   ([LedgerId],
						        [JournalNumber],
						        [JournalDescription],
						        [ManualJournalTypeId],
						        [ManualJournalBalanceTypeId],
						        [EntryDate],
						        [EffectiveDate],
						        [AccountingPeriodId],
						        [ManualJournalStatusId],
						        [IsRecuring],
						        [ReversingDate],
						        [ReversingaccountingPeriodId],
						        [ReversingStatusId],
						        [FunctionalCurrencyId],
						        [ReportingCurrencyId],
						        [ConversionCurrencyDate],
						        [ConvertionTypeId],
						        [ConversionRate],
						        [ManagementStructureId],
						        [EmployeeId],
						        [MasterCompanyId],
						        [CreatedBy],
						        [UpdatedBy],
						        [CreatedDate],
						        [UpdatedDate],
						        [IsActive],
						        [IsDeleted],
						        [IsEnforce],
						        [EnforceEffectiveDate],
						        [IsRecursiveDone])
				         SELECT [LedgerId],
				                @JournalNumber,
						        JournalDescription,
						        ManualJournalTypeId,
						        ManualJournalBalanceTypeId,
						        GETUTCDATE(),
						        @FromDate,
						        @NextAccountingCalendarId,
						        @StatusId,
						        [IsRecuring],
						        [ReversingDate],
						        [ReversingaccountingPeriodId],
						        [ReversingStatusId],
						        [FunctionalCurrencyId],
						        [ReportingCurrencyId],
						        [ConversionCurrencyDate],
						        [ConvertionTypeId],
						        [ConversionRate],
						        [ManagementStructureId],
						        [EmployeeId],
						        [MasterCompanyId],
						        [CreatedBy],
						        [UpdatedBy],
						        GETUTCDATE(),
						        GETUTCDATE(),
						        1,
						        0,
						        [IsEnforce],
						        [EnforceEffectiveDate],
						        0
				           FROM [dbo].[ManualJournalHeader] WITH(NOLOCK) WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
					 			
					SELECT @NewManualJournalHeaderId = SCOPE_IDENTITY(); 

					UPDATE [dbo].[ManualJournalHeader] SET [IsRecursiveDone] = 1, [ReverseJournalNumber] = @JournalNumber, [PostedDate] = GETUTCDATE() WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
					
					UPDATE [dbo].[ManualJournalHeader] SET [ReversingStatusId] = 1, [IsRecuring] = 3  WHERE [ManualJournalHeaderId] = @NewManualJournalHeaderId;

					CREATE TABLE #tmpTbl
					(        
						[rowId] [bigint] IDENTITY,    
						[ManualJournalHeaderId] BIGINT,
						[ManualJournalDetailsId] BIGINT,
						[ManagementStructureId]  BIGINT,
					) 

					INSERT INTO #tmpTbl([ManualJournalHeaderId],[ManualJournalDetailsId],[ManagementStructureId])
					SELECT [ManualJournalHeaderId],[ManualJournalDetailsId],[ManagementStructureId]
					FROM [dbo].[ManualJournalDetails] WITH(NOLOCK) WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
				
					SELECT @TotalRecord = COUNT(*), @MinId = MIN([rowid]) FROM #tmpTbl 

					WHILE @MinId <= @TotalRecord   
					BEGIN				
						SELECT @ManualJournalDetailsId = [ManualJournalDetailsId],@ManagementStructureId = [ManagementStructureId] FROM #tmpTbl WHERE [rowId] = @MinId;

						INSERT INTO [dbo].[ManualJournalDetails] 
								   ([ManualJournalHeaderId],
									[GlAccountId],
									[Debit],
									[Credit],
									[Description],
									[ManagementStructureId],
									[LastMSLevel],
									[AllMSlevels],
									[MasterCompanyId],
									[CreatedBy],
									[UpdatedBy],
									[CreatedDate],
									[UpdatedDate],
									[IsActive],
									[IsDeleted])
							 SELECT @NewManualJournalHeaderId,
									[GlAccountId],
									[Debit],
									[Credit],
									[Description],
									[ManagementStructureId],
									[LastMSLevel],
									[AllMSlevels],
									[MasterCompanyId],
									[CreatedBy],
									[UpdatedBy],
									GETUTCDATE(),
									GETUTCDATE(),
									[IsActive],
									[IsDeleted] 
							   FROM [dbo].[ManualJournalDetails] WITH(NOLOCK) 
							  WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId 
								AND [ManualJournalDetailsId] = @ManualJournalDetailsId

						SET @NewManualJournalDetailsId = SCOPE_IDENTITY();

						INSERT INTO [dbo].[ManualJournalApproval]
								   ([ManualJournalHeaderId],
									[ManualJournalDetailsId],
									[Memo],
									[SentDate],
									[ApprovedDate],
									[ApprovedById],
									[ApprovedByName],
									[RejectedDate],
									[RejectedBy],
									[RejectedByName],
									[StatusId],
									[StatusName],
									[ActionId],
									[MasterCompanyId],
									[CreatedBy],
									[UpdatedBy],
									[CreatedDate],
									[UpdatedDate],
									[IsActive],
									[IsDeleted],
									[InternalSentToId],
									[InternalSentToName],
									[InternalSentById])
							 SELECT @NewManualJournalHeaderId,
									@NewManualJournalDetailsId,
									[Memo],
									[SentDate],
									[ApprovedDate],
									[ApprovedById],
									[ApprovedByName],
									[RejectedDate],
									[RejectedBy],
									[RejectedByName],
									[StatusId],
									[StatusName],
									[ActionId],
									[MasterCompanyId],
									[CreatedBy],
									[UpdatedBy],
									GETUTCDATE(),
									GETUTCDATE(),
									[IsActive],
									[IsDeleted],
									[InternalSentToId],
									[InternalSentToName],
									[InternalSentById]
							  FROM [dbo].[ManualJournalApproval] WITH(NOLOCK) 
							 WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId 
							   AND [ManualJournalDetailsId] = @ManualJournalDetailsId

						EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @NewManualJournalDetailsId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy,@MSModuleId,1; 

						SET @MinId = @MinId + 1;
					END

					INSERT INTO [dbo].[AccountingManagementStructureDetails]
					   ([ModuleID]
					   ,[ReferenceID]
					   ,[EntityMSID]
					   ,[Level1Id]
					   ,[Level1Name]
					   ,[Level2Id]
					   ,[Level2Name]
					   ,[Level3Id]
					   ,[Level3Name]
					   ,[Level4Id]
					   ,[Level4Name]
					   ,[Level5Id]
					   ,[Level5Name]
					   ,[Level6Id]
					   ,[Level6Name]
					   ,[Level7Id]
					   ,[Level7Name]
					   ,[Level8Id]
					   ,[Level8Name]
					   ,[Level9Id]
					   ,[Level9Name]
					   ,[Level10Id]
					   ,[Level10Name]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[LastMSLevel]
					   ,[AllMSlevels])
				 SELECT [ModuleID]
				       ,@NewManualJournalHeaderId
					   ,[EntityMSID]
					   ,[Level1Id]
					   ,[Level1Name]
					   ,[Level2Id]
					   ,[Level2Name]
					   ,[Level3Id]
					   ,[Level3Name]
					   ,[Level4Id]
					   ,[Level4Name]
					   ,[Level5Id]
					   ,[Level5Name]
					   ,[Level6Id]
					   ,[Level6Name]
					   ,[Level7Id]
					   ,[Level7Name]
					   ,[Level8Id]
					   ,[Level8Name]
					   ,[Level9Id]
					   ,[Level9Name]
					   ,[Level10Id]
					   ,[Level10Name]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[LastMSLevel]
					   ,[AllMSlevels]
				   FROM [dbo].[AccountingManagementStructureDetails]
				  WHERE [ModuleID] = @ManualJournalMSModuleId 
				    AND [ReferenceID] = @ManualJournalHeaderId;
					
					--IF(ISNULL(@AccountStatus,0) = 1)
					--BEGIN
					--	UPDATE [dbo].[ManualJournalHeader] 
					--	   SET [ManualJournalStatusId] = (SELECT [ManualJournalStatusId] FROM [dbo].[ManualJournalStatus] WITH(NOLOCK) WHERE [Name] = 'Posted')
					--	 WHERE [ManualJournalHeaderId] = @NewManualJournalHeaderId;
					--END
			
					UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId			
				
					IF OBJECT_ID(N'tempdb..#tmpTbl') IS NOT NULL        
					BEGIN        
						DROP TABLE #tmpTbl        
					END 

					SET @Counter  = @Counter  + 1;

                END
			END  
		END
		COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_ManualJournalReversingEntry'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManualJournalHeaderId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END