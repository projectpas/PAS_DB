
/*************************************************************           
 ** File:   [usp_SaveJournalBatchDetails]           
 ** Author:   Subhash Saliya
 ** Description: Save Customer JournalBatchDetails
 ** Purpose:         
 ** Date:   22-Auguest-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/22/2022   Subhash Saliya Created
	
**************************************************************/ 
CREATE     PROCEDURE [dbo].[usp_SaveJournalBatchDetails]
@tbl_JournalBatchDetails JournalBatchDetailsType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN
				

				--  JournalBatchDetails LIST
					IF((SELECT COUNT(JournalBatchDetailId) FROM @tbl_JournalBatchDetails) > 0 )
					BEGIN
						MERGE dbo.BatchDetails AS TARGET
						USING @tbl_JournalBatchDetails AS SOURCE ON (TARGET.JournalBatchHeaderId = SOURCE.JournalBatchHeaderId AND TARGET.JournalBatchDetailId = SOURCE.JournalBatchDetailId) 
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
							
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (
										JournalBatchHeaderId
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
										 SOURCE.JournalBatchHeaderId
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
		     
			 declare @TotalDebit decimal(18,2)=0
	         declare @TotalCredit decimal(18,2)=0
	         declare @TotalBalance decimal(18,2)=0
			 Declare @JournalBatchHeaderId bigint 

			 SET @JournalBatchHeaderId = (Select top 1 JournalBatchHeaderId from @tbl_JournalBatchDetails)

			 SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
			 SET @TotalBalance =@TotalDebit-@TotalCredit
				          
			 Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE()   where JournalBatchHeaderId= @JournalBatchHeaderId

			 update JBD  set jbd.GlAccountName=gl.AccountName,jbd.GlAccountNumber=gl.AccountCode from dbo.BatchDetails JBD left join GLAccount GL on Gl.GLAccountId=JBD.GLAccountId 

				
				END
				COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveJournalBatchDetails' 
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