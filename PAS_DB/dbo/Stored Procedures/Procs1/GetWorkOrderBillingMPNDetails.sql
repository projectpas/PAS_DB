/*************************************************************           
 ** File:  [GetWorkOrderBillingMPNDetails]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Work Order Part Details     
 ** Date:   01/05/2025     
 ** PARAMETERS: @WorkOrderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/05/2025   Moin Bloch    Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
--  EXEC [dbo].[GetWorkOrderBillingMPNDetails] 8809,0,'',15
--  EXEC [dbo].[GetWorkOrderBillingMPNDetails] 8800,0,'',15
--  EXEC [dbo].[GetWorkOrderBillingMPNDetails] 8800,0,'8559,8560',15

************************************************************************/
CREATE PROCEDURE [dbo].[GetWorkOrderBillingMPNDetails]
@ReferenceId BIGINT=NULL,
@SubReferenceId BIGINT=NULL,
@SubReferenceIds VARCHAR(200)=NULL,
@ModuleId INT=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN
		    DECLARE @TotalRecords INT = 0,@MinId INT = 1,@WorkOrderMPNMSModuleEnum INT=12   			 
			DECLARE @ID BIGINT = 0, @CustomerId BIGINT = 0,@MasterCompanyId INT = 0;			
			DECLARE @Partnumber VARCHAR(50)='',@ManufacturerName VARCHAR(250)='',@PartDescription NVARCHAR(MAX)='',@SerialNumber VARCHAR(100)=''

			IF(@SubReferenceIds = '')
			BEGIN
				SET @SubReferenceIds = NULL;
			END
			
			SELECT @WorkOrderMPNMSModuleEnum = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN'

			SELECT @CustomerId = WO.[CustomerId],@MasterCompanyId = WO.[MasterCompanyId] FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.[WorkOrderId] = @ReferenceId;
			
			IF OBJECT_ID(N'tempdb..#TempWorkOrderPartNumberDetailsForBilling') IS NOT NULL
			BEGIN
				DROP TABLE #TempWorkOrderPartNumberDetailsForBilling
			END

			CREATE TABLE #TempWorkOrderPartNumberDetailsForBilling
			(		
				[PKID] BIGINT NOT NULL IDENTITY, 
				[ReferenceId] BIGINT NULL,
				[SubReferenceId] BIGINT NULL,
				[WorkOrderWorkflowId] BIGINT NULL, 
				[ItemMasterId] BIGINT NULL,	
				[StockLineId] BIGINT NULL,
				[ConditionId] BIGINT NULL,
				[UnitPrice] DECIMAL(18,2) NULL,	 
				[QtyBilled] INT NULL, 
				[PartNumber] VARCHAR(200) NULL,
				[PartDescription] NVARCHAR(max) NULL,				
				[ManufacturerName] VARCHAR(250) NULL,				
				[SerialNumber] VARCHAR(100) NULL,
				[MaterialCost] DECIMAL(18,2) NULL,
				[LabourCost] DECIMAL(18,2) NULL,
				[MiscCharges] DECIMAL(18,2) NULL,
				[FreightCost] DECIMAL(18,2) NULL,
				[TotalCost] DECIMAL(18,2) NULL, 
				[SalesTaxPercent] BIGINT NULL,				
				[SalesTax] DECIMAL(18,2) NULL, 
				[SalesTaxAmount] DECIMAL(18,2) NULL, 
				[OtherTaxPercent] BIGINT NULL,
				[OtherTax] DECIMAL(18,2) NULL, 
				[OtherTaxAmount] DECIMAL(18,2) NULL,
				[GrandTotal] DECIMAL(18,2) NULL
			)
				
			INSERT INTO #TempWorkOrderPartNumberDetailsForBilling([ReferenceId],[SubReferenceId],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[SerialNumber]) 
				                                           SELECT [WorkOrderId],[ID],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[CurrentSerialNumber]
			FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) 
			WHERE [WorkOrderId] = @ReferenceId  
			  AND (@SubReferenceIds IS NULL OR [ID] IN (SELECT Item FROM DBO.SPLITSTRING(@SubReferenceIds,',')))                
			  AND [IsDeleted] = 0 
			ORDER BY [ID]	
		
		    SELECT @TotalRecords = COUNT(*), @MinId = MIN([PKID]) FROM #TempWorkOrderPartNumberDetailsForBilling    
			
			WHILE @MinId <= @TotalRecords
			BEGIN
				DECLARE @WorkFlowWorkOrderId BIGINT = 0
				DECLARE @LabourCost DECIMAL(18,2) = 0;
				DECLARE @PartsCost DECIMAL(18,2) = 0;
				DECLARE @MicCharges DECIMAL(18,2) = 0;
				DECLARE @FreightCost DECIMAL(18,2) = 0;
				DECLARE @TotalCost DECIMAL(18,2) = 0;
				DECLARE @SalesTax DECIMAL(18,2) = 0;
				DECLARE @OtherTax DECIMAL(18,2) = 0;
				DECLARE @SalesTaxPercent BIGINT = 0;
				DECLARE @OtherTaxPercent BIGINT = 0;
				DECLARE @SalesTaxAmount DECIMAL(18,2) = 0;
				DECLARE @OtherTaxAmount DECIMAL(18,2) = 0;
				DECLARE @GrandTotal DECIMAL(18,2) = 0;
						

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

				SELECT @ID = [SubReferenceId] FROM #TempWorkOrderPartNumberDetailsForBilling WHERE [PKID] = @MinId;	
				
				SELECT @WorkFlowWorkOrderId = (SELECT TOP 1 [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @ID)
				
				SELECT TOP 1
				  	   @PartNumber = CASE WHEN wop.[RevisedPartNumber] IS NOT NULL AND wop.[RevisedPartNumber] <> '' THEN wop.[RevisedPartNumber] ELSE im.[PartNumber] END,
					   @ManufacturerName = im.[ManufacturerName],
					   @PartDescription = CASE WHEN wop.[RevisedPartDescription] IS NOT NULL AND wop.[RevisedPartDescription] <> '' THEN wop.[RevisedPartDescription] ELSE im.[PartDescription] END,
					   @SerialNumber = CASE WHEN wop.[RevisedSerialNumber] IS NOT NULL AND wop.[RevisedSerialNumber] <> '' THEN wop.[RevisedSerialNumber] ELSE sl.[SerialNumber] END
					FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
					INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON wop.[StockLineId] = sl.[StockLineId]
					INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.[ItemMasterId] = im.[ItemMasterId]					
					WHERE wop.[WorkOrderId] = @ReferenceId AND wop.[ID] = @ID

				-- Calculate parts cost (Materials)
				 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
				 SELECT @PartsCost = ISNULL(SUM(ISNULL(WOMS.[UnitCost],0) * ISNULL(WOMS.[QtyIssued],0)), 0)
				FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)
				JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsId] = WOMS.[WorkOrderMaterialsId]
				WHERE WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND WOM.[IsDeleted] = 0;

				-- Add Kit materials
				SELECT @PartsCost = @PartsCost + ISNULL(SUM(ISNULL(WOMS.[UnitCost],0) * ISNULL(WOMS.[QtyIssued],0)), 0)
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH(NOLOCK)
				JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsKitId] = WOMS.[WorkOrderMaterialsKitId]
				WHERE WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND WOM.[IsDeleted] = 0;

				-- Charges
				SELECT @MicCharges = ISNULL(SUM([ExtendedCost]),0)
				FROM [dbo].[WorkOrderCharges] WITH(NOLOCK)
				WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [IsActive] = 1 AND [IsDeleted] = 0;

				-- Freight
				SELECT @FreightCost = ISNULL(SUM([Amount]),0)
				FROM [dbo].[WorkOrderFreight] WITH(NOLOCK)
				WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [IsActive] = 1 AND [IsDeleted] = 0;

				-- Labour Cost
				SELECT TOP 1 @LabourCost = ISNULL(SUM(l.[TotalCost]), 0)
				FROM [dbo].[WorkOrderLaborHeader] lh WITH(NOLOCK)
				JOIN [dbo].[WorkOrderLabor] l WITH(NOLOCK) ON lh.[WorkOrderLaborHeaderId] = l.[WorkOrderLaborHeaderId]
				WHERE lh.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND l.BillableId = 1 AND l.[IsActive] = 1 AND l.[IsDeleted] = 0;
				
				SET @TotalCost = @PartsCost + @LabourCost + @MicCharges + @FreightCost

				INSERT INTO #SalesTaxAndOtherTaxDetails
				EXEC [dbo].[USP_GetCustomerTax_Information_Repair_WO] @WorkOrderId = @ReferenceId, @WorkOrderPartId = @ID, @CustomerId = @CustomerId, @MasterCompanyId = @MasterCompanyId
				
				SET @SalesTax = (SELECT [SalesTax] FROM #SalesTaxAndOtherTaxDetails);
				SET @OtherTax = (SELECT [OtherTax] FROM #SalesTaxAndOtherTaxDetails);
				
				IF(@SalesTax > 0)
				BEGIN
					SELECT @SalesTaxPercent = [PercentId] FROM [dbo].[Percent] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [PercentValue] = @SalesTax;					
					SET @SalesTaxAmount = (@SalesTax / 100.00) * @TotalCost
				END
				IF(@OtherTax > 0)
				BEGIN
					SELECT @OtherTaxPercent = [PercentId] FROM [dbo].[Percent] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [PercentValue] = @OtherTax;
					SET @OtherTaxAmount = (@OtherTax / 100.00) * @TotalCost
				END

				SET @GrandTotal = @TotalCost + ISNULL(@SalesTaxAmount,0) +  ISNULL(@OtherTaxAmount,0)
				
				UPDATE #TempWorkOrderPartNumberDetailsForBilling 
				   SET [WorkOrderWorkflowId] = @WorkFlowWorkOrderId,
				       [ManufacturerName] = @ManufacturerName,
					   [SerialNumber] = @SerialNumber,						  
					   [PartDescription] = @PartDescription,
					   [PartNumber] = @PartNumber,
					   [UnitPrice] = @PartsCost,
					   [QtyBilled] = 1,
					   [MaterialCost] = @PartsCost,
					   [LabourCost] = @LabourCost,
					   [MiscCharges] = @MicCharges,
					   [FreightCost] = @FreightCost,
					   [TotalCost] = @TotalCost,
					   [SalesTaxPercent] = @SalesTaxPercent,
					   [SalesTax] = @SalesTax,
					   [SalesTaxAmount] = ISNULL(@SalesTaxAmount,0),
					   [OtherTaxPercent] = @OtherTaxPercent,
				       [OtherTax] = @OtherTax,
					   [OtherTaxAmount] = ISNULL(@OtherTaxAmount,0),	
					   [GrandTotal] = @GrandTotal
				 WHERE [PKID] = @MinId;
					 
				SET @MinId = @MinId + 1;
			END

			SELECT [ReferenceId],
			       [SubReferenceId],
				   [WorkOrderWorkflowId],
				   [ItemMasterId],
				   [StockLineId],
				   [ConditionId],
				   [UnitPrice],
				   [QtyBilled],
				   [PartNumber],
				   [PartDescription],
				   [ManufacturerName],
				   [SerialNumber],
				   [MaterialCost],
				   [LabourCost],
				   [MiscCharges],
				   [FreightCost],
				   [TotalCost],
				   [SalesTaxPercent],		
				   [SalesTax],
				   [SalesTaxAmount],
				   [OtherTaxPercent],
				   [OtherTax],				   
				   [OtherTaxAmount],
				   [GrandTotal]
			  FROM #TempWorkOrderPartNumberDetailsForBilling
		END
		
	
    END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments VARCHAR(150)    = 'GetWorkOrderBillingMPNDetails'
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(250))			  
			   + '@Parameter2 = ''' + CAST(ISNULL(@SubReferenceId, '') AS VARCHAR(250))
			   + '@Parameter3 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(250))
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