/*************************************************************           
 ** File:   [USP_GetTeardownReasonDetails]           
 ** Author:   Devendra Shekh
 ** Description: Retrieves teardown reason details
 ** Purpose:         
 ** Date:   25-Feb-2025        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   25-Feb-2025		Devendra Shekh			Created
	2   25-Feb-2025		Hemant Saliya			Updated for Get Revised Condition
	3   26-Feb-2025		Devendra Shekh			Updated to Get Revised PartNumber
	4   26-Feb-2025		Devendra Shekh			Added Changes for SubWO
	5	09-APR-2025		Devendra Shekh			Comparing @CorrectiveActionCode instead of name
	6	17-APR-2025		Devendra Shekh			Reading Memo Text From [CorrectiveActionTemplate]
	
 EXECUTE [USP_GetTeardownReasonDetails] 73, '', 7976, 1, 0
 EXECUTE [USP_GetTeardownReasonDetails] 147, '', 0, 1, 222
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetTeardownReasonDetails]
    @TeardownReasonId BIGINT = NULL,
    @PublicationIds NVARCHAR(MAX) = NULL,
	@WOPartNoId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@SubWOPartNoId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
	
	BEGIN TRY
		
		DECLARE @NeoSourceMemoText VARCHAR(1000) = '##condition## PER ##publication## REV: ##revisionNum## DATED: ##revisedDate##.<br>S/N: ##oldSRNUM## CHANGED TO ##NewSRNum## FOR TRACKING PURPOSES.<br>LATCH CORRECTLY IDENTIFIED AS PART NUMBER ##MPNPNNUMBER##';
		DECLARE @NeoSourceCompanyId INT = 0;
		DECLARE @RPPubTypeId BIGINT = 0;
		DECLARE @CorrectiveActionCode VARCHAR(100) = 'CRA';

		SELECT @NeoSourceMemoText = ISNULL([TemplateBody], @NeoSourceMemoText) FROM [dbo].[CommonTeardownTemplate] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [TemplateCode] = @CorrectiveActionCode;

		DECLARE @ConditionName VARCHAR(256),@CMMIds VARCHAR(256), @Publications VARCHAR(500), @CurrentSerialNumber VARCHAR(100), @RevisedSerialNumber VARCHAR(100), @PartNumber VARCHAR(200),
		@PublicationName NVARCHAR(MAX), @RevisionDate NVARCHAR(MAX), @RevisionNum NVARCHAR(MAX);

		SELECT @NeoSourceCompanyId = [MasterCompanyId] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyCode] = 'NEO';

		IF(ISNULL(@SubWOPartNoId, 0) = 0)
		BEGIN
			SELECT @ConditionName = CASE WHEN WOP.RevisedConditionId > 0 THEN ISNULL(C.Code, '') ELSE ISNULL(CD.Code, '') END, 		
			@CMMIds = ISNULL(WOP.CMMIds, ''), @CurrentSerialNumber = ISNULL(CurrentSerialNumber, ''), @RevisedSerialNumber = ISNULL(RevisedSerialNumber, ''), @PartNumber = COALESCE(RevisedPartNumber, PartNumber, '')
			FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)
			LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = WOP.RevisedConditionId
			LEFT JOIN [dbo].[Condition] CD WITH(NOLOCK) ON CD.ConditionId = WOP.ConditionId
			WHERE [ID] = @WOPartNoId;
		END
		ELSE
		BEGIN
			SELECT @ConditionName = CASE WHEN SWOP.RevisedConditionId > 0 THEN ISNULL(C.Code, '') ELSE ISNULL(CD.Code, '') END, 		
			@CMMIds = ISNULL(SWOP.CMMIds, ''), @CurrentSerialNumber = ISNULL(SL.SerialNumber, ''), @RevisedSerialNumber = COALESCE(RevisedSerialNumber, SL.SerialNumber, ''),
			@PartNumber = CASE WHEN SWOP.RevisedItemmasterid > 0 THEN ISNULL(RIM.PartNumber, '') ELSE ISNULL(IM.PartNumber, '') END
			FROM [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK)
			LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = SWOP.RevisedConditionId
			LEFT JOIN [dbo].[Condition] CD WITH(NOLOCK) ON CD.ConditionId = SWOP.ConditionId
			LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWOP.StockLineId
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = SWOP.ItemMasterId
			LEFT JOIN [dbo].[ItemMaster] RIM WITH(NOLOCK) ON RIM.ItemMasterId = SWOP.RevisedItemmasterid
			WHERE SWOP.[SubWOPartNoId] = @SubWOPartNoId;
		END

		SELECT @RPPubTypeId = [PublicationTypeId] FROM [dbo].[PublicationType] WITH(NOLOCK) WHERE [Name] = 'RSPEC' AND [MasterCompanyId] = @MasterCompanyId;

		SELECT 
				@PublicationName = STRING_AGG(NULLIF(CAST(PublicationId AS NVARCHAR(MAX)), ''), ', '),  
				@RevisionDate = STRING_AGG(NULLIF(FORMAT(revisionDate, 'dd/MMM/yyyy'), ''), ', '),  
				@RevisionNum = STRING_AGG(NULLIF(CAST(RevisionNum AS NVARCHAR(MAX)), ''), ', ') 
		FROM [dbo].[Publication] PB WITH(NOLOCK)
		WHERE PB.PublicationTypeId = @RPPubTypeId AND PB.PublicationRecordId IN (SELECT value FROM STRING_SPLIT(@CMMIds, ',') )

		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##condition##', ISNULL(@ConditionName, ''));
		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##publication##', ISNULL(@PublicationName, ''));
		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##revisionNum##', ISNULL(@RevisionNum, ''));
		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##revisedDate##', ISNULL(@RevisionDate, ''));
		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##oldSRNUM##', ISNULL(@CurrentSerialNumber, ''));
		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##NewSRNum##', ISNULL(@RevisedSerialNumber, ''));
		SET @NeoSourceMemoText = REPLACE(@NeoSourceMemoText, '##MPNPNNUMBER##', ISNULL(@PartNumber, ''));

		SET @NeoSourceMemoText = CASE WHEN ISNULL(@PublicationName, '') = '' THEN '' ELSE @NeoSourceMemoText END;

		SELECT 
			dt.TeardownReasonId,
			dt.Reason,
			Memo = 
				CASE 
					WHEN @MasterCompanyId = @NeoSourceCompanyId AND (tt.Code) = @CorrectiveActionCode THEN dt.Memo + ' ' + UPPER(@NeoSourceMemoText)
					WHEN tt.CommonTeardownTypeId IS NULL THEN dt.Memo
					WHEN (tt.Code) = @CorrectiveActionCode 
						 AND UPPER(dt.Memo) LIKE '%CMM ATA%' 
					THEN REPLACE(dt.Memo, 'CMM ATA', 'CMM ATA:' + @PublicationIds)
					WHEN (tt.Code) = @CorrectiveActionCode
						 AND @PublicationIds <> '' 
					THEN dt.Memo + '<p>CMM ATA:' + @PublicationIds + '</p>'
					ELSE dt.Memo
				END,
			dt.IsActive,
			dt.CreatedBy,
			dt.CreatedDate,
			dt.UpdatedBy,
			dt.UpdatedDate,
			dt.MasterCompanyId,
			TeardownType = ISNULL(tt.Name, ''),
			dt.CommonTeardownTypeId
		FROM dbo.[TeardownReason] dt WITH(NOLOCK)
		LEFT JOIN dbo.[CommonTeardownType] tt ON dt.CommonTeardownTypeId = tt.CommonTeardownTypeId
		WHERE dt.IsDeleted = 0 AND dt.TeardownReasonId = @TeardownReasonId;
	END TRY
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetSyncPendingSOInvoiceList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TeardownReasonId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END;