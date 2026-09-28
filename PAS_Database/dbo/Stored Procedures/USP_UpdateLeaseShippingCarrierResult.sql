
/***************************************************************
 ** File:  [USP_UpdateLeaseShippingCarrierResult]
 ** Author:   Moin Bloch
 ** Description: Persist the real FedEx/UPS tracking number and generated label PDF path(s)
 **              after a live carrier shipment-creation call, mirroring how
 **              WorkOrderController updates WorkOrderShipping.AirwayBill / WorkOrderShippingItem.FedexPdfPath/UPSPdfPath.
 ** Date:  25-Sep-2026
 ** Change History
 *******************************************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    25-Sep-2026		Moin Bloch			Created

*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateLeaseShippingCarrierResult]
	@LeaseShippingId BIGINT,
	@AirwayBill VARCHAR(50) = NULL,
	@FedexPdfPath VARCHAR(500) = NULL,
	@UpsPdfPath VARCHAR(500) = NULL,
	@UpdatedBy VARCHAR(256) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @AirwayBill IS NOT NULL AND LTRIM(RTRIM(@AirwayBill)) <> ''
		BEGIN
			UPDATE [dbo].[LeaseShipping]
			SET [AirwayBill] = @AirwayBill, [UpdatedBy] = ISNULL(@UpdatedBy, [UpdatedBy]), [UpdatedDate] = GETUTCDATE()
			WHERE [LeaseShippingId] = @LeaseShippingId;
		END

		IF @FedexPdfPath IS NOT NULL AND LTRIM(RTRIM(@FedexPdfPath)) <> ''
		BEGIN
			UPDATE [dbo].[LeaseShippingItem]
			SET [FedexPdfPath] = @FedexPdfPath, [UpdatedBy] = ISNULL(@UpdatedBy, [UpdatedBy]), [UpdatedDate] = GETUTCDATE()
			WHERE [LeaseShippingId] = @LeaseShippingId AND [IsDeleted] = 0;
		END

		IF @UpsPdfPath IS NOT NULL AND LTRIM(RTRIM(@UpsPdfPath)) <> ''
		BEGIN
			UPDATE [dbo].[LeaseShippingItem]
			SET [UPSPdfPath] = @UpsPdfPath, [UpdatedBy] = ISNULL(@UpdatedBy, [UpdatedBy]), [UpdatedDate] = GETUTCDATE()
			WHERE [LeaseShippingId] = @LeaseShippingId AND [IsDeleted] = 0;
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_UpdateLeaseShippingCarrierResult]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseShippingId = ''' + CAST(ISNULL(@LeaseShippingId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END