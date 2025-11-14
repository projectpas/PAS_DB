/*****************************************************************************************           
 ** File:   [USP_GetWOMRODashboardData]        
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Display WO MRODashBoard Data
 ** Purpose:         
 ** Date:   02-June-2025    
 **********************           
  ** Change History           
 **********************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------					----------------------------   
    1    02-June-2025		Devendra Shekh			CREATED   
	2    16-June-2025		Devendra Shekh 			Amount Issue Resolved for MTD Billing
	3    24-June-2025		Devendra Shekh			Billing Table Changes
	4	 01-July-2025		Devendra Shekh			Parts Count Issue resolved for WOQ
	5	 02-July-2025		Devendra Shekh			Using @BaseUtcOffsetSec for DateConversion
	6	 03 NOV 2025		HEMANT SALIYA			Corrected Dashbord Reports Issue for Multiple MPN
	7    05 NOV 2025        Moin Bloch              Exclude Credit Memo Condition 
	8    14 NOV 2025        Moin Bloch              Fix For Partial Credit Memo 
	
	EXEC dbo.[USP_GetWOMRODashboardData] @MasterCompanyId=1,@StartDate='2024-10-17 00:00:00',@EmployeeId=2,@ManagementStructureId=1
*********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOMRODashboardData]
	@MasterCompanyId INT = NULL,
	@StartDate DATETIME = NULL,
	@EmployeeId BIGINT = NULL,
	@ManagementStructureId BIGINT = NULL
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		
		DECLARE @WOReceiptUnits AS INT;
		DECLARE @WOQuotedUnits AS INT;
		DECLARE @WOQuotedAmount AS DECIMAL(20, 2);
		DECLARE @WOApprovalUnits AS INT;
		DECLARE @WOApprovalAmount AS DECIMAL(20, 2);
		DECLARE @WOBillingUnits AS INT;
		DECLARE @WOBillingAmount AS DECIMAL(20, 2);
		DECLARE @WOMTDUnits AS INT;
		DECLARE @WOMTDAmount AS DECIMAL(20, 2);
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;

		DECLARE @RecevingModuleID AS BIGINT = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'RecevingCustomer');
		DECLARE @WOPartModuleID AS BIGINT = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN');
		DECLARE @WOQApproveStatus AS BIGINT = (SELECT [WorkOrderQuoteStatusId] FROM [dbo].[WorkOrderQuoteStatus] WITH(NOLOCK) WHERE [Description] = 'Approved');

		DECLARE @CMPostedStatusId INT = (SELECT [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED');
		DECLARE @ClosedCreditMemoStatus INT = (SELECT [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'CLOSED');
		DECLARE @RefundedCreditMemoStatus INT = (SELECT [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUNDED');
		DECLARE @RefundRequestedCreditMemoStatus INT = (SELECT [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUND REQUESTED');
		DECLARE @WOInvoiceTypeId INT = (SELECT [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='WorkOrder');

		DECLARE @WOModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder');
		DECLARE @SubModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN');

		IF OBJECT_ID(N'tempdb..#tmpRCWorkOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpRCWorkOrderUserRole
		END

		IF OBJECT_ID(N'tempdb..#tmpWorkOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpWorkOrderUserRole
		END	

		SELECT * INTO #tmpRCWorkOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
		FROM [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK)
		INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.EntityStructureId = MSD.EntityMSID 
		INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @RecevingModuleID AND EUR.[EmployeeId] = @EmployeeId) AS Result

		SELECT * INTO #tmpWorkOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
		FROM [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK)
		INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.EntityStructureId = MSD.EntityMSID 
		INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @WOPartModuleID AND EUR.[EmployeeId] = @EmployeeId) AS Result

		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		SELECT TOP 1 @BaseUtcOffsetSec = [BaseUtcOffsetSec] FROM [dbo].[TimeZone] WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc;

		-- selecting receiving customer work details		:(DashboardType = 9)
		SELECT @WOReceiptUnits = SUM(Quantity) FROM (
				SELECT DISTINCT	
					WO.WorkOrderId,
					rec_cust.PartNumber, 
					item.PartDescription, 
					rec_cust.WorkScope, 
					item.ItemGroup,
					SUM(ISNULL(rec_cust.Quantity, 0)) Quantity,
					wo.WorkOrderNum, 
					rec_cust.CustomerName, 
					(emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.ReceivingCustomerWork rec_cust WITH (NOLOCK)
				INNER JOIN DBO.ItemMaster item WITH (NOLOCK) ON rec_cust.ItemMasterId = item.ItemMasterId
				INNER JOIN #tmpRCWorkOrderUserRole TMP ON TMP.ReferenceID = rec_cust.ReceivingCustomerWorkId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON rec_cust.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				WHERE rec_cust.IsActive = 1 
				AND rec_cust.IsDeleted = 0 
				AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, rec_cust.CreatedDate)) = CONVERT(DATE, @StartDate)
				AND rec_cust.MasterCompanyId = @MasterCompanyId
				AND  rec_cust.IsPiecePart = 0 
				GROUP BY WO.WorkOrderId, rec_cust.PartNumber, item.PartDescription, rec_cust.WorkScope, item.ItemGroup, wo.WorkOrderNum, rec_cust.CustomerName, emp.FirstName, emp.LastName
		) AS ReceivingResult
		
		-- selecting work order quote unit and amount details		:(DashboardType = 11)
		SELECT @WOQuotedUnits = COUNT(*), @WOQuotedAmount = SUM(GrandTotal) FROM (
				SELECT DISTINCT wop.ID,
					item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup, WOQ.CustomerName, WOQ.QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson,
					SUM(CASE WHEN ISNULL(WOQD.QuoteMethod,0) = 1 THEN ISNULL((WOQD.CommonFlatRate),0)
												 ELSE ISNULL((WOQD.LaborFlatBillingAmount),0) + ISNULL((WOQD.MaterialFlatBillingAmount),0) + ISNULL((WOQD.ChargesFlatBillingAmount),0) + ISNULL((FreightFlatBillingAmount),0) END) AS GrandTotal
				FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON WOQ.WorkOrderId = wop.WorkOrderId AND WOQD.WOPartNoId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON WOQD.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN #tmpWorkOrderUserRole TMP ON TMP.ReferenceID = WOQD.WOPartNoId
				WHERE  CONVERT(DATE,WOQ.OpenDate) = CONVERT(DATE, @StartDate) 
				AND WOQ.MasterCompanyId = @MasterCompanyId
				GROUP BY wop.ID, item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,WOQD.QuoteMethod, WOQ.CustomerName,WOQ.QuoteNumber,emp.FirstName , emp.LastName
		) AS WOQuoteResult

		-- selecting approved work order quote unit and amount details		:(DashboardType = 12)
		SELECT @WOApprovalUnits = COUNT(*), @WOApprovalAmount = SUM(GrandTotal) FROM (
				SELECT DISTINCT WOP.ID,
					item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup, WOQ.CustomerName, WOQ.QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson,
					SUM(CASE WHEN ISNULL(WOQD.QuoteMethod,0) = 1 THEN ISNULL((WOQD.CommonFlatRate),0)
												 ELSE ISNULL((WOQD.LaborFlatBillingAmount),0) + ISNULL((WOQD.MaterialFlatBillingAmount),0) + ISNULL((WOQD.ChargesFlatBillingAmount),0) + ISNULL((FreightFlatBillingAmount),0) END) AS GrandTotal
				FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON WOQ.WorkOrderId = wop.WorkOrderId AND WOQD.WOPartNoId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON WOQD.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN #tmpWorkOrderUserRole TMP ON TMP.ReferenceID = WOQD.WOPartNoId
				WHERE  CONVERT(DATE,WOQ.ApprovedDate) = CONVERT(DATE, @StartDate) AND WOQ.MasterCompanyId = @MasterCompanyId AND  WOQ.QuoteStatusId = @WOQApproveStatus
				GROUP BY WOP.ID, item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,WOQD.QuoteMethod, WOQ.CustomerName,WOQ.QuoteNumber,emp.FirstName , emp.LastName
		) AS ApprovedWOQuoteResult

		-- selecting work order billing unit and amount details		:(DashboardType = 13)
		SELECT @WOBillingUnits = COUNT(*), @WOBillingAmount = SUM(GrandTotal) FROM (
				SELECT DISTINCT
					wobii.BillingInvoicingItemId ,item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup--, wobii.GrandTotal
					, (ISNULL(wobii.GrandTotal, 0) - (ISNULL(wobii.SalesTax, 0) + ISNULL(wobii.OtherTax, 0))) AS GrandTotal
					--, CASE WHEN WOBI.CostPlusType = 'Flat Rate' AND ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) ELSE CASE WHEN ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) WHEN ISNULL(WOBII.SubTotal,0) > 0 THEN ISNULL(WOBII.SubTotal,0) ELSE ISNULL(WOBII.UnitPrice,0) END END [GrandTotal]
					, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.BillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.BillingInvoicingItems wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobii.SubModuleId = @SubModuleId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.ReferenceId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId and wobii.SubReferenceId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN #tmpWorkOrderUserRole TMP ON TMP.ReferenceID = wop.ID
				WHERE wobi.IsActive = 1 
				AND wobi.IsDeleted = 0 
				AND wobi.IsVersionIncrease = 0
				AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, wobi.InvoiceDate)) = CONVERT(DATE, @StartDate)
				AND wobi.MasterCompanyId = @MasterCompanyId
				AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
			  --AND wobi.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
			    AND wobii.[BillingInvoicingItemId] NOT IN (SELECT ISNULL(CMD.[BillingInvoicingItemId], 0) FROM [dbo].[CreditMemo] CM WITH(NOLOCK) INNER JOIN [dbo].[CreditMemoDetails] CMD WITH(NOLOCK) ON CM.[CreditMemoHeaderId] = CMD.[CreditMemoHeaderId]
				WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)				
			    AND wobi.ModuleId = @WOModuleId
		) AS WorkOrderBillingResult

		-- selecting work order MTD billing unit and amount details		:(DashboardType = 10)
		SELECT @WOMTDUnits = COUNT(*), @WOMTDAmount = SUM(GrandTotal) FROM (
				SELECT DISTINCT
					wop.ID, item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup, 
					(ISNULL(wobii.GrandTotal, 0) - (ISNULL(wobii.SalesTax, 0) + ISNULL(wobii.OtherTax, 0))) AS GrandTotal, 
					--CASE WHEN WOBI.CostPlusType = 'Flat Rate' AND ISNULL(wobii.GrandTotal,0) > 0 THEN ISNULL(wobii.GrandTotal,0) ELSE CASE WHEN ISNULL(wobii.GrandTotal,0) > 0 THEN ISNULL(wobii.GrandTotal,0) WHEN ISNULL(wobii.SubTotal,0) > 0 THEN ISNULL(wobii.SubTotal,0) ELSE ISNULL(wobii.UnitPrice,0) END END AS 'GrandTotal',   
					wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.BillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.BillingInvoicingItems wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobii.SubModuleId = @SubModuleId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.ReferenceId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId and wobii.SubReferenceId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN #tmpWorkOrderUserRole TMP ON TMP.ReferenceID = wop.ID
				WHERE wobi.IsActive = 1 
				AND wobi.IsDeleted = 0 
				AND wobi.IsVersionIncrease = 0
				AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, wobi.InvoiceDate)) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AND @StartDate
				AND wobi.MasterCompanyId = @MasterCompanyId
				AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
			  --AND wobi.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
				AND wobii.[BillingInvoicingItemId] NOT IN (SELECT ISNULL(CMD.[BillingInvoicingItemId], 0) FROM [dbo].[CreditMemo] CM WITH(NOLOCK) INNER JOIN [dbo].[CreditMemoDetails] CMD WITH(NOLOCK) ON CM.[CreditMemoHeaderId] = CMD.[CreditMemoHeaderId]
				WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)
				AND wobi.ModuleId = @WOModuleId
		) AS WorkOrderMTDBillingResult

		SELECT  @WOReceiptUnits AS WoReceiptUnits,
			    @WOQuotedUnits AS WoQuotedUnits,
				@WOQuotedAmount AS WoQuotedAmount,
				@WOApprovalUnits AS WoApprovalUnits,
				@WOApprovalAmount AS WoApprovalAmount,
				@WOBillingUnits AS WoBillingUnits,
				@WOBillingAmount AS WoBillingAmount,
				@WOMTDUnits AS WoMTDUnits,
				@WOMTDAmount AS WoMTDAmount
	END
	END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetWOMRODashboardData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '
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