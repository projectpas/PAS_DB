
/*************************************************************           
 ** File:   [GetJournalBatchHeaderById]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used to GetJournalBatchHeaderById
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
     
-- EXEC GetJournalBatchHeaderById 3
************************************************************************/
CREATE   PROCEDURE [dbo].[GetJournalBatchHeaderById]
@JournalBatchHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT [JournalBatchHeaderId]
              ,[BatchName]
              ,[CurrentNumber]
              ,[EntryDate]
              ,[PostDate]
              ,[AccountingPeriod]
              ,[StatusId]
              ,[StatusName]
              ,[JournalTypeId]
              ,[JournalTypeName]
              ,[TotalDebit]
              ,[TotalCredit]
              ,[TotalBalance]
              ,[MasterCompanyId]
              ,[CreatedBy]
              ,[UpdatedBy]
              ,[CreatedDate]
              ,[UpdatedDate]
              ,[IsActive]
              ,[IsDeleted]
      FROM [dbo].[BatchHeader] where JournalBatchHeaderId =@JournalBatchHeaderId


    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchHeaderById' 
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