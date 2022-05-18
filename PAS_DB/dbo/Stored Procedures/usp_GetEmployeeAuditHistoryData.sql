
/*********************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Sub Work Order Materials Issue Stockline Details>  
  
EXEC [usp_IssueSubWorkOrderMaterialsStockline] 
********************** 
** Change History 
**********************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    12/30/2021  HEMANT SALIYA    Employee History.

EXEC dbo.usp_IssueSubWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1

EXEC usp_GetEmployeeAuditHistoryData 31
**********************/ 
CREATE PROCEDURE [dbo].[usp_GetEmployeeAuditHistoryData]
@EmployeeId BIGINT
AS
BEGIN
	DECLARE @MSModuleID INT = 47; -- Employee Management Structure Module ID
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
					SELECT 
						EMP.AuditEmployeeId,
                        EMP.EmployeeId,
                        EMP.FirstName,
                        EMP.LastName,
                        EMP.MiddleName,
                        EMP.EmployeeIdAsPerPayroll,
                        EMP.StationId,
                        EMP.JobTitleId,
                        EMP.EmployeeExpertiseId,
                        EMP.DateOfBirth,
                        EMP.StartDate,
                        EMP.EmployeeCode,
                        --employeeExpertise = ext.Description,
                        Jobtitle = jt.Description,
                        EMP.Fax,
                        EMP.Email,
                        EMP.SSN,
                        EMP.LegalEntityId,
                        IsHourly = EMP.IsHourly,
                        EMP.HourlyPay,
                        EMP.EmployeeCertifyingStaff,
                        EMP.SupervisorId,
                        EMP.MasterCompanyId,
                        EMP.IsDeleted,
                        EMP.ManagementStructureId,
                        EMP.IsActive,
                        EMP.CreatedDate,
                        EMP.CreatedBy,
                        EMP.UpdatedBy,
                        EMP.UpdatedDate,
                        EMP.CurrencyId,
						EMPE.IsWorksInShop AS IsHeWorksInShop,
						CASE WHEN EMP.IsHourly = 1 THEN 'Hourly' ELSE 'Monthly' END AS PayType,
                        Company = le.Name,
						(SELECT Stuff((
						SELECT ', ' + [Description] FROM dbo.EmployeeExpertise EMPEXP WITH(NOLOCK) WHERE EMPEXP.EmployeeExpertiseId IN (SELECT Item FROM DBO.SPLITSTRING(EMP.EmployeeExpIds, ','))
						FOR XML PATH('')
						), 1, 2, '')) AS EmployeeExpertise
						--EmployeeExpertise1 = (SELECT [Description] FROM dbo.EmployeeExpertise EMPEXP WITH(NOLOCK) WHERE EMPEXP.EmployeeExpertiseId IN (SELECT Item FROM DBO.SPLITSTRING(EMP.EmployeeExpIds, ',')))
					FROM dbo.EmployeeAudit EMP WITH(NOLOCK)
					--LEFT JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON EMP.ManagementStructureId = MS.ManagementStructureId
					--INNER JOIN dbo.EmployeeManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = EMP.EmployeeId
					LEFT JOIN dbo.EmployeeExpertise EMPE WITH(NOLOCK) ON EMPE.EmployeeExpertiseId = EMP.EmployeeExpertiseId
					LEFT JOIN dbo.JobTitle  JT WITH(NOLOCK) ON JT.JobTitleId = EMP.JobTitleId
					LEFT JOIN  dbo.LegalEntity le WITH (NOLOCK) ON EMP.LegalEntityId  = le.LegalEntityId
					WHERE EMP.EmployeeId = @EmployeeId ORDER BY EMP.AuditEmployeeId DESC;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_IssueSubWorkOrderMaterialsStockline' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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