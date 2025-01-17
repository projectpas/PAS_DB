/************************************************************************************           
 ** File:   [GetWorkFlowWorkOrderChargesList]           
 ** Author: 
 ** Description: This stored procedure is used to get Charge Data List.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    
	2    22/12/2023   Bhargav Salya	  get UOMid
	3	 01/17/2025	  Moin Bloch	  Modified (Added @WorkOrderFormTypeId from WO)     
****************************************************************************************/
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
	
			DECLARE @WorkOrderFormTypeId BIT = 0; 			

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
				SELECT	
					woc.ChargesTypeId,
					ct.ChargeType AS ChargeType,
					woc.[Description],
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
					woc.ChargesTypeId AS WorkflowChargeTypeId,
					--ISNULL(ts.Description,'') as TaskName,
					CASE WHEN @WorkOrderFormTypeId = 1 THEN  ISNULL(WOT.[TaskName],'')  ELSE ISNULL(ts.[Description],'') END AS TaskName,
					woc.ReferenceNo AS RefNum,
					ISNULL(gl.AccountName,'') AS GLAccountName,
					woc.UOMId,
					ISNULL(uom.ShortName,'') AS UOM
				FROM [dbo].[WorkOrderCharges] woc WITH(NOLOCK)				
					JOIN [dbo].[Charge] ct WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId
					LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
					LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
					LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = woc.TaskId
					LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId	
					LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON woc.UOMId = uom.UnitOfMeasureId
				WHERE woc.IsDeleted = @IsDeleted AND woc.WorkFlowWorkOrderId = @wfwoId AND woc.MasterCompanyId=@masterCompanyId
		
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
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