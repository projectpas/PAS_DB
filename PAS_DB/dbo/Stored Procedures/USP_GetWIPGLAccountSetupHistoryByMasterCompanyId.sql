
/*************************************************************           
 ** File:		          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To 
 ** Purpose:         
 ** Date:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 02/02/2026          Nakul Chandigra     Created 
	2	 19-02-2026		     Nakul Chandigra     ADDED ORDER BY WIPGLAccountSetupAuditId 

EXEC [dbo].[USP_GetWIPGLAccountSetupHistoryByMasterCompanyId] 3,1
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetWIPGLAccountSetupHistoryByMasterCompanyId]
@WIPGLAccountId BIGINT,
@MasterCompanyId BIGINT

AS 
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON  
BEGIN TRY

	SELECT	
		WIP.[WIPGLAccountId], 
		WC.[WIPCategory],
		VGL.[AccountName] AS [GLAccountName],
		VGL.GLAccountId,
		WIP.[CreatedBy],
		WIP.[CreatedDate],
		WIP.[UpdatedBy],
		WIP.[UpdatedDate],
		WIP.[IsActive],
		WIP.[IsDeleted]
	FROM [DBO].[WIPGLAccountSetupAudit] WIP WITH(NOLOCK)
	LEFT JOIN View_GLAccount VGL WITH (NOLOCK) ON WIP.GLAccountId = VGL.GLAccountId
	LEFT JOIN WIPCategory WC WITH (NOLOCK) ON WIP.WIPCategoryId = WC.WIPCategoryId
	WHERE WIP.MasterCompanyId = @MasterCompanyId AND WIP.WIPGLAccountId = @WIPGLAccountId
	ORDER BY WIPGLAccountSetupAuditId DESC 

END TRY    
BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetWIPGLAccountSetupHistoryByMasterCompanyId]'
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

        exec spLogException 
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters	   =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
END CATCH	
			            
END