/*************************************************************
 ** File:   [USP_PublicApi_GetEmployeeList]
 ** Author: Moin Bloch
 ** Description: 4.28 Employees like the PAS Employee List, oldest first. @EmployeeId is the credential employee (its roles'
 **              management structures). @EmployeeCode is exact; @IsActive NULL = active and inactive.
 **              Expertise is the employee's expertise list (EmployeeExpertiseMapping), as PAS shows it.
 **              SUPERADMIN credential employee: same rules as the PAS screen for a SUPERADMIN user (IsSuperAdmin = 1).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/employees
 ** Date:   23/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetEmployeeList] @MasterCompanyId = 1, @EmployeeId = 2, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetEmployeeList]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT,
    @PageNumber      INT,
    @PageSize        INT,
    @EmployeeCode    VARCHAR(100) = NULL,
    @IsActive        BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @MSModuleId INT = 47; -- Employee (EmployeeManagementStructureDetails.ModuleID), as in ProceEmployeeList

        -- Same check as the PAS Employee List screen: the user's roles (as PAS puts them in the login token) include SUPERADMIN.
        DECLARE @IsSuperAdmin BIT = CASE WHEN EXISTS (SELECT 1 FROM [dbo].[EmployeeUserRole] R WITH (NOLOCK)
                                                      INNER JOIN [dbo].[UserRole] UR WITH (NOLOCK) ON UR.[Id] = R.[RoleId] AND UR.[MasterCompanyId] = @MasterCompanyId
                                                      WHERE R.[EmployeeId] = @EmployeeId AND UR.[Name] = 'SUPERADMIN') THEN 1 ELSE 0 END;

        ;WITH PagedEmployee AS
        (
            SELECT E.[EmployeeId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[Employee] E WITH (NOLOCK)
            WHERE E.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(E.[IsDeleted], 0) = 0
              AND (@IsActive IS NULL OR E.[IsActive] = @IsActive)
              AND (@EmployeeCode IS NULL OR E.[EmployeeCode] = @EmployeeCode)
              AND E.[FirstName] <> 'TBD'
              AND EXISTS (SELECT 1 FROM [dbo].[EmployeeManagementStructureDetails] MSD WITH (NOLOCK)
                          WHERE MSD.[ModuleID] = @MSModuleId AND MSD.[ReferenceID] = E.[EmployeeId])
              AND EXISTS (SELECT 1 FROM [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
                          INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId] AND (EUR.[EmployeeId] = @EmployeeId OR @IsSuperAdmin = 1)
                          WHERE RMS.[EntityStructureId] = E.[ManagementStructureId])
              -- Other SUPERADMIN employees are not listed, unless the credential employee is a SUPERADMIN (as in PAS).
              AND (@IsSuperAdmin = 1
                   OR NOT EXISTS (SELECT 1 FROM [dbo].[EmployeeUserRole] SA WITH (NOLOCK)
                                  INNER JOIN [dbo].[UserRole] UR WITH (NOLOCK) ON UR.[Id] = SA.[RoleId] AND UR.[Name] = 'SUPERADMIN'
                                  WHERE SA.[EmployeeId] = E.[EmployeeId] AND E.[EmployeeId] <> @EmployeeId))
            ORDER BY E.[EmployeeId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            E.[EmployeeCode],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(E.[FirstName])), ''), NULLIF(LTRIM(RTRIM(E.[LastName])), '')) AS [EmployeeName],
            E.[StartDate],
            NULLIF(LTRIM(RTRIM(E.[Email])), '') AS [Email],
            EX.[Expertise],
            JT.[Description] AS [JobTitle],
            E.[HourlyPay] AS [HourlyRate],
            MS.[Level1Name] AS [LegalEntity],
            MS.[Level2Name] AS [BusinessUnit],
            MS.[Level3Name] AS [Division],
            MS.[Level4Name] AS [Department],
            P.[TotalRecords]
        FROM PagedEmployee P
        INNER JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = P.[EmployeeId]
        LEFT JOIN [dbo].[JobTitle] JT WITH (NOLOCK) ON JT.[JobTitleId] = E.[JobTitleId]
        OUTER APPLY (SELECT STRING_AGG(I.[Description], ', ') WITHIN GROUP (ORDER BY I.[Description]) AS [Expertise]
                     FROM [dbo].[EmployeeExpertiseMapping] M WITH (NOLOCK)
                     INNER JOIN [dbo].[EmployeeExpertise] I WITH (NOLOCK) ON I.[EmployeeExpertiseId] = M.[EmployeeExpertiseIds]
                     WHERE M.[EmployeeId] = E.[EmployeeId] AND M.[IsActive] = 1 AND M.[IsDeleted] = 0) EX
        OUTER APPLY (SELECT TOP (1) D.[Level1Name], D.[Level2Name], D.[Level3Name], D.[Level4Name]
                     FROM [dbo].[EmployeeManagementStructureDetails] D WITH (NOLOCK)
                     WHERE D.[ModuleID] = @MSModuleId AND D.[ReferenceID] = E.[EmployeeId]
                     ORDER BY D.[MSDetailsId]) MS
        ORDER BY E.[EmployeeId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetEmployeeList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@EmployeeCode, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@IsActive, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END