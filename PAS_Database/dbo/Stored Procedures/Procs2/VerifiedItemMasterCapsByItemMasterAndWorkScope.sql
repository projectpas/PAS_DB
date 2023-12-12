
/*************************************************************           
 ** File:   [VerifiedItemMasterCapsByItemMasterAndWorkScope]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Item Master Capes List Based On Item Master ID
 ** Purpose:         
 ** Date:   07/01/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/01/2021   Hemant Saliya Created
     
--EXEC VerifiedItemMasterCapsByItemMasterAndWorkScope 279,26,71,1
**************************************************************/

CREATE PROCEDURE [dbo].[VerifiedItemMasterCapsByItemMasterAndWorkScope]
@ItemMasterId BIGINT = '0',
@WorkScopeId BIGINT = '0',
@ManagementStructureId BIGINT = '0',
@MasterCompanyId BIGINT = '0'

AS
BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					SELECT DISTINCT TOP 20 
						@WorkScopeId AS WorkScopeId,
						WS.WorkScopeCode,
						IMC.IsVerified,
						@ItemMasterId AS ItemMasterId,
						@ManagementStructureId AS ManagementStructureId
					FROM dbo.[ItemMasterCapes] IMC WITH(NOLOCK)
						JOIN dbo.[CapabilityType] CT WITH(NOLOCK) ON IMC.CapabilityTypeId = CT.CapabilityTypeId
						JOIN dbo.[WorkScope] WS WITH(NOLOCK) on WS.WorkScopeId = CT.WorkScopeId
					WHERE (IMC.IsActive = 1 AND ISNULL(IMC.IsDeleted,0) = 0 AND (IMC.ItemMasterId = @ItemMasterId) AND (IMC.ManagementStructureId = @ManagementStructureId) AND IMC.IsVerified = 1
									AND IMC.MasterCompanyId = @MasterCompanyId AND (WS.WorkScopeId = @WorkScopeId))
					
					ORDER BY WorkScopeCode
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsWorkScopeByItemMasterCaps' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkScopeId, '') + ''',
													   @Parameter2 = ' + ISNULL(@ItemMasterId ,'') +'''
													   @Parameter3 = ' + ISNULL(@MasterCompanyId ,'') +'''
													   @Parameter4 = ' + ISNULL(@ManagementStructureId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END