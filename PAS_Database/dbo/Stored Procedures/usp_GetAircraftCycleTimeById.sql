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
** 3    28/04/2026  Amit Ghediya		Get Minutes related data (PN-16151)
*************************************************************/
CREATE     PROCEDURE [dbo].[usp_GetAircraftCycleTimeById]
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
			LastFlownDate = (SELECT TOP 1 DateInstalled FROM dbo.AircraftInstalledPartDetails WITH(NOLOCK) WHERE [AircraftRegistryId] = [RefrenceId])
		FROM dbo.AircraftCycleTimeMappings WITH(NOLOCK)
		WHERE RefrenceId = @AircraftCycleTimeMappingsId
		  AND IsActive = 1 AND IsDeleted = 0;

		-- Engine Data
		SELECT 
			AESM.AircraftEngineStartsMappingsId,
			AESM.AircraftCycleTimeMappingsId,
			AESM.EngineName,
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
		FROM dbo.AircraftEngineStartsMappings AESM WITH(NOLOCK)
		INNER JOIN dbo.AircraftCycleTimeMappings ACTM WITH(NOLOCK) ON ACTM.AircraftCycleTimeMappingsId = AESM.AircraftCycleTimeMappingsId
		WHERE ACTM.RefrenceId = @AircraftCycleTimeMappingsId
		  AND AESM.IsActive = 1 AND AESM.IsDeleted = 0;
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