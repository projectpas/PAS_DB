

/*************************************************************           
 ** File:   [GetWorkOrderQuoteLaborAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for Work order Quote Labor Audit List    
 ** Purpose:         
 ** Date:   16-March-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/16/2021   Subhash Saliya Created

     
 EXECUTE [GetWorkOrderQuoteLaborAuditList] 27
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderQuoteLaborAuditList]
	-- Add the parameters for the stored procedure here	
	@WorkOrderQuoteLaborId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
					Wqm.WorkOrderQuoteLaborAuditId,
					Wqm.WorkOrderQuoteLaborId,
                    Wqm.WorkOrderQuoteLaborHeaderId,
                    Wqm.ExpertiseId,
                    Wqm.Hours,
                    Wqm.BillableId,
                    Wqm.MasterCompanyId,
                    Wqm.CreatedBy,
                    Wqm.UpdatedBy,
                    Wqm.UpdatedDate,
                    Wqm.CreatedDate,
                    Wqm.IsActive,
                    Wqm.IsDeleted,
                    Wqm.MarkupPercentageId,
                    Wqm.TaskId,
                    Wqm.DirectLaborOHCost,
                    Wqm.BillingAmount,
                    isnull(Wqm.BillingRate,0) as BillingRate,
                    Wqm.MarkupPercentageId,
                    Wqm.BurdenRateAmount,
                    Wqm.TotalCostPerHour,
					Wqm.TotalCost,
                    Wqm.BillingRate,
                    Wqm.BillingAmount,
                    Wqm.BurdaenRatePercentageId,
                    ISNULL(Wqm.TaskName,'') TaskName,
                    ISNULL(Wqm.Expertise,'') Expertise,
                    ISNULL(Wqm.Billabletype,'') as Billabletype,
                    ISNULL(Wqm.BurdaenRatePercentage,'0') BurdaenRatePercentage,
                    ISNULL(WQM.BillingName,'') BillingName,
					ISNULL(Wqm.MarkUp,'') MarkUp
				FROM dbo.WorkOrderQuoteLaborAudit Wqm  WITH(NOLOCK)
				WHERE  Wqm.WorkOrderQuoteLaborId = @WorkOrderQuoteLaborId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteLaborAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteLaborId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END