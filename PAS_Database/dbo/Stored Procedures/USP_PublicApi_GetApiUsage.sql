
---------------------------------------------------------------------------------------------
-- 3.2 Call counts per API, for one employee (@EmployeeId) or the whole company (@EmployeeId NULL).
--     Example: EXEC dbo.USP_PublicApi_GetApiUsage @MasterCompanyId = 1, @EmployeeId = 2;
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetApiUsage]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT U.[EmployeeId],
           E.[FirstName] + ' ' + E.[LastName] AS [EmployeeName],
           U.[ApiName],
           U.[TotalCalls],
           U.[SuccessCalls],
           U.[FailedCalls],
           U.[LastStatusCode],
           U.[LastCalledDate]
    FROM [dbo].[EmployeeApiUsage] U WITH (NOLOCK)
    LEFT JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = U.[EmployeeId]
    WHERE U.[MasterCompanyId] = @MasterCompanyId
      AND (@EmployeeId IS NULL OR U.[EmployeeId] = @EmployeeId)
    ORDER BY U.[EmployeeId], U.[ApiName];
END