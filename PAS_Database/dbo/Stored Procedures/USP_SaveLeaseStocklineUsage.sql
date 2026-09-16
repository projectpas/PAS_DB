/*************************************************************
 ** File:   [USP_SaveLeaseStocklineUsage]
 ** Description: Records a new Time (TSN) / Cycle (CSN) usage reading for a
 **              LeaseStockline. @TSNHours/@TSNMinutes and @CSNHours/@CSNMinutes
 **              are an INCREMENT (this reading's own added usage, e.g. "2:45"),
 **              not an absolute value - the running total in LeaseStocklineUsage
 **              (one row per stockline) is the SUM of every increment ever
 **              submitted (e.g. current 2:45 + new 4:05 = 6:50), with standard
 **              HH:MM carry (minutes >= 60 rolls into hours). The raw increment
 **              as entered is separately appended to LeaseStocklineUsageHistory
 **              (full audit trail of every individual reading, unsummed).
 **              Validates: no negative Hours/Minutes, Minutes in [0,59].
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    15/09/2026     Amit Ghediya            Created
    2    15/09/2026     Amit Ghediya            Reworked: @TSNHours/@TSNMinutes and
                                                 @CSNHours/@CSNMinutes are now the
                                                 incremental amount added this entry,
                                                 summed (with HH:MM carry) into the
                                                 running total on LeaseStocklineUsage,
                                                 instead of overwriting it as an
                                                 absolute reading - removed the
                                                 "new value cannot be less than
                                                 current" guard, which no longer
                                                 applies to an incremental amount
    3    15/09/2026     Amit Ghediya            @Notes is now also stored as
                                                 LatestNotes on LeaseStocklineUsage
                                                 (not just appended to History), so
                                                 the most recent note is available to
                                                 show directly on the Usage Info list

exec USP_SaveLeaseStocklineUsage @LeaseStocklineId=1, @EntryDate='2026-09-15', @TSNHours=2, @TSNMinutes=45,
	@CSNHours=1, @CSNMinutes=30, @Notes=N'test', @MasterCompanyId=1, @UpdatedBy='test'
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_SaveLeaseStocklineUsage]
	@LeaseStocklineId BIGINT,
	@EntryDate DATETIME2(7),
	@TSNHours DECIMAL(18,6) = NULL,
	@TSNMinutes DECIMAL(18,6) = NULL,
	@CSNHours DECIMAL(18,6) = NULL,
	@CSNMinutes DECIMAL(18,6) = NULL,
	@Notes NVARCHAR(MAX) = NULL,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Basic range validation - guard clauses, raised before the transaction starts
	IF (ISNULL(@TSNHours,0) < 0 OR ISNULL(@TSNMinutes,0) < 0 OR ISNULL(@CSNHours,0) < 0 OR ISNULL(@CSNMinutes,0) < 0)
	BEGIN
		RAISERROR ('Time and Cycle values cannot be negative.', 16, 1);
		RETURN (1);
	END

	IF (ISNULL(@TSNMinutes,0) > 59 OR ISNULL(@CSNMinutes,0) > 59)
	BEGIN
		RAISERROR ('Minutes must be between 0 and 59.', 16, 1);
		RETURN (1);
	END

	DECLARE @CurrentTSNTotalMinutes DECIMAL(18,6) = 0;
	DECLARE @CurrentCSNTotalMinutes DECIMAL(18,6) = 0;

	SELECT
		@CurrentTSNTotalMinutes = ISNULL(CurrentTSNHours,0) * 60 + ISNULL(CurrentTSNMinutes,0),
		@CurrentCSNTotalMinutes = ISNULL(CurrentCSNHours,0) * 60 + ISNULL(CurrentCSNMinutes,0)
	FROM [dbo].[LeaseStocklineUsage] WITH (NOLOCK)
	WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;

	-- Sum this entry's increment onto the running total (HH:MM carry via total-minutes arithmetic)
	DECLARE @NewCurrentTSNTotalMinutes DECIMAL(18,6) = ISNULL(@CurrentTSNTotalMinutes,0) + (ISNULL(@TSNHours,0) * 60 + ISNULL(@TSNMinutes,0));
	DECLARE @NewCurrentCSNTotalMinutes DECIMAL(18,6) = ISNULL(@CurrentCSNTotalMinutes,0) + (ISNULL(@CSNHours,0) * 60 + ISNULL(@CSNMinutes,0));

	DECLARE @NewCurrentTSNHours DECIMAL(18,6) = FLOOR(@NewCurrentTSNTotalMinutes / 60);
	DECLARE @NewCurrentTSNMinutes DECIMAL(18,6) = @NewCurrentTSNTotalMinutes - (@NewCurrentTSNHours * 60);
	DECLARE @NewCurrentCSNHours DECIMAL(18,6) = FLOOR(@NewCurrentCSNTotalMinutes / 60);
	DECLARE @NewCurrentCSNMinutes DECIMAL(18,6) = @NewCurrentCSNTotalMinutes - (@NewCurrentCSNHours * 60);

	BEGIN TRY
	BEGIN TRANSACTION

		IF EXISTS (SELECT 1 FROM [dbo].[LeaseStocklineUsage] WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0)
		BEGIN
			UPDATE [dbo].[LeaseStocklineUsage]
			SET CurrentTSNHours   = @NewCurrentTSNHours,
				CurrentTSNMinutes = @NewCurrentTSNMinutes,
				CurrentTSNDate    = @EntryDate,
				CurrentCSNHours   = @NewCurrentCSNHours,
				CurrentCSNMinutes = @NewCurrentCSNMinutes,
				CurrentCSNDate    = @EntryDate,
				LatestNotes       = @Notes,
				UpdatedBy         = @UpdatedBy,
				UpdatedDate       = GETUTCDATE()
			WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[LeaseStocklineUsage]
				(LeaseStocklineId, CurrentTSNHours, CurrentTSNMinutes, CurrentTSNDate, CurrentCSNHours, CurrentCSNMinutes, CurrentCSNDate, LatestNotes,
				 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES
				(@LeaseStocklineId, @NewCurrentTSNHours, @NewCurrentTSNMinutes, @EntryDate, @NewCurrentCSNHours, @NewCurrentCSNMinutes, @EntryDate, @Notes,
				 @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
		END

		-- History keeps the raw, unsummed increment exactly as entered
		INSERT INTO [dbo].[LeaseStocklineUsageHistory]
			(LeaseStocklineId, EntryDate, TSNHours, TSNMinutes, CSNHours, CSNMinutes, Notes,
			 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
		VALUES
			(@LeaseStocklineId, @EntryDate, @TSNHours, @TSNMinutes, @CSNHours, @CSNMinutes, @Notes,
			 @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

		SELECT LeaseStocklineId, CurrentTSNHours, CurrentTSNMinutes, CurrentTSNDate,
			CurrentCSNHours, CurrentCSNMinutes, CurrentCSNDate, LatestNotes, UpdatedBy, UpdatedDate
		FROM [dbo].[LeaseStocklineUsage] WITH (NOLOCK)
		WHERE LeaseStocklineId = @LeaseStocklineId AND IsDeleted = 0;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_SaveLeaseStocklineUsage]',
            @ProcedureParameters varchar(3000) = '@LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS varchar(100)),
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
