/***************************************************************  
 ** File:   [USP_WorkOrderAnalysis]             
 ** Author:   Shrey Chandegara
 ** Description: Get WorkOrder Analysis
 ** Date:  11-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    18-04-2025		Hemnat Saliya		Created  	
		
	exec dbo.USP_GetWorkOrderBillingCostDetails 8374,1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderBillingCostDetails]
    @WorkOrderWorkflowId BIGINT,
	@ManagementStructureId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  

		-- Temp tables or variables
		DECLARE @LabourCost DECIMAL(18,2) = 0;
		DECLARE @PartsCost DECIMAL(18,2) = 0;
		DECLARE @MicCharges DECIMAL(18,2) = 0;
		DECLARE @FreightCost DECIMAL(18,2) = 0;
		DECLARE @TotalCost DECIMAL(18,2) = 0;
		DECLARE @CustomerId BIGINT = 0;
		DECLARE @WorkOrderId BIGINT = 0;
		DECLARE @WorkOrderPartId BIGINT = 0;
		DECLARE @MasterCompanyId BIGINT = 0;

		SELECT TOP  1 @CustomerId = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId , @WorkOrderId = WO.WorkOrderId, @WorkOrderPartId = WorkOrderPartNoId
		FROM dbo.WorkOrder WO JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkOrderWorkflowId

		IF OBJECT_ID(N'tempdb..#SalesTaxAndOtherTaxDetails') IS NOT NULL
		BEGIN
			DROP TABLE #SalesTaxAndOtherTaxDetails
		END
	
		CREATE TABLE #SalesTaxAndOtherTaxDetails
		(
			[ID] BIGINT NOT NULL IDENTITY,
			[SalesTax] DECIMAL(18,2) NULL,
			[OtherTax]  DECIMAL(18,2) NULL				
		)

		-- Calculate parts cost (Materials)
		SELECT @PartsCost = ISNULL(SUM(ISNULL(WOMS.UnitCost,0) * ISNULL(WOMS.QtyIssued,0)), 0)
		FROM [dbo].WorkOrderMaterials WOM WITH(NOLOCK)
		JOIN [dbo].WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOM.IsDeleted = 0;

		-- Add Kit materials
		SELECT @PartsCost = @PartsCost + ISNULL(SUM(ISNULL(WOMS.UnitCost,0) * ISNULL(WOMS.QtyIssued,0)), 0)
		FROM [dbo].WorkOrderMaterialsKit WOM WITH(NOLOCK)
		JOIN [dbo].WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
		WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOM.IsDeleted = 0;

		-- Charges
		SELECT @MicCharges = ISNULL(SUM(ISNULL(ExtendedCost, 0)), 0)
		FROM [dbo].WorkOrderCharges WITH(NOLOCK)
		WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId AND IsActive = 1 AND IsDeleted = 0;

		-- Freight
		SELECT @FreightCost = ISNULL(SUM(ISNULL(Amount, 0)), 0)
		FROM [dbo].WorkOrderFreight WITH(NOLOCK)
		WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId AND IsActive = 1 AND IsDeleted = 0;

		-- Labour Cost
		SELECT TOP 1 @LabourCost = ISNULL(SUM(l.TotalCost), 0)
		FROM [dbo].WorkOrderLaborHeader lh WITH(NOLOCK)
		JOIN [dbo].WorkOrderLabor l WITH(NOLOCK) ON lh.WorkOrderLaborHeaderId = l.WorkOrderLaborHeaderId
		WHERE lh.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND l.BillableId = 1 AND l.IsActive = 1 AND l.IsDeleted = 0;

		SET @TotalCost = @PartsCost + @LabourCost + @MicCharges + @FreightCost

		PRINT '1'
		INSERT INTO #SalesTaxAndOtherTaxDetails
		EXEC dbo.USP_GetCustomerTax_Information_Repair_WO @WorkOrderId = @WorkOrderId, @WorkOrderPartId = @WorkOrderPartId, @CustomerId = @CustomerId, @MasterCompanyId = @MasterCompanyId
		PRINT '2'
		-- After all calculations, return the result
		SELECT 
			@PartsCost AS MaterialCost,
			@LabourCost AS LabourCost,
			@MicCharges AS MiscCharges,
			@FreightCost AS FreightCost,
			@TotalCost AS TotalCost,
			tmp.SalesTax AS SalesTax,
			tmp.OtherTax AS OtherTax,
			(@TotalCost * tmp.SalesTax)/100 AS SalesTaxAmount,
			(@TotalCost * tmp.OtherTax)/100 AS OtherTaxAmount
		FROM #SalesTaxAndOtherTaxDetails tmp 
			
	END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderBillingCostDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workorderid, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END;