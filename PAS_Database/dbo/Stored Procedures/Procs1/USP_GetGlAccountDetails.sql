/*************************************************************             
** File:   [USP_GetGlAccountDetails]            
** Author:   Satish Gohil
** Description: This procedre is used to display GL Account List
** Purpose:           
** Date:   21/07/2023
**************************************************************             
** Change History             
**************************************************************             
** PR   Date         Author			Change Description              
** --   --------     -------		--------------------------------            
	1   21/07/2023   Satish Gohil	Modify(ISdeleted Filter added)
	2   08/08/2023   Satish Gohil	Modify(ISdeleted Filter added for duplicatew validation)
	3   16/08/2023   Satish Gohil	Modify(ISdeleted Filter added for gl account list)
	4   12/01/2025   Moin Bloch	    Modify(Fix For GL Account Validate)

	EXEC [dbo].[USP_GetGlAccountDetails]  44,14
    
**************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_GetGlAccountDetails]
(  
 @ReportingStructureId BIGINT,  
 @MasterCompanyId BIGINT  
)  
AS  
BEGIN   
 BEGIN TRY  
  
  DECLARE @GlAccountClassId VARCHAR(MAX);  
  select @GlAccountClassId = ISNULL(GlAccountClassId,0) FROM [dbo].[ReportingStructure] WITH(NOLOCK) WHERE [ReportingStructureId] = @ReportingStructureId  
  
  SELECT a.leafnodeid 'LeafNodeId',
         oc.id,
		 UPPER(l1.Name) 'Name',
		 UPPER(g.AccountCode) 'GlAccountCode',
		 UPPER(g.AccountName) 'GlAccountName'  
  FROM [dbo].[GLAccountLeafNodeMapping] a WITH(NOLOCK) 
  INNER JOIN (  
  SELECT g.GLAccountid,
        COUNT(*) AS id  
   FROM [dbo].[GLAccountLeafNodeMapping] g WITH(NOLOCK) 
   INNER JOIN [dbo].[LeafNode] l WITH(NOLOCK) ON l.LeafNodeId = g.LeafNodeId AND l.IsDeleted = 0  
   WHERE l.ReportingStructureId = @ReportingStructureId AND g.IsDeleted = 0  
   GROUP BY g.GLAccountId   
   HAVING COUNT(*) > 1  
  ) oc ON a.GLAccountId = oc.GLAccountId  
  INNER JOIN [dbo].[LeafNode] l1 WITH(NOLOCK) ON l1.LeafNodeId = a.LeafNodeId AND l1.IsDeleted = 0  
   LEFT JOIN [dbo].[GLAccount] g WITH(NOLOCK) ON a.GLAccountId = g.GLAccountId  
  WHERE l1.ReportingStructureId = @ReportingStructureId  
  AND a.IsDeleted = 0
  
  SELECT 0 'LeafNodeId',
          UPPER(gl.AccountCode) 'GlAccountCode',
		  UPPER(gl.AccountName) 'GlAccountName'  
     FROM [dbo].[GLAccount] gl WITH(NOLOCK)       
    INNER JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON gl.GLAccountTypeId = GLC.GLAccountClassId         
    WHERE gl.MasterCompanyId=@MasterCompanyId AND GLC.GLAccountClassId IN(SELECT ITEM FROM SplitString(@GlAccountClassId,','))   
	AND gl.IsDeleted = 0 AND gl.IsActive = 1
    AND gl.GLAccountId NOT IN       
    (SELECT glf.GLAccountId FROM [dbo].[LeafNode] L WITH(NOLOCK)    
    INNER JOIN [dbo].[GLAccountLeafNodeMapping] glf WITH(NOLOCK) ON L.LeafNodeId = glf.LeafNodeId    
    WHERE L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 AND glf.IsDeleted = 0 )--AND L.GLAccountId is not null)      
  
 END TRY  
 BEGIN CATCH  
  SELECT    
  ERROR_NUMBER() AS ErrorNumber,    
  ERROR_STATE() AS ErrorState,    
  ERROR_SEVERITY() AS ErrorSeverity,    
  ERROR_PROCEDURE() AS ErrorProcedure,    
  ERROR_LINE() AS ErrorLine,    
  ERROR_MESSAGE() AS ErrorMessage;    
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
     , @AdhocComments     VARCHAR(150)    = 'USP_GetGlAccountDetails'     
	 , @ProcedureParameters VARCHAR(3000)  = '@ReportingStructureId = ''' + CAST(ISNULL(@ReportingStructureId, '') AS VARCHAR(100)) 
     , @ApplicationName VARCHAR(100) = 'PAS'    
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
   exec spLogException     
     @DatabaseName           = @DatabaseName    
     , @AdhocComments          = @AdhocComments    
     , @ProcedureParameters = @ProcedureParameters    
     , @ApplicationName        =  @ApplicationName    
     , @ErrorLogID             = @ErrorLogID OUTPUT ;    
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
   RETURN(1);   
 END CATCH  
   
END