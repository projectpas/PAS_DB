/*************************************************************             
 ** File:   [GetJournalBatchDetailsViewById]  
 ** Author:  Satish Gohil  
 ** Description: This stored procedure is used get Batch Details By Id  
 ** Purpose:           
 ** Date:   03/08/2023        
            
 ** PARAMETERS: @JournalBatchHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    03/08/2023  Satish Gohil   AccountingPeriodId and AccountingPeriod Field Added  
    2    18/09/2023  Bhargav Saliya  Added Fields PostedDate and Status
************************************************************************/  
CREATE    PROCEDURE [dbo].[GetJournalBatchDetailsViewById]  
@JournalBatchHeaderId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  select JBH.JournalBatchHeaderId,JBD.JournalBatchDetailId,JBH.Module,ISNULL(JBD.DebitAmount,0) as DebitAmount,ISNULL(JBD.CreditAmount,0) as CreditAmount,JBD.JournalTypeNumber,JBD.EntryDate,JBD.JournalTypeName,JT.JournalTypeCode,JBD.StatusId,JBD.CreatedDate,JBD.UpdatedDate,JBD.CreatedBy,JBD.UpdatedBy,  
  JBD.AccountingPeriodId,JBD.AccountingPeriod,JBD.PostedDate,BS.Name AS [Status]
  from [dbo].[BatchHeader] JBH  
  Inner JOIN BatchDetails JBD WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId   
  LEFT JOIN BatchStatus BS WITH(NOLOCK) ON JBD.StatusId = BS.ID  
  LEFT JOIN JournalType JT WITH(NOLOCK) ON JBD.JournalTypeId = JT.ID  
  --Inner JOIN CommonBatchDetails CJBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=CJBD.JournalBatchDetailId    
  where JBH.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=0 order by JournalBatchDetailId desc;  
    END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchDetailsViewById'   
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