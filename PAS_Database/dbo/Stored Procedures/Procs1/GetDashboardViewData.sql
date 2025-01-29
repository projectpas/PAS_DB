/*************************************************************           
 ** File:   [GetDashboardViewData]
 ** Author: unknown
 ** Description: This stored procedure is used to Get Dashboard View Data
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	01/31/2024		Devendra Shekh	added isperforma Flage for WO
	3	02/1/2024		AMIT GHEDIYA	added isperforma Flage for SO
	4   03/06/2024      Bhargav Saliya  Convert  Into Temp table SP
	5	03/28/2024		Bhargav Saliya  Resolve Snapshot: MRO Billing amount issue
	6	16/10/2024		Shrey Chandegara  add new @DashboardType for workorder dashboard
	7   11/04/2024		Vishal Suthar	Modified to make use of new SOQ new tables
	8   01/16/2025		Bhargav Saliya 	Resolved Dashboard Amount issue (SO invoice)
	9   01/22/2025		Bhargav Saliya 	Resolved Workable Backlog(More Info) PN Amount Issues [PN-10689]
	10   01/28/2025		Bhargav Saliya 	Resolved DashBoard INVOICE AND NON-INVOICE records issues [PN-11084]

-- EXEC GetDashboardViewData 
************************************************************************/

CREATE    PROCEDURE [dbo].[GetDashboardViewData]
	@MasterCompanyId BIGINT = NULL,
	@Date DATETIME = NULL,
	@DashboardType INT = NULL,
	@EmployeeId BIGINT = NULL,
	@ManagementStructureId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			DECLARE @BacklogStartDt AS DateTime;
			DECLARE @RecevingModuleID AS INT =1;
			DECLARE @wopartModuleID AS INT =12
			DECLARE @woqModuleID AS INT =15
			DECLARE @SalesOrderModuleID AS INT =17
			DECLARE @SalesOrderQouteModuleID AS INT =18
			DECLARE @SpeedQouteModuleID AS INT =27
			DECLARE @WOQApproveStatus AS INT;
			SET @WOQApproveStatus = (SELECT WorkOrderQuoteStatusId FROM [dbo].[WorkOrderQuoteStatus] WHERE Description = 'Approved')
			SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0

			IF OBJECT_ID(N'tempdb..#tmpSalesOrderUserRole') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpSalesOrderUserRole
			END
		
			SELECT * INTO #tmpSalesOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
				INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
			WHERE MSD.[ModuleID] = @SalesOrderModuleID AND EUR.[EmployeeId] = @EmployeeId) AS SalesOrderUserRole

			print @DashboardType
			IF (@DashboardType = 1)
			BEGIN
					;With TempResults as  (
					SELECT DISTINCT
						WO.WorkOrderId,
						rec_cust.PartNumber, 
						item.PartDescription, 
						rec_cust.WorkScope, 
						item.ItemGroup,
						rec_cust.Quantity, 
						wo.WorkOrderNum, 
						rec_cust.CustomerName, 
						(emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
					FROM 
						DBO.ReceivingCustomerWork rec_cust WITH (NOLOCK)
						INNER JOIN DBO.ItemMaster item WITH (NOLOCK) ON rec_cust.ItemMasterId = item.ItemMasterId
						INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = rec_cust.ReceivingCustomerWorkId
						INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON rec_cust.ManagementStructureId = RMS.EntityStructureId
						INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON rec_cust.WorkOrderId = WO.WorkOrderId
						LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
					WHERE 
						rec_cust.IsActive = 1 
						AND rec_cust.IsDeleted = 0 
						AND CONVERT(DATE, rec_cust.ReceivedDate) = CONVERT(DATE, @Date) 
						AND rec_cust.MasterCompanyId = @MasterCompanyId
					)
					SELECT * FROM TempResults Order by WorkOrderId
			END
			ELSE IF (@DashboardType = 2)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				wobii.GrandTotal, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderBillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId and wobii.WorkOrderPartId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOBI.ManagementStructureId = RMS.EntityStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				WHERE wobi.IsActive = 1 
				AND wobi.IsDeleted = 0 
				AND wobi.IsVersionIncrease = 0
				AND CONVERT(DATE, wobi.InvoiceDate) = CONVERT(DATE, @Date) 
				AND wobi.MasterCompanyId = @MasterCompanyId
				AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
			END
			ELSE IF (@DashboardType = 3)
			BEGIN
				;WITH Result AS (	
					SELECT DISTINCT
					IM.PartNumber, IM.PartDescription, CDTN.[Description] AS Condition, IM.ItemGroup,
					SUM(ISNULL(SOBIII.PartCost, 0)) + SUM(ISNULL(SOBIII.SalesTax, 0)) + SUM(ISNULL(SOBIII.OtherTax, 0)) + SUM(ISNULL(SOBIII.MiscCharges, 0)) AS 'GrandTotal',
					cust.Name AS CustomerName, so.SalesOrderNumber, UPPER(SO.SalesPersonName) 'SalesPerson'
					FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
					INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId AND SO.IsDeleted = 0 AND SO.IsActive = 1 AND ISNULL(SOBI.IsVersionIncrease, 0) = 0 AND ISNULL(SOBI.IsProforma, 0) = 0
					INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
					INNER JOIN dbo.SalesOrderBillingInvoicingItem SOBIII WITH (NOLOCK) ON SOBIII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND ISNULL(SOBIII.IsVersionIncrease, 0) = 0 AND ISNULL(SOBIII.IsProforma, 0) = 0 AND SOP.SalesOrderPartId = SOBIII.SalesOrderPartId
					INNER JOIN dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON SOV.StockLineId = SOBIII.StockLineId AND SOV.SalesOrderPartId = SOBIII.SalesOrderPartId
					INNER JOIN dbo.customer C WITH (NOLOCK) ON SOBI.customerid = C.customerid 
					INNER JOIN dbo.itemmaster IM WITH (NOLOCK) ON SOP.itemmasterid = IM.itemmasterid 
					INNER JOIN dbo.stockline STL WITH (NOLOCK) ON SOV.stocklineid = STL.stocklineid AND STL.IsParent = 1 
					LEFT JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid
					LEFT JOIN dbo.workorder WO WITH (NOLOCK)  ON STL.workorderid = WO.workorderid 
					LEFT JOIN dbo.condition CDTN WITH (NOLOCK) ON SOP.conditionid = CDTN.conditionid
					LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
					INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SO.SalesOrderId
					WHERE sobi.IsActive = 1
					AND sobi.IsDeleted = 0
					AND ISNULL(SOV.StockLineId, 0) > 0
					AND CONVERT(DATE, sobi.InvoiceDate) = CONVERT(DATE, @Date)
					AND sobi.MasterCompanyId = @MasterCompanyId
					AND ISNULL(sobi.IsProforma,0) = 0
					GROUP BY IM.PartNumber, IM.PartDescription,CDTN.[Description],IM.ItemGroup,cust.Name, so.SalesOrderNumber, SO.SalesPersonName
				), ResultCount AS(Select COUNT(PartNumber) AS totalItems FROM Result) 

				Select * from Result
					
			END
			ELSE IF (@DashboardType = 4)
			BEGIN
				SELECT 
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				wop.Quantity, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderPartNumber wop WITH (NOLOCK)
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = WOP.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOP.ManagementStructureId = RMS.EntityStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				WHERE 
				wop.WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId
										AND IsActive = 1 AND IsDeleted = 0)
				AND wop.IsActive = 1
				AND wop.IsDeleted = 0
				AND CONVERT(DATE, wop.CreatedDate) = CONVERT(DATE, @Date)
				AND wop.MasterCompanyId = @MasterCompanyId
			END
			ELSE IF (@DashboardType = 5)
			BEGIN
				SELECT 
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SUM(ISNULL(SOPC.UnitSalesPrice,0)) AS GrandTotal,
				cust.Name AS CustomerName, SO.SalesOrderNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson
				FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderStockLineCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
				INNER JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
				INNER JOIN DBO.SalesOrderStocklineV1 STKV WITH (NOLOCK) ON SOP.SalesOrderPartId = STKV.SalesOrderPartId AND STKV.SalesOrderStocklineId = SOPC.SalesOrderStocklineId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SOP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SOP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SO.SalesPersonId = emp.EmployeeId
				INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SO.SalesOrderId
				WHERE
				STKV.StockLineId NOT IN (SELECT SOBII.StockLineId FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
					INNER JOIN DBO.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND SOBII.IsVersionIncrease = 0
					Where SOBI.SalesOrderId = SOP.SalesOrderId AND SO.MasterCompanyId = 1)
				AND SO.IsActive = 1
				AND SO.IsDeleted = 0
				AND CONVERT(DATE, SO.CreatedDate) = CONVERT(DATE, @Date)
				AND SO.MasterCompanyId = @MasterCompanyId
				GROUP BY item.PartNumber, item.PartDescription, cond.[Description], item.ItemGroup, cust.Name, SO.SalesOrderNumber, emp.FirstName, emp.LastName
				ORDER BY SO.SalesOrderNumber
			END
			ELSE IF (@DashboardType = 6)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, A.WorkScope, item.ItemGroup,
				WOP.Quantity, cust.Name AS CustomerName, WOQ.QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
				LEFT JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOQ.WorkOrderId = WOP.WorkOrderId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON WOQ.CustomerId = cust.CustomerId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON WOQD.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = WOP.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOP.ManagementStructureId = RMS.EntityStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				Outer Apply(
					SELECT 
					STUFF((SELECT ', ' + WOPP.WorkScope
					FROM DBO.WorkOrderQuote WOQ INNER JOIN DBO.WorkOrderPartNumber WOPP WITH (NOLOCK)
					ON WOQ.WorkOrderId = WOPP.WorkOrderId
					WHERE WOPP.WorkOrderId = WOP.WorkOrderId
					FOR XML PATH('')), 1, 1, '') WorkScope
				) A
				WHERE
				WOQ.IsActive = 1
				AND WOQ.IsDeleted = 0
				AND WOQ.SentDate IS NOT NULL
				AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @Date) 
				AND WOQ.MasterCompanyId = @MasterCompanyId
			END
			ELSE IF (@DashboardType = 7)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SQP.QuantityRequested AS Quantity, cust.Name AS CustomerName, SQ.SpeedQuoteNumber AS QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SpeedQuote SQ WITH (NOLOCK)
				INNER JOIN DBO.SpeedQuotePart SQP WITH (NOLOCK) ON SQ.SpeedQuoteId = SQP.SpeedQuoteId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON SQ.CustomerId = cust.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SQP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SQP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SQ.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID =@SpeedQouteModuleID AND MSD.ReferenceID = SQ.SpeedQuoteId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SQ.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				WHERE
				SQ.StatusId IN (SELECT Id FROM DBO.MasterSpeedQuoteStatus WITH (NOLOCK) WHERE 
						[Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
				AND SQ.IsActive = 1
				AND SQ.IsDeleted = 0
				AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @Date) 
				AND SQ.MasterCompanyId = @MasterCompanyId
			END
			ELSE IF (@DashboardType = 8)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SOQM.NetSales AS GrandTotal,SOQPC.NetSaleAmount NetSales, cust.Name AS CustomerName, SOQ.SalesOrderQuoteNumber AS QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
				INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON SOQ.CustomerId = cust.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SOQP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SOQP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SOQ.SalesOrderQuoteId
				WHERE
				SOQA.CustomerApprovedDate IS NOT NULL
				AND SOQ.IsActive = 1
				AND SOQ.IsDeleted = 0
				AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @Date) 
				AND SOQ.MasterCompanyId = @MasterCompanyId
			END
			ELSE IF (@DashboardType = 9)
			BEGIN
				SELECT DISTINCT
						WO.WorkOrderId,
						rec_cust.PartNumber, 
						item.PartDescription, 
						rec_cust.WorkScope, 
						item.ItemGroup,
						rec_cust.Quantity, 
						wo.WorkOrderNum, 
						rec_cust.CustomerName, 
						(emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
					FROM 
						DBO.ReceivingCustomerWork rec_cust WITH (NOLOCK)
						INNER JOIN DBO.ItemMaster item WITH (NOLOCK) ON rec_cust.ItemMasterId = item.ItemMasterId
						--INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 1 AND MSD.ReferenceID = rec_cust.ReceivingCustomerWorkId
						INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON rec_cust.ManagementStructureId = RMS.EntityStructureId
						INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON rec_cust.WorkOrderId = WO.WorkOrderId
						LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
					WHERE 
						rec_cust.IsActive = 1 
						AND rec_cust.IsDeleted = 0 
						AND CONVERT(DATE, rec_cust.CreatedDate) = CONVERT(DATE, @Date) 
						AND rec_cust.MasterCompanyId = @MasterCompanyId
						AND  rec_cust.IsPiecePart = 0 
			END
			ELSE IF (@DashboardType = 10)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				wobii.GrandTotal, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderBillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId and wobii.WorkOrderPartId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOBI.ManagementStructureId = RMS.EntityStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				WHERE wobi.IsActive = 1 
				AND wobi.IsDeleted = 0 
				AND wobi.IsVersionIncrease = 0
				AND CONVERT(DATE,wobi.CreatedDate) BETWEEN DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1) 
								AND @Date 
				AND wobi.MasterCompanyId = @MasterCompanyId
				AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
			END
			ELSE IF (@DashboardType = 11)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				 CASE WHEN ISNULL(WOQD.QuoteMethod,0) = 1 THEN ISNULL(SUM(WOQD.CommonFlatRate),0) ELSE ISNULL(SUM(WOQD.LaborFlatBillingAmount),0) + ISNULL(SUM(WOQD.MaterialFlatBillingAmount),0) + ISNULL(SUM(WOQD.ChargesFlatBillingAmount),0) + ISNULL(SUM(FreightFlatBillingAmount),0) END AS GrandTotal
				, WOQ.CustomerName, WOQ.QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON WOQ.WorkOrderId = wop.WorkOrderId --and wobii.WorkOrderPartId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON WOQD.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RMS.EntityStructureId = @ManagementStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				WHERE  CONVERT(DATE,WOQ.CreatedDate) = @Date 
				AND WOQ.MasterCompanyId = @MasterCompanyId
				GROUP BY item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,WOQD.QuoteMethod, WOQ.CustomerName,WOQ.QuoteNumber,emp.FirstName , emp.LastName
			END
			ELSE IF (@DashboardType = 12)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				 CASE WHEN ISNULL(WOQD.QuoteMethod,0) = 1 THEN ISNULL(SUM(WOQD.CommonFlatRate),0) ELSE ISNULL(SUM(WOQD.LaborFlatBillingAmount),0) + ISNULL(SUM(WOQD.MaterialFlatBillingAmount),0) + ISNULL(SUM(WOQD.ChargesFlatBillingAmount),0) + ISNULL(SUM(FreightFlatBillingAmount),0) END AS GrandTotal
				, WOQ.CustomerName, WOQ.QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON WOQ.WorkOrderId = wop.WorkOrderId --and wobii.WorkOrderPartId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON WOQD.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RMS.EntityStructureId = @ManagementStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				WHERE  CONVERT(DATE,WOQ.ApprovedDate) = @Date AND WOQ.MasterCompanyId = @MasterCompanyId AND  WOQ.QuoteStatusId = @WOQApproveStatus
				GROUP BY item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,WOQD.QuoteMethod, WOQ.CustomerName,WOQ.QuoteNumber,emp.FirstName , emp.LastName
			END
			ELSE IF (@DashboardType = 13)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				wobii.GrandTotal, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderBillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId and wobii.WorkOrderPartId = wop.ID
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @wopartModuleID AND MSD.ReferenceID = wop.ID
		        INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON WOBI.ManagementStructureId = RMS.EntityStructureId
		        INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				WHERE wobi.IsActive = 1 
				AND wobi.IsDeleted = 0 
				AND wobi.IsVersionIncrease = 0
				AND CONVERT(DATE, wobi.InvoiceDate) = CONVERT(DATE, @Date) 
				AND wobi.MasterCompanyId = @MasterCompanyId
				AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
			END
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments VARCHAR(150) = 'GetDashboardViewData' 
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
	END CATCH    
END