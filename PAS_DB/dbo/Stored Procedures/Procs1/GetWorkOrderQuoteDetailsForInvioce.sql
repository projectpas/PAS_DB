
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.GetWorkOrderQuoteDetailsForInvioce   (source: PAS_DB/dbo/Stored Procedures/Procs1/GetWorkOrderQuoteDetailsForInvioce.sql)
-- ---------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [GetWorkOrderQuoteDetailsForInvioce]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Get Invoce Details from Quote  
 ** Purpose:         
 ** Date:   05/25/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/25/2021   Hemant Saliya  Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
	3	 02/23/2024	  Moin Bloch     Added WorkOrderId,CustomerId Fields For Tax Info
	4    05/01/2025   Hemant Saliya  Updated for Handle Falt Billing Amount
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
-- EXEC [GetWorkOrderQuoteDetailsForInvioce] 3566, 3596
**************************************************************/

CREATE   PROCEDURE [dbo].[GetWorkOrderQuoteDetailsForInvioce]
	@workflowWorkorderId BIGINT,
	@WorkOrderPartNoId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT 
					 WQD.WorkOrderQuoteDetailsId,
					 WQD.WorkOrderQuoteId,
					 WQD.ItemMasterId,
					 WQD.WorkFlowWorkOrderId,
					 WQD.WOPartNoId,
					 IM.PartNumber,
					 IM.PartDescription,
					 CASE WHEN WQD.BuildMethodId = 1 THEN 'WF' WHEN WQD.BuildMethodId = 2 THEN 'WO' WHEN WQD.BuildMethodId = 3 THEN 'WF' ELSE 'Third Party' END AS BuildMethod,
					 WQD.BuildMethodId,
                     WQD.MaterialCost,
					 WQD.MaterialBilling,
					 WQD.LaborCost,
					 WQD.LaborBilling,
					 WQD.ChargesCost,
					 WQD.ChargesBilling,
					 WQD.FreightCost,
					 WQD.FreightBilling,
					 MaterialFlatBillingAmount = CASE WHEN ISNULL(wqd.MaterialBuildMethod,0) = 3 THEN ISNULL(wqd.MaterialFlatBillingAmount,0) ELSE ISNULL(wqd.MaterialRevenue,0) END,
					 LaborFlatBillingAmount = CASE WHEN ISNULL(wqd.LaborBuildMethod,0) = 3 THEN ISNULL(wqd.LaborFlatBillingAmount,0) ELSE ISNULL(wqd.LaborRevenue,0) END,
					 ChargesFlatBillingAmount = CASE WHEN ISNULL(wqd.ChargesBuildMethod,0) = 3 THEN ISNULL(wqd.ChargesFlatBillingAmount,0) ELSE ISNULL(wqd.ChargesRevenue,0) END,
					 FreightFlatBillingAmount = CASE WHEN ISNULL(wqd.FreightBuildMethod,0) = 3 THEN ISNULL(wqd.FreightFlatBillingAmount,0) ELSE ISNULL(wqd.FreightRevenue,0) END,
                     --WQD.LaborFlatBillingAmount,
                     --WQD.MaterialFlatBillingAmount,
                     --WQD.ChargesFlatBillingAmount,
                     --WQD.FreightFlatBillingAmount,
                     WQD.MaterialBuildMethod,
                     WQD.LaborBuildMethod,
                     WQD.ChargesBuildMethod,
                     WQD.FreightBuildMethod,
                     WQD.MaterialMarkupId,
                     WQD.LaborMarkupId,
                     WQD.ChargesMarkupId,
                     WQD.FreightMarkupId,
                     WQD.ExclusionsMarkupId,
					 WQD.QuoteMethod,
					 WQD.CommonFlatRate,
					 WOQ.MasterCompanyId,
					 WOQ.WorkOrderId,
					 WO.CustomerId
				FROM dbo.WorkOrderQuoteDetails WQD  WITH(NOLOCK) 				
				LEFT JOIN dbo.WorkOrderQuote WOQ WITH(NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId
				LEFT JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId
				LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WQD.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0
				 WHERE WQD.WorkflowWorkOrderId = @workflowWorkorderId AND WQD.WOPartNoId = @WorkOrderPartNoId AND WQD.IsVersionIncrease = 0
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteBuildMethodDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workflowWorkorderId, '') + '''
													   @Parameter2 = ' + ISNULL(@WorkOrderPartNoId ,'') +''
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