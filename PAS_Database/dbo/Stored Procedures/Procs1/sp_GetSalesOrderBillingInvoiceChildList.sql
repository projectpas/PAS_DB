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
	6    01/30/2024   AMIT GHEDIYA	Updated the SP to show billing data only when is Billing Invoiced
	7    02/05/2024   AMIT GHEDIYA	Updated the SP to show Proforma invoice Data.
	8    02/19/2024   AMIT GHEDIYA	Updated the SP to get Proforma DepositAmount.
     
 EXEC [dbo].[sp_GetSalesOrderBillingInvoiceChildList] 561, 41196, 7  
**************************************************************/
CREATE    PROCEDURE [dbo].[sp_GetSalesOrderBillingInvoiceChildList]
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

		--Create Temp Table 
		IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoiceChildList') IS NOT NULL
		BEGIN
			DROP TABLE #SalesOrderBillingInvoiceChildList
		END

		CREATE TABLE #SalesOrderBillingInvoiceChildList(
			SalesOrderShippingId [BIGINT] NOT NULL,
			SOBillingInvoicingId [BIGINT] NULL,
			InvoiceDate [datetime2](7) NULL, 
			InvoiceNo [VARCHAR](250)  NULL,
			SOShippingNum [VARCHAR](250)  NULL,
			QtyToBill [INT]  NULL,
			SalesOrderNumber [VARCHAR](250)  NULL,
			partnumber [VARCHAR](250) NOT NULL,
			ItemMasterId [BIGINT] NOT NULL,
			ConditionId [BIGINT] NOT NULL,
			PartDescription [VARCHAR](MAX) NULL,
			StockLineNumber  [VARCHAR](250)  NULL,
			SerialNumber  [VARCHAR](250)  NULL,
			CustomerName [VARCHAR](250)  NULL,
			StockLineId [BIGINT]  NULL,
			QtyBilled [INT]  NULL,
			ItemNo [INT]  NULL,
			SalesOrderId [BIGINT]  NULL,
			SalesOrderPartId [BIGINT]  NULL,
			Condition [VARCHAR](250)  NULL,
			CurrencyCode [VARCHAR](100)  NULL,
			TotalSales [decimal](18,2) NULL,   
			InvoiceStatus [VARCHAR](250)  NULL,
			SmentNo [VARCHAR](250)  NULL,
			VersionNo [VARCHAR](250)  NULL,
			IsVersionIncrease [INT]  NULL,
			IsNewInvoice [INT]  NULL,
			IsProforma [BIT] NULL,
			DepositAmount [DECIMAL](18,2) NULL
		);

		IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
		BEGIN 
			INSERT INTO #SalesOrderBillingInvoiceChildList(
			SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
			StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
			TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma,DepositAmount )
		(
			SELECT DISTINCT sosi.SalesOrderShippingId,   
			(SELECT TOP 1 a.SOBillingInvoicingId FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where b.SalesOrderShippingId = sosi.SalesOrderShippingId AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0
			AND b.ItemMasterId = sop.ItemMasterId AND sop.StockLineId = b.StockLineId) AS SOBillingInvoicingId,  
			(SELECT TOP 1 a.InvoiceDate FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceDate,  
			(SELECT TOP 1 a.InvoiceNo FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceNo,  
			sos.SOShippingNum, 
			sosi.QtyShipped as QtyToBill,   
			so.SalesOrderNumber, 
			imt.partnumber, 
			imt.ItemMasterId,
			sop.ConditionId,
			imt.PartDescription, 
			sl.StockLineNumber,  
			sl.SerialNumber, 
			cr.[Name] as CustomerName,   
			sop.StockLineId,  
			(SELECT TOP 1 b.NoofPieces FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				WHERE a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND b.SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS QtyBilled,  
			sop.ItemNo,  
			sop.SalesOrderId, 
			sop.SalesOrderPartId, 
			cond.Description as 'Condition',   
			curr.Code as 'CurrencyCode',  
			--((ISNULL(sop.UnitSalePrice, 0) * sosi.QtyShipped) +   
			--(((ISNULL(sop.UnitSalePrice, 0) * sosi.QtyShipped) * ISNULL(sop.TaxPercentage, 0)) / 100) + 
			((ISNULL(sop.UnitSalesPricePerUnit, 0) * sosi.QtyShipped) +   
			((((ISNULL(sop.UnitSalesPricePerUnit, 0) * sosi.QtyShipped) +
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
			) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)) 
			as 'TotalSales',  
			(SELECT TOP 1 a.InvoiceStatus FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId  AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) 
			AS InvoiceStatus, --AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId  
			sos.SmentNum AS 'SmentNo',
			sobii.VersionNo,
			(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
			CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
			0 AS IsProforma,
			0 AS DepositAmount
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
			GROUP BY sosi.SalesOrderShippingId, sos.SOShippingNum, so.SalesOrderNumber, imt.ItemMasterId, imt.partnumber,imt.ItemMasterId,sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
			sl.SerialNumber, cr.[Name], sop.ItemNo, sop.SalesOrderId, sop.SalesOrderPartId, cond.Description, curr.Code, sop.StockLineId,  
			sobi.InvoiceStatus, sosi.QtyShipped, sop.ItemMasterId, sobi.InvoiceStatus,sop.UnitSalesPricePerUnit,   
			sop.TaxAmount, sop.TaxPercentage, sos.SmentNum, sobii.VersionNo, sobii.IsVersionIncrease, sobi.SOBillingInvoicingId)
			--ORDER BY sosi.SalesOrderShippingId DESC)
			--ORDER BY sobi.SOBillingInvoicingId DESC;
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT TOP 1 * FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId)
			BEGIN  
				INSERT INTO #SalesOrderBillingInvoiceChildList(
					SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId ,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
					TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount )
				(
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
				(SELECT (CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE (SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId) end)				
				FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK) WHERE SORR.SalesOrderPartId = sop.SalesOrderPartId) as QtyToBill,   
				so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name] as CustomerName,   
				sop.StockLineId,  
				--(SELECT TOP 1 b.NoofPieces FROM SalesOrderBillingInvoicing a WITH (NOLOCK) INNER JOIN SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId WHERE a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId AND sop.StockLineId = b.StockLineId AND b.SalesOrderPartId = sop.SalesOrderPartId) AS QtyBilled,  
				(SELECT b.NoofPieces FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS QtyBilled, 
				sop.ItemNo,  
				sop.SalesOrderId, sop.SalesOrderPartId, cond.Description as 'Condition',   
				curr.Code as 'CurrencyCode',  
				CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
				((((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
				) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
				ELSE sobi.GrandTotal END as 'TotalSales',  
				(SELECT a.InvoiceStatus FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					Where a.SalesOrderId = @SalesOrderId AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceStatus,
				(CASE WHEN sobii.IsVersionIncrease = 1 then (CASE WHEN SOBII.SalesOrderShippingId > 0 THEN 1 ELSE 0 END) else 1 end) AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
				CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
				0 AS IsProforma,
				0 AS DepositAmount
				FROM DBO.SalesOrderPart sop WITH (NOLOCK)
				LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 0
				LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 0 
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId  
				INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
				WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId )
				--ORDER BY sobi.SOBillingInvoicingId DESC
			END
			ELSE
			BEGIN 
				INSERT INTO #SalesOrderBillingInvoiceChildList(
					SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
					TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount )
				(
					SELECT DISTINCT 0 AS SalesOrderShippingId,   
					sobi.SOBillingInvoicingId,
					sobi.InvoiceDate,
					sobi.InvoiceNo AS InvoiceNo,
					'' AS SOShippingNum, 
					(SELECT ISNULL(SUM(SORR.QtyToReserve), 0) FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK) WHERE SORR.SalesOrderPartId = sop.SalesOrderPartId AND SORR.StockLineId = sop.StockLineId) as QtyToBill,   
					so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId,sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
					sl.SerialNumber, cr.[Name] as CustomerName,   
					sop.StockLineId,  
					(SELECT b.NoofPieces FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
						WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId
						AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS QtyBilled,  
					sop.ItemNo,  
					sop.SalesOrderId, sop.SalesOrderPartId, cond.Description as 'Condition',   
					curr.Code as 'CurrencyCode',  
					CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
					((((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +
					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
					) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
					ELSE sobi.GrandTotal END as 'TotalSales',  
					(SELECT a.InvoiceStatus FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
						Where a.SalesOrderId = @SalesOrderId AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
						AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceStatus,
					0 AS 'SmentNo',
					sobii.VersionNo, 
					(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
					CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					0 AS IsProforma,
					0 AS DepositAmount
					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 0
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 0 
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId  
					INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
					WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId 
					--AND ((ISNULL(soapr.SalesOrderApprovalId, 0) > 0   
					AND (ISNULL(SOR.SalesOrderReservePartId, 0) > 0) AND (ISNULL(SOR.TotalReserved, 0) > 0))
				--ORDER BY sobi.SOBillingInvoicingId DESC
			END
		END
		
		--IF((SELECT COUNT(1) FROM #SalesOrderBillingInvoiceChildList WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = @SalesOrderPartId AND ConditionId = @ConditionId) <= 0 )
		--BEGIN 
			INSERT INTO #SalesOrderBillingInvoiceChildList(
				SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
				TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount )
			(
				SELECT DISTINCT 0 AS SalesOrderShippingId,   
					sobi.SOBillingInvoicingId,
					sobi.InvoiceDate,
					sobi.InvoiceNo AS InvoiceNo,
					'' AS SOShippingNum, 
					sop.Qty AS QtyToBill, 
					so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
					sl.SerialNumber, cr.[Name] AS CustomerName,   
					sop.StockLineId,  
					(SELECT b.NoofPieces FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
						WHERE b.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId AND ISNULL(b.IsProforma,0) = 1 AND ISNULL(a.IsProforma,0) = 1) AS QtyBilled,  
					sop.ItemNo,  
					sop.SalesOrderId, sop.SalesOrderPartId, cond.Description AS 'Condition',   
					curr.Code as 'CurrencyCode',  
					sobi.GrandTotal as 'TotalSales',  
					(SELECT a.InvoiceStatus FROM DBO.SalesOrderBillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
						Where a.SalesOrderId = @SalesOrderId 
						AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
						AND ISNULL(b.IsProforma,0) = 1 AND ISNULL(a.IsProforma,0) = 1) AS InvoiceStatus,
					0 AS 'SmentNo',
					sobii.VersionNo, 
					(CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
					CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					1 AS IsProforma,
					ISNULL(sobi.DepositAmount,0) AS DepositAmount
					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 1
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 1
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.CurrencyId  
					--LEFT JOIN #SalesOrderBillingInvoiceChildList tmp ON tmp.ItemMasterId != imt.ItemMasterId AND tmp.ConditionId = sop.ConditionId
					WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId
					--AND sop.ItemMasterId NOT IN()
					)
					--ORDER BY sobi.SOBillingInvoicingId DESC
		--END
		SELECT SalesOrderShippingId,
			   SOBillingInvoicingId ,
			   InvoiceDate , 
			   InvoiceNo ,
			   SOShippingNum ,	
			   QtyToBill ,
			   SalesOrderNumber ,
			   partnumber ,
			   PartDescription ,
			   StockLineNumber,
			   SerialNumber ,	
			   CustomerName ,	
			   StockLineId ,
			   QtyBilled ,
			   ItemNo,	
			   SalesOrderId ,
			   SalesOrderPartId ,
			   Condition ,	
			   CurrencyCode ,
			   TotalSales ,
			   InvoiceStatus ,	
			   SmentNo ,
			   VersionNo ,
			   IsVersionIncrease ,	
			   IsNewInvoice,
			   IsProforma,
			   DepositAmount
			  FROM #SalesOrderBillingInvoiceChildList;
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