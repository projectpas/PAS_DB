/*********************             
 ** File:   [usp_GetSalesQuoteVerificationResult]             
 ** Author:  Ekta Chnadegra 
 ** Description: This stored procedure is used to GetSalesQuoteVerificationResult
 ** Purpose:           
 ** Date:  15/04/2025        
            
 ** PARAMETERS: @SalesOrderQuoteId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
    1     15/04/2025      Ekta Chandegra        Created  
    2     09/July/2026      RAJESH GAMI        [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
    3     22/July/2026      RAJESH GAMI        [PN-17350] - Removed leftover IsNonStock=0 exclusion filter left over from the PN-17008/PN-17009 transitional phase, now that Non-Stock is fully merged into ItemMaster/Stockline
-- exec dbo.usp_GetSalesQuoteVerificationResult @SalesOrderQuoteId=937
************************/   
CREATE PROCEDURE [dbo].[usp_GetSalesQuoteVerificationResult]
    @SalesOrderQuoteId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;    
	BEGIN TRY   

		DECLARE 
			@SalesOrderQuoteIdOut INT,
			@CustomerReference NVARCHAR(100),
			@QuoteExpireDate DATE,
			@CanConvertToSalesOrder BIT = 0,
			@CanTransferStockline BIT = 0,
			@CanReserveStockline BIT = 0;

			DECLARE @ApprovalStatusId INT;
			DECLARE @ApprovalProcessId INT;
			SELECT @ApprovalStatusId =  ApprovalStatusId FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE Name = 'Approved';
			SELECT @ApprovalProcessId =  ApprovalProcessId FROM [dbo].[ApprovalProcess] WITH(NOLOCK) WHERE Name = 'Approved';

		-- Step 1: Get quote info
		SELECT 
			@SalesOrderQuoteIdOut = SalesOrderQuoteId,
			@CustomerReference = CustomerReference,
			@QuoteExpireDate = QuoteExpireDate
		FROM [dbo].[SalesOrderQuote] WITH(NOLOCK)
		WHERE SalesOrderQuoteId = @SalesOrderQuoteId;

		-- If quote not found
		IF @SalesOrderQuoteIdOut IS NULL
		BEGIN
			SELECT NULL AS CustomerReference, NULL AS SalesOrderQuoteId,
				   0 AS CanConvertToSalesOrder, 0 AS CanTransferStockline, 0 AS CanReserveStockline;
			RETURN;
		END

		-- Step 2: Approved parts
		DECLARE @HasApprovedParts BIT = 0;

		IF EXISTS (
			SELECT 1
			FROM [dbo].[SalesOrderQuotePartV1] sop WITH(NOLOCK)
			INNER JOIN [dbo].[SalesOrderQuoteApproval] soqcapl WITH(NOLOCK) 
				ON sop.SalesOrderQuotePartId = soqcapl.SalesOrderQuotePartId
			WHERE sop.SalesOrderQuoteId = @SalesOrderQuoteId
			  AND sop.IsDeleted = 0
			  AND sop.IsConvertedToSalesOrder = 0
			  AND (
				  soqcapl.CustomerStatusId = @ApprovalStatusId OR soqcapl.ApprovalActionId = @ApprovalProcessId
			  )
		)
		BEGIN
			SET @HasApprovedParts = 1;
		END

		-- Step 3: Can convert to sales order
		IF @QuoteExpireDate >= CAST(GETDATE() AS DATE) AND @HasApprovedParts = 1
		BEGIN
			SET @CanConvertToSalesOrder = 1;
		END

		-- Step 4: Part results for Stockline/Item Master check
		DECLARE @PartTemp TABLE (
			MethodType CHAR(1),
			QuantityAvailable INT,
			QuantityQuoted INT
		);

		INSERT INTO @PartTemp (MethodType, QuantityAvailable, QuantityQuoted)
		SELECT 
			CASE WHEN stk.SalesOrderQuotePartId IS NOT NULL THEN 'S' ELSE 'I' END,
			ISNULL(slr.QuantityAvailable, 0),
			sop.QtyQuoted
		FROM [dbo].[SalesOrderQuotePartV1] sop WITH(NOLOCK)
		LEFT JOIN [dbo].[SalesOrderQuoteApproval] soqcapl WITH(NOLOCK) ON sop.SalesOrderQuotePartId = soqcapl.SalesOrderQuotePartId
		LEFT JOIN [dbo].[SalesOrderQuoteStocklineV1] stk WITH(NOLOCK) ON sop.SalesOrderQuotePartId = stk.SalesOrderQuotePartId
		LEFT JOIN [dbo].[StockLine] slr WITH(NOLOCK) ON stk.StockLineId = slr.StockLineId
		WHERE sop.SalesOrderQuoteId = @SalesOrderQuoteId
		  AND sop.IsDeleted = 0;

		DECLARE @HasStockline BIT = 0;
		DECLARE @HasItemMaster BIT = 0;
		DECLARE @HasInsufficientStock BIT = 0;

		IF EXISTS (SELECT 1 FROM @PartTemp WHERE MethodType = 'S') SET @HasStockline = 1;
		IF EXISTS (SELECT 1 FROM @PartTemp WHERE MethodType = 'I') SET @HasItemMaster = 1;

		IF @HasStockline = 1 AND @HasItemMaster = 0
		BEGIN
			SET @CanTransferStockline = 1;

			IF NOT EXISTS (
				SELECT 1 FROM @PartTemp 
				WHERE MethodType = 'S' AND QuantityQuoted > QuantityAvailable
			)
			BEGIN
				SET @CanReserveStockline = 1;
			END
		END

		-- Final result
		SELECT 
			@CustomerReference AS CustomerReference,
			@SalesOrderQuoteIdOut AS SalesOrderQuoteId,
			@CanConvertToSalesOrder AS CanConvertToSalesOrder,
			@CanTransferStockline AS CanTransferStockline,
			@CanReserveStockline AS CanReserveStockline;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'usp_GetSalesQuoteVerificationResult'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + ''    
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