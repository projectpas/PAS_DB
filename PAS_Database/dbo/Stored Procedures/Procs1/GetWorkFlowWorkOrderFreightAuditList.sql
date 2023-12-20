

/*************************************************************           
 ** File:   [GetWorkFlowWorkOrderFreightAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get for Work order Freight Audit List    
 ** Purpose:         
 ** Date:   23-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2021   Subhash Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
     
 EXECUTE [GetWorkFlowWorkOrderFreightAuditList] 154, null
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkFlowWorkOrderFreightAuditList]
@workOrderFreightId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
					wf.Amount,
                    wf.CreatedBy,
                    wf.CreatedDate,
                    wf.IsActive,
                    wf.IsDeleted,
                    wf.MasterCompanyId,
                    wf.Memo,
                    wf.ShipViaId,
                    wf.UpdatedBy,
                    wf.UpdatedDate,
                    wf.Weight,
                    wf.WorkFlowWorkOrderId,
                    wf.WorkOrderFreightId,
                    wf.WorkOrderId,
                    ISNULL(ShipVia,'') as ShipVia,
                    wf.TaskId,
                    ISNULL(Task,'') as TaskName,
                    wf.Length,
                    wf.Width,
                    wf.Height,
                    wf.UOMId,
                    wf.DimensionUOMId,
                    wf.CurrencyId,
                    ISNULL(UOM,'') as UOM,
                    ISNULL(DimentionUOM,'') DimensionUOM,
                    ISNULL(Currency,'') as Currency
				FROM dbo.WorkOrderFreightAudit wf WITH(NOLOCK)
				WHERE wf.WorkOrderFreightId = @workOrderFreightId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteVersion' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderFreightId, '') + ''
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