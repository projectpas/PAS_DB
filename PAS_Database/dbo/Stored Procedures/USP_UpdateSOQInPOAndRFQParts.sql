/*************************************************************
** File:              [USP_UpdateSOQInPOAndRFQParts]
** Author:            Ayushi Patel
** Description:       Updates SalesOrderQuoteId & SalesOrderQuoteNumber 
**                    in PurchaseOrderPart and VendorRFQPurchaseOrderPart tables
** Purpose:           To sync new Sales Order Quote version with PO/RFQ PO parts
** Date:              17-12-2025
**
** PARAMETERS:
** @OldSalesOrderQuoteId   BIGINT
** @NewSalesOrderQuoteId   BIGINT
** @SalesOrderQuoteNumber  VARCHAR(50)
** @UpdatedBy              VARCHAR(50)
** @MasterCompanyId        INT
**
** RETURN VALUE:
**************************************************************
** Change History
**************************************************************
** PR   Date         Author            Change Description
** --   --------     -------           ----------------------------
** 1    17-12-2025   Ayushi Patel      Created
************************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateSOQInPOAndRFQParts]
    @OldSalesOrderQuoteId BIGINT = 0,
    @NewSalesOrderQuoteId BIGINT = 0,
    @SalesOrderQuoteNumber VARCHAR(50) = NULL,
    @MasterCompanyId INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        UPDATE dbo.PurchaseOrderPart 
        SET 
            SalesOrderQuoteId = @NewSalesOrderQuoteId,
            SalesOrderQuoteNumber = @SalesOrderQuoteNumber,
            UpdatedDate = GETUTCDATE()
        WHERE 
            SalesOrderQuoteId = @OldSalesOrderQuoteId
            AND MasterCompanyId = @MasterCompanyId;

        UPDATE dbo.VendorRFQPurchaseOrderPart 
        SET 
            SalesOrderQuoteId = @NewSalesOrderQuoteId,
            SalesOrderQuoteNumber = @SalesOrderQuoteNumber,
            UpdatedDate = GETUTCDATE()
        WHERE 
            SalesOrderQuoteId = @OldSalesOrderQuoteId
            AND MasterCompanyId = @MasterCompanyId;

    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_UpdateSOQInPOAndRFQParts',
                @ProcedureParameters VARCHAR(3000),
                @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
            '@OldSalesOrderQuoteId = ' + CAST(ISNULL(@OldSalesOrderQuoteId,0) AS VARCHAR(50)) + ', ' +
            '@NewSalesOrderQuoteId = ' + CAST(ISNULL(@NewSalesOrderQuoteId,0) AS VARCHAR(50)) + ', ' +
            '@SalesOrderQuoteNumber = ' + ISNULL(@SalesOrderQuoteNumber,'') + ', ' +
            '@MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId,0) AS VARCHAR(50));

        EXEC spLogException 
             @DatabaseName        = @DatabaseName,
             @AdhocComments       = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName     = @ApplicationName,
             @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occurred in database. Please share the error number: %d', 
            16, 1, @ErrorLogID
        );

        RETURN(1);
    END CATCH
END