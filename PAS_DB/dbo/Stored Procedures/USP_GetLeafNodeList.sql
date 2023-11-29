/*************************************************************             
** File:   [USP_GetLeafNodeList]            
** Author:   Satish Gohil
** Description: This procedre is used to Leaf node list by reporting structure Id
** Purpose:           
** Date:   21/07/2023
**************************************************************             
** Change History             
**************************************************************             
** PR   Date         Author			Change Description              
** --   --------     -------		--------------------------------            
	1   21/07/2023   Satish Gohil		Created
	2   29/11/2023   Devendra Shekh		added order by AccountCode

    USP_GetLeafNodeList 8,1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetLeafNodeList](   
	@ReportingStructureId BIGINT,
	@masterCompanyId INT
)
AS
BEGIN
	BEGIN TRY 
	BEGIN
		
		;WITH CTE
		AS(
			SELECT 
			L.LeafNodeId,L.Name,L.ParentId,LP.Name 'ParentNodeName',
			l.IsLeafNode,GL.AccountCode + '-' + GL.AccountName 'GLAccount',
			L.MasterCompanyId,
			L.CreatedBy,
			L.CreatedDate,
			L.UpdatedBy,
			L.UpdatedDate,
			L.ReportingStructureId,
			CASE WHEN ISNULL(GLM.GLAccountLeafNodeMappingId,0) = 0 THEN 0 ELSE glm.GLAccountLeafNodeMappingId END 'GlMappingId',
			L.IsPositive,
			L.SequenceNumber,
			GLM.IsPositive 'GlIsPositive',
			ROW_NUMBER() OVER(PARTITION BY L.Name ORDER BY(SELECT 1)) rownum,
			ROW_NUMBER() OVER(PARTITION BY L.Name ORDER BY ISNULL(GL.AccountCode, 0)) rowSeq,
			STUFF((SELECT DISTINCT ', ' + CAST(GLM.GLAccountId AS VARCHAR(50))
				FROM Dbo.LeafNode LM WITH(NOLOCK) 
				LEFT JOIN DBO.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON LM.LeafNodeId = GLM.LeafNodeId
				WHERE L.LeafNodeId = LM.LeafNodeId       
				AND GLM.IsDeleted = 0
				FOR XML PATH('')          
				), 1, 1, '')  GLAccountId,
			ISNULL(GL.AccountCode, 0) AS AccountCode
			FROM dbo.LeafNode L WITH(NOLOCK)
			LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON L.LeafNodeId = GLM.LeafNodeId AND GLM.IsDeleted = 0
			LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GLM.GLAccountId = GL.GLAccountId
			LEFT JOIN dbo.LeafNode LP ON L.ParentId = LP.LeafNodeId
			WHERE L.MasterCompanyId = @masterCompanyId AND L.IsDeleted = 0 AND
			L.ReportingStructureId = @ReportingStructureId AND L.IsActive = 1 
		)


		SELECT
			L.LeafNodeId,
			L.Name AS 'FilterName',
			CASE WHEN l.IsLeafNode = 1 THEN
				CASE rowSeq
				WHEN 1 THEN L.Name
				ELSE ''
				END 
			ELSE L.Name END
			AS 'Name',
			L.ParentId,
			L.ParentNodeName,
			l.IsLeafNode,
			L.GLAccount,
			L.MasterCompanyId,
			L.CreatedBy,
			L.CreatedDate,
			L.UpdatedBy,
			L.UpdatedDate,
			L.ReportingStructureId,
			L.GlMappingId,
			L.IsPositive,
			L.SequenceNumber,
			L.GlIsPositive,
			L.GLAccountId,
			L.AccountCode

		FROM CTE L
		ORDER BY L.ParentId,L.SequenceNumber,L.AccountCode


	END
	END TRY
	BEGIN CATCH
		SELECT        
		ERROR_NUMBER() AS ErrorNumber,        
		ERROR_STATE() AS ErrorState,        
		ERROR_SEVERITY() AS ErrorSeverity,        
		ERROR_PROCEDURE() AS ErrorProcedure,        
		ERROR_LINE() AS ErrorLine,        
		ERROR_MESSAGE() AS ErrorMessage;        
		IF @@trancount > 0        
		PRINT 'ROLLBACK'        
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		, @AdhocComments     VARCHAR(150)    = 'USP_GetLeafNodeList'         
		, @ProcedureParameters VARCHAR(3000)  = '@MstCompanyId = '''+ ISNULL(@masterCompanyId, '') + ''        
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