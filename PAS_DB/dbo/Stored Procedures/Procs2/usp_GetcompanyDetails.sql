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
 ** S NO	Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
 **	1							
 **	2		20-Jan-2025		Devendra Shekh		Added IsQuickBookEnabled to select and formatted the SP
 **	3		10-JUL-2025		Moin Bloch  		Added IsBillingMultipleMPN 
 **	4		06-MAY-2026		Moin Bloch  		Added IsXeroAccountingEnabled

 EXEC [usp_GetcompanyDetails] 20
**************************************************************/    
CREATE   PROCEDURE [dbo].[usp_GetcompanyDetails] 
@mastercompanyid int
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
  
	  SELECT	MasterCompanyId, MasterCompanyCode, CompanyName, TaxId, EmailAddress, companylogo,
				Line1, Line2, City, StateOrProvince, PostalCode, CountryId, PhoneNumber, ISNULL(IsQuickBookEnabled, 0) AS IsQuickBookEnabled, 
				ISNULL(IsBillingMultipleMPN, 0) AS IsBillingMultipleMPN, ISNULL([IsXeroAccountingEnabled], 0) AS [IsXeroAccountingEnabled]  
	  FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE MasterCompanyId = @mastercompanyid

    COMMIT TRANSACTION  
  END TRY  
  
  BEGIN CATCH  
    ROLLBACK TRANSACTION  
  
   
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usp_GetcompanyDetails]',  
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