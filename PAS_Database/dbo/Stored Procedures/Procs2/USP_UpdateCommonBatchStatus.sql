/*************************************************************             
 ** File:   [USP_UpdateCommonBatchStatus]  
 ** Author:  Satish Gohil  
 ** Description: This stored procedure is used update Batch Status  
 ** Purpose:           
 ** Date:   07/13/2023        
            
 ** PARAMETERS: @JournalBatchHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change		Description              
 ** --   --------     -------  ------		--------------------------            
    1    07/13/2023		Satish Gohil		Created   
	2	 18/10/2023		Nainshi Joshi		Update PostedBy in BatchDetails
	3	 11/06/2024		HEMANT SALIYA		Added AP Posted Date
  
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_UpdateCommonBatchStatus]  
(  
 @journalBatchDetailId BIGINT,  
 @updatedBy VARCHAR(100),  
 @AccountingPeriodId BIGINT,  
 @AccountingPeriod VARCHAR(50)  
)  
AS  
BEGIN  
 BEGIN TRY  
  DECLARE @JournalBatchHeaderId BIGINT;  
  DECLARE @StatusId BIGINT;  
  DECLARE @BatchCount INT;  
  DECLARE @PostBatchCount INT;  
  DECLARE @StatusName VARCHAR(50);  
  DECLARE @APPostedDate DATETIME;  
  
  SELECT @JournalBatchHeaderId = JournalBatchHeaderId FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchDetailId = @journalBatchDetailId  
  SELECT @StatusId = Id,@StatusName = Name FROM dbo.BatchStatus WITH(NOLOCK) WHERE Name = 'Posted'  
  SELECT * FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @AccountingPeriodId

  IF((SELECT COUNT(1) FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE GETUTCDATE() BETWEEN CAST(FromDate AS date) AND CAST(ToDate AS date) AND AccountingCalendarId = @AccountingPeriodId) > 0)
  BEGIN
	SET @APPostedDate = GETUTCDATE();
  END
  ELSE
  BEGIN
	SELECT @APPostedDate = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) 
		WHERE GETUTCDATE() BETWEEN CAST(FromDate AS date) AND CAST(ToDate AS date) AND AccountingCalendarId = @AccountingPeriodId
  END
  
  UPDATE dbo.BatchDetails SET   
   PostedDate = GETUTCDATE(),
   APPostedDate = @APPostedDate,  
   PostedBy = @updatedBy,
   StatusId = @StatusId,  
   UpdatedBy = @updatedBy,  
   UpdatedDate = GETUTCDATE(),  
   AccountingPeriodId = @AccountingPeriodId,  
   AccountingPeriod = @AccountingPeriod  
   WHERE JournalBatchDetailId = @journalBatchDetailId  
  
  SELECT @BatchCount = COUNT(*) FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId  
  SELECT @PostBatchCount = COUNT(*) FROM dbo.BatchDetails WITH(NOLOCK) WHERE JournalBatchHeaderId = @JournalBatchHeaderId AND StatusId = @StatusId  
  
  IF(@BatchCount = @PostBatchCount)  
  BEGIN  
   UPDATE dbo.BatchHeader SET  
   PostDate = GETUTCDATE(),  
   APPostedDate = @APPostedDate,  
   PostedBy = @updatedBy,  
   StatusId = @StatusId,  
   StatusName = @StatusName,  
   UpdatedBy = @updatedBy,  
   UpdatedDate= GETUTCDATE()  
   WHERE JournalBatchHeaderId = @JournalBatchHeaderId  
  END  
  
 END TRY  
 BEGIN CATCH    
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonDistribution'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@journalBatchDetailId, '') + ''  
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