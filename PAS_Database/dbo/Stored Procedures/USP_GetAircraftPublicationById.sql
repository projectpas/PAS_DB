/*************************************************************
** File:        [USP_GetAircraftPublicationById]
** Description:
** Purpose:
** Date:
**
** RETURN VALUE:
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   -------------  --------------------------------
**  1    01/05/2026  Amit Ghediya		Created
*************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetAircraftPublicationById]
(
    @AircraftPublicationId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		
		SELECT 
			AircraftPublicationId,
			AircraftPublicationNumber,
			PubDate,
			PublicationTypeId,
			PubNum,
			RevisionNum,
			AircraftSectionId,
			Subject,
			PublishedById,
			PublishedByRefId,
			PublishedByOthers,
			ComplianceCategoryId,
			ComplianceCategory,
			Timeframe,
			PurposeReasonBackground,
			EntryDate,
			VerifiedBy,
			MasterCompanyId
		FROM AircraftPublication WITH (NOLOCK)
		WHERE AircraftPublicationId = @AircraftPublicationId
		  AND ISNULL(IsDeleted,0) = 0;
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = 'USP_GetAircraftPublicationById',
            @ProcedureParameters VARCHAR(3000),
            @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
              '@AircraftPublicationId=' + CAST(ISNULL(@AircraftPublicationId, 0) AS VARCHAR(20));

        EXEC spLogException
             @DatabaseName        = @DatabaseName,
             @AdhocComments       = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName     = @ApplicationName,
             @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR
        (
            'Unexpected error occurred in the database. Please let the support team know the error number: %d',
            16,
            1,
            @ErrorLogID
        );

        RETURN 1;
    END CATCH
END;