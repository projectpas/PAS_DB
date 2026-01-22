
/*************************************************************           
 ** File:   [AutoCompleteDropdownsWorkScopeByItemMasterCaps]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Item Master Capes List Based On Item Master ID
 ** Purpose:         
 ** Date:   07/01/2021        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/01/2021   Hemant Saliya Created
     
--EXEC [AutoCompleteDropdownsWorkScopeByItemMasterCaps] '',1,200,'108,109,11'
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsWorkScopeByItemMasterCaps]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@itemmasterid bigint = '0',
@MasterCompanyId bigint = '0',
@ManagementStructureId bigint = '0'

AS
BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					DECLARE @Sql NVARCHAR(MAX);	
					IF(@Count = '0') 
					   BEGIN
					   set @Count = '20';	
					END	
					SELECT DISTINCT TOP 20 
						WS.WorkScopeId as value,
						WS.WorkScopeCode as label
					FROM dbo.[WorkScope] WS WITH(NOLOCK)
						JOIN dbo.[CapabilityType] CT WITH(NOLOCK) ON CT.WorkScopeId = WS.WorkScopeId
						JOIN dbo.[ItemMasterCapes] IMC WITH(NOLOCK) on IMC.CapabilityTypeId = CT.CapabilityTypeId
					WHERE (WS.IsActive = 1 AND ISNULL(WS.IsDeleted, 0) = 0 AND (IMC.ItemMasterId = @itemmasterid) AND (IMC.ManagementStructureId = @ManagementStructureId) AND IMC.IsVerified = 1
									AND (WS.WorkScopeCode LIKE @StartWith + '%'))
					UNION     
					SELECT DISTINCT  
						WS.WorkScopeId as value,
						WS.WorkScopeCode as label
					FROM dbo.[WorkScope] WS WITH(NOLOCK)
					WHERE WS.WorkScopeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StartWith, '') + ''',
													   @Parameter2 = ' + ISNULL(@itemmasterid ,'') +''
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