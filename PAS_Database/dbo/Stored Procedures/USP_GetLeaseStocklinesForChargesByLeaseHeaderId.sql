/*************************************************************
 ** File:   [USP_GetLeaseStocklinesForChargesByLeaseHeaderId]
 ** Description: Returns the "Item (Stockline)" dropdown source for the Lease
 **              "Charges" tab - every non-deleted LeaseStockline added to the
 **              lease (not restricted to reserved-only, unlike Usage Info),
 **              with PN and Serial Number so the popup can label each option
 **              as "PN / SN".
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/09/2026     Amit Ghediya            Created

exec USP_GetLeaseStocklinesForChargesByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetLeaseStocklinesForChargesByLeaseHeaderId]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT
			LSL.LeaseStocklineId,
			LSL.PN AS PartNumber,
			SLIVE.SerialNumber
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId
		  AND LSL.IsDeleted = 0
		ORDER BY LSL.LeaseStocklineId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseStocklinesForChargesByLeaseHeaderId]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END
