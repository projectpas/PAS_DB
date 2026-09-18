/*************************************************************
 ** File:   [USP_GetLeaseChargesByLeaseHeaderId]
 ** Description: Returns the Lease "Charges" tab's list - every non-deleted
 **              LeaseCharges row for the lease, joined to the shared Charge
 **              (Charge Type) master (-> GLAccount), Vendor, UnitOfMeasure,
 **              and LeaseStockline (-> live Stockline for Serial Number) so
 **              the grid can show "Item (Stockline)" as PN/SN together.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/09/2026     Amit Ghediya            Created

exec USP_GetLeaseChargesByLeaseHeaderId @LeaseHeaderId=1
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetLeaseChargesByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@IsDeleted BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT
			LC.LeaseChargesId,
			LC.LeaseStocklineId,
			LSL.PN AS PartNumber,
			SLIVE.SerialNumber,
			LC.ReportedDate,
			LC.ChargesTypeId,
			CH.ChargeType,
			ISNULL(GL.AccountName, '') AS GLAccountName,
			LC.Description,
			LC.UOMId,
			ISNULL(UOM.ShortName, '') AS UOM,
			LC.Quantity,
			LC.UnitCost,
			LC.ExtendedCost,
			LC.VendorId,
			V.VendorName
		FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
		JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = LC.LeaseStocklineId
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		JOIN [dbo].[Charge] CH WITH (NOLOCK) ON CH.ChargeId = LC.ChargesTypeId
		LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON GL.GLAccountId = CH.GLAccountId
		LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = LC.UOMId
		LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = LC.VendorId
		WHERE LC.LeaseHeaderId = @LeaseHeaderId
		  AND LC.IsDeleted = @IsDeleted
		ORDER BY LC.LeaseChargesId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseChargesByLeaseHeaderId]',
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
