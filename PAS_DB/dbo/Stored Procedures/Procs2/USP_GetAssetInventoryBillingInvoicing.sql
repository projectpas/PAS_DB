/*********************
 ** File:   [USP_GetAssetInventoryBillingInvoicing]
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used to return Asset Inventory billing Invoicing details
 ** Purpose:
 ** Date:   09/16/2024
 ** PARAMETERS:         
 @ASBillingInvoicingId BIGINT
 ** RETURN VALUE:
 **********************
  ** Change History
 **********************
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    09/16/2024   Abhishek Jirawla			Created


 EXECUTE USP_GetAssetInventoryBillingInvoicing 37
**********************/ 
CREATE   PROCEDURE [dbo].[USP_GetAssetInventoryBillingInvoicing]
    @ASBillingInvoicingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT bi.[ASBillingInvoicingId]
		,bi.[AssetInventoryId]
		,bi.[InvoiceTypeId]
		,bi.[InvoiceNo]
		,bi.[CustomerId]
		,bi.[InvoiceDate]
		,bi.[PrintDate]
		,bi.[ShipDate]
		,bi.[EmployeeId]
		,bi.[RevType]
		,bi.[SoldToCustomerId]
		,bi.[SoldToSiteId]
		,bi.[BillToCustomerId]
		,bi.[BillToSiteId]
		,bi.[BillToAttention]
		,bi.[ShipToCustomerId]
		,bi.[ShipToSiteId]
		,bi.[ShipToAttention]
		,bi.[IsPartialInvoice]
		,bi.[CurrencyId]
		,bi.[AvailableCredit]
		,bi.[MasterCompanyId]
		,bi.[CreatedBy]
		,bi.[UpdatedBy]
		,bi.[CreatedDate]
		,bi.[UpdatedDate]
		,bi.[IsActive]
		,bi.[IsDeleted]
		,bi.[InvoiceStatus]
		,bi.[InvoiceFilePath]
		,bi.[GrandTotal]
		,bi.[Level1]
		,bi.[Level2]
		,bi.[Level3]
		,bi.[Level4]
		,bi.[SubTotal]
		,bi.[TaxRate]
		,bi.[SalesTax]
		,bi.[OtherTax]
		,bi.[MiscCharges]
		,bi.[Freight]
		,bi.[RemainingAmount]
		,bi.[PostedDate]
		,bi.[Notes]
		,bi.[SalesTotal]
		,bi.[CreditMemoUsed]
		,bi.[VersionNo]
		,bi.[IsVersionIncrease]
		,bi.[IsProforma]
		,bi.[IsBilling]
		,bi.[DepositAmount]
		,bi.[UsedDeposit]
		,bi.[BillToUserType]
		,bi.[ShipToUserType]
		,bi.[ProformaDeposit] 
		,bii.[ASBillingInvoicingItemId]
		,bii.[ASBillingInvoicingId]
		,bii.[NoofPieces]
		,bii.[AssetRecordId]
		,bii.[MasterCompanyId]
		,bii.[CreatedBy]
		,bii.[UpdatedBy]
		,bii.[CreatedDate]
		,bii.[UpdatedDate]
		,bii.[IsActive]
		,bii.[IsDeleted]
		,bii.[UnitPrice]
		,bii.[AssetSaleShippingId]
		,bii.[PDFPath]
		,bii.[StockLineId]
		,bii.[VersionNo]
		,bii.[IsVersionIncrease]
		,bii.[IsProforma]
		,bii.[IsBilling]
    FROM AssetInventoryBillingInvoicing AS bi WITH(NOLOCK)
		INNER JOIN AssetInventoryBillingInvoicingItem AS bii WITH(NOLOCK) ON bi.ASBillingInvoicingId = bii.ASBillingInvoicingId
    WHERE bi.ASBillingInvoicingId = @ASBillingInvoicingId;

END