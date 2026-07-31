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
    2    27/JUL/2026  Abhishek Jirawala Join via Stockline to AircraftRegistryHeader/EngineRegistryHeader and TimeLife
                                        instead of returning hardcoded engine values
    3    27/JUL/2026  Abhishek Jirawala Only one of the Aircraft/Engine variant fields is now sourced per row,
                                        based on which registry the stockline actually resolves to
    4    27/JUL/2026  Abhishek Jirawala Removed the WO.IsFromAircraft=1 filter - that flag is actually set from
                                        the PART's own Aircraft/Engine discriminator (0 for Engine), so it was
                                        silently excluding every genuine Engine work order from the result set
	5    30/JUL/2026  Amit Ghediya	   Get mm data from TTSNMM [PN-17127]


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
            WorkOrderNumber        = WO.WorkOrderNum,
            -- Engine variant fields (only sourced when the stockline is NOT an Aircraft registry match)
            EngineModel            = CASE WHEN ARH.AircraftRegistryId IS NOT NULL THEN NULL ELSE ERH.EngineModel END,
            ItemSerialNumber       = CASE WHEN ARH.AircraftRegistryId IS NOT NULL THEN ARH.SerialNum ELSE ERH.SerialNum END,
            TSO                    = CASE WHEN ARH.AircraftRegistryId IS NOT NULL THEN NULL ELSE CAST(TL.TimeSinceOVH AS VARCHAR(50)) END,
            TT                     = CASE
                                        WHEN ARH.AircraftRegistryId IS NOT NULL THEN NULL
                                        WHEN ERH.EngineRegistryId IS NOT NULL THEN CAST(CAST(ERH.TotalTSN AS BIGINT) AS VARCHAR(50))
                                        ELSE NULL
                                      END,
            CSO                    = CASE WHEN ARH.AircraftRegistryId IS NOT NULL THEN NULL ELSE CAST(TL.CyclesSinceOVH AS VARCHAR(50)) END,
            TC                     = CASE
                                        WHEN ARH.AircraftRegistryId IS NOT NULL THEN NULL
                                        WHEN ERH.EngineRegistryId IS NOT NULL THEN CAST(CAST(ERH.TotalCSN AS BIGINT) AS VARCHAR(50))
                                        ELSE NULL
                                      END,
            -- Aircraft variant fields (only sourced when the stockline IS an Aircraft registry match)
            AircraftModel          = CASE WHEN ARH.AircraftRegistryId IS NOT NULL THEN ARH.AircraftModel ELSE NULL END,
            AircraftTailNumber     = CASE WHEN ARH.AircraftRegistryId IS NOT NULL THEN ARH.TailNum ELSE NULL END,
            AircraftTT = CASE
                WHEN ARH.AircraftRegistryId IS NOT NULL
                    THEN CAST(CAST(ARH.TotalTSN AS BIGINT) AS VARCHAR(20))
                         + ' : ' +
                         CAST(CAST(ARH.TotalTSNMM AS BIGINT) AS VARCHAR(20))
                ELSE NULL
             END,
            -- Shared fields
            ReleaseDate            = CAST(NULL AS DATETIME),
            SignedByName           = CAST('' AS VARCHAR(100))
        FROM dbo.WorkOrder WO WITH(NOLOCK)
		JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
		LEFT JOIN dbo.Stockline STK WITH(NOLOCK) ON STK.StockLineId = WOP.StockLineId
		LEFT JOIN dbo.AircraftRegistryHeader ARH WITH(NOLOCK) ON ARH.StockLineId = STK.StockLineId
		LEFT JOIN dbo.EngineRegistryHeader ERH WITH(NOLOCK) ON ERH.StockLineId = STK.StockLineId
		LEFT JOIN dbo.TimeLife TL WITH(NOLOCK) ON TL.StockLineId = STK.StockLineId AND ISNULL(TL.IsActive,0) = 1
        WHERE WO.WorkOrderId = @WorkOrderId
		AND WOP.ID = @WorkOrderPartNumberId;

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