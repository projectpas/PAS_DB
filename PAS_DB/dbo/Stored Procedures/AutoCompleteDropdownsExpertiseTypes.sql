/*************************************************************           
 ** File:   [AutoCompleteDropdownsExpertiseTypes]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Expertize TypesList    
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
     
--EXEC [AutoCompleteDropdownsExpertiseTypes] '',1,200,'108,109,11'
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsExpertiseTypes]
@Parameter3 VARCHAR(50) = null,
@Parameter4 bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
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
			IF(@Parameter4=1)
			BEGIN		
				SELECT DISTINCT TOP 50 CAST(EE.EmployeeExpertiseId AS bigint) AS Value, EE.Description AS Label
				FROM dbo.EmployeeExpertise EE WITH(NOLOCK) 
				WHERE EE.MasterCompanyId = @MasterCompanyId AND (EE.IsActive = 1 AND ISNULL(EE.IsDeleted, 0) = 0 AND (EE.Description LIKE @Parameter3 + '%' OR EE.Description  LIKE '%' + @Parameter3 + '%')) --EE.IsWorksInShop = 1 AND
				UNION 
				SELECT DISTINCT  CAST(EmployeeExpertiseId AS bigint) AS Value, Description AS Label
				FROM dbo.EmployeeExpertise WITH(NOLOCK) 
				WHERE EmployeeExpertiseId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 50  CAST(EE.EmployeeExpertiseId AS bigint) AS Value, EE.Description AS Label
				FROM dbo.EmployeeExpertise EE  WITH(NOLOCK) 
				WHERE EE.MasterCompanyId = @MasterCompanyId AND Ee.IsActive = 1 AND ISNULL(Ee.IsDeleted, 0) = 0 AND EE.Description LIKE '%' + @Parameter3 + '%' OR EE.Description  LIKE '%' + @Parameter3 + '%' --AND eE.IsWorksInShop = 1
				UNION 
				SELECT DISTINCT CAST(EmployeeExpertiseId AS bigint) AS Value, Description AS Label
				FROM dbo.EmployeeExpertise WITH(NOLOCK) 
				WHERE EmployeeExpertiseId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label	
			END

	END TRY 
	BEGIN CATCH				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsExpertiseTypes'               
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