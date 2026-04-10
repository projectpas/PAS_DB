/*************************************************************
** File:        [USP_GetAircraftInstalledPartDetails]
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
** 1    2026-03-27   Amit Ghediya   Created
** 2    2026-04-07   Amit Ghediya   Get ItemMasterId for tender stk (PN-15938)
*************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAircraftInstalledPartDetails]
(
    @PageNumber         INT,
    @PageSize           INT,
    @SortColumn         VARCHAR(50) = NULL,
    @SortOrder          INT,
    @AircraftRegistryId BIGINT = NULL,
    @MasterCompanyId    INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Use only if dirty reads are acceptable for this screen/report
    --SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @RecordFrom INT = (@PageNumber - 1) * @PageSize;

        SET @SortColumn = UPPER(ISNULL(@SortColumn, 'CREATEDDATE'));

        ;WITH Result AS
        (
            SELECT
                AIPD.AircraftInstalledPartDetailsId,
                AIPD.ATAChapterId,
                --ATAC.ATAChapterName AS AtaChapter,
				CONCAT_WS(' - ', IMAM.Level1, IMAM.Level2, IMAM.Level3) AS AtaChapter,
                AIPD.PartNumber,
                AIPD.PartDescription,
				AIPD.ItemMasterId,
				ARH.AircraftRegistryId,
				ARH.AircraftRegistryNumber,
				STK.Condition,
				STK.StockLineNumber,
				STK.ControlNumber,
				STK.SerialNumber,
				STK.StockLineId,
                AIPD.IsLLP,
                CASE
                    WHEN AIPD.IsLLP = 1 THEN 'YES'
                    ELSE 'NO'
                END AS LLP,
                AIPD.IsSerialized,
                AIPD.DateInstalled,
                AIPD.PositionCode,
                AIPD.[Hours],
                AIPD.[Minutes],
                AIPD.FlightHours,
                AIPD.Cycles,
                AIPD.Landings,
                AIPD.EngineStarts,
                AIPD.Memo,
                AIPD.CreatedDate,
                AIPD.UpdatedDate,
                UPPER(AIPD.CreatedBy) AS CreatedBy,
                UPPER(AIPD.UpdatedBy) AS UpdatedBy,
                COUNT(*) OVER () AS NumberOfItems
            FROM dbo.AircraftInstalledPartDetails AS AIPD WITH (NOLOCK)
			LEFT JOIN dbo.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON AIPD.ATAChapterId = IMAM.ItemMasterAircraftMappingId
           -- INNER JOIN dbo.ATAChapter AS ATAC WITH (NOLOCK) ON AIPD.ATAChapterId = ATAC.ATAChapterId
			INNER JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK) ON ARH.AircraftRegistryId = AIPD.AircraftRegistryId
			LEFT JOIN dbo.Stockline STK WITH (NOLOCK) ON STK.StockLineId = AIPD.StockLineId
            WHERE AIPD.AircraftRegistryId = @AircraftRegistryId AND AIPD.MasterCompanyId = @MasterCompanyId
        )
        SELECT
            AircraftInstalledPartDetailsId,
            ATAChapterId,
            AtaChapter,
            PartNumber,
            PartDescription,
			ItemMasterId,
			AircraftRegistryId,
			AircraftRegistryNumber,
			Condition,
			StockLineNumber,
			ControlNumber,
			SerialNumber,
			StockLineId,
            IsLLP,
            LLP,
            IsSerialized,
            DateInstalled,
            PositionCode,
            [Hours],
            [Minutes],
            FlightHours,
            Cycles,
            Landings,
            EngineStarts,
            Memo,
            CreatedDate,
            UpdatedDate,
            CreatedBy,
            UpdatedBy,
            NumberOfItems
        FROM Result
        ORDER BY
            CASE WHEN @SortOrder =  1 AND @SortColumn = 'ATACHAPTER'      THEN AtaChapter      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'ATACHAPTER'      THEN AtaChapter      END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'LLP'         THEN LLP         END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'LLP'         THEN LLP         END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'PARTNUMBER'      THEN PartNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PARTNUMBER'      THEN PartNumber      END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'PARTDESCRIPTION' THEN PartDescription END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION' THEN PartDescription END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'POSITIONCODE'    THEN PositionCode    END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'POSITIONCODE'    THEN PositionCode    END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'CREATEDDATE'     THEN CreatedDate     END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CREATEDDATE'     THEN CreatedDate     END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'UPDATEDDATE'     THEN UpdatedDate     END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'UPDATEDDATE'     THEN UpdatedDate     END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'DATEINSTALLED'     THEN DATEINSTALLED     END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'DATEINSTALLED'     THEN DATEINSTALLED     END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'CONDITION'      THEN Condition      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CONDITION'      THEN Condition      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'STOCKLINENUMBER'      THEN StockLineNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'STOCKLINENUMBER'      THEN StockLineNumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'CONTROLNUMBER'      THEN ControlNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CONTROLNUMBER'      THEN ControlNumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'SERIALNUMBER'      THEN SerialNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'SERIALNUMBER'      THEN SerialNumber      END DESC,

            AircraftInstalledPartDetailsId DESC
        OFFSET @RecordFrom ROWS
        FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = 'USP_GetAircraftInstalledPartDetails',
            @ProcedureParameters VARCHAR(3000),
            @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
              '@PageNumber=' + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(20))
            + ', @PageSize=' + CAST(ISNULL(@PageSize, 0) AS VARCHAR(20))
            + ', @SortColumn=' + ISNULL(@SortColumn, '')
            + ', @SortOrder=' + CAST(ISNULL(@SortOrder, 0) AS VARCHAR(20))
            + ', @AircraftRegistryId=' + CAST(ISNULL(@AircraftRegistryId, 0) AS VARCHAR(20))
            + ', @MasterCompanyId=' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20));

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