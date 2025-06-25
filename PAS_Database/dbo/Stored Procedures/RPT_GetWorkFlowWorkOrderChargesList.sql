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
@MasterCompanyId INT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		--DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
	
		--SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		--SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		--SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	
		--IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		--BEGIN	
		--  DECLARE @WorkOrderFormTypeId BIT = 0,@IsCreatedFromQuote BIT=0 	
			
		--	DECLARE @TotalRecords INT = 0,@MinId INT = 1
		--	SELECT @WorkOrderId = BII.[ReferenceId],@MasterCompanyId = [MasterCompanyId],@IsCreatedFromQuote = ISNULL([IsCreatedFromQuote],0) FROM [dbo].[BillingInvoicing] BII WITH(NOLOCK) WHERE BII.[BillingInvoicingId] = @BillingInvoicingId;
		--	SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
			
		--	IF OBJECT_ID(N'tempdb..#TempWorkFlowWorkOrderChargesListForBilling') IS NOT NULL
		--	BEGIN
		--		DROP TABLE #TempWorkFlowWorkOrderChargesListForBilling
		-- 	END

		--	IF OBJECT_ID(N'tempdb..#TempWorkFlowWorkOrderChargesListForBillingItems') IS NOT NULL
		--	BEGIN
		--		DROP TABLE #TempWorkFlowWorkOrderChargesListForBillingItems
		-- 	END

		--	CREATE TABLE #TempWorkFlowWorkOrderChargesListForBilling
		--	(		
		--		[PKID] BIGINT NOT NULL IDENTITY, 	
		--		[ReferenceId] BIGINT NULL,
		--		[SubReferenceId] BIGINT NULL,	
		--		[WorkFlowWorkOrderId] BIGINT NULL,	
		--		[ItemMasterId] BIGINT NULL,					
		--		[PartNumber] VARCHAR(50) NULL,				
		--	)			

		--	CREATE TABLE #TempWorkFlowWorkOrderChargesListForBillingItems
		--	(
		--		[PartNumber] VARCHAR(50) NULL,					
		--		[SubReferenceId] BIGINT NULL,	
		--		[TaskName] VARCHAR(200) NULL,
		--		[ChargeType] VARCHAR(256) NULL,
		--		[UnitCost] DECIMAL(18,2) NULL,	
		--		[Quantity] INT NULL,
		--		[ExtendedCost] DECIMAL(18,2) NULL
		--	)

		--	INSERT INTO #TempWorkFlowWorkOrderChargesListForBilling([ReferenceId],[SubReferenceId],[WorkFlowWorkOrderId],[ItemMasterId],[PartNumber]) 
		--												 SELECT BII.[ReferenceId],BII.[SubReferenceId],BII.[WorkFlowWorkOrderId],BII.[ItemMasterId],itm.[partnumber]
		--	FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) 
		--	INNER JOIN [dbo].[ItemMaster] ITM ON BII.[ItemMasterId] = ITM.[ItemMasterId]
		--	WHERE BII.[BillingInvoicingId] = @BillingInvoicingId	
			
  --		    SELECT @TotalRecords = COUNT(*), @MinId = MIN([PKID]) FROM #TempWorkFlowWorkOrderChargesListForBilling    
			
		--	WHILE @MinId <= @TotalRecords
		--	BEGIN
		--		DECLARE @WorkFlowWorkOrderId BIGINT = 0,@SubReferenceId BIGINT = 0,@PartNumber VARCHAR(50)=''
				
		--		SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId],
		--		       @SubReferenceId = [SubReferenceId], 
		--			   @PartNumber = [PartNumber]
		--	      FROM #TempWorkFlowWorkOrderChargesListForBilling WHERE [PKID] = @MinId;
				
		--		INSERT INTO #TempWorkFlowWorkOrderChargesListForBillingItems([PartNumber],[SubReferenceId],[TaskName],[ChargeType],[UnitCost],[Quantity],[ExtendedCost])
		--		SELECT	@PartNumber [PartNumber],
		--		        @SubReferenceId [SubReferenceId], 
		--		        CASE WHEN @WorkOrderFormTypeId = 1 THEN UPPER(ISNULL(WOT.[TaskName],''))  ELSE UPPER(ISNULL(ts.[Description],'')) END [TaskName],
		--				UPPER(ct.[ChargeType]) [ChargeType],
		--				ISNULL(woc.[UnitCost],0) [UnitCost],
		--				ISNULL(woc.[Quantity],0) [Quantity],
		--				CASE WHEN @IsCreatedFromQuote = 1 THEN 0 ELSE ISNULL(woc.[ExtendedCost],0) END  [ExtendedCost]	
		--			FROM [dbo].[WorkOrderCharges] woc WITH(NOLOCK)				
		--				JOIN [dbo].[Charge] ct WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId
		--				LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
		--				LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
		--				LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = woc.TaskId
		--				LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId	
		--				LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON woc.UOMId = uom.UnitOfMeasureId
		--			WHERE woc.[IsDeleted] = 0 AND woc.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND woc.[MasterCompanyId]=@MasterCompanyId

		--		SET @MinId = @MinId + 1;
		--	END

		--	SELECT * FROM #TempWorkFlowWorkOrderChargesListForBillingItems

		--END
		     DECLARE @WOModuleId INT
	
	        SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

			DECLARE @WorkOrderFormTypeId BIT = 0; 			

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
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
					 LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
					 LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
					 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = woc.TaskId
					 LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId	
					 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON woc.UOMId = uom.UnitOfMeasureId
					 LEFT JOIN [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK) ON WOF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					 LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.ID = WOF.WorkOrderPartNoId
					 LEFT JOIN [dbo].[BillingInvoicingItems] BII WITH(NOLOCK) ON WOP.ID = BII.SubReferenceId AND WOP.WorkOrderId = BII.ReferenceId AND ISNULL(BII.IsVersionIncrease,0) = 0 AND ISNULL(BII.IsPerformaInvoice,0) = 0 AND BII.ModuleId = @WOModuleId
				     LEFT JOIN [dbo].[Percent] PER WITH(NOLOCK) ON BII.MiscChargesCostPercent = PER.PercentId AND BII.ModuleId = @WOModuleId
				WHERE woc.IsDeleted = 0 AND woc.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND woc.MasterCompanyId=@masterCompanyId
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