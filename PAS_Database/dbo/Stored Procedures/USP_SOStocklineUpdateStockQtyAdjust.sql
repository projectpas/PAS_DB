
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
    2    06/10/2026   Kishor Makwana		[PN-18238] - Guard: reject QtyOrder below reserved+shipped qty (logged to Appl_ErrorLog, ModuleName SO_QTY_GUARD)
***************************************************************/

CREATE PROCEDURE [dbo].[USP_SOStocklineUpdateStockQtyAdjust]
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

        -- [SO-QTY-GUARD] never allow Qty Ordered below the qty already reserved / shipped on this stockline
        DECLARE @FloorQty DECIMAL(18,6) = 0;

        SELECT @FloorQty = CASE WHEN ISNULL(ToTalReservedQty, 0) > ISNULL(QtyReserved, 0) THEN ISNULL(ToTalReservedQty, 0) ELSE ISNULL(QtyReserved, 0) END
        FROM [dbo].[SalesOrderStockLineV1]
        WHERE SalesOrderStocklineId = @SalesOrderStocklineId
          AND SalesOrderPartId = @SalesOrderPartId;

        IF ISNULL(@NewQtyOrder, 0) < @FloorQty
        BEGIN
            ROLLBACK TRANSACTION;

            BEGIN TRY
                INSERT INTO Appl_ErrorLog ([SQLUserName],[ErrorNumber],[ErrorSeverity],[ErrorState],[ErrorProcedure],[ProcedureParameters],[ErrorLine],[ErrorMessage],DatabaseName,ModuleName,AdhocComments,RolledBackTranCount,SPID,HostName,ClientAppName,ApplicationName)
                VALUES (ISNULL(CONVERT(sysname, CURRENT_USER), ''), 0, 0, 0, 'USP_SOStocklineUpdateStockQtyAdjust',
                    'SalesOrderPartId=' + CAST(ISNULL(@SalesOrderPartId, 0) AS VARCHAR(20)) + ';SalesOrderStocklineId=' + CAST(ISNULL(@SalesOrderStocklineId, 0) AS VARCHAR(20))
                    + ';OldQtyOrder=' + CAST(ISNULL(@OldQtyOrder, 0) AS VARCHAR(20)) + ';NewQtyOrder=' + CAST(ISNULL(@NewQtyOrder, 0) AS VARCHAR(20)) + ';Floor=' + CAST(@FloorQty AS VARCHAR(20)),
                    0, 'Qty adjust below reserved/shipped qty rejected.',
                    DB_NAME(), 'SO_QTY_GUARD', 'SO_QTY_GUARD', 0, @@SPID, HOST_NAME(), SUBSTRING(APP_NAME(), 0, 300), 'PAS');
            END TRY
            BEGIN CATCH
                SET @FloorQty = @FloorQty; -- logging must never break the call
            END CATCH

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