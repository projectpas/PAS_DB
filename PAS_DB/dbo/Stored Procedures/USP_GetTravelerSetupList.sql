-----------------------------------------------------------------------------------------------------  
  
/*************************************************************             
 ** File:   [USP_GetTravelerSetupList]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA     
 ** Purpose:           
 ** Date:   12/22/2022          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    12/22/2022   Subhash Saliya  Created  
       
-- EXEC [USP_GetTravelerSetupList] 44  
**************************************************************/  
  
CREATE    PROCEDURE [dbo].[USP_GetTravelerSetupList]  
 @MasterCompanyId bigint ,  
 @Status varchar(100) , 
 @isdeleted bit
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    Declare @IsActive bit=1  
  
    IF @Status='InActive'  
       BEGIN   
        SET @IsActive=0  
       END   
       ELSE IF @Status='Active'  
       BEGIN   
        SET @IsActive=1  
       END   
       ELSE IF @Status='ALL'  
       BEGIN   
        SET @IsActive=NULL  
       END  
    SELECT [Traveler_SetupId]  
                      ,[TravelerId]  
                      ,[WorkScopeId]  
                      ,[WorkScope]  
                      ,[Version]  
       ,[ItemMasterId]  
       ,[PartNumber]  
                      ,[MasterCompanyId]  
                      ,[CreatedBy]  
                      ,[UpdatedBy]  
                      ,[CreatedDate]  
                      ,[UpdatedDate]  
                      ,[IsActive]  
                      ,[IsDeleted]  
       ,[IsVersionIncrease]  
                  FROM [dbo].[Traveler_Setup]  where IsDeleted=@isdeleted  AND (@IsActive IS NULL OR IsActive=@IsActive) and MasterCompanyId=@MasterCompanyId Order by CreatedDate desc   
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTravelerSetupList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END