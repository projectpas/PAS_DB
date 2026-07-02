/*************************************************************           
 ** File:   [USP_BulkCreateReceivingReconciliationDetails]           
 ** Author:   Priyansh Patel
 ** Description: Bulk inserts Receiving Reconciliation Detail rows.
 ** Purpose:         
 ** Date:   30/06/2026   
         
 ** RETURN VALUE: 1 = Success           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author			Change Description            
 ** --   --------      -------			--------------------------------          
    1    30/06/2026    Priyansh Patel	Created - converted from EF AddRange/SaveChanges

--   EXEC [USP_BulkCreateReceivingReconciliationDetails] 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_BulkCreateReceivingReconciliationDetails]
@tbl_ReceivingReconciliationDetails ReceivingReconciliationDetailsBulkType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		DECLARE @InsertedRows TABLE
		(
			[ReceivingReconciliationDetailId] BIGINT,
			[ReceivingReconciliationId]  BIGINT,
			[StocklineId]                BIGINT,
			[StocklineNumber]            VARCHAR(50),
			[ItemMasterId]               BIGINT,
			[PartNumber]                 VARCHAR(100),
			[PartDescription]            VARCHAR(MAX),
			[SerialNumber]               VARCHAR(50),
			[POReference]                VARCHAR(50),
			[POQtyOrder]                 DECIMAL(18,6),
			[ReceivedQty]                DECIMAL(18,6),
			[POUnitCost]                 DECIMAL(18,6),
			[POExtCost]                  DECIMAL(18,6),
			[InvoicedQty]                DECIMAL(18,6),
			[InvoicedUnitCost]           DECIMAL(18,6),
			[InvoicedExtCost]            DECIMAL(18,6),
			[AdjQty]                     DECIMAL(18,6),
			[AdjUnitCost]                DECIMAL(18,6),
			[AdjExtCost]                 DECIMAL(18,6),
			[APNumber]                   VARCHAR(50),
			[PurchaseOrderId]            BIGINT,
			[PurchaseOrderPartRecordId]  BIGINT,
			[IsManual]                   BIT,
			[PackagingId]                INT,
			[Description]                VARCHAR(200),
			[GlAccountId]                BIGINT,
			[Type]                       INT,
			[StockType]                  VARCHAR(50),
			[RemainingRRQty]             DECIMAL(18,6),
			[FreightAdjustment]          DECIMAL(18,6),
			[TaxAdjustment]              DECIMAL(18,6),
			[FreightAdjustmentPerUnit]   DECIMAL(18,6),
			[TaxAdjustmentPerUnit]       DECIMAL(18,6),
			[QtyVariance]                DECIMAL(18,6),
			[PriceVariance]              DECIMAL(18,6),
			[VendorProformaAmount]       DECIMAL(18,6),
			[VendorProformaInvoiceId]    BIGINT
		);

	            INSERT INTO [dbo].[ReceivingReconciliationDetails]
                ([ReceivingReconciliationId],[StocklineId],[StocklineNumber],[ItemMasterId],[PartNumber],[PartDescription],
                [SerialNumber],[POReference],[POQtyOrder],[ReceivedQty],[POUnitCost],[POExtCost],[InvoicedQty],[InvoicedUnitCost],
                [InvoicedExtCost],[AdjQty],[AdjUnitCost],[AdjExtCost],[APNumber],[PurchaseOrderId],[PurchaseOrderPartRecordId],
                [IsManual],[PackagingId],[Description],[GlAccountId],[Type],[StockType],[RemainingRRQty],[FreightAdjustment],
                [TaxAdjustment],[FreightAdjustmentPerUnit],[TaxAdjustmentPerUnit],[QtyVariance],[PriceVariance],
                [VendorProformaAmount],[VendorProformaInvoiceId])
            OUTPUT INSERTED.[ReceivingReconciliationDetailId],INSERTED.[ReceivingReconciliationId],INSERTED.[StocklineId],
                INSERTED.[StocklineNumber],INSERTED.[ItemMasterId],INSERTED.[PartNumber],INSERTED.[PartDescription],
                INSERTED.[SerialNumber],INSERTED.[POReference],INSERTED.[POQtyOrder],INSERTED.[ReceivedQty],INSERTED.[POUnitCost],
                INSERTED.[POExtCost],INSERTED.[InvoicedQty],INSERTED.[InvoicedUnitCost],INSERTED.[InvoicedExtCost],INSERTED.[AdjQty],
                INSERTED.[AdjUnitCost],INSERTED.[AdjExtCost],INSERTED.[APNumber],INSERTED.[PurchaseOrderId],INSERTED.[PurchaseOrderPartRecordId],
                INSERTED.[IsManual],INSERTED.[PackagingId],INSERTED.[Description],INSERTED.[GlAccountId],INSERTED.[Type],INSERTED.[StockType],
                INSERTED.[RemainingRRQty],INSERTED.[FreightAdjustment],INSERTED.[TaxAdjustment],INSERTED.[FreightAdjustmentPerUnit],
                INSERTED.[TaxAdjustmentPerUnit],INSERTED.[QtyVariance],INSERTED.[PriceVariance],INSERTED.[VendorProformaAmount],
                INSERTED.[VendorProformaInvoiceId]
            INTO @InsertedRows
            SELECT
                RRD.[ReceivingReconciliationId],
                RRD.[StocklineId],
                RRD.[StocklineNumber],
                RRD.[ItemMasterId],
                RRD.[PartNumber],
                RRD.[PartDescription],
                RRD.[SerialNumber],
                RRD.[POReference],

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[POQtyOrder],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId)
                    ELSE RRD.[POQtyOrder]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[ReceivedQty],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId)
                    ELSE RRD.[ReceivedQty]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[POUnitCost],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)
                    ELSE RRD.[POUnitCost]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[POExtCost],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)
                    ELSE RRD.[POExtCost]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[InvoicedQty],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId)
                    ELSE RRD.[InvoicedQty]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[InvoicedUnitCost],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)
                    ELSE RRD.[InvoicedUnitCost]
                END,

                --CASE WHEN RRD.[Type] = 1
                --        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                --        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                --        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                --    THEN dbo.fn_ConvertUOM(RRD.[InvoicedExtCost],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)
                --    ELSE RRD.[InvoicedExtCost]
                --END,
                RRD.[InvoicedExtCost],
                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[AdjQty],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId)
                    ELSE RRD.[AdjQty]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[AdjUnitCost],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)
                    ELSE RRD.[AdjUnitCost]
                END,

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[AdjExtCost],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,1,IM.MasterCompanyId)
                    ELSE RRD.[AdjExtCost]
                END,

                RRD.[APNumber],
                RRD.[PurchaseOrderId],
                RRD.[PurchaseOrderPartRecordId],
                ISNULL(RRD.[IsManual],0),
                RRD.[PackagingId],
                RRD.[Description],
                RRD.[GlAccountId],
                RRD.[Type],
                RRD.[StockType],

                CASE WHEN RRD.[Type] = 1
                        AND NULLIF(IM.StockUnitOfMeasure,'') IS NOT NULL
                        AND NULLIF(IM.PurchaseUnitOfMeasure,'') IS NOT NULL
                        AND IM.StockUnitOfMeasure <> IM.PurchaseUnitOfMeasure
                    THEN dbo.fn_ConvertUOM(RRD.[RemainingRRQty],IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId)
                    ELSE RRD.[RemainingRRQty]
                END,

                ISNULL(RRD.[FreightAdjustment],0),
                ISNULL(RRD.[TaxAdjustment],0),
                ISNULL(RRD.[FreightAdjustmentPerUnit],0),
                ISNULL(RRD.[TaxAdjustmentPerUnit],0),
                ISNULL(RRD.[QtyVariance],0),
                ISNULL(RRD.[PriceVariance],0),
                RRD.[VendorProformaAmount],
                RRD.[VendorProformaInvoiceId]
            FROM @tbl_ReceivingReconciliationDetails RRD
            LEFT JOIN ItemMaster IM
            ON IM.ItemMasterId = RRD.ItemMasterId;

		SELECT * FROM @InsertedRows;

	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		--ROLLBACK TRAN;
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_STATE() AS ErrorState,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
			ERROR_MESSAGE() AS ErrorMessage;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_BulkCreateReceivingReconciliationDetails' 
		, @ProcedureParameters VARCHAR(3000)  = '@RowCount = ''' + CAST((SELECT COUNT(1) FROM @tbl_ReceivingReconciliationDetails) AS VARCHAR(20)) + ''''
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