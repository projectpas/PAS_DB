/*************************************************************
 ** File:   [USP_GetLeasePickTicketChildList]
 ** Description: Child grid of the Leasing "Pick Ticket" tab - the pick history of a single
 **              Lease Stock Line (one row per pick transaction). Mirrors
 **              dbo.sp_GetPickTicketChildList (Sales Order).
 **
 **              Picked/Confirmed dates are stored in UTC and converted to the requesting
 **              employee's time zone (falling back to their Legal Entity's) the same way
 **              the Sales Order child list does.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_GetLeasePickTicketChildList @LeaseHeaderId=1, @LeaseStocklineId=1, @EmployeeId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePickTicketChildList]
	@LeaseHeaderId BIGINT,
	@LeaseStocklineId BIGINT,
	@EmployeeId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		FROM [dbo].[Employee] E WITH (NOLOCK)
		LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK)    ON E.[TimeZoneId] = ETZ.[TimeZoneId]
		LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK)  ON E.[LegalEntityId] = LE.[LegalEntityId]
		LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK)    ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE E.[EmployeeId] = @EmployeeId;

		DECLARE @QtyRemaining DECIMAL(18, 6) = 0;

		SELECT @QtyRemaining = ISNULL(LSL.[QtyReserved], 0) - ISNULL(
			(SELECT SUM(ISNULL([QtyPicked], 0)) FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
			 WHERE [LeaseStocklineId] = @LeaseStocklineId AND [IsDeleted] = 0), 0)
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId;

		IF (@QtyRemaining < 0) SET @QtyRemaining = 0;

		SELECT
			LPT.[LeasePickTicketId],
			LPT.[LeasePickTicketNumber],
			LPT.[LeaseHeaderId],
			LPT.[LeaseStocklineId],
			LPT.[StockLineId],
			LPT.[ItemMasterId],
			CAST(ISNULL(LPT.[QtyPicked], 0) AS DECIMAL(18, 6))    AS QtyPicked,
			CAST(ISNULL(LPT.[QtyReserved], 0) AS DECIMAL(18, 6))  AS QtyReserved,
			CAST(@QtyRemaining AS DECIMAL(18, 6))                 AS QtyRemaining,
			ISNULL(SL.[SerialNumber], '')   AS SerialNumber,
			ISNULL(SL.[StockLineNumber], '') AS StockLineNumber,
			ISNULL(SL.[ControlNumber], '')  AS ControlNumber,
			ISNULL(SL.[IdNumber], '')       AS IdNumber,
			CONCAT(EMP.[FirstName], ' ', EMP.[LastName])   AS PickedBy,
			CASE WHEN CAST(ISNULL(LPT.[PickedDate], LPT.[CreatedDate]) AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)
				 THEN NULL
				 ELSE CAST([dbo].[ConvertUTCtoLocal](ISNULL(LPT.[PickedDate], LPT.[CreatedDate]), @CurrntEmpTimeZoneDesc) AS DATE)
			END AS PickedDate,
			CONCAT(EMPC.[FirstName], ' ', EMPC.[LastName]) AS ConfirmedBy,
			CASE WHEN CAST(LPT.[ConfirmedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)
				 THEN NULL
				 ELSE CAST([dbo].[ConvertUTCtoLocal](LPT.[ConfirmedDate], @CurrntEmpTimeZoneDesc) AS DATE)
			END AS ConfirmedDate,
			ISNULL(LPT.[IsConfirmed], 0) AS IsConfirmed,
			LPT.[Memo],
			LPT.[Status],
			LPT.[MasterCompanyId]
		FROM [dbo].[LeasePickTicket] LPT WITH (NOLOCK)
		 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK)  ON SL.[StockLineId] = LPT.[StockLineId]
		 LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK)  ON EMP.[EmployeeId] = LPT.[PickedById]
		 LEFT JOIN [dbo].[Employee] EMPC WITH (NOLOCK) ON EMPC.[EmployeeId] = LPT.[ConfirmedById]
		WHERE LPT.[LeaseHeaderId]    = @LeaseHeaderId
		  AND LPT.[LeaseStocklineId] = @LeaseStocklineId
		  AND LPT.[IsDeleted]        = 0
		ORDER BY LPT.[LeasePickTicketId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeasePickTicketChildList]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS VARCHAR(100))
											   + ''', @LeaseStocklineId = ''' + CAST(ISNULL(@LeaseStocklineId, 0) AS VARCHAR(100)),
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