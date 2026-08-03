/************************************************************
** File:        [USP_GetOpenWorksheetsForAircraft]
** Description: Returns the paginated list of OPEN worksheets (WorkSheetStatusId = 1)
**              for a given aircraft -- feeds the "Add to Existing Worksheet" picker
**              shown from the "Create Worksheet" confirmation popup. Mirrors the
**              shape of GetAircraftWorkOrderList's existing-WO picker.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    24/07/2026  Amit Ghediya      Created
** 2    30/07/2026  Amit Ghediya      Update for get MakeTypeId,ModelId data match Ws only [PN-17477]
************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetOpenWorksheetsForAircraft]
    @PageNumber         INT          = 1,
    @PageSize           INT          = 10,
    @SortColumn         VARCHAR(50)  = 'createdDate',
    @SortOrder          VARCHAR(4)   = 'DESC',
    @AircraftRegistryId BIGINT,
    @MasterCompanyId    INT,
    @IsFromAircraft     BIT
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

		DECLARE @MakeTypeId BIGINT = 0,
				@ModelId BIGINT = 0,
				@Model VARCHAR(100);

        SET @PageNumber = CASE WHEN @PageNumber < 1 THEN 1 ELSE @PageNumber END;
        SET @PageSize   = CASE WHEN @PageSize < 1 THEN 10 WHEN @PageSize > 500 THEN 500 ELSE @PageSize END;
        SET @SortOrder  = CASE WHEN UPPER(@SortOrder) = 'ASC' THEN 'ASC' ELSE 'DESC' END;

		IF ISNULL(@IsFromAircraft, 1) = 1
		BEGIN
			SELECT @MakeTypeId = [MakeTypeId], @ModelId = [AircraftModelId]
			FROM [dbo].[AircraftRegistryHeader] WITH (NOLOCK)
			WHERE [AircraftRegistryId] = @AircraftRegistryId
		END
		ELSE
		BEGIN
			SELECT @Model = [EngineModel]
			FROM [dbo].[EngineRegistryHeader] WITH (NOLOCK)
			WHERE [EngineRegistryId] = @AircraftRegistryId
		END

        ;WITH OpenWorksheets AS
        (
            SELECT
                WH.WorksheetHeaderId,
                WH.WorksheetNumber,
                WH.TailNum,
                WH.MakeType,
				WH.AircraftModel,
                WH.SerialNum,
				ERH.EngineName,
                CASE WHEN ISNULL(WH.IsFromAircraft,0) = 1 THEN ARH.CustomerName ELSE ERH.CustomerName END AS CustomerName,
                WSS.Status,
                WH.CreatedDate,
                COUNT_BIG(1) OVER () AS TotalRecords
            FROM [dbo].[WorksheetHeader] WH WITH (NOLOCK)
            LEFT JOIN [dbo].[AircraftRegistryHeader] ARH WITH (NOLOCK) ON ARH.AircraftRegistryId = WH.AircraftRegistryId
                AND ARH.MasterCompanyId = WH.MasterCompanyId
				AND ISNULL(WH.IsFromAircraft,0) = 1
			LEFT JOIN [dbo].[EngineRegistryHeader] ERH WITH (NOLOCK) ON ERH.EngineRegistryId = WH.EngineRegistryId
                AND ERH.MasterCompanyId = WH.MasterCompanyId
				AND ISNULL(WH.IsFromAircraft,0) = 0
            LEFT JOIN [dbo].[WorkSheetStatus] WSS WITH (NOLOCK)
                ON WSS.WorkSheetStatusId = WH.WorkSheetStatusId
            WHERE
			  (
				(ISNULL(@IsFromAircraft,1) = 1 AND WH.MakeTypeId = @MakeTypeId AND WH.AircraftModelId = @ModelId)
				OR
				(ISNULL(@IsFromAircraft,1) = 0 AND WH.AircraftModel = @Model)
			  )
			  AND ISNULL(WH.IsFromAircraft,0) = ISNULL(@IsFromAircraft,1)
              AND WH.MasterCompanyId = @MasterCompanyId
              AND WH.IsDeleted = 0
              AND WH.WorkSheetStatusId = 1 -- Open
        )
        SELECT
            WorksheetHeaderId,
            WorksheetNumber,
            TailNum,
			AircraftModel,
            MakeType,
            SerialNum,
			EngineName,
            CustomerName,
            Status,
            CreatedDate,
            TotalRecords
        FROM OpenWorksheets
        ORDER BY
            CASE WHEN @SortColumn = 'worksheetNumber' AND @SortOrder = 'ASC'  THEN WorksheetNumber END ASC,
            CASE WHEN @SortColumn = 'worksheetNumber' AND @SortOrder = 'DESC' THEN WorksheetNumber END DESC,
            CASE WHEN @SortColumn = 'createdDate'     AND @SortOrder = 'ASC'  THEN CreatedDate END ASC,
            CASE WHEN @SortColumn = 'createdDate'     AND @SortOrder = 'DESC' THEN CreatedDate END DESC,
            WorksheetHeaderId DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_GetOpenWorksheetsForAircraft',
            @ProcedureParameters VARCHAR(3000) =
                '@AircraftRegistryId = ' + ISNULL(CAST(@AircraftRegistryId AS VARCHAR(20)), 'NULL')
                + ', @IsFromAircraft = ' + ISNULL(CAST(@IsFromAircraft AS VARCHAR(5)), 'NULL')
                + ', @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL'),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected error in the database. Please provide error number %d to the support team.',
            16, 1, @ErrorLogID
        );

        RETURN 1;

    END CATCH;
END;