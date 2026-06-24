
/*************************************************************           
 ** File:   [USP_UpdateStocklineUOMByItemMasterId]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Update Stockline UOM By ItemMasterId
 ** Date:   16/June/2026
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author  			Change Description            
 ** --   --------			-------				---------------------------     
    1    16/June/2026		Rajesh Gami			Created [PN-16878]
**************************************************************
 EXEC USP_UpdateStocklineUOMByItemMasterId 97800,1,3,5,125,1,1,1,3,125,125,0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateStocklineUOMByItemMasterId]
    @ItemMasterId             BIGINT,
    @MasterCompanyId          INT,
    @PurchaseUnitOfMeasureId  BIGINT,
    @StockUnitOfMeasureId     BIGINT,
    @ConsumeUnitOfMeasureId   BIGINT,
    @IsPOUOMEdited            BIT,
    @IsStockUOMEdited         BIT,
    @IsConsumeUOMEdited       BIT,
    @ExistingPOUOMId          BIGINT,
    @ExistingStockUOMId       BIGINT,
    @ExistingConsumeUOMId     BIGINT,
    @IsStkTimeLife            BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PurchaseUOM    VARCHAR(250),
                @StockUOM       VARCHAR(250),
                @ConsumeUOM     VARCHAR(250),
                @OldPurchaseUOM VARCHAR(250),
                @OldStockUOM    VARCHAR(250),
                @OldConsumeUOM  VARCHAR(250);

        SELECT @PurchaseUOM    = ShortName FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE UnitOfMeasureId = @PurchaseUnitOfMeasureId;
        SELECT @StockUOM       = ShortName FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE UnitOfMeasureId = @StockUnitOfMeasureId;
        SELECT @ConsumeUOM     = ShortName FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE UnitOfMeasureId = @ConsumeUnitOfMeasureId;
        SELECT @OldPurchaseUOM = ShortName FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE UnitOfMeasureId = @ExistingPOUOMId;
        SELECT @OldStockUOM    = ShortName FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE UnitOfMeasureId = @ExistingStockUOMId;
        SELECT @OldConsumeUOM  = ShortName FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE UnitOfMeasureId = @ExistingConsumeUOMId;

        DECLARE @DefaultPOUOMQtyValue       DECIMAL(18,6) = CAST(CASE WHEN @IsPOUOMEdited      = 1 THEN dbo.fn_ConvertUOM(1, @OldPurchaseUOM, @PurchaseUOM, 0, @MasterCompanyId) ELSE 1 END AS DECIMAL(18,6));
        DECLARE @DefaultPOUOMCostValue      DECIMAL(18,6) = CAST(CASE WHEN @IsPOUOMEdited      = 1 THEN dbo.fn_ConvertUOM(1, @OldPurchaseUOM, @PurchaseUOM, 1, @MasterCompanyId) ELSE 1 END AS DECIMAL(18,6));
        DECLARE @DefaultStockUOMQtyValue    DECIMAL(18,6) = CAST(CASE WHEN @IsStockUOMEdited   = 1 THEN dbo.fn_ConvertUOM(1, @OldStockUOM,    @StockUOM,   0, @MasterCompanyId) ELSE 1 END AS DECIMAL(18,6));
        DECLARE @DefaultStockUOMCostValue   DECIMAL(18,6) = CAST(CASE WHEN @IsStockUOMEdited   = 1 THEN dbo.fn_ConvertUOM(1, @OldStockUOM,    @StockUOM,   1, @MasterCompanyId) ELSE 1 END AS DECIMAL(18,6));
        DECLARE @DefaultConsumeUOMQtyValue  DECIMAL(18,6) = CAST(CASE WHEN @IsConsumeUOMEdited = 1 THEN dbo.fn_ConvertUOM(1, @OldConsumeUOM,  @ConsumeUOM, 0, @MasterCompanyId) ELSE 1 END AS DECIMAL(18,6));
        DECLARE @DefaultConsumeUOMCostValue DECIMAL(18,6) = CAST(CASE WHEN @IsConsumeUOMEdited = 1 THEN dbo.fn_ConvertUOM(1, @OldConsumeUOM,  @ConsumeUOM, 1, @MasterCompanyId) ELSE 1 END AS DECIMAL(18,6));

        -- -----------------------------------------------------------------------
        -- Step 1: Update purchase price fields
        -- -----------------------------------------------------------------------
        UPDATE ItemMasterPurchaseSale
        SET
            PP_VendorListPrice    = CASE WHEN @IsPOUOMEdited = 1
                                        THEN CAST(PP_VendorListPrice * @DefaultPOUOMCostValue AS DECIMAL(28,6))
                                        ELSE PP_VendorListPrice END,

            PP_PurchaseDiscAmount = CASE WHEN @IsPOUOMEdited = 1
                                        THEN CAST(
                                                (CAST(PP_VendorListPrice * @DefaultPOUOMCostValue AS DECIMAL(28,6))
                                                 * PP_PurchaseDiscPercValue) / 100.0
                                             AS DECIMAL(28,6))
                                        ELSE PP_PurchaseDiscAmount END,

            PP_UnitPurchasePrice  = CASE WHEN @IsPOUOMEdited = 1
                                        THEN CAST(
                                                CAST(PP_VendorListPrice * @DefaultPOUOMCostValue AS DECIMAL(28,6))
                                                - CAST(
                                                    (CAST(PP_VendorListPrice * @DefaultPOUOMCostValue AS DECIMAL(28,6))
                                                     * PP_PurchaseDiscPercValue) / 100.0
                                                  AS DECIMAL(28,6))
                                             AS DECIMAL(28,6))
                                        ELSE PP_UnitPurchasePrice END,

            PP_UOMId       = CASE WHEN @IsPOUOMEdited      = 1 THEN @PurchaseUnitOfMeasureId  ELSE PP_UOMId      END,
            PP_UOMName     = CASE WHEN @IsPOUOMEdited      = 1 THEN @PurchaseUOM              ELSE PP_UOMName    END,
            SP_FSP_UOMName = CASE WHEN @IsConsumeUOMEdited = 1 THEN @ConsumeUOM              ELSE SP_FSP_UOMName END,
            SP_FSP_UOMId   = CASE WHEN @IsConsumeUOMEdited = 1 THEN @ConsumeUnitOfMeasureId  ELSE SP_FSP_UOMId   END
        WHERE ITEMMASTERId = @ItemMasterId;

        -- -----------------------------------------------------------------------
        -- Step 2: Update sale price fields
        -- -----------------------------------------------------------------------
        UPDATE ItemMasterPurchaseSale
        SET
            SP_CalSPByPP_MarkUpAmount =
                CASE
                    WHEN ISNULL(SP_FSP_FlatPriceAmount, 0) > 0 THEN 0
                    ELSE
                        CAST(
                            (CASE
                                WHEN ISNULL(SP_CalSPByPP_MarkUpPercOnListPrice, 0) > 0
                                    THEN CAST(
                                             ISNULL(PP_UnitPurchasePrice, 0)
                                             * (SELECT TOP 1 PercentValue FROM DBO.[PERCENT] WITH(NOLOCK)
                                                WHERE PercentId = SP_CalSPByPP_MarkUpPercOnListPrice)
                                             / 100.0
                                         AS DECIMAL(28,6))
                                ELSE CAST(ISNULL(PP_UnitPurchasePrice, 0) AS DECIMAL(28,6))
                            END)
                            * @DefaultConsumeUOMCostValue
                        AS DECIMAL(28,6))
                END,

            SP_CalSPByPP_UnitSalePrice =
                CASE
                    WHEN ISNULL(SP_FSP_FlatPriceAmount, 0) > 0 THEN SP_FSP_FlatPriceAmount
                    ELSE
                        CAST(
                            CAST(ISNULL(PP_UnitPurchasePrice, 0) * @DefaultConsumeUOMCostValue AS DECIMAL(28,6))
                            +
                            CAST(
                                (CASE
                                    WHEN ISNULL(SP_CalSPByPP_MarkUpPercOnListPrice, 0) > 0
                                        THEN CAST(
                                                 ISNULL(PP_UnitPurchasePrice, 0)
                                                 * (SELECT TOP 1 PercentValue FROM DBO.[PERCENT] WITH(NOLOCK)
                                                    WHERE PercentId = SP_CalSPByPP_MarkUpPercOnListPrice)
                                                 / 100.0
                                             AS DECIMAL(28,6))
                                    ELSE CAST(ISNULL(PP_UnitPurchasePrice, 0) AS DECIMAL(28,6))
                                END)
                                * @DefaultConsumeUOMCostValue
                            AS DECIMAL(28,6))
                        AS DECIMAL(28,6))
                END
        WHERE ITEMMASTERId = @ItemMasterId;

         -----------------------------------------------------------------------
         --Step 3: Update Stockline
         -----------------------------------------------------------------------
        UPDATE [dbo].[Stockline]
        SET
            [PurchaseUnitOfMeasureId] = @PurchaseUnitOfMeasureId,
            [StockUnitOfMeasureId]    = @StockUnitOfMeasureId,
            [ConsumeUnitOfMeasureId]  = @ConsumeUnitOfMeasureId,
            [UnitOfMeasure]           = @PurchaseUOM,
            [StockUnitOfMeasure]      = @StockUOM,
            [ConsumeUnitOfMeasure]    = @ConsumeUOM,
            [IsStkTimeLife]           = @IsStkTimeLife,
            [UpdatedDate]             = GETUTCDATE(),

            Quantity          = CAST(@DefaultStockUOMQtyValue  * Quantity          AS DECIMAL(28,6)),
            QuantityOnHand    = CAST(@DefaultStockUOMQtyValue  * QuantityOnHand    AS DECIMAL(28,6)),
            QuantityReserved  = QuantityReserved,
            QuantityIssued    = QuantityIssued,
            QuantityAvailable = CAST(@DefaultStockUOMQtyValue  * QuantityAvailable AS DECIMAL(28,6)),

            UnitCost              = CAST(UnitCost              * @DefaultStockUOMCostValue   AS DECIMAL(28,6)),
            PurchaseOrderUnitCost = CAST(PurchaseOrderUnitCost * @DefaultStockUOMCostValue   AS DECIMAL(28,6)),
            RepairOrderUnitCost   = CAST(RepairOrderUnitCost   * @DefaultStockUOMCostValue   AS DECIMAL(28,6)),
            PoPartUnitCost        = CAST(PoPartUnitCost        * @DefaultPOUOMCostValue      AS DECIMAL(28,6)),
            UnitSalesPrice        = CAST(UnitSalesPrice        * @DefaultConsumeUOMCostValue AS DECIMAL(28,6)),

            PurchaseOrderExtendedCost =
                CAST(
                    CAST(@DefaultStockUOMQtyValue  * QuantityOnHand           AS DECIMAL(28,6))
                    * CAST(PurchaseOrderUnitCost   * @DefaultStockUOMCostValue AS DECIMAL(28,6))
                AS DECIMAL(28,6))

        WHERE
            ItemMasterId              = @ItemMasterId
            AND MasterCompanyId       = @MasterCompanyId
            AND ISNULL(isDeleted,  0) = 0
            AND ISNULL(isActive,   0) = 1
            AND ISNULL(QuantityOnHand,   0) > 0
            AND ISNULL(QuantityReserved, 0) = 0
            AND ISNULL(QuantityIssued,   0) = 0;


		 --SELECT 
   --         [PurchaseUnitOfMeasureId] = @PurchaseUnitOfMeasureId,
   --         [StockUnitOfMeasureId]    = @StockUnitOfMeasureId,
   --         [ConsumeUnitOfMeasureId]  = @ConsumeUnitOfMeasureId,
   --         [UnitOfMeasure]           = @PurchaseUOM,
   --         [StockUnitOfMeasure]      = @StockUOM,
   --         [ConsumeUnitOfMeasure]    = @ConsumeUOM,
   --         [IsStkTimeLife]           = @IsStkTimeLife,
   --         [UpdatedDate]             = GETUTCDATE(),

   --         Quantity          = CAST(@DefaultStockUOMQtyValue  * Quantity          AS DECIMAL(28,6)),
   --         QuantityOnHand    = CAST(@DefaultStockUOMQtyValue  * QuantityOnHand    AS DECIMAL(28,6)),
   --         QuantityReserved  = QuantityReserved,
   --         QuantityIssued    = QuantityIssued,
   --         QuantityAvailable = CAST(@DefaultStockUOMQtyValue  * QuantityAvailable AS DECIMAL(28,6)),

   --         UnitCost              = CAST(UnitCost              * @DefaultStockUOMCostValue   AS DECIMAL(28,6)),
   --         PurchaseOrderUnitCost = CAST(PurchaseOrderUnitCost * @DefaultStockUOMCostValue   AS DECIMAL(28,6)),
   --         RepairOrderUnitCost   = CAST(RepairOrderUnitCost   * @DefaultStockUOMCostValue   AS DECIMAL(28,6)),
   --         PoPartUnitCost        = CAST(PoPartUnitCost        * @DefaultPOUOMCostValue      AS DECIMAL(28,6)),
   --         UnitSalesPrice        = CAST(UnitSalesPrice        * @DefaultConsumeUOMCostValue AS DECIMAL(28,6)),

   --         PurchaseOrderExtendedCost =
   --             CAST(
   --                 CAST(@DefaultStockUOMQtyValue  * QuantityOnHand           AS DECIMAL(28,6))
   --                 * CAST(PurchaseOrderUnitCost   * @DefaultStockUOMCostValue AS DECIMAL(28,6))
   --             AS DECIMAL(28,6))

			--	FROM Stockline
   --     WHERE
   --         ItemMasterId              = @ItemMasterId
   --         AND MasterCompanyId       = @MasterCompanyId
   --         AND ISNULL(isDeleted,  0) = 0
   --         AND ISNULL(isActive,   0) = 1
   --         AND ISNULL(QuantityOnHand,   0) > 0
   --         AND ISNULL(QuantityReserved, 0) = 0
   --         AND ISNULL(QuantityIssued,   0) = 0;


        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER()    AS ErrorNumber,
            ERROR_STATE()     AS ErrorState,
            ERROR_SEVERITY()  AS ErrorSeverity,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE()      AS ErrorLine,
            ERROR_MESSAGE()   AS ErrorMessage;

        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID          INT,
                @DatabaseName        VARCHAR(100)  = DB_NAME(),
                @AdhocComments       VARCHAR(150)  = '[USP_UpdateStocklineUOMByItemMasterId]',
                @ProcedureParameters VARCHAR(3000) = '@ItemMasterId = '''    + CAST(ISNULL(@ItemMasterId,    '') AS VARCHAR(100))
                                                   + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)),
                @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END