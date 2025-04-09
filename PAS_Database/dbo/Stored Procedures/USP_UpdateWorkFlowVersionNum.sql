/***************************************************************  
 ** File:   [USP_UpdateWorkFlowVersionNum]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used TO generate Uppdated Workflow Version Number
 ** Date:   09-April-2025

 ** Change History
 **************************************************************
 ** PR   Date				Author  					Change Description
 ** --   --------			-------					--------------------------------
    1    09-April-2025	   Devendra Shekh				Created

DECLARE @NewVersion VARCHAR(20) = '';
EXEC [USP_UpdateWorkFlowVersionNum] 1, 'VER-0001', @NewVersion OUTPUT  
SELECT @NewVersion
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWorkFlowVersionNum]
	@MasterCompanyId INT = 0,
	@VersionNum VARCHAR(10) = '',
	@NewVersion VARCHAR(10) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		
		DECLARE @versionNo INT = 1;
		DECLARE @IdCodeTypeId BIGINT;
		DECLARE @CodePrefix VARCHAR(10) = '';
		DECLARE @CodeSufix VARCHAR(10) = '';

		SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'Version';
		    			
		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixes
		END
	
		CREATE TABLE #tmpCodePrefixes
		(
			ID BIGINT NOT NULL IDENTITY, 
			CodePrefixId BIGINT NULL,
			CodeTypeId BIGINT NULL,
			CodePrefix VARCHAR(50) NULL,
			CodeSufix VARCHAR(50) NULL,
		)

		INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId, CodePrefix, CodeSufix) 
		SELECT TOP 1 CodePrefixId, CP.CodeTypeId, CodePrefix, CodeSufix 
		FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId = @IdCodeTypeId
		--AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;		

		SET @NewVersion = @VersionNum;
		IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
		BEGIN

			IF(ISNULL(@VersionNum, '') <> '')
			BEGIN
				SET @versionNo = (CAST(RIGHT(@VersionNum, LEN(@VersionNum) - CHARINDEX('-', @VersionNum)) AS INT)) + 1
			END

			SELECT @CodePrefix = CodePrefix, @CodeSufix = CodeSufix	FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					
			SET @NewVersion = (SELECT * FROM dbo.[udfGenerateCodeNumber](@versionNo, ISNULL(@CodePrefix, 'V'), ISNULL(@CodeSufix, '')))
		END
	 
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
		@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments varchar(150) = 'USP_UpdateWorkFlowVersionNum',
		@ProcedureParameters varchar(3000) = '@VersionNum = ''' + ISNULL(@VersionNum, ''),
		@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		EXEC	spLogException @DatabaseName = @DatabaseName,
				@AdhocComments = @AdhocComments,
				@ProcedureParameters = @ProcedureParameters,
				@ApplicationName = @ApplicationName,
				@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END