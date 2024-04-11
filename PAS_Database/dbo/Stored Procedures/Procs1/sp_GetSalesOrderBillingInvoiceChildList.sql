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
	9    22/02/2024   AMIT GHEDIYA	Updated the SP to get Proforma IsAllowIncreaseVersionForBillItem.
	10   26/02/2024   Moin Bloch	Updated the SP to get TotalUnitCost,Freight,and Charges
	11   01/03/2024   Devendra Shekh added [IsBilling] to select
	11   20/03/2024   HEMANT SALIYA Convert to Temp Table for handle Duplicate Values

  EXEC [dbo].[sp_GetSalesOrderBillingInvoiceChildList] 657,41190,7
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
		DECLARE @FreightBilingMethodId INT = 3
		DECLARE @ChargesBilingMethodId INT = 3	
		SELECT @AllowBillingBeforeShipping = AllowInvoiceBeforeShipping FROM DBO.SalesOrder SO (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

		--Create Temp Table 
		IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoiceChildList') IS NOT NULL
		BEGIN
			DROP TABLE #SalesOrderBillingInvoiceChildList
		END

		CREATE TABLE #SalesOrderBillingInvoiceChildList(
			SalesOrderShippingId [BIGINT] NOT NULL,
			SOBillingInvoicingId [BIGINT] NULL,
			SOBillingInvoicingItemId [BIGINT] NULL,
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
			TotalUnitCost [decimal](18,2) NULL,  
			TotalFreight [decimal](18,2) NULL,  
			TotalFlatFreight [decimal](18,2) NULL,   
			TotalCharges [decimal](18,2) NULL,  
			TotalFlatCharges [decimal](18,2) NULL, 
			InvoiceStatus [VARCHAR](250)  NULL,
			SmentNo [VARCHAR](250)  NULL,
			VersionNo [VARCHAR](250)  NULL,
			IsVersionIncrease [INT]  NULL,
			IsNewInvoice [INT]  NULL,
			IsProforma [BIT] NULL,
			DepositAmount [DECIMAL](18,2) NULL,
			IsAllowIncreaseVersionForBillItem [BIT] NULL,
			[IsBilling] [bit] NULL,
		);

		IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
		BEGIN 
			PRINT '1.0'
			INSERT INTO #SalesOrderBillingInvoiceChildList(
			SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
			StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
			TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling )
		(
			SELECT DISTINCT sosi.SalesOrderShippingId,   
			CASE WHEN sop.SalesOrderPartId IS NOT NULL and  (SELECT COUNT(1) FROM DBO.SalesOrderBillingInvoicingItem sobii_1 WITH(NOLOCK) 
			WHERE sobii_1.SOBillingInvoicingId = sobi.SOBillingInvoicingId and sobii_1.ItemMasterId = sop.ItemMasterId
			AND ISNULL(sobii_1.IsProforma, 0) = 0) > 0 THEN sobii.SOBillingInvoicingId  
			ELSE NULL END AS SOBillingInvoicingId,

			(SELECT TOP 1 a.InvoiceDate FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceDate,

			CASE WHEN sop.SalesOrderPartId IS NOT NULL and  (SELECT COUNT(1) FROM DBO.SalesOrderBillingInvoicingItem sobii_1 WITH(NOLOCK) 
			WHERE sobii_1.SOBillingInvoicingId = sobi.SOBillingInvoicingId and sobii_1.ItemMasterId = sop.ItemMasterId 
			AND ISNULL(sobii_1.IsProforma, 0) = 0) >0  THEN sobi.InvoiceNo ELSE NULL END AS InvoiceNo,
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
			CASE WHEN ISNULL(sobii.SOBillingInvoicingId, 0) > 0 THEN ISNULL(sobi.GrandTotal, 0) ELSE 
			((ISNULL(sop.UnitSalesPricePerUnit, 0) * sosi.QtyShipped) +   
			((((ISNULL(sop.UnitSalesPricePerUnit, 0) * sosi.QtyShipped) +
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
			) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = @SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = @ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = @SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = @ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
			END 
			as 'TotalSales',  
			(ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(sosi.QtyShipped, 0)) AS TotalUnitCost,
			(SELECT ISNULL(SUM(BillingAmount), 0) 
				FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
					JOIN dbo.SalesOrderPart SOPI WITH (NOLOCK) ON sof.SalesOrderPartId = SOPI.SalesOrderPartId AND SOPI.SalesOrderPartId = SOP.SalesOrderPartId
			 WHERE sof.SalesOrderId = @SalesOrderId 			  
				AND sof.ItemMasterId = sop.ItemMasterId 
				AND sof.ConditionId = @ConditionId 
				AND sof.IsActive = 1 
				AND sof.IsDeleted = 0)  AS TotalFreight,

			(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
				WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.FreightBilingMethodId = @FreightBilingMethodId)
			 AS  TotalFlatFreight,
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
				JOIN dbo.SalesOrderPart SOPI WITH (NOLOCK) ON socg.SalesOrderPartId = SOPI.SalesOrderPartId AND SOPI.SalesOrderPartId = SOP.SalesOrderPartId
			WHERE socg.SalesOrderId = @SalesOrderId 				
				AND socg.ItemMasterId = sop.ItemMasterId 
				AND socg.ConditionId = @ConditionId 
				AND socg.IsActive = 1 
				AND socg.IsDeleted = 0) 
			AS TotalCharges,
			(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
			WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.ChargesBilingMethodId = @ChargesBilingMethodId)
			AS TotalFlatCharges,
			(SELECT a.InvoiceStatus FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
				Where a.SalesOrderId = @SalesOrderId  AND b.ItemMasterId = sop.ItemMasterId 
				AND sop.StockLineId = b.StockLineId AND SalesOrderShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0 ) 
			AS InvoiceStatus,
			sos.SmentNum AS 'SmentNo',
			sobii.VersionNo,
			(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
			CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
			0 AS IsProforma,
			0 AS DepositAmount,
			(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
			ISNULL(sobi.[IsBilling], 0) as [IsBilling]
			FROM DBO.SalesOrderShippingItem sosi WITH (NOLOCK)  
			INNER JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sosi.SalesOrderShippingId = sos.SalesOrderShippingId  
			INNER JOIN DBO.SalesOrderPart sop WITH (NOLOCK) on sop.SalesOrderId = sos.SalesOrderId AND sop.SalesOrderPartId = sosi.SalesOrderPartId  
			LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.ItemMasterId = sop.ItemMasterId AND ISNULL(sobii.IsProforma,0) = 0
			LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 0
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
			sobi.InvoiceStatus, sosi.QtyShipped, sop.ItemMasterId, sobi.InvoiceStatus,sop.UnitSalesPricePerUnit, sobi.InvoiceNo,
			sop.TaxAmount, sop.TaxPercentage, sos.SmentNum, sobii.VersionNo,sobi.IsVersionIncrease,sobii.IsVersionIncrease, sobi.SOBillingInvoicingId, sobii.SOBillingInvoicingId,sobi.GrandTotal,sobi.[IsBilling])
		END
		ELSE
		BEGIN
			PRINT '2.0'
			IF EXISTS (SELECT TOP 1 * FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId)
			BEGIN  
				PRINT '2.1'
				INSERT INTO #SalesOrderBillingInvoiceChildList(
					SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId ,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
					TotalSales, TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling] )
				(
				SELECT DISTINCT 
				(CASE WHEN sobii.IsVersionIncrease = 1 then sobii.SalesOrderShippingId 
				else (SELECT TOP 1 SOS.SalesOrderShippingId FROM DBO.SalesOrderShipping SOS 
				WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOPA WITH (NOLOCK) on SOPA.SalesOrderId = SOS.SalesOrderId AND SOPA.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOPA.ItemMasterId = @SalesOrderPartId AND SOPA.ConditionId = @ConditionId) end) AS SalesOrderShippingId,   
				sobi.SOBillingInvoicingId,
				sobi.InvoiceDate,
				sobi.InvoiceNo AS InvoiceNo,
				(CASE WHEN sobii.IsVersionIncrease = 1 then (SELECT TOP 1 SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) WHERE SOS.SalesOrderShippingId = sobii.SalesOrderShippingId) else (SELECT TOP 1 SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOPB WITH (NOLOCK) on SOPB.SalesOrderId = SOS.SalesOrderId AND SOPB.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOPB.ItemMasterId = @SalesOrderPartId AND SOPB.ConditionId = @ConditionId) end) AS SOShippingNum, 
				
				CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE (SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOPI WITH (NOLOCK) on SOPI.SalesOrderId = SOS.SalesOrderId AND SOPI.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOPI.ItemMasterId = @SalesOrderPartId AND SOPI.ConditionId = @ConditionId AND SOPI.SalesOrderPartId = sop.SalesOrderPartId) end  as QtyToBill, 				
				
				so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
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

				(ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
				FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
				INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPart SOPI WITH (NOLOCK) on SOPI.SalesOrderId = SOS.SalesOrderId AND SOPI.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId 
				AND SOPI.ItemMasterId = @SalesOrderPartId 
				AND SOPI.ConditionId = @ConditionId 
				AND SOPI.SalesOrderPartId = sop.SalesOrderPartId), 0)) AS TotalUnitCost,
			
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
					JOIN dbo.SalesOrderPart SOPI WITH (NOLOCK) ON sof.SalesOrderPartId = SOPI.SalesOrderPartId AND SOPI.SalesOrderPartId = SOP.SalesOrderPartId
				 WHERE sof.SalesOrderId = @SalesOrderId 					
					AND sof.ItemMasterId = sop.ItemMasterId 
					AND sof.ConditionId = @ConditionId 
					AND sof.IsActive = 1 
					AND sof.IsDeleted = 0)  AS TotalFreight,

				(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
					WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.FreightBilingMethodId = @FreightBilingMethodId)
				 AS  TotalFlatFreight,

				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
					JOIN dbo.SalesOrderPart SOPI WITH (NOLOCK) ON socg.SalesOrderPartId = SOPI.SalesOrderPartId AND SOPI.SalesOrderPartId = SOP.SalesOrderPartId
				WHERE socg.SalesOrderId = @SalesOrderId 					
					AND socg.ItemMasterId = sop.ItemMasterId 
					AND socg.ConditionId = @ConditionId 
					AND socg.IsActive = 1 
					AND socg.IsDeleted = 0) 
				AS TotalCharges,
			
				(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
				WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.ChargesBilingMethodId = @ChargesBilingMethodId)
				AS TotalFlatCharges,

				(SELECT a.InvoiceStatus FROM dbo.SalesOrderBillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) ON a.SOBillingInvoicingId = b.SOBillingInvoicingId 
					Where a.SalesOrderId = @SalesOrderId AND b.SOBillingInvoicingItemId = sobii.SOBillingInvoicingItemId
					AND ISNULL(a.IsProforma,0) = 0 AND ISNULL(b.IsProforma,0) = 0) AS InvoiceStatus,
				(CASE WHEN sobii.IsVersionIncrease = 1 then (CASE WHEN SOBII.SalesOrderShippingId > 0 THEN 1 ELSE 0 END) else 1 end) AS 'SmentNo',
				sobii.VersionNo, 
				(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
				CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
				0 AS IsProforma,
				0 AS DepositAmount,
				(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
				ISNULL(sobi.[IsBilling], 0) as [IsBilling]
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
			END
			ELSE
			BEGIN 
				PRINT '2.2'
				INSERT INTO #SalesOrderBillingInvoiceChildList(
				SalesOrderShippingId,SOBillingInvoicingId , SOBillingInvoicingItemId, InvoiceDate , InvoiceNo ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
				SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling] )
				SELECT DISTINCT 0 AS SalesOrderShippingId,   
					sobi.SOBillingInvoicingId,
					sobii.SOBillingInvoicingItemId,
					sobi.InvoiceDate,
					sobi.InvoiceNo AS InvoiceNo,
					'' AS SOShippingNum,
					so.SalesOrderNumber, 
					imt.partnumber, 
					imt.ItemMasterId,
					sop.ConditionId, 
					imt.PartDescription, 
					sl.StockLineNumber,  
					sl.SerialNumber, 
					cr.[Name] as CustomerName,   
					sop.StockLineId,
					sop.ItemNo,  
					sop.SalesOrderId, 
					sop.SalesOrderPartId, 
					cond.Description as 'Condition',   
					curr.Code as 'CurrencyCode',
					0 AS 'SmentNo',
					(ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) AS TotalUnitCost,
					sobii.VersionNo,
					(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
					CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					0 AS IsProforma,
					0 AS DepositAmount,
					(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
					ISNULL(sobi.[IsBilling], 0) as [IsBilling]
				FROM DBO.SalesOrderPart SOP WITH (NOLOCK)
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId 
					INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.StockLineId = sop.StockLineId AND ISNULL(sobii.IsProforma,0) = 0
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId AND ISNULL(sobi.IsProforma,0) = 0 
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.CurrencyId  
					LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
				WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId and SOP.ConditionId = @ConditionId

				UPDATE  #SalesOrderBillingInvoiceChildList SET QtyToBill = tmpcash.QtyToBill
							FROM( SELECT ISNULL(SUM(SORR.QtyToReserve), 0)  QtyToBill, tmpSOBI.SalesOrderPartId 
									FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK)
									JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON SORR.SalesOrderPartId = tmpSOBI.SalesOrderPartId AND SORR.StockLineId = tmpSOBI.StockLineId
									GROUP BY tmpSOBI.SalesOrderPartId
							) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId

				UPDATE  #SalesOrderBillingInvoiceChildList SET QtyBilled = tmpcash.NoofPieces
							FROM( SELECT b.NoofPieces, b.SalesOrderPartId FROM dbo.SalesOrderBillingInvoicingItem b WITH (NOLOCK) 
										JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = b.SOBillingInvoicingItemId
										WHERE b.SOBillingInvoicingItemId = tmpSOBI.SOBillingInvoicingItemId
										AND ISNULL(b.IsProforma,0) = 0 
							) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalSales = tmpcash.TotalSales
				FROM( SELECT 
						CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
							((((ISNULL(sop.UnitSalesPricePerUnit, 0) * ISNULL(SOR.QtyToReserve, 0)) +
							(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = tmpSOBI.SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = tmpSOBI.ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
							(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = tmpSOBI.SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = tmpSOBI.ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0)
							) * ISNULL(sop.TaxPercentage, 0)) / 100) +   
							(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) WHERE sof.SalesOrderId = tmpSOBI.SalesOrderId AND sof.ItemMasterId = sop.ItemMasterId AND sof.ConditionId = tmpSOBI.ConditionId AND sof.IsActive = 1 AND sof.IsDeleted = 0) +   
							(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) WHERE socg.SalesOrderId = tmpSOBI.SalesOrderId AND socg.ItemMasterId = sop.ItemMasterId AND socg.ConditionId = tmpSOBI.ConditionId AND socg.IsActive = 1 AND socg.IsDeleted = 0))
						ELSE sobi.GrandTotal END as 'TotalSales',
						sop.SalesOrderPartId 
					FROM dbo.SalesOrderPart SOP WITH (NOLOCK) 
						JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SalesOrderPartId
						JOIN dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId =  SOBII.SOBillingInvoicingId
						INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = SOP.SalesOrderPartId
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId
				) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFreight = tmpcash.TotalFreight
				FROM( SELECT ISNULL(SUM(BillingAmount), 0) AS TotalFreight , tmpSOBI.SalesOrderPartId
					FROM dbo.SalesOrderFreight SOF WITH (NOLOCK) 
					JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderPartId = SOF.SalesOrderPartId
					WHERE sof.SalesOrderId = tmpSOBI.SalesOrderId 						
						AND sof.ItemMasterId = tmpSOBI.ItemMasterId 
						AND sof.ConditionId = tmpSOBI.ConditionId 
						AND sof.IsActive = 1 
						AND sof.IsDeleted = 0
					GROUP BY tmpSOBI.SalesOrderPartId
				) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFlatFreight = tmpcash.TotalFreight
				FROM( SELECT ISNULL(SO.TotalFreight,0) As TotalFreight, SO.SalesOrderId
						FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
						WHERE so.FreightBilingMethodId = @FreightBilingMethodId
				) tmpcash WHERE tmpcash.SalesOrderId = #SalesOrderBillingInvoiceChildList.SalesOrderId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalCharges = tmpcash.TotalCharges
				FROM( SELECT ISNULL(SUM(BillingAmount), 0) AS TotalCharges , tmpSOBI.SalesOrderPartId
						FROM dbo.SalesOrderCharges SOC WITH (NOLOCK) 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderPartId = SOC.SalesOrderPartId
						WHERE SOC.SalesOrderId = tmpSOBI.SalesOrderId 						
							AND SOC.ItemMasterId = tmpSOBI.ItemMasterId 
							AND SOC.ConditionId = tmpSOBI.ConditionId 
							AND SOC.IsActive = 1 
							AND SOC.IsDeleted = 0
						GROUP BY tmpSOBI.SalesOrderPartId
				) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFlatCharges = tmpcash.TotalFlatCharges
				FROM( SELECT ISNULL(SO.TotalCharges,0) As TotalFlatCharges, SO.SalesOrderId
						FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
						WHERE so.FreightBilingMethodId = @ChargesBilingMethodId
				) tmpcash WHERE tmpcash.SalesOrderId = #SalesOrderBillingInvoiceChildList.SalesOrderId

				UPDATE  #SalesOrderBillingInvoiceChildList SET InvoiceStatus = tmpcash.InvoiceStatus
				FROM( SELECT SOBI.InvoiceStatus, tmpSOBI.SOBillingInvoicingId 
						FROM dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = SOBII.SOBillingInvoicingItemId
						Where SOBI.SalesOrderId = @SalesOrderId AND ISNULL(SOBI.IsProforma,0) = 0 AND ISNULL(SOBII.IsProforma,0) = 0
					
				) tmpcash WHERE tmpcash.SOBillingInvoicingId = #SalesOrderBillingInvoiceChildList.SOBillingInvoicingId
				
			END
		END
		
			PRINT '3.0'
			INSERT INTO #SalesOrderBillingInvoiceChildList(
				SalesOrderShippingId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId ,Condition ,	CurrencyCode ,
				TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling] )
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
					(CASE WHEN sobi.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
					CASE WHEN sobi.SOBillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					1 AS IsProforma,
					ISNULL(sobi.DepositAmount,0) AS DepositAmount,
					(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
					ISNULL(sobi.[IsBilling], 0) as [IsBilling]
					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SalesOrderPartId = sop.SalesOrderPartId AND ISNULL(sobii.IsProforma,0) = 1
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SOBillingInvoicingId = sobii.SOBillingInvoicingId  AND ISNULL(sobi.IsProforma,0) = 1
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.CurrencyId  
					WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId
					)

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
					   ISNULL(TotalUnitCost,0) TotalUnitCost,
					   ISNULL(TotalFreight,0) TotalFreight,
					   ISNULL(TotalFlatFreight,0) TotalFlatFreight,
					   ISNULL(TotalCharges,0) TotalCharges,
					   ISNULL(TotalFlatCharges,0) TotalFlatCharges,
					   InvoiceStatus ,	
					   SmentNo ,
					   VersionNo ,
					   IsVersionIncrease ,	
					   IsNewInvoice,
					   IsProforma,
					   DepositAmount,
					   IsAllowIncreaseVersionForBillItem,
					   [IsBilling]
				FROM #SalesOrderBillingInvoiceChildList
				ORDER BY partnumber, IsProforma DESC,InvoiceNo DESC, VersionNo DESC ;
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