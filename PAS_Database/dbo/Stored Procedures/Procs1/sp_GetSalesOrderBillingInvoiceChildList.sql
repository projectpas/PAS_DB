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
	1    06/12/2023   Vishal Suthar		Updated the SP to handle invoice before shipping and versioning
	2    06/16/2023   Vishal Suthar		Fixed issue with Invoice status
	3    06/21/2023   Vishal Suthar		Fixed issue with qty shipped
	4    07/19/2023	  Satish Gohil		Fixed issue with wrong showing multiple invoice record 
	5    12/29/2023	  Vishal Suthar		Fixed issue with Where condition when allow billing before shipping in not enabled
	6    01/30/2024   AMIT GHEDIYA		Updated the SP to show billing data only when is Billing Invoiced
	7    02/05/2024   AMIT GHEDIYA		Updated the SP to show Proforma invoice Data.
	8    02/19/2024   AMIT GHEDIYA		Updated the SP to get Proforma DepositAmount.
	9    22/02/2024   AMIT GHEDIYA		Updated the SP to get Proforma IsAllowIncreaseVersionForBillItem.
	10   26/02/2024   Moin Bloch		Updated the SP to get TotalUnitCost,Freight,and Charges
	11   01/03/2024   Devendra Shekh	added [IsBilling] to select
	12   20/03/2024   HEMANT SALIYA		Convert to Temp Table for handle Duplicate Values
	13   23/04/2024   Moin Bloch		Updated Invoice Status is not changed Issue PN-7651
	14   23/04/2024   Vishal Suthar		Modified to make use of new SO part table
	15   07/11/2024   AMIT GHEDIYA		Modified for get InvoiceTypeId.
	16   12/11/2024   AMIT GHEDIYA		Modified for get qtybilled.
	17   15/11/2024   AMIT GHEDIYA		Modified for get standard bill amount without performa.
	18	 20/11/2024	  AMIT GHEDIYA		Modified for get Curr for billng data.
	19	 20/11/2024	  Vishal Suthar		Modified for fixing amount and qty related issues
	20	 21/11/2024	  AMIT GHEDIYA		Modified for get WHL & Weight data for billing update.
	21	 28/11/2024	  Vishal Suthar		Fixed the issue with duplicate entries when billing is after shipping
	22	 03/12/2024	  Vishal Suthar		Fixed the issue with flat charges calculation
    23   04/12/2024   Moin Bloch		Updated the SP to get Proforma TotalUnitCost.
    24   04/12/2024   Vishal Suthar		Fixed the issue with total sales amount calculation
	25	 05/12/2024	  Abhishek Jirawla	Fixed the issue with flat charges calculation
	26   05/12/2024   Vishal Suthar		Fixed the issue with versioning and revised invoice
	27   10/12/2024   RAJESH GAMI		Fixed the issue with TotalUnitCost : Commented -- + ISNULL(SOR.QtyToReserve, 0) as discussed with Vishal due to multyply the amount
	28	 25/12/2024	  AMIT GHEDIYA		Modified for get TotalSales calculated with Sales tax & Other Tax.
	29	 26/12/2024	  AMIT GHEDIYA		Fixed the billing amount when partial qty is rerserved
	30	 26/12/2024	  Vishal Suthar		Fixed the issue with tax calculation when part has multiple stockline and freight and charges are also applied
	31   08-01-2025   Shrey Chandegara  Fixed Issue of costplus amount in salesorder billing.
	32	 21/01/2025	  AMIT GHEDIYA		Fixed the billing data issue after shipping.
	33	 30/01/2025	  Vishal Suthar		Fixed issue with the qty shipped after billing is completed
	34	 03/02/2025	  Vishal Suthar		Fixed issue with the qty shipped after billing and shipping is completed
	35	 27/02/2025	  Vishal Suthar		Fixed issue with billing when multiple pick ticket created for same stockline AND one when Proforma is created and standard invoice is pending
	36	 13/03/2025	  Vishal Suthar		Fixed issue with duplicate records when no invoice is created and only proforma was created
	37	 03/04/2025	  Vishal Suthar		Fixed issue with Freight and Charges not populating on revised billing
	38   07-07-2025   Moin Bloch        Changed Old To New Billing Table
	39   21-07-2025   Ayushi Patel      [PN-17375]UOM changes
	40    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	41    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	42    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filter(s) so Non-Stock parts appear/populate correctly on SO billing invoice child list.
  EXEC [dbo].[sp_GetSalesOrderBillingInvoiceChildList] 1584,20745,1
**************************************************************/
CREATE     PROCEDURE [dbo].[sp_GetSalesOrderBillingInvoiceChildList]
@SalesOrderId  bigint,  
@SalesOrderPartId bigint,  
@ConditionId bigint,
@EmployeeId bigint
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
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

		DECLARE @WOModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';


			SELECT
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM
					dbo.Employee E WITH (NOLOCK)
				LEFT JOIN
					dbo.TimeZone ETZ WITH (NOLOCK)
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN
					dbo.LegalEntity LE WITH (NOLOCK)
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN
					dbo.TimeZone LTZ WITH (NOLOCK)
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
		--Create Temp Table 
		IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoiceChildList') IS NOT NULL
		BEGIN
			DROP TABLE #SalesOrderBillingInvoiceChildList
		END

		CREATE TABLE #SalesOrderBillingInvoiceChildList(
			IndexColumn BIGINT NULL,
			SalesOrderShippingId [BIGINT] NOT NULL,
			SalesOrderShippingItemId [BIGINT] NOT NULL,
			SOBillingInvoicingId [BIGINT] NULL,
			SOBillingInvoicingItemId [BIGINT] NULL,
			InvoiceDate [datetime2](7) NULL, 
			InvoiceNo [VARCHAR](250)  NULL,
			InvoiceTypeId [BIGINT] NULL,
			SOShippingNum [VARCHAR](250)  NULL,
			QtyToBill [decimal](18,6)  NULL,
			SalesOrderNumber [VARCHAR](250)  NULL,
			partnumber [VARCHAR](250) NOT NULL,
			ItemMasterId [BIGINT] NOT NULL,
			ConditionId [BIGINT] NOT NULL,
			PartDescription [VARCHAR](MAX) NULL,
			StockLineNumber  [VARCHAR](250)  NULL,
			SerialNumber  [VARCHAR](250)  NULL,
			CustomerName [VARCHAR](250)  NULL,
			StockLineId [BIGINT]  NULL,
			QtyBilled [decimal](18,6)  NULL,
			ItemNo [INT]  NULL,
			SalesOrderId [BIGINT]  NULL,
			SalesOrderPartId [BIGINT]  NULL,
			SalesOrderStocklineId [BIGINT] NULL,
			Condition [VARCHAR](250)  NULL,
			CurrencyCode [VARCHAR](100)  NULL,
			TotalSales [decimal](18,6) NULL,   
			TotalUnitCost [decimal](18,6) NULL,  
			TotalFreight [decimal](18,6) NULL,  
			TotalFlatFreight [decimal](18,6) NULL,   
			TotalCharges [decimal](18,6) NULL,  
			TotalFlatCharges [decimal](18,6) NULL, 
			InvoiceStatus [VARCHAR](250)  NULL,
			SmentNo [VARCHAR](250)  NULL,
			VersionNo [VARCHAR](250)  NULL,
			IsVersionIncrease [INT]  NULL,
			IsNewInvoice [INT]  NULL,
			IsProforma [BIT] NULL,
			DepositAmount [DECIMAL](18,6) NULL,
			IsAllowIncreaseVersionForBillItem [BIT] NULL,
			[IsBilling] [bit] NULL,
			ECCN [VARCHAR](200)  NULL,
			HSCODE [VARCHAR](200)  NULL,
			[Weight] [DECIMAL](18,2) NULL,
			SizeLength [DECIMAL](18,2) NULL,
			SizeWidth [DECIMAL](18,2) NULL,
			SizeHeight [DECIMAL](18,2) NULL
		);

		IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
		BEGIN 
			PRINT '1.0'
			;WITH CTE (IndexColumn,
			SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
			StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
			TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling,
			ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight) AS
			(
			SELECT DISTINCT 
			--ROW_NUMBER() OVER (ORDER BY sop.SalesOrderPartId, sobi.SOBillingInvoicingId DESC) AS IndexColumn,
			0 AS IndexColumn,
			sosi.SalesOrderShippingId,   
			sosi.SalesOrderShippingItemId,   
			CASE WHEN sop.SalesOrderPartId IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems sobii_1 WITH(NOLOCK) 
			WHERE sobii_1.BillingInvoicingId = sobi.BillingInvoicingId and sobii_1.ItemMasterId = sop.ItemMasterId AND sobii_1.[ModuleId] = @SOModuleId
			AND ISNULL(sobii_1.IsPerformaInvoice, 0) = 0) > 0 THEN sobii.BillingInvoicingId  
			ELSE NULL END AS SOBillingInvoicingId,

			(SELECT TOP 1 case when CAST(a.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(a.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end 
				FROM dbo.BillingInvoicing a WITH (NOLOCK)
				INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
				Where a.ReferenceId = @SalesOrderId AND b.ItemMasterId = sop.ItemMasterId  AND a.[ModuleId] = @SOModuleId
				AND stk.StockLineId = b.StockLineId AND ShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) AS InvoiceDate,

			CASE WHEN sop.SalesOrderPartId IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems sobii_1 WITH(NOLOCK) 
			WHERE sobii_1.BillingInvoicingId = sobi.BillingInvoicingId and sobii_1.ItemMasterId = sop.ItemMasterId  AND sobii_1.[ModuleId] = @SOModuleId
			AND ISNULL(sobii_1.IsPerformaInvoice, 0) = 0) >0  THEN sobi.InvoiceNo ELSE NULL END AS InvoiceNo,
			sobi.InvoiceTypeId,
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
			stk.StockLineId,  
			(SELECT TOP 1 b.QtyBilled FROM dbo.BillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
				WHERE a.ReferenceId = @SalesOrderId AND a.[ModuleId] = @SOModuleId AND b.ItemMasterId = sop.ItemMasterId 
				AND stk.StockLineId = b.StockLineId AND b.ShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) AS QtyBilled,  
			0 AS ItemNo,  
			sop.SalesOrderId, 
			sop.SalesOrderPartId, 
			stk.SalesOrderStocklineId,
			cond.Description as 'Condition',   
			CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
			CASE WHEN ISNULL(sobii.BillingInvoicingId, 0) > 0 THEN ISNULL(sobi.GrandTotal, 0) ELSE 
			((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * sosi.QtyShipped)
			END 
			as 'TotalSales',  
			
			((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * ISNULL(sosi.QtyShipped, 0)) AS TotalUnitCost,
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
			 WHERE sof.SalesOrderId = @SalesOrderId 			  
				AND sof.ItemMasterId = sop.ItemMasterId 
				AND sof.ConditionId = @ConditionId 
				AND sof.IsActive = 1 
				AND sof.IsDeleted = 0)  AS TotalFreight,

			(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
				WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.FreightBilingMethodId = @FreightBilingMethodId)
			 AS  TotalFlatFreight,
			(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
			WHERE socg.SalesOrderId = @SalesOrderId 				
				AND socg.ItemMasterId = sop.ItemMasterId 
				AND socg.ConditionId = @ConditionId 
				AND socg.IsActive = 1 
				AND socg.IsDeleted = 0) 
			AS TotalCharges,
			(SELECT ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
			WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.ChargesBilingMethodId = @ChargesBilingMethodId)
			AS TotalFlatCharges,
			(SELECT a.InvoiceStatus FROM dbo.BillingInvoicing a WITH (NOLOCK) 
				INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
				Where a.ReferenceId = @SalesOrderId AND a.[ModuleId] = @SOModuleId AND sobii.BillingInvoicingId = a.BillingInvoicingId AND b.ItemMasterId = sop.ItemMasterId 
				AND stk.StockLineId = b.StockLineId AND ShippingId = sosi.SalesOrderShippingId
				AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) 
			AS InvoiceStatus, 
			sos.SmentNum AS 'SmentNo',
			sobii.VersionNo,
			(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
			CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
			0 AS IsProforma,
			0 AS DepositAmount,
			(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
			--ISNULL(sobi.[IsBilling], 0) 
			0 as [IsBilling],
			sop.ECCN AS ECCN,
			sop.HSCODE AS HSCODE,
			sop.[Weight] AS [Weight], 
			sop.SizeLength AS BillSizeLength,
			sop.SizeWidth AS BillSizeWidth,
			sop.SizeHeight AS BillSizeHeight

			FROM DBO.SalesOrderShipping sos WITH (NOLOCK)
			INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) on sop.SalesOrderId = sos.SalesOrderId --AND sop.SalesOrderPartId = sosi.SalesOrderPartId  
			INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) on SOPC.SalesOrderPartId = sop.SalesOrderPartId
			LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
			LEFT JOIN DBO.SalesOrderStocklineCost sosc WITH (NOLOCK) ON sosc.SalesOrderStocklineId = stk.SalesOrderStocklineId
			INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) on SOPT.SalesOrderId = sos.SalesOrderId AND SOPT.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
			INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sosi.SalesOrderShippingId = sos.SalesOrderShippingId  AND sosi.SOPickTicketId = SOPT.SOPickTicketId
			LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.ItemMasterId = sop.ItemMasterId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
			LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
			INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
			LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
			 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
			LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) on soc.SalesOrderShippingId = sos.SalesOrderShippingId  
			LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
			LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
			LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.FunctionalCurrencyId 
			LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
			WHERE sos.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId  
			GROUP BY sosi.SalesOrderShippingId, sosi.SalesOrderShippingItemId, sos.SOShippingNum, so.SalesOrderNumber, imt.ItemMasterId, imt.partnumber,imt.ItemMasterId,sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
			sl.SerialNumber, cr.[Name], sop.SalesOrderId, sop.SalesOrderPartId, stk.SalesOrderStocklineId, cond.Description, curr.Code, currb.Code, stk.StockLineId,  
			sobi.InvoiceStatus, sosi.QtyShipped, sop.ItemMasterId, sobi.InvoiceStatus,SOSC.NetSaleAmount, sobi.InvoiceNo, sobi.InvoiceTypeId,
			SOPC.TaxAmount, SOPC.TaxPercentage, sos.SmentNum, sobii.VersionNo,sobi.IsVersionIncrease,sobii.IsVersionIncrease, sobi.BillingInvoicingId, sobii.BillingInvoicingId,sobi.GrandTotal,--sobi.[IsBilling],
			sop.ECCN ,sop.HSCODE ,sop.[Weight] ,sop.SizeLength ,sop.SizeWidth ,sop.SizeHeight, stk.QtyOrder)

			INSERT INTO #SalesOrderBillingInvoiceChildList (IndexColumn,
			SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
			StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
			TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling,
			ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
			SELECT IndexColumn,
			SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
			StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
			TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling,
			ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight FROM CTE;
		END
		ELSE
		BEGIN
			PRINT '2.0'
			IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				WHERE SOS.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId)
			BEGIN  
				PRINT '2.1'
				IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.BillingInvoicing SOBI WITH (NOLOCK) 
				INNER JOIN DBO.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId
				INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) on SOP.SalesOrderId = SOBI.ReferenceId AND SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBI.[ModuleId] = @SOModuleId
				WHERE SOBI.ReferenceId = @SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice, 0) = 0 AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId)
				BEGIN
					PRINT '2.1.1.1'
					INSERT INTO #SalesOrderBillingInvoiceChildList(IndexColumn,
					SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo ,InvoiceTypeId,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId ,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
					TotalSales, TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
					ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
					(
					SELECT DISTINCT 
					--ROW_NUMBER() OVER (ORDER BY sop.SalesOrderPartId, sobi.SOBillingInvoicingId DESC) AS IndexColumn,
					0 AS IndexColumn,
					(CASE WHEN sobii.IsVersionIncrease = 1 then sobii.ShippingId 
					else (SELECT SOS.SalesOrderShippingId FROM DBO.SalesOrderShipping SOS 
					WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
					INNER JOIN DBO.SOPickTicket SO_PICK WITH (NOLOCK) on SO_PICK.SOPickTicketId = SOSI.SOPickTicketId
					WHERE SOS.SalesOrderId = @SalesOrderId AND SO_PICK.SOPickTicketId = SOPPick.SOPickTicketId) end) AS SalesOrderShippingId,   
					SOSI.SalesOrderShippingItemId,
					sobi.BillingInvoicingId SOBillingInvoicingId,
					case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
					sobi.InvoiceNo AS InvoiceNo,
					sobi.InvoiceTypeId,
					(CASE WHEN sobii.IsVersionIncrease = 1 then 
						(SELECT TOP 1 SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) WHERE SOS.SalesOrderShippingId = sobii.ShippingId) 
					else 
						(SELECT SOS.SOShippingNum 
						FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
						INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
						INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) on SOPICK.SOPickTicketId = SOSI.SOPickTicketId
						INNER JOIN DBO.SalesOrderStocklineV1 SOSB WITH (NOLOCK) on SOSB.SalesOrderStocklineId = SOPICK.SalesOrderPartStocklineId
						WHERE SOS.SalesOrderId = @SalesOrderId AND SOSB.SalesOrderStocklineId = STK.SalesOrderStocklineId
						AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId) end)
					AS SOShippingNum, 
				
					CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE (SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
					FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
					INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
					INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
					INNER JOIN DBO.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderStocklineId = SOPT.SalesOrderPartStocklineId
					WHERE SOS.SalesOrderId = @SalesOrderId AND stk.SalesOrderStocklineId = SOPS.SalesOrderStocklineId
					AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId) end  as QtyToBill,
				
					so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
					sl.SerialNumber, cr.[Name] as CustomerName,   
					stk.StockLineId,  
					ISNULL((SELECT ISNULL(b.QtyBilled, 0) FROM dbo.BillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
						WHERE b.BillingInvoicingItemId = SOBII.BillingInvoicingItemId AND b.StockLineId = SOBII.StockLineId
						AND a.ReferenceId = @SalesOrderId AND a.[ModuleId] = @SOModuleId
						AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0), 0) AS QtyBilled,
					0 AS ItemNo, 
					sop.SalesOrderId, sop.SalesOrderPartId, stk.SalesOrderStocklineId, cond.Description as 'Condition',   
					CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
					--CASE WHEN ISNULL(sobi.SOBillingInvoicingId, 0) = 0 THEN ((ISNULL(SOPC.UnitSalesPrice, 0) * ISNULL(SOR.QtyToReserve, 0)) +   
					CASE WHEN ISNULL(sobi.BillingInvoicingId, 0) = 0 THEN ((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 0)) * ((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
					FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
					INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
					INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
					INNER JOIN DBO.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderStocklineId = SOPT.SalesOrderPartStocklineId
					WHERE SOS.SalesOrderId = @SalesOrderId AND stk.SalesOrderStocklineId = SOPS.SalesOrderStocklineId
					AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId)))
					ELSE sobii.GrandTotal END as 'TotalSales',  

					((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 0)) * 
					(ISNULL((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
					FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
					INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
					INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
					INNER JOIN DBO.SalesOrderPartV1 SOPI WITH (NOLOCK) on SOPI.SalesOrderId = SOS.SalesOrderId AND SOPI.SalesOrderPartId = SOSI.SalesOrderPartId
					WHERE SOS.SalesOrderId = @SalesOrderId AND SOPT.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
					--AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId
					), 0) 
					-- + ISNULL(SOR.QtyToReserve, 0)
					)) AS TotalUnitCost,
			
					(SELECT ISNULL((BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
						--JOIN dbo.SalesOrderPartV1 SOPI WITH (NOLOCK) ON sof.SalesOrderPartId = SOPI.SalesOrderPartId AND SOPI.SalesOrderPartId = SOP.SalesOrderPartId
					 WHERE sof.SalesOrderId = @SalesOrderId 					
						AND sof.ItemMasterId = sop.ItemMasterId 
						AND sof.ConditionId = @ConditionId 
						AND sof.IsActive = 1 
						AND sof.IsDeleted = 0)  AS TotalFreight,

					(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.FreightBilingMethodId = @FreightBilingMethodId)
					 AS  TotalFlatFreight,

					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
						--JOIN dbo.SalesOrderPartV1 SOPI WITH (NOLOCK) ON socg.SalesOrderPartId = SOPI.SalesOrderPartId AND SOPI.SalesOrderPartId = SOP.SalesOrderPartId
					WHERE socg.SalesOrderId = @SalesOrderId 					
						AND socg.ItemMasterId = sop.ItemMasterId 
						AND socg.ConditionId = @ConditionId 
						AND socg.IsActive = 1 
						AND socg.IsDeleted = 0) 
					AS TotalCharges,
			
					(SELECT ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
					WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.ChargesBilingMethodId = @ChargesBilingMethodId)
					AS TotalFlatCharges,

					(SELECT a.InvoiceStatus FROM dbo.BillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
						Where a.ReferenceId = @SalesOrderId AND b.BillingInvoicingItemId = sobii.BillingInvoicingItemId
						AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) AS InvoiceStatus,
					(CASE WHEN sobii.IsVersionIncrease = 1 then (CASE WHEN SOBII.ShippingId > 0 THEN 1 ELSE 0 END) else 1 end) AS 'SmentNo',
					sobii.VersionNo, 
					(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
					CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					0 AS IsProforma,
					0 AS DepositAmount,
					(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
					--ISNULL(sobi.[IsBilling], 0) as [IsBilling],
					0 as [IsBilling],
					stk.ECCN AS ECCN,
					stk.HSCODE AS HSCODE,
					stk.[Weight] AS [Weight], 
					stk.SizeLength AS BillSizeLength,
					stk.SizeWidth AS BillSizeWidth,
					stk.SizeHeight AS BillSizeHeight

					FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId AND sop.SalesOrderId = @SalesOrderId
					LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					LEFT JOIN DBO.SOPickTicket SOPPick WITH (NOLOCK) on SOPPick.SalesOrderId = sop.SalesOrderId AND SOPPick.SalesOrderPartId = sop.SalesOrderPartId AND SOPPick.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
					LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) on SOSI.SOPickTicketId = SOPPick.SOPickTicketId
					LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.ShippingId = SOSI.SalesOrderShippingId AND sobii.StockLineId = stk.StockLineId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
					LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId  AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ReferenceId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
					 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = imt.PurchaseCurrencyId  
					LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
					LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = Stk.StockLineId AND SOR.SalesOrderId = @SalesOrderId
					WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId
					AND (SOSI.SalesOrderShippingItemId IS NOT NULL))

					UNION ALL

					SELECT DISTINCT 
						--ROW_NUMBER() OVER (ORDER BY sop.SalesOrderPartId, sobi.SOBillingInvoicingId DESC) AS IndexColumn,
						0 AS IndexColumn,
						0 AS SalesOrderShippingId,   
						0 AS SalesOrderShippingItemId,   
						sobi.BillingInvoicingId SOBillingInvoicingId,
						--sobi.InvoiceDate,
						case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
						sobi.InvoiceNo AS InvoiceNo,
						sobi.InvoiceTypeId,
						'' AS SOShippingNum,
						ISNULL(SOR.QtyToReserve, 0) AS QtyToBill,
						so.SalesOrderNumber,
						imt.partnumber, 
						imt.ItemMasterId,
						sop.ConditionId, 
						imt.PartDescription, 
						sl.StockLineNumber,  
						sl.SerialNumber, 
						cr.[Name] as CustomerName,   
						stk.StockLineId,
						ISNULL(sobii.QtyBilled, 0) AS QtyBilled,
						0 AS ItemNo,  
						sop.SalesOrderId, 
						sop.SalesOrderPartId, 
						stk.SalesOrderStocklineId,
						cond.Description as 'Condition',   
						CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
						((ISNULL(SOSC.NetSaleAmount, 0) / STK.QtyOrder) * SOR.QtyToReserve) AS 'TotalSales',
						((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 0)) * (ISNULL((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
						FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
						INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
						INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
						INNER JOIN DBO.SalesOrderPartV1 SOPI WITH (NOLOCK) on SOPI.SalesOrderId = SOS.SalesOrderId AND SOPI.SalesOrderPartId = SOSI.SalesOrderPartId
						WHERE SOS.SalesOrderId = @SalesOrderId AND SOPT.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
						), 0) + ISNULL(SOR.QtyToReserve, 0))) AS TotalUnitCost,
						0 AS TotalFreight,
						0 AS TotalFlatFreight,
						0 AS TotalCharges,
						0 AS TotalFlatCharges,
						'' AS InvoiceStatus,
						0 AS 'SmentNo',
						sobii.VersionNo,
						(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
						CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
						0 AS IsProforma,
						0 AS DepositAmount,
						(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
						--ISNULL(sobi.[IsBilling], 0) as [IsBilling],
						0 as [IsBilling],
						stk.ECCN AS ECCN,
						stk.HSCODE AS HSCODE,
						stk.[Weight] AS [Weight], 
						stk.SizeLength AS BillSizeLength,
						stk.SizeWidth AS BillSizeWidth,
						stk.SizeHeight AS BillSizeHeight

					FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId 
						LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = Stk.StockLineId AND SOR.SalesOrderId = @SalesOrderId
						LEFT JOIN DBO.SOPickTicket SOPPick WITH (NOLOCK) on SOPPick.SalesOrderId = sop.SalesOrderId AND SOPPick.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
						LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) on SOSI.SOPickTicketId = SOPPick.SOPickTicketId
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.StockLineId = stk.StockLineId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ReferenceId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
						 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
						LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
						LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.FunctionalCurrencyId  
						LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
						LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = @SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
						INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId and SOP.ConditionId = @ConditionId
					AND (SOSI.SalesOrderShippingItemId IS NULL AND ISNULL(SOR.QtyToReserve, 0) > 0)
				END
				ELSE
				BEGIN
					PRINT '2.1.1'
					;WITH CTE AS (
						SELECT DISTINCT 
							0 AS IndexColumn,
							ISNULL(
								CASE 
									WHEN sobii.IsVersionIncrease = 1 THEN 
										(SELECT TOP 1 SOS.SalesOrderShippingId 
										 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
										 INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
										 INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
										 WHERE SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
									ELSE 
										(SELECT TOP 1 SOS.SalesOrderShippingId 
										 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
										 INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
										 INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
										 INNER JOIN DBO.SalesOrderStocklineV1 SOSB WITH (NOLOCK) ON SOSB.SalesOrderStocklineId = SOPICK.SalesOrderPartStocklineId
										 WHERE SOS.SalesOrderId = @SalesOrderId 
										 AND SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
								END, 0) AS SalesOrderShippingId,
							0 AS SalesOrderShippingItemId,
							sobi.BillingInvoicingId SOBillingInvoicingId,
							sobii.BillingInvoicingItemId SOBillingInvoicingItemId,
							CASE 
								WHEN CAST(sobi.InvoiceDate AS DATE) = '0001-01-01 00:00:00' THEN NULL 
								ELSE CAST(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)
							END AS InvoiceDate,
							sobi.InvoiceNo,
							sobi.InvoiceTypeId,
							CASE WHEN sobii.IsVersionIncrease = 1 THEN 
								(SELECT TOP 1 SOS.SOShippingNum 
									FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
									INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
									INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
									WHERE SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
								ELSE 
								(SELECT TOP 1 SOS.SOShippingNum 
									FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
									INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
									INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
									INNER JOIN DBO.SalesOrderStocklineV1 SOSB WITH (NOLOCK) ON SOSB.SalesOrderStocklineId = SOPICK.SalesOrderPartStocklineId
									WHERE SOS.SalesOrderId = @SalesOrderId 
									AND SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
								END
							AS SOShippingNum,
							so.SalesOrderNumber, 
							imt.partnumber, 
							imt.ItemMasterId,
							sop.ConditionId, 
							imt.PartDescription, 
							sl.StockLineNumber,  
							sl.SerialNumber, 
							cr.[Name] AS CustomerName,   
							ISNULL(stk.StockLineId, 0) AS StockLineId,
							0 AS ItemNo,  
							sop.SalesOrderId, 
							sop.SalesOrderPartId, 
							stk.SalesOrderStocklineId,
							cond.Description AS 'Condition',   
							ISNULL(currb.Code, curr.Code) AS 'CurrencyCode',
							(CASE WHEN SOBII.ShippingId > 0 THEN 1 ELSE 0 END) AS 'SmentNo',
							ISNULL(SOSC.NetSaleAmount, 0) AS TotalUnitCost,
							sobii.VersionNo,
							CASE WHEN ISNULL(sobi.IsVersionIncrease, 0) = 1 then 0 else 1 end AS IsVersionIncrease,
							CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
							0 AS IsProforma,
							0 AS DepositAmount,
							(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
							--ISNULL(sobi.[IsBilling], 0) AS [IsBilling],
							0 AS [IsBilling],
							stk.ECCN, 
							stk.HSCODE, 
							stk.[Weight], 
							stk.SizeLength,
							stk.SizeWidth,
							stk.SizeHeight
						FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SOPickTicket SOPPick WITH (NOLOCK) ON SOPPick.SalesOrderId = sop.SalesOrderId AND SOPPick.SalesOrderPartId = sop.SalesOrderPartId AND SOPPick.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
						INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId 
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) ON sobii.SubReferenceId = sop.SalesOrderPartId AND (sobii.StockLineId = stk.StockLineId OR sobii.StockLineId IS NULL) AND sobii.[ModuleId] = @SOModuleId
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) ON sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice, 0) = 0 AND sobi.ReferenceId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
						 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
						LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
						LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.FunctionalCurrencyId  
						LEFT JOIN DBO.Currency currb WITH (NOLOCK) ON currb.CurrencyId = sobi.CurrencyId
						INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
						WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId AND SOP.ConditionId = @ConditionId
						AND (sobi.BillingInvoicingId IS NOT NULL OR ISNULL(stk.QtyReserved, 0) > 0)
					)

					INSERT INTO #SalesOrderBillingInvoiceChildList (IndexColumn,
					SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId , SOBillingInvoicingItemId, InvoiceDate , InvoiceNo, InvoiceTypeId ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
					SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
					ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
					SELECT DISTINCT
					--ROW_NUMBER() OVER (ORDER BY SalesOrderPartId, SOBillingInvoicingId DESC) AS IndexColumn,
					0 AS IndexColumn,
					SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId , SOBillingInvoicingItemId, InvoiceDate , InvoiceNo, InvoiceTypeId ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
					SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
					ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight FROM CTE;

					UPDATE  #SalesOrderBillingInvoiceChildList SET QtyToBill = tmpcash.QtyToBill
						FROM (SELECT CASE WHEN SOSI.SalesOrderShippingId IS NOT NULL THEN ISNULL(SOSI.QtyShipped, 0) ELSE ISNULL(SOP.QtyReserved, 0) END  QtyToBill, b.BillingInvoicingItemId, b.StockLineId
							FROM dbo.BillingInvoicingItems b WITH (NOLOCK) 
									JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingId = b.BillingInvoicingId
									AND tmpSOBI.SOBillingInvoicingItemId = b.BillingInvoicingItemId
									LEFT JOIN DBO.SOPickTicket SOPick WITH (NOLOCK) ON SOPick.SalesOrderId = @SalesOrderId AND tmpSOBI.SalesOrderStocklineId = SOPick.SalesOrderPartStocklineId
									LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOPick.SOPickTicketId = SOSI.SOPickTicketId AND b.ShippingId = SOSI.SalesOrderShippingId
									LEFT JOIN DBO.SalesOrderStocklineV1 SOP WITH (NOLOCK) ON b.StockLineId = SOP.StockLineId
						) tmpcash WHERE tmpcash.BillingInvoicingItemId = #SalesOrderBillingInvoiceChildList.SOBillingInvoicingItemId
						AND tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId

					UPDATE  #SalesOrderBillingInvoiceChildList SET QtyToBill = tmpcash.QtyToBill
						FROM (SELECT CASE WHEN SOSI.SalesOrderShippingId IS NOT NULL THEN ISNULL(SOSI.QtyShipped, 0) ELSE ISNULL(SOP.QtyReserved, 0) END QtyToBill, tmpSOBI.SalesOrderShippingId, tmpSOBI.StockLineId
							FROM #SalesOrderBillingInvoiceChildList tmpSOBI 
									LEFT JOIN DBO.SOPickTicket SOPick WITH (NOLOCK) ON SOPick.SalesOrderId = @SalesOrderId AND tmpSOBI.SalesOrderStocklineId = SOPick.SalesOrderPartStocklineId
									LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOPick.SOPickTicketId = SOSI.SOPickTicketId AND tmpSOBI.SalesOrderShippingId = SOSI.SalesOrderShippingId
									LEFT JOIN DBO.SalesOrderStocklineV1 SOP WITH (NOLOCK) ON SOP.StockLineId = tmpSOBI.StockLineId
						) tmpcash WHERE tmpcash.SalesOrderShippingId = #SalesOrderBillingInvoiceChildList.SalesOrderShippingId
						AND tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId
					  
					UPDATE  #SalesOrderBillingInvoiceChildList SET QtyBilled = tmpcash.QtyBilled
						FROM( SELECT b.QtyBilled, b.BillingInvoicingItemId, b.StockLineId
							FROM dbo.BillingInvoicingItems b WITH (NOLOCK) 
									JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingId = b.BillingInvoicingId
									AND tmpSOBI.SOBillingInvoicingItemId = b.BillingInvoicingItemId
						) tmpcash WHERE tmpcash.BillingInvoicingItemId = #SalesOrderBillingInvoiceChildList.SOBillingInvoicingItemId
						AND tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
					FROM( SELECT 
							CASE WHEN ISNULL(tmpSOBI.SOBillingInvoicingId, 0) = 0 THEN 
							((ISNULL(SOSC.NetSaleAmount, 0)))
							ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
							tmpSOBI.SOBillingInvoicingItemId,
							STK.SalesOrderStocklineId,
							SOBII.StockLineId
						FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
							INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
							--INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = SOP.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId
							LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
							LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
							LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0 AND SOBII.[ModuleId] = @SOModuleId
							LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
							LEFT JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingId = SOBI.BillingInvoicingId AND tmpSOBI.SOBillingInvoicingItemId = SOBII.BillingInvoicingItemId
					) tmpcash WHERE 
					tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId
					--tmpcash.SalesOrderStocklineId = #SalesOrderBillingInvoiceChildList.SalesOrderStocklineId

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
					FROM( SELECT 
							CASE WHEN ISNULL(tmpSOBI.SOBillingInvoicingId, 0) = 0 THEN 
							((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * ISNULL(STK.QtyReserved, 1))
							ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
							STK.SalesOrderStocklineId,
							tmpSOBI.SOBillingInvoicingId
						FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
							INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
							INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = SOP.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId
							LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
							LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
							LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0 AND SOBII.[ModuleId] = @SOModuleId
							LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
							LEFT JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = SOBII.BillingInvoicingItemId
					) tmpcash WHERE 
					tmpcash.SalesOrderStocklineId = #SalesOrderBillingInvoiceChildList.SalesOrderStocklineId
					AND tmpcash.SOBillingInvoicingId IS NULL
					AND #SalesOrderBillingInvoiceChildList.SalesOrderShippingId IS NULL
					
					UPDATE #SalesOrderBillingInvoiceChildList
					SET TotalFreight = tmp.TotalFreight
					FROM (SELECT SalesOrderPartId, SUM(ISNULL(BillingAmount, 0)) AS TotalFreight
						FROM dbo.SalesOrderFreight WITH (NOLOCK)
						WHERE IsActive = 1 AND IsDeleted = 0
						GROUP BY SalesOrderPartId
					) tmp JOIN #SalesOrderBillingInvoiceChildList sobi ON sobi.SalesOrderPartId = tmp.SalesOrderPartId
					WHERE ISNULL(sobi.IsVersionIncrease, 0) = 1;

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFlatFreight = tmpcash.TotalFreight
					FROM( SELECT ISNULL(SO.TotalFreight,0) As TotalFreight, SO.SalesOrderId
							FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
							JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
							WHERE so.FreightBilingMethodId = @FreightBilingMethodId
					) tmpcash WHERE tmpcash.SalesOrderId = #SalesOrderBillingInvoiceChildList.SalesOrderId

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalCharges = tmpcash.TotalCharges
					FROM( SELECT SUM(ISNULL((BillingAmount), 0)) AS TotalCharges , tmpSOBI.SalesOrderPartId, ISNULL(tmpSOBI.StockLineId, 0) StockLineId
							FROM dbo.SalesOrderCharges SOC WITH (NOLOCK) 
							LEFT JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderPartId = SOC.SalesOrderPartId
							WHERE SOC.SalesOrderId = @SalesOrderId 						
								AND SOC.ItemMasterId = tmpSOBI.ItemMasterId 
								AND SOC.ConditionId = tmpSOBI.ConditionId 
								AND SOC.IsActive = 1 
								AND SOC.IsDeleted = 0  AND ISNULL(tmpSOBI.IsVersionIncrease,0) = 1
							GROUP BY tmpSOBI.SalesOrderPartId, tmpSOBI.StockLineId
					) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId --AND tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFlatCharges = tmpcash.TotalFlatCharges
					FROM( SELECT ISNULL(SO.TotalCharges,0) As TotalFlatCharges, SO.SalesOrderId
							FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
							JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
							WHERE so.ChargesBilingMethodId = @ChargesBilingMethodId
					) tmpcash WHERE tmpcash.SalesOrderId = #SalesOrderBillingInvoiceChildList.SalesOrderId

					UPDATE  #SalesOrderBillingInvoiceChildList SET InvoiceStatus = tmpcash.InvoiceStatus
					FROM( SELECT SOBI.InvoiceStatus, tmpSOBI.SOBillingInvoicingId 
							FROM dbo.BillingInvoicing SOBI WITH (NOLOCK) 
							INNER JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId AND SOBII.[ModuleId] = @SOModuleId
							JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = SOBII.BillingInvoicingItemId 
							Where SOBI.ReferenceId = @SalesOrderId AND SOBI.[ModuleId] = @SOModuleId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
					
					) tmpcash WHERE tmpcash.SOBillingInvoicingId = #SalesOrderBillingInvoiceChildList.SOBillingInvoicingId

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFreight = 0
					WHERE IndexColumn > 1

					UPDATE  #SalesOrderBillingInvoiceChildList SET TotalCharges = 0
					WHERE IndexColumn > 1
				END				
			END
			ELSE
			BEGIN 
				PRINT '2.2'
				INSERT INTO #SalesOrderBillingInvoiceChildList(IndexColumn,
				SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId , SOBillingInvoicingItemId, InvoiceDate , InvoiceNo, InvoiceTypeId ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
				SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
				ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
				SELECT DISTINCT 
					--ROW_NUMBER() OVER (ORDER BY sop.SalesOrderPartId, sobi.SOBillingInvoicingId DESC) AS IndexColumn,
					0 AS IndexColumn,
					0 AS SalesOrderShippingId,   
					0 AS SalesOrderShippingItemId,   
					sobi.BillingInvoicingId,
					sobii.BillingInvoicingItemId,
					--sobi.InvoiceDate,
					case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
					sobi.InvoiceNo AS InvoiceNo,
					sobi.InvoiceTypeId,
					'' AS SOShippingNum,
					so.SalesOrderNumber, 
					imt.partnumber, 
					imt.ItemMasterId,
					sop.ConditionId, 
					imt.PartDescription, 
					sl.StockLineNumber,  
					sl.SerialNumber, 
					cr.[Name] as CustomerName,   
					ISNULL(stk.StockLineId, 0) StockLineId,
					0 AS ItemNo,  
					sop.SalesOrderId, 
					sop.SalesOrderPartId, 
					stk.SalesOrderStocklineId,
					cond.Description as 'Condition',   
					CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
					0 AS 'SmentNo',
					--(ISNULL(SOPC.UnitSalesPrice, 0) * ISNULL(SOR.QtyToReserve, 0)) AS TotalUnitCost,
					(ISNULL(SOSC.NetSaleAmount, 0)) AS TotalUnitCost,
					sobii.VersionNo,
					(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
					CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					0 AS IsProforma,
					0 AS DepositAmount,
					(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
					--ISNULL(sobi.[IsBilling], 0) as [IsBilling],
					0 as [IsBilling],
					stk.ECCN AS ECCN,
					stk.HSCODE AS HSCODE,
					stk.[Weight] AS [Weight], 
					stk.SizeLength AS BillSizeLength,
					stk.SizeWidth AS BillSizeWidth,
					stk.SizeHeight AS BillSizeHeight

				FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId 
					INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = Stk.StockLineId AND SOR.SalesOrderId = @SalesOrderId
					LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.StockLineId = stk.StockLineId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
					LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ReferenceId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
					 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.FunctionalCurrencyId  
					LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
					LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = @SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
					INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
				WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @SalesOrderPartId and SOP.ConditionId = @ConditionId
				AND SOR.QtyToReserve > 0

				UPDATE  #SalesOrderBillingInvoiceChildList SET QtyToBill = tmpcash.QtyToBill
							FROM( SELECT ISNULL(SORR.QtyToReserve, 0)  QtyToBill, tmpSOBI.StockLineId
									FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK)
									JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON SORR.SalesOrderPartId = tmpSOBI.SalesOrderPartId 
									AND SORR.StockLineId = tmpSOBI.StockLineId
									AND SORR.SalesOrderId = @SalesOrderId
							) tmpcash WHERE tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId

				UPDATE  #SalesOrderBillingInvoiceChildList SET QtyBilled = tmpcash.QtyBilled
							FROM( SELECT b.QtyBilled, b.SubReferenceId, b.StockLineId
								FROM dbo.BillingInvoicingItems b WITH (NOLOCK) 
										JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = b.BillingInvoicingItemId
										WHERE b.BillingInvoicingItemId = tmpSOBI.SOBillingInvoicingItemId
										AND ISNULL(b.IsPerformaInvoice,0) = 0 
							) tmpcash WHERE tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId
							--tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
				FROM( SELECT 
						CASE WHEN ISNULL(tmpSOBI.SOBillingInvoicingId, 0) = 0 THEN 
						((ISNULL(SOSC.NetSaleAmount, 0)))
						ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
						tmpSOBI.SOBillingInvoicingItemId
					FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
						LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
						LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
						LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0 AND SOBII.[ModuleId] = @SOModuleId
						LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
						LEFT JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingId = SOBI.BillingInvoicingId AND tmpSOBI.SOBillingInvoicingItemId = SOBII.BillingInvoicingItemId
				) tmpcash WHERE 
				tmpcash.SOBillingInvoicingItemId = #SalesOrderBillingInvoiceChildList.SOBillingInvoicingItemId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
				FROM( SELECT 
						CASE WHEN ISNULL(tmpSOBI.SOBillingInvoicingId, 0) = 0 THEN 
						((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * ISNULL(STK.QtyReserved, 1))
						ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
						STK.SalesOrderStocklineId,
						tmpSOBI.SOBillingInvoicingId
					FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
						INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
						INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = SOP.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId
						LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
						LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
						LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0 AND SOBII.[ModuleId] = @SOModuleId
						LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
						LEFT JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = SOBII.BillingInvoicingItemId
				) tmpcash WHERE 
				tmpcash.SalesOrderStocklineId = #SalesOrderBillingInvoiceChildList.SalesOrderStocklineId
				AND tmpcash.SOBillingInvoicingId IS NULL

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFreight = tmpcash.TotalFreight
				FROM( SELECT SUM(ISNULL((BillingAmount), 0)) AS TotalFreight , tmpSOBI.SalesOrderPartId, ISNULL(tmpSOBI.StockLineId, 0) StockLineId
					FROM dbo.SalesOrderFreight SOF WITH (NOLOCK) 
					JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderPartId = SOF.SalesOrderPartId
					WHERE sof.SalesOrderId = tmpSOBI.SalesOrderId 						
						AND sof.ItemMasterId = tmpSOBI.ItemMasterId 
						AND sof.ConditionId = tmpSOBI.ConditionId 
						AND sof.IsActive = 1 
						AND sof.IsDeleted = 0 AND ISNULL(tmpSOBI.IsVersionIncrease,0) = 1
					GROUP BY tmpSOBI.SalesOrderPartId, tmpSOBI.StockLineId
				) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId --AND tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFlatFreight = tmpcash.TotalFreight
				FROM( SELECT ISNULL(SO.TotalFreight,0) As TotalFreight, SO.SalesOrderId
						FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
						WHERE so.FreightBilingMethodId = @FreightBilingMethodId
				) tmpcash WHERE tmpcash.SalesOrderId = #SalesOrderBillingInvoiceChildList.SalesOrderId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalCharges = tmpcash.TotalCharges
				FROM( SELECT SUM(ISNULL((BillingAmount), 0)) AS TotalCharges , tmpSOBI.SalesOrderPartId, ISNULL(tmpSOBI.StockLineId, 0) StockLineId
						FROM dbo.SalesOrderCharges SOC WITH (NOLOCK) 
						LEFT JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderPartId = SOC.SalesOrderPartId
						WHERE SOC.SalesOrderId = @SalesOrderId 						
							AND SOC.ItemMasterId = tmpSOBI.ItemMasterId 
							AND SOC.ConditionId = tmpSOBI.ConditionId 
							AND SOC.IsActive = 1 
							AND SOC.IsDeleted = 0  AND ISNULL(tmpSOBI.IsVersionIncrease,0) = 1
						GROUP BY tmpSOBI.SalesOrderPartId, tmpSOBI.StockLineId
				) tmpcash WHERE tmpcash.SalesOrderPartId = #SalesOrderBillingInvoiceChildList.SalesOrderPartId --AND tmpcash.StockLineId = #SalesOrderBillingInvoiceChildList.StockLineId

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFlatCharges = tmpcash.TotalFlatCharges
				FROM( SELECT ISNULL(SO.TotalCharges,0) As TotalFlatCharges, SO.SalesOrderId
						FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
						WHERE so.ChargesBilingMethodId = @ChargesBilingMethodId
				) tmpcash WHERE tmpcash.SalesOrderId = #SalesOrderBillingInvoiceChildList.SalesOrderId

				UPDATE  #SalesOrderBillingInvoiceChildList SET InvoiceStatus = tmpcash.InvoiceStatus
				FROM( SELECT SOBI.InvoiceStatus, tmpSOBI.SOBillingInvoicingId 
						FROM dbo.BillingInvoicing SOBI WITH (NOLOCK) 
						INNER JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId 
						JOIN #SalesOrderBillingInvoiceChildList tmpSOBI ON tmpSOBI.SOBillingInvoicingItemId = SOBII.BillingInvoicingItemId
						Where SOBI.ReferenceId = @SalesOrderId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
						  AND SOBI.[ModuleId] = @SOModuleId
				) tmpcash WHERE tmpcash.SOBillingInvoicingId = #SalesOrderBillingInvoiceChildList.SOBillingInvoicingId
				
				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalFreight = 0
				WHERE IndexColumn > 1

				UPDATE  #SalesOrderBillingInvoiceChildList SET TotalCharges = 0
				WHERE IndexColumn > 1
			END
		END
			PRINT '3.0'
			INSERT INTO #SalesOrderBillingInvoiceChildList (IndexColumn,
				SalesOrderShippingId,SalesOrderShippingItemId,SOBillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
				TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProforma, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
				ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight,TotalUnitCost,TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges)
			(
					
					SELECT DISTINCT 
					--ROW_NUMBER() OVER (ORDER BY sop.SalesOrderPartId) AS IndexColumn,
					0 AS IndexColumn,
					0 AS SalesOrderShippingId,   
					0 AS SalesOrderShippingItemId,   
					sobi.BillingInvoicingId,
					--sobi.InvoiceDate,
					case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
					sobi.InvoiceNo AS InvoiceNo,
					sobi.InvoiceTypeId,
					'' AS SOShippingNum, 
					ISNULL(stk.QtyOrder, 0) AS QtyToBill, 
					so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
					sl.SerialNumber, cr.[Name] AS CustomerName,   
					stk.StockLineId,  
					ISNULL((SELECT ISNULL(b.QtyBilled, 0)
						FROM dbo.BillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
						WHERE b.BillingInvoicingItemId = SOBII.BillingInvoicingItemId AND ISNULL(b.IsPerformaInvoice,0) = 1 AND ISNULL(a.IsPerformaInvoice,0) = 1), 0) AS QtyBilled,  
					0 AS ItemNo,  
					sop.SalesOrderId, sop.SalesOrderPartId, stk.SalesOrderStocklineId, cond.Description AS 'Condition',   
					CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
					ISNULL(sobi.GrandTotal, 0) as 'TotalSales',  
					(SELECT a.InvoiceStatus FROM DBO.BillingInvoicing a WITH (NOLOCK) 
						INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
						Where a.ReferenceId = @SalesOrderId 
						AND b.BillingInvoicingItemId = sobii.BillingInvoicingItemId
						AND ISNULL(b.IsPerformaInvoice,0) = 1 AND ISNULL(a.IsPerformaInvoice,0) = 1) AS InvoiceStatus,
					0 AS 'SmentNo',
					sobii.VersionNo, 
					(CASE WHEN sobi.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
					CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
					1 AS IsProforma,
					ISNULL(sobi.DepositAmount,0) AS DepositAmount,
					(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
					--ISNULL(sobi.[IsBilling], 0) as [IsBilling],
					0 as [IsBilling],
					'' AS ECCN,
					'' AS HSCODE,
					0 AS [Weight], 
					0 AS BillSizeLength,
					0 AS BillSizeWidth,
					0 AS BillSizeHeight,
					CASE WHEN SOSC.[SalesOrderStocklineId] > 0 THEN ISNULL(SOSC.NetSaleAmount,0) ELSE ISNULL(spc.NetSaleAmount,0) END AS TotalUnitCost,
					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
						WHERE sof.SalesOrderId = @SalesOrderId 			  
						AND sof.ItemMasterId = sop.ItemMasterId 
						AND sof.ConditionId = @ConditionId 
						AND sof.IsActive = 1 
						AND sof.IsDeleted = 0)  AS TotalFreight,
					(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.FreightBilingMethodId = @FreightBilingMethodId)
					 AS  TotalFlatFreight,
					(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
					WHERE socg.SalesOrderId = @SalesOrderId 				
						AND socg.ItemMasterId = sop.ItemMasterId 
						AND socg.ConditionId = @ConditionId 
						AND socg.IsActive = 1 
						AND socg.IsDeleted = 0) 
					AS TotalCharges,
					(SELECT ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
					WHERE [SO].[SalesOrderId] = @SalesOrderId AND so.ChargesBilingMethodId = @ChargesBilingMethodId)
					AS TotalFlatCharges
					FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrderPartCost spc WITH (NOLOCK) ON spc.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) ON sobii.SubReferenceId = sop.SalesOrderPartId AND (sobii.StockLineId = stk.StockLineId OR ISNULL(sobii.StockLineId, 0) = 0) AND ISNULL(sobii.IsPerformaInvoice,0) = 1 AND sobii.[ModuleId] = @SOModuleId
					LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) ON sobi.BillingInvoicingId = sobii.BillingInvoicingId  AND ISNULL(sobi.IsPerformaInvoice,0) = 1 AND sobi.ReferenceId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId
					INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
					 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
					LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
					LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.FunctionalCurrencyId 
					LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
					WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @SalesOrderPartId AND sop.ConditionId = @ConditionId
					)

				;WITH FinalCTE AS(
				SELECT DISTINCT
					   ROW_NUMBER() OVER (PARTITION BY SalesOrderPartId, IsProforma ORDER BY SalesOrderPartId, IsVersionIncrease DESC) AS IndexColumn,
					   SalesOrderShippingId,
					   SalesOrderShippingItemId,
					   SOBillingInvoicingId,
					   SOBillingInvoicingItemId,
					   InvoiceDate,
					   InvoiceNo,
					   InvoiceTypeId,
					   SOShippingNum,
					   QtyToBill,
					   SalesOrderNumber,
					   partnumber,
					   PartDescription,
					   StockLineNumber,
					   SerialNumber,	
					   CustomerName,
					   StockLineId,
					   QtyBilled,
					   ItemNo,
					   SalesOrderId,
					   SalesOrderPartId,
					   SalesOrderStocklineId,
					   Condition,
					   CurrencyCode,
					   TotalSales,
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
					   [IsBilling],
					   ECCN,
					   HSCODE,
					   [Weight],
					   SizeLength,
					   SizeWidth,
					   SizeHeight
				FROM #SalesOrderBillingInvoiceChildList)

				SELECT IndexColumn,
					   SalesOrderShippingId,
					   SalesOrderShippingItemId,
					   SOBillingInvoicingId,
					   SOBillingInvoicingItemId,
					   InvoiceDate , 
					   InvoiceNo ,
					   InvoiceTypeId,
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
					   SalesOrderStocklineId,
					   Condition ,	
					   CurrencyCode ,
					   TotalSales ,
					   TotalUnitCost,
					   ISNULL(CASE WHEN IndexColumn = 1 THEN TotalFreight ELSE 0 END,0) TotalFreight,
					   TotalFlatFreight,
					   ISNULL(CASE WHEN IndexColumn = 1 THEN TotalCharges ELSE 0 END,0) TotalCharges,
					   TotalFlatCharges,
					   InvoiceStatus ,	
					   SmentNo ,
					   VersionNo ,
					   IsVersionIncrease ,	
					   IsNewInvoice,
					   IsProforma,
					   DepositAmount,
					   IsAllowIncreaseVersionForBillItem,
					   [IsBilling],
					   ECCN,
					   HSCODE,
					   [Weight],
					   SizeLength,
					   SizeWidth,
					   SizeHeight
				FROM FinalCTE
				ORDER BY partnumber, IsProforma DESC,InvoiceNo DESC, VersionNo DESC ;
   END  
   COMMIT  TRANSACTION  
  END TRY      
  BEGIN CATCH        
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
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