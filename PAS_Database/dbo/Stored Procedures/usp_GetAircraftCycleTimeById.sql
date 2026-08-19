/*************************************************************
** File:        [usp_GetAircraftCycleTimeById]
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
** 1    14/04/2026  Amit Ghediya		Created
** 2    14/04/2026  Amit Ghediya		Get LastFlownDate (PN-16156)
** 3    28/04/2026  Amit Ghediya		Get Minutes related data,LastFlownDate (PN-16151)
** 4    17/07/2026  Amit Ghediya		Drive engine list from AircraftRegistryHeader.EngineRegistryIds
**                                      (real EngineRegistryId + EngineName) instead of only whatever
**                                      was previously saved into AircraftEngineStartsMappings.
*************************************************************/
CREATE       PROCEDURE [dbo].[usp_GetAircraftCycleTimeById]
(
    @AircraftCycleTimeMappingsId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		
		-- Main Cycle Data
		SELECT 
			AircraftCycleTimeMappingsId,
			ModuleId,
			RefrenceId,
			CycleDate,
			Hours,
			Minutes,
			CurruntHours,
			CurruntMinutes,
			CumulativeHours,
			CumulativeMinutes,
			Cycles,
			CyclesMinutes,
			CurruntCycles,
			CurruntCyclesMinutes,
			CumulativeCycles,
			CumulativeCyclesMinutes,
			Memo,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy,
			LastFlownDate = (SELECT TOP 1 LastFlownDate FROM dbo.AircraftRegistryHeader WITH(NOLOCK) WHERE [AircraftRegistryId] = [RefrenceId])
		FROM dbo.AircraftCycleTimeMappings WITH(NOLOCK)
		WHERE RefrenceId = @AircraftCycleTimeMappingsId
		  AND IsActive = 1 AND IsDeleted = 0;

		-- Engine Data
		-- Driven by the aircraft's currently attached engines (AircraftRegistryHeader.EngineRegistryIds),
		-- so the list always reflects real attached engines (with their real name/id) even when no
		-- cycle data has ever been saved for that engine yet. Previously saved values (if any) are
		-- pulled in via OUTER APPLY so the popup can still pre-populate on edit.
		SELECT
			AESM.AircraftEngineStartsMappingsId,
			AESM.AircraftCycleTimeMappingsId,
			ERH.EngineRegistryId,
			ERH.EngineName,
			AESM.Hours,
			AESM.Minutes,
			AESM.CurruntHours,
			AESM.CurruntMinutes,
			AESM.CumulativeHours,
			AESM.CumulativeMinutes,
			AESM.Starts,
			AESM.CurruntStarts,
			AESM.CumulativeStarts,
			AESM.Memo,
			AESM.MasterCompanyId,
			AESM.CreatedBy,
			AESM.UpdatedBy
		FROM dbo.AircraftRegistryHeader ARH WITH(NOLOCK)
		CROSS APPLY STRING_SPLIT(ARH.EngineRegistryIds, ',') S
		INNER JOIN dbo.EngineRegistryHeader ERH WITH(NOLOCK)
			ON ERH.EngineRegistryId = TRY_CONVERT(BIGINT, LTRIM(RTRIM(S.value)))
		   AND ERH.IsActive = 1 AND ERH.IsDeleted = 0
		OUTER APPLY (
			SELECT TOP 1 AESM2.*
			FROM dbo.AircraftEngineStartsMappings AESM2 WITH(NOLOCK)
			INNER JOIN dbo.AircraftCycleTimeMappings ACTM2 WITH(NOLOCK) ON ACTM2.AircraftCycleTimeMappingsId = AESM2.AircraftCycleTimeMappingsId
			WHERE ACTM2.RefrenceId = @AircraftCycleTimeMappingsId
			  AND AESM2.EngineRegistryId = ERH.EngineRegistryId
			  AND AESM2.IsActive = 1 AND AESM2.IsDeleted = 0
			ORDER BY AESM2.AircraftEngineStartsMappingsId DESC
		) AESM
		WHERE ARH.AircraftRegistryId = @AircraftCycleTimeMappingsId
		  AND TRY_CONVERT(BIGINT, LTRIM(RTRIM(S.value))) IS NOT NULL;
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = 'usp_GetAircraftCycleTimeById',
            @ProcedureParameters VARCHAR(3000),
            @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
              '@AircraftCycleTimeMappingsId=' + CAST(ISNULL(@AircraftCycleTimeMappingsId, 0) AS VARCHAR(20));
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