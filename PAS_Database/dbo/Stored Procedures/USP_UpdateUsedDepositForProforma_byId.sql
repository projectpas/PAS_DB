/*************************************************************             
 ** File:   [USP_UpdateUsedDepositForProforma_byId]             
 ** Author:   Devendra Shekh 
 ** Description: This stored procedure is used to update usedDeposit amt for proforma
 ** Purpose:           
 ** Date:   14/02/2024 (DD/MM/YYYY)     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				-------------------------------            
    1    14/02/2024   Devendra Shekh		created
    1    15/02/2024   Devendra Shekh		changes subtotal to grandtotal

	EXEC  [dbo].[USP_UpdateUsedDepositForProforma_byId] 508
**************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_UpdateUsedDepositForProforma_byId]      
@BillingInvoicingId BIGINT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      

	DECLARE @WorkOrderId BIGINT = 0,
	@DepositAmt DECIMAL(18,2) = 0,
	@TotalWorkOrderCostPlus DECIMAL(18,2) = 0,
	@GrandTotal DECIMAL(18,2) = 0,
	@TotalTax DECIMAL(18,2) = 0,
	@OtherTotalTax DECIMAL(18,2) = 0,
	@CustomerId BIGINT = 0,
	@TotalTaxRec DECIMAL(18,2) = 0,
	@UsedDepositAmt DECIMAL(18,2) = 0,
	@StartTacRec BIGINT = 1,
	@WOProFormaBillingInvoicingId BIGINT = 0;

	DECLARE @SALESTAX DECIMAL(18,2) = 0,
	@OTHERTAX DECIMAL(18,2) = 0,
	@TaxRate DECIMAL(18,2) = 0,
	@TaxCode VARCHAR(100) = '';


	IF OBJECT_ID('tempdb.dbo.#tmpTaxTypeData', 'U') IS NOT NULL
		DROP TABLE #tmpTaxTypeData; 

	CREATE TABLE #tmpTaxTypeData (
		[Id] [BIGINT] IDENTITY NOT NULL,
		[TaxRate] [DECIMAL](18,2) NULL,
		[Code] [VARCHAR](100) NULL,
		[TaxTypeId] [BIGINT] NULL,
	)

	SELECT @WorkOrderId = [WorkOrderId], @TotalWorkOrderCostPlus = [GrandTotal]
	FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId;

	SELECT @CustomerId = [CustomerId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId; 

	SELECT @DepositAmt = SUM(ISNULL([DepositAmount], 0)) FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK) 
	WHERE [WorkOrderId] = @WorkOrderId AND IsVersionIncrease = 0 AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED'

	INSERT INTO #tmpTaxTypeData([TaxRate], [Code], [TaxTypeId])
	SELECT tr.TaxRate, t.Code,ctt.TaxTypeId FROM [dbo].[CustomerTaxTypeRateMapping] ctt WITH(NOLOCK)
	JOIN [dbo].[TaxType] t WITH(NOLOCK) ON ctt.TaxTypeId = t.TaxTypeId
	JOIN [dbo].[TaxRate] tr WITH(NOLOCK) ON ctt.TaxRateId = tr.TaxRateId
	WHERE ctt.CustomerId = @CustomerId AND ctt.IsActive = 1 AND ctt.IsDeleted = 0

	SET @TotalTaxRec = (SELECT MAX(Id) FROM #tmpTaxTypeData);
	IF(ISNULL(@TotalTaxRec , 0) > 0)
	BEGIN
		WHILE(@TotalTaxRec >= @StartTacRec)
		BEGIN

			SELECT @TaxCode = [Code] , @TaxRate = TaxRate FROM #tmpTaxTypeData WHERE Id = @StartTacRec;

			IF(ISNULL(@TaxCode, '') = '')
			BEGIN
				SET @OTHERTAX =  @OTHERTAX + @TaxRate
			END
			ELSE IF(UPPER(ISNULL(@TaxCode, '')) = 'SALES TAX')
			BEGIN
				SET @SALESTAX =  @SALESTAX + @TaxRate
			END

			SET @StartTacRec = @StartTacRec + 1;
		END
	END

	SET @TotalTax = (@TotalWorkOrderCostPlus * @SALESTAX)/ 100 
	SET @OtherTotalTax = (@TotalWorkOrderCostPlus * @OTHERTAX)/ 100 

	SET @GrandTotal = @TotalWorkOrderCostPlus + @TotalTax + @OtherTotalTax;
	PRINT 'GRANDTOTAL : '  + ' - ' + CAST(@GrandTotal AS VARCHAR)

	--SET @UsedDepositAmt = @GrandTotal - @DepositAmt;
	SET @UsedDepositAmt = CASE WHEN ISNULL(@GrandTotal ,0) > ISNULL(@DepositAmt,0) THEN ISNULL(@DepositAmt,0) ELSE ISNULL(@GrandTotal ,0) END
	PRINT 'UsedDepositAmt : '  + ' - ' + CAST(@UsedDepositAmt AS VARCHAR)

	SELECT TOP 1 @WOProFormaBillingInvoicingId = BillingInvoicingId FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK) 
	WHERE [WorkOrderId] = @WorkOrderId AND IsVersionIncrease = 0 AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED'

	IF(ISNULL(@WOProFormaBillingInvoicingId, 0) > 0)
	BEGIN

	--PRINT @WOProFormaBillingInvoicingId
		UPDATE [dbo].[WorkOrderBillingInvoicing]
		SET [UsedDeposit] = ISNULL(UsedDeposit, 0) + @UsedDepositAmt
		WHERE [BillingInvoicingId] = @WOProFormaBillingInvoicingId

	END

 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateUsedDepositForProforma_byId'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@BillingInvoicingId AS VARCHAR(10)), '') + ''      
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName           = @DatabaseName      
                , @AdhocComments          = @AdhocComments                  , @ProcedureParameters = @ProcedureParameters      
                , @ApplicationName        =  @ApplicationName      
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
 END CATCH      
END