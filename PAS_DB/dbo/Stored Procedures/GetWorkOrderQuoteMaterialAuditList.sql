

/*************************************************************           
 ** File:   [GetWorkOrderQuoteMaterialAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for Work order Quote Materila Audit List    
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

     
 EXECUTE [GetWorkOrderQuoteMaterialAuditList] 198
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderQuoteMaterialAuditList]
	-- Add the parameters for the stored procedure here	
	@WorkOrderQuoteMaterialId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
					Wqm.WorkOrderQuoteMaterialAuditId,
					Wqm.WorkOrderQuoteMaterialId,
                    Wqm.WorkOrderQuoteDetailsId,
                    Wqm.ItemMasterId,
                    Wqm.ConditionCodeId,
                    Wqm.ItemClassificationId,
                    Wqm.Quantity,
                    Wqm.UnitOfMeasureId,
                    Wqm.UnitCost,
                    Wqm.ExtendedCost,
                    Wqm.Memo,
                    Wqm.IsDefered,
                    Wqm.MasterCompanyId,
                    Wqm.CreatedBy,
                    Wqm.UpdatedBy,
                    Wqm.UpdatedDate,
                    Wqm.CreatedDate,
                    Wqm.IsActive,
                    Wqm.IsDeleted,
                    Wqm.MarkupPercentageId,
                    Wqm.TaskId,
                    Wqm.MarkupFixedPrice,
                    Wqm.BillingAmount,
                    ISNULL(Wqm.BillingRate,0) as BillingRate,
                    Wqm.HeaderMarkupId,
                    Wqm.ProvisionId,
                    Wqm.MaterialMandatoriesId,
                    Wqm.BillingMethodId,
					ISNULL(Wqm.TaskName,'') TaskName,
                    ISNULL(Wqm.PartNumber,'') PartNumber,
                    ISNULL(Wqm.PartDescription,'') PartDescription,
                    ISNULL(Wqm.Provision,'') as Provision,
                    ISNULL(Wqm.UomName,'') UomName,
                    ISNULL(WQM.Conditiontype,'') Conditiontype,
					ISNULL(Wqm.Stocktype,'') Stocktype,
                    ISNULL(Wqm.BillingName,'') BillingName,
					ISNULL(Wqm.MarkUp,'') MarkUp
				FROM dbo.WorkOrderQuoteMaterialAudit Wqm  WITH(NOLOCK)
				WHERE  Wqm.WorkOrderQuoteMaterialId = @WorkOrderQuoteMaterialId		            
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteMaterialAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteMaterialId, '') + ''
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