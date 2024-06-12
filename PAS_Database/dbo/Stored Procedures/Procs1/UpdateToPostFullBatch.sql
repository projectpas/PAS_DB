
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
	1    02/08/2023		Satish Gohil		Account CalenderId and Period Update in BatchDetails
	2	 18/10/2023		Nainshi Joshi		Update PostedBy and PostedDate in BatchDetails and BatchHeader
	3	 11/06/2024		HEMANT SALIYA		Added AP Posted Date
     
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
  BEGIN   
	   DECLARE @ids nvarchar(100);  
	   DECLARE @AccountingPeriodId BIGINT;  
	   DECLARE @AccountingPeriod nvarchar(100); 
	   DECLARE @StatusId BIGINT;  
	   DECLARE @StatusName VARCHAR(50);  
	   DECLARE @APPostedDate DATETIME; 

	   SELECT @StatusId = Id, @StatusName = [Name] FROM dbo.BatchStatus WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED' 

	   ;WITH CTE AS(  
	   SELECT DISTINCT CAST(t.[JournalBatchHeaderId] as NVARCHAR(100)) as JournalBatchHeaderId,  
		 STUFF((SELECT ',' + CONVERT(VARCHAR, CAST(t1.JournalBatchDetailId as NVARCHAR(100)), 101)  
				FROM dbo.BatchDetails t1 WITH (NOLOCK) WHERE t.[JournalBatchHeaderId] = t1.[JournalBatchHeaderId] AND t1.StatusId=1 AND t1.IsDeleted=0  
				FOR XML PATH('')), 1, 1, '') jbdids  
		 FROM dbo.BatchDetails t WITH (NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId  
	   )  
	   SELECT @ids=jbdids FROM CTE  

	   SELECT @AccountingPeriodId = AccountingPeriodId, @AccountingPeriod = AccountingPeriod FROM dbo.BatchHeader WITH(NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId  
  
		IF((SELECT COUNT(1) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE GETUTCDATE() BETWEEN CAST(FromDate AS date) AND CAST(ToDate AS date) AND AccountingCalendarId = @AccountingPeriodId) > 0)
		BEGIN
		SET @APPostedDate = GETUTCDATE();
		END
		ELSE
		BEGIN
		SELECT @APPostedDate = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) 
			WHERE GETUTCDATE() BETWEEN CAST(FromDate AS date) AND CAST(ToDate AS date) AND AccountingCalendarId = @AccountingPeriodId
		END

	   UPDATE BatchDetails SET StatusId = @StatusId,
		   UpdatedDate=GETUTCDATE(),
		   UpdatedBy = @updateBy,
		   AccountingPeriodId = @AccountingPeriodId,
		   AccountingPeriod = @AccountingPeriod,
		   PostedDate = GETUTCDATE(),
		   APPostedDate = @APPostedDate,  
		   PostedBy = @updateBy
	   WHERE JournalBatchDetailId IN (SELECT Item FROM DBO.SPLITSTRING(@ids,','))  

	   UPDATE BatchHeader SET StatusId= @StatusId,
			PostDate = GETUTCDATE(),
			APPostedDate = @APPostedDate,  
			PostedBy = @updateBy,
			StatusName = @StatusName,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = @updateBy 
	   where JournalBatchHeaderId = @JournalBatchHeaderId;
  END  
  
 END TRY      
 BEGIN CATCH        
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