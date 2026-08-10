/*************************************************************   
** Author:  Moin Bloch
** Create date: <07/10/2025>  
** Description: <Get Work order Release Form Data>  
  
EXEC [[GetWorkorderQuoteCurrectiveAction]] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description
** --   --------    -------         --------------------------------
** 01   10/07/2025  Moin Bloch		Created
** 02   10/07/2025  Devendra Shekh  Added Changes for Other Company to Hanldle 2 CMM
** 03   09/23/2025  Vishal Suthar	Fixed the issue with populating publication details correctly
** 04   09-FEB-2026 AMIT GHEDIYA    Changes for Neo Company only to bind condition from workscope.(PN-15347)
** 05   07-AUG-2026 Abhishek Jirawala Added Fleet field in Section 12 Remarks (PN-17260)

 EXEC [dbo].[GetWorkorderReleaseFromData] 9737,9847
 EXEC [dbo].[GetWorkorderQuoteCurrectiveAction] 9737,9847
**************************************************************/ 
CREATE     PROC [dbo].[GetWorkorderQuoteCurrectiveAction]
@WorkorderId BIGINT = NULL,  
@workOrderPartNumberId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
		DECLARE @MasterCompanyId INT;  
		DECLARE @MTIMasterCompanyId INT; 

		DECLARE @CMMIds VARCHAR(200) = NULL;			
		DECLARE @IsMultiple BIT = NULL;
		DECLARE @EmailBody NVARCHAR(MAX)=''		
		DECLARE @ECMasterCompanyId INT = 19
		DECLARE @NeoMasterCompanyId INT = 20
		DECLARE @CMMID1 BIGINT = 0 
		DECLARE @CMMID2 BIGINT = 0 

		DECLARE @MasterCompanyCode VARCHAR(100)='', @NEOMasterCompanyCode VARCHAR(100)='',@WorkScopeCode VARCHAR(50) = NULL;
		
		SELECT @MasterCompanyId = [MasterCompanyId] FROM [DBO].[WorkOrder] CTT WITH(NOLOCK) WHERE [WorkorderId] = @WorkorderId;
		
		SELECT @MasterCompanyCode = [MasterCompanyCode] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		
		-- NEO COMPANY
		SELECT  @NEOMasterCompanyCode = [MasterCompanyCode] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyCode] = 'NEO';	

		IF OBJECT_ID(N'tempdb..#tmprCMMIDsDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmprCMMIDsDetails
		END		
		
		CREATE TABLE #tmprCMMIDsDetails
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[CMMId] BIGINT NULL
	    )
		
		SELECT @CMMIds = wop.[CMMIds]
		FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) 
		WHERE wop.[WorkOrderId] = @WorkOrderId AND wop.[ID]=@workOrderPartNumberId AND [MasterCompanyId] = @MasterCompanyId

		IF(@CMMIds = '')
		BEGIN
			SET @CMMIds = NULL
		END

		IF(@CMMIds IS NOT NULL)
		BEGIN
			INSERT INTO #tmprCMMIDsDetails ([CMMId])
			SELECT [PublicationRecordId]
			FROM [dbo].[Publication] P INNER JOIN [dbo].[PublicationType] PT ON P.PublicationTypeId = PT.PublicationTypeId
			WHERE P.[PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ','))  
			ORDER BY PT.[Name]
		END			
		
		IF(@CMMIds IS NOT NULL)
		BEGIN			
			IF CHARINDEX(',', @CMMIds) > 0
			BEGIN
				SET @IsMultiple = 1
			END
			ELSE
			BEGIN
				SET @IsMultiple = 0
			END
		END

		IF(@MasterCompanyId = @ECMasterCompanyId OR @MasterCompanyId = @NeoMasterCompanyId)
		BEGIN
			IF(@CMMIds IS NOT NULL)
			BEGIN
				IF(@IsMultiple = 1)
				BEGIN
					SELECT @EmailBody = [EmailBody] FROM 
						[dbo].[PublicationTemplate] PT WITH(NOLOCK) 
						WHERE [MasterCompanyId] = @MasterCompanyId AND [PublicationTypeId] = 0
				END
				ELSE
				BEGIN
					SELECT @EmailBody = [EmailBody]
						FROM [dbo].[Publication] PC WITH(NOLOCK)
						LEFT JOIN [dbo].[PublicationTemplate] PT WITH(NOLOCK) ON PT.[PublicationTypeId] = PC.[PublicationTypeId] and PT.[IsActive] = 1 AND PT.[IsDeleted] = 0
						WHERE PC.[PublicationRecordId] = CAST(@CMMIds AS BIGINT) AND PC.[MasterCompanyId] = @MasterCompanyId 
				END		
			END
		END
		ELSE
		BEGIN			
			IF(@CMMIds IS NOT NULL)
			BEGIN
				SELECT TOP 1 @EmailBody = [EmailBody] FROM [dbo].[PublicationTemplate] PT WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId	
			END
			ELSE
			BEGIN
				SELECT @EmailBody = '';
			END
		END

		IF(@MasterCompanyId = @ECMasterCompanyId OR @MasterCompanyId = @NeoMasterCompanyId)
		BEGIN
			IF(@IsMultiple IS NULL OR @IsMultiple = 0 )
			BEGIN
				SELECT ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
					   ISNULL(UPPER(pub.Fleet),'-') AS Fleet,
					   CASE WHEN @MasterCompanyCode = @NEOMasterCompanyCode 
					   		THEN UPPER(wop.[WorkScope])
					   ELSE
					   		CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END 
					   END AS ConditionName,
					   ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
					   UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,
					   '' SecondPublicationId,
					   '' SecondRevisionNum,
					   '' SecondRevisionDate,
					   wo.[WorkOrderNum],
					   '' IsEasaUKLicenseType,
					   ISNULL(pub.[PublishedById],0) PublishedById,
					   ven.[VendorName],
					   mf.[Name] [ManufacturerName],
					   pub.[PublishedByOthers],
					   @IsMultiple AS IsMultiple,	
					   @EmailBody AS EmailBody
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
					  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  					 
					  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.PublicationRecordId = @CMMIds 
					  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
					  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 					 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
			END
			ELSE
			BEGIN			
				
				  SELECT @CMMID1 = CMMId FROM #tmprCMMIDsDetails WHERE [ID] = 1;
				  SELECT @CMMID2 = CMMId FROM #tmprCMMIDsDetails WHERE [ID] = 2;
		  				  
				  SELECT ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
					   ISNULL(UPPER(pub.Fleet),'-') AS Fleet,
			             CASE WHEN @MasterCompanyCode = @NEOMasterCompanyCode 
							THEN UPPER(wop.[WorkScope])
						 ELSE
							 CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END 
						 END AS ConditionName,
				 		 ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
						 UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,
						 ISNULL(UPPER(pub2.PublicationId),0) AS SecondPublicationId,
						 ISNULL(CONVERT(VARCHAR(20),UPPER(pub2.RevisionNum)),'-') SecondRevisionNum,
						 UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub2.revisionDate,106),' ','/'),'-')) SecondRevisionDate,
						 wo.[WorkOrderNum],
						 '' IsEasaUKLicenseType,
						 ISNULL(pub.[PublishedById],0) PublishedById,
						 ven.[VendorName],
						 mf.[Name] ManufacturerName,
				         pub.[PublishedByOthers],
						 @IsMultiple AS IsMultiple,
						 @EmailBody AS EmailBody
			FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
				  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
				  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
				  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.[PublicationRecordId] = @CMMID1 
				  LEFT JOIN [dbo].[Publication] pub2 WITH(NOLOCK) ON pub2.[PublicationRecordId] = @CMMID2 				  
				  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
				  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
				  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
			 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
			END	
		END
		ELSE
		BEGIN
			IF(@IsMultiple IS NULL OR @IsMultiple = 0 )
			BEGIN
			   SELECT ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
					   ISNULL(UPPER(pub.Fleet),'-') AS Fleet,
			          CASE WHEN @MasterCompanyCode = @NEOMasterCompanyCode 
							THEN UPPER(wop.[WorkScope])
					  ELSE
						    CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END 
					  END AS ConditionName,
					  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
					  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,	
					  '' SecondPublicationId,
					  '' SecondRevisionNum,
					  '' SecondRevisionDate,		
					  wo.[WorkOrderNum],
					  '' IsEasaUKLicenseType,
					  ISNULL(pub.[PublishedById],0) PublishedById,
					  ven.[VendorName],
					  mf.[Name] [ManufacturerName],
					  pub.[PublishedByOthers],					  
					  @IsMultiple AS IsMultiple,
					  @EmailBody AS EmailBody					   
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
					  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
					  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.PublicationRecordId = @CMMIds 
					  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
					  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
			END
			ELSE
			BEGIN
				SELECT @CMMID1 = CMMId FROM #tmprCMMIDsDetails WHERE [ID] = 1;
				SELECT @CMMID2 = CMMId FROM #tmprCMMIDsDetails WHERE [ID] = 2;

				SELECT ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
					   ISNULL(UPPER(pub.Fleet),'-') AS Fleet,
			          CASE WHEN @MasterCompanyCode = @NEOMasterCompanyCode 
							THEN UPPER(wop.[WorkScope])
					  ELSE
							CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END
					  END AS ConditionName,
					  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
					  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,	
					  ISNULL(UPPER(pub2.PublicationId),0) AS SecondPublicationId,
					  ISNULL(CONVERT(VARCHAR(20),UPPER(pub2.RevisionNum)),'-') SecondRevisionNum,
					  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub2.revisionDate,106),' ','/'),'-')) SecondRevisionDate,	
					  wo.[WorkOrderNum],
					  '' IsEasaUKLicenseType,
					  ISNULL(pub.[PublishedById],0) PublishedById,
					  ven.[VendorName],
					  mf.[Name] [ManufacturerName],
					  pub.[PublishedByOthers],					  
					  @IsMultiple AS IsMultiple,
					  @EmailBody AS EmailBody					   
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
					  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
					  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.[PublicationRecordId] = @CMMID1 
					  LEFT JOIN [dbo].[Publication] pub2 WITH(NOLOCK) ON pub2.[PublicationRecordId] = @CMMID2 	
					  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
					  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
			END
		END		
					
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkorderQuoteCurrectiveAction'                
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkorderId, '') AS VARCHAR(100))
			                                       + '@Parameter2 = ''' + CAST(ISNULL(@workOrderPartNumberId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END