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

-- EXEC GetDashboardViewData 
************************************************************************/

CREATE   PROCEDURE [dbo].[GetDashboardViewData]
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
			DECLARE @RecevingModuleID AS INT =1;
			DECLARE @wopartModuleID AS INT =12
			DECLARE @woqModuleID AS INT =15
			DECLARE @SalesOrderModuleID AS INT =17
			DECLARE @SalesOrderQouteModuleID AS INT =18
			DECLARE @SpeedQouteModuleID AS INT =27

			SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK) 
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0

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
				wobi.GrandTotal, wo.CustomerName, wo.WorkOrderNum, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.WorkOrderBillingInvoicing wobi WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH (NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId
				LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK) ON wobi.WorkOrderId = WO.WorkOrderId
				LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
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
					item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
					sobi.GrandTotal, cust.Name AS CustomerName, so.SalesOrderNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
					FROM DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK)
					INNER JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobii.IsProforma,0) = 0
					LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON sobi.SalesOrderId = so.SalesOrderId
					LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON so.SalesPersonId = emp.EmployeeId
					LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
					LEFT JOIN DBO.SalesOrderPart sop WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
					LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON sop.ItemMasterId = item.ItemMasterId
					INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
					INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
					INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					WHERE sobi.IsActive = 1
					AND sobi.IsDeleted = 0
					AND ISNULL(sop.StockLineId,0) > 0
					AND CONVERT(DATE, sobi.InvoiceDate) = CONVERT(DATE, @Date)
					AND sobi.MasterCompanyId = @MasterCompanyId
					AND ISNULL(sobi.IsProforma,0) = 0
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
				AND CONVERT(DATE, wop.CreatedDate) >= CONVERT(DATE, @BacklogStartDt)
				AND wop.MasterCompanyId = @MasterCompanyId
			END
			ELSE IF (@DashboardType = 5)
			BEGIN
				SELECT 
				item.PartNumber, item.PartDescription, cond.[Description] AS Condition, item.ItemGroup,
				SUM(SOP.NetSales) AS GrandTotal, cust.Name AS CustomerName, SO.SalesOrderNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
				INNER JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SOP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SOP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SO.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderModuleID AND MSD.ReferenceID = SO.SalesOrderId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				WHERE
				SO.StatusId NOT IN (SELECT Id FROM DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Closed')
				AND SOP.SalesOrderPartId NOT IN (SELECT SalesOrderPartId FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
					INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
					Where SOS.SalesOrderId = SOP.SalesOrderId AND SO.MasterCompanyId = @MasterCompanyId)
				AND SO.IsActive = 1
				AND SO.IsDeleted = 0
				AND CONVERT(DATE, SO.CreatedDate) >= CONVERT(DATE, @BacklogStartDt)
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
				SOQM.NetSales AS GrandTotal,SOQP.NetSales, cust.Name AS CustomerName, SOQ.SalesOrderQuoteNumber AS QuoteNumber, (emp.FirstName + ' ' + emp.LastName) AS SalesPerson 
				FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
				INNER JOIN DBO.SOQuoteMarginSummary SOQM WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQM.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuoteApproval SOQA WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQA.SalesOrderQuoteId
				INNER JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				LEFT JOIN DBO.Customer cust WITH (NOLOCK) ON SOQ.CustomerId = cust.CustomerId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON SOQP.ConditionId = cond.ConditionId
				LEFT JOIN DBO.ItemMaster item WITH (NOLOCK) ON SOQP.ItemMasterId = item.ItemMasterId
				LEFT JOIN DBO.Employee emp WITH (NOLOCK) ON SOQ.SalesPersonId = emp.EmployeeId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SalesOrderQouteModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				WHERE
				SOQA.CustomerApprovedDate IS NOT NULL
				AND SOQ.IsActive = 1
				AND SOQ.IsDeleted = 0
				AND CONVERT(DATE, SOQ.OpenDate) = CONVERT(DATE, @Date) 
				AND SOQ.MasterCompanyId = @MasterCompanyId
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