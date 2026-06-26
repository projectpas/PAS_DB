/*************************************************************
 ** File:        [USP_GetAircraftDataByWorkOrderIdS]
 ** Author:      Amit Ghediya
 ** Description: Return Aircraft Data.
 ** Purpose:
 ** Date:        23/JUN/2026

 ** PARAMETERS:  @WorkOrderId     BIGINT
 **              @WorkOrderPartNumberId BIGINT

 ** RETURN VALUE: single-row result set with the columns below.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author			Change Description
 ** --   --------      -------			--------------------------------
    1    23/JUN/2026  Amit Ghediya      Created


 EXEC USP_GetAircraftDataByWorkOrderId @WorkOrderId = 1, @workOrderPartNumberId = 1
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAircraftDataByWorkOrderId] 
    @WorkOrderId     BIGINT,
    @WorkOrderPartNumberId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            WorkOrderNumber            = WO.WorkOrderNum,
            -- Engine variant fields
            EngineModel            = CAST('Engine' AS VARCHAR(100)),
            TSO                    = CAST('12' AS VARCHAR(50)),
            TT                     = CAST('13' AS VARCHAR(50)),
            CSO                    = CAST('15' AS VARCHAR(50)),
            TC                     = CAST('18' AS VARCHAR(50)),
            -- Aircraft variant fields
            AircraftModel          = CASE WHEN ARHM.AircraftRegistryId > 0 THEN ARHM.AircraftModel ELSE ARHP.AircraftModel END,
            AircraftTailNumber     = CASE WHEN ARHM.AircraftRegistryId > 0 THEN ARHM.TailNum ELSE ARHP.TailNum END,
            ItemSerialNumber       = CASE WHEN ARHM.AircraftRegistryId > 0 THEN ARHM.SerialNum ELSE ARHP.SerialNum END,
            AircraftTT = CASE
                WHEN ARHM.AircraftRegistryId > 0
                    THEN CAST(CAST(ARHM.TotalTSN AS BIGINT) AS VARCHAR(20))
                         + ' : ' +
                         CAST(CAST(ARHM.TotalCSN AS BIGINT) AS VARCHAR(20))
                ELSE CAST(CAST(ARHP.TotalTSN AS BIGINT) AS VARCHAR(20))
                         + ' : ' +
                         CAST(CAST(ARHP.TotalCSN AS BIGINT) AS VARCHAR(20))
             END,
            -- Shared fields
            ReleaseDate            = CAST(NULL AS DATETIME),
            SignedByName           = CAST('' AS VARCHAR(100))
        FROM dbo.WorkOrder WO WITH(NOLOCK)
		JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
		LEFT JOIN dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK) ON AMP.ProgramId = WOP.ProgramId
		LEFT JOIN dbo.AircraftInstalledPartDetails AIP WITH(NOLOCK) ON AIP.AircraftInstalledPartDetailsId = WOP.AircraftInstalledPartDetailsId
		LEFT JOIN dbo.AircraftRegistryHeader ARHM WITH(NOLOCK) ON ARHM.AircraftRegistryId = AMP.AircraftRegistryId
		LEFT JOIN dbo.AircraftRegistryHeader ARHP WITH(NOLOCK) ON ARHP.AircraftRegistryId = AIP.AircraftRegistryId
        WHERE WO.WorkOrderId = @WorkOrderId 
		AND WOP.ID = @WorkOrderPartNumberId
		AND ISNULL(WO.IsFromAircraft,0) = 1;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID  INT,
                @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments        VARCHAR(150)  = 'USP_GetAircraftDataByWorkOrderId'
              , @ProcedureParameters  VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(20))
                                                     + ''', @WorkOrderPartNumberId = ''' + CAST(ISNULL(@WorkOrderPartNumberId, 0) AS VARCHAR(20)) + ''''
              , @ApplicationName      VARCHAR(100)  = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException
                  @DatabaseName          = @DatabaseName
                , @AdhocComments         = @AdhocComments
                , @ProcedureParameters   = @ProcedureParameters
                , @ApplicationName        = @ApplicationName
                , @ErrorLogID            = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END