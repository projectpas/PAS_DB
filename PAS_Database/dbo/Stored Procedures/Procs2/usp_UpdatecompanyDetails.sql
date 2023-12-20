  
/*************************************************************             
 ** File:   [usp_GetcompanyDetails]             
 ** Author:   Mukesh    
 ** Description: Get Data for company Details   
 ** Purpose:           
 ** Date:   14-march-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date         Author    Change Description              
 ** --   --------     -------    --------------------------------            
  
  
**************************************************************/  
 
CREATE   PROCEDURE [dbo].[usp_UpdatecompanyDetails] 
@mastercompanyid int,
@companylogo varchar(256)='',
@Line1 varchar(50),
@Line2 varchar(50),
@City varchar(50),
@StateOrProvince varchar(50),
@PostalCode varchar(20),
@CountryId smallint,
@PhoneNumber varchar(30)
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
  
update MasterCompany 
set 
companylogo=@companylogo,
Line1=@Line1,
Line2=@Line2,
City=@City,
StateOrProvince=@StateOrProvince,
PostalCode=@PostalCode,
CountryId=@CountryId,
PhoneNumber=@PhoneNumber
where MasterCompanyId=@mastercompanyid
    COMMIT TRANSACTION  
  END TRY  
  
  BEGIN CATCH  
    ROLLBACK TRANSACTION  
  
   
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usp_UpdatecompanyDetails]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) ,  
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
  
END