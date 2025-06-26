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
	1    19/06/2025   Moin Bloch	  Created
	2    24/06/2025   Moin Bloch	  Added [IsMiscChargesCheck] Flag
	
	EXEC [dbo].[RPT_GetWorkFlowWorkOrderChargesList] 8982,8764,1    
****************************************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetWorkFlowWorkOrderChargesList]
@WorkOrderId BIGINT = NULL,
@WorkFlowWorkOrderId  BIGINT = NULL,
@MasterCompanyId INT = NULL,
@IsCreatedFromQuote BIT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY	
	
	DECLARE @WOModuleId INT	
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

	DECLARE @WorkOrderFormTypeId BIT = 0; 			
	SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
	
	IF(ISNULL(@IsCreatedFromQuote,0) = 0)
	BEGIN				
		SELECT	DISTINCT
				WOP.[RevisedPartNumber] [PNNumber],									
				CASE WHEN @WorkOrderFormTypeId = 1 THEN UPPER(ISNULL(WOT.[TaskName],''))  ELSE UPPER(ISNULL(ts.[Description],'')) END [TaskName],
				UPPER(ct.[ChargeType]) [ChargeType],
				CASE WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) > 0
				     THEN ISNULL(woc.[UnitCost],0) + (ISNULL(woc.[UnitCost],0) * PER.[PercentValue] / 100.0) 
					 WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) = 0
					 THEN ISNULL(woc.[UnitCost],0)
					 ELSE ISNULL(woc.[UnitCost],0) END [UnitCost],
				ISNULL(woc.[Quantity],0) [Quantity],
				CASE WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) > 0
				     THEN ISNULL(woc.[Quantity],0) * (ISNULL(woc.[UnitCost],0) + (ISNULL(woc.[UnitCost],0) * PER.[PercentValue] / 100.0)) 
					 WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) = 0
					 THEN ISNULL(woc.[ExtendedCost],0)
					 ELSE ISNULL(woc.[ExtendedCost],0) END [ExtendedCost]
			FROM [dbo].[WorkOrderCharges] woc WITH(NOLOCK)				
				 JOIN [dbo].[Charge] ct WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId
				 --LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
				 LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
				 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = woc.TaskId
				 --LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId	
				 --LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON woc.UOMId = uom.UnitOfMeasureId
				 LEFT JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
				 LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.ID = WOF.WorkOrderPartNoId
				 LEFT JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON WOP.ID = BII.SubReferenceId AND WOP.WorkOrderId = BII.ReferenceId AND ISNULL(BII.IsVersionIncrease,0) = 0 AND ISNULL(BII.IsPerformaInvoice,0) = 0 AND BII.ModuleId = @WOModuleId
			     LEFT JOIN [dbo].[Percent] PER WITH(NOLOCK) ON BII.MiscChargesCostPercent = PER.PercentId AND BII.ModuleId = @WOModuleId
			WHERE woc.IsDeleted = 0 AND woc.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND woc.MasterCompanyId=@masterCompanyId
	END
	ELSE
	BEGIN
		SELECT	DISTINCT
				WOP.[RevisedPartNumber] [PNNumber],									
				CASE WHEN @WorkOrderFormTypeId = 1 THEN UPPER(ISNULL(WOT.[TaskName],''))  ELSE UPPER(ISNULL(ts.[Description],'')) END [TaskName],
				UPPER(ct.[ChargeType]) [ChargeType],
				CASE WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) > 0
				     THEN ISNULL(woc.[UnitCost],0) + (ISNULL(woc.[UnitCost],0) * PER.[PercentValue] / 100.0) 
					 WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) = 0
					 THEN ISNULL(woc.[UnitCost],0)
					 ELSE ISNULL(woc.[UnitCost],0) END [UnitCost],
				ISNULL(woc.[Quantity],0) [Quantity],
				CASE WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) > 0
				     THEN ISNULL(woc.[Quantity],0) * (ISNULL(woc.[UnitCost],0) + (ISNULL(woc.[UnitCost],0) * PER.[PercentValue] / 100.0)) 
					 WHEN BII.[IsMiscChargesCheck] = 1 AND ISNULL(BII.[MiscChargesCostPercent],0) = 0
					 THEN ISNULL(woc.[BillingAmount],0) 
					 ELSE ISNULL(woc.[BillingAmount],0) END [ExtendedCost]
			FROM [dbo].[WorkOrderQuoteCharges] woc WITH(NOLOCK)
		         INNER JOIN [dbo].[WorkOrderQuoteDetails] wq WITH(NOLOCK) ON woc.WorkOrderQuoteDetailsId = wq.WorkOrderQuoteDetailsId
				 INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId
				  --LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
				  LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
				  LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = woc.TaskId
				  --LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId	
				  --LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON woc.UOMId = uom.UnitOfMeasureId
				  LEFT JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
				  LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.ID = WOF.WorkOrderPartNoId
				  LEFT JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON WOP.ID = BII.SubReferenceId AND WOP.WorkOrderId = BII.ReferenceId AND ISNULL(BII.IsVersionIncrease,0) = 0 AND ISNULL(BII.IsPerformaInvoice,0) = 0 AND BII.ModuleId = @WOModuleId
			      LEFT JOIN [dbo].[Percent] PER WITH(NOLOCK) ON BII.MiscChargesCostPercent = PER.PercentId AND BII.ModuleId = @WOModuleId
			WHERE woc.IsDeleted = 0 AND wq.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND woc.MasterCompanyId=@masterCompanyId
	END


	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkFlowWorkOrderChargesList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@workOrderId ,'') +'''													 
													   @Parameter2 = ' + ISNULL(CAST(1 AS varchar(10)) ,'') +''
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