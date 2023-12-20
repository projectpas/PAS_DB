/*************************************************************           	
**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_SaveCommonJournalBatchDetails]
@tbl_CommonJournalBatchDetails CommonJournalBatchDetailsType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
				

				--  JournalBatchDetails LIST
					IF((SELECT COUNT(CommonJournalBatchDetailId) FROM @tbl_CommonJournalBatchDetails) > 0 )
					BEGIN
						MERGE dbo.CommonBatchDetails AS TARGET
						USING @tbl_CommonJournalBatchDetails AS SOURCE ON (TARGET.JournalBatchHeaderId = SOURCE.JournalBatchHeaderId AND TARGET.CommonJournalBatchDetailId = SOURCE.CommonJournalBatchDetailId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 
							
								 TARGET.GlAccountId = SOURCE.GlAccountId
								,TARGET.TransactionDate = SOURCE.TransactionDate
								,TARGET.EntryDate =SOURCE.EntryDate
								,TARGET.DebitAmount =SOURCE.DebitAmount
								,TARGET.CreditAmount = SOURCE.CreditAmount
								,TARGET.[UpdatedBy] = SOURCE.UpdatedBy
								,TARGET.[UpdatedDate] = GETUTCDATE()
								,TARGET.JournalTypeName= SOURCE.JournalTypeName
								,TARGET.ManagementStructureId= SOURCE.ManagementStructureId
								,TARGET.LastMSLevel= SOURCE.LastMSLevel
								,TARGET.AllMSlevels= SOURCE.AllMSlevels
								,TARGET.IsDebit= SOURCE.IsDebit
							
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (
										JournalBatchDetailId
										,JournalBatchHeaderId
										,LineNumber
										,GlAccountId
										,TransactionDate
										,EntryDate
										,IsDebit
										,DebitAmount
										,CreditAmount
										,JournalTypeId
										,JournalTypeName
										,[MasterCompanyId]
										,[CreatedBy]
										,[UpdatedBy]
										,[CreatedDate]
										,[UpdatedDate]
										,[IsActive]
										,[IsDeleted]
										,IsManualEntry
										,ManagementStructureId
										,LastMSLevel
										,AllMSlevels
										
										)
							VALUES (
										SOURCE.JournalBatchDetailId
										,SOURCE.JournalBatchHeaderId
										,SOURCE.LineNumber
										,SOURCE.GlAccountId
										,SOURCE.TransactionDate
										,SOURCE.EntryDate
										,SOURCE.IsDebit
										,SOURCE.DebitAmount
										,SOURCE.CreditAmount
										,SOURCE.JournalTypeId
										,SOURCE.JournalTypeName
										,SOURCE.[MasterCompanyId]
										,SOURCE.[UpdatedBy]
										,SOURCE.[UpdatedBy]
										,GETUTCDATE()
										,GETUTCDATE()
										,1
										,SOURCE.[IsDeleted]
										,1
										,SOURCE.ManagementStructureId
										,SOURCE.LastMSLevel
										,SOURCE.AllMSlevels
										);


					 END

			 Declare @commonBatchDetailsId bigint;
			 Declare @BDetailsId bigint;
			 Declare @manualentry bit;
			 declare @DAmount decimal(18,2)=0;
			 declare @CAmount decimal(18,2)=0;
			 Declare @isdebit bit;
			 SET @commonBatchDetailsId = (Select top 1 CommonJournalBatchDetailId from @tbl_CommonJournalBatchDetails)
			 --SELECT @manualentry=IsManualEntry,@DAmount=DebitAmount,@CAmount=CreditAmount,@isdebit=IsDebit,@BDetailsId=JournalBatchDetailId FROM CommonBatchDetails WITH(NOLOCK) where CommonJournalBatchDetailId=@commonBatchDetailsId
			 SELECT @BDetailsId=JournalBatchDetailId FROM CommonBatchDetails WITH(NOLOCK) where CommonJournalBatchDetailId=@commonBatchDetailsId

			 SELECT @DAmount=SUM(DebitAmount),@CAmount=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@BDetailsId AND IsDeleted=0
			 --IF(@manualentry = 1)
			 --BEGIN
				Update BatchDetails set DebitAmount=@DAmount,CreditAmount=@CAmount,IsDebit=@isdebit,UpdatedDate=GETUTCDATE() where JournalBatchDetailId= @BDetailsId
			 --END
		     
			 declare @TotalDebit decimal(18,2)=0
	         declare @TotalCredit decimal(18,2)=0
	         declare @TotalBalance decimal(18,2)=0
			 Declare @JournalBatchHeaderId bigint 
			  Declare @MasterCompanyId bigint 

			 SET @JournalBatchHeaderId = (Select top 1 JournalBatchHeaderId from @tbl_CommonJournalBatchDetails)

			 SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount),@MasterCompanyId=MasterCompanyId FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId,MasterCompanyId
			   	          
			 SET @TotalBalance =@TotalDebit-@TotalCredit
				          
			 Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE()   where JournalBatchHeaderId= @JournalBatchHeaderId

			 update JBD  set jbd.GlAccountName=gl.AccountName,jbd.GlAccountNumber=gl.AccountCode from dbo.CommonBatchDetails JBD left join GLAccount GL on Gl.GLAccountId=JBD.GLAccountId 


DECLARE @JournalBatchDetailId int;
DECLARE db_cursor CURSOR FOR 
SELECT JournalBatchDetailId 
FROM BatchDetails where JournalBatchHeaderId= @JournalBatchHeaderId and JournalTypeNumber is null

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @JournalBatchDetailId  

WHILE @@FETCH_STATUS = 0  
BEGIN  
      print @JournalBatchDetailId
	         DECLARE @currentNo AS BIGINT = 0;
			 DECLARE @CodeTypeId AS BIGINT = 74;
			 DECLARE @JournalTypeNumber varchar(100);
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

       update BatchDetails set JournalTypeNumber=@JournalTypeNumber ,CurrentNumber=@currentNo  where JournalBatchDetailId=@JournalBatchDetailId
       UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
      
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