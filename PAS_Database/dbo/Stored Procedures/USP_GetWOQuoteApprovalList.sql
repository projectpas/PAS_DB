/*************************************************************             
 ** File: [USP_GetWOQuoteApprovalList]             
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get WO Quote Approval List
 ** Purpose:           
 ** Date:   25/08/2025             
 ** PARAMETERS: @WorkOrderQuoteId bigint             
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------		--------------------------------            
    1	 25/08/2025   Moin Bloch		 Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	EXEC [dbo].[USP_GetWOQuoteApprovalList] 7832
************************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetWOQuoteApprovalList]  
@WorkOrderQuoteId BIGINT  
AS  
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
		BEGIN TRY  

		DECLARE @ApprovalTaskId BIGINT = 0
		DECLARE @IsInternalApprove BIT = 1
		DECLARE @WorkOrderId BIGINT = 0
		DECLARE @MasterCompanyId INT = 0
		DECLARE @WorkOrderTypeId BIGINT = 0
		DECLARE @QuoteTotalsFlat DECIMAL(18,2) = 0
		DECLARE @QuoteTotals DECIMAL(18,2) = 0
		DECLARE @TotalQuote DECIMAL(18,2) = 0
		
		IF OBJECT_ID(N'tempdb..#tmprGetWOQuoteApprovalList') IS NOT NULL
		BEGIN
			DROP TABLE #tmprGetWOQuoteApprovalList
		END

		SELECT @ApprovalTaskId  = [ApprovalTaskId] FROM [dbo].[ApprovalTask] WITH(NOLOCK) WHERE [Name] = 'WO Quote Approval';
		 
		CREATE TABLE #tmprGetWOQuoteApprovalList
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[ApproverId] BIGINT NULL,
			[ApproverName] VARCHAR(100) NULL,
			[ApproverCode] VARCHAR(50) NULL,
			[ApproverEmail] VARCHAR(200) NULL,
			[TotalCost] DECIMAL(18,2) NULL,
			[Rule] VARCHAR(500) NULL,
			[Memo] NVARCHAR(MAX) NULL,
			[Message] NVARCHAR(500) NULL,
			[IsExceeded] BIT NULL,	
			[ApproverEmails] VARCHAR(500) NULL		
		)
		
		INSERT INTO #tmprGetWOQuoteApprovalList
		EXEC [dbo].[usp_GetApprovalListByTaskId] @ApprovalTaskId,@WorkOrderQuoteId
		
		IF EXISTS (SELECT 1 FROM #tmprGetWOQuoteApprovalList WHERE [IsExceeded] = 0)
		BEGIN
			SET @IsInternalApprove = 1;
		END
		
		SELECT @WorkOrderId = [WorkOrderId], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @workOrderQuoteId;

		SELECT @WorkOrderTypeId = [WorkOrderTypeId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
		--NOT  IN USE
	    --SELECT TOP 1 * FROM dbo.WorkOrderQuoteSettings WQS WHERE WQS.IsActive = 1 AND WQS.IsDeleted = 0 AND WQS.MasterCompanyId = @MasterCompanyId AND WQS.WorkOrderTypeId = @WorkOrderTypeId;

		SELECT @QuoteTotalsFlat = SUM(ISNULL([MaterialFlatBillingAmount], 0) + ISNULL([LaborFlatBillingAmount], 0) + ISNULL([ChargesFlatBillingAmount], 0)) 
		FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK)
		WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId
		  AND [IsVersionIncrease] = 0
		  AND ([QuoteMethod] IS NULL OR [QuoteMethod] = 0);

		SELECT @QuoteTotals = SUM(ISNULL([CommonFlatRate], 0))
		FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK)
		WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId
		  AND [IsVersionIncrease] = 0
		  AND [QuoteMethod] = 1;

		SET @TotalQuote = ISNULL(@QuoteTotals,0) + ISNULL(@QuoteTotalsFlat,0)

		IF(@TotalQuote = 0)
		BEGIN
			SET @IsInternalApprove = 0;
		END

		IF EXISTS (SELECT 1 FROM #tmprGetWOQuoteApprovalList)
		BEGIN
			SET @IsInternalApprove = 1;
		END

		SELECT DISTINCT
		wop.[ID],
		IM.[PartNumber],
		IM.[PartDescription],
		IM.[ManufacturerName],		
		ST.[Stage],
		WOP.[WorkOrderStageId],
		STL.[StockLineNumber],
		STL.[SiteId],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[MaterialCost],0) END [PartsCost],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[MaterialRevenuePercentage],0) END [PartsRevPercentage],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[LaborCost],0) END [TotalLaborCost],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[LaborCost],0) END [LaborCost],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[LaborRevenuePercentage],0) END [LaborRevPercentage],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[OverHeadCost],0) END [OverHeadCost],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[OverHeadCostRevenuePercentage],0) END [OverHeadPercentage],
		CASE WHEN WOC.[QuoteMethod] = 1 THEN 0 ELSE ISNULL(WOC.[ChargesCost],0) END [ChargesCost],
		ISNULL(WOC.[FreightCost],0) [FreightCost],
		ISNULL(WOC.[FreightFlatBillingAmount],0) [FreightFlatBillingAmount],
		WOQ.[VersionNo],
		CASE WHEN woc.[QuoteMethod] = 1 THEN 0 ELSE (ISNULL(WOC.[MaterialCost],0) + ISNULL(WOC.[LaborCost],0) + ISNULL(WOC.[ChargesCost],0)) END [DirectCost],
		CASE WHEN woc.[QuoteMethod] = 1 THEN 0 ELSE [dbo].[RevenuePercentage]((ISNULL(WOC.[MaterialCost],0) + ISNULL(WOC.[LaborCost],0) + ISNULL(WOC.[ChargesCost],0)),(ISNULL(WOC.[MaterialFlatBillingAmount],0) + ISNULL(WOC.[LaborFlatBillingAmount],0) + ISNULL(WOC.[ChargesFlatBillingAmount],0))) END [DirectCostPercentage],
		CASE WHEN woc.[QuoteMethod] = 1 THEN ISNULL(WOC.[CommonFlatRate],0) ELSE (ISNULL(WOC.[MaterialFlatBillingAmount],0) + ISNULL(WOC.[LaborFlatBillingAmount],0) + ISNULL(WOC.[ChargesFlatBillingAmount],0)) END [Revenue],
		CASE WHEN woc.[QuoteMethod] = 1 THEN 0 ELSE ((ISNULL(WOC.[MaterialFlatBillingAmount],0) + ISNULL(WOC.[LaborFlatBillingAmount],0) + ISNULL(WOC.[ChargesFlatBillingAmount],0)) - (ISNULL(WOC.[MaterialCost],0) + ISNULL(WOC.[LaborCost],0) + ISNULL(WOC.[ChargesCost],0))) END [Margin],
		CASE WHEN woc.[QuoteMethod] = 1 THEN 0 ELSE [dbo].[RevenuePercentage](((ISNULL(WOC.[MaterialFlatBillingAmount],0) + ISNULL(WOC.[LaborFlatBillingAmount],0) + ISNULL(WOC.[ChargesFlatBillingAmount],0)) - (ISNULL(WOC.[MaterialCost],0) + ISNULL(WOC.[LaborCost],0) + ISNULL(WOC.[ChargesCost],0))),(ISNULL(WOC.[MaterialFlatBillingAmount],0) + ISNULL(WOC.[LaborFlatBillingAmount],0) + ISNULL(WOC.[ChargesFlatBillingAmount],0))) END [MarginPercentage],
		SCOPE.[Description] [Scope],
		WAP.[InternalApprovedDate],
		WAP.[InternalRejectedDate],
		ISNULL(WAP.[InternalRejectedID], 0) [InternalRejectedID],
		NULLIF(LTRIM(RTRIM(ISNULL(app1.[FirstName], '') + ' ' + ISNULL(app1.[LastName], ''))), '') [InternalRejectedBy],
		ISNULL(wap.[CustomerRejectedbyID], 0) [CustomerRejectedbyID],
		NULLIF(LTRIM(RTRIM(ISNULL(con1.[FirstName], '') + ' ' + ISNULL(con1.[LastName], ''))), '') [CustomerRejectedBy],
		wap.[InternalSentDate],		
		NULLIF(LTRIM(RTRIM(ISNULL(app.[FirstName], '') + ' ' + ISNULL(app.[LastName], ''))), '') [InternalApprovedBy],
		wap.[CustomerApprovedDate],
		wap.[CustomerRejectedDate],
		wap.[CustomerSentDate],
		NULLIF(LTRIM(RTRIM(ISNULL(con.[FirstName], '') + ' ' + ISNULL(con.[LastName], ''))), '') [CustomerApprovedBy],
		woq.[WorkOrderId],
		woc.[WorkOrderQuoteId],
		woc.[WOPartNoId] [WorkOrderPartNoId],
		woc.[WorkflowWorkOrderId] [WorkFlowWorkOrderId],
		woq.[CustomerId],
		woc.[WorkOrderQuoteDetailsId] [WorkOrderDetailId],
		ISNULL(wap.[WorkOrderApprovalId], 0) [WorkOrderApprovalId],
		woq.[MasterCompanyId],
		ISNULL(wap.[InternalApprovedById], 0) [InternalApprovedById],
		ISNULL(wap.[CustomerApprovedById], 0) [CustomerApprovedById],
		ISNULL(wap.[InternalMemo], '') [InternalMemo],
		ISNULL(wap.[CustomerMemo], '') [CustomerMemo],
		ISNULL(wap.[CreatedBy], '') AS [CreatedBy],
		ISNULL(wap.[CreatedDate], GETUTCDATE()) [CreatedDate],
		ISNULL(wap.[UpdatedBy], '') AS [UpdatedBy],
		ISNULL(wap.[UpdatedDate], GETUTCDATE()) [UpdatedDate],
		1 AS [IsActive],
		0 AS [IsDeleted],
		dbo.GetApprovalActionId(ISNULL(wap.[ApprovalActionId], 0), @IsInternalApprove, ISNULL(woq.[IsApprovalBypass], 0)) [ApprovalActionId],
		dbo.GetActionStatus(ISNULL(wap.[ApprovalActionId], 0), @IsInternalApprove, ISNULL(woq.[IsApprovalBypass], 0)) [ActionStatus],
        dbo.GetInternalStatusId(ISNULL(wap.[InternalStatusId], 0), @IsInternalApprove, ISNULL(woq.[IsApprovalBypass], 0)) [InternalStatusId],
        ISNULL(wap.[CustomerStatusId], 1) [CustomerStatusId],
        @IsInternalApprove [IsInternalApprove],
		ISNULL(wap.[InternalSentToId], 0) AS [InternalSentToId],
		ISNULL(wap.[InternalSentToName], '') AS [InternalSentToName],
		ISNULL(wap.[InternalSentById], 0) AS [InternalSentById],
		CASE 
			WHEN (wop.[RevisedPartNumber] IS NOT NULL AND wop.[RevisedPartNumber] <> '') AND (wop.[RevisedSerialNumber] IS NOT NULL AND wop.[RevisedSerialNumber] <> '')
				 THEN wop.[RevisedPartNumber] + '-' + wop.[RevisedSerialNumber]
			WHEN (wop.[RevisedPartNumber] IS NOT NULL AND wop.[RevisedPartNumber] <> '')
				 THEN wop.[RevisedPartNumber] + '-' + stl.[ControlNumber]
			ELSE wop.[PartNumber] + '-' + stl.[ControlNumber]
		END AS [PartNumberLabel]		
		FROM [dbo].[WorkOrderQuoteDetails] WOC WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WOC.[WorkOrderQuoteId] = WOQ.[WorkOrderQuoteId]
		 LEFT JOIN [dbo].[WorkOrderApproval] WAP WITH(NOLOCK) ON WOC.[WOPartNoId] = wap.[WorkOrderPartNoId]
		INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOC.[WOPartNoId] = wop.[ID]
		INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WOP.[ItemMasterId] = IM.[ItemMasterId]
		INNER JOIN [dbo].[WorkOrderStage] ST WITH(NOLOCK) ON WOP.[WorkOrderStageId] = ST.[WorkOrderStageId]
		INNER JOIN [dbo].[StockLine] STL WITH(NOLOCK) ON WOP.[StockLineId] = STL.[StockLineId]
		INNER JOIN [dbo].[WorkScope] SCOPE WITH(NOLOCK) ON WOP.[WorkOrderScopeId] = SCOPE.[WorkScopeId]
		 LEFT JOIN [dbo].[Employee] APP WITH(NOLOCK) ON WAP.[InternalApprovedById] = APP.[EmployeeId]
		 LEFT JOIN [dbo].[Employee] APP1 WITH(NOLOCK) ON WAP.[InternalRejectedID] = APP1.[EmployeeId]
		 LEFT JOIN [dbo].[Contact] CON WITH(NOLOCK) ON WAP.[CustomerApprovedById] = CON.[ContactId]
		 LEFT JOIN [dbo].[Contact] CON1 WITH(NOLOCK) ON WAP.[CustomerRejectedbyID] = CON1.[ContactId]
		 WHERE WOC.[WorkOrderQuoteId] = @WorkOrderQuoteId
		   AND WOC.[IsVersionIncrease] = 0
		  AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(STL.IsNonStock,0) = 0
		    ORDER BY WOP.[ID];			
		END TRY  
 BEGIN CATCH        
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetWOQuoteApprovalList'   
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteId, '') AS VARCHAR(100))  
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