
-- EXEC GetAllBankNameBasedOnEmployeeId 10
CREATE   PROCEDURE [dbo].[GetAllBankNameBasedOnEmployeeId]
@EmployeeId BIGINT = NULL,
@LegalEntityId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
		IF OBJECT_ID(N'tempdb..#tmpEmployeeUserRole') IS NOT NULL
		BEGIN
		DROP TABLE #tmpEmployeeUserRole
		END
			SELECT  DISTINCT ER.RoleId INTO #tmpEmployeeUserRole
			FROM dbo.EmployeeManagementStructureDetails MSD WITH (NOLOCK) 
			JOIN dbo.Employee E WITH(NOLOCK) ON MSD.ReferenceID = e.EmployeeId 
			INNER JOIN dbo.EmployeeUserRole ER WITH(NOLOCK) ON E.EmployeeId = ER.EmployeeId
			WHERE ER.EmployeeId = @EmployeeId;

			select DISTINCT lebl.LegalEntityBankingLockBoxId,lebl.BankName,lebl.BankAccountNumber,lebl.LegalEntityId,lebl.GLAccountId 
			from RoleManagementStructure rms WITH (NOLOCK)
			INNER JOIN EntityStructureSetup ess WITH (NOLOCK) on ess.EntityStructureId = rms.EntityStructureId
			INNER JOIN ManagementStructureLevel msl WITH (NOLOCK) on msl.ID = ess.Level1Id
			INNER JOIN LegalEntity le WITH (NOLOCK) on le.LegalEntityId = msl.LegalEntityId
			INNER JOIN LegalEntityBankingLockBox lebl WITH (NOLOCK) on lebl.LegalEntityId = le.LegalEntityId
			where RoleId IN (SELECT RoleId FROM #tmpEmployeeUserRole) AND (@LegalEntityId IS NULL OR le.LegalEntityId = @LegalEntityId)
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetAllBankNameBasedOnEmployeeId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END