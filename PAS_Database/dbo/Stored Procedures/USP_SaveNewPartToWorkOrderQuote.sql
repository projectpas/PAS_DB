/*************************************************************           
 ** File:   [dbo].[USP_SaveNewPartToWorkOrderQuote]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to add New MPN to Work Order Quote Details
 ** Purpose:         
 ** Date:   18-June-2025       
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date					Author					Change Description            
 ** --   --------				-------				--------------------------------          
    1    18-June-2025			Devendra Shekh			Created
     
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveNewPartToWorkOrderQuote]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@CreatedDate DATETIME2(7) = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRY
BEGIN TRANSACTION
	
	DECLARE @TotalRows INT = 0, @CurrentRowId INT = 0, @WorkOrderQuoteId BIGINT = 0, @WorkOrderTypeId BIGINT = 0;

	IF OBJECT_ID(N'tempdb..#tmpWorkOrderParts') IS NOT NULL
	BEGIN
		DROP TABLE #tmpWorkOrderParts
	END

	SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, TPN.[ID], WF.[WorkFlowWorkOrderId], TPN.[ItemMasterId], 0 AS [BuildMethodId], 0 AS [QuoteMethod], 0 AS [CommonFlatRate]
	INTO #tmpWorkOrderParts 
	FROM @tbl_WorkOrderPartNumberType TPN
	INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON TPN.[ID] = WF.WorkOrderPartNoId ;

	SELECT @WorkOrderQuoteId = [WorkOrderQuoteId] FROM [DBO].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
	SELECT @WorkOrderTypeId = [WorkOrderTypeId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

	IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [WorkOrderTypeId] = @WorkOrderTypeId AND [IsActive] = 1 AND [IsDeleted] = 0 AND ISNULL([IsFlatRate], 0) = 1)
	BEGIN
		UPDATE TMP
		SET	TMP.QuoteMethod = 1,
			TMP.CommonFlatRate = 0
		FROM #tmpWorkOrderParts TMP
	END
		
	IF EXISTS(SELECT 1 FROM [DBO].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId)
	BEGIN
		IF EXISTS(SELECT 1 FROM #tmpWorkOrderParts)
		BEGIN
			SELECT @TotalRows = COUNT(RowId), @CurrentRowId = MIN(RowId) FROM #tmpWorkOrderParts;

			WHILE(@TotalRows >= @CurrentRowId)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuoteDetails] WQD WITH(NOLOCK) INNER JOIN #tmpWorkOrderParts TMP ON WQD.WOPartNoId = TMP.ID WHERE TMP.RowId = @CurrentRowId)
				BEGIN
					INSERT INTO [dbo].[WorkOrderQuoteDetails] (
							[WorkOrderQuoteId], [WorkflowWorkOrderId], [ItemMasterId], [MasterCompanyId], [BuildMethodId], [WOPartNoId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [QuoteMethod], [CommonFlatRate]
							,[MaterialCost], [MaterialBilling], [MaterialRevenuePercentage], [MaterialMargin], [LaborHours], [LaborCost], [LaborBilling], [LaborRevenuePercentage], [LaborMargin], [ChargesCost], [ChargesBilling], [ChargesRevenuePercentage], 
							[ChargesMargin], [ExclusionsCost], [ExclusionsBilling], [ExclusionsRevenuePercentage], [ExclusionsMargin], [FreightCost], [FreightBilling], [FreightRevenuePercentage], [FreightMargin], [MaterialMarginPer], [LaborMarginPer],
							[ChargesMarginPer], [ExclusionsMarginPer], [FreightMarginPer], [OverHeadCost], [AdjustmentHours], [AdjustedHours], [LaborFlatBillingAmount], [MaterialFlatBillingAmount], [ChargesFlatBillingAmount], [FreightFlatBillingAmount],
							[MaterialBuildMethod], [LaborBuildMethod], [ChargesBuildMethod], [FreightBuildMethod], [ExclusionsBuildMethod], [MaterialMarkupId], [LaborMarkupId], [ChargesMarkupId], [FreightMarkupId], [ExclusionsMarkupId], [FreightRevenue],
							[LaborRevenue], [MaterialRevenue], [ExclusionsRevenue], [ChargesRevenue], [OverHeadCostRevenuePercentage], [QuoteParentId], [IsVersionIncrease], [EvalFees]
					)
					SELECT	@WorkOrderQuoteId, [WorkflowWorkOrderId], [ItemMasterId], @MasterCompanyId, [BuildMethodId], [ID], @CreatedBy, @CreatedDate, @CreatedBy, @CreatedDate, 1, 0, [QuoteMethod], [CommonFlatRate]
							,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
							0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
							0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
							0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
							0, 0, 0, 0, 0, NULL, 0, NULL
					FROM #tmpWorkOrderParts WHERE [RowId] = @CurrentRowId;
				END
				
				SET @CurrentRowId += 1;
			END
		END
	END

COMMIT  TRANSACTION
END TRY    
BEGIN CATCH      
	IF @@trancount > 0
	PRINT 'ROLLBACK'
    ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveNewPartToWorkOrderQuote' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                        '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))
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