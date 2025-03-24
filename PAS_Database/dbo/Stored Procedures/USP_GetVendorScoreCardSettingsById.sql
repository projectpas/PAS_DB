/***************************************************************************************          
 ** File:   [USP_GetVendorScoreCardSettingsById]            
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get JournalBatchDetailsById for PO List
 ** Purpose:           
 ** Date:   21-Mar-2025   
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    21-Mar-2025    Bhargav Saliya		Created  

********************************************************************************/   
Create     PROCEDURE [dbo].[USP_GetVendorScoreCardSettingsById]    
@MasterCompanyId bigint,
@VendorScoreCardSettingsId bigint
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY      
   BEGIN   
		SELECT VSC.[VendorScoreCardSettingsId]
			,VSC.[Rating] 
			,VSC.[OnTimeDelivery]  
			,VSC.[Description]  
			,VSC.[StatusId]  
			,VSC.[MasterCompanyId]  
			,VSC.[CreatedBy] 
			,VSC.[UpdatedBy] 
			,VSC.[CreatedDate]
			,VSC.[UpdatedDate]
			,VSC.[IsActive]  
			,VSC.[IsDeleted]  
		FROM [dbo].[VendorScoreCardSettings] VSC WITH(NOLOCK)  
		WHERE VSC.[MasterCompanyId] = @MasterCompanyId  and VSC.[VendorScoreCardSettingsId] = @VendorScoreCardSettingsId
	order by VSC.[VendorScoreCardSettingsId] desc
	
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorScoreCardSettingsById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''    
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