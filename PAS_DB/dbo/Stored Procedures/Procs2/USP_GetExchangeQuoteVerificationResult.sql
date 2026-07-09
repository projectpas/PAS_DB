 /*************************************************************           
 ** File:   [USP_GetExchangeQuoteVerificationResult]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteVerificationResult
 ** Purpose:         
 ** Date:   07/16/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/16/2025   Ekta Chandegra     Created
    2    09/July/2026   RAJESH GAMI     [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
  EXEC USP_GetExchangeQuoteVerificationResult @ExchangeQuoteId = 10118

************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteVerificationResult]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		-- Declare result variables
		DECLARE 
			@CustomerReference NVARCHAR(100),
			@ExchangeQuoteIdOut BIGINT,
			@TransferFreight BIT = 0,
			@TransferCharges BIT = 0,
			@TransferNotes BIT = 0,
			@TransferMemos BIT = 0,
			@CanConvertToSalesOrder BIT = 0,
			@CanTransferStockline BIT = 0,
			@CanReserveStockline BIT = 0;

		-- Get base quote
		SELECT 
			@CustomerReference = CustomerReference,
			@ExchangeQuoteIdOut = ExchangeQuoteId,
			@TransferNotes = CASE WHEN ISNULL(LTRIM(RTRIM(Notes)), '') <> '' THEN 1 ELSE 0 END,
			@TransferMemos = CASE WHEN ISNULL(LTRIM(RTRIM(Memo)), '') <> '' THEN 1 ELSE 0 END
		FROM [dbo].[ExchangeQuote] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

		IF @ExchangeQuoteIdOut IS NULL
		BEGIN
			-- Return empty if not found
			SELECT 
				NULL AS CustomerReference,
				NULL AS ExchangeQuoteId,
				0 AS TransferFreight,
				0 AS TransferCharges,
				0 AS TransferNotes,
				0 AS TransferMemos,
				0 AS CanConvertToSalesOrder,
				0 AS CanTransferStockline,
				0 AS CanReserveStockline;
			RETURN;
		END

		-- Freight/Charge flags
		DECLARE 
			@FreightFlatRate BIT = 0,
			@ChargeFlatRate BIT = 0,
			@FreightCount INT = 0,
			@ChargeCount INT = 0;

		SELECT 
			@FreightFlatRate = ISNULL(IsFreightFlatRate, 0),
			@ChargeFlatRate = ISNULL(IsChargeFlatRate, 0)
		FROM [dbo].[ExchangeQuote] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId;

		SELECT @FreightCount = COUNT(*) 
		FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsDeleted, 0) = 0;

		SELECT @ChargeCount = COUNT(*) 
		FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsDeleted, 0) = 0;

		SET @TransferFreight = CASE WHEN @FreightFlatRate = 1 OR @FreightCount > 0 THEN 1 ELSE 0 END;
		SET @TransferCharges = CASE WHEN @ChargeFlatRate = 1 OR @ChargeCount > 0 THEN 1 ELSE 0 END;

		-- Can convert logic
		DECLARE @QuoteExpireDate DATE;
		SELECT @QuoteExpireDate = QuoteExpireDate
		FROM [dbo].[ExchangeQuote] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId;

		DECLARE @ApprovalStatusId INT;
		SELECT @ApprovalStatusId = ApprovalStatusId FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE Name = 'Approved';
		PRINT @ApprovalStatusId

		IF EXISTS (
			SELECT 1 
			FROM [dbo].[ExchangeQuotePart] sop WITH(NOLOCK) 
			JOIN [dbo].[ExchangeQuoteApproval] soqcapl WITH(NOLOCK) ON sop.ExchangeQuotePartId = soqcapl.ExchangeQuotePartId
			WHERE sop.ExchangeQuoteId = @ExchangeQuoteId 
			  AND ISNULL(sop.IsDeleted, 0) = 0
			  AND ISNULL(sop.IsConvertedToSalesOrder, 0) = 0
			  AND soqcapl.CustomerStatusId = @ApprovalStatusId
		)
		BEGIN
			IF @QuoteExpireDate >= CAST(GETDATE() AS DATE)
				SET @CanConvertToSalesOrder = 1;
		END

		-- Stockline and ItemMaster check
		DECLARE @HasStockline BIT = 0, @HasItemMaster BIT = 0;

		IF EXISTS (
			SELECT 1
			FROM [dbo].[ExchangeQuotePart] sop WITH(NOLOCK)
			LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
			WHERE sop.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(sop.IsDeleted, 0) = 0
				  AND LOWER(sop.MethodType) = 's'
		)
			SET @HasStockline = 1;

		IF EXISTS (
			SELECT 1
			FROM [dbo].[ExchangeQuotePart] sop WITH(NOLOCK)
			WHERE sop.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(sop.IsDeleted, 0) = 0
				  AND LOWER(sop.MethodType) = 'i'
		)
			SET @HasItemMaster = 1;

		SET @CanTransferStockline = CASE WHEN @HasStockline = 1 AND @HasItemMaster = 0 THEN 1 ELSE 0 END;

		IF @CanTransferStockline = 1
		BEGIN
			IF NOT EXISTS (
				SELECT 1
				FROM [dbo].[ExchangeQuotePart] sop WITH(NOLOCK)
				LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
				WHERE sop.ExchangeQuoteId = @ExchangeQuoteId
				  AND LOWER(sop.MethodType) = 's'
				  AND sop.QtyQuoted > ISNULL(sl.QuantityAvailable, 0)
			)
				SET @CanReserveStockline = 1;
		END

		-- Final Output
		SELECT 
			@CustomerReference AS CustomerReference,
			@ExchangeQuoteIdOut AS ExchangeQuoteId,
			@TransferFreight AS TransferFreight,
			@TransferCharges AS TransferCharges,
			@TransferNotes AS TransferNotes,
			@TransferMemos AS TransferMemos,
			@CanConvertToSalesOrder AS CanConvertToSalesOrder,
			@CanTransferStockline AS CanTransferStockline,
			@CanReserveStockline AS CanReserveStockline;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteVerificationResult'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteId = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END