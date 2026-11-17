/*************************************************************
** File:        [USP_GetCopyComponentSourceAircraftList]
** Description: Autocomplete list of aircraft / engines that installed components can be copied FROM
**              into the given (target) registry record.
**              Aircraft (@IsFromAircraft = 1): same Make and Model, different Tail Num.
**              Engine   (@IsFromAircraft = 0): same Engine Model, different engine.
** Date:        16/11/2026
**
** RETURN VALUE: Label (TailNum / EngineName), Value (AircraftRegistryId / EngineRegistryId), MakeType, AircraftModel, SerialNum, ComponentCount
**************************************************************
** Change History
**************************************************************
** PR   Date         Author             Change Description
** --   ----------   -------------      --------------------------------
** 1    16/11/2026   RAJESH GAMI        Created [PN-18542]
** 2    16/11/2026   RAJESH GAMI        Engine support (@IsFromAircraft = 0) [PN-18542]
**************************************************************/
--EXEC [dbo].[USP_GetCopyComponentSourceAircraftList] @TargetAircraftRegistryId = 128, @MasterCompanyId = 1, @SearchText = ''
--EXEC [dbo].[USP_GetCopyComponentSourceAircraftList] @TargetAircraftRegistryId = 10, @MasterCompanyId = 1, @SearchText = '', @IsFromAircraft = 0
CREATE   PROCEDURE [dbo].[USP_GetCopyComponentSourceAircraftList]
(
    @TargetAircraftRegistryId BIGINT,
    @MasterCompanyId          INT,
    @SearchText               VARCHAR(100) = NULL,
    @TopCount                 INT          = 50,
    @IsFromAircraft           BIT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @EscSearchText VARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@SearchText, '\', '\\'), '%', '\%'), '_', '\_'), '[', '\[');

        IF (ISNULL(@IsFromAircraft, 1) = 1)
        BEGIN
            DECLARE @TargetMakeTypeId      BIGINT,
                    @TargetAircraftModelId BIGINT;

            SELECT @TargetMakeTypeId      = [MakeTypeId],
                   @TargetAircraftModelId = [AircraftModelId]
            FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
            WHERE [AircraftRegistryId] = @TargetAircraftRegistryId
              AND [MasterCompanyId]    = @MasterCompanyId;

            SELECT TOP (@TopCount)
                SourceAircraft.[TailNum]            AS [Label],
                SourceAircraft.[AircraftRegistryId] AS [Value],
                SourceAircraft.[MakeType]           AS [MakeType],
                SourceAircraft.[AircraftModel]      AS [AircraftModel],
                SourceAircraft.[SerialNum]          AS [SerialNum],
                (SELECT COUNT(1)
                 FROM [dbo].[AircraftInstalledPartDetails] SourceComponent WITH (NOLOCK)
                 WHERE SourceComponent.[AircraftRegistryId] = SourceAircraft.[AircraftRegistryId]
                   AND ISNULL(SourceComponent.[IsFromAircraft], 0) = 1
                   AND SourceComponent.[IsActive]  = 1
                   AND SourceComponent.[IsDeleted] = 0)  AS [ComponentCount]
            FROM [dbo].[AircraftRegistryHeader] SourceAircraft WITH (NOLOCK)
            WHERE SourceAircraft.[MasterCompanyId]    = @MasterCompanyId
              AND SourceAircraft.[IsActive]           = 1
              AND SourceAircraft.[IsDeleted]          = 0
              AND SourceAircraft.[AircraftRegistryId] <> @TargetAircraftRegistryId
              AND SourceAircraft.[MakeTypeId]         = @TargetMakeTypeId
              AND SourceAircraft.[AircraftModelId]    = @TargetAircraftModelId
              AND (ISNULL(@SearchText, '') = '' OR SourceAircraft.[TailNum] LIKE '%' + @EscSearchText + '%' ESCAPE '\')
            ORDER BY SourceAircraft.[TailNum]
            OPTION (RECOMPILE);
        END
        ELSE
        BEGIN
            DECLARE @TargetEngineModel VARCHAR(100);

            SELECT @TargetEngineModel = UPPER(LTRIM(RTRIM([EngineModel])))
            FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
            WHERE [EngineRegistryId] = @TargetAircraftRegistryId
              AND [MasterCompanyId]  = @MasterCompanyId;

            SELECT TOP (@TopCount)
                ISNULL(NULLIF(SourceEngine.[EngineName], ''), SourceEngine.[TailNum]) AS [Label],
                SourceEngine.[EngineRegistryId] AS [Value],
                SourceEngine.[MakeType]         AS [MakeType],
                SourceEngine.[EngineModel]      AS [AircraftModel],
                SourceEngine.[SerialNum]        AS [SerialNum],
                (SELECT COUNT(1)
                 FROM [dbo].[AircraftInstalledPartDetails] SourceComponent WITH (NOLOCK)
                 WHERE SourceComponent.[AircraftRegistryId] = SourceEngine.[EngineRegistryId]
                   AND ISNULL(SourceComponent.[IsFromAircraft], 0) = 0
                   AND SourceComponent.[IsActive]  = 1
                   AND SourceComponent.[IsDeleted] = 0)  AS [ComponentCount]
            FROM [dbo].[EngineRegistryHeader] SourceEngine WITH (NOLOCK)
            WHERE SourceEngine.[MasterCompanyId]   = @MasterCompanyId
              AND SourceEngine.[IsActive]          = 1
              AND SourceEngine.[IsDeleted]         = 0
              AND SourceEngine.[EngineRegistryId] <> @TargetAircraftRegistryId
              AND @TargetEngineModel IS NOT NULL
              AND UPPER(LTRIM(RTRIM(SourceEngine.[EngineModel]))) = @TargetEngineModel
              AND (ISNULL(@SearchText, '') = ''
                   OR ISNULL(NULLIF(SourceEngine.[EngineName], ''), SourceEngine.[TailNum]) LIKE '%' + @EscSearchText + '%' ESCAPE '\')
            ORDER BY ISNULL(NULLIF(SourceEngine.[EngineName], ''), SourceEngine.[TailNum])
            OPTION (RECOMPILE);
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments       VARCHAR(150)  = '[dbo].[USP_GetCopyComponentSourceAircraftList] '
            , @ProcedureParameters VARCHAR(3000) = '@TargetAircraftRegistryId = ' + ISNULL(CAST(@TargetAircraftRegistryId AS VARCHAR(20)), '')
            , @ApplicationName     VARCHAR(100)  = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException
              @DatabaseName        = @DatabaseName
            , @AdhocComments       = @AdhocComments
            , @ProcedureParameters = @ProcedureParameters
            , @ApplicationName     = @ApplicationName
            , @ErrorLogID          = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END
