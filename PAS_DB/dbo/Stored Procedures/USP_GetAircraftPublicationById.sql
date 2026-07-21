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
**  2    08/07/2026  Amit Ghediya		Get Applicability,MEL [PN-17157]
**  3    14/07/2026  Amit Ghediya		Allow to create maintanace for allow except ser num [PN-17223]
*************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetAircraftPublicationById]
(
    @AircraftPublicationId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		
		SELECT 
			AP.AircraftPublicationId,
			AP.AircraftPublicationNumber,
			AP.PubDate,
			AP.PublicationTypeId,
			AP.PubNum,
			AP.RevisionNum,
			AP.AircraftSectionId,
			AP.Subject,
			AP.PublishedById,
			AP.PublishedByRefId,
			AP.PublishedByOthers,
			AP.ComplianceCategoryId,
			AP.ComplianceCategory,
			AP.Timeframe,
			AP.PurposeReasonBackground,
			AP.EntryDate,
			AP.VerifiedBy,
			AP.MasterCompanyId,
			AP.Applicability,
			AP.MEL,
			CASE WHEN ACE.HasRow = 1 THEN 1 ELSE 0 END AS IsAircraftEffectivity,
			CASE WHEN MTC.HasRow = 1 THEN 1 ELSE 0 END AS IsForMaintenance
		FROM DBO.AircraftPublication AP WITH (NOLOCK)
		OUTER APPLY (
				SELECT TOP 1 1 AS HasRow
				FROM dbo.AircraftEffectivity ACE2 WITH (NOLOCK)
				WHERE ACE2.AircraftPublicationId = AP.AircraftPublicationId
			 ) ACE
		OUTER APPLY (
				SELECT TOP 1 1 AS HasRow
				FROM dbo.AircraftEffectivity ACE3 WITH (NOLOCK)
				INNER JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK)
						ON ARH.MakeTypeId = ACE3.MakeTypeId
					   AND (ACE3.AircraftModelId IS NULL OR ARH.AircraftModelId = ACE3.AircraftModelId)
					   AND (
							 -- Case A: rule HAS aircraft affect rows -> registry serial must be in that list
							 (
								 EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AF WITH (NOLOCK)
										 WHERE AF.AircraftEffectivityId = ACE3.AircraftEffectivityId
										   AND AF.IsAircraftSerialNum = 1 AND AF.IsAffect = 1 AND AF.IsDeleted = 0)
								 AND EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AF WITH (NOLOCK)
											 WHERE AF.AircraftEffectivityId = ACE3.AircraftEffectivityId
											   AND AF.IsAircraftSerialNum = 1 AND AF.IsAffect = 1 AND AF.IsDeleted = 0
											   AND (
												   (AF.FromSerial = ARH.SerialNum)
											   ))
							 )
							 OR
							 -- Case B: NO affect rows -> if the picker has EVER touched this rule's
							 -- AC-level data (any affect OR except row), trust the child table and treat
							 -- "no affects" as wildcard -- AircraftEffectivity.SerialNum isn't kept in
							 -- sync once the grid's eye icon edits only the child table. Only fall back
							 -- to the legacy single-value/blank field when completely untouched by the picker.
							 (
								 NOT EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AF WITH (NOLOCK)
											 WHERE AF.AircraftEffectivityId = ACE3.AircraftEffectivityId
											   AND AF.IsAircraftSerialNum = 1 AND AF.IsAffect = 1 AND AF.IsDeleted = 0)
								 AND (
									   EXISTS (SELECT 1 FROM dbo.AircraftEffectivitySerialDetail ANYAC WITH (NOLOCK)
											   WHERE ANYAC.AircraftEffectivityId = ACE3.AircraftEffectivityId
												 AND ANYAC.IsAircraftSerialNum = 1 AND ANYAC.IsDeleted = 0)
									   OR (ISNULL(ACE3.SerialNum,'') <> '' AND ARH.SerialNum = ACE3.SerialNum)
									   OR ISNULL(ACE3.SerialNum,'') = ''
									 )
							 )
						   )
					   -- Aircraft-level exclusion: this aircraft's serial must not be explicitly excepted
					   AND NOT EXISTS (
							   SELECT 1
							   FROM dbo.AircraftEffectivitySerialDetail EXC WITH (NOLOCK)
							   WHERE EXC.AircraftEffectivityId = ACE3.AircraftEffectivityId
								 AND EXC.IsAircraftSerialNum    = 1
								 AND EXC.IsAffect               = 0
								 AND EXC.IsDeleted              = 0
								 AND EXC.FromSerial             = ARH.SerialNum
						   )
				WHERE ACE3.AircraftPublicationId = AP.AircraftPublicationId
				  AND ISNULL(ACE3.IsDeleted, 0) = 0
				  AND ISNULL(ARH.IsDeleted, 0) = 0
			 ) MTC
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