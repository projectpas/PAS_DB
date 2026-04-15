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
			CurruntHours,
			CumulativeHours,
			Cycles,
			CurruntCycles,
			CumulativeCycles,
			Memo,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy
		FROM dbo.AircraftCycleTimeMappings WITH(NOLOCK)
		WHERE AircraftCycleTimeMappingsId = @AircraftCycleTimeMappingsId
		  AND IsDeleted = 0;

		-- Engine Data
		SELECT 
			AircraftEngineStartsMappingsId,
			AircraftCycleTimeMappingsId,
			EngineName,
			Hours,
			CurruntHours,
			CumulativeHours,
			Starts,
			CurruntStarts,
			CumulativeStarts,
			Memo,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy
		FROM dbo.AircraftEngineStartsMappings WITH(NOLOCK)
		WHERE AircraftCycleTimeMappingsId = @AircraftCycleTimeMappingsId
		  AND IsDeleted = 0;
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