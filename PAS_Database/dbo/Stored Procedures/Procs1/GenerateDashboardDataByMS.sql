/*********************           
 ** File:   [GenerateDashboardDataByMS]        
 ** Author:   JEVIK RAIYANI
 ** Description: This stored procedure is used Display snapshot count in DashBoard
 ** Purpose:         
 ** Date:   22-11-2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author			Change Description            
 ** --   --------         -------			----------------------------   
    1    22 Nov 2023	JEVIK RAIYANI		update SQProcessed variable calculation         
	2	 01/31/2024		Devendra Shekh		added isperforma Flage for WO
	3	 01/02/2024	    AMIT GHEDIYA	    added isperforma Flage for SO
	4    03/07/2024     Bhargav Saliya		Fixed duplicate Record Issue
	6    19 March 2024  Bhargav Saliya		Resolved Count Issue(MRO Inputs) in MRO Dashboard 
	7	 28 March 2024  Bhargav Saliya		Resolve Snapshot: MRO Billing amount issue
	8	 28 June 2024   Vishal Suthar		Added login entry in LogInLog table for employee when they login into the system
	9    16 OCT 2024	Abhishek Jirawla	Implemented the new tables for SalesOrderQuotePart related tables
	10	 30 Oct 2024    HEMANT SALIYA		Verify the count 
	11   01/28/2025		Bhargav Saliya 		Resolved DashBoard INVOICE AND NON-INVOICE records issues [PN-11084]
	12   01/29/2025		Bhargav Saliya 		SELECT ID'S Using MouleName
	13   18/03/2025		RAJESH GAMI			Fix the ReceivedDate issue (make a created date as a Received Date) AND convert UTC to LOCAL where we compare the CREATEDDate
	14   06/04/2025		Hemant Saliya 		Snapshot DashBoard - Todays received Count Issue Resoled
	15   06/05/2025		Devendra Shekh 		Snapshot DashBoard - Count Issue Resoled
	16	 06/24/2025		Devendra Shekh		Billing Table Changes
	17	 06/30/2025		Devendra Shekh		SO Billing Table Changes
	18	 07/01/2025		Devendra Shekh		Parts Count Issue resolved for WOQ
	19	 07/02/2025		Devendra Shekh		Using @BaseUtcOffsetSec for DateConversion
**********************/

CREATE   PROCEDURE [dbo].[GenerateDashboardDataByMS] 
	@EmployeeId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@SelectedDate DATETIME = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		DECLARE @Qty AS INT;
		DECLARE @WOBillingAmt AS DECIMAL(20, 2);
		DECLARE @PartsSaleBillingAmt AS DECIMAL(20, 2);
		DECLARE @MROWorkable AS INT;
		DECLARE @PartsSaleWorkable AS DECIMAL(20, 2);
		DECLARE @WOQProcessed AS INT;
		DECLARE @SQProcessed AS INT;
		DECLARE @SOQProcessed AS DECIMAL(20, 2);
		DECLARE @BacklogStartDt AS DateTime;
		DECLARE @RecevingModuleID AS INT =(SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule	WITH (NOLOCK)  where ModuleName = 'RecevingCustomer');
		DECLARE @wopartModuleID AS INT =(SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule	WITH (NOLOCK)  where ModuleName = 'WorkOrderMPN');
		DECLARE @woqModuleID AS INT =(SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule	WITH (NOLOCK)  where ModuleName = 'WorkOrderQuote');
		DECLARE @SalesOrderModuleID AS INT =(SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule	WITH (NOLOCK)  where ModuleName = 'SalesOrder');
		DECLARE @SalesOrderQouteModuleID AS INT =(SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule	WITH (NOLOCK)  where ModuleName = 'SalesOrderQuote');
		DECLARE @SpeedQouteModuleID AS INT =(SELECT ManagementStructureModuleId FROM [dbo].ManagementStructureModule	WITH (NOLOCK)  where ModuleName = 'SpeedQuote');
		DECLARE @EmployeeRoleID AS VARCHAR(MAX);

		DECLARE @WOModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder');
		DECLARE @SubModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN');
		DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');

		/* --------------START: Get the timzone and UTC offset -------------- */
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
			SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
								FROM dbo.Employee E WITH (NOLOCK) 
									LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
									LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
									LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
								WHERE E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee		
				
			SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
		/* -------------- END: Get the timzone and UTC offset -------------- */

		IF OBJECT_ID(N'tempdb..#tmpSalesOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpSalesOrderUserRole
		END
		
		SELECT * INTO #tmpSalesOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
		FROM [dbo].SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @SalesOrderModuleID AND EUR.[EmployeeId] = @EmployeeId) AS SalesOrderUserRole


		IF OBJECT_ID(N'tempdb..#tmpSpeedQuoteUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpSpeedQuoteUserRole
		END
		
		SELECT * INTO #tmpSpeedQuoteUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
		FROM [dbo].WorkOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @SpeedQouteModuleID AND EUR.[EmployeeId] = @EmployeeId) AS WorkOrderUserRole

		IF OBJECT_ID(N'tempdb..#tmpWorkOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpWorkOrderUserRole
		END

		SELECT * INTO #tmpWorkOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
		FROM [dbo].WorkOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @wopartModuleID AND EUR.[EmployeeId] = @EmployeeId) AS WorkOrderUserRole

		IF OBJECT_ID(N'tempdb..#tmpRCWorkOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpRCWorkOrderUserRole
		END

		SELECT * INTO #tmpRCWorkOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
		FROM [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.EntityStructureId = MSD.EntityMSID 
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @RecevingModuleID AND EUR.[EmployeeId] = @EmployeeId) AS Result

		INSERT INTO [dbo].[LogInLog]([EmployeeId],[LogInTime],[LogOutTime],[IPAddress],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate])
        SELECT EmployeeId,GETDATE(),GETDATE(),'0',MasterCompanyId,FirstName + ' ' +LASTNAME,FirstName + ' ' +LASTNAME,GETDATE(),GETDATE()  
		FROM dbo.Employee WITH (NOLOCK) WHERE [EmployeeId]  = @EmployeeId
		
		SET @EmployeeRoleID = STUFF((SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
							FROM dbo.EmployeeUserRole WITH (NOLOCK) WHERE EmployeeId = @EmployeeId
							FOR XML PATH('')), 1, 1, '')
							
		-- selecting MRO Inputs Count		:(DashboardType = 1)
		SELECT @Qty = SUM(Quantity) FROM (
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
				AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, rec_cust.CreatedDate)) = CONVERT(DATE, @SelectedDate)
				AND rec_cust.MasterCompanyId = @MasterCompanyId
				AND  rec_cust.IsPiecePart = 0 
				GROUP BY WO.WorkOrderId, rec_cust.PartNumber, item.PartDescription, rec_cust.WorkScope, item.ItemGroup, wo.WorkOrderNum, rec_cust.CustomerName, emp.FirstName, emp.LastName
		) AS ReceivingResult

		--Selecting WO Billing MRO		:(DashboardType = 2)
		SELECT @WOBillingAmt = SUM(GrandTotal) FROM (
			SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				ISNULL(wobii.GrandTotal, 0) AS GrandTotal, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
			FROM DBO.BillingInvoicing wobi WITH (NOLOCK)
			INNER JOIN DBO.BillingInvoicingItems wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobii.SubModuleId = @SubModuleId
			LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.ReferenceId = WO.WorkOrderId
			LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId and wobii.SubReferenceId = wop.ID
			LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
			LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
			INNER JOIN #tmpWorkOrderUserRole TMP ON wop.ID = TMP.ReferenceID
			WHERE wobi.IsActive = 1 
			AND wobi.IsDeleted = 0 
			AND wobi.IsVersionIncrease = 0
			AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, wobi.InvoiceDate)) = CONVERT(DATE, @SelectedDate)
			AND wobi.MasterCompanyId = @MasterCompanyId
			AND ISNULL(wobi.IsPerformaInvoice, 0) = 0
			AND wobi.ModuleId = @WOModuleId
		) AS WOBillingResult

		--Selecting SO Billing Parts Sale		:(DashboardType = 3)
		SELECT @PartsSaleBillingAmt = SUM(GrandTotal) FROM (
			SELECT DISTINCT
				IM.PartNumber, IM.PartDescription, CDTN.[Description] AS Condition, IM.ItemGroup,
				ISNULL(SUM(SOBIII.PartCost),0) + ISNULL(SUM(SOBIII.SalesTax),0) + ISNULL(SUM(SOBIII.OtherTax),0) + ISNULL(SUM(SOBIII.MiscCharges),0) AS 'GrandTotal',
				cust.Name AS CustomerName, so.SalesOrderNumber, UPPER(SO.SalesPersonName) 'SalesPerson'
			FROM DBO.BillingInvoicing SOBI WITH (NOLOCK)
			INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.ReferenceId AND SO.IsDeleted = 0 AND SO.IsActive = 1 AND ISNULL(SOBI.IsVersionIncrease, 0) = 0 AND ISNULL(SOBI.IsPerformaInvoice, 0) = 0
			INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			INNER JOIN dbo.BillingInvoicingItems SOBIII WITH (NOLOCK) ON SOBIII.BillingInvoicingId = SOBI.BillingInvoicingId AND ISNULL(SOBIII.IsVersionIncrease, 0) = 0 AND ISNULL(SOBIII.IsPerformaInvoice, 0) = 0 AND SOP.SalesOrderPartId = SOBIII.SubReferenceId
			INNER JOIN dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON SOV.StockLineId = SOBIII.StockLineId AND SOV.SalesOrderPartId = SOBIII.SubReferenceId
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
			AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, sobi.InvoiceDate)) = CONVERT(DATE, @SelectedDate)
			AND sobi.MasterCompanyId = @MasterCompanyId
			AND ISNULL(sobi.IsPerformaInvoice,0) = 0
			AND SOBI.ModuleId = @SOModuleId
			GROUP BY IM.PartNumber, IM.PartDescription,CDTN.[Description],IM.ItemGroup,cust.Name, so.SalesOrderNumber, SO.SalesPersonName
		) AS SOBillingResult

		--Selecting Workable Backlog MRO (Units)		:(DashboardType = 4)
		SELECT @MROWorkable = SUM(Quantity) FROM (
			SELECT 
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				wop.Quantity, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
			FROM DBO.WorkOrderPartNumber wop WITH (NOLOCK)
			LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wop.WorkOrderId = wo.WorkOrderId
			LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
			LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
			INNER JOIN #tmpWorkOrderUserRole MSD WITH(NOLOCK) ON MSD.ReferenceID = WOP.ID
			WHERE 
			wop.WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)
			AND wop.IsActive = 1
			AND wop.IsDeleted = 0
			AND CONVERT(DATE, wop.CreatedDate) = CONVERT(DATE, @SelectedDate)
			AND wop.MasterCompanyId = @MasterCompanyId
			--AND WOP.IsClosed = 0
		) WOBacklogResult

		--Selecting Workable Backlog Parts Sale		:(DashboardType = 5)
		IF OBJECT_ID(N'tempdb..#tmpNonInvoiceDashboard') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpNonInvoiceDashboard
		END

		CREATE TABLE #tmpNonInvoiceDashboard (
			[PartNumber] VARCHAR(50),
			[PartDescription] VARCHAR(MAX),
			[Condition] VARCHAR(256),
			[ItemGroup] VARCHAR(250),
			[GrandTotal] DECIMAL(18,2),
			[CustomerName] VARCHAR(256),
			[SalesOrderNumber] VARCHAR(256),
			[SalesPerson] VARCHAR(100),
			[SalesOrderId] BIGINT,
			[SalesOrderPartId] BIGINT,
			[MasterCompanyId] int
		)

		INSERT INTO #tmpNonInvoiceDashboard ([PartNumber],[PartDescription],[Condition],[ItemGroup],[GrandTotal],[CustomerName],[SalesOrderNumber],[SalesPerson],[SalesOrderId],[SalesOrderPartId],[MasterCompanyId])
		SELECT 
			item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
			ISNULL(SUM(SOPC.NetSaleAmount),0) AS GrandTotal,
			cust.Name AS CustomerName, SO.SalesOrderNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson,SOP.SalesOrderId,SOP.SalesOrderPartId,SOP.MasterCompanyId
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
		STKV.StockLineId NOT IN (SELECT SOBII.StockLineId FROM DBO.BillingInvoicing SOBI WITH (NOLOCK) 
			INNER JOIN DBO.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId AND SOBII.IsVersionIncrease = 0
			Where SOBI.ReferenceId = SOP.SalesOrderId AND SO.MasterCompanyId = @MasterCompanyId AND SOBI.ModuleId = @SOModuleId) AND
			SO.IsActive = 1
		AND SO.IsDeleted = 0
		AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, SO.CreatedDate)) = CONVERT(DATE, @SelectedDate)
		AND SO.MasterCompanyId = @MasterCompanyId
		GROUP BY item.PartNumber, item.PartDescription, cond.[Description], item.ItemGroup, cust.Name, SO.SalesOrderNumber, emp.FirstName, emp.LastName,SOP.SalesOrderId,SOP.SalesOrderPartId,SOP.MasterCompanyId
		ORDER BY SO.SalesOrderNumber

		UPDATE TMP
		SET TMP.GrandTotal = ISNULL(TMP.GrandTotal,0) + ISNULL(partAmount.MiscCharges,0) - ISNULL(billedData.MiscCharges,0)
		FROM #tmpNonInvoiceDashboard TMP
		OUTER APPLY (
			SELECT ISNULL(SUM(sopc.MiscCharges),0) AS MiscCharges FROM DBO.SalesOrderPartCost sopc WITH (NOLOCK) 
						WHERE sopc.SalesOrderId = TMP.SalesOrderId AND sopc.SalesOrderPartId = TMP.SalesOrderPartId and  TMP.MasterCompanyId = @MasterCompanyId
			) AS partAmount

		OUTER APPLY (
			SELECT ISNULL(SUM(SOBII.MiscCharges),0) AS MiscCharges FROM DBO.BillingInvoicing SOBI WITH (NOLOCK) 
						INNER JOIN DBO.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId AND SOBII.IsVersionIncrease = 0
						WHERE SOBI.ReferenceId = TMP.SalesOrderId AND TMP.MasterCompanyId = @MasterCompanyId AND SOBI.ModuleId = @SOModuleId
			) AS billedData

		select @PartsSaleWorkable = ISNULL(SUM(GrandTotal),0) from #tmpNonInvoiceDashboard

		-- selecting Work Order Quote Processed (Units)		:(DashboardType = 6)
		SELECT @WOQProcessed = COUNT(*)  FROM (
			SELECT DISTINCT WOP.ID,
				item.PartNumber, item.PartDescription, WOP.WorkScope, item.ItemGroup,
				WOP.Quantity, cust.Name AS CustomerName, WOQ.QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
			FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK)
			INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
			INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) on WOQD.WorkflowWorkOrderId = WOWF.WorkFlowWorkOrderId
			INNER JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) on WOP.ID = WOWF.WorkOrderPartNoId
			LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON WOQ.CustomerId = cust.CustomerId
			LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON WOQD.ItemMasterId = item.ItemMasterId
			LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WOQ.SalesPersonId = emp.EmployeeId
			INNER JOIN #tmpWorkOrderUserRole MSD WITH(NOLOCK) ON MSD.ReferenceID = WOP.ID
			--Outer Apply(
			--	SELECT 
			--	STUFF((SELECT ', ' + WOPP.WorkScope
			--	FROM DBO.WorkOrderQuote WOQ INNER JOIN DBO.WorkOrderPartNumber WOPP WITH (NOLOCK)
			--	ON WOQ.WorkOrderId = WOPP.WorkOrderId
			--	WHERE WOPP.WorkOrderId = WOP.WorkOrderId
			--	FOR XML PATH('')), 1, 1, '') WorkScope
			--) A
			WHERE
			WOQ.IsActive = 1
			AND WOQ.IsDeleted = 0
			AND WOQ.SentDate IS NOT NULL
			AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @SelectedDate) 
			AND WOQ.MasterCompanyId = @MasterCompanyId
		) AS WorkOrderQuoteResult

		-- selecting Speed Quote Processed		:(DashboardType = 7)
		SELECT @SQProcessed = COUNT(*) FROM (
			SELECT DISTINCT
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SQP.QuantityRequested AS Quantity, cust.Name AS CustomerName, SQ.SpeedQuoteNumber AS QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
			FROM DBO.SpeedQuote SQ WITH (NOLOCK)
			INNER JOIN DBO.SpeedQuotePart SQP WITH (NOLOCK) ON SQ.SpeedQuoteId = SQP.SpeedQuoteId
			LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON SQ.CustomerId = cust.CustomerId
			LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SQP.ConditionId = cond.ConditionId
			LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SQP.ItemMasterId = item.ItemMasterId
			LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SQ.SalesPersonId = emp.EmployeeId
			INNER JOIN #tmpSpeedQuoteUserRole MSD WITH(NOLOCK) ON MSD.ReferenceID = SQ.SpeedQuoteId
			WHERE
			SQ.StatusId IN (SELECT Id FROM DBO.MasterSpeedQuoteStatus WITH (NOLOCK) WHERE [Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
			AND SQ.IsActive = 1
			AND SQ.IsDeleted = 0
			AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @SelectedDate) 
			AND SQ.MasterCompanyId = @MasterCompanyId
		) AS SpeedQuoteResult

		-- selecting Sales Order Quote Parts Sale		:(DashboardType = 8)
		SELECT @SOQProcessed = SUM(NetSales) FROM (
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
			AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @SelectedDate) 
			AND SOQ.MasterCompanyId = @MasterCompanyId
		) AS SOQResult

		SELECT ISNULL(@Qty, 0) AS 'MROInputCount', ISNULL(@WOBillingAmt, 0) AS 'MROBillingAmount', ISNULL(@PartsSaleBillingAmt, 0) AS 'PartsSaleBillingAmount', 
		ISNULL(@MROWorkable, 0) AS 'MROWorkableBacklog', ISNULL(@PartsSaleWorkable, 0) AS 'PartsSaleWorkableBacklog', ISNULL(@WOQProcessed, 0) AS 'WOQProcessed', 
		ISNULL(@SQProcessed, 0) AS 'SQProcessed', ISNULL(@SOQProcessed, 0) 'SOQProcessed'
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GenerateDashboardDataByMS' 
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