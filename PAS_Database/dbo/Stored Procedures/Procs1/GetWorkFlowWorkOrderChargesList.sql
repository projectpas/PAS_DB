/*************************************************************           
 ** File:   [GetWorkFlowWorkOrderChargesList]           
 ** Author: 
 ** Description: This stored procedure is used to get Charge Data List.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    
	2    22/12/2023   Bhargav Salya		  get UOMid

     
**************************************************************/
CREATE     PROCEDURE [dbo].[GetWorkFlowWorkOrderChargesList]
@wfwoId bigint = null,
@workOrderId bigint = null,
@IsDeleted bit= null,
@masterCompanyId int= null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  

  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
					woc.ChargesTypeId,
					ct.ChargeType as ChargeType,
					woc.Description,
					woc.Quantity,
					woc.UnitCost,
					woc.ExtendedCost,
					woc.VendorId,
					v.VendorName,
					woc.CreatedBy,
					woc.CreatedDate,
					woc.IsActive,
					woc.IsDeleted,
					woc.MasterCompanyId,
					woc.TaskId,
					woc.UpdatedBy,
					woc.UpdatedDate,
					woc.WorkFlowWorkOrderId,
					woc.WorkOrderChargesId,
					woc.WorkOrderId,
					woc.IsFromWorkFlow,
					woc.ChargesTypeId as WorkflowChargeTypeId,
					ISNULL(ts.Description,'') as TaskName,
					woc.ReferenceNo as RefNum,
					ISNULL(gl.AccountName,'') as GLAccountName,
					woc.UOMId,
					ISNULL(uom.ShortName,'') as UOM
				FROM dbo.WorkOrderCharges woc WITH(NOLOCK)				
					JOIN dbo.Charge ct WITH(NOLOCK) on woc.ChargesTypeId = ct.ChargeId
					LEFT JOIN dbo.Vendor v WITH(NOLOCK) on woc.VendorId = v.VendorId
					JOIN dbo.Task ts WITH(NOLOCK) on woc.TaskId = ts.TaskId
					LEFT JOIN dbo.GLAccount gl WITH(NOLOCK) on ct.GLAccountId = gl.GLAccountId	
					LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) on woc.UOMId = uom.UnitOfMeasureId
				WHERE woc.IsDeleted = @IsDeleted AND woc.WorkFlowWorkOrderId = @wfwoId and woc.MasterCompanyId=@masterCompanyId
			END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkFlowWorkOrderChargesList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@wfwoId, '') + ''',
													   @Parameter2 = ' + ISNULL(@workOrderId ,'') +'''
													   @Parameter3 = ' + ISNULL(@masterCompanyId ,'') +'''
													   @Parameter4 = ' + ISNULL(CAST(@IsDeleted AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END