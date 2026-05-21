/*************************************************************             
 ** File:   [USP_GetWorksheetPartsByHeaderIdSSRS]        
 ** Author:   
 ** Description: This stored procedure is used to get records from [WorksheetHeader].
 ** Purpose:           
 ** Date:  [14-May-2026] 
            
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    21/05/2026   Ayushi Patel            Created 
**************************************************************/


CREATE PROCEDURE [dbo].[USP_GetWorksheetPartsByHeaderIdSSRS]
    @WorksheetHeaderId BIGINT, @MasterCompanyId INT

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

        ;WITH NumberedRows AS (
            SELECT 
                ROW_NUMBER() OVER (ORDER BY WorksheetPartId) AS RowNum,
                WorksheetPartId,
                ItemNo,
                WorksheetHeaderId,
                SignedBy,
                DefectDescription,
                MaintenanceAction,
                MaintenanceTime,
                MechBy,
                InspBy,
                MasterCompanyId,
                IsActive,
                IsDeleted,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate
            FROM dbo.WorksheetPart  
            WHERE WorksheetHeaderId = @WorksheetHeaderId
              AND MasterCompanyId = @MasterCompanyId
              AND ISNULL(IsDeleted, 0) = 0
        ),
        Padding AS (
            SELECT n.number AS RowNum
            FROM (
                SELECT TOP 13 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS number
                FROM sys.objects
            ) n
        )
        SELECT
            ISNULL(NR.WorksheetPartId, 0)   AS WorksheetPartId,
            ISNULL(NR.ItemNo, '')           AS ItemNo,
            ISNULL(NR.WorksheetHeaderId, @WorksheetHeaderId) AS WorksheetHeaderId,
            ISNULL(NR.SignedBy, '')         AS SignedBy,
            ISNULL(NR.DefectDescription, '') AS DefectDescription,
            ISNULL(NR.MaintenanceAction, '') AS MaintenanceAction,
            ISNULL(NR.MaintenanceTime, '')  AS MaintenanceTime,
            ISNULL(NR.MechBy, 0)            AS MechBy,
            ISNULL(NR.InspBy, 0)            AS InspBy,
            @MasterCompanyId                AS MasterCompanyId,
            ISNULL(NR.IsActive, 1)          AS IsActive,
            ISNULL(NR.IsDeleted, 0)         AS IsDeleted,
            ISNULL(NR.CreatedBy, '')        AS CreatedBy,
            ISNULL(NR.UpdatedBy, '')        AS UpdatedBy,
            ISNULL(NR.CreatedDate, GETDATE()) AS CreatedDate,
            ISNULL(NR.UpdatedDate, GETDATE()) AS UpdatedDate
        FROM Padding P
        LEFT JOIN NumberedRows NR ON P.RowNum = NR.RowNum
        ORDER BY P.RowNum;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID          INT,
                @DatabaseName        VARCHAR(100) = DB_NAME(),
                @AdhocComments       VARCHAR(150) = 'USP_GetWorksheetPartsByHeaderId',
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