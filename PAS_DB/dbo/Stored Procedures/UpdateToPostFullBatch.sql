
 /*************************************************************           
 ** File:   [UpdateToPostFullBatch]           
 ** Author: Satish Gohil
 ** Description: This stored procedure is used update Batch Details Record
 ** Purpose:         
 ** Date:   02/08/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	2    02/08/2023		Satish Gohil		Account CalenderId and Period Update in BatchDetails
	3	 18/10/2023		Nainshi Joshi		Update PostedBy and PostedDate in BatchDetails and BatchHeader
     
--EXEC UpdateToPostFullBatch 535,'Admin User'
**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateToPostFullBatch]  
@JournalBatchHeaderId bigint,
@updateBy varchar(50)
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 --BEGIN TRANSACTION  
  BEGIN   
   declare @ids nvarchar(100);  
   declare @AccountingPeriodId BIGINT;  
   declare @AccountingPeriod nvarchar(100);  
   ;WITH CTE AS(  
   select distinct CAST(t.[JournalBatchHeaderId] as Nvarchar(100)) as JournalBatchHeaderId,  
     STUFF((SELECT ',' + CONVERT(VARCHAR, CAST(t1.JournalBatchDetailId as NVARCHAR(100)), 101)  
            FROM BatchDetails t1 WITH (NOLOCK) Where t.[JournalBatchHeaderId] = t1.[JournalBatchHeaderId] AND t1.StatusId=1 AND t1.IsDeleted=0  
            FOR XML PATH('')), 1, 1, '') jbdids  
     from BatchDetails t where JournalBatchHeaderId=@JournalBatchHeaderId  
   )  
   --select * from CTE;  
   SELECT @ids=jbdids FROM CTE  
   SELECT @AccountingPeriodId = AccountingPeriodId,@AccountingPeriod = AccountingPeriod FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalBatchHeaderId=@JournalBatchHeaderId  
   --SET @ids= (SELECT jbdids FROM CTE)  
  
  
   UPDATE BatchDetails SET StatusId=3,UpdatedDate=GETUTCDATE(),UpdatedBy = @updateBy,
   AccountingPeriodId = @AccountingPeriodId,AccountingPeriod = @AccountingPeriod,PostedDate=GETUTCDATE(),
   PostedBy=@updateBy
   WHERE JournalBatchDetailId IN (SELECT Item FROM DBO.SPLITSTRING(@ids,','))  

   UPDATE BatchHeader SET StatusId= 3,PostDate = GETUTCDATE(),PostedBy = @updateBy,StatusName = 'Posted',UpdatedDate =GETUTCDATE(),UpdatedBy = @updateBy where JournalBatchHeaderId = @JournalBatchHeaderId;
  END  
 -- COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  --IF @@trancount > 0  
  -- PRINT 'ROLLBACK'  
  -- ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'UpdateToPostFullBatch'   
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