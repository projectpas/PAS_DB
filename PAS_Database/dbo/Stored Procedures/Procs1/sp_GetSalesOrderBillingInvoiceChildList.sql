/*************************************************************           
 ** File:   [sp_GetSalesOrderBillingInvoiceChildList]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to retrieve Invoice child listing data
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    06/12/2023   Vishal Suthar Updated the SP to handle invoice before shipping and versioning
	2    06/16/2023   Vishal Suthar Fixed issue with Invoice status
	3    06/21/2023   Vishal Suthar Fixed issue with qty shipped
	4    07/19/2023	  Satish Gohil	Fixed issue with wrong showing multiple invoice record 
	5    12/29/2023	  Vishal Suthar	Fixed issue with Where condition when allow billing before shipping in not enabled
	6    01/30/2024   AMIT GHEDIYA		    Updated the SP to show billing data only when is Billing Invoiced
     
 EXEC [dbo].[sp_GetSalesOrderBillingInvoiceChildList] 561, 41196, 7  
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_GetSalesOrderBillingInvoiceChildList]
	 @SalesOrderId  bigint,  
	 @SalesOrderPartId bigint,  
	 @ConditionId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
 BEGIN TRANSACTION  
   BEGIN  
		DECLARE @AllowBillingBeforeShipping BIT;
		SELECT @AllowBillingBeforeShipping = AllowInvoiceBeforeShipping FROM DBO.SalesOrder SO (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

		IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
		BEGIN
			SELECT DISTINCT sosi.SalesOrderShippingId,   
			(SELECT TOP 1 a.SOBillingInvoicingId FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where b.SalesOrderShippingId = sosi.SalesOrderShippingId AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0
			AND b.ItemMasterId = sop.ItemMasterId AND sop.StockLineId = b.StockLineId) AS SOBillingInvoicingId,  
			(SELECT TOP 1 a.InvoiceDate FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceDate,  
			(SELECT TOP 1 a.InvoiceNo FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceNo,  
			sos.SOShippingNum, sosi.QtyShipped as QtyToBill,   
			so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
			sl.SerialNumber, cr.[Name] as CustomerName,   
			sop.StockLineId,  
			(SELECT TOP 1 b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				WHERE a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND b.SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS QtyBilled,  
			sop.ItemNo,  
			sop.SalesOrderId, sop.SalesOrderPartId, cond.Description as 'Condition',   
			curr.Code as 'CurrencyCode',  
			--((ISNULL(sop.UnitSalePrice, 0) * sosi.QtyShipped) +   
			--(((ISNULL(sop.UnitSalePrice, 0) * sosi.QtyShipped) * ISNULL(sop.TaxPercentage, 0)) / 100) + 
			((ISNULL(sop.UnitSalesPricePerUnit, 0) * sosi.QtyShipped) +   
			((((ISNULL(sop.UnitSalesPricePerUnit, 0) * sosi.QtyShipped) +
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
			) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)) as 'TotalSales',  
			(SELECT TOP 1 a.InvoiceStatus FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId  AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceStatus, --AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId  
			sos.SmentNum AS 'SmentNo',
			sobii.VersionNo,
			(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
			CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice
			FROM DBO.SalesOrderShippingItem sosi WITH (NOLOCK)  
			INNER JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sosi.SalesOrderShippingId = sos.SalesOrderShippingId  
			LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderShippingId = sos.SalesOrderShippingId AND ISNULL(sobii.IsProforma,0) = 0
			LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 0
			INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) on sop.SalesOrderId = sos.SalesOrderId AND sop.SalesOrderPartId = sosi.SalesOrderPartId  
			INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
			LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
			LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
			LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) on soc.SalesOrderShippingId = sos.SalesOrderShippingId  
			LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
			LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
			LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId  
			WHERE sos.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId  
			GROUP BY sosi.SalesOrderShippingId, sos.SOShippingNum, so.SalesOrderNumber, imt.ItemMasterId, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
			sl.SerialNumber, cr.[Name], sop.ItemNo, sop.SalesOrderId, sop.SalesOrderPartId, cond.Description, curr.Code, sop.StockLineId,  
			sobi.InvoiceStatus, sosi.QtyShipped, sop.ItemMasterId, sobi.InvoiceStatus,sop.UnitSalesPricePerUnit,   
			sop.TaxAmount, sop.TaxPercentage, sos.SmentNum, sobii.VersionNo, sobii.IsVersionIncrease, sobi.SOBillingInvoicingId
			ORDER BY sosi.SalesOrderShippingId DESC;
			--ORDER BY sobi.SOBillingInvoicingId DESC;
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT TOP 1 * FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId)
			BEGIN
				SELECT DISTINCT 
				(CASE WHEN sobii.IsVersionIncrease = 1 then sobii.SalesOrderShippingId 
				else (SELECT TOP 1 SOS.SalesOrderShippingId FROM DBO.SalesOrderShipping SOS 
				WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId) end) AS SalesOrderShippingId,   
				sobi.SOBillingInvoicingId,
				sobi.InvoiceDate,
				sobi.InvoiceNo AS InvoiceNo,
				(CASE WHEN sobii.IsVersionIncrease = 1 then (SELECT TOP 1 SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) WHERE SOS.SalesOrderShippingId = sobii.SalesOrderShippingId) else (SELECT TOP 1 SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId) end) AS SOShippingNum, 
				(SELECT ISNULL(SUM(SORR.QtyToReserve), 0) + (CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE (SELECT TOP 1 ISNULL(SOSI.QtyShipped, 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId) end)				
				FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK) WHERE SORR.SalesOrderPartId = sop.SalesOrderPartId) as QtyToBill,   
				so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name] as CustomerName,   
				sop.StockLineId,  
				--(SELECT TOP 1 b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId WHERE a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId AND sop.StockLineId = b.StockLineId AND b.SalesOrderPartId = sop.SalesOrderPartId) AS QtyBilled,  
				(SELECT b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS QtyBilled, 
				sop.ItemNo,  
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description as 'Condition',   
				curr.Code as 'CurrencyCode',  
				CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
				((((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
				) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
				ELSE sobi.GrandTotal END as 'TotalSales',  
				(SELECT a.InvoiceStatus FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					Where a.SalesOrderId = @SalesOrderId AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceStatus,
				(CASE WHEN sobii.IsVersionIncrease = 1 then (CASE WHEN SOBII.SalesOrderShippingId > 0 THEN 1 ELSE 0 END) else 1 end) AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
				CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice
				FROM DBO.SalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 0
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 0 
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId  
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
				WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId  
				ORDER BY sobi.SOBillingInvoicingId DESC;
			END
			ELSE
			BEGIN
				SELECT DISTINCT 0 AS SalesOrderShippingId,   
				sobi.SOBillingInvoicingId,
				sobi.InvoiceDate,
				sobi.InvoiceNo AS InvoiceNo,
				'' AS SOShippingNum, 
				(SELECT ISNULL(SUM(SORR.QtyToReserve), 0) FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK) WHERE SORR.SalesOrderPartId = sop.SalesOrderPartId AND SORR.StockLineId = sop.StockLineId) as QtyToBill,   
				so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name] as CustomerName,   
				sop.StockLineId,  
				(SELECT b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS QtyBilled,  
				sop.ItemNo,  
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description as 'Condition',   
				curr.Code as 'CurrencyCode',  
				CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
				((((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
				) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderFreight sof WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM SalesOrderCharges socg WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
				ELSE sobi.GrandTotal END as 'TotalSales',  
				(SELECT a.InvoiceStatus FROM SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					Where a.SalesOrderId = @SalesOrderId AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceStatus,
				0 AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
				CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice
				FROM DBO.SalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 0
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 0 
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId  
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
				WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId  
				ORDER BY sobi.SOBillingInvoicingId DESC;
			END
		END
   END  
   COMMIT  TRANSACTION  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSalesOrderBillingInvoiceChildList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END