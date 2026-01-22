/*************************************************************           
 ** File:   [AddUpdateJournalBatchDetails]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used AddUpdateJournalBatchDetails
 ** Purpose:         
 ** Date:   08/10/2022      
          
 ** PARAMETERS: @JournalBatchHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/10/2022  Subhash Saliya     Created
     
-- EXEC AddUpdateJournalBatchDetails 3
************************************************************************/
CREATE   PROCEDURE [dbo].[AddUpdateJournalBatchDetails]
@JournalBatchHeaderId bigint,
@JournalBatchDetailId bigint,
@LineNumber int,
@GlAccountNumber varchar(200),
@GlAccountName varchar(200) ,
@TransactionDate datetime,
@EntryDate datetime,
@ReferenceId bigint ,
@ReferenceName varchar(200) ,
@MPNName varchar(200) ,
@PiecePN varchar(200) ,
@JournalTypeId bigint,
@JournalTypeName varchar(200) ,
@IsDebit bit ,
@DebitAmount decimal(18,2),
@CreditAmount decimal(18,2),
@CustomerId bigint,
@CustomerName varchar(200) ,
@InvoiceId bigint,
@InvoiceName varchar(200) ,
@ARControlNum varchar(200) ,
@CustRefNumber varchar(200) ,
@ManagementStructureId bigint,
@ModuleName varchar(200) ,
@MasterCompanyId int,
@CreatedBy varchar(200) ,
@UpdatedBy varchar(200) ,
@CreatedDate datetime,
@UpdatedDate datetime,
@IsActive bit,
@IsDeleted bit
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		UPDATE [dbo].[JournalBatchDetails]
        SET 
                [LineNumber] = @LineNumber
               ,[GlAccountNumber] = @GlAccountNumber
               ,[GlAccountName] = @GlAccountName
               ,[TransactionDate] = @TransactionDate
               ,[EntryDate] = @EntryDate
               ,[ReferenceId] = @ReferenceId
               ,[ReferenceName] = @ReferenceName
               ,[MPNName] = @MPNName
               ,[PiecePN] = @PiecePN
               ,[JournalTypeId] = @JournalTypeId
               ,[JournalTypeName] = @JournalTypeName
               ,[IsDebit] = @IsDebit
               ,[DebitAmount] = @DebitAmount
               ,[CreditAmount] = @CreditAmount
               ,[ARControlNum] = @ARControlNum
               ,[UpdatedBy] = @UpdatedBy
               ,[UpdatedDate] = GETUTCDATE()
                WHERE JournalBatchDetailId = @JournalBatchDetailId


    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'AddUpdateJournalBatchDetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchHeaderId, '') + ''
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