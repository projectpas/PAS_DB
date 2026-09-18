/*************************************************************
 ** File:   [USP_GetNextLeasePickTicketNumber]
 ** Description: Reserves and returns the next Lease Pick Ticket number for a Master Company.
 **              Mirrors the SO Pick Ticket numbering (PT(SO)-000001) but keeps the sequence
 **              in SQL like the rest of the Leasing module (see USP_CreateUpdateLeaseHeader).
 **              One Pick Ticket number covers every line saved in a single pick transaction,
 **              so the caller asks for the number ONCE and passes it to each
 **              USP_SaveLeasePickTicketItem call of that batch.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    16/09/2026     Bhargav Saliya          [PN-17931] Created - Leasing Pick Ticket

exec USP_GetNextLeasePickTicketNumber @MasterCompanyId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetNextLeasePickTicketNumber]
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @CodeTypeId BIGINT, @CurrentNo BIGINT = 0;
		DECLARE @CodePrefix VARCHAR(10) = '', @CodeSuffix VARCHAR(10) = '';
		DECLARE @Generated TABLE (CurrentNummber BIGINT, CodePrefix VARCHAR(10), CodeSufix VARCHAR(10));

		SELECT @CodeTypeId = [CodeTypeId]
		FROM [dbo].[CodeTypes] WITH (NOLOCK)
		WHERE [CodeType] = 'LeasePickTicket';

		-- Single atomic statement so two users picking at the same time can never take the same number.
		UPDATE [dbo].[CodePrefixes]
		SET [CurrentNummber] = CASE WHEN ISNULL([CurrentNummber], 0) > 0
									THEN ISNULL([CurrentNummber], 0) + 1
									ELSE ISNULL([StartsFrom], 0) + 1
							   END
		OUTPUT inserted.[CurrentNummber], inserted.[CodePrefix], inserted.[CodeSufix] INTO @Generated
		WHERE [CodeTypeId]      = @CodeTypeId
		  AND [MasterCompanyId] = @MasterCompanyId
		  AND [IsActive]        = 1
		  AND [IsDeleted]       = 0;

		IF NOT EXISTS (SELECT 1 FROM @Generated)
		BEGIN
			SELECT CAST('' AS VARCHAR(50)) AS LeasePickTicketNumber,
			       0 AS [Status],
			       'Code Prefix is not configured for Lease Pick Ticket.' AS [Message];
			RETURN;
		END

		SELECT TOP 1 @CurrentNo  = [CurrentNummber],
		             @CodePrefix = ISNULL([CodePrefix], ''),
		             @CodeSuffix = ISNULL([CodeSufix], '')
		FROM @Generated;

		SELECT CAST(gen.StocklineNumber AS VARCHAR(50)) AS LeasePickTicketNumber,
		       1 AS [Status],
		       'Success' AS [Message]
		FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, @CodePrefix, @CodeSuffix) gen;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetNextLeasePickTicketNumber]',
			@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)),
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
