
/*********************           
 ** File:   [USP_GetUserDetailByUserTypePOAddress]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve User List Based on User Type for Purchage Order Addressed    
 ** Purpose:         
 ** Date:   09/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **********************           
 ** Change History           
 **********************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/23/2020   Hemant Saliya Created
     
 EXECUTE [AutoCompleteSmartDropDownContactList] 'middleName','',1,'874',1
**********************/ 
    
CREATE PROCEDURE [dbo].[AutoCompleteSmartDropDownContactList]    
(    
	@ColumnName VARCHAR(100),
	@StrFilter VARCHAR(50),
	@StartWith bit = true,
	@Idlist VARCHAR(max) = '0',
	@masterCompanyId int
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON 
BEGIN TRY

	IF(LOWER(@ColumnName)= LOWER('firstname'))
	BEGIN
		IF(@StartWith = 1)
		BEGIN
	
			SELECT DISTINCT TOP 20 FirstName As Label, MIN(ContactId) AS Value  FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(firstName, '') != '' AND
					FirstName NOT IN (Select FirstName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (firstName LIKE @StrFilter + '%')
			GROUP BY FirstName

			UNION 

			SELECT DISTINCT TOP 20 FirstName As Label, MIN(ContactId) AS Value
			FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY FirstName
			ORDER BY FirstName	
		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 FirstName As Label, MIN(ContactId) AS Value  FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(firstName, '') != '' AND
					FirstName NOT IN (Select FirstName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (firstName LIKE '%' + @StrFilter + '%')
			GROUP BY FirstName

			UNION 

			SELECT DISTINCT TOP 20 FirstName As Label, MIN(ContactId) AS Value
			FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY FirstName
			ORDER BY FirstName	
		END	
	END

	IF(LOWER(@ColumnName)= LOWER('middlename'))
	BEGIN
		IF(@StartWith=1)
		BEGIN
	
			SELECT DISTINCT TOP 20 MiddleName As Label, MIN(ContactId) AS Value  FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(MiddleName, '') != '' AND
					--MiddleName NOT IN (Select MiddleName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND 
					(MiddleName LIKE @StrFilter + '%')
			GROUP BY MiddleName

			UNION 

			SELECT DISTINCT TOP 20 MiddleName As Label, MIN(ContactId) AS Value
			FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY MiddleName
			ORDER BY MiddleName	

		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 MiddleName As Label, MIN(ContactId) AS Value  FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(MiddleName, '') != '' AND
					--MiddleName NOT IN (Select MiddleName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND 
					(MiddleName LIKE '%' + @StrFilter + '%')
			GROUP BY MiddleName

			UNION 

			SELECT DISTINCT TOP 20 MiddleName As Label, MIN(ContactId) AS Value
			FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY MiddleName
			ORDER BY MiddleName	
		END	
	END

	IF(LOWER(@ColumnName)= LOWER('lastname'))
	BEGIN
		IF(@StartWith=1)
		BEGIN
	
			SELECT DISTINCT TOP 20 LastName As Label, MIN(ContactId) AS Value  FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(LastName, '') != '' AND
					LastName NOT IN (Select LastName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (LastName LIKE @StrFilter + '%')
			GROUP BY LastName

			UNION 

			SELECT DISTINCT TOP 20 LastName As Label, MIN(ContactId) AS Value
			FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY LastName
			ORDER BY LastName	

		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 LastName As Label, MIN(ContactId) AS Value  FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND ISNULL(LastName, '') != '' AND
					LastName NOT IN (Select LastName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (LastName LIKE '%' + @StrFilter + '%')
			GROUP BY LastName

			UNION 

			SELECT DISTINCT TOP 20 LastName As Label, MIN(ContactId) AS Value
			FROM  dbo.Contact WITH(NOLOCK) 
			WHERE MasterCompanyId = @masterCompanyId AND contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY LastName
			ORDER BY LastName	
		END	
	END
END TRY 
BEGIN CATCH 			   
				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteSmartDropDownContactList'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ColumnName, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@StrFilter, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@masterCompanyId, '') as varchar(100))  	
													
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