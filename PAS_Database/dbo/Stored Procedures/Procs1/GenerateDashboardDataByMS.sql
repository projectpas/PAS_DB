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
	11   01/28/2025		Bhargav Saliya 	Resolved DashBoard INVOICE AND NON-INVOICE records issues [PN-11084]
	12   01/29/2025		Bhargav Saliya 	SELECT ID'S Using MouleName
	13   18/03/2025   RAJESH GAMI       Fix the ReceivedDate issue (make a created date as a Received Date) AND convert UTC to LOCAL where we compare the CREATEDDate
	14   06/04/2025		Hemant Saliya 	Snapshot DashBoard - Todays received Count Issue Resoled
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
		/* --------------START: Get the timzone and UTC offset -------------- */
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
			SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
								FROM dbo.Employee E WITH (NOLOCK) 
									LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
									LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
									LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
								WHERE E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee		
				
			SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
				FROM dbo.TimeZone WITH(NOLOCK)  
				WHERE [Description] = @CurrntEmpTimeZoneDesc
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

		INSERT INTO [dbo].[LogInLog]
           ([EmployeeId],[LogInTime],[LogOutTime],[IPAddress],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate])
        SELECT EmployeeId,GETDATE(),GETDATE(),'0',MasterCompanyId,FirstName + ' ' +LASTNAME,FirstName + ' ' +LASTNAME,GETDATE(),GETDATE()  
		FROM dbo.Employee WITH (NOLOCK) WHERE [EmployeeId]  = @EmployeeId
     
		
		SET @EmployeeRoleID = STUFF((SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
							FROM dbo.EmployeeUserRole WITH (NOLOCK) WHERE EmployeeId = @EmployeeId
							FOR XML PATH('')), 1, 1, '')
							
		SELECT DISTINCT RC.ReceivingCustomerWorkId 
		INTO #tmpReceivingCustomerWork
		FROM DBO.ReceivingCustomerWork RC WITH (NOLOCK)
			INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @RecevingModuleID AND MSD.ReferenceID = RC.ReceivingCustomerWorkId
			INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RC.ManagementStructureId = RMS.EntityStructureId
			INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE CAST(DATEADD(SECOND, @BaseUtcOffsetSec, Rc.CreatedDate) as Date) = CAST(@SelectedDate AS DATE) AND EUR.RoleId IN (SELECT item FROM dbo.SplitString(@EmployeeRoleID, ','))
			AND RC.MasterCompanyId = @MasterCompanyId

		SELECT @Qty = COUNT(ReceivingCustomerWorkId) FROM #tmpReceivingCustomerWork
		SELECT DISTINCT WOBI.GrandTotal
		INTO #tmpWorkOrderBillingInvoicing
		FROM DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
			INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId IN (SELECT item FROM dbo.SplitString(@EmployeeRoleID, ',')) AND EUR.EmployeeId = @EmployeeId
		WHERE WOBI.IsVersionIncrease = 0 AND CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate) 
			AND WOBI.MasterCompanyId = @MasterCompanyId

		Select @WOBillingAmt = SUM(GrandTotal) from #tmpWorkOrderBillingInvoicing	

		SELECT @PartsSaleBillingAmt = ISNULL(SUM(SOBII.PartCost),0) + ISNULL(SUM(SOBII.SalesTax),0) + ISNULL(SUM(SOBII.OtherTax),0) + ISNULL(SUM(SOBII.MiscCharges),0)
		FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
			INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId AND SO.IsDeleted = 0 AND SO.IsActive = 1 AND ISNULL(SOBI.IsVersionIncrease, 0) = 0 AND ISNULL(SOBI.IsProforma, 0) = 0
			INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			INNER JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId AND ISNULL(SOBII.IsVersionIncrease, 0) = 0 AND ISNULL(SOBII.IsProforma, 0) = 0 AND SOP.SalesOrderPartId = SOBII.SalesOrderPartId
			LEFT JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
			INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SO.SalesOrderId
		WHERE CONVERT(DATE, InvoiceDate) = CONVERT(DATE, @SelectedDate)
			AND SOBI.MasterCompanyId = @MasterCompanyId AND ISNULL(SOBI.IsProforma,0) = 0
		GROUP BY CAST(InvoiceDate AS DATE)

		SELECT @MROWorkable = SUM(Quantity) FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) 
			INNER JOIN #tmpWorkOrderUserRole MSD WITH(NOLOCK) ON MSD.ReferenceID = WOP.ID
		WHERE WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
										WHERE MasterCompanyId = @MasterCompanyId 
										AND IsActive = 1 AND IsDeleted = 0)
		AND WOP.IsClosed = 0 AND WOP.MasterCompanyId = @MasterCompanyId 
		AND CONVERT(DATE,DATEADD(SECOND, @BaseUtcOffsetSec, WOP.CreatedDate)) = CONVERT(DATE, @SelectedDate)
		--AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, WOP.CreatedDate)) >= CONVERT(DATE, @BacklogStartDt) AND 
		--AND CONVERT(DATE,DATEADD(SECOND, @BaseUtcOffsetSec, WOP.CreatedDate)) <= CONVERT(DATE, @SelectedDate) 

		--SELECT @PartsSaleWorkable = SUM(ISNULL(SOPC.UnitSalesPrice,0)) 

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
				STKV.StockLineId NOT IN (SELECT SOBII.StockLineId FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
					INNER JOIN DBO.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND SOBII.IsVersionIncrease = 0
					Where SOBI.SalesOrderId = SOP.SalesOrderId AND SO.MasterCompanyId = 1) AND
				 SO.IsActive = 1
				AND SO.IsDeleted = 0
				AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, SO.CreatedDate)) = CONVERT(DATE, @SelectedDate)
				AND SO.MasterCompanyId = 1
				GROUP BY item.PartNumber, item.PartDescription, cond.[Description], item.ItemGroup, cust.Name, SO.SalesOrderNumber, emp.FirstName, emp.LastName,SOP.SalesOrderId,SOP.SalesOrderPartId,SOP.MasterCompanyId
				ORDER BY SO.SalesOrderNumber

		UPDATE TMP
		SET TMP.GrandTotal = ISNULL(TMP.GrandTotal,0) + ISNULL(partAmount.MiscCharges,0) - ISNULL(billedData.MiscCharges,0)
		FROM #tmpNonInvoiceDashboard TMP
		OUTER APPLY (
			SELECT ISNULL(SUM(sopc.MiscCharges),0) AS MiscCharges FROM DBO.SalesOrderPartCost sopc WITH (NOLOCK) 
					
						Where sopc.SalesOrderId = TMP.SalesOrderId AND sopc.SalesOrderPartId = TMP.SalesOrderPartId and  TMP.MasterCompanyId = 1
			) AS partAmount

		OUTER APPLY (
			SELECT ISNULL(SUM(SOBII.MiscCharges),0) AS MiscCharges FROM DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
						INNER JOIN DBO.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND SOBII.IsVersionIncrease = 0
						Where SOBI.SalesOrderId = TMP.SalesOrderId AND TMP.MasterCompanyId = 1
			) AS billedData


		select @PartsSaleWorkable = ISNULL(SUM(GrandTotal),0) from #tmpNonInvoiceDashboard

		SELECT @WOQProcessed = COUNT(WOQD.WorkOrderQuoteId) FROM DBO.WorkOrderQuote WOQ WITH (NOLOCK) 
			INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
			INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) on WOQD.WorkflowWorkOrderId = WOWF.WorkFlowWorkOrderId
			INNER JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) on WOP.ID = WOWF.WorkOrderPartNoId
			INNER JOIN #tmpWorkOrderUserRole MSD WITH(NOLOCK) ON MSD.ReferenceID = WOP.ID
		WHERE WOQ.SentDate IS NOT NULL
			AND CONVERT(DATE, WOQ.OpenDate) = CONVERT(DATE, @SelectedDate) 
			AND WOQ.MasterCompanyId = @MasterCompanyId

		SELECT @SQProcessed = COUNT(SQ.SpeedQuoteId) FROM DBO.SpeedQuote SQ WITH (NOLOCK) 
			INNER JOIN #tmpSpeedQuoteUserRole MSD WITH(NOLOCK) ON MSD.ReferenceID = SQ.SpeedQuoteId
		WHERE SQ.StatusId IN (SELECT Id FROM MasterSpeedQuoteStatus Where [Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
			AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SQ.MasterCompanyId = @MasterCompanyId

		SELECT @SOQProcessed = SUM(SOQM.NetSales) FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) 
			INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
			INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
			INNER JOIN #tmpSalesOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = SOQ.SalesOrderQuoteId
		WHERE SOQA.CustomerApprovedDate IS NOT NULL
			AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @SelectedDate) AND SOQ.MasterCompanyId = @MasterCompanyId

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