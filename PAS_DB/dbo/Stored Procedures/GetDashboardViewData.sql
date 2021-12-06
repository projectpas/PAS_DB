/*************************************************************

**************************************************************/ 
CREATE PROCEDURE [dbo].[GetDashboardViewData]
	@MasterCompanyId BIGINT = NULL,
	@Date DATETIME = NULL,
	@DashboardType INT = NULL,
	@EmployeeId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			DECLARE @BacklogStartDt AS DateTime;

			SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0

			IF (@DashboardType = 1)
			BEGIN
				SELECT rec_cust.PartNumber, item.PartDescription, rec_cust.WorkScope, item.ItemGroup,
				rec_cust.Quantity, wo.WorkOrderNum, rec_cust.CustomerName, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.ReceivingCustomerWork rec_cust WITH (NOLOCK)
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON rec_cust.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON rec_cust.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = rec_cust.ManagementStructureId
				WHERE rec_cust.IsActive = 1 
				AND rec_cust.IsDeleted = 0 
				AND EMS.EmployeeId = @EmployeeId
				AND CONVERT(DATE, rec_cust.ReceivedDate) = CONVERT(DATE, @Date) 
				AND rec_cust.MasterCompanyId = @MasterCompanyId
				ORDER BY WO.WorkOrderId
			END
			ELSE IF (@DashboardType = 2)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, wop.WorkScope, item.ItemGroup,
				wobi.GrandTotal, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderBillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON wop.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON WO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOBI.ManagementStructureId
				WHERE wobi.IsActive = 1 
				AND wobi.IsDeleted = 0 
				AND wobi.IsVersionIncrease = 0
				AND CONVERT(DATE, wobi.InvoiceDate) = CONVERT(DATE, @Date) 
				AND wobi.MasterCompanyId = @MasterCompanyId
				AND EMS.EmployeeId = @EmployeeId
			END
			ELSE IF (@DashboardType = 3)
			BEGIN
				SELECT
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				sobi.GrandTotal, cust.Name AS CustomerName, so.SalesOrderNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId
				LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON sobi.SalesOrderId = so.SalesOrderId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON so.SalesPersonId = emp.EmployeeId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
				LEFT JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON sop.ItemMasterId = item.ItemMasterId
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SO.ManagementStructureId
				WHERE sobi.IsActive = 1
				AND sobi.IsDeleted = 0
				AND CONVERT(DATE, sobi.InvoiceDate) = CONVERT(DATE, @Date)
				AND sobi.MasterCompanyId = @MasterCompanyId
				AND EMS.EmployeeId = @EmployeeId
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
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOP.ManagementStructureId
				WHERE 
				wop.WorkOrderStageId IN (SELECT BacklogMROStage FROM [dbo].[DashboardSettings] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId
										AND IsActive = 1 AND IsDeleted = 0)
				AND wop.IsActive = 1
				AND wop.IsDeleted = 0
				AND CONVERT(DATE, wop.CreatedDate) >= CONVERT(DATE, @BacklogStartDt)
				AND wop.MasterCompanyId = @MasterCompanyId
				AND EMS.EmployeeId = @EmployeeId
			END
			ELSE IF (@DashboardType = 5)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SOM.NetSales AS GrandTotal, cust.Name AS CustomerName, SO.SalesOrderNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SOMarginSummary SOM WITH (NOLOCK)
				INNER JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOM.SalesOrderId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
				LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SOP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SOP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SO.ManagementStructureId
				WHERE
				SO.StatusId NOT IN (SELECT Id FROM DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Closed')
				AND SO.IsActive = 1
				AND SO.IsDeleted = 0
				AND CONVERT(DATE, SO.CreatedDate) >= CONVERT(DATE, @BacklogStartDt)
				AND SO.MasterCompanyId = @MasterCompanyId
				AND EMS.EmployeeId = @EmployeeId
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
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = WOP.ManagementStructureId
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
				AND EMS.EmployeeId = @EmployeeId
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
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SQ.ManagementStructureId
				WHERE
				SQ.StatusId IN (SELECT Id FROM DBO.MasterSpeedQuoteStatus WITH (NOLOCK) WHERE 
						[Name] = 'Open' AND IsActive = 1 AND IsDeleted = 0)
				AND SQ.IsActive = 1
				AND SQ.IsDeleted = 0
				AND CONVERT(DATE, SQ.OpenDate) = CONVERT(DATE, @Date) 
				AND SQ.MasterCompanyId = @MasterCompanyId
				AND EMS.EmployeeId = @EmployeeId
			END
			ELSE IF (@DashboardType = 8)
			BEGIN
				SELECT DISTINCT
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SOQM.NetSales AS GrandTotal, cust.Name AS CustomerName, SOQ.SalesOrderQuoteNumber AS QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
				INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON SOQ.CustomerId = cust.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SOQP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SOQP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = SOQ.ManagementStructureId
				WHERE
				SOQA.CustomerApprovedDate IS NOT NULL
				AND SOQ.IsActive = 1
				AND SOQ.IsDeleted = 0
				AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @Date) 
				AND SOQ.MasterCompanyId = @MasterCompanyId
				AND EMS.EmployeeId = @EmployeeId
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