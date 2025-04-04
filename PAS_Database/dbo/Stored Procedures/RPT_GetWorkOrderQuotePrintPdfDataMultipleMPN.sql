/*************************************************************             
 ** File:   [RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN]             
 ** Author:   RAJESH GAMI  
 ** Description: This stored procedure is used to get work order quote pdf details for multiple MPN 
 ** Purpose:           
 ** Date:   12-FEB-2025          
            
 ** PARAMETERS:   
 ** RETURN VALUE:             
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			 Author			   Change Description              
 ** --   --------		 -------			--------------------------------            
    1    12-FEB-2025	 RAJESH GAMI		Created  
    2    24-FEB-2025	 RAJESH GAMI		Fixed the Total Amount Issue

--EXEC [RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN] 6561,'7844',0  
**************************************************************/  
CREATE   PROCEDURE [dbo].[RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN]  
 @WorkOrderQuoteId bigint,  
 @workOrderPartNoIds varchar(max),
 @isByPartIds INT = 0
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
   			IF OBJECT_ID(N'tempdb..#tmpQuoteIds') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpQuoteIds
			END

			IF OBJECT_ID(N'tempdb..#tmpQuotetblMulti') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpQuotetblMulti
			END
			IF OBJECT_ID(N'tempdb..#tblTempQuoteMain') IS NOT NULL    
			BEGIN    
				DROP TABLE #tblTempQuoteMain
			END
			DECLARE @totalCount INT =0,@currentRow INT = 1,@sql NVARCHAR(MAX), @PartId BIGINT = 0;
			DECLARE @TotalFreight DECIMAL(18,2)=0 ,@TotalCharges  DECIMAL(18,2)=0,@SubTotal  DECIMAL(18,2)=0,@WOQGrandTotal  DECIMAL(18,2)=0,@FinalSalesTaxes  DECIMAL(18,2)=0,@FinalOtherTaxes  DECIMAL(18,2) =0
			DECLARE @WOId BIGINT = (SELECT WorkorderId FROM DBO.WorkOrderQuote WITH(NOLOCK) Where WorkOrderQuoteId = @WorkOrderQuoteId);
			DECLARE @corrective VARCHAR(20) = 'corrective action'

			CREATE TABLE #tblTempQuoteMain (
				ID INT,
				ItemMasterId INT,
				PartNumber NVARCHAR(255),
				PartDescription NVARCHAR(500),
				RevisedPartNo NVARCHAR(255),
				Revenue DECIMAL(18, 2),
				MaterialCost DECIMAL(18, 2),
				MaterialRevenuePercentage DECIMAL(18, 2),
				LaborCost DECIMAL(18, 2),
				LaborRevenuePercentage DECIMAL(18, 2),
				OverHeadCost DECIMAL(18, 2),
				OverHeadCostRevenuePercentage DECIMAL(18, 2),
				FreightRevenue DECIMAL(18, 2),
				OtherCost DECIMAL(18, 2),
				DirectCost DECIMAL(18, 2),
				Margin DECIMAL(18, 2),
				MarginPercentage DECIMAL(18, 2),
				Scope NVARCHAR(255),
				StockLineNumber NVARCHAR(255),
				SerialNumber NVARCHAR(255),
				MaterialRevenue DECIMAL(18, 2),
				LaborRevenue DECIMAL(18, 2),
				ChargesRevenue DECIMAL(18, 2),
				MaterialFlatBillingAmount DECIMAL(18, 2),
				LaborFlatBillingAmount DECIMAL(18, 2),
				ChargesFlatBillingAmount DECIMAL(18, 2),
				FreightFlatBillingAmount DECIMAL(18, 2),
				LaborFinalAmount DECIMAL(18, 2),
				ChargesFinalAmount DECIMAL(18, 2),
				FreightFinalAmount DECIMAL(18, 2),
				Quantity INT,
				QuoteMethod INT,
				CommonFlatRate DECIMAL(18, 2),
				TATDaysStandard INT,
				EvalFees DECIMAL(18, 2),
				SubtotalForTax DECIMAL(18, 2),
				TAXRates DECIMAL(18, 2),
				OtherTax DECIMAL(18, 2),
				SalesTaxAmount DECIMAL(18, 2),
				OtherTaxAmount DECIMAL(18, 2),
				FinalTotal DECIMAL(18, 2),
				FinalLaborTotal DECIMAL(18, 2),
				RowNumber INT,
				Memo VARCHAR(MAX)
			);


		IF(@isByPartIds = 1)
		BEGIN
				;WITH WOQPartCte AS (
				SELECT DISTINCT
				wop.ID,
				im.ItemMasterId,
				 im.PartNumber,  
				 im.PartDescription,  
				 RevisedPartNo = CASE WHEN im1.ItemMasterId IS null THEN  '' ELSE im1.PartNumber END,  
				 Revenue = SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)),  
				 SUM(wqd.MaterialCost) AS 'MaterialCost',  
				 SUM(wqd.MaterialRevenuePercentage) AS 'MaterialRevenuePercentage',  
				 SUM(wqd.LaborCost) AS 'LaborCost',  
				 SUM(wqd.LaborRevenuePercentage) AS 'LaborRevenuePercentage',  
				 SUM(wqd.OverHeadCost) AS 'OverHeadCost',  
				 SUM(wqd.OverHeadCostRevenuePercentage) AS 'OverHeadCostRevenuePercentage',  
				 SUM(wqd.FreightRevenue) AS 'FreightRevenue',  
				 OtherCost = SUM(wqd.ChargesCost),  
				 DirectCost = SUM(wqd.MaterialCost + wqd.LaborCost + wqd.ChargesCost),  
				 Margin = SUM(wqd.MaterialMargin + wqd.LaborMargin + wqd.ChargesMargin),  
				 MarginPercentage = SUM(wqd.MaterialMarginPer + wqd.LaborMarginPer + wqd.ChargesMarginPer),  
				 Scope = UPPER(MAX(s.WorkScopeCode)),
				 UPPER(sl.StockLineNumber) AS StockLineNumber,
				 UPPER(sl.SerialNumber) AS SerialNumber,
				 SUM(wqd.MaterialRevenue) AS 'MaterialRevenue',  
				 SUM(wqd.LaborRevenue) AS 'LaborRevenue',  
				 SUM(wqd.ChargesRevenue) AS 'ChargesRevenue',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate ELSE SUM(wqd.MaterialFlatBillingAmount) END AS 'MaterialFlatBillingAmount' ,  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFinalAmount',
				 wop.Quantity,  
				 ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
				 wqd.CommonFlatRate,  
				 wop.TATDaysStandard ,
				 ISNULL(wqd.EvalFees,0) AS EvalFees,
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate 
				 ELSE SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0) + ISNULL(wqd.FreightFlatBillingAmount,0))
				 END AS subtotalfortax,
				 TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId  and t.Code !='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				Memo =
				(SELECT CAST('<x>' + REPLACE(REPLACE(ctd.Memo, '</p><p>',' '),'<br>','') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)') 
					FROM
						dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK)
						LEFT JOIN dbo.CommonTeardownType ctt WITH(NOLOCK) ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
					WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId AND UPPER(ctt.name) = UPPER(@corrective))
			FROM dbo.WorkOrder wo WITH(NOLOCK)
				 INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
				 INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
				 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID  
				 INNER JOIN dbo.WorkOrderWorkFlow wf WITH(NOLOCK) ON  wop.ID = wf.WorkOrderPartNoId
				 INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
				 LEFT JOIN dbo.ItemMaster im1 WITH(NOLOCK) ON im.RevisedPartId = im1.ItemMasterId  
				 INNER JOIN dbo.WorkScope s WITH(NOLOCK) ON wop.WorkOrderScopeId = s.WorkScopeId  
				 INNER JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId  
				 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
			WHERE woq.WorkOrderQuoteId = @WorkOrderQuoteId AND wop.ID IN (SELECT value FROM STRING_SPLIT(@workOrderPartNoIds, ','))
				 AND woq.IsActive = 1 AND woq.IsDeleted = 0  
			GROUP BY im.PartNumber, wop.ID, 
				 im.PartDescription, im1.ItemMasterId, im1.PartNumber,im.ItemMasterId,  
				 sl.StockLineNumber, sl.SerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees, cust.CustomerId,wf.WorkFlowWorkOrderId),
			AfterTax AS (SELECT *, CAST(((Ct.subtotalfortax * Ct.TAXRates) / 100) AS DECIMAL(18, 2)) AS SalesTaxAmount, CAST(((Ct.subtotalfortax * Ct.Othertax) / 100) AS DECIMAL(18, 2)) AS OtherTaxAmount FROM WOQPartCte Ct)
	
			SELECT *, (ISNULL(FinalQuote.SalesTaxAmount, 0) + ISNULL(FinalQuote.OtherTaxAmount, 0) + ISNULL(FinalQuote.subtotalfortax, 0)) FinalTotal, 
			CASE WHEN ISNULL(QuoteMethod,0) > 0  THEN ISNULL(MaterialFlatBillingAmount,0) ELSE ISNULL(MaterialFlatBillingAmount,0) + ISNULL(LaborFlatBillingAmount,0)END as FinalLaborTotal,ROW_NUMBER() OVER (ORDER BY ItemMasterId) AS RowNumber INTO #tmpQuoteIds FROM AfterTax FinalQuote;
			
			INSERT INTO #tblTempQuoteMain(ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
						MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
						OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
						MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
						LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
						ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
						ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
						TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
						OtherTaxAmount, FinalTotal, FinalLaborTotal, RowNumber, Memo)
			SELECT 
					ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
					MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
					OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
					MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
					LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
					ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
					ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
					TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
					OtherTaxAmount, 
					FinalTotal,
					FinalLaborTotal,
					RowNumber,
					Memo
				FROM #tmpQuoteIds; 

		END
		ELSE
		BEGIN
			
				;WITH WOQPartCte AS (
				SELECT DISTINCT  
				wop.ID,
				im.ItemMasterId,
				 im.PartNumber,  
				 im.PartDescription,  
				 RevisedPartNo = CASE WHEN im1.ItemMasterId IS null THEN  '' ELSE im1.PartNumber END,  
				 Revenue = SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)),  
				 SUM(wqd.MaterialCost) AS 'MaterialCost',  
				 SUM(wqd.MaterialRevenuePercentage) AS 'MaterialRevenuePercentage',  
				 SUM(wqd.LaborCost) AS 'LaborCost',  
				 SUM(wqd.LaborRevenuePercentage) AS 'LaborRevenuePercentage',  
				 SUM(wqd.OverHeadCost) AS 'OverHeadCost',  
				 SUM(wqd.OverHeadCostRevenuePercentage) AS 'OverHeadCostRevenuePercentage',  
				 SUM(wqd.FreightRevenue) AS 'FreightRevenue',  
				 OtherCost = SUM(wqd.ChargesCost),  
				 DirectCost = SUM(wqd.MaterialCost + wqd.LaborCost + wqd.ChargesCost),  
				 Margin = SUM(wqd.MaterialMargin + wqd.LaborMargin + wqd.ChargesMargin),  
				 MarginPercentage = SUM(wqd.MaterialMarginPer + wqd.LaborMarginPer + wqd.ChargesMarginPer),  
				 Scope = UPPER(MAX(s.WorkScopeCode)),
				 UPPER(sl.StockLineNumber) AS StockLineNumber,
				 UPPER(sl.SerialNumber) AS SerialNumber,
				 SUM(wqd.MaterialRevenue) AS 'MaterialRevenue',  
				 SUM(wqd.LaborRevenue) AS 'LaborRevenue',  
				 SUM(wqd.ChargesRevenue) AS 'ChargesRevenue',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate ELSE SUM(wqd.MaterialFlatBillingAmount) END AS 'MaterialFlatBillingAmount' ,  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFlatBillingAmount',  
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN 0.00 ELSE SUM(wqd.LaborFlatBillingAmount) END AS 'LaborFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.ChargesFlatBillingAmount) END AS 'ChargesFinalAmount',
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN  0.00 ELSE SUM(wqd.FreightFlatBillingAmount) END AS 'FreightFinalAmount',
				 wop.Quantity,  
				 ISNULL(wqd.QuoteMethod,0) AS QuoteMethod,  
				 wqd.CommonFlatRate,  
				 wop.TATDaysStandard ,
				 ISNULL(wqd.EvalFees,0) AS EvalFees,
				 CASE WHEN ISNULL(wqd.QuoteMethod,0) > 0 THEN wqd.CommonFlatRate 
				 ELSE SUM(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0) + ISNULL(wqd.FreightFlatBillingAmount,0))
				 END AS subtotalfortax,
				 TAXRates = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId and t.Code ='SALES TAX'
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				Othertax = (SELECT SUM(ISNULL(tr.TaxRate,0)) FROM dbo.CustomerTaxTypeRateMapping custtax WITH(NOLOCK)
							LEFT JOIN dbo.TaxType t WITH(NOLOCK) ON custtax.TaxTypeId = t.TaxTypeId
							LEFT JOIN dbo.TaxRate tr WITH(NOLOCK) ON custtax.TaxRateId = tr.TaxRateId 
						WHERE custtax.CustomerId = cust.[CustomerId] and custtax.IsActive = 1 and custtax.IsDeleted = 0 ),
				Memo =
				(SELECT CAST('<x>' + REPLACE(REPLACE(ctd.Memo, '</p><p>',' '),'<br>','') + '</x>' AS XML).value('.', 'NVARCHAR(MAX)') 
					FROM
						dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK)
						LEFT JOIN dbo.CommonTeardownType ctt WITH(NOLOCK) ON ctd.CommonTeardownTypeId = ctt.CommonTeardownTypeId 
						WHERE ctd.WorkFlowWorkOrderId = wf.WorkFlowWorkOrderId AND UPPER(ctt.name) = UPPER(@corrective))
			FROM dbo.WorkOrder wo WITH(NOLOCK)
				 INNER JOIN dbo.WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
				 INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
				 INNER JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID 
				 INNER JOIN dbo.WorkOrderWorkFlow wf WITH(NOLOCK) ON  wop.ID = wf.WorkOrderPartNoId
				 --LEFT JOIN dbo.CommonWorkOrderTearDown ctd WITH(NOLOCK) ON wf.WorkFlowWorkOrderId = ctd.WorkFlowWorkOrderId
				 INNER JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
				 LEFT JOIN dbo.ItemMaster im1 WITH(NOLOCK) ON im.RevisedPartId = im1.ItemMasterId  
				 INNER JOIN dbo.WorkScope s WITH(NOLOCK) ON wop.WorkOrderScopeId = s.WorkScopeId  
				 INNER JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId  
				 INNER JOIN dbo.Customer cust WITH(NOLOCK)  ON woq.CustomerId = cust.CustomerId
			WHERE woq.WorkOrderQuoteId = @WorkOrderQuoteId 
				 AND woq.IsActive = 1 AND woq.IsDeleted = 0  
			GROUP BY im.PartNumber,  wop.ID, 
				 im.PartDescription, im1.ItemMasterId, im1.PartNumber, im.ItemMasterId, 
				 sl.StockLineNumber, sl.SerialNumber, wop.Quantity, wqd.QuoteMethod, wqd.CommonFlatRate, TATDaysStandard,wqd.EvalFees, cust.CustomerId,wf.WorkFlowWorkOrderId),
			AfterTax AS (SELECT *, CAST(((Ct.subtotalfortax * Ct.TAXRates) / 100) AS DECIMAL(18, 2)) AS SalesTaxAmount, CAST(((Ct.subtotalfortax * Ct.Othertax) / 100) AS DECIMAL(18, 2)) AS OtherTaxAmount FROM WOQPartCte Ct)

			SELECT *, (ISNULL(FinalQuote.SalesTaxAmount, 0) + ISNULL(FinalQuote.OtherTaxAmount, 0) + ISNULL(FinalQuote.subtotalfortax, 0)) FinalTotal, 
			CASE WHEN ISNULL(QuoteMethod,0) > 0  THEN ISNULL(MaterialFlatBillingAmount,0) ELSE ISNULL(MaterialFlatBillingAmount,0) + ISNULL(LaborFlatBillingAmount,0)END as FinalLaborTotal,ROW_NUMBER() OVER (ORDER BY ItemMasterId) AS RowNumber INTO #tmpQuotetblMulti FROM AfterTax FinalQuote;
			
			INSERT INTO #tblTempQuoteMain(ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
						MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
						OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
						MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
						LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
						ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
						ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
						TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
						OtherTaxAmount, FinalTotal, FinalLaborTotal, RowNumber, Memo)
				SELECT 
					ID, ItemMasterId, PartNumber, PartDescription, RevisedPartNo, Revenue, MaterialCost, 
					MaterialRevenuePercentage, LaborCost, LaborRevenuePercentage, OverHeadCost, 
					OverHeadCostRevenuePercentage, FreightRevenue, OtherCost, DirectCost, Margin, 
					MarginPercentage, Scope, StockLineNumber, SerialNumber, MaterialRevenue, 
					LaborRevenue, ChargesRevenue, MaterialFlatBillingAmount, LaborFlatBillingAmount, 
					ChargesFlatBillingAmount, FreightFlatBillingAmount, LaborFinalAmount, 
					ChargesFinalAmount, FreightFinalAmount, Quantity, QuoteMethod, CommonFlatRate, 
					TATDaysStandard, EvalFees, SubtotalForTax, TAXRates, OtherTax, SalesTaxAmount, 
					OtherTaxAmount, 
					FinalTotal,
					FinalLaborTotal,
					RowNumber,
					Memo
				FROM #tmpQuotetblMulti; 

		END

		SET @totalCount = (SELECT  COUNT(*) FROM #tblTempQuoteMain)

		WHILE @currentRow <= @totalCount
		BEGIN
			SET @PartId =  (SELECT  ID FROM #tblTempQuoteMain WHERE RowNumber = @currentRow) 
			print @PartId
			EXEC [dbo].[USP_GetCustomerTax_Information_Repair_WOQ_Output] 
		     @WorkOrderQuoteId,
			 @WOId,
			 @PartId,
		     @TotalFreight = @TotalFreight OUTPUT,
		     @TotalCharges = @TotalCharges OUTPUT,
			 @SubTotal = @SubTotal OUTPUT,
			 @WOQGrandTotal = @WOQGrandTotal OUTPUT,
			 @FinalSalesTaxes = @FinalSalesTaxes OUTPUT,
			 @FinalOtherTaxes = @FinalOtherTaxes OUTPUT
			UPDATE  #tblTempQuoteMain SET SalesTaxAmount = @FinalSalesTaxes,OtherTaxAmount = @FinalOtherTaxes, FinalTotal = ISNULL(@FinalSalesTaxes,0) + ISNULL(@FinalOtherTaxes,0) + ISNULL(SubtotalForTax,0)  WHERE RowNumber = @currentRow
			SET @currentRow = @currentRow + 1;
		END

	SELECT * FROM #tblTempQuoteMain
		
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderQuotePrintPdfDataMultipleMPN'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        = @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END