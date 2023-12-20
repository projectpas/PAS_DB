CREATE   PROCEDURE DBO.CheckAllGlAccountLinkedWithReportingStructure
(
	@ReportingStructureId BIGINT,
	@GlAccount VARCHAR(MAX),
	@MasterCompanyId BIGINT
)
AS
BEGIN 
	BEGIN TRY
		SELECT STUFF((SELECT ','+AccountName FROM GLAccount gl  
		INNER JOIN GLAccountClass GLC ON gl.GLAccountTypeId = GLC.GLAccountClassId   
		where gl.MasterCompanyId=@MasterCompanyId  and GLC.GLAccountClassName IN('Revenue','Expense')  
		AND gl.GLAccountId not in 
		(SELECT L.GLAccountId from LeafNode L where L.ReportingStructureId = @ReportingStructureId AND L.IsDeleted = 0 AND L.GLAccountId is not null
		UNION 
		SELECT L.GLAccountId from GLAccount L where L.GLAccountId IN (SELECT ITEM FROM DBO.SplitString(@GlAccount,','))
		)FOR XML PATH('')),1,1,'') GlAccountName    
	END TRY
	BEGIN CATCH

		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
               , @AdhocComments     VARCHAR(150)    = 'CheckAllGlAccountLinkedWithReportingStructure'     
      , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReportingStructureId, '') as varchar(100))     
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