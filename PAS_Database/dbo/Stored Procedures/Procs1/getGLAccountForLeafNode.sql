

/***************************************************************************    
--EXEC [dbo].[getGLAccountForLeafNode] 1,0,1    
****************************************************************************/    
CREATE   PROCEDURE [dbo].[getGLAccountForLeafNode]    
@MasterCompanyId int,    
@GLAccountId BIGINT,
@ReportingStructureId BIGINT
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    SET NOCOUNT ON    
 BEGIN TRY    
  --BEGIN TRANSACTION    
   --BEGIN    

   DECLARE @GlAccountClassId VARCHAR(MAX) = '';
   SELECT @GlAccountClassId = ISNULL(GlAccountClassId,'') FROM ReportingStructure WHERE ReportingStructureId = @ReportingStructureId;

    select DISTINCT gl.AccountCode +' '+ gl.AccountName as [Label],gl.GLAccountId as [Value],gl.AllowManualJE,GLC.GLAccountClassName from GLAccount gl  
	INNER JOIN GLAccountClass GLC ON gl.GLAccountTypeId = GLC.GLAccountClassId   
	where gl.MasterCompanyId=@MasterCompanyId  and GLC.GLAccountClassId IN(select ITEM FROM dbo.SplitString(@GlAccountClassId,',')) AND
	gl.IsDeleted = 0
    --AND gl.GLAccountId not in (SELECT L.GLAccountId from LeafNode L where L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 AND L.GLAccountId is not null)    
    UNION    
    select DISTINCT gl.AccountCode +' '+ gl.AccountName as [Label],gl.GLAccountId as [Value],gl.AllowManualJE,GLC.GLAccountClassName  from GLAccount gl   
	INNER JOIN GLAccountClass GLC ON gl.GLAccountTypeId = GLC.GLAccountClassId   
    where gl.MasterCompanyId=@MasterCompanyId  and GLC.GLAccountClassId IN(select ITEM FROM dbo.SplitString(@GlAccountClassId,','))  
	AND gl.GLAccountId = @GLAccountId  
  END TRY        
  BEGIN CATCH          
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
               , @AdhocComments     VARCHAR(150)    = 'getGLAccountForLeafNode'     
      , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@GLAccountId, '') as varchar(100))     
              , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
              exec spLogException     
                       @DatabaseName        = @DatabaseName    
                     , @AdhocComments       = @AdhocComments    
                     , @ProcedureParameters = @ProcedureParameters    
                     , @ApplicationName     =  @ApplicationName    
                     , @ErrorLogID          = @ErrorLogID OUTPUT ;    
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
              RETURN(1);    
  END CATCH    
END