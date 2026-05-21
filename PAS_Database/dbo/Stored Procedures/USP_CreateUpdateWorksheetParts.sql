/*************************************************************             
 ** File:   [USP_CreateUpdateWorksheetParts]          
 ** Author:   
 ** Description: This stored procedure is used to Create/Update a record in [WorksheetParts].
 ** Purpose:           
 ** Date:  [14-May-2026] 
            
 ** PARAMETERS:             
 @tbl_WorksheetHeaderType WorksheetHeaderTableType     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date          Author            Change Description              
 ** --   --------      -------           --------------------------------     
    1    14/05/2026    Priyansh Patel    Created [PN-16408]
    2    14/05/2026    Priyansh Patel    Added SignById [PN-16520]

**************************************************************/

CREATE PROCEDURE [dbo].[USP_CreateUpdateWorksheetParts]
    @tbl_WorksheetPartType dbo.WorksheetPartTableType READONLY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

        DECLARE @WorksheetHeaderId BIGINT = (SELECT TOP 1 WorksheetHeaderId FROM @tbl_WorksheetPartType);

        IF (
            EXISTS (
                SELECT 1 FROM [dbo].[WorksheetHeader] WITH (NOLOCK)
                WHERE  WorksheetHeaderId = @WorksheetHeaderId
                  AND  IsDeleted = 0
                  AND  IsActive  = 1
            )
            AND NOT EXISTS (
                SELECT 1 FROM @tbl_WorksheetPartType
                WHERE WorksheetHeaderId != @WorksheetHeaderId
            )
            AND (SELECT COUNT(DISTINCT MasterCompanyId) FROM @tbl_WorksheetPartType) = 1
            AND NOT EXISTS (
                SELECT 1
                FROM @tbl_WorksheetPartType T
                INNER JOIN [dbo].[WorksheetPart] WP ON WP.WorksheetPartId = T.WorksheetPartId
                WHERE ISNULL(T.WorksheetPartId, 0) > 0
                  AND WP.WorksheetHeaderId != @WorksheetHeaderId
            )
        )
        BEGIN

            BEGIN TRANSACTION;

                -- UPDATE existing rows
                UPDATE WP
                SET
                    WP.ItemNo            = T.ItemNo,
                    WP.SignedBy          = T.SignedBy,
                    WP.SignedById          = T.SignedById,
                    WP.DefectDescription = T.DefectDescription,
                    WP.MaintenanceAction = T.MaintenanceAction,
                    WP.MaintenanceTime   = T.MaintenanceTime,
                    WP.MaintenanceTimeMinutes   = T.MaintenanceTimeMinutes,
                    WP.MechBy            = T.MechBy,
                    WP.InspBy            = T.InspBy,
                    WP.IsActive          = ISNULL(T.IsActive,  WP.IsActive),
                    WP.IsDeleted         = ISNULL(T.IsDeleted, WP.IsDeleted),
                    WP.UpdatedBy         = T.UpdatedBy,
                    WP.UpdatedDate       = GETUTCDATE()
                FROM [dbo].[WorksheetPart] WP
                INNER JOIN @tbl_WorksheetPartType T
                    ON WP.WorksheetPartId = T.WorksheetPartId
                WHERE ISNULL(T.WorksheetPartId, 0) > 0;

                -- INSERT new rows
                INSERT INTO [dbo].[WorksheetPart]
                (
                    WorksheetHeaderId,
                    ItemNo,
                    SignedBy,
                    SignedById,
                    DefectDescription,
                    MaintenanceAction,
                    MaintenanceTime,
                    MaintenanceTimeMinutes,
                    MechBy,
                    InspBy,
                    IsActive,
                    IsDeleted,
                    MasterCompanyId,
                    CreatedBy,
                    UpdatedBy,
                    CreatedDate,
                    UpdatedDate
                )
                SELECT
                    T.WorksheetHeaderId,
                    T.ItemNo,
                    T.SignedBy,
                    T.SignedById,
                    T.DefectDescription,
                    T.MaintenanceAction,
                    T.MaintenanceTime,
                    T.MaintenanceTimeMinutes,
                    T.MechBy,
                    T.InspBy,
                    ISNULL(T.IsActive,  1),
                    ISNULL(T.IsDeleted, 0),
                    T.MasterCompanyId,
                    T.CreatedBy,
                    T.UpdatedBy,
                    GETUTCDATE(),
                    GETUTCDATE()
                FROM @tbl_WorksheetPartType T
                WHERE ISNULL(T.WorksheetPartId, 0) = 0;

            COMMIT TRANSACTION;

            -- Return all parts for this header
            SELECT *
            FROM   [dbo].[WorksheetPart] WITH (NOLOCK)
            WHERE  WorksheetHeaderId = @WorksheetHeaderId
              AND  IsDeleted = 0
            ORDER BY WorksheetPartId ASC;

        END
        ELSE
        BEGIN
            SELECT 0 AS Status, 'Validation failed. Please check WorksheetHeaderId, MasterCompanyId, and WorksheetPartIds.' AS Message;
        END

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID          INT,
                @DatabaseName        VARCHAR(100) = DB_NAME(),
                @AdhocComments       VARCHAR(150) = 'USP_CreateUpdateWorksheetParts',
                @ProcedureParameters VARCHAR(3000) = '@WorksheetHeaderId = ' + ISNULL(CAST(@WorksheetHeaderId AS VARCHAR(20)), 'NULL'),
                @ApplicationName     VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);
    END CATCH
END