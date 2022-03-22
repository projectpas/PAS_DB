--searchText=&startWith=true&count=20&idList=0,52&managementStructureId=7899&masterCompanyId=2
--EXEC AutoCompleteDropdownsEmployeeByMS '',1,200,'0',7899,2
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsEmployeeByRoleWise]
@Parameter3 VARCHAR(50) = Null,
@Parameter4 bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@masterCompanyId bigint,
@RoleId int
AS
BEGIN

	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON
	 BEGIN TRY

		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count = '20';	
		END	

			SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee E WITH(NOLOCK) 
			INNER JOIN dbo.EmployeeUserRole ER WITH(NOLOCK) ON E.EmployeeId = ER.EmployeeId
			--INNER JOIN dbo.RoleManagementStructure RS WITH(NOLOCK) ON RS.RoleId = ER.RoleId
			WHERE E.MasterCompanyId = @masterCompanyId AND ER.RoleId = @RoleId AND (E.IsActive = 1 AND ISNULL(E.IsDeleted, 0) = 0)
			UNION 
			SELECT DISTINCT EmployeeId AS Value,FirstName + ' ' + LastName AS Label
            FROM dbo.Employee WITH(NOLOCK)  
				WHERE EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label
	END TRY 
	BEGIN CATCH   
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsEmployeeByRoleWise' 
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))
			    + '@Parameter2 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100)) 			  
			    + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))
			    + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			    + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH	
END