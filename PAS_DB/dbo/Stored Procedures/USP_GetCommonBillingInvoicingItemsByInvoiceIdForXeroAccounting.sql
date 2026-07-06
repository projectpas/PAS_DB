/*****************************************************************************************
 ** File:   [[USP_GetCommonBillingInvoicingItemsByInvoiceIdForXeroAccounting]]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Get Common Billing Invoicing Items
 ** Purpose:
 ** Date:   19/05/2025
 ** RETURN VALUE:
 ******************************************************************************************
 ** Change History
 ******************************************************************************************
 ** PR   Date         Author		    Change Description
 ** --   --------     -------		 --------------------------------
    1    19/05/2026   Moin Bloch        Created
    2    29/05/2026   Bhargav Saliya    Added @IsSync Case
	3    05/06/2026   Moin Bloch        Fix Discription
	4    08/06/2026   Abhishek Jirawla  Adding ItemMasterId
	5    09/06/2026   Moin Bloch        Fix For Due Date PN-16784
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

	EXEC [dbo].[USP_GetCommonBillingInvoicingItemsByInvoiceIdForXeroAccounting] 12682,15,0
********************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCommonBillingInvoicingItemsByInvoiceIdForXeroAccounting]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL,
@IsSync BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT

	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';

		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN
			SELECT BII.[InvoiceNo],
				   BII.[BillingInvoicingId],
			       CST.[QuickBooksReferenceId] [ContactId],
				   BII.[InvoiceDate],
				   DATEADD(DAY,ISNULL(WO.NetDays,0),BII.[InvoiceDate]) DueDate,
				   CRR.[Code]
				  ---------- LINEAMOUNT TYPES ----------
				  --Exclusive	Line items are exclusive of tax ,
				  --Inclusive	Line items are inclusive tax,
				  --NoTax	    Line have no tax
				  ,'Exclusive' LineAmountTypes
			   FROM [dbo].[BillingInvoicing] BII WITH(NOLOCK)
			  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BII.[ReferenceId] = WO.[WorkOrderId]
			  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = WO.[CustomerId]
			  INNER JOIN [dbo].[Currency] CRR WITH(NOLOCK) ON BII.[CurrencyId] = CRR.[CurrencyId]
			   WHERE ISNULL(BII.[IsVersionIncrease],0) = 0 AND ISNULL(BII.[IsPerformaInvoice],0) = 0
			   AND (
                    (@IsSync = 0 AND BII.BillingInvoicingId = @BillingInvoicingId)  -- Single invoice
                OR  (@IsSync = 1 AND ISNULL(BII.QuickBooksReferenceId, '') = ''
                     AND ISNULL(BII.IsUpdated, 0) = 1)                              -- All unsynced
				)

  			SELECT ISNULL(BII.[UnitPrice],0) [UnitPrice]
				  ,ISNULL(BII.[QtyBilled],0) [QtyBilled]
				  ,ISNULL(BII.[PartCost],0) [PartCost]
				  ,ISNULL(BII.[IsTotalCheck],0) [IsTotalCheck]
				  ,ISNULL(BII.[TotalBillingCost],0) [TotalBillingCost]
				  ,ISNULL(BII.[TotalBillingCostPercent],0) [TotalBillingCostPercent]
				  ,ISNULL(BII.[TotalBillingCostPlus],0) [TotalBillingCostPlus]
				  ,ISNULL(BII.[IsMaterialCheck],0) [IsMaterialCheck]
				  ,ISNULL(BII.[MaterialCost],0) [MaterialCost]
				  ,ISNULL(BII.[MaterialCostPercent],0) [MaterialCostPercent]
				  ,ISNULL(BII.[MaterialCostPlus],0) [MaterialCostPlus]
				  ,ISNULL(BII.[IsLaborCheck],0) [IsLaborCheck]
				  ,ISNULL(BII.[LaborCost],0) [LaborCost]
				  ,ISNULL(BII.[LaborCostPercent],0) [LaborCostPercent]
				  ,ISNULL(BII.[LaborCostPlus],0) [LaborCostPlus]
				  ,ISNULL(BII.[IsFreightCheck],0) [IsFreightCheck]
				  ,ISNULL(BII.[Freight],0) [Freight]
				  ,ISNULL(BII.[FreightCostPercent],0) [FreightCostPercent]
				  ,ISNULL(BII.[FreightCostPlus],0) [FreightCostPlus]
				  ,ISNULL(BII.[IsMiscChargesCheck],0) [IsMiscChargesCheck]
				  ,ISNULL(BII.[MiscCharges],0) [MiscCharges]
				  ,ISNULL(BII.[MiscChargesCostPercent],0) [MiscChargesCostPercent]
				  ,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
				  ,ISNULL(BII.[SubTotal],0) [SubTotal]
				  ,ISNULL(BII.[SalesTaxPercent],0) [SalesTaxPercent]
				  ,ISNULL(BII.[OtherTaxPercent],0) [OtherTaxPercent]
				  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
				  ,ITM.[QuickBooksReferenceId] [LineItemID]
				  ,ITM.[PartDescription]  [Notes]
				  ---------- TAX TYPE ----------
				  -- INPUT	0.00	TAX ON PURCHASES
				  -- OUTPUT	0.00	TAX ON SALES
				  ,'OUTPUT' [TaxType]
				  ,'200' [AccountCode]
				  ,'' [AccountID]
				  ,BII.[BillingInvoicingId]
				  ,ISNULL(BII.[SalesTax],0) [SalesTax]
				  ,ISNULL(BII.[OtherTax],0) [OtherTax]
				  ,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
				  ,ISNULL(BII.[FreightCostPlus],0)   [FreightCostPlus]
				  ,ISNULL(BII.[ItemMasterId],0) [ItemMasterId]
			   FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
			  INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON BII.[ReferenceId] = WO.[WorkOrderId]
			  INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON ITM.[ItemMasterId] = BII.[ItemMasterId]
			  INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]
			   WHERE ISNULL(BII.[IsVersionIncrease],0) = 0 AND ISNULL(BII.[IsPerformaInvoice],0) = 0
			   AND (
                    (@IsSync = 0 AND BII.BillingInvoicingId = @BillingInvoicingId)
                OR  (@IsSync = 1 AND ISNULL(BI.QuickBooksReferenceId, '') = ''
                     AND ISNULL(BI.IsUpdated, 0) = 1)
              )
		 AND ISNULL(ITM.IsNonStock,0) = 0 END
		IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
		BEGIN
			SELECT BII.[InvoiceNo],
				   BII.[BillingInvoicingId],
			       CST.[QuickBooksReferenceId] [ContactId],
				   BII.[InvoiceDate],
				   DATEADD(DAY,ISNULL(SO.NetDays,0),BII.[InvoiceDate]) DueDate,
				   CRR.[Code]
				  ---------- LINEAMOUNT TYPES ----------
				  --Exclusive	Line items are exclusive of tax ,
				  --Inclusive	Line items are inclusive tax,
				  --NoTax	    Line have no tax
				  ,'Exclusive' LineAmountTypes
			   FROM [dbo].[BillingInvoicing] BII WITH(NOLOCK)
			  INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BII.[ReferenceId] = SO.[SalesOrderId]
			  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = SO.[CustomerId]
			  INNER JOIN [dbo].[Currency] CRR WITH(NOLOCK) ON BII.[CurrencyId] = CRR.[CurrencyId]
			   WHERE ISNULL(BII.[IsVersionIncrease],0) = 0 AND ISNULL(BII.[IsPerformaInvoice],0) = 0
			   AND (
                    (@IsSync = 0 AND BII.BillingInvoicingId = @BillingInvoicingId)
                OR  (@IsSync = 1 AND ISNULL(BII.QuickBooksReferenceId, '') = ''
                     AND ISNULL(BII.IsUpdated, 0) = 1)
              )

			SELECT ISNULL(BII.[UnitPrice],0) [UnitPrice]
				  ,ISNULL(BII.[QtyBilled],0) [QtyBilled]
				  ,ISNULL(BII.[PartCost],0) [PartCost]
				  ,ISNULL(BII.[IsTotalCheck],0) [IsTotalCheck]
				  ,ISNULL(BII.[TotalBillingCost],0) [TotalBillingCost]
				  ,ISNULL(BII.[TotalBillingCostPercent],0) [TotalBillingCostPercent]
				  ,ISNULL(BII.[TotalBillingCostPlus],0) [TotalBillingCostPlus]
				  ,ISNULL(BII.[IsMaterialCheck],0) [IsMaterialCheck]
				  ,ISNULL(BII.[MaterialCost],0) [MaterialCost]
				  ,ISNULL(BII.[MaterialCostPercent],0) [MaterialCostPercent]
				  ,ISNULL(BII.[MaterialCostPlus],0) [MaterialCostPlus]
				  ,ISNULL(BII.[IsLaborCheck],0) [IsLaborCheck]
				  ,ISNULL(BII.[LaborCost],0) [LaborCost]
				  ,ISNULL(BII.[LaborCostPercent],0) [LaborCostPercent]
				  ,ISNULL(BII.[LaborCostPlus],0) [LaborCostPlus]
				  ,ISNULL(BII.[IsFreightCheck],0) [IsFreightCheck]
				  ,ISNULL(BII.[Freight],0) [Freight]
				  ,ISNULL(BII.[FreightCostPercent],0) [FreightCostPercent]
				  ,ISNULL(BII.[FreightCostPlus],0) [FreightCostPlus]
				  ,ISNULL(BII.[IsMiscChargesCheck],0) [IsMiscChargesCheck]
				  ,ISNULL(BII.[MiscCharges],0) [MiscCharges]
				  ,ISNULL(BII.[MiscChargesCostPercent],0) [MiscChargesCostPercent]
				  ,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
				  ,ISNULL(BII.[SubTotal],0) [SubTotal]
				  ,ISNULL(BII.[SalesTaxPercent],0) [SalesTaxPercent]
				  ,ISNULL(BII.[OtherTaxPercent],0) [OtherTaxPercent]
				  ,ISNULL(BII.[GrandTotal],0) [GrandTotal]
				  ,ITM.[QuickBooksReferenceId] [LineItemID]
				  ,ITM.[PartDescription]  [Notes]
				  ---------- TAX TYPE ----------
				  -- INPUT	0.00	TAX ON PURCHASES
				  -- OUTPUT	0.00	TAX ON SALES
				  ,'OUTPUT' [TaxType]
				  ,'200' [AccountCode]
				  ,'' [AccountID]
				  ,BII.[BillingInvoicingId]
				  ,ISNULL(BII.[SalesTax],0) [SalesTax]
				  ,ISNULL(BII.[OtherTax],0) [OtherTax]
				  ,ISNULL(BII.[MiscChargesCostPlus],0) [MiscChargesCostPlus]
				  ,ISNULL(BII.[FreightCostPlus],0)   [FreightCostPlus]
				  ,ISNULL(BII.[ItemMasterId],0) [ItemMasterId]
			   FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				  INNER JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON BII.[ReferenceId] = SO.[SalesOrderId]
				  INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON ITM.[ItemMasterId] = BII.[ItemMasterId]
				  INNER JOIN [dbo].[BillingInvoicing] BI WITH(NOLOCK) ON BI.[BillingInvoicingId] = BII.[BillingInvoicingId]
			   WHERE ISNULL(BII.[IsVersionIncrease],0) = 0 AND ISNULL(BII.[IsPerformaInvoice],0) = 0
			   AND (
                    (@IsSync = 0 AND BII.BillingInvoicingId = @BillingInvoicingId)
                OR  (@IsSync = 1 AND ISNULL(BI.QuickBooksReferenceId, '') = ''
                     AND ISNULL(BI.IsUpdated, 0) = 1)
              )
		 AND ISNULL(ITM.IsNonStock,0) = 0 END
		IF(@ModuleId = @EXModuleId) /*********START:EXCHANGE SALES ORDER ********/
		BEGIN
			SELECT BII.[InvoiceNo],
			       CST.[QuickBooksReferenceId] [ContactId],
				   BII.[InvoiceDate],
				   DATEADD(DAY,ISNULL(ESO.NetDays,0),BII.[InvoiceDate]) [DueDate],
				   CRR.[Code]
				  ---------- LINEAMOUNT TYPES ----------
				  --Exclusive	Line items are exclusive of tax ,
				  --Inclusive	Line items are inclusive tax,
				  --NoTax	    Line have no tax
				  ,'Exclusive' [LineAmountTypes]
				  ,BII.[SOBillingInvoicingId] [BillingInvoicingId]
			   FROM [dbo].[ExchangeSalesOrderBillingInvoicing] BII WITH(NOLOCK)
			  INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) ON BII.[ExchangeSalesOrderId] = ESO.[ExchangeSalesOrderId]
			  INNER JOIN [dbo].[Customer] CST WITH(NOLOCK) ON CST.[CustomerId] = ESO.[CustomerId]
			   LEFT JOIN [dbo].[Currency] CRR WITH(NOLOCK) ON BII.[CurrencyId] = CRR.[CurrencyId]
			   WHERE (
                    (@IsSync = 0 AND BII.SOBillingInvoicingId = @BillingInvoicingId)
                OR  (@IsSync = 1 AND ISNULL(BII.QuickBooksReferenceId, '') = ''
                     AND ISNULL(BII.IsUpdated, 0) = 1)
              )

			SELECT ISNULL(SOBII.[UnitPrice], 0) AS [UnitPrice]
			       ,SSBI.[Qty] AS [QtyBilled]
			       ,IM.[QuickBooksReferenceId] [LineItemID]
				   ,IM.[PartDescription]  [Notes]
				   ,ISNULL(SOBII.[UnitPrice], 0) AS [TotalBillingCostPlus]
				   ,ISNULL(SOBI.SalesTax, 0) AS [SalesTax]
				   ,ISNULL(SOBI.OtherTax, 0) AS [OtherTax]
				   ,(ISNULL(SOBI.OtherTax, 0) + ISNULL(SOBI.SalesTax, 0)) AS [TotalTax]
				   ,ISNULL(SOBI.SubTotal, 0) AS [SubTotal]
				   ,ISNULL(SOBI.GrandTotal, 0) AS [GrandTotal]
				   ,ISNULL(SOBII.MiscCharges, 0) [MiscChargesCostPlus]
				   ,ISNULL(SOBII.Freight, 0) [FreightCostPlus]
				   -- INPUT	0.00	TAX ON PURCHASES
				   -- OUTPUT	0.00	TAX ON SALES
				   ,'OUTPUT' [TaxType]
				   ,'200' [AccountCode]
				   ,'' [AccountID]
				   ,SOBII.[SOBillingInvoicingId] [BillingInvoicingId]
				   ,ISNULL(SOBII.[ItemMasterId], 0) [ItemMasterId]
				FROM [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH(NOLOCK)
					INNER JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = SOBII.SOBillingInvoicingId
					INNER JOIN [dbo].[ExchangeSalesOrder] SO WITH(NOLOCK) ON SO.ExchangeSalesOrderId= SOBI.ExchangeSalesOrderId AND ISNULL(SO.IsVendor, 0) = 0
					LEFT JOIN [dbo].[ExchangeSalesOrderScheduleBilling] SSBI WITH(NOLOCK) ON SSBI.ExchangeSalesOrderScheduleBillingId = SOBII.ExchangeSalesOrderScheduleBillingId
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId= SOBII.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0 WHERE (
                    (@IsSync = 0 AND SOBII.SOBillingInvoicingId = @BillingInvoicingId)
                OR  (@IsSync = 1 AND ISNULL(SOBI.QuickBooksReferenceId, '') = ''
                     AND ISNULL(SOBI.IsUpdated, 0) = 1)
              )
		END

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[USP_GetCommonBillingInvoicingItemsByInvoiceIdForXeroAccounting]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
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