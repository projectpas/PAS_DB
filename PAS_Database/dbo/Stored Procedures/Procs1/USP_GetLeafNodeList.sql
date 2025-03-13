/*************************************************************             
** File:   [USP_GetLeafNodeList]            
** Author:   Satish Gohil
** Description: This procedre is used to Leaf node list by reporting structure Id
** Purpose:           
** Date:   21/07/2023
**************************************************************             
** Change History             
**************************************************************             
** PR   Date			Author				Change Description              
** --   --------		-------				--------------------------------            
	1   21/07/2023		Satish Gohil		Created
	2   29/11/2023		Devendra Shekh		added order by AccountCode
	3   30/11/2023		Devendra Shekh		order by AccountCode issue resolved
	4   12/12/2023		Moin Bloch		    order by AccountCode issue resolved
	5   01Mar2023		Rajesh Gami			GLMapping Sequence related change
	6   05-Mar-2025     Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone 

    USP_GetLeafNodeList 1,1,226
**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetLeafNodeList](   
	@ReportingStructureId BIGINT,
	@masterCompanyId INT,
	@EmployeeId BIGINT
)
AS
BEGIN
	BEGIN TRY 
	BEGIN
						
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				)
			FROM 
				dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN 
				dbo.TimeZone ETZ WITH (NOLOCK) 
				ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN 
				dbo.LegalEntity LE WITH (NOLOCK) 
				ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN 
				dbo.TimeZone LTZ WITH (NOLOCK) 
				ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE 
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		;WITH CTE
		AS(
			SELECT 
			L.LeafNodeId,L.Name,L.ParentId,LP.Name 'ParentNodeName',
			l.IsLeafNode,GL.AccountCode + '-' + GL.AccountName 'GLAccount',
			L.MasterCompanyId,
			L.CreatedBy,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(L.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(L.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(L.CreatedDate AS DATETIME)) END CreatedDate,
			L.UpdatedBy,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(L.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(L.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(L.UpdatedDate AS DATETIME)) END UpdatedDate,
			L.ReportingStructureId,
			CASE WHEN ISNULL(GLM.GLAccountLeafNodeMappingId,0) = 0 THEN 0 ELSE glm.GLAccountLeafNodeMappingId END 'GlMappingId',
			L.IsPositive,
			L.SequenceNumber,
			ISNULL(GLM.SequenceNumber,0) GLSequenceNumber,
			GLM.IsPositive 'GlIsPositive',
			ROW_NUMBER() OVER(PARTITION BY L.Name ORDER BY(SELECT 1)) rownum,
			--ROW_NUMBER() OVER(PARTITION BY L.Name ORDER BY ISNULL(GL.AccountCode, 0)) rowSeq,
			ROW_NUMBER() OVER(PARTITION BY L.Name ORDER BY			
				CASE WHEN ISNUMERIC(GL.AccountCode) = 1 THEN CONVERT(NUMERIC,GL.AccountCode) END,               
				CASE WHEN ISNUMERIC(GL.AccountCode) = 0 THEN GL.AccountCode END )
			rowSeq,
			ROW_NUMBER() OVER(PARTITION BY L.Name ORDER BY			
				ISNULL(GLM.SequenceNumber,0))
			rowSeqGl,
			STUFF((SELECT DISTINCT ', ' + CAST(GLM.GLAccountId AS VARCHAR(50))
				FROM Dbo.LeafNode LM WITH(NOLOCK) 
				LEFT JOIN DBO.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON LM.LeafNodeId = GLM.LeafNodeId
				WHERE L.LeafNodeId = LM.LeafNodeId       
				AND GLM.IsDeleted = 0
				FOR XML PATH('')          
				), 1, 1, '')  GLAccountId,
			ISNULL(GL.AccountCode, 0) AS AccountCode,
			CASE WHEN ISNULL(GL.AccountCode, 0) LIKE '%[a-zA-Z]%' THEN 1 ELSE 0 END AS IsStringData,
		    ROW_NUMBER() OVER 
            (
            ORDER BY
                CASE WHEN ISNUMERIC(GL.AccountCode) = 1 THEN CONVERT(NUMERIC,GL.AccountCode) END,               
                CASE WHEN ISNUMERIC(GL.AccountCode) = 0 THEN GL.AccountCode END 
            ) AS GLRowNumber
			,0 AS IsMainLeafNode
			FROM dbo.LeafNode L WITH(NOLOCK)
			LEFT JOIN dbo.GLAccountLeafNodeMapping GLM WITH(NOLOCK) ON L.LeafNodeId = GLM.LeafNodeId AND GLM.IsDeleted = 0
			LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GLM.GLAccountId = GL.GLAccountId
			LEFT JOIN dbo.LeafNode LP WITH(NOLOCK) ON L.ParentId = LP.LeafNodeId
			WHERE L.MasterCompanyId = @masterCompanyId AND L.IsDeleted = 0 AND
			L.ReportingStructureId = @ReportingStructureId AND L.IsActive = 1 
			--AND (l.LeafNodeId = 156)
		)
		SELECT * INTO #LeafTempTbl FROM CTE

		UPDATE #LeafTempTbl SET IsMainLeafNode = 1 WHERE IsLeafNode = 1 AND rowSeqGl = 1
		--Select * from #LeafTempTbl
		SELECT * INTO #LeafTempTblMainLeaf FROM #LeafTempTbl WHERE IsMainLeafNode = 1

		UPDATE #LeafTempTblMainLeaf SET IsMainLeafNode = 0 WHERE IsMainLeafNode = 1 
		Update #LeafTempTbl set GLSequenceNumber = 0,GLAccount = NULL, GlMappingId = 0,GlIsPositive = NULL,AccountCode= 0
		WHERE IsMainLeafNode = 1 AND IsLeafNode = 1 AND rowSeqGl = 1 

		SELECT * INTO #FinalTempTable FROM (SELECT * FROM #LeafTempTbl UNION ALL SELECT * FROM #LeafTempTblMainLeaf) as FinalTemp
		--Select * from #FinalTempTable			
		--SELECT * FROM #LeafTempTbl
		--SELECT * FROM #LeafTempTblMainLeaf

		SELECT
			L.LeafNodeId,
			L.Name AS 'FilterName',
				CASE WHEN l.IsLeafNode = 1 THEN
						CASE l.IsMainLeafNode
							WHEN 1 THEN L.Name
							ELSE ''
						END 
			ELSE L.Name END AS 'Name',
			--CASE WHEN l.IsLeafNode = 1 THEN
			--		CASE rowSeqGl
			--			WHEN 1 THEN L.Name
			--			ELSE ''
			--		END 
			--	ELSE L.Name END AS 'Name',
			--	CASE WHEN l.IsLeafNode = 1 THEN
			--	CASE rowSeq
			--	WHEN 1 THEN L.Name
			--	ELSE ''
			--	END 
			--ELSE L.Name END
			--AS 'Old_Name',
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
			L.AccountCode,
			L.IsStringData,
			L.GLSequenceNumber,
			CASE WHEN l.IsMainLeafNode = 1 THEN
				CASE rowSeqGl
					WHEN 1 THEN 
							CASE WHEN (Select COUNT(LeafNodeId) from #FinalTempTable ct where ct.LeafNodeId = L.LeafNodeId) > 0 THEN (Select COUNT(LeafNodeId) from #FinalTempTable ct where ct.LeafNodeId = L.LeafNodeId) - 1 ELSE (Select COUNT(LeafNodeId) from #FinalTempTable ct where ct.LeafNodeId = L.LeafNodeId) END
					ELSE 0
				END 
			ELSE 0 END AS 'LeafNodeGLCount'
			,IsMainLeafNode
		FROM #FinalTempTable L
		WHERE ISNULL(l.IsLeafNode,0) = 0 OR ((ISNULL(l.IsLeafNode,0) = 1 AND ISNULL(L.GLAccount,'') != '')OR l.IsMainLeafNode = 1)
		ORDER BY L.ParentId,L.SequenceNumber,L.GLSequenceNumber--,L.GLRowNumber		
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
		, @ProcedureParameters VARCHAR(3000)  = '@MstCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS varchar(100))  
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