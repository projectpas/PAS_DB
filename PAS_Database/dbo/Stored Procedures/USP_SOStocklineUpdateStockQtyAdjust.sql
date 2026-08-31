
/***************************************************************  
 ** File:   [USP_SOStocklineUpdateStockQtyAdjust]             
 ** Author:   Kishor Makwana
 ** Description: This stored procedure is used update SalesOrderStockLineV1 and SalesOrderPartV1 Order Qty.
 ** Purpose:
 ** Date:   26/Aug/2026

 ** Change History
 **************************************************************
 ** PR   Date         Author  			    Change Description
 ** --   --------     -------			    --------------------------------
    1    26/Aug/2026   Kishor Makwana		Created [PN-17734] - ported from Sprint 67, adapted to DECIMAL(18,6) qty for UOM fractional quantities

***************************************************************/

CREATE PROCEDURE dbo.USP_SOStocklineUpdateStockQtyAdjust
    @SalesOrderPartId BIGINT,
    @SalesOrderStocklineId BIGINT,
    @OldQtyOrder DECIMAL(18,6),
    @NewQtyOrder DECIMAL(18,6)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentQtyOrder DECIMAL(18,6);

        SELECT @CurrentQtyOrder = ISNULL(QtyOrder, 0)
        FROM [dbo].[SalesOrderStockLineV1]
        WHERE SalesOrderStocklineId = @SalesOrderStocklineId
          AND SalesOrderPartId = @SalesOrderPartId;

        IF @CurrentQtyOrder IS NULL
        BEGIN
            -- stockline not found for this part
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @CurrentQtyOrder <> @OldQtyOrder
        BEGIN
            -- stale data - stockline's QtyOrder changed since the popup was opened, don't overwrite it
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE [dbo].[SalesOrderStockLineV1]
        SET QtyOrder = @NewQtyOrder
        WHERE SalesOrderStocklineId = @SalesOrderStocklineId
          AND SalesOrderPartId = @SalesOrderPartId;

        DECLARE @TotalQtyOrder DECIMAL(18,6);

        SELECT @TotalQtyOrder = SUM(ISNULL(QtyOrder, 0))
        FROM [dbo].[SalesOrderStockLineV1]
        WHERE SalesOrderPartId = @SalesOrderPartId;

        UPDATE [dbo].[SalesOrderPartV1]
        SET QtyOrder = @TotalQtyOrder,
            QtyRequested = @TotalQtyOrder
        WHERE SalesOrderPartId = @SalesOrderPartId
          AND QtyRequested < @TotalQtyOrder;

        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_SOStocklineUpdateStockQtyAdjust',
            @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
