/*************************************************************           
 ** File:   [GetSalesOrderBillingInvoicingData]           
 ** Author:   
 ** Description: 
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 @soBillingInvoiceId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1	12/11/2024		AMIT GHEDIYA		Created
	2	16th-Jan-2025	Devendra Shekh		Added New Fields (IsQuickBookGeneratedInvoice, IsUpdated)
	3   07-07-2025      Moin Bloch          Comment Code This SP NOT IN USE
     
   EXEC [dbo].[GetSalesOrderBillingInvoicingData] 1038
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderBillingInvoicingData]
    @soBillingInvoiceId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
			--Get BillingInvoicing Results
			SELECT 
				bi.BillingInvoicingId SOBillingInvoicingId,
				bi.CustomerId,
				bi.ReferenceId SalesOrderId,
				bi.InvoiceTypeId,
				bi.InvoiceNo,
				bi.InvoiceDate,
				bi.PrintDate,
				null ShipDate,
				bi.EmployeeId,
				bi.RevType,
				--bi.SoldToCustomerId,
				--bi.SoldToSiteId,
				--bi.BillToCustomerId,
				--bi.BillToSiteId,
				--bi.BillToAttention,
				--bi.ShipToCustomerId,
				--bi.ShipToSiteId,
				--bi.ShipToAttention,
				bi.CurrencyId,
				--ISNULL(bi.AvailableCredit,0) AS AvailableCredit,
				bi.InvoiceStatus,
				bi.InvoiceFilePath,
				ISNULL(bi.GrandTotal,0) AS GrandTotal,
				--ISNULL(bi.Level1,'') AS Level1,
				--ISNULL(bi.Level2,'') AS Level2,
				--ISNULL(bi.Level3,'') AS Level3,
				--ISNULL(bi.Level4,'') AS Level4,
				ISNULL(bi.SubTotal,0) AS SubTotal,
				--ISNULL(bi.TaxRate,0) AS TaxRate,
				ISNULL(bi.SalesTax,0) AS SalesTax,
				ISNULL(bi.OtherTax,0) AS OtherTax,
				--ISNULL(bi.MiscCharges,0) AS MiscCharges,
				--ISNULL(bi.Freight,0) AS Freight,
				bi.Notes,
				ISNULL(bi.RemainingAmount,0) AS RemainingAmount,
				bi.PostedDate,
				--ISNULL(bi.SalesTotal,0) AS SalesTotal,
				--ISNULL(CreditMemoUsed,0) AS CreditMemoUsed,
				bi.VersionNo,
				ISNULL(bi.IsVersionIncrease,0) AS IsVersionIncrease,
				0 AS isNewInvoice,
				0 AS validBatchDetails,
				ISNULL(bi.IsPerformaInvoice,0) AS IsProforma,
				--ISNULL(bi.IsBilling,0) AS IsBilling,
				ISNULL(bi.DepositAmount,0) AS DepositAmount,
				ISNULL(bi.UsedDeposit,0) AS UsedDeposit,
				--ISNULL(bi.BillToUserType,0) AS BillToUserType,
				--ISNULL(bi.ShipToUserType,0) AS ShipToUserType,
				ISNULL(bi.ProformaDeposit,0) AS ProformaDeposit,
				ISNULL(bi.OriginCountryId,0) AS OriginCountryId,
				ISNULL(bi.ShipToCountryId,0) AS ShipToCountryId,
				bi.CreatedBy,
				bi.SignEmpId,
				bi.MasterCompanyId,
				bi.CreatedDate,
				bi.UpdatedBy,
				bi.UpdatedDate,
				bi.IsActive,
				bi.IsDeleted,
				ISNULL(bi.IsQuickBookGeneratedInvoice,0) AS IsQuickBookGeneratedInvoice,
				ISNULL(bi.IsUpdated,0) AS IsUpdated
			FROM DBO.BillingInvoicing bi WITH(NOLOCK)
			inner join DBO.BillingInvoicing bii WITH(NOLOCK) on bi.BillingInvoicingId = bii.BillingInvoicingId
			inner join DBO.BillingInvoicingDetails bid WITH(NOLOCK) on bi.BillingInvoicingId = bid.BillingInvoicingId
			WHERE bi.BillingInvoicingId = @soBillingInvoiceId;

			----Get BillingInvoicingItems Results
			--SELECT 
			--	 bii.SOBillingInvoicingItemId
			--	,bii.SOBillingInvoicingId
			--	,bii.SalesOrderPartId
			--	,bii.ItemMasterId
			--	,bii.SalesOrderShippingId
			--	,bii.NoofPieces
			--	,ISNULL(bii.UnitPrice,0) AS UnitPrice
			--	,ISNULL(bii.PDFPath,'') AS PDFPath
			--	,ISNULL(bii.StocklineId,0) AS StocklineId
			--	,ISNULL(bii.VersionNo,0) AS VersionNo
			--	,bii.IsVersionIncrease
			--	,ISNULL(bii.[IsProforma],0) AS IsProforma
			--    ,ISNULL(bii.[IsBilling],0) AS IsBilling
			--    ,bii.[PartCost]
			--    ,ISNULL(bii.[MiscCharges],0) AS MiscCharges
			--    ,ISNULL(bii.[Freight],0) AS Freight
			--    ,bii.[SubTotal]
			--    ,ISNULL(bii.[OtherTaxPercent],0) AS OtherTaxPercent
			--    ,ISNULL(bii.[SalesTaxPercent],0) AS SalesTaxPercent
			--    ,ISNULL(bii.[GrandTotal],0) AS GrandTotal
			--    ,ISNULL(bii.[OtherTax],0) AS OtherTax
			--    ,ISNULL(bii.[SalesTax],0) AS SalesTax
			--    ,bii.[ECCN]
			--    ,bii.[HSCODE]
			--    ,ISNULL(bii.[Weight],0) AS [Weight]
			--    ,ISNULL(bii.[SizeLength],0) AS SizeLength
			--    ,ISNULL(bii.[SizeWidth],0) AS SizeWidth
			--    ,ISNULL(bii.[SizeHeight],0) AS SizeHeight
			--	,bii.CreatedBy
			--	,bii.MasterCompanyId
			--	,bii.CreatedDate
			--	,bii.UpdatedBy
			--	,bii.UpdatedDate
			--	,bii.IsActive
			--	,bii.IsDeleted
			--FROM DBO.BillingInvoicingItems bii WITH(NOLOCK)
			--WHERE bii.BillingInvoicingId = @soBillingInvoiceId;
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderBillingInvoicingData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@soBillingInvoiceId, '') + ''
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