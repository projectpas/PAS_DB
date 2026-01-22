/*************************************************************           
 ** File:   [AutoCompleteDropdownsCertifyEmployeeByMS]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Certified Employee List Based on Managment Structure ID    
 ** Purpose:         
 ** Date:   12/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/23/2020   Hemant Saliya Created
	2    04/18/2022   Hemant Saliya Updated for MS Changes
     
--EXEC [AutoCompleteDropdownsCertifyEmployeeByMS] '',1,200,'108,109,11',71,1
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsCertifyEmployeeByMS]
@Parameter3 VARCHAR(50)= null,
@Parameter4 bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@ManagementStructureId bigint = 0,
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
			IF(@Parameter4=1)
			BEGIN		
				SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
				FROM dbo.Employee E WITH(NOLOCK) 
				INNER JOIN dbo.EmployeeUserRole EUR WITH(NOLOCK) ON E.EmployeeId = EUR.EmployeeId
				INNER JOIN dbo.RoleManagementStructure RMS WITH(NOLOCK) ON RMS.RoleId = EUR.RoleId and isnull(RMS.IsDeleted,0)=0
				--INNER JOIN dbo.EmployeeManagementStructure EMS WITH(NOLOCK) ON E.EmployeeId = EMS.EmployeeId 				
				WHERE E.MasterCompanyId = @MasterCompanyId AND (E.IsActive = 1 AND E.EmployeeCertifyingStaff = 1 AND ISNULL(E.IsDeleted, 0) = 0 AND (RMS.EntityStructureId =  @ManagementStructureId or E.ManagementStructureId = @ManagementStructureId) AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))
				UNION 
				SELECT DISTINCT  EmployeeId AS Value, FirstName + ' ' + LastName AS Label
				FROM dbo.Employee WITH(NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT top 20 E.EmployeeId AS Value, FirstName + ' ' + LastName AS Label
				FROM dbo.Employee E WITH(NOLOCK) 
				INNER JOIN dbo.EmployeeUserRole EUR WITH(NOLOCK) ON E.EmployeeId = EUR.EmployeeId
				INNER JOIN dbo.RoleManagementStructure RMS WITH(NOLOCK) ON RMS.RoleId = EUR.RoleId and isnull(RMS.IsDeleted,0)=0
				--INNER JOIN dbo.EmployeeManagementStructure EMS WITH(NOLOCK) ON E.EmployeeId = EMS.EmployeeId 
				WHERE E.MasterCompanyId = @MasterCompanyId AND E.IsActive = 1 AND E.EmployeeCertifyingStaff = 1 AND ISNULL(E.IsDeleted, 0) = 0 AND (RMS.EntityStructureId =  @ManagementStructureId or E.ManagementStructureId = @ManagementStructureId) AND FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'
				UNION 
				SELECT DISTINCT  EmployeeId AS Value,FirstName + ' ' + LastName AS Label
				FROM dbo.Employee WITH(NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label	
			END
		END
 END TRY
 BEGIN CATCH 
			-- temp table drop			
	         DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsCertifyEmployeeByMS'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))			  
			   + '@Parameter2 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100)) 			   	
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100)) 
			   + '@Parameter5 = ''' + CAST(ISNULL(@ManagementStructureId, '') as varchar(100)) 			   
			   + '@Parameter6 = ''' + CAST(ISNULL(@masterCompanyID, '') as varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);

 END CATCH
END