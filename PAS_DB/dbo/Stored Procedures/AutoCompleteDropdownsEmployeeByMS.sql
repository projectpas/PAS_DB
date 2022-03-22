--select * from dbo.Employee
--EXEC AutoCompleteDropdowns 'Employee','EmployeeId','FirstName','sur',1,20,'108,109,11'
--select * from dbo.Customer
--EXEC [AutoCompleteDropdownsEmployeeByMS] '',1,20,'108,109,11',86
--EXEC AutoCompleteDropdowns 'Customer','CustomerId','Name','',0,5,'102,43'
--EXEC AutoCompleteDropdowns 'Customer','CustomerId','Name','',1,'50'

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsEmployeeByMS]
@Parameter3 VARCHAR(50) = Null,
@Parameter4 bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@ManagementStructureId bigint = 0,
@masterCompanyId bigint

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

		IF(@ManagementStructureId > 0)
		BEGIN
		IF(@Parameter4 = 1)
		BEGIN		
			SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee E WITH(NOLOCK) INNER JOIN dbo.EmployeeManagementStructure EMS WITH(NOLOCK)  
			  ON E.EmployeeId = EMS.EmployeeId AND EMS.ManagementStructureId = @ManagementStructureId
			WHERE E.MasterCompanyId = @masterCompanyId AND (E.IsActive = 1 AND ISNULL(E.IsDeleted, 0) = 0 AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))
			UNION 
			SELECT DISTINCT EmployeeId AS Value,FirstName + ' ' + LastName AS Label
            FROM dbo.Employee WITH(NOLOCK)  
				WHERE EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label				
		END
		ELSE
		BEGIN
			SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee E WITH(NOLOCK)  INNER JOIN dbo.EmployeeManagementStructure EMS  WITH(NOLOCK) 
			  ON E.EmployeeId = EMS.EmployeeId AND EMS.ManagementStructureId = @ManagementStructureId
			WHERE E.MasterCompanyId = @masterCompanyId AND E.IsActive = 1 AND ISNULL(E.IsDeleted, 0) = 0 AND FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'
			UNION 
			SELECT DISTINCT  EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee WITH(NOLOCK) 
				WHERE EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label	
		END
		END
		ELSE
		BEGIN
		IF(@Parameter4 = 1)
		BEGIN		
			SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee E WITH(NOLOCK) 
			WHERE E.MasterCompanyId = @masterCompanyId AND (E.IsActive = 1 AND ISNULL(E.IsDeleted, 0) = 0 AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))
			UNION 
			SELECT DISTINCT  EmployeeId AS Value,FirstName + ' ' + LastName AS Label
            FROM dbo.Employee  WITH(NOLOCK) 
				WHERE EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label				
		END
		ELSE
		BEGIN
			SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee E WITH(NOLOCK) 
			WHERE E.MasterCompanyId = @masterCompanyId AND E.IsActive=1 AND ISNULL(E.IsDeleted, 0) = 0 AND FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'
			UNION 
			SELECT DISTINCT EmployeeId AS Value, FirstName + ' ' + LastName AS Label
            FROM dbo.Employee WITH(NOLOCK) 
				WHERE EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label	
		END
		END		
	END TRY 
	BEGIN CATCH   
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsEmployeeByMS' 
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