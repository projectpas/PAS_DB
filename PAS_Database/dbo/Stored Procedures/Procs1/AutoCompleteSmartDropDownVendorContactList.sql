
/*************************************************************           
 ** File:   [AutoCompleteSmartDropDownVendorContactList]           
 ** Author:   MOIN BLOCH
 ** Description: vendor wise contact list   
 ** Purpose:         
 ** Date:   02/23/2021      
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2021   MOIN BLOCH Created
     
EXECUTE [AutoCompleteSmartDropDownVendorContactList] 'lastname','',1,'',1,10431
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[AutoCompleteSmartDropDownVendorContactList]    
(    
@ColumnName VARCHAR(100),
@StrFilter VARCHAR(50),
@StartWith bit = true,
@Idlist VARCHAR(max) = '0',
@masterCompanyId int,
@VendorId bigint
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   
BEGIN TRY

	IF(LOWER(@ColumnName)= LOWER('firstname'))
	BEGIN
		IF(@StartWith=1)
		BEGIN
	
			SELECT DISTINCT TOP 20 C.FirstName As Label, MIN(C.ContactId) AS Value  FROM dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) 
			ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(C.firstName, '') != '' AND
					C.FirstName NOT IN (Select FirstName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (firstName LIKE @StrFilter + '%')
			GROUP BY C.FirstName

			UNION 

			SELECT DISTINCT TOP 20 FirstName As Label, MIN(C.ContactId) AS Value
			FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.ContactId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.FirstName
			ORDER BY C.FirstName	

		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 C.FirstName As Label, MIN(C.ContactId) AS Value  FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) 
			ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.IsActive = 1 AND ISNULL(C.IsDeleted,0) = 0 AND ISNULL(C.firstName, '') != '' AND
					C.FirstName NOT IN (Select FirstName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (firstName LIKE '%' + @StrFilter + '%')
			GROUP BY C.FirstName

			UNION 

			SELECT DISTINCT TOP 20 C.FirstName As Label, MIN(C.ContactId) AS Value
			FROM  dbo.Contact  C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.ContactId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.FirstName
			ORDER BY C.FirstName	
		END	
	END

	IF(LOWER(@ColumnName) = LOWER('middlename'))
	BEGIN
		IF(@StartWith=1)
		BEGIN
	
			SELECT DISTINCT TOP 20 C.MiddleName As Label, MIN(C.ContactId) AS Value FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK)
			ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(C.MiddleName, '') != '' AND
					(C.MiddleName LIKE @StrFilter + '%')
			GROUP BY C.MiddleName

			UNION 

			SELECT DISTINCT TOP 20 C.MiddleName As Label, MIN(C.ContactId) AS Value
			FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.ContactId  IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.MiddleName
			ORDER BY C.MiddleName	

		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 C.MiddleName As Label, MIN(C.ContactId) AS Value  FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(C.MiddleName, '') != '' AND
					(C.MiddleName LIKE '%' + @StrFilter + '%')
			GROUP BY C.MiddleName

			UNION 

			SELECT DISTINCT TOP 20 C.MiddleName As Label, MIN(C.ContactId) AS Value
			FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.ContactId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.MiddleName
			ORDER BY C.MiddleName	
		END	
	END

	IF(LOWER(@ColumnName)= LOWER('lastname'))
	BEGIN
		IF(@StartWith=1)
		BEGIN			

			SELECT DISTINCT TOP 20 C.LastName As Label, MIN(C.ContactId) AS Value  FROM dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK)
			ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 
			      AND ISNULL(C.LastName, '') != '' AND
				  C.LastName NOT IN (Select LastName from dbo.Contact where ContactId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (C.LastName LIKE '%' + @StrFilter + '%')
			GROUP BY C.LastName

			UNION 			
						
			SELECT DISTINCT TOP 20 LastName As Label, MIN(C.ContactId) AS Value
			FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.ContactId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.LastName
			ORDER BY C.LastName

		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 C.LastName As Label, MIN(C.ContactId) AS Value  FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) 
			ON C.ContactId = VC.ContactId
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(C.LastName,'') != '' AND
					LastName NOT IN (Select LastName from Contact where contactid IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (LastName LIKE '%' + @StrFilter + '%')
			GROUP BY C.LastName	

			UNION 

			SELECT DISTINCT TOP 20 C.LastName	 As Label, MIN(C.ContactId) AS Value
			FROM  dbo.Contact C WITH(NOLOCK) INNER JOIN dbo.VendorContact VC WITH(NOLOCK) ON C.ContactId = VC.ContactId
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.ContactId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.LastName	
			ORDER BY C.LastName		
		END	
	END
END TRY 
	BEGIN CATCH 			   
				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteSmartDropDownVendorContactList'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ColumnName, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@StrFilter, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@masterCompanyId, '') as varchar(100))  
			   + '@Parameter6 = ''' + CAST(ISNULL(@VendorId, '') as varchar(100))  	
													
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