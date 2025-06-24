/*************************************************************           
 ** File:  [GetCommonBillingMPNDetails]           
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
    2    12/05/2025   RAJESH GAMI    Added SO Part Details Code
	3    11/06/2025   RAJESH GAMI    Fix the getting wrong invoicingId (SO)
	4    17/06/2025   RAJESH GAMI    Fix the Shipping Related issue AND Proforma amount related issue
	5    17/06/2025   Moin Bloch     Add QuoteMethod
	6    19/06/2025   RAJESH GAMI    Change the logic that freight and charges add only on first stockline (Partition by SOPartId) in SO
	7    23/06/2025   Moin Bloch     checked IsFinishGood IN WO
	8    23/06/2025   Moin Bloch     Added WorkOrderShippingId IN WO
--  EXEC [dbo].[GetCommonBillingMPNDetails] 8810,8582,'',15,1
--  EXEC [dbo].[GetCommonBillingMPNDetails] 8980,8806,'',15,0,0
--  EXEC [dbo].[GetCommonBillingMPNDetails] 846,0,'1011,1012,1013',10,0
DROP PROCEDURE GetCommonBillingMPNDetails
************************************************************************/
CREATE     PROCEDURE [dbo].[GetCommonBillingMPNDetails]
@ReferenceId BIGINT=NULL,
@SubReferenceId BIGINT=NULL,
@SubReferenceIds VARCHAR(200)=NULL,
@ModuleId INT=NULL,
@IsCreatedFromQuote BIT=NULL,
@IsProformaInvoice BIT=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		DECLARE @FlatBillingMethodId INT = (select BillingMethodId from dbo.BillingMethod WITH(NOLOCK) WHERE Description = 'Flate Rate')
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		DECLARE @SoFreightBillingMethodId INT = 0, @SoChargesBillingMethodId INT = 0, @SoTotalCharges DECIMAL(10,2) = 0, @SoTotalFreight DECIMAL(10,2) = 0,@itemProformaGrandTotal DECIMAL(10,2) = 0
		DECLARE @TotalRecords INT = 0,@MinId INT = 1,@WorkOrderMPNMSModuleEnum INT=12   			 
		DECLARE @ID BIGINT = 0, @CustomerId BIGINT = 0,@MasterCompanyId INT = 0;			
		DECLARE @Partnumber VARCHAR(50)='',@ManufacturerName VARCHAR(250)='',@PartDescription NVARCHAR(MAX)='',@SerialNumber VARCHAR(100)=''
		DECLARE @WorkFlowWorkOrderId BIGINT = 0, @BillingInvoicingId BIGINT = 0, @BillingInvoicingItemId BIGINT = 0, @LabourCost DECIMAL(18,2) = 0,@UnitCostExt DECIMAL(18,2) = 0, @UnitCost DECIMAL(18,2) = 0,@PartsCost DECIMAL(18,2) = 0, @MicCharges DECIMAL(18,2) = 0, @FreightCost DECIMAL(18,2) = 0;
		DECLARE @TotalCost DECIMAL(18,2) = 0, @SalesTax DECIMAL(18,2) = 0, @OtherTax DECIMAL(18,2) = 0, @SalesTaxPercent BIGINT = 0, @OtherTaxPercent BIGINT = 0, @SalesTaxAmount DECIMAL(18,2) = 0, @OtherTaxAmount DECIMAL(18,2) = 0, @GrandTotal DECIMAL(18,2) = 0;
		DECLARE @WorkOrderTypeId INT=0,@AllowInvoiceBeforeShipping BIT=0,@WorkOrderShippingId BIGINT = 0 

		IF(@SubReferenceIds = '')
		BEGIN
			SET @SubReferenceIds = NULL;
		END
		IF(@IsProformaInvoice = NULL)
		BEGIN
			SET @IsProformaInvoice = 0;
		END

		IF OBJECT_ID(N'tempdb..#TempWithRowNum') IS NOT NULL
		BEGIN
			DROP TABLE #TempWithRowNum
		END

		IF OBJECT_ID(N'tempdb..#TempCommonPartNumberDetailsForBilling') IS NOT NULL
		BEGIN
			DROP TABLE #TempCommonPartNumberDetailsForBilling
		END

			CREATE TABLE #TempCommonPartNumberDetailsForBilling
			(		
				[PKID] BIGINT NOT NULL IDENTITY, 
				[ReferenceId] BIGINT NULL,
				[SubReferenceId] BIGINT NULL,
				[WorkOrderWorkflowId] BIGINT NULL, 
				[BillingInvoicingId] BIGINT NULL, 
				[BillingInvoicingItemId] BIGINT NULL, 
				[WorkOrderShippingId]  BIGINT NULL, 
				[ItemMasterId] BIGINT NULL,	
				[StockLineId] BIGINT NULL,
				[ConditionId] BIGINT NULL,
				[UnitPrice] DECIMAL(18,2) NULL,	 
				[QtyBilled] INT NULL, 
				[PartCost] DECIMAL(18,2) NULL,	 
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
				[GrandTotal] DECIMAL(18,2) NULL,
				[SOStockLineId] BIGINT NULL,
				[StockLineNumber] VARCHAR(200) NULL,
				[QuoteMethod] BIT NULL,
			)

		IF(@ModuleId = @WOModuleId) /*START: WORK ORDER ********/
		BEGIN
			SELECT @WorkOrderMPNMSModuleEnum = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN'

			SELECT @CustomerId = WO.[CustomerId],@WorkOrderTypeId = [WorkOrderTypeId], @MasterCompanyId = WO.[MasterCompanyId] FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.[WorkOrderId] = @ReferenceId;
			
			SELECT @AllowInvoiceBeforeShipping = ISNULL([AllowInvoiceBeforeShipping],0) FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId]=@WorkOrderTypeId AND [MasterCompanyId]=@MasterCompanyId

			IF(@IsProformaInvoice = 0)
			BEGIN
				INSERT INTO #TempCommonPartNumberDetailsForBilling([ReferenceId],[SubReferenceId],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[SerialNumber]) 
															   SELECT [WorkOrderId],[ID],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[CurrentSerialNumber]
				FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) 
				WHERE [WorkOrderId] = @ReferenceId 
				  AND (@AllowInvoiceBeforeShipping = 1 AND ISNULL([IsFinishGood], 0) = 1 OR @AllowInvoiceBeforeShipping = 0)
				  AND (@SubReferenceIds IS NULL OR [ID] IN (SELECT Item FROM DBO.SPLITSTRING(@SubReferenceIds,',')))                
				  AND [IsDeleted] = 0 
				ORDER BY [ID]	
			END
			ELSE
			BEGIN
				INSERT INTO #TempCommonPartNumberDetailsForBilling([ReferenceId],[SubReferenceId],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[SerialNumber]) 
															   SELECT [WorkOrderId],[ID],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[CurrentSerialNumber]
				FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) 
				WHERE [WorkOrderId] = @ReferenceId 
				  AND (@SubReferenceIds IS NULL OR [ID] IN (SELECT Item FROM DBO.SPLITSTRING(@SubReferenceIds,',')))                
				  AND [IsDeleted] = 0 
				ORDER BY [ID]	
			END
		
		    SELECT @TotalRecords = COUNT(*), @MinId = MIN([PKID]) FROM #TempCommonPartNumberDetailsForBilling    
			
			WHILE @MinId <= @TotalRecords
			BEGIN
				SET @WorkFlowWorkOrderId = 0;
				SET @BillingInvoicingId = 0;
				SET @BillingInvoicingItemId = 0;
				SET @WorkOrderShippingId = 0;
				SET @LabourCost = 0;
				SET @PartsCost = 0;
				SET @MicCharges = 0;
				SET @FreightCost = 0;
				SET @TotalCost = 0;
				SET @SalesTax = 0;
				SET @OtherTax = 0;
				SET @SalesTaxPercent = 0;
				SET @OtherTaxPercent = 0;
				SET @SalesTaxAmount = 0;
				SET @OtherTaxAmount = 0;
				SET @GrandTotal = 0;
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

				SELECT @ID = [SubReferenceId] FROM #TempCommonPartNumberDetailsForBilling WHERE [PKID] = @MinId;	
				
				SELECT @WorkFlowWorkOrderId = (SELECT TOP 1 [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @ID)

				IF(ISNULL(@IsCreatedFromQuote,0) = 0)
				BEGIN				
					SELECT TOP 1
				  		   @PartNumber = CASE WHEN wop.[RevisedPartNumber] IS NOT NULL AND wop.[RevisedPartNumber] <> '' THEN wop.[RevisedPartNumber] ELSE im.[PartNumber] END,
						   @ManufacturerName = im.[ManufacturerName],
						   @PartDescription = CASE WHEN wop.[RevisedPartDescription] IS NOT NULL AND wop.[RevisedPartDescription] <> '' THEN wop.[RevisedPartDescription] ELSE im.[PartDescription] END,
						   @SerialNumber = CASE WHEN wop.[RevisedSerialNumber] IS NOT NULL AND wop.[RevisedSerialNumber] <> '' THEN wop.[RevisedSerialNumber] ELSE sl.[SerialNumber] END,
						   @BillingInvoicingId = boi.[BillingInvoicingId],
						   @BillingInvoicingItemId = boi.[BillingInvoicingItemId],
						   @WorkOrderShippingId = wos.[WorkOrderShippingId]
						FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
						INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON wop.[StockLineId] = sl.[StockLineId]
						INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.[ItemMasterId] = im.[ItemMasterId]	
						 LEFT JOIN [dbo].[BillingInvoicingItems] boi WITH(NOLOCK) ON wop.[ID] = boi.[SubReferenceId] AND wop.[WorkOrderId] = boi.[ReferenceId] AND ISNULL(boi.[IsVersionIncrease],0) = 0 AND ISNULL(boi.[IsPerformaInvoice],0) = @IsProformaInvoice AND boi.[ModuleId] = @WOModuleId  
						 LEFT JOIN [dbo].[WorkOrderShippingItem] wos WITH(NOLOCK) ON wop.[ID] = wos.[WorkOrderPartNumId] AND wos.[IsDeleted] = 0 
						WHERE wop.[WorkOrderId] = @ReferenceId AND wop.[ID] = @ID
									   
					-- Calculate parts cost (Materials)
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
				
					UPDATE #TempCommonPartNumberDetailsForBilling 
					   SET [WorkOrderWorkflowId] = @WorkFlowWorkOrderId,
						   [BillingInvoicingId] = @BillingInvoicingId,
						   [BillingInvoicingItemId] = @BillingInvoicingItemId,
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
						   [GrandTotal] = @GrandTotal,
						   [WorkOrderShippingId] = @WorkOrderShippingId
					 WHERE [PKID] = @MinId;

				END
				ELSE
				BEGIN
					DECLARE @QuoteMethod BIT = 0; 
					DECLARE @FlatRate DECIMAL(18,2) = 0;
					DECLARE @MaterialFlatBillingAmount DECIMAL(18,2) = 0;
					DECLARE @LaborFlatBillingAmount    DECIMAL(18,2) = 0;
					DECLARE @ChargesFlatBillingAmount  DECIMAL(18,2) = 0;
					DECLARE @FreightFlatBillingAmount  DECIMAL(18,2) = 0;

					SELECT 
					 @PartNumber = IM.[PartNumber],					
					 @ManufacturerName = IM.[ManufacturerName],
					 @PartDescription = IM.[PartDescription],
					 @SerialNumber = wop.[RevisedSerialNumber],
					 @BillingInvoicingId = boi.[BillingInvoicingId],
					 @BillingInvoicingItemId = boi.[BillingInvoicingItemId],		
					 @WorkOrderShippingId = wos.[WorkOrderShippingId],
					 @MaterialFlatBillingAmount = CASE WHEN ISNULL(wqd.[MaterialBuildMethod],0) = 3 THEN ISNULL(wqd.[MaterialFlatBillingAmount],0) ELSE ISNULL(wqd.[MaterialRevenue],0) END,
					 @LaborFlatBillingAmount = CASE WHEN ISNULL(wqd.[LaborBuildMethod],0) = 3 THEN ISNULL(wqd.[LaborFlatBillingAmount],0) ELSE ISNULL(wqd.[LaborRevenue],0) END,
					 @ChargesFlatBillingAmount = CASE WHEN ISNULL(wqd.[ChargesBuildMethod],0) = 3 THEN ISNULL(wqd.[ChargesFlatBillingAmount],0) ELSE ISNULL(wqd.[ChargesRevenue],0) END,
					 @FreightFlatBillingAmount = CASE WHEN ISNULL(wqd.[FreightBuildMethod],0) = 3 THEN ISNULL(wqd.FreightFlatBillingAmount,0) ELSE ISNULL(wqd.FreightRevenue,0) END,					 
					 @QuoteMethod = WQD.[QuoteMethod],
					 @FlatRate = WQD.[CommonFlatRate]					 
					FROM [dbo].[WorkOrderQuoteDetails] WQD  WITH(NOLOCK) 				
					LEFT JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WOQ.[WorkOrderQuoteId] = WQD.[WorkOrderQuoteId]
					LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.[WorkOrderId] = WOQ.[WorkOrderId]
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = WQD.[ItemMasterId]
					LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.[ID]  = WQD.[WOPartNoId] 
					LEFT JOIN [dbo].[BillingInvoicingItems] boi WITH(NOLOCK) ON wop.[ID] = boi.[SubReferenceId] AND wop.[WorkOrderId] = boi.[ReferenceId] AND ISNULL(boi.[IsVersionIncrease],0) = 0 AND ISNULL(boi.[IsPerformaInvoice],0) = @IsProformaInvoice AND boi.[ModuleId] = @WOModuleId  
					LEFT JOIN [dbo].[WorkOrderShippingItem] wos WITH(NOLOCK) ON wop.[ID] = wos.[WorkOrderPartNumId] AND wos.[IsDeleted] = 0 
					WHERE WQD.[WorkflowWorkOrderId] = @WorkFlowWorkOrderId AND WQD.[WOPartNoId] = @ID AND WQD.[IsVersionIncrease] = 0

				IF(@QuoteMethod = 1)
				BEGIN
					SET @PartsCost = 0;					
					SET @LabourCost = 0;
					SET @MicCharges = 0;
				    SET @FreightCost = 0;
					SET @TotalCost = @FlatRate;

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
				END
				ELSE
				BEGIN
					SET @PartsCost = @MaterialFlatBillingAmount;
					SET @LabourCost = @LaborFlatBillingAmount;
					SET @MicCharges = @ChargesFlatBillingAmount;
				    SET @FreightCost = @FreightFlatBillingAmount;					
					SET @TotalCost = @PartsCost + @LabourCost + @MicCharges + @FreightCost;

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

					SET @GrandTotal = @TotalCost + ISNULL(@SalesTaxAmount,0) +  ISNULL(@OtherTaxAmount,0);
				END				

				UPDATE #TempCommonPartNumberDetailsForBilling 
					   SET [WorkOrderWorkflowId] = @WorkFlowWorkOrderId,
						   [BillingInvoicingId] = @BillingInvoicingId,
						   [BillingInvoicingItemId] = @BillingInvoicingItemId,
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
						   [GrandTotal] = @GrandTotal,
						   [QuoteMethod] = @QuoteMethod,
						   [WorkOrderShippingId] = @WorkOrderShippingId
					 WHERE [PKID] = @MinId;

				END
					 
				SET @MinId = @MinId + 1;
			END
			
		END /*END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId) /****************** START: SALES ORDER ********************/
		BEGIN
			
			INSERT INTO #TempCommonPartNumberDetailsForBilling([ReferenceId],[SubReferenceId],[ItemMasterId],[StockLineId],[ConditionId],[PartNumber],[PartDescription],[ManufacturerName],[SerialNumber],SOStockLineId,QtyBilled,StockLineNumber) 
				                                           SELECT Sop.SalesOrderId,Sop.[SalesOrderPartId],SOP.[ItemMasterId],STK.[StockLineId],STK.[ConditionId],SOP.[PartNumber],[PartDescription],SL.[Manufacturer],SL.[SerialNumber],STK.SalesOrderStocklineId,STK.QtyOrder,Sl.StockLineNumber

			FROM [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK) 
				 INNER JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId 
				 LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
				 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
			WHERE SOP.SalesOrderId = @ReferenceId  
			  AND (@SubReferenceIds IS NULL OR SOP.SalesOrderPartId IN (SELECT Item FROM DBO.SPLITSTRING(@SubReferenceIds,',')))                
			  AND ISNULL(SOP.IsDeleted,0) = 0 AND  (( (@IsProformaInvoice = 1 AND ISNULL(SOP.QtyReserved, 0) >= 0) OR (@IsProformaInvoice != 1 AND ISNULL(STK.QtyReserved, 0) > 0)) 
			  OR ((SELECT SUM(ISNULL(sopi.QtyShipped,0)) FROM dbo.SalesOrderShippingItem sopi WITH(NOLOCK) WHERE  sopi.SalesOrderPartId = SOP.SalesOrderPartId and SOPI.IsActive = 1 AND ISNULL(SOPI.IsDeleted,0) = 0)) > 0
			  )
			ORDER BY SOP.SalesOrderPartId	
	
			SELECT @CustomerId = SO.[CustomerId],@MasterCompanyId = SO.[MasterCompanyId], 
				  @SoFreightBillingMethodId = ISNULL(FreightBilingMethodId,0), @SoChargesBillingMethodId = ISNULL(ChargesBilingMethodId,0),
				  @SoTotalCharges = ISNULL(TotalCharges,0), @SoTotalFreight = ISNULL(TotalFreight,0)
			FROM [dbo].[SalesOrder] SO WITH(NOLOCK) WHERE SO.[SalesOrderId] = @ReferenceId;
		    
			SELECT @TotalRecords = COUNT(*), @MinId = MIN([PKID]) FROM #TempCommonPartNumberDetailsForBilling    

			WHILE @MinId <= @TotalRecords
			BEGIN
				DECLARE @SOFlatRate DECIMAL(18,2) = 0; 
				DECLARE @stocklineID BIGINT = 0,@SOStocklineId BIGINT = 0;
				DECLARE @SOChargesAmount  DECIMAL(18,2) = CASE WHEN @SoChargesBillingMethodId = @FlatBillingMethodId THEN @SoTotalCharges ELSE 0 END;
				DECLARE @SOFreightAmount  DECIMAL(18,2) = CASE WHEN @SoFreightBillingMethodId = @FlatBillingMethodId THEN @SoTotalFreight ELSE 0 END;

				SET @BillingInvoicingId = 0;
				SET @BillingInvoicingItemId = 0;
				SET @TotalCost = 0;
				SET @SalesTax = 0;
				SET @OtherTax = 0;
				SET @SalesTaxPercent = 0;
				SET @OtherTaxPercent = 0;
				SET @SalesTaxAmount = 0;
				SET @OtherTaxAmount = 0;
				SET @GrandTotal = 0;			

				IF OBJECT_ID(N'tempdb..#tblSalesTaxAndOtherTaxDetails') IS NOT NULL
				BEGIN
					DROP TABLE #tblSalesTaxAndOtherTaxDetails
				END
	
				CREATE TABLE #tblSalesTaxAndOtherTaxDetails
				(
					[ID] BIGINT NOT NULL IDENTITY,
					[SalesTax] DECIMAL(18,2) NULL,
					[OtherTax]  DECIMAL(18,2) NULL				
				)		
				SELECT @ID = [SubReferenceId], @stocklineID = StockLineId,@SOStocklineId = SOStockLineId FROM #TempCommonPartNumberDetailsForBilling WHERE [PKID] = @MinId;	
				SELECT TOP 1 @BillingInvoicingId = BI.BillingInvoicingId, @BillingInvoicingItemId = BII.BillingInvoicingItemId,@itemProformaGrandTotal = ISNULL(BII.GrandTotal,0)  FROM #TempCommonPartNumberDetailsForBilling cpd   
							INNER JOIN dbo.BillingInvoicing BI WITH (NOLOCK) ON BI.ReferenceId = cpd.ReferenceId AND BI.ModuleId = @ModuleId AND ISNULL(Bi.IsVersionIncrease,0) = 0
							INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK) ON BI.BillingInvoicingId = BII.BillingInvoicingId AND BII.ItemMasterId = CPD.ItemMasterId AND BII.ConditionId = CPD.ConditionId AND cpd.StockLineId = BII.StocklineId
							
							WHERE cpd.ReferenceId = @ReferenceId  AND ISNULL(Bi.IsVersionIncrease,0) = 0 AND [PKID] = @MinId AND ISNULL(BI.IsPerformaInvoice,0) = ISNULL(@IsProformaInvoice,0);	
				
				IF(@SoChargesBillingMethodId != 0 AND @SoChargesBillingMethodId != @FlatBillingMethodId)
				BEGIN
					SET @SOChargesAmount = ISNULL((SELECT SUM(ISNULL(BillingAmount,0)) FROM Dbo.SalesOrderCharges WHERE SalesOrderPartId = @ID AND ISNULL(IsDeleted,0) = 0),0.0)
				END
				IF(@SoFreightBillingMethodId != 0 AND @SoFreightBillingMethodId != @FlatBillingMethodId)
				BEGIN
					SET @SOFreightAmount = ISNULL((SELECT SUM(ISNULL(BillingAmount,0)) FROM Dbo.SalesOrderFreight WHERE SalesOrderPartId = @ID AND ISNULL(IsDeleted,0) = 0),0.0)
				END
				--SET @UnitCost = (SELECT SUM(ISNULL(NetSaleAmountPerUnit,0)) FROM dbo.SalesOrderStocklineCost WHERE SalesOrderStocklineId = @SOStocklineId)
				 SELECT @UnitCost = SUM(ISNULL(NetSaleAmountPerUnit,0)), @UnitCostExt = SUM(ISNULL(NetSaleAmount,0))  FROM dbo.SalesOrderStocklineCost WHERE SalesOrderStocklineId = @SOStocklineId
				--SET @PartsCost = (SELECT SUM(ISNULL(NetSaleAmount,0)) FROM dbo.SalesOrderStocklineCost WHERE SalesOrderStocklineId = @SOStocklineId)
				--SET @PartsCost = ISNULL(@UnitCost,0.0) * ISNULL((Select QtyReserved From dbo.SalesOrderPartV1 WITH(NOLOCK) Where SalesOrderPartId = @ID),0.0)
				DECLARE @stkShipped decimal(10,2) = ISNULL((Select SUM(ISNULL(QtyShipped,0)) From dbo.SalesOrderShippingItem SOS WITH(NOLOCK) INNER JOIN dbo.SOPickTicket SOPIC WITH(NOLOCK) on SOS.SOPickTicketId = SOPIC.SOPickTicketId
															Where SOS.SalesOrderPartId =  @ID AND  SOS.IsActive = 1 AND ISNULL(SOS.IsDeleted,0) = 0 AND  SOPIC.SalesOrderPartStocklineId = @SOStocklineId),0.0)
				DECLARE @stkReservedQty decimal(10,2) =  ISNULL((Select ISNULL(QtyReserved,0) From dbo.SalesOrderStocklineV1 WITH(NOLOCK) Where StockLineId = @stocklineID AND SalesOrderPartId =  @ID),0.0)
				DECLARE @totalQtyShippedReserved decimal(10,2) = ISNULL(@stkShipped,0.0) + ISNULL(@stkReservedQty,0.0)
				PRINT @totalQtyShippedReserved
				PRINT '@totalQtyShippedReserved'
				SET @PartsCost = CASE WHEN @IsProformaInvoice = 1 AND @BillingInvoicingItemId >0 THEN @itemProformaGrandTotal WHEN @IsProformaInvoice = 1 AND ISNULL(@BillingInvoicingItemId,0)  = 0  THEN @UnitCostExt ELSE ISNULL(@UnitCost,0.0) * @totalQtyShippedReserved END
				SET @TotalCost = CASE WHEN @IsProformaInvoice = 1 THEN @PartsCost ELSE @PartsCost + @SOChargesAmount + @SOFreightAmount END
					
				--IF(@IsProformaInvoice = 1)
				--BEGIN
				--	SET @SalesTax = 0;
				--	SET @OtherTax = 0;
				--END
				--ELSE
				--BEGIN	
				--	INSERT INTO #tblSalesTaxAndOtherTaxDetails
				--	EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale_SO_New] @SalesOrderId = @ReferenceId, @SalesOrderPartId = @ID, @CustomerId = @CustomerId
				--	SET @SalesTax = (SELECT [SalesTax] FROM #tblSalesTaxAndOtherTaxDetails);
				--	SET @OtherTax = (SELECT [OtherTax] FROM #tblSalesTaxAndOtherTaxDetails);
				--END

				INSERT INTO #tblSalesTaxAndOtherTaxDetails
					EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale_SO_New] @SalesOrderId = @ReferenceId, @SalesOrderPartId = @ID, @CustomerId = @CustomerId
					SET @SalesTax = (SELECT [SalesTax] FROM #tblSalesTaxAndOtherTaxDetails);
					SET @OtherTax = (SELECT [OtherTax] FROM #tblSalesTaxAndOtherTaxDetails);
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

				UPDATE #TempCommonPartNumberDetailsForBilling 
					   SET 
						   [UnitPrice] = @UnitCost,
						   PartCost = CASE WHEN @IsProformaInvoice = 1 THEN @UnitCostExt ELSE @PartsCost END,
						   [BillingInvoicingId] = @BillingInvoicingId,
						   [BillingInvoicingItemId] = @BillingInvoicingItemId,
						   [MiscCharges] = @SOChargesAmount,
						   [FreightCost] = @SOFreightAmount,
						   [TotalCost] = ISNULL(@TotalCost,0),
						   [SalesTaxPercent] = @SalesTaxPercent,
						   [SalesTax] = ISNULL(@SalesTax,0),
						   [SalesTaxAmount] = ISNULL(@SalesTaxAmount,0),
						   [OtherTaxPercent] = @OtherTaxPercent,
						   [OtherTax] = ISNULL(@OtherTax,0),
						   [OtherTaxAmount] = ISNULL(@OtherTaxAmount,0),	
						   [GrandTotal] = @GrandTotal
					 WHERE [PKID] = @MinId;
					 SET @MinId = @MinId + 1;
			END /****** END OF WHILE LOOP ********/
		END /**END: SALES ORDER ************************/


		/********** Final Get Query From the Temp Table *************/
		SELECT  ROW_NUMBER() OVER (PARTITION BY SubReferenceId ORDER BY PKID) AS RowNum,* INTO #TempWithRowNum FROM #TempCommonPartNumberDetailsForBilling;
		IF(@ModuleId = @SOModuleId AND @IsProformaInvoice = 0)
		BEGIN
			UPDATE #TempWithRowNum SET MiscCharges = 0, FreightCost = 0, 
									   TotalCost = CASE WHEN (ISNULL(TotalCost,0) - (ISNULL(MiscCharges,0) + ISNULL(FreightCost,0))) >= 0 THEN (ISNULL(TotalCost,0) - (ISNULL(MiscCharges,0) + ISNULL(FreightCost,0))) ELSE 0 END  WHERE RowNum > 1

			Update #TempWithRowNum SET SalesTaxAmount = CASE WHEN SalesTax > 0 THEN (SalesTax / 100.00) * TotalCost ELSE 0 END, OtherTaxAmount = CASE WHEN OtherTax > 0 THEN (OtherTax / 100.00) * TotalCost ELSE 0 END WHERE RowNum > 1

			UPDATE #TempWithRowNum SET GrandTotal = TotalCost + SalesTaxAmount + OtherTaxAmount  WHERE RowNum > 1
		END
		SELECT * FROM #TempWithRowNum
	  --SELECT *  FROM #TempCommonPartNumberDetailsForBilling
	
    END TRY    
	BEGIN CATCH
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments VARCHAR(150)    = 'GetCommonBillingMPNDetails'
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
	END CATCH
END