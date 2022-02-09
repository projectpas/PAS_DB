/*************************************************************           
 ** File:   [AutoCompleteDropdownsEmployeeByExpertise]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve  Employee List Based on Managment Structure ID  anf Jobtitle   
 ** Purpose:         
 ** Date:   02/25/2021        
          
 ** PARAMETERS:  @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/25/2021   Subhash Saliya Created
     
--EXEC [AutoCompleteDropdownsEmployeeByExpertise] '',1,200,'108,109,11',71,4
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsEmployeeByExpertise]
@Parameter3 VARCHAR(50),
@Parameter4  VARCHAR(max) = '0',
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@ManagementStructureId bigint,
@MasterCompanyId int
AS
BEGIN
	  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      SET NOCOUNT ON
	  BEGIN TRY

		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count='20';	
		END	

		IF(@ManagementStructureId > 0)
		BEGIN
			 --   SELECT DISTINCT top 50 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
				--FROM dbo.Employee E WITH(NOLOCK) INNER JOIN dbo.EmployeeManagementStructure EMS WITH(NOLOCK) 
				--ON E.EmployeeId = EMS.EmployeeId 
				--WHERE E.MasterCompanyId = @MasterCompanyId AND (E.IsActive = 1 AND E.EmployeeExpertiseId in  (SELECT Item FROM DBO.SPLITSTRING(@Parameter4, ',')) AND ISNULL(E.IsDeleted, 0) = 0 AND (EMS.ManagementStructureId = @ManagementStructureId OR E.ManagementStructureId = @ManagementStructureId) AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))
				--UNION 
				--SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
				--FROM dbo.Employee  WITH(NOLOCK)
				--WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				--ORDER BY Label	

				SELECT DISTINCT top 50 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
				FROM dbo.Employee E WITH(NOLOCK) 
				INNER JOIN dbo.EmployeeManagementStructure EMS WITH(NOLOCK) ON E.EmployeeId = EMS.EmployeeId 
				LEFT JOIN dbo.EmployeeExpertiseMapping EEMP WITH(NOLOCK) ON E.EmployeeId = EEMP.EmployeeId
				WHERE E.MasterCompanyId = @MasterCompanyId 
				AND (E.IsActive = 1 AND EEMP.EmployeeExpertiseIds in  (SELECT Item FROM DBO.SPLITSTRING(@Parameter4, ',')) 
				AND ISNULL(E.IsDeleted, 0) = 0 AND (EMS.ManagementStructureId = @ManagementStructureId OR E.ManagementStructureId = @ManagementStructureId) 
				AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))
				UNION 
				SELECT DISTINCT EmployeeId AS Value, FirstName+' '+LastName AS Label
				FROM dbo.Employee  WITH(NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label	
		END
	  END TRY 
	  BEGIN CATCH      
			    --IF @@trancount > 0
				--PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsEmployeeByExpertise'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@ManagementStructureId, '') as varchar(100))  
			   + '@Parameter6 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  	
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
              RETURN(1);
		END CATCH	  
END