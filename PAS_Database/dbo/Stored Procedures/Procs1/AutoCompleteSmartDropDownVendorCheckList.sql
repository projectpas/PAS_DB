
/*************************************************************           
 ** File:   [AutoCompleteSmartDropDownVendorCheckList]           
 ** Author:   MOIN BLOCH
 ** Description: vendor wise check contact list   
 ** Purpose:         
 ** Date:   02/23/2021      
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/04/2021   MOIN BLOCH Created
     
EXECUTE [AutoCompleteSmartDropDownVendorCheckList] 'sitename','',1,'',1,1
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[AutoCompleteSmartDropDownVendorCheckList]    
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

	IF(LOWER(@ColumnName)= LOWER('sitename'))
	BEGIN
		IF(@StartWith=1)
		BEGIN
	
			SELECT DISTINCT TOP 20 C.SiteName As Label, MIN(C.CheckPaymentId) AS Value  FROM dbo.CheckPayment 
			C WITH(NOLOCK) INNER JOIN dbo.VendorCheckPayment VC WITH(NOLOCK)
			ON C.CheckPaymentId = VC.CheckPaymentId
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND 
					C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(C.SiteName, '') != '' AND
					C.SiteName NOT IN (Select SiteName from CheckPayment where CheckPaymentId IN 
					(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND (SiteName LIKE @StrFilter + '%')
			GROUP BY C.SiteName

			UNION 

			SELECT DISTINCT TOP 20 C.SiteName As Label, MIN(C.CheckPaymentId) AS Value
			FROM  dbo.CheckPayment C WITH(NOLOCK) INNER JOIN dbo.VendorCheckPayment VC WITH(NOLOCK) ON C.CheckPaymentId = VC.CheckPaymentId 
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND C.CheckPaymentId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.SiteName
			ORDER BY C.SiteName	

		END	
		ELSE
		BEGIN
	
			SELECT DISTINCT TOP 20 C.SiteName As Label, MIN(C.CheckPaymentId) AS Value  FROM  dbo.CheckPayment C  WITH(NOLOCK)
			INNER JOIN dbo.VendorCheckPayment VC WITH(NOLOCK)
			ON C.CheckPaymentId = VC.CheckPaymentId
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId 
			  AND C.IsActive = 1 AND ISNULL(C.IsDeleted, 0) = 0 AND ISNULL(C.SiteName, '') != '' AND
					C.SiteName NOT IN (Select SiteName from CheckPayment where CheckPaymentId IN 
					(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ) AND 
					(SiteName LIKE '%' + @StrFilter + '%')
			GROUP BY C.SiteName

			UNION 

			SELECT DISTINCT TOP 20 C.SiteName As Label, MIN(C.CheckPaymentId) AS Value
			FROM  dbo.CheckPayment  C WITH(NOLOCK) INNER JOIN dbo.VendorCheckPayment VC  WITH(NOLOCK)
			ON C.CheckPaymentId = VC.CheckPaymentId
			WHERE C.MasterCompanyId = @masterCompanyId AND VC.VendorId = @VendorId AND 
			C.CheckPaymentId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
			GROUP BY C.SiteName
			ORDER BY C.SiteName	
		END	
	END

END TRY 
	BEGIN CATCH 			   
				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteSmartDropDownVendorCheckList'               
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
                     , @ErrorLogID             = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH		
END