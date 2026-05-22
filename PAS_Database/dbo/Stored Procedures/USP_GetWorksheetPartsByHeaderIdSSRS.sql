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
    1    21/05/2026   Ayushi Patel         [PN-16530]Created 
    2    22/05/2026   Ayushi Patel         [PN-16544]Return SignedBy,MechBy,InspBy,MaintenanceTime
    exec USP_GetWorksheetPartsByHeaderIdSSRS 14,1
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
                ISNULL(es.FirstName,'') + CASE WHEN ISNULL(es.LastName,'') <> '' THEN ' ' + es.LastName ELSE '' END AS SignedBy,
                DefectDescription,
                MaintenanceAction,
                RIGHT('00' + CAST(WP.MaintenanceTime AS VARCHAR(2)), 2) + ' : ' + 
                RIGHT('00' + CAST(WP.MaintenanceTimeMinutes AS VARCHAR(2)), 2) AS MaintenanceTime,
                ISNULL(em.FirstName,'') + CASE WHEN ISNULL(em.LastName,'') <> '' THEN ' ' + em.LastName ELSE '' END AS MechBy,
                ISNULL(ei.FirstName,'') + CASE WHEN ISNULL(ei.LastName,'') <> '' THEN ' ' + ei.LastName ELSE '' END AS InspBy,
                wp.MasterCompanyId,
                wp.IsActive,
                wp.IsDeleted,
                wp.CreatedBy,
                wp.UpdatedBy,
                wp.CreatedDate,
                wp.UpdatedDate
            FROM dbo.WorksheetPart wp WITH(NOLOCK)
            LEFT JOIN dbo.Employee es WITH(NOLOCK) ON es.EmployeeId = wp.SignedById
            LEFT JOIN dbo.Employee em WITH(NOLOCK) ON em.EmployeeId = wp.MechBy
            LEFT JOIN dbo.Employee ei WITH(NOLOCK) ON ei.EmployeeId = wp.InspBy
            WHERE WorksheetHeaderId = @WorksheetHeaderId
              AND wp.MasterCompanyId = @MasterCompanyId
              AND ISNULL(wp.IsDeleted, 0) = 0
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
            ISNULL(NR.MechBy, '')            AS MechBy,
            ISNULL(NR.InspBy, '')            AS InspBy,
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