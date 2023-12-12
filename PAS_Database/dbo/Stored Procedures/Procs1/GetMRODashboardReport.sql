/*************************************************************           
 ** File:   [GetMRODashboardReport]           
 ** Author:   Vishal Suthar
 ** Description: Get MRO Data for Dashboard
 ** Purpose:         
 ** Date:   25-Aug-2023
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/25/2023   Vishal Suthar Created
     
 EXECUTE [GetMRODashboardReport] 1
**************************************************************/
CREATE   PROCEDURE [dbo].[GetMRODashboardReport]
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @CustomerModule INT=1;

		SELECT DISTINCT UPPER(IM.partnumber) AS MPN, 
		UPPER(IM.PartDescription) AS MPNDescription, 
		UPPER(ISNULL(Stk.SerialNumber, '')) AS SerialNumber,
		UPPER(IM.ItemGroup) AS ItemGroup, UPPER(IM.ManufacturerName) AS Manufacturer,
		UPPER(WOS.Stage) AS Stage,
		WOTAT.Days AS DaysInStage,
		UPPER(WO.CustomerName) AS CustomerName,
		STUFF((SELECT ', ' + UPPER(CC.Description)
			FROM dbo.ClassificationMapping cm WITH (NOLOCK)
			INNER JOIN dbo.CustomerClassification CC WITH (NOLOCK) ON CC.CustomerClassificationId=CM.ClasificationId
			WHERE cm.ReferenceId=C.CustomerId AND cm.ModuleId = @CustomerModule
			FOR XML PATH('')), 1, 1, '') 'CustomerClassification',
		UPPER(Addr.Line1) AS Address1,
		UPPER(Addr.Line2) AS Address2,
		UPPER(Addr.City) AS City,
		UPPER(Addr.StateOrProvince) AS State,
		UPPER(Cont.countries_name) AS Country,
		UPPER(WO.WorkOrderNum) AS WorkOrderNum,
		WO.OpenDate,
		WOP.CustomerRequestDate,
		WOP.EstimatedShipDate,
		WOP.ReceivedDate,
		WOShip.ShipDate AS MPNShipDate,
		WOBill.InvoiceDate AS MPNInvoiceDate,
		ISNULL(WOBill.GrandTotal, 0) AS InvoiceAmount,
		ISNULL(WOPCost.PartsCost, 0) AS MaterialCost, 
		ISNULL(WOPCost.LaborCost, 0) AS LaborCost,
		WOPCost.OtherCost,
		WOPCost.ActualMargin AS MarginAmount,
		WOPCost.ActualMarginPercentage AS MarginPercentage,
		UPPER(Curr.Code) AS Currency,
		WOP.TATDaysCurrent AS TAT,
		UPPER(ISNULL(WOQ.QuoteNumber, '')) WOQuote,
		CASE WHEN WOQD.QuoteMethod = 1 THEN 'Use Flat Rate' ELSE 'Build Up From Detail Tabs' END QuoteMethod,
		WOQD.MaterialCost AS QuoteMaterialCost,
		WOQD.LaborCost AS QuoteLaborCost,
		WOQD.ChargesCost AS QuoteOtherCost,
		CASE WHEN WOQD.QuoteMethod = 1 THEN WOQD.CommonFlatRate - (WOQD.MaterialCost + WOQD.LaborCost + WOQD.ChargesCost) ELSE ((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount) - (WOQD.MaterialCost + WOQD.LaborCost + WOQD.ChargesCost)) END AS QuoteMarginAmount,
		CASE WHEN WOQD.QuoteMethod = 1 
			THEN 
				CASE WHEN WOQD.CommonFlatRate > 0 
					THEN ((WOQD.CommonFlatRate - (WOQD.MaterialCost + WOQD.LaborCost + WOQD.ChargesCost)) / WOQD.CommonFlatRate) * 100 
				ELSE 
					CASE WHEN (WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount) > 0 
						THEN (((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount) - (WOQD.MaterialCost + WOQD.LaborCost + WOQD.ChargesCost)) / (WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount)) * 100
					ELSE 
						0 
					END 
				END 
			ELSE 
				0 
		END AS QuoteMarginPercentage,
		UPPER(WOP.WorkScope) WorkScope,
		UPPER(FinalWorkScope.Memo) AS FinalWorkScope,
		WOLH.TotalWorkHours AS TotalLaborHrs,
		UPPER(EMP_Tech.FirstName + ' ' + EMP_Tech.LastName) AS Mechanic
		FROM DBO.WorkOrder WO WITH (NOLOCK)
		INNER JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
		INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId AND WOWF.WorkOrderPartNoId = WOP.ID
		INNER JOIN DBO.WorkOrderStage WOS WITH (NOLOCK) ON WOP.WorkOrderStageId = WOS.WorkOrderStageId
		INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
		INNER JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId
		INNER JOIN DBO.WorkOrderMPNCostDetails WOPCost WITH (NOLOCK) ON WOPCost.WOPartNoId = WOP.ID
		LEFT JOIN DBO.[Address] Addr WITH (NOLOCK) ON Addr.AddressId = C.AddressId
		LEFT JOIN DBO.Countries Cont WITH (NOLOCK) ON Cont.countries_id = Addr.CountryId
		LEFT JOIN DBO.Stockline Stk WITH (NOLOCK) ON WOP.StockLineId = Stk.StockLineId		
		LEFT JOIN DBO.WorkOrderTurnArroundTime WOTAT WITH (NOLOCK) ON WOP.ID = WOTAT.WorkOrderPartNoId AND WOTAT.CurrentStageId = WOP.WorkOrderStageId
		LEFT JOIN DBO.WorkOrderShippingItem WOShipItem WITH (NOLOCK) ON WOShipItem.WorkOrderPartNumId = WOP.ID
		LEFT JOIN DBO.WorkOrderShipping WOShip WITH (NOLOCK) ON WOShipItem.WorkOrderShippingId = WOShip.WorkOrderShippingId
		LEFT JOIN DBO.WorkOrderBillingInvoicing WOBill WITH (NOLOCK) ON WOBill.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOBill.IsVersionIncrease = 0
		LEFT JOIN DBO.Currency Curr WITH (NOLOCK) ON Curr.CurrencyId = WOBill.CurrencyId
		LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WOQ.WorkOrderId = WO.WorkOrderId
		LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
		LEFT JOIN DBO.WorkOrderLaborHeader WOLH WITH (NOLOCK) ON WOLH.WorkOrderId = WO.WorkOrderId
		LEFT JOIN DBO.Employee EMP_Tech WITH (NOLOCK) ON EMP_Tech.EmployeeId = WOP.TechnicianId
		LEFT JOIN DBO.Condition FinalWorkScope WITH (NOLOCK) ON FinalWorkScope.ConditionId = WOP.RevisedConditionId
		WHERE WO.IsActive = 1 AND WO.IsDeleted = 0 AND WO.MasterCompanyId = @MasterCompanyId;

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetMRODashboardReport'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);           
	END CATCH
END