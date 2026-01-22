/*************************************************************             
 ** File:   [usp_SaveCommonJournalBatchDetails]             
 ** Author: 
 ** Description: This stored procedure is used to update batch details  
 ** Purpose:           
 ** Date:   08/10/2022        
            
 ** PARAMETERS: 
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------		--------------------------------            
 1    08/10/2022             		 Created   
 2    10/05/2023  Moin Bloch		 added IsUpdated 

 EXEC usp_SaveCommonJournalBatchDetails 
************************************************************************/  
CREATE PROCEDURE [dbo].[usp_SaveCommonJournalBatchDetails]
@tbl_CommonJournalBatchDetails CommonJournalBatchDetailsType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
				
				DECLARE @ID BIGINT = 0, @DistributionName VARCHAR(250),@ManualName VARCHAR(100) ='Manual';

				SELECT @ID = [ID], @DistributionName = [Name] FROM DBO.DistributionSetup WITH(NOLOCK) WHERE UPPER([Name]) = UPPER(@ManualName) AND UPPER([DistributionSetupCode]) = UPPER(@ManualName);

				--  JournalBatchDetails LIST
					IF((SELECT COUNT(CommonJournalBatchDetailId) FROM @tbl_CommonJournalBatchDetails) > 0 )
					BEGIN
						MERGE dbo.CommonBatchDetails AS TARGET
						USING @tbl_CommonJournalBatchDetails AS SOURCE ON (TARGET.JournalBatchHeaderId = SOURCE.JournalBatchHeaderId AND TARGET.CommonJournalBatchDetailId = SOURCE.CommonJournalBatchDetailId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 							
								 TARGET.[GlAccountId] = SOURCE.[GlAccountId]
								,TARGET.[TransactionDate] = SOURCE.[TransactionDate]
								,TARGET.[EntryDate] =SOURCE.[EntryDate]
								,TARGET.[DebitAmount] =SOURCE.[DebitAmount]
								,TARGET.[CreditAmount] = SOURCE.[CreditAmount]
								,TARGET.[UpdatedBy] = SOURCE.[UpdatedBy]
								,TARGET.[UpdatedDate] = GETUTCDATE()
								,TARGET.[JournalTypeName] = SOURCE.[JournalTypeName]
								,TARGET.[ManagementStructureId] = SOURCE.[ManagementStructureId]
								,TARGET.[LastMSLevel] = SOURCE.[LastMSLevel]
								,TARGET.[AllMSlevels] = SOURCE.[AllMSlevels]
								,TARGET.[IsDebit] = SOURCE.[IsDebit]
								,TARGET.[IsUpdated] = SOURCE.[IsUpdated]
							
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (
										 [JournalBatchDetailId]
										,[JournalBatchHeaderId]
										,[LineNumber]
										,[GlAccountId]
										,[TransactionDate]
										,[EntryDate]
										,[IsDebit]
										,[DebitAmount]
										,[CreditAmount]
										,[JournalTypeId]
										,[JournalTypeName]
										,[MasterCompanyId]
										,[CreatedBy]
										,[UpdatedBy]
										,[CreatedDate]
										,[UpdatedDate]
										,[IsActive]
										,[IsDeleted]
										,[IsManualEntry]
										,[ManagementStructureId]
										,[LastMSLevel]
										,[AllMSlevels]
										,[DistributionSetupId]
										,[DistributionName]
										,[IsUpdated]
										)
							     VALUES (
										 SOURCE.[JournalBatchDetailId]
										,SOURCE.[JournalBatchHeaderId]
										,SOURCE.[LineNumber]
										,SOURCE.[GlAccountId]
										,SOURCE.[TransactionDate]
										,SOURCE.[EntryDate]
										,SOURCE.[IsDebit]
										,SOURCE.[DebitAmount]
										,SOURCE.[CreditAmount]
										,SOURCE.[JournalTypeId]
										,SOURCE.[JournalTypeName]
										,SOURCE.[MasterCompanyId]
										,SOURCE.[UpdatedBy]
										,SOURCE.[UpdatedBy]
										,GETUTCDATE()
										,GETUTCDATE()
										,1
										,SOURCE.[IsDeleted]
										,1
										,SOURCE.[ManagementStructureId]
										,SOURCE.[LastMSLevel]
										,SOURCE.[AllMSlevels]
										,@ID
										,@DistributionName
										,1
										);
					 END

			 DECLARE @commonBatchDetailsId BIGINT;
			 DECLARE @BDetailsId BIGINT;
			 DECLARE @manualentry BIT;
			 DECLARE @DAmount DECIMAL(18,2)=0;
			 DECLARE @CAmount DECIMAL(18,2)=0;
			 DECLARE @isdebit BIT;
			 SET @commonBatchDetailsId = (SELECT TOP 1 [CommonJournalBatchDetailId] FROM @tbl_CommonJournalBatchDetails)

			 SELECT @BDetailsId = [JournalBatchDetailId] FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE [CommonJournalBatchDetailId] = @commonBatchDetailsId;

			 SELECT @DAmount = ISNULL(SUM([DebitAmount]),0),@CAmount = ISNULL(SUM([CreditAmount]),0) FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) WHERE JournalBatchDetailId=@BDetailsId AND IsDeleted=0
			 
			 UPDATE [dbo].[BatchDetails] set DebitAmount=@DAmount,CreditAmount=@CAmount,IsDebit=@isdebit,UpdatedDate=GETUTCDATE() WHERE [JournalBatchDetailId] = @BDetailsId
			 		     
			 DECLARE @TotalDebit DECIMAL(18,2)=0
	         DECLARE @TotalCredit DECIMAL(18,2)=0
	         DECLARE @TotalBalance DECIMAL(18,2)=0
			 DECLARE @JournalBatchHeaderId BIGINT 
			 DECLARE @MasterCompanyId BIGINT 

			 SET @JournalBatchHeaderId = (SELECT TOP 1 [JournalBatchHeaderId] from @tbl_CommonJournalBatchDetails)

			 SELECT @TotalDebit = ISNULL(SUM([DebitAmount]),0),@TotalCredit = ISNULL(SUM([CreditAmount]),0),@MasterCompanyId=MasterCompanyId FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId AND IsDeleted=0 GROUP BY JournalBatchHeaderId,MasterCompanyId
			   	          
			 SET @TotalBalance = @TotalDebit-@TotalCredit
				          
			 UPDATE [dbo].[BatchHeader] SET [TotalDebit] = @TotalDebit,[TotalCredit]=@TotalCredit,[TotalBalance]=@TotalBalance,[UpdatedDate]=GETUTCDATE() WHERE [JournalBatchHeaderId]= @JournalBatchHeaderId

			 UPDATE JBD SET jbd.[GlAccountName] = gl.[AccountName],jbd.[GlAccountNumber]=gl.[AccountCode] FROM dbo.[CommonBatchDetails] JBD LEFT JOIN dbo.[GLAccount] GL on Gl.[GLAccountId]=JBD.[GLAccountId] 
			 
			 DECLARE @JournalBatchDetailId int;
			 DECLARE db_cursor CURSOR FOR 
			 SELECT JournalBatchDetailId FROM [dbo].[BatchDetails] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [JournalTypeNumber] IS NULL

			 OPEN db_cursor  
			 FETCH NEXT FROM db_cursor INTO @JournalBatchDetailId  

			 WHILE @@FETCH_STATUS = 0  
			 BEGIN  
						 DECLARE @currentNo AS BIGINT = 0;
						 DECLARE @CodeTypeId AS BIGINT = 74;
						 DECLARE @JournalTypeNumber varchar(100);
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

							UPDATE [dbo].[BatchDetails] SET [JournalTypeNumber]=@JournalTypeNumber,[CurrentNumber]=@currentNo  WHERE [JournalBatchDetailId]=@JournalBatchDetailId
							UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @currentNo WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId
      
							IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
							BEGIN
								DROP TABLE #tmpCodePrefixes 
							END
	  
				  FETCH NEXT FROM db_cursor INTO @JournalBatchDetailId 
			END
			CLOSE db_cursor
			DEALLOCATE db_cursor
				
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveCommonJournalBatchDetails' 
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