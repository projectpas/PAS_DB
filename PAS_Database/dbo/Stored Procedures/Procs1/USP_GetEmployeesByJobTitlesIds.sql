﻿CREATE PROCEDURE [dbo].[USP_GetEmployeesByJobTitlesIds] 
(
	@JobTitleIds varchar(50)
)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY

    --SELECT
    --  EMP.EmployeeId AS employeeId,
    --  EMP.EmployeeExpertiseId AS EmployeeExpertiseId,
    --  EMP.EmployeeCode AS employeeCode,
    --  EMP.FirstName + ' ' + EMP.LastName AS [name]
    --FROM Employee EMP WITH (NOLOCK)
    --WHERE EMP.isDeleted = 0
    --AND EMP.IsActive = 1
    --AND EMP.EmployeeExpertiseId IN (SELECT
    --  Item
    --FROM DBO.SPLITSTRING(@JobTitleIds, ','))
    --ORDER BY EMP.FirstName

	SELECT
      EMP.EmployeeId AS employeeId,
      EEMP.EmployeeExpertiseIds AS EmployeeExpertiseId,
      EMP.EmployeeCode AS employeeCode,
      EMP.FirstName + ' ' + EMP.LastName AS [name]
    FROM Employee EMP WITH (NOLOCK)
	LEFT JOIN EmployeeExpertiseMapping EEMP WITH (NOLOCK) ON EMP.EmployeeId = EEMP.EmployeeId
    WHERE EMP.isDeleted = 0
    AND EMP.IsActive = 1
    AND EEMP.EmployeeExpertiseIds IN (SELECT
      Item
    FROM DBO.SPLITSTRING(@JobTitleIds, ','))
    ORDER BY EMP.FirstName
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetEmployeesByJobTitlesIds]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@JobTitleIds, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END