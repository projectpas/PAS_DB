/***************************************************************  
** File:   [USP_GetAircraftMapped]             
** Author: Ayushi Patel  
** Description: This stored procedure is used to get Aircraft Mapping details by ItemMasterId  
** Date:   11-Aug-2025            
** PARAMETERS:  
**   @ItemMasterId  - Item Master record Id  
**   @IsDeleted     - Deleted flag  
**   @EmployeeId    - Employee Id (used for TimeZone conversion)  
** RETURN VALUE:  
**   Returns Aircraft mapping list for given ItemMasterId  
**************************************************************  
** Change History             
**************************************************************  
** PR   Date         Author          Change Description              
** --   --------     -------         --------------------------------            
** 1    11-Aug-2025  Ayushi Patel    Created SP from EF Method GetAircraftMapped  
***************************************************************/
create   PROCEDURE [dbo].[USP_GetAircraftMapped]
    @ItemMasterId BIGINT,
    @IsDeleted BIT,
    @EmployeeId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

    -- Get current employee's timezone (same as in GetAssetList)
    SELECT
        @CurrntEmpTimeZoneDesc = COALESCE(
            ETZ.[Description],  -- Employee's timezone
            LTZ.[Description]   -- Fallback to LegalEntity timezone
        )
    FROM dbo.Employee E WITH (NOLOCK)
    LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK)
        ON E.TimeZoneId = ETZ.TimeZoneId
    LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK)
        ON E.LegalEntityId = LE.LegalEntityId
    LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK)
        ON LE.TimeZoneId = LTZ.TimeZoneId
    WHERE E.EmployeeId = @EmployeeId;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT 
            iM.ItemMasterAircraftMappingId,
            iM.AircraftTypeId,
            AircraftType = ISNULL(iM.AircraftType, ''),
            iM.AircraftModelId,
            iM.DashNumberId,
            DashNumber = ISNULL(iM.DashNumber, ''),
            AircraftModel = ISNULL(iM.AircraftModel, ''),
            iM.Memo,
            iM.CreatedBy,
            iM.UpdatedBy,
            CreatedDate = CAST(DBO.ConvertUTCtoLocal(iM.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME),
            UpdatedDate = CAST(DBO.ConvertUTCtoLocal(iM.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME),
            iM.IsDeleted,
            iM.IsActive,
            iM.ATAReferenceId,
            iM.ATAReference,
            iM.Level1,
            iM.Level2,
            iM.Level3,
            ATAChapter = iM.Level1
                         + CASE WHEN ISNULL(iM.Level2, '') <> '' THEN '-' + iM.Level2 ELSE '' END
                         + CASE WHEN ISNULL(iM.Level3, '') <> '' THEN '-' + iM.Level3 ELSE '' END,
            ATAChapterId = CASE WHEN ISNULL(iM.ATAChapterId, 0) > 0 THEN iM.ATAChapterId ELSE 0 END
        FROM dbo.ItemMasterAircraftMapping iM WITH (NOLOCK)
        WHERE iM.ItemMasterId = @ItemMasterId
          AND iM.IsActive = 1
          AND iM.IsDeleted = @IsDeleted;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetAircraftMapped',
                @ProcedureParameters VARCHAR(3000) =
                    '@ItemMasterId=' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR) + ',' +
                    '@IsDeleted=' + CAST(ISNULL(@IsDeleted, 0) AS VARCHAR) + ',' +
                    '@EmployeeId=' + CAST(ISNULL(@EmployeeId, 0) AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number: %d',
                   16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END