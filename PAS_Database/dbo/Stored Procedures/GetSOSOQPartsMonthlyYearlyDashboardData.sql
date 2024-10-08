
/*************************************************************           
 ** File:   [GetSOSOQPartsMonthlyYearlyDashboardData]
 ** Author:   
 ** Description: This stored procedure is used to Get Parts Dashboard details
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    09/10/2024  Abhishek Jirawla		Created
EXEC GetSOSOQPartsMonthlyYearlyDashboardData 1, 2, '09/19/2024', 10
************************************************************************/

CREATE   PROCEDURE [dbo].[GetSOSOQPartsMonthlyYearlyDashboardData]
	@MasterCompanyId BIGINT = NULL,
	@EmployeeId BIGINT = NULL,
	@StartDate DATETIME2 = NULL,
	@TopNumberDetails INT = NULL
AS  
BEGIN  
  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  
		BEGIN TRANSACTION  
			BEGIN
				-- Declare variables
				DECLARE @MasterLoopID INT, @Month INT, @Day INT, @Year INT, @EmployeeRoleID NVARCHAR(MAX);
				DECLARE @SOQMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'SalesOrderQuote');
				DECLARE @SOMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'SalesOrder');

				-- Fetch the employee role IDs in a single query
				SELECT @EmployeeRoleID = STUFF((
						SELECT DISTINCT ',' + CAST(RoleId AS VARCHAR(100))
						FROM dbo.EmployeeUserRole WITH (NOLOCK)
						WHERE EmployeeId = @EmployeeId
						FOR XML PATH('')
					), 1, 1, '');

				IF @StartDate IS NULL
				BEGIN
					SET @StartDate = GETUTCDATE()
				END

				SET @Month = MONTH(@StartDate);
				SET @Day = DAY(@StartDate);

				--SET @Month = CASE WHEN MONTH(@StartDate) = 12 THEN 1 ELSE (MONTH(@StartDate) + 1) END;
				SET @Year = CASE WHEN MONTH(@StartDate) = 12 THEN YEAR(@StartDate) ELSE YEAR(@StartDate) - 1 END;
  
				IF OBJECT_ID(N'tempdb..#tmpDateOfMonth') IS NOT NULL
				BEGIN
					DROP TABLE #tmpDateOfMonth
				END

				CREATE TABLE #tmpDateOfMonth (
					ID bigint NOT NULL IDENTITY,
					DateOfMonth DateTime NULL
				)
				-- Prepare dates of the current month
				;WITH MonthDays_CTE(DayNum) AS
				(
					SELECT DATEFROMPARTS(YEAR(@StartDate), @Month, 1) AS DayNum
					UNION ALL
					SELECT DATEADD(DAY, 1, DayNum)
					FROM MonthDays_CTE
					WHERE DayNum < EOMONTH(DATEFROMPARTS(YEAR(@StartDate), @Month, 1)) AND DayNum <= DATEADD(DAY, -1, @StartDate)
				)

				INSERT INTO #tmpDateOfMonth (DateOfMonth) SELECT DayNum FROM MonthDays_CTE ORDER BY DayNum;

				-- Ensure we have a date range for the current month up to the current day
				DECLARE @BacklogStartDt AS DateTime;

				SELECT TOP 1 @BacklogStartDt = BacklogStartDate FROM [dbo].[DashboardSettings] WITH (NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

				IF OBJECT_ID(N'tempdb..#tmpMonthlyDataSOQParts') IS NOT NULL
				BEGIN
					DROP TABLE #tmpMonthlyDataSOQParts
				END

				CREATE TABLE #tmpMonthlyDataSOQParts (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpMonthlyDataSOQ') IS NOT NULL
				BEGIN
					DROP TABLE #tmpMonthlyDataSOQ
				END

				CREATE TABLE #tmpMonthlyDataSOQ (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpMonthlyDataSOQAmt') IS NOT NULL
				BEGIN
					DROP TABLE #tmpMonthlyDataSOQAmt
				END

				CREATE TABLE #tmpMonthlyDataSOQAmt (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpMonthlyDataSOParts') IS NOT NULL
				BEGIN
					DROP TABLE #tmpMonthlyDataSOParts
				END

				CREATE TABLE #tmpMonthlyDataSOParts (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpMonthlyDataSO') IS NOT NULL
				BEGIN
					DROP TABLE #tmpMonthlyDataSO
				END

				CREATE TABLE #tmpMonthlyDataSO (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpMonthlyDataSOAmt') IS NOT NULL
				BEGIN
					DROP TABLE #tmpMonthlyDataSOAmt
				END

				CREATE TABLE #tmpMonthlyDataSOAmt (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				SELECT @MasterLoopID = MIN(ID) FROM #tmpDateOfMonth;

				-- Monthly Dashboard
				WHILE (@MasterLoopID <= @Day)
				BEGIN
					DECLARE @SelectedDate DateTime;
					SELECT @SelectedDate = DateOfMonth FROM #tmpDateOfMonth WHERE ID = @MasterLoopID;

					-- Total Parts Sales Order Quote -----------------------------------------------------------------------------------------------------------------------
					DECLARE @CntsSOQParts INT = 0; 
					;WITH tmpSalesOrderQuotePart as (
					SELECT DISTINCT  SOQP.SalesOrderQuotePartId
					FROM DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
					WHERE Cast(SOQ.OpenDate as Date) = CONVERT(DATE, @SelectedDate)
					AND SOQP.MasterCompanyId = @MasterCompanyId AND SOQP.IsDeleted = 0
					)
					SELECT @CntsSOQParts = COUNT(SalesOrderQuotePartId) FROM tmpSalesOrderQuotePart

					INSERT INTO #tmpMonthlyDataSOQParts (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsSOQParts, 0)

					-- Total Parts Sales Order -------------------------------------------------------------------------------------------------
					DECLARE @CntsSOParts INT = 0;
					;WITH tmpSalesOrderPart as (
					SELECT DISTINCT  SOP.SalesOrderPartId
					FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
					WHERE Cast(SO.OpenDate as Date) = CONVERT(DATE, @SelectedDate)
					AND SOP.MasterCompanyId = @MasterCompanyId AND SOP.IsDeleted = 0
					GROUP BY SOP.SalesOrderPartId
					)
					SELECT @CntsSOParts = COUNT(SalesOrderPartId) FROM tmpSalesOrderPart

					INSERT INTO #tmpMonthlyDataSOParts (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsSOParts, 0)

					-- Total Sales Order Quote---------------------------------------------------------------------------------------------------
					DECLARE @CntsSOQ INT = 0;
					;WITH tmpSalesOrderQuote as (
					SELECT DISTINCT  SOQ.SalesOrderQuoteId
					FROM dbo.SalesOrderQuote SOQ WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
					WHERE Cast(SOQ.OpenDate as Date) = CONVERT(DATE, @SelectedDate)
					AND SOQ.MasterCompanyId = @MasterCompanyId AND SOQ.IsDeleted = 0
					)
					SELECT @CntsSOQ = COUNT(SalesOrderQuoteId) FROM tmpSalesOrderQuote

					INSERT INTO #tmpMonthlyDataSOQ (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsSOQ, 0)

					-- Total Sales Order -------------------------------------------------------------------------------------------------------------
					DECLARE @CntsSO INT = 0;
					;WITH tmpSalesOrder as (
					SELECT DISTINCT  SO.SalesOrderId
					FROM dbo.SalesOrder SO WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
					WHERE Cast(SO.OpenDate as Date) = CONVERT(DATE, @SelectedDate)
						AND SO.MasterCompanyId = @MasterCompanyId AND SO.IsDeleted = 0
					)
					SELECT @CntsSO = COUNT(SalesOrderId) FROM tmpSalesOrder

					INSERT INTO #tmpMonthlyDataSO (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsSO, 0)

					-- Total Sales Order Quote Amount------------------------------------------------------------------------------------------------------
					DECLARE @CntsSOQAmt DECIMAL(18, 2) = 0;;
					;WITH tmpSalesOrderQuoteAmt(Total, Mnth) as (
					SELECT SUM(ISNULL(SOQP.SalesPriceExtended, 0) + ISNULL(SOQC.BillingAmount, 0) + ISNULL(SOQP.TaxAmount,0)), @Month
					FROM DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
						LEFT OUTER JOIN dbo.SalesOrderQuoteCharges SOQC ON SOQC.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
					WHERE Cast(SOQ.OpenDate as Date) = CONVERT(DATE, @SelectedDate)
					AND SOQ.MasterCompanyId = @MasterCompanyId AND SOQ.IsDeleted = 0
					)
					SELECT @CntsSOQAmt = SUM(Total) FROM tmpSalesOrderQuoteAmt

					INSERT INTO #tmpMonthlyDataSOQAmt (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsSOQAmt, 0)

					-- Total Sales Order Amount
					DECLARE @CntsSOAmt DECIMAL(18, 2) = 0;;
					;WITH tmpSalesOrderAmt(Total, Mnth) as (
					SELECT SUM(ISNULL(SOP.SalesPriceExtended, 0) + ISNULL(SOC.BillingAmount, 0) + ISNULL(SOP.TaxAmount,0)), @Month--SUM(SOP.NetSales), @Month
					FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
						LEFT OUTER JOIN dbo.SalesOrderCharges SOC ON SOC.SalesOrderPartId = SOP.SalesOrderPartId
					WHERE Cast(SO.OpenDate as Date) = CONVERT(DATE, @SelectedDate)
					AND SO.MasterCompanyId = @MasterCompanyId AND SO.IsDeleted = 0
					)
					SELECT @CntsSOAmt = SUM(Total) FROM tmpSalesOrderAmt

					INSERT INTO #tmpMonthlyDataSOAmt (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsSOAmt, 0)

					SET @MasterLoopID = @MasterLoopID + 1
				END


				-- Yearly 
				SET @Month = CASE WHEN MONTH(@StartDate) = 12 THEN 1 ELSE (MONTH(@StartDate)) END;
				SET @Year = CASE WHEN MONTH(@StartDate) = 12 THEN YEAR(@StartDate) ELSE YEAR(@StartDate) - 1 END;


				IF OBJECT_ID(N'tempdb..#tmpYearlyDataSOQParts') IS NOT NULL
				BEGIN
					DROP TABLE #tmpYearlyDataSOQParts
				END

				CREATE TABLE #tmpYearlyDataSOQParts (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpYearlyDataSOQ') IS NOT NULL
				BEGIN
					DROP TABLE #tmpYearlyDataSOQ
				END

				CREATE TABLE #tmpYearlyDataSOQ (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpYearlyDataSOQAmt') IS NOT NULL
				BEGIN
					DROP TABLE #tmpYearlyDataSOQAmt
				END

				CREATE TABLE #tmpYearlyDataSOQAmt (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpYearlyDataSOParts') IS NOT NULL
				BEGIN
					DROP TABLE #tmpYearlyDataSOParts
				END

				CREATE TABLE #tmpYearlyDataSOParts (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpYearlyDataSO') IS NOT NULL
				BEGIN
					DROP TABLE #tmpYearlyDataSO
				END

				CREATE TABLE #tmpYearlyDataSO (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				IF OBJECT_ID(N'tempdb..#tmpYearlyDataSOAmt') IS NOT NULL
				BEGIN
					DROP TABLE #tmpYearlyDataSOAmt
				END

				CREATE TABLE #tmpYearlyDataSOAmt (
					ID bigint NOT NULL IDENTITY,
					DateProcess DateTime NULL,
					ResultData DECIMAL(18, 2) NULL
				)

				SET @SelectedDate = DATEFROMPARTS(@Year, @Month, 1)

				SELECT @MasterLoopID = 1;

				-- Yearly Dashboard
				WHILE (@MasterLoopID <= 13)
				BEGIN
					SET @Month = MONTH(CONVERT(DATE, @SelectedDate));
					SET @Year = YEAR(CONVERT(DATE, @SelectedDate));

					-- Total Parts Sales Order Quote -----------------------------------------------------------------------------------------------------------------------
					DECLARE @CntsYearlySOQParts INT = 0;
					;WITH tmpYearlySalesOrderQuotePart as (
					SELECT DISTINCT  SOQP.SalesOrderQuotePartId
					FROM DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
					WHERE MONTH(Cast(SOQ.OpenDate as Date)) = @Month AND YEAR(Cast(SOQ.OpenDate as Date)) = @YEAR
					AND SOQP.MasterCompanyId = @MasterCompanyId AND SOQP.IsDeleted = 0
					)
					SELECT @CntsYearlySOQParts = COUNT(SalesOrderQuotePartId) FROM tmpYearlySalesOrderQuotePart

					INSERT INTO #tmpYearlyDataSOQParts (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsYearlySOQParts, 0)

					-- Total Parts Sales Order -------------------------------------------------------------------------------------------------
					DECLARE @CntsYearlySOParts INT = 0;
					--SELECT @Cnts = SUM(Quantity) 
					;WITH tmpYearlySalesOrderPart as (
					SELECT DISTINCT  SOP.SalesOrderPartId
					FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
					WHERE MONTH(Cast(SO.OpenDate as Date)) = @Month AND YEAR(Cast(SO.OpenDate as Date)) = @YEAR
					AND SOP.MasterCompanyId = @MasterCompanyId AND SOP.IsDeleted = 0
					)
					SELECT @CntsYearlySOParts = COUNT(SalesOrderPartId) FROM tmpYearlySalesOrderPart

					INSERT INTO #tmpYearlyDataSOParts (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsYearlySOParts, 0)

					-- Total Sales Order Quote---------------------------------------------------------------------------------------------------
					DECLARE @CntsYearlySOQ INT = 0;
					;WITH tmpYearlySalesOrderQuote as (
					SELECT DISTINCT  SOQ.SalesOrderQuoteId
					FROM dbo.SalesOrderQuote SOQ WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
					WHERE MONTH(Cast(SOQ.OpenDate as Date)) = @Month AND YEAR(Cast(SOQ.OpenDate as Date)) = @YEAR
					AND SOQ.MasterCompanyId = @MasterCompanyId AND SOQ.IsDeleted = 0
					)
					SELECT @CntsYearlySOQ = COUNT(SalesOrderQuoteId) FROM tmpYearlySalesOrderQuote

					INSERT INTO #tmpYearlyDataSOQ (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsYearlySOQ, 0)

					-- Total Sales Order -------------------------------------------------------------------------------------------------------------
					DECLARE @CntsYearlySO INT = 0;
					;WITH tmpYearlySalesOrder as (
					SELECT DISTINCT  SO.SalesOrderId
					FROM dbo.SalesOrder SO WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
					WHERE MONTH(Cast(SO.OpenDate as Date)) = @Month AND YEAR(Cast(SO.OpenDate as Date)) = @YEAR
					AND SO.MasterCompanyId = @MasterCompanyId AND SO.IsDeleted = 0
					)
					SELECT @CntsYearlySO = COUNT(SalesOrderId) FROM tmpYearlySalesOrder

					INSERT INTO #tmpYearlyDataSO (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsYearlySO, 0)

					-- Total Sales Order Quote Amount------------------------------------------------------------------------------------------------------
					DECLARE @CntsYearlySOQAmt DECIMAL(18, 2) = 0;;
					;WITH tmpYearlySalesOrderQuoteAmt(Total, Mnth) as (
					SELECT SUM(ISNULL(SOQP.SalesPriceExtended, 0) + ISNULL(SOQC.BillingAmount, 0) + ISNULL(SOQP.TaxAmount,0)), @Month
					FROM DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
						LEFT OUTER JOIN dbo.SalesOrderQuoteCharges SOQC ON SOQC.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
					WHERE MONTH(Cast(SOQ.OpenDate as Date)) = @Month AND YEAR(Cast(SOQ.OpenDate as Date)) = @YEAR
					AND SOQ.MasterCompanyId = @MasterCompanyId AND SOQ.IsDeleted = 0
					)
					SELECT @CntsYearlySOQAmt = SUM(Total) FROM tmpYearlySalesOrderQuoteAmt

					INSERT INTO #tmpYearlyDataSOQAmt (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsYearlySOQAmt, 0)

					-- Total Sales Order Amount
					DECLARE @CntsYearlySOAmt DECIMAL(18, 2) = 0;;
					;WITH tmpYearlySalesOrderAmt(Total, Mnth) as (
					SELECT SUM(ISNULL(SOP.SalesPriceExtended, 0) + ISNULL(SOC.BillingAmount, 0) + ISNULL(SOP.TaxAmount,0)), @Month
					FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
						LEFT OUTER JOIN dbo.SalesOrderCharges SOC ON SOC.SalesOrderPartId = SOP.SalesOrderPartId
					WHERE MONTH(Cast(SO.OpenDate as Date)) = @Month AND YEAR(Cast(SO.OpenDate as Date)) = @YEAR
					AND SO.MasterCompanyId = @MasterCompanyId AND SO.IsDeleted = 0
					)
					SELECT @CntsYearlySOAmt = SUM(Total) FROM tmpYearlySalesOrderAmt

					INSERT INTO #tmpYearlyDataSOAmt (DateProcess, ResultData)
					SELECT CONVERT(DATE, @SelectedDate) AS DateProcess, ISNULL(@CntsYearlySOAmt, 0)

					SELECT @SelectedDate = DATEADD(MONTH, 1, @SelectedDate);

					SET @MasterLoopID = @MasterLoopID + 1;
				END


				-- Get the current year and month
				DECLARE @CurrentYear INT = YEAR(@StartDate);
				DECLARE @CurrentMonth INT = MONTH(@StartDate);

				----Top 10 Parts Quoted
				IF OBJECT_ID(N'tempdb..#tmpTop10PartQuoted') IS NOT NULL
				BEGIN
					DROP TABLE #tmpTop10PartQuoted
				END

				CREATE TABLE #tmpTop10PartQuoted (
					ID bigint NOT NULL IDENTITY,
					PartNumber VARCHAR(100)  NULL,
					TotalSalesCount INT NULL
				)

				;WITH tmpTop10SalesOrderQuotePart as (
					SELECT
						IM.partnumber,
						IM.ItemMasterId,
						COUNT(SOQP.QtyQuoted) AS TotalSalesCount
					FROM DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
						INNER JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOQP.ItemMasterId = IM.ItemMasterId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
					WHERE YEAR(SOQ.OpenDate) = @CurrentYear 
					AND MONTH(SOQ.OpenDate) = @CurrentMonth 
					AND SOQ.OpenDate <= @StartDate
					AND SOQP.MasterCompanyId = @MasterCompanyId AND SOQP.IsDeleted = 0
					GROUP BY 
						IM.partnumber, 
						IM.ItemMasterId
					)
					INSERT INTO #tmpTop10PartQuoted (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount  -- Number of sales for each part
					FROM tmpTop10SalesOrderQuotePart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;

					----Top 10 Parts Sold
					IF OBJECT_ID(N'tempdb..#tmpTop10PartSold') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10PartSold
					END

					CREATE TABLE #tmpTop10PartSold (
						ID bigint NOT NULL IDENTITY,
						PartNumber VARCHAR(100)  NULL,
						TotalSalesCount INT
					)

					DECLARE @ShippedStatusId INT, @PostedStatusId VARCHAR(100)
					SELECT @ShippedStatusId = SOPartStatusId FROM SOPartStatus WHERE PartStatus = 'Shipped'
					SELECT @PostedStatusId = InvoiceStatus FROM SalesOrderBillingInvoicing WHERE InvoiceStatus = 'Invoiced'

					;WITH tmpTop10SalesOrderPartSold as (
						SELECT
							IM.partnumber,
							IM.ItemMasterId,
							COUNT(Qty) AS TotalSalesCount
						FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
							INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
							INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
							--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
							--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
							LEFT OUTER JOIN dbo.SalesOrderShipping SOS WITH (NOLOCK) ON SO.SalesOrderId = SOS.SalesOrderId
							LEFT OUTER JOIN dbo.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
							LEFT OUTER JOIN dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId
							LEFT OUTER JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId AND SOP.SalesOrderPartId = SOBII.SalesOrderPartId
						WHERE  ((YEAR(SO.ShippedDate) = @CurrentYear 
						AND MONTH(SO.ShippedDate) = @CurrentMonth
						AND CAST(SO.ShippedDate AS DATE) <= CAST(@StartDate AS DATE)
						AND SOP.StatusId = @ShippedStatusId AND SOS.AirwayBill IS NOT NULL) OR (YEAR(SOBI.InvoiceDate) = @CurrentYear 
						AND MONTH(SOBI.InvoiceDate) = @CurrentMonth
						AND CAST(SOBI.InvoiceDate AS DATE) <= CAST(@StartDate AS DATE)
						AND SOBillingInvoicingItemId IS NOT NULL AND SOBI.InvoiceStatus = @PostedStatusId))
						--AND EUR.RoleId IN(SELECT item FROM dbo.SplitString(@EmployeeRoleID, ','))
						AND SOP.MasterCompanyId = @MasterCompanyId AND SOP.IsDeleted = 0
						GROUP BY
							IM.partnumber, 
							IM.ItemMasterId
					)
					INSERT INTO #tmpTop10PartSold (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount  -- Number of sales for each part
					FROM tmpTop10SalesOrderPartSold
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;

					----Top 10 Customers
					IF OBJECT_ID(N'tempdb..#tmpTop10Customers') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop10Customers
					END

					CREATE TABLE #tmpTop10Customers (
						ID bigint NOT NULL IDENTITY,
						CustomerName VARCHAR(200)  NULL,
						TotalSalesCount DECIMAL(18, 2) NULL
					)

					;WITH tmpTop10Customer as (
						SELECT
							C.[Name] AS CustomerName,
							C.CustomerId,
							SUM(SOP.NetSales) AS TotalSalesCount
						FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
							INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
							INNER JOIN Customer C WITH (NOLOCK) ON C.CustomerId = SO.CustomerId
							INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
						WHERE YEAR(SO.OpenDate) = @CurrentYear
						AND MONTH(SO.OpenDate) = @CurrentMonth 
						AND SO.OpenDate <= @StartDate
						AND SOP.MasterCompanyId = @MasterCompanyId AND SOP.IsDeleted = 0
						GROUP BY
							C.Name,
							C.CustomerId
					)
					INSERT INTO #tmpTop10Customers (CustomerName, TotalSalesCount)
					SELECT
						CustomerName,         
						TotalSalesCount
					FROM tmpTop10Customer
					WHERE TotalSalesCount > 0
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST @TopNumberDetails ROWS ONLY;


				DECLARE @MonthValue INT = Month(@StartDate)
				DECLARE @YearStartDate DATE = DATEFROMPARTS(YEAR(@StartDate), 1, 1);

				DECLARE @soqNumOfPartsYearly INT, @soqYearlyCount INT, @soqYearlyAmount DECIMAL(18, 2), @soNumOfPartsYearly INT, @soYearlyCount INT, @soYearlyAmount DECIMAL(18, 2)

				SELECT @soqNumOfPartsYearly = COUNT(SalesOrderQuotePartId)
				FROM SalesOrderQuotePart SOQP
					INNER JOIN SalesOrderQuote SOQ ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				WHERE SOQ.OpenDate BETWEEN @YearStartDate AND @StartDate
					AND SOQP.MasterCompanyId = @MasterCompanyId AND SOQP.IsDeleted = 0;

				SELECT @soqYearlyCount = COUNT(SOQ.SalesOrderQuoteId)
				FROM SalesOrderQuote SOQ
				WHERE SOQ.OpenDate BETWEEN @YearStartDate AND @StartDate
					AND SOQ.MasterCompanyId = @MasterCompanyId AND SOQ.IsDeleted = 0;

				SELECT @soqYearlyAmount = SUM(SOQP.NetSales)
				FROM SalesOrderQuotePart SOQP
					INNER JOIN SalesOrderQuote SOQ ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				WHERE SOQ.OpenDate BETWEEN @YearStartDate AND @StartDate
					AND SOQP.MasterCompanyId = @MasterCompanyId AND SOQP.IsDeleted = 0;


				SELECT @soNumOfPartsYearly = COUNT(SalesOrderPartId)
				FROM SalesOrderPart SOP
					INNER JOIN SalesOrder SO ON SO.SalesOrderId = SOP.SalesOrderId
				WHERE SO.OpenDate BETWEEN @YearStartDate AND @StartDate
					AND SOP.MasterCompanyId = @MasterCompanyId AND SOP.IsDeleted = 0;

				SELECT @soYearlyCount = COUNT(SO.SalesOrderId)
				FROM SalesOrder SO
				WHERE SO.OpenDate BETWEEN @YearStartDate AND @StartDate
					AND SO.MasterCompanyId = @MasterCompanyId AND SO.IsDeleted = 0;

				SELECT @soYearlyAmount = SUM(SOP.NetSales)
				FROM SalesOrderPart SOP
					INNER JOIN SalesOrder SO ON SO.SalesOrderId = SOP.SalesOrderId
				WHERE SO.OpenDate BETWEEN @YearStartDate AND @StartDate
					AND SOP.MasterCompanyId = @MasterCompanyId AND SOP.IsDeleted = 0;


				SELECT ISNULL((SELECT SUM(ResultData) FROM #tmpMonthlyDataSOQParts) , 0) AS soqNumOfPartsMonthly, ISNULL((SELECT SUM(ResultData) FROM #tmpMonthlyDataSOQ) , 0) AS soqMonthlyCount, ISNULL((SELECT SUM(ResultData) FROM #tmpMonthlyDataSOQAMT) , 0) AS soqMonthlyAmount, 
					ISNULL((SELECT SUM(ResultData) FROM #tmpMonthlyDataSOParts) , 0) AS soNumOfPartsMonthly, ISNULL((SELECT SUM(ResultData) FROM #tmpMonthlyDataSO) , 0) AS soMonthlyCount, ISNULL((SELECT SUM(ResultData) FROM #tmpMonthlyDataSOAMT) , 0) AS soMonthlyAmount, 
					--ISNULL((SELECT SUM(ResultData) FROM #tmpYearlyDataSOQParts), 0) AS soqNumOfPartsYearly, ISNULL((SELECT SUM(ResultData) FROM #tmpYearlyDataSOQ) , 0) AS soqYearlyCount, ISNULL((SELECT SUM(ResultData) FROM #tmpYearlyDataSOQAMT) , 0) AS soqYearlyAmount,
					--ISNULL((SELECT SUM(ResultData) FROM #tmpYearlyDataSOParts), 0) AS soNumOfPartsYearly, ISNULL((SELECT SUM(ResultData) FROM #tmpYearlyDataSO) , 0) AS soYearlyCount, ISNULL((SELECT SUM(ResultData) FROM #tmpYearlyDataSOAMT) , 0) AS soYearlyAmount
					ISNULL(@soqNumOfPartsYearly, 0) AS soqNumOfPartsYearly, ISNULL(@soqYearlyCount, 0) AS soqYearlyCount, ISNULL(@soqYearlyAmount, 0) AS soqYearlyAmount, 
					ISNULL(@soNumOfPartsYearly, 0) AS soNumOfPartsYearly, ISNULL(@soYearlyCount, 0) AS soYearlyCount, ISNULL(@soYearlyAmount, 0) AS soYearlyAmount					

				SELECT ResultData AS barChartLabels_PartSaleMonthlySOQBilling FROM #tmpMonthlyDataSOQAmt

				SELECT ResultData AS barChartLabels_PartSaleMonthlySOBilling FROM #tmpMonthlyDataSOAmt

				SELECT ResultData AS barChartLabels_PartSaleYearlySOQBilling FROM #tmpYearlyDataSOQAmt

				SELECT ResultData AS barChartLabels_PartSaleYearlySOBilling FROM #tmpYearlyDataSOAmt

				SELECT TotalSalesCount AS col1, PartNumber AS col2 FROM #tmpTop10PartQuoted

				SELECT TotalSalesCount AS col1, PartNumber AS col2 FROM #tmpTop10PartSold

				SELECT TotalSalesCount AS col1, CustomerName AS col2 FROM #tmpTop10Customers
			END  
		COMMIT  TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
			PRINT 'ROLLBACK'  
            ROLLBACK TRAN;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetSOSOQPartsMonthlyYearlyDashboardData'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''--+ ISNULL(@MasterCompanyId, '') 
                 
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
        RETURN(1);  
    END CATCH    
END