/*************************************************************           
 ** File:   [GetExchangeBillingList]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeBillingList
 ** Purpose:         
 ** Date:   06/09/2025      
          
 ** PARAMETERS: @ExchangeSalesOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/09/2025   Ekta Chandegra     Created
     
 EXEC GetExchangeBillingList @ExchangeSalesOrderId=163
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeBillingList]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
	
		-- 1. Exchange Sales Order
		SELECT TOP 1 *
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;

		-- 2. Schedule Billing
		SELECT DISTINCT
			sqe.ExchangeSalesOrderScheduleBillingId,
			sqe.ExchangeSalesOrderPartId,
			sqe.ExchangeSalesOrderId,
			sqe.ScheduleBillingDate,
			sqe.PeriodicBillingAmount,
			sqe.Cogs,
			sqe.CogsAmount,
			sqe.Qty,
			sqe.BillingTypeId,
			ISNULL(sqe.Notes,'') AS Notes,
			ISNULL(sqe.Memo,'') AS Memo,
			ISNULL(sqe.UnitOfMeasureId, um.UnitOfMeasureId) AS UnitOfMeasureId,
			ISNULL(sqe.BillingAmount, 0) AS BillingAmount,
			CAST(1 AS BIT) AS isEditPart,
			sqe.Type,
			ebt.Description AS BillingType,
			sqe.StatusId,
			ISNULL(essp.ExchangeSalesOrderShippingId, 0) AS ExchangeSalesOrderShippingId,
			sqe.IsPartEntry,
			ISNULL(esbi.InvoiceStatus, '') AS InvoiceStatus,
			ISNULL(esbi.SOBillingInvoicingId, 0) AS SOBillingInvoicingId,
			ISNULL(esbi.InvoiceNo, '-') AS InvoiceNumber,
			ISNULL(esbi.BillingId, 0) AS BillingId,
			sqe.MarkupPercentageId,
			sqe.ExtendedCost
		FROM [dbo].[ExchangeSalesOrderScheduleBilling] sqe WITH(NOLOCK)
		LEFT JOIN [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK) ON sqe.ExchangeSalesOrderPartId = part.ExchangeSalesOrderPartId
		LEFT JOIN [dbo].[ExchangeSalesOrder] eso WITH(NOLOCK) ON part.ExchangeSalesOrderId = eso.ExchangeSalesOrderId
		INNER JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN [dbo].[ExchangeBillingType] ebt WITH(NOLOCK) ON sqe.BillingTypeId = ebt.ExchangeBillingTypeId
		LEFT JOIN [dbo].[ExchangeSalesOrderShipping] essp WITH(NOLOCK) ON sqe.ExchangeSalesOrderId = essp.ExchangeSalesOrderId
		LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] esbii WITH(NOLOCK) ON sqe.ExchangeSalesOrderScheduleBillingId = esbii.ExchangeSalesOrderScheduleBillingId AND ISNULL(esbii.IsDeleted,0) = 0
		LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] esbi WITH(NOLOCK) ON esbii.SOBillingInvoicingId = esbi.SOBillingInvoicingId
		WHERE sqe.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sqe.StatusId != 5
		ORDER BY sqe.ExchangeSalesOrderScheduleBillingId;

		-- 3. Charges
		CREATE TABLE #Results (
			ExchangeSalesOrderChargesId BIGINT NULL,
			ExchangeSalesOrderScheduleBillingId BIGINT,
			ExchangeSalesOrderPartId BIGINT,
			ScheduleBillingDate DATETIME,
			Cogs FLOAT,
			CogsAmount FLOAT,
			BillingTypeId INT,
			Notes NVARCHAR(MAX),
			Memo NVARCHAR(MAX),
			UnitOfMeasureId INT NULL,
			isEditPart BIT,
			BillingAmount FLOAT,
			ExchangeSalesOrderId BIGINT,
			Qty INT,
			PeriodicBillingAmount FLOAT,
			Type NVARCHAR(50),
			StatusId INT,
			MarkupPercentageId INT,
			ExtendedCost FLOAT,
			IsCharge BIT,
			IsChargeFlatRate BIT,
			ExchangeSalesOrderMarginSummaryId BIGINT NULL
		);

		DECLARE @IsChargeFlatRate BIT,
				@ChargeFlatRate FLOAT,
				@IsChargeFlatRateInsert BIT,
				@ChargesBillingTypeId INT;

		SELECT @ChargesBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'Charges'


		SELECT 
			@IsChargeFlatRate = IsChargeFlatRate,
			@ChargeFlatRate = ChargeFlatRate,
			@IsChargeFlatRateInsert = IsChargeFlatRateInsert
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;

		IF (@IsChargeFlatRate = 1 AND @IsChargeFlatRateInsert = 0)
		BEGIN
			INSERT INTO #Results
			VALUES (
				NULL, 0, 0, GETUTCDATE(), 0,
				ISNULL(@ChargeFlatRate, 0), @ChargesBillingTypeId, '', '', NULL, 1,
				ISNULL(@ChargeFlatRate, 0), @ExchangeSalesOrderId, 1,
				ISNULL(@ChargeFlatRate, 0), 'Charge', 1, 0,
				ISNULL(@ChargeFlatRate, 0), 1, 1, NULL
			);
		END
		ELSE
		BEGIN
			DECLARE 
				@ExchangeSalesOrderChargesId BIGINT,
				@ExtendedCost FLOAT,
				@UomId INT,
				@BillingAmount FLOAT,
				@Quantity INT,
				@BillingRate FLOAT,
				@OtherCharges FLOAT,
				@ExchangeSalesOrderMarginSummaryId BIGINT;

			SELECT TOP 1
				@ExchangeSalesOrderChargesId = esc.ExchangeSalesOrderChargesId,
				@ExtendedCost = esc.ExtendedCost,
				@UomId = esc.UomId,
				@BillingAmount = esc.BillingAmount,
				@Quantity = esc.Quantity,
				@BillingRate = esc.BillingRate
			FROM [dbo].[ExchangeSalesOrderCharges] esc WITH(NOLOCK)
			WHERE esc.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esc.IsInsert = 0 AND (esc.IsDeleted IS NULL OR esc.IsDeleted = 0)
			ORDER BY esc.ExchangeSalesOrderChargesId;

			SELECT TOP 1
				@OtherCharges = esm.OtherCharges,
				@ExchangeSalesOrderMarginSummaryId = esm.ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrderMarginSummary] esm WITH(NOLOCK)
			WHERE esm.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esm.OtherCharges > 0 AND (esm.IsChargeInsert IS NULL OR esm.IsChargeInsert = 0)
			ORDER BY esm.ExchangeSalesOrderMarginSummaryId;

			IF (@OtherCharges IS NOT NULL AND (@ExchangeSalesOrderChargesId IS NOT NULL))
			BEGIN
				INSERT INTO #Results
				VALUES (
					NULL, 0, 0, GETUTCDATE(), 0,
					ISNULL(@ExtendedCost, 0), @ChargesBillingTypeId, '', '', @UomId, 1,
					ISNULL(@OtherCharges, 0), @ExchangeSalesOrderId, 1,
					ISNULL(@OtherCharges, 0), 'Charge', 1, 0,
					ISNULL(@OtherCharges, 0), 1, 0, @ExchangeSalesOrderMarginSummaryId
				);
			END
			ELSE
			BEGIN
				INSERT INTO #Results
				SELECT
					esc.ExchangeSalesOrderChargesId,
					0,
					0,
					GETUTCDATE(),
					0,
					esc.ExtendedCost,
					@ChargesBillingTypeId,
					'',
					'',
					esc.UomId,
					1,
					esc.BillingAmount,
					esc.ExchangeSalesOrderId,
					esc.Quantity,
					esc.BillingRate,
					'Charge',
					1,
					0,
					esc.BillingAmount,
					0,
					0,
					NULL
				FROM [dbo].[ExchangeSalesOrderCharges] esc WITH(NOLOCK)
				WHERE esc.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esc.IsInsert = 0 AND (esc.IsDeleted IS NULL OR esc.IsDeleted = 0);
			END
		END

		SELECT * FROM #Results ORDER BY ExchangeSalesOrderChargesId;

		DROP TABLE #Results;

		-- 4. Freight Billing
		CREATE TABLE #FreightResults (
			ExchangeSalesOrderFreightId BIGINT NULL,
			ExchangeSalesOrderScheduleBillingId BIGINT,
			ExchangeSalesOrderPartId BIGINT,
			ScheduleBillingDate DATETIME,
			Cogs FLOAT,
			CogsAmount FLOAT,
			BillingTypeId INT,
			Notes NVARCHAR(MAX),
			Memo NVARCHAR(MAX),
			isEditPart BIT,
			Qty INT,
			UnitOfMeasureId INT NULL,
			BillingAmount FLOAT,
			ExchangeSalesOrderId BIGINT,
			PeriodicBillingAmount FLOAT,
			Type NVARCHAR(50),
			StatusId INT,
			MarkupPercentageId INT,
			ExtendedCost FLOAT,
			IsFreight BIT,
			ExchangeSalesOrderMarginSummaryId BIGINT NULL,
			IsFreightFlatRate BIT
		);

		DECLARE 
			@IsFreightFlatRate BIT,
			@FreightFlatRate FLOAT,
			@IsFreightFlatRateInsert BIT,
			@FreightsBillingTypeId INT;

		SELECT @FreightsBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'FREIGHT'


		SELECT 
			@IsFreightFlatRate = IsFreightFlatRate,
			@FreightFlatRate = FreightFlatRate,
			@IsFreightFlatRateInsert = IsFreightFlatRateInsert
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;

		IF (@IsFreightFlatRate = 1 AND @IsFreightFlatRateInsert = 0)
		BEGIN
			INSERT INTO #FreightResults
			VALUES (
				NULL, 0, 0, GETUTCDATE(), 0,
				ISNULL(@FreightFlatRate, 0), @FreightsBillingTypeId, '', '', 1, 1,
				NULL,
				ISNULL(@FreightFlatRate, 0),
				@ExchangeSalesOrderId,
				ISNULL(@FreightFlatRate, 0),
				'Freight',
				1,
				0,
				ISNULL(@FreightFlatRate, 0),
				1,
				NULL,
				1
			);
		END
		ELSE
		BEGIN
			DECLARE 
				@ExchangeSalesOrderFreightId BIGINT,
				@FreightAmount FLOAT,
				@Amount FLOAT,
				@BillingMethodId INT,
				@UOM INT,
				@ExchangeSOMarginSummaryId BIGINT;

			SELECT TOP 1
				@ExchangeSalesOrderFreightId = esf.ExchangeSalesOrderFreightId,
				@Amount = esf.Amount,
				@BillingMethodId = esf.BillingMethodId,
				@UOM = esf.UOMId
			FROM [dbo].[ExchangeSalesOrderFreight] esf WITH(NOLOCK)
			WHERE esf.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esf.IsInsert = 0 AND (esf.IsDeleted IS NULL OR esf.IsDeleted = 0);

			SELECT TOP 1
				@FreightAmount = esm.FreightAmount,
				@ExchangeSOMarginSummaryId = esm.ExchangeSalesOrderMarginSummaryId
			FROM [dbo].[ExchangeSalesOrderMarginSummary] esm WITH(NOLOCK)
			WHERE esm.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esm.FreightAmount > 0 AND esm.IsFreightInsert = 1;

			IF (@FreightAmount IS NOT NULL AND 
			   (@BillingMethodId = @FreightsBillingTypeId OR @ExchangeSalesOrderFreightId IS NOT NULL))
			BEGIN
				INSERT INTO #FreightResults
				VALUES (
					NULL, 0, 0, GETUTCDATE(), 0,
					ISNULL(@Amount, 0), @FreightsBillingTypeId, '', '', 1, 1,
					@UOM,
					ISNULL(@FreightAmount, 0),
					@ExchangeSalesOrderId,
					ISNULL(@FreightAmount, 0),
					'Freight',
					1,
					0,
					ISNULL(@FreightAmount, 0),
					1,
					@ExchangeSOMarginSummaryId,
					0
				);
			END
			ELSE
			BEGIN
				INSERT INTO #FreightResults
				SELECT 
					esf.ExchangeSalesOrderFreightId,
					0,
					0,
					GETUTCDATE(),
					0,
					esf.Amount,
					@FreightsBillingTypeId,
					'',
					'',
					1,
					1,
					esf.UOMId,
					esf.BillingAmount,
					esf.ExchangeSalesOrderId,
					esf.BillingAmount,
					'Freight',
					1,
					0,
					esf.BillingAmount,
					0,
					NULL,
					0
				FROM [dbo].[ExchangeSalesOrderFreight] esf WITH(NOLOCK)
				WHERE esf.ExchangeSalesOrderId = @ExchangeSalesOrderId
				  AND esf.IsInsert = 0
				  AND (esf.IsDeleted IS NULL OR esf.IsDeleted = 0)
				  AND esf.BillingMethodId != @FreightsBillingTypeId;
			END
		END

		SELECT * FROM #FreightResults ORDER BY ExchangeSalesOrderFreightId;

		DROP TABLE #FreightResults;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeBillingList'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100))
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