/*************************************************************           
 ** File:   [USP_UpdateSOQCostDetails]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Recalculate SOQ Total Cost    
 ** Purpose:         
 ** Date:   07/25/2024
          
 ** PARAMETERS:
 
 ** RETURN VALUE:

 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/25/2024   Vishal Suthar Created
     
 EXECUTE USP_UpdateSOQCostDetails 766, 'Admin User', 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateSOQCostDetails]
(
	@SalesOrderQuoteId BIGINT = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@MasterCompanyId INT = NULL
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF OBJECT_ID(N'tempdb..#SOQPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOQPartCostDetails
				END

				CREATE TABLE #SOQPartCostDetails (
					ID bigint NOT NULL IDENTITY,
					[SalesOrderQuoteId] [bigint] NOT NULL,
					[SalesOrderQuotePartId] [bigint] NOT NULL,
					[NetSaleAmount] [decimal](18, 4) NULL,
					[Charges] [decimal](18, 4) NULL,
					[Freights] [decimal](18, 4) NULL					
				)

				DECLARE @MasterLoopID AS INT;
				DECLARE @SalesOrderQuotePartId AS BIGINT;
				DECLARE @NetSaleAmount_S AS [decimal](18, 4);
				DECLARE @Freight_S AS [decimal](18, 4);
				DECLARE @Charges_S AS [decimal](18, 4);

				INSERT INTO #SOQPartCostDetails ([SalesOrderQuoteId], [SalesOrderQuotePartId], [NetSaleAmount], [Charges], [Freights])
				SELECT [SalesOrderQuoteId], [SalesOrderQuotePartId], [NetSaleAmount], [MiscCharges], [Freight]
				FROM [DBO].[SalesOrderQuotePartCost] WITH (NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId;

				DECLARE @IsFlatRateAdded_Charges BIT = 0;
				DECLARE @IsFlatRateAdded_Freight BIT = 0;

				IF EXISTS (SELECT * FROM [DBO].[SalesOrderQuoteFreight] F WITH (NOLOCK) WHERE F.SalesOrderQuoteId = @SalesOrderQuoteId)
				BEGIN
					SELECT @Freight_S = SUM(ISNULL(BillingAmount, 0)) FROM [DBO].[SalesOrderQuoteFreight] F WITH (NOLOCK) WHERE F.SalesOrderQuoteId = @SalesOrderQuoteId;
					SET @IsFlatRateAdded_Freight = (CASE WHEN @Freight_S > 0 THEN 1 ELSE 0 END);
				END

				IF EXISTS (SELECT * FROM [DBO].[SalesOrderQuoteCharges] C WITH (NOLOCK) WHERE C.SalesOrderQuoteId = @SalesOrderQuoteId)
				BEGIN
					SELECT @Charges_S = SUM(ISNULL(BillingAmount, 0)) FROM [DBO].[SalesOrderQuoteCharges] C WITH (NOLOCK) WHERE C.SalesOrderQuoteId = @SalesOrderQuoteId;
					SET @IsFlatRateAdded_Charges = (CASE WHEN @Charges_S > 0 THEN 1 ELSE 0 END);
				END

				SELECT @MasterLoopID = MAX(ID) FROM #SOQPartCostDetails;
				WHILE (@MasterLoopID > 0)
				BEGIN
					SELECT 
					@NetSaleAmount_S = ISNULL(@NetSaleAmount_S, 0) + NetSaleAmount,
					@Freight_S = CASE WHEN @IsFlatRateAdded_Freight = 1 THEN ISNULL(@Freight_S, 0) ELSE (ISNULL(@Freight_S, 0) + Freights) END,
					@Charges_S = CASE WHEN @IsFlatRateAdded_Charges = 1 THEN ISNULL(@Charges_S, 0) ELSE ISNULL(@Charges_S, 0) + Charges END
					FROM #SOQPartCostDetails WHERE ID  = @MasterLoopID

					SET @MasterLoopID = @MasterLoopID - 1;
				END
				
				DECLARE @AppModuleId bigint = 0;
				DECLARE @CustomerId bigint = 0;
				DECLARE @SalesTax AS [decimal](18, 4);
				DECLARE @OtherTax AS [decimal](18, 4);

				IF ((SELECT COUNT(1) FROM [DBO].[SalesOrderQuoteCost] SOQC WITH(NOLOCK) WHERE SOQC.SalesOrderQuoteId = @SalesOrderQuoteId) > 0)
				BEGIN
					DECLARE @SalesTaxAmt AS [decimal](18, 4);
					DECLARE @OtherTaxAmt AS [decimal](18, 4); 

					SET @SalesTaxAmt = ((@NetSaleAmount_S) * @SalesTax) / 100
					SET @OtherTaxAmt = ((@NetSaleAmount_S) * @OtherTax) / 100

					UPDATE [DBO].[SalesOrderQuoteCost]
					SET 
					SubTotal = @NetSaleAmount_S,
					Freight = @Freight_S,
					MiscCharges = @Charges_S,
					SalesTax = @SalesTaxAmt,
					OtherTax = @OtherTaxAmt,
					NetTotal = (ISNULL(@NetSaleAmount_S, 0) + ISNULL(@Freight_S, 0) + ISNULL(@Charges_S, 0) + ISNULL(@SalesTaxAmt, 0) + ISNULL(@OtherTaxAmt, 0))
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId
				END
				ELSE
				BEGIN
					INSERT INTO [DBO].[SalesOrderQuoteCost] ([SalesOrderQuoteId], [SubTotal], [SalesTax], [OtherTax], [MiscCharges], [Freight], [NetTotal], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
					VALUES
					(@SalesOrderQuoteId, ISNULL(@NetSaleAmount_S, 0), 0, 0, ISNULL(@Charges_S, 0), ISNULL(@Freight_S, 0), (ISNULL(@NetSaleAmount_S, 0) + ISNULL(@Freight_S, 0) + ISNULL(@Charges_S, 0)), @MasterCompanyId, @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0)
				END

				IF OBJECT_ID(N'tempdb..#SOQPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOQPartCostDetails
				END
			END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments varchar(150) = 'USP_UpdateSOQCostDetails',
        @ProcedureParameters varchar(3000) = '@SalesOrderQuoteId = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100))
        + '@Parameter2 = ''' + CAST(ISNULL(@SalesOrderQuotePartId, '') AS varchar(100))
        + '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
        + '@Parameter4 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName,
						@AdhocComments = @AdhocComments,
						@ProcedureParameters = @ProcedureParameters,
						@ApplicationName = @ApplicationName,
						@ErrorLogID = @ErrorLogID OUTPUT;
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1);
	END CATCH
END