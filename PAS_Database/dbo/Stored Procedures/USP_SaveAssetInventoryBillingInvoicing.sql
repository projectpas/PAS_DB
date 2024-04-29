/*************************************************************           
 ** File:   [USP_SaveAssetInventoryBillingInvoicingPdfData]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to Get AssetInventory Billing Invoicing Pdf Data 
 ** Purpose:         
 ** Date:   18/04/2024  
          
 ** PARAMETERS: @ASBillingInvoicingId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/04/2024   Abhishek Jirawla     Created
     
-- EXEC USP_GetAssetInventoryBillingInvoicingPdfData 2
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveAssetInventoryBillingInvoicing]  
	@AssetInventoryId BIGINT,
	@InvoiceNumber VARCHAR(50),
	@CustomerId BIGINT,
	@MasterCompanyId BIGINT,
	@Remarks VARCHAR(MAX),
	@SalesTotal DECIMAL,
	@EmployeeId BIGINT,
	@CreatedBy VARCHAR(50),
	@InvoiceStatus VARCHAR(50),
	@NoofPieces INT,
	@UnitPrice DECIMAL
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
  DECLARE @AssetRecordId BIGINT,
	@AssetId VARCHAR(100), @InvoiceTypeId BIGINT,
	@InvoiceDate DATETIME = GETUTCDATE(),@PrintDate DATETIME = GETUTCDATE(),@ShipDate DATETIME = GETUTCDATE(),
	@SoldToSiteId BIGINT = 0,@BillToSiteId BIGINT = 0,@ShipToSiteId BIGINT = 0,
	@BillToAttention VARCHAR(50) = '',@ShipToAttention VARCHAR(50) = '',
	@SoldToCustomerId BIGINT = @CustomerId,
	@BillToCustomerId BIGINT = @CustomerId,
	@ShipToCustomerId BIGINT = @CustomerId,
	@CurrencyId VARCHAR(50) = '', @Level1 VARCHAR(50) = '', @Level2 VARCHAR(50) = '', @Level3 VARCHAR(50) = '', @Level4 VARCHAR(50) = '';


	DECLARE @ASBillingInvoicingId BIGINT;
	DECLARE @ASBillingInvoicingItemId BIGINT;
  
  SELECT @AssetRecordId = AI.AssetRecordId,  @AssetId = AI.AssetId, @CurrencyId = AI.CurrencyId
  FROM AssetInventory AS AI WITH(NOLOCK)
  WHERE AssetInventoryId = @AssetInventoryId

  SELECT @InvoiceTypeId = InvoiceTypeId
  FROM InvoiceType
  WHERE Description = 'STANDARD' AND MasterCompanyId = @MasterCompanyId



	INSERT INTO AssetInventoryBillingInvoicing
	(
		[AssetInventoryId],	[InvoiceTypeId], [InvoiceNo], [CustomerId],	[InvoiceDate],	[PrintDate], [ShipDate],[EmployeeId],[RevType],	[SoldToCustomerId],	[SoldToSiteId],
		[BillToCustomerId],	[BillToSiteId],	[BillToAttention],	[ShipToCustomerId],	[ShipToSiteId],	[ShipToAttention],	[IsPartialInvoice],	[CurrencyId],[AvailableCredit],
		[MasterCompanyId],	[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[InvoiceStatus],	[InvoiceFilePath],[GrandTotal],	[Level1],[Level2],
		[Level3],[Level4],[SubTotal],[TaxRate],	[SalesTax],[OtherTax],[MiscCharges],[Freight],[RemainingAmount],[PostedDate],[Notes],[SalesTotal],	[CreditMemoUsed],
		[VersionNo],[IsVersionIncrease],[IsProforma],[IsBilling],[DepositAmount],[UsedDeposit],	[BillToUserType],[ShipToUserType],[ProformaDeposit]
	)
	VALUES
	(
		@AssetInventoryId,@InvoiceTypeId,@InvoiceNumber,@CustomerId,@InvoiceDate,@PrintDate,@ShipDate,@EmployeeId,'Asset Sale',@SoldToCustomerId,@SoldToSiteId,
		@BillToCustomerId,@BillToSiteId,@BillToAttention,	@ShipToCustomerId,@ShipToSiteId,@ShipToAttention,0,@CurrencyId,0,
		@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@InvoiceStatus,'',@SalesTotal,@Level1,@Level2,
		@Level3,@Level4,@SalesTotal,0,	0,0,0,0,0,GETUTCDATE(),@Remarks,@SalesTotal,0,
		'',0,0,0,0,0,1,1,0
	)

	SET @ASBillingInvoicingId = SCOPE_IDENTITY()

	INSERT INTO AssetInventoryBillingInvoicingItem
	(
		[ASBillingInvoicingId],	[NoofPieces],[AssetRecordId],[MasterCompanyId],[CreatedBy],[UpdatedBy],	[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],	[UnitPrice],
		[AssetSaleShippingId],[PDFPath],[StockLineId],[VersionNo],[IsVersionIncrease],[IsProforma],[IsBilling]
	)
	VALUES
	(
		@ASBillingInvoicingId,@NoofPieces,@AssetRecordId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@UnitPrice,
		0,'',0,0,	0,	0,1
	)

	SET @ASBillingInvoicingItemId = SCOPE_IDENTITY()

	SELECT @ASBillingInvoicingId AS InvoiceId, @ASBillingInvoicingItemId AS InvoiceItemId

 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetAssetInventoryBillingInvoicingPdfData'              
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@AssetInventoryId, '') AS VARCHAR(100))           
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