/*************************************************************           
 ** File:   [USP_GetGLAccountDetailsByID]          
 ** Author:   Bhargav Saliya
 ** Description: This stored procedure is used to Get  Get GLAccount Detail by ID
 ** JIRA ID: [PN-16035]
 ** Purpose:         
 ** Date:   15/04/2026
          
 ** PARAMETERS:
 
 ** RETURN VALUE:

 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    15/04/2026   Bhargav Saliya		Created
     
**************************************************************/ 
CREATE   PROCEDURE dbo.[USP_GetGLAccountDetailsByID]
    @GLAccountId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON    
	BEGIN TRY
	 BEGIN TRANSACTION
		BEGIN
			SELECT 
				gl.GLAccountId,
				gl.LedgerName,
				ISNULL(lg.LedgerId, 0) AS LedgerId,
				gl.OldAccountCode,
				gl.AccountCode,
				gl.AccountName,
				gl.GLAccountTypeId,
				glclas.GLAccountClassName,
				gl.AccountDescription,
				gl.GLAccountNodeId,
				NdType.Name AS nodeTypeName,
				gl.InterCompany,
				gl.Category1099Id,
				gl.Threshold,
				glcat.Name,
				gl.AllowManualJE,
				gl.GLClassFlowClassificationId,
				glclss.GLClassFlowClassificationName,
				gl.POROCategoryId,
				glpo.CategoryName,
				gl.IsActive,
				gl.IsDeleted,
				gl.CreatedBy,
				gl.UpdatedBy,
				gl.CreatedDate,
				gl.UpdatedDate,
				gl.IsManualJEReference,
				gl.ReferenceTypeId,
				gl.SubLedgerId,
				ISNULL(subgl.Code,'') AS SubledgerCode,
				ISNULL(subgl.Name,'') AS SubledgerName,
				CASE WHEN gl.ReferenceTypeId = 1 THEN 'Customer'
					WHEN gl.ReferenceTypeId = 2 THEN 'Vendor'
				ELSE ''
				END AS ReferenceType
			INTO #Main
			FROM [dbo].[GLAccount] gl WITH(NOLOCK)
			LEFT JOIN [dbo].[GLAccountClass] glclas WITH(NOLOCK) ON gl.GLAccountTypeId = glclas.GLAccountClassId
			LEFT JOIN [dbo].[Ledger] lg WITH(NOLOCK) ON gl.LedgerId = lg.LedgerId
			LEFT JOIN [dbo].[LeafNode] NdType WITH(NOLOCK) ON gl.GLAccountNodeId = NdType.LeafNodeId
			LEFT JOIN [dbo].[Master1099] glcat WITH(NOLOCK) ON gl.Category1099Id = glcat.Master1099Id
			LEFT JOIN [dbo].[GLCashFlowClassification] glclss WITH(NOLOCK) ON gl.GLClassFlowClassificationId = glclss.GlClassFlowClassificationId
			LEFT JOIN [dbo].[SubLedger] subgl WITH(NOLOCK) ON gl.SubLedgerId = subgl.SubLedgerId
			LEFT JOIN [dbo].[POROCategory] glpo WITH(NOLOCK) ON gl.POROCategoryId = glpo.POROCategoryId
			WHERE gl.GLAccountId = @GLAccountId;

			SELECT 
				mp.GlAccountId,
				le.LegalEntityId,
				le.Name
			INTO #Entity
			FROM GLAccountEntitiesMapping mp
			INNER JOIN LegalEntity le ON mp.EntitiesId = le.LegalEntityId
			WHERE mp.GlAccountId = @GLAccountId;

			SELECT 
				mp.GlAccountId,
				l.LedgerId,
				l.LedgerName
			INTO #Ledger
			FROM GLAccountLadgerMapping mp
			INNER JOIN Ledger l ON mp.LedgerId = l.LedgerId
			WHERE mp.GlAccountId = @GLAccountId;


			SELECT 
				m.*,
				EntityIds = STRING_AGG(CAST(e.LegalEntityId AS VARCHAR), ','),
				EntityNames = STRING_AGG(e.Name, ','),
				LedgerIds = STRING_AGG(CAST(l.LedgerId AS VARCHAR), ','),
				LedgerNames = STRING_AGG(l.LedgerName, ',')
			FROM #Main m
			LEFT JOIN #Entity e ON m.GLAccountId = e.GlAccountId
			LEFT JOIN #Ledger l ON m.GLAccountId = l.GlAccountId
			GROUP BY 
				m.GLAccountId,
				m.LedgerName,
				m.LedgerId,
				m.OldAccountCode,
				m.AccountCode,
				m.AccountName,
				m.GLAccountTypeId,
				m.GLAccountClassName,
				m.AccountDescription,
				m.GLAccountNodeId,
				m.nodeTypeName,
				m.InterCompany,
				m.Category1099Id,
				m.Threshold,
				m.Name,
				m.AllowManualJE,
				m.GLClassFlowClassificationId,
				m.GLClassFlowClassificationName,
				m.POROCategoryId,
				m.CategoryName,
				m.IsActive,
				m.IsDeleted,
				m.CreatedBy,
				m.UpdatedBy,
				m.CreatedDate,
				m.UpdatedDate,
				m.IsManualJEReference,
				m.ReferenceTypeId,
				m.SubLedgerId,
				m.SubledgerCode,
				m.SubledgerName,
				m.ReferenceType;

			DROP TABLE #Main;
			DROP TABLE #Entity;
			DROP TABLE #Ledger;
		END
	 COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
			IF @@trancount > 0
				PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
			DECLARE @ErrorLogID int,
			@DatabaseName varchar(100) = DB_NAME()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments varchar(150) = 'USP_GetGLAccountDetailsByID',
			@ProcedureParameters varchar(3000) = '@GLAccountId = ''' + CAST(ISNULL(@GLAccountId, '') AS varchar(100)),
			@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END