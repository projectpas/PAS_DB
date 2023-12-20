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
    
**************************************************************/ 

CREATE   PROCEDURE dbo.USP_GetGlAccountDetails  
(  
 @ReportingStructureId BIGINT,  
 @MasterCompanyId BIGINT  
)  
AS  
BEGIN   
 BEGIN TRY  
  
  DECLARE @GlAccountClassId VARCHAR(MAX);  
  select @GlAccountClassId = ISNULL(GlAccountClassId,0) from dbo.ReportingStructure WITH(NOLOCK) WHERE ReportingStructureId = @ReportingStructureId  
  
  select a.leafnodeid 'LeafNodeId',oc.id,UPPER(l1.Name) 'Name',UPPER(g.AccountCode) 'GlAccountCode',UPPER(g.AccountName) 'GlAccountName'  
  from dbo.GLAccountLeafNodeMapping a WITH(NOLOCK) 
  inner join (  
  select g.GLAccountid,COUNT(*) as id  
   from dbo.GLAccountLeafNodeMapping g WITH(NOLOCK) 
   inner join dbo.LeafNode l WITH(NOLOCK) on l.LeafNodeId = g.LeafNodeId and l.IsDeleted = 0  
   where l.ReportingStructureId = @ReportingStructureId and g.IsDeleted = 0  
   group by g.GLAccountId   
   having COUNT(*) > 1  
  ) oc on a.GLAccountId = oc.GLAccountId  
  inner join dbo.LeafNode l1 WITH(NOLOCK) on l1.LeafNodeId = a.LeafNodeId and l1.IsDeleted = 0  
  left join dbo.GLAccount g WITH(NOLOCK) on a.GLAccountId = g.GLAccountId  
  where l1.ReportingStructureId = @ReportingStructureId  
  and a.IsDeleted = 0
  
  select 0 'LeafNodeId',UPPER(gl.AccountCode) 'GlAccountCode',UPPER(gl.AccountName) 'GlAccountName'  
  from dbo.GLAccount gl WITH(NOLOCK)       
    INNER JOIN dbo.GLAccountClass GLC WITH(NOLOCK) ON gl.GLAccountTypeId = GLC.GLAccountClassId         
    where gl.MasterCompanyId=@MasterCompanyId  and GLC.GLAccountClassId IN(select ITEM FROM SplitString(@GlAccountClassId,','))   
	and gl.IsDeleted = 0 and gl.IsActive = 1
    AND gl.GLAccountId not in       
    (SELECT glf.GLAccountId from dbo.LeafNode L WITH(NOLOCK)    
    INNER JOIN dbo.GLAccountLeafNodeMapping glf WITH(NOLOCK) ON L.LeafNodeId = glf.LeafNodeId    
    where L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 AND glf.IsDeleted =0 AND L.GLAccountId is not null)      
  
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
     , @AdhocComments     VARCHAR(150)    = 'USP_GetDuplicateGl'     
     , @ProcedureParameters VARCHAR(3000)  = '@ReportingStructureId = '''+ ISNULL(@ReportingStructureId, '') + ''    
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