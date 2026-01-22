/*********************           
 ** File:  [usp_SaveKITMasterHistory]           
 ** Author:  
 ** Description: This stored procedure is used to Update Kit Item Master Mapping 
 ** Purpose:         
 ** Date:     
          
 ** 
         
 ** RETURN VALUE:           
 **********************           
 ** Change History           
 **********************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
     
	 2   05-Sep-2023  Shrey Chandegara  Add history in kitmasterhistory
     
-- EXEC usp_SaveKITMasterHistory 629
************************/
CREATE   PROCEDURE [dbo].[usp_SaveKITMasterHistory]  
@KitId [BIGINT]   
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
  BEGIN TRANSACTION  
  BEGIN  
   
      
   INSERT INTO KitMasterHistory   
   ([KitId],[KitNumber],[ItemMasterId],[ManufacturerId],[PartNumber],[PartDescription],	[Manufacturer] ,[MasterCompanyId],[CreatedBy] ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[CustomerId],[CustomerName],[KitCost],[KitDescription],[WorkScopeId],[WorkScopeName] ,[Memo])  
   SELECT [KitId],[KitNumber],[ItemMasterId],[ManufacturerId],[PartNumber],[PartDescription],[Manufacturer],[MasterCompanyId],[CreatedBy] ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive] ,[IsDeleted],[CustomerId],[CustomerName],[KitCost],[KitDescription],[WorkScopeId],[WorkScopeName] ,[Memo]
   FROM DBO.[KitMaster]  WHERE KitId = @KitId
  
   
     
   
      
   END  
   COMMIT TRANSACTION  
   END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
                    ROLLBACK TRAN;  
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveKITMasterHistory'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''  
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