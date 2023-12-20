/*************************************************************             
** File:   [CreateUpdateManualJournalHeader]             
** Author:   Deep Patel  
** Description: Create Update Manual Journal Entry  
** Purpose:           
** Date:   27/12/2022           
**************************************************************             
** Change History             
**************************************************************             
** PR   Date         Author  Change Description              
** --   --------     -------  --------------------------------            
1    27/12/2022   Deep Patel    Created  
2    05/06/2023   Satish Gohil  Modify (Entry Date Saved As a UTCDATE)    
3    13/07/2023   Satish Gohil  Modify (Set Approval Status Based on Status)
4    05/09/2023   MOIN BLOCH    Modify (Added RecurringNumberOfPeriod For Recurring)
5    06/09/2023   Moin Bloch    Added Posted date for Accounting Batch
5    07/09/2023   Moin Bloch    Modify (Added Update Journal Status Open when update Header info)

-- exec CreateUpdateManualJournalHeader 92,1      
**************************************************************/   
CREATE   PROCEDURE [dbo].[CreateUpdateManualJournalHeader]  
@ManualJournalHeaderId bigint = NULL,  
@LedgerId bigint = NULL,  
@JournalNumber varchar(100) = NULL,  
@JournalDescription varchar(MAX) = NULL,  
@ManualJournalTypeId int = NULL,  
@ManualJournalBalanceTypeId int = NULL,  
@EntryDate datetime,  
@EffectiveDate datetime,  
@AccountingPeriodId bigint = NULL,  
@ManualJournalStatusId int = NULL,  
@IsRecuring int,  
@ReversingDate datetime,  
@ReversingaccountingPeriodId bigint = NULL,  
@ReversingStatusId int = NULL,  
@FunctionalCurrencyId bigint = NULL,  
@ReportingCurrencyId bigint = NULL,  
@ConversionCurrencyDate datetime = NULL,  
@ConvertionTypeId bigint = NULL,  
@ConversionRate decimal(18,2) = NULL,  
@ManagementStructureId bigint = NULL,  
@EmployeeId bigint = NULL,  
@MasterCompanyId int,  
@CreatedBy varchar(100),  
@UpdatedBy varchar(100)= NULL,  
@RecurringNumberOfPeriod int = NULL,  
@Result bigint =1 OUTPUT  
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;   
	BEGIN TRY  
		BEGIN TRANSACTION  
		BEGIN  
  
			DECLARE @RC int  
			DECLARE @Opr int  
			DECLARE @MSDetailsId bigint;  
			DECLARE @MSAccountingModuleId bigint=64;  
			DECLARE @CodeTypeId AS BIGINT = 75;  
			DECLARE @currentNo AS BIGINT = 0;  
			DECLARE @OldManualJournalStatusId BIGINT;
			DECLARE @StatusId INT;
			DECLARE @PostStatusId INT;
			DECLARE @ApprovalStatusId INT;
			DECLARE @OpenStatusId INT;			
			DECLARE @ActionId INT;

			SELECT @StatusId = ManualJournalStatusId FROM [dbo].ManualJournalStatus WHERE [Name] = 'Approved';
			SELECT @PostStatusId = ManualJournalStatusId FROM [dbo].ManualJournalStatus WHERE [Name] = 'Posted';
			SELECT @OpenStatusId = ManualJournalStatusId FROM [dbo].ManualJournalStatus WHERE [Name] = 'Pending';

			IF (@ManualJournalHeaderId IS NULL OR @ManualJournalHeaderId=0)  
			BEGIN  
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
         
					SET @JournalNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))  
				END  
				ELSE   
				BEGIN  
					ROLLBACK TRAN;  
				END  
  
  
				INSERT INTO [dbo].[ManualJournalHeader] 
				           ([LedgerId]  
				           ,[JournalNumber]  
				           ,[JournalDescription]  
				           ,[ManualJournalTypeId] 
				           ,[ManualJournalBalanceTypeId]  
				           ,[EntryDate]  
				           ,[EffectiveDate]  
				           ,[AccountingPeriodId]  
				           ,[ManualJournalStatusId]  
				           ,[IsRecuring]  
				           ,[ReversingDate]  
				           ,[ReversingaccountingPeriodId]  
				           ,[ReversingStatusId]  
				           ,[FunctionalCurrencyId]  
				           ,[ReportingCurrencyId]  
				           ,[ConversionCurrencyDate]  
				           ,[ConvertionTypeId]  
				           ,[ConversionRate]  
				           ,[ManagementStructureId]  
				           ,[EmployeeId]  
				           ,[MasterCompanyId]  
				           ,[CreatedBy]  
				           ,[UpdatedBy]  
				           ,[CreatedDate]  
				           ,[UpdatedDate]  
				           ,[IsActive]  
				           ,[IsDeleted]  
				           ,[RecurringNumberOfPeriod])  
				     VALUES
					       (@LedgerId  
				           ,@JournalNumber  
				           ,@JournalDescription  
				           ,@ManualJournalTypeId  
				           ,@ManualJournalBalanceTypeId  
				           ,GETUTCDATE()  
				           ,@EffectiveDate  
				           ,@AccountingPeriodId  
				           ,@ManualJournalStatusId  
				           ,@IsRecuring  
				           ,@ReversingDate  
				           ,@ReversingaccountingPeriodId  
				           ,@ReversingStatusId  
				           ,@FunctionalCurrencyId  
				           ,@ReportingCurrencyId  
				           ,@ConversionCurrencyDate  
				           ,@ConvertionTypeId  
				           ,@ConversionRate  
				           ,@ManagementStructureId  
				           ,@EmployeeId  
				           ,@MasterCompanyId  
				           ,@CreatedBy  
				           ,@UpdatedBy  
				           ,GETUTCDATE()  
				           ,GETUTCDATE()  
				           ,1  
				           ,0  
				           ,@RecurringNumberOfPeriod);  
  
				SELECT @Result = IDENT_CURRENT('ManualJournalHeader');  
				UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId  
				SELECT @Result AS ManualJournalHeaderId  
				--EXEC [DBO].[UpdateDistributionCodeEntryDetails] @Result;  
				EXEC [DBO].[PROCAddUpdateAccountingMSData] @Result,@ManagementStructureId,@MasterCompanyId,@updatedBy,@updatedBy,@MSAccountingModuleId,1;  
      
			END  
			ELSE  
			BEGIN  
				
				SELECT @OldManualJournalStatusId = ManualJournalStatusId FROM [ManualJournalHeader] WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId  
					
				UPDATE [dbo].[ManualJournalHeader]  
				   SET [LedgerId] = @LedgerId  
				      ,[JournalDescription] = @JournalDescription  
				      ,[ManualJournalTypeId] = @ManualJournalTypeId  
				      ,[ManualJournalBalanceTypeId] = @ManualJournalBalanceTypeId  
				      ,[EffectiveDate] = @EffectiveDate  
				      ,[AccountingPeriodId] = @AccountingPeriodId  
				      ,[ManualJournalStatusId] = @ManualJournalStatusId  
				      ,[IsRecuring] = @IsRecuring  
				      ,[ReversingDate] = @ReversingDate  
				      ,[ReversingaccountingPeriodId] = @ReversingaccountingPeriodId  
				      ,[ReversingStatusId] = @ReversingStatusId  
				      ,[FunctionalCurrencyId] = @FunctionalCurrencyId  
				      ,[ReportingCurrencyId] =@ReportingCurrencyId  
				      ,[ConversionCurrencyDate] =@ConversionCurrencyDate  
				      ,[ConvertionTypeId] =@ConvertionTypeId  
				      ,[ConversionRate] =@ConversionRate  
				      ,[ManagementStructureId] =@ManagementStructureId  
				      ,[EmployeeId] =@EmployeeId  
				      ,[UpdatedBy] =@updatedBy  
				      ,[UpdatedDate] = GETUTCDATE()  
				      ,[RecurringNumberOfPeriod] = @RecurringNumberOfPeriod				      
				 WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;  
  
				SELECT @ManualJournalHeaderId AS DistributionId  
				SET @Result= @ManualJournalHeaderId  
				--EXEC [DBO].[UpdateDistributionCodeEntryDetails] @DistributionId;  
				EXEC [DBO].[PROCAddUpdateAccountingMSData] @ManualJournalHeaderId,@ManagementStructureId,@MasterCompanyId,@updatedBy,@updatedBy,@MSAccountingModuleId,2;  
  
				IF(@OldManualJournalStatusId = @StatusId AND @ManualJournalStatusId <> @PostStatusId)
				BEGIN
					SELECT @ActionId = [ApprovalProcessId] FROM ApprovalProcess WITH(NOLOCK) WHERE [Name] = 'SentForInternalApproval';
					SELECT @StatusId = [ApprovalStatusId] FROM ApprovalStatus WITH(NOLOCK) WHERE [Name] = 'Pending';

					UPDATE [dbo].[ManualJournalHeader] SET [ManualJournalStatusId] = @OpenStatusId WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
										
					UPDATE [dbo].[ManualJournalApproval]
					   SET [ActionId] = @ActionId,
						   [StatusId] = @StatusId,
						   [UpdatedBy] = @UpdatedBy,
						   [UpdatedDate] = GETUTCDATE(),
						   [ApprovedById] = 0,
						   [RejectedBy] = null,
						   [ApprovedByName] = null,
						   [ApprovedDate] = null,
						   [RejectedByName] = null,
						   [RejectedDate] = null,
						   [InternalSentById] = null,
						   [InternalSentToId] = null,
						   [InternalSentToName] = null
				     WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
				END

				IF(@ManualJournalStatusId = @PostStatusId)
				BEGIN
					UPDATE [dbo].[ManualJournalHeader] SET [PostedDate] = GETUTCDATE() WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
				END

			END  
		END  
		COMMIT  TRANSACTION  
	END TRY   
	BEGIN CATCH        
	IF @@trancount > 0  
	PRINT 'ROLLBACK'  
	ROLLBACK TRANSACTION;  
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
	, @AdhocComments     VARCHAR(150)    = 'CreateUpdateManualJournalHeader'   
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ManualJournalHeaderId, '') AS varchar(100))  
	, @ApplicationName VARCHAR(100) = 'PAS'  
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
	exec spLogException   
	@DatabaseName           = @DatabaseName  
	, @AdhocComments          = @AdhocComments  
	, @ProcedureParameters    = @ProcedureParameters  
	, @ApplicationName        =  @ApplicationName  
	, @ErrorLogID                    = @ErrorLogID OUTPUT ;  
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
	RETURN(1);  
	END CATCH  
END