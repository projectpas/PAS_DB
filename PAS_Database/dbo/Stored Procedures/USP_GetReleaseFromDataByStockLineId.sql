/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <12/26/2023>  
** Description: <Get Release Form Data by stocklineid>  
  
EXEC [USP_GetReleaseFromDataByStockLineId] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    12/26/2023		Devendra Shekh		created
** 2    10/02/2024		AMIT GHEDIYA		Updated For Get EASA UK Dualreleaselanguage message.
** 3    12/13/2024		Moin Bloch		    Updated For Add @formTypeId
** 4    25/12/2024      Devendra Shekh      Resolved Design Issue while Print form
** 5    27/12/2024      Devendra Shekh      Resolved Design Issue while Print form
** 6    18/02/2025      Moin Bloch          Updated (Added Publication CMMIds)
** 7    19/02/2025      Moin Bloch          Updated (Changed Logic For Publication CMMIds For MasterCompanyId Wise)
** 8    20/02/2025      Moin Bloch          Updated (Checked @CMMIds Empty)
** 9    24/02/2025      Moin Bloch          Updated (Renamed FotterRemarks TO FooterRemarks)
** 10   25/02/2025      Moin Bloch          Updated (changed Condition Table)
** 11   10/10/2025      Moin Bloch          Updated For Get VersionNo & IsVersionIncrease Flag
** 12   13/10/2025      Moin Bloch          Updated to Dynamic VersionNo
** 19   20/01/2026      Moin Bloch          Updated For PAR Added CorrectiveAction For PAR
** 20   21/01/2026      Vishal Suthar       Move CorrectiveAction data with "*" only and remove "*" after moving to release form For PAR
** 21   12/02/2026      Moin Bloch          Updated Added WOReleaseFormId insted of Country PN-15388
** 22   11/03/2026      Moin Bloch          Removed '-' FROM FooterRemarks
** 23   18/MAY/2026     Rajesh Gami			8130 Release Form Enhancements for the ATI [PN-16447]	

 EXEC [dbo].[USP_GetReleaseFromDataByStockLineId] 3553,1,0
**************************************************************/ 

CREATE   PROC [dbo].[USP_GetReleaseFromDataByStockLineId]
@StockLineId BIGINT,  
@WorkOrderPartNumberId BIGINT,
@IsEasaLicense BIT = 0 ,
@IsEasaUKLicense BIT = 0,
@formTypeId INT = 0
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
		DECLARE @CommonTeardownTypeId INT;
		DECLARE @MSModuleId INT;  
		DECLARE @MasterCompanyId INT;  
		DECLARE @MTIMasterCompanyId INT; 
		DECLARE @UkCountryISOCode VARCHAR(100) = 'GB';
		DECLARE @USCountryISOCode VARCHAR(100) = 'US';
		--DECLARE @CountryId BIGINT = 0;	
		DECLARE @FAA INT= 1
		DECLARE @FAAEASA INT= 2
		DECLARE @FAAEASAUK INT= 3
		DECLARE @CMMIds VARCHAR(200) = NULL;			
		DECLARE @IsMultiple BIT = NULL;
		DECLARE @EmailBody NVARCHAR(MAX)=''		
		DECLARE @ECMasterCompanyId INT = 19
		DECLARE @NeoMasterCompanyId INT = 20
		DECLARE @MasterCompanyCode VARCHAR(20) = 'PAR'
		DECLARE @ParCommonTeardownTypeId BIGINT = 0;
		DECLARE @CorrectiveAction NVARCHAR(MAX)=''
		DECLARE @WorkorderId BIGINT = 0;
		DECLARE @WorkFlowWorkOrderId  BIGINT = 0;
		DECLARE @MasterCompanyCodeATI VARCHAR(20) = 'ATI'
		DECLARE @ATIReleaseFormCommonTeardownTypeId BIGINT = 0;
		DECLARE @ReleaseForm NVARCHAR(MAX) = '';
		DECLARE @isATICompany BIT = 0;
		SET @MSModuleId = 2 ; -- For WO PART NUMBER  
		SET @MTIMasterCompanyId = 11; -- For MTI
	  	  
		SELECT @MasterCompanyId = [MasterCompanyId] FROM [DBO].[Stockline] CTT WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

		SELECT @WorkorderId = [WorkorderId] FROM [DBO].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID]=@workOrderPartNumberId

		IF(@MasterCompanyCode = (SELECT [MasterCompanyCode] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId))
		BEGIN
			SELECT @ParCommonTeardownTypeId = [CommonTeardownTypeId] FROM [dbo].[CommonTeardownType] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [TearDownCode] = 'CRA';			
			SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM [DBO].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkorderId]=@WorkorderId AND [WorkOrderPartNoId]=@workOrderPartNumberId				
			DECLARE @Start INT, @End INT;

			WHILE PATINDEX('%<ul%', @CorrectiveAction) > 0
			BEGIN
				SET @Start = PATINDEX('%<ul%', @CorrectiveAction);
				SET @End = CHARINDEX('</ul>', @CorrectiveAction, @Start);
				SET @CorrectiveAction = STUFF(@CorrectiveAction, @Start, (@End - @Start) + 5, '');
			END
			WHILE PATINDEX('%<ol%', @CorrectiveAction) > 0
			BEGIN
				SET @Start = PATINDEX('%<ol%', @CorrectiveAction);
				SET @End = CHARINDEX('</ol>', @CorrectiveAction, @Start);
				SET @CorrectiveAction = STUFF(@CorrectiveAction, @Start, (@End - @Start) + 5, '');
			END			
			DECLARE @FinalResult NVARCHAR(MAX) = '';
			SELECT @FinalResult = @FinalResult + '<p>' + LTRIM(SUBSTRING(CleanedItem, CHARINDEX('*', CleanedItem) + 1, LEN(CleanedItem))) + '</p>'
			FROM (				
				SELECT value as RawItem,					  
					   SUBSTRING(value, CHARINDEX('>', value) + 1, LEN(value)) as CleanedItem
				FROM STRING_SPLIT(REPLACE(@CorrectiveAction, '</p>', '|'), '|')
			) AS T
			WHERE CleanedItem LIKE '%*%';
									
			SET	@CorrectiveAction = @FinalResult
		END
		/********* For the ATI company: Release Form *********/
		IF(@MasterCompanyCodeATI = (SELECT [MasterCompanyCode]FROM [dbo].[MasterCompany] WITH(NOLOCK)WHERE [MasterCompanyId] = @MasterCompanyId	))
			BEGIN
				SET @isATICompany = 1;
				SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId]
				FROM [DBO].[WorkOrderWorkFlow] WITH(NOLOCK)
				WHERE [WorkorderId] = @WorkorderId
				AND [WorkOrderPartNoId] = @workOrderPartNumberId;

				SELECT @ATIReleaseFormCommonTeardownTypeId = [CommonTeardownTypeId]
				FROM [dbo].[CommonTeardownType] WITH(NOLOCK)
				WHERE [MasterCompanyId] = @MasterCompanyId
				AND [Code] = 'RELEASEFORM';

				SELECT @ReleaseForm = [Memo]
				FROM [DBO].[CommonWorkOrderTearDown] WITH(NOLOCK)
				WHERE [CommonTeardownTypeId] = @ATIReleaseFormCommonTeardownTypeId
				AND [WorkorderId] = @WorkorderId
				AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;

				PRINT @ReleaseForm;

				DECLARE @StartATI INT, @EndATI INT;

				WHILE PATINDEX('%<ul%', @ReleaseForm) > 0
				BEGIN
					SET @StartATI = PATINDEX('%<ul%', @ReleaseForm);
					SET @EndATI = CHARINDEX('</ul>', @ReleaseForm, @StartATI);
					SET @ReleaseForm = STUFF(@ReleaseForm, @StartATI, (@EndATI - @StartATI) + 5, '');
				END

				WHILE PATINDEX('%<ol%', @ReleaseForm) > 0
				BEGIN
					SET @StartATI = PATINDEX('%<ol%', @ReleaseForm);
					SET @EndATI = CHARINDEX('</ol>', @ReleaseForm, @StartATI);
					SET @ReleaseForm = STUFF(@ReleaseForm, @StartATI, (@EndATI - @StartATI) + 5, '');
				END

				DECLARE @FinalResultATI NVARCHAR(MAX) = '';

				SELECT @FinalResultATI = @FinalResultATI + '<p>' +
					   LTRIM(
							CASE 
								WHEN CHARINDEX('*', CleanedItem) > 0 
									THEN SUBSTRING(CleanedItem, CHARINDEX('*', CleanedItem) + 1, LEN(CleanedItem))
								ELSE CleanedItem
							END
					   ) + '</p>'
				FROM
				(
					SELECT value AS RawItem,
						   SUBSTRING(value, CHARINDEX('>', value) + 1, LEN(value)) AS CleanedItem
					FROM STRING_SPLIT(REPLACE(@ReleaseForm, '</p>', '|'), '|')
				) AS T
				WHERE LTRIM(RTRIM(CleanedItem)) <> '';

				SET @ReleaseForm = @FinalResultATI;
				SET @CorrectiveAction = @ReleaseForm;
				PRINT @CorrectiveAction
			END

		DECLARE @VerCodePrefix NVARCHAR(50),@VerCode INT

		SELECT @VerCode  = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Version';
		
		SELECT TOP 1 @VerCodePrefix = [CodePrefix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @VerCode AND [MasterCompanyId] = @MasterCompanyId;

		DECLARE @VersionNo VARCHAR(50) = NULL

		SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](1, ISNULL(@VerCodePrefix,''),''));

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
		WHERE wop.[ID]=@workOrderPartNumberId AND [MasterCompanyId] = @MasterCompanyId

		IF(@CMMIds = '')
		BEGIN
			SET @CMMIds = NULL
		END

		IF(@CMMIds IS NOT NULL)
		BEGIN
			INSERT INTO #tmprCMMIDsDetails ([CMMId])
			SELECT [PublicationRecordId] --(SELECT Item FROM DBO.SPLITSTRING(wop.CMMIds, ',')) AS cmmids 
			FROM [dbo].[Publication] WHERE [PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ','))  
		END	

		SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [DBO].[CommonTeardownType] CTT WITH(NOLOCK) 
		WHERE CTT.[MasterCompanyId] = @MasterCompanyId AND UPPER(CTT.[TearDownCode]) = UPPER('MODIFICATIONSERVICE');
	   
	   --GET Country code id
	 --   IF(ISNULL(@IsEasaUKLicense, 0) = 1 AND @formTypeId = @FAAEASAUK)
		--BEGIN
		--	SELECT @CountryId = countries_id FROM [DBO].[Countries] WITH(NOLOCK) WHERE countries_iso_code = @UkCountryISOCode AND MasterCompanyId = @MasterCompanyId;	  
		--END

		--IF(ISNULL(@IsEasaLicense, 0) = 1 AND @formTypeId = @FAAEASA)
		--BEGIN
		--	SELECT @CountryId = countries_id FROM [DBO].[Countries] WITH(NOLOCK) WHERE countries_iso_code = @USCountryISOCode AND MasterCompanyId = @MasterCompanyId;	
		--END

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

		IF(@MasterCompanyId <> @ECMasterCompanyId AND @MasterCompanyId <> @NeoMasterCompanyId)
		BEGIN
			IF(@IsMultiple = 1)
			BEGIN
				DECLARE @PID VARCHAR(200) = NULL;					
				SELECT TOP 1 @PID = [PublicationRecordId]
				FROM [dbo].[Publication] 
				WHERE [MasterCompanyId] = @MasterCompanyId AND [PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ',')) AND [ExpirationDate] IS NULL; 
				
				IF(@PID IS NULL OR @PID = '')
				BEGIN					
					SELECT TOP 1 @PID = [PublicationRecordId]
					FROM [dbo].[Publication] 
					WHERE [MasterCompanyId] = @MasterCompanyId AND [PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ',')) ORDER BY [ExpirationDate] DESC;
					SET @CMMIds = @PID;					
				END
				ELSE 
				BEGIN
					SET @CMMIds = @PID;
				END
			END				
		END

		IF(@MasterCompanyId = @ECMasterCompanyId OR @MasterCompanyId = @NeoMasterCompanyId)
		BEGIN
			IF(@IsMultiple IS NULL OR @IsMultiple = 0)
			BEGIN
				SELECT 'UNITED STATES' AS Country,  
			  '' AS trackingNo,  
			  le.CompanyName AS OrganizationName,  
			  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,  
			  wo.WorkOrderNum AS InvoiceNo,  
			  '1' AS ItemName,  
			  UPPER(im.PartDescription) AS Description,  
			  UPPER(im.partnumber) AS PartNumber,  
			  wop.CustomerReference AS Reference,  
			  sl.Quantity AS Quantity,  
			  UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN 'NA' ELSE sl.SerialNumber END) AS Batchnumber,  
			  ISNULL(sl.Condition, '') AS [status],  
			  '' as Certifies,   
			  0 AS approved ,  
			  0 AS Nonapproved,  
			  '' AS AuthorisedSign,   
			  UPPER(le.FAALicense) AS AuthorizationNo,  
			  '' as PrintedName,GETDATE() AS [Date],  
			  '' as AuthorisedSign2,  
			  UPPER(le.FAALicense) AS ApprovalCertificate,  
			  '' AS PrintedName2,GETDATE() Date2,  
			  0 AS CFR,  
			  0 AS Otherregulation,  
			  1 AS is8130from ,  
			  sl.ReceivedDate,  
			  sl.ManagementStructureId AS ManagementStructureId, 
			  @IsMultiple AS IsMultiple,
			  --UPPER(wosc.conditionName) AS ConditionName,			  
			  ISNULL(UPPER(sl.Condition), '') AS ConditionName,
			  ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
			  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
			  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,	
			  '' SecondPublicationId,
			  '' SecondRevisionNum,
			  '' SecondRevisionDate,		
			  wo.WorkOrderNum,
			  ISNULL(pub.[PublishedById],0) PublishedById,
			  ven.[VendorName],
			  mf.[Name] ManufacturerName,
			  pub.[PublishedByOthers],				  
			  CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END AS IsEasaUKLicenseType,
			  @EmailBody AS EmailBody,
			  ('<div style = "position:relative;' +CASE WHEN @isATICompany = 1 THEN 'min-height:130px;max-height:140px;' ELSE 'min-height:140px;max-height:150px;' END +  'padding-bottom:35px; font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">') AS HeaderRemarks,  
			  (CASE WHEN cwt.Memo IS NOT NULL THEN (CASE WHEN ISNULL(cwt.Memo,'') = '' THEN '' ELSE ISNULL(cwt.Memo,'') END) + '<p>&nbsp;</p>' ELSE '' END) 	
			  + (CASE WHEN @IsEasaLicense = 0 AND @IsEasaUKLicense = 0 THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ +'</div>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)         
			   + '</div>' AS FooterRemarks,   
			   Upper(le.EASALicense) AS EASALicense,
			   0 AS [IsClosed],
			   wop.[islocked],
			   CASE WHEN @IsEasaLicense = 1 THEN 1 ELSE 0 END AS 'IsEASALicense',
			   '8130 Form' as FormType,
			   wo.EmployeeId,
			   0 AS 'ReleaseFromId',
			   ISNULL(SL.[WorkorderId], 0) AS [WorkorderId],
			   ISNULL(wop.ID, 0) AS [workOrderPartNoId],
			   SL.[MasterCompanyId],
			   '' AS 'PDFPath',
			   wop.IsFinishGood
			   ,@VersionNo VersionNo
			   ,0 AS IsVersionIncrease
			   ,@CorrectiveAction CorrectiveAction
		FROM [dbo].[Stockline] sl WITH(NOLOCK)   
			  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = sl.WorkOrderId 
			  LEFT JOIN [dbo].[WorkOrderPartNumber] wop  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId AND wop.ID = @WorkOrderPartNumberId
			  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.WOReleaseFormId = @formTypeId	
			 --LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9 
			  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId  
			  LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = sl.StockLineId  
			  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
			  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
			  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
			  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.PublicationRecordId = @CMMIds 
			  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId  
			  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId 
			  LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
		 WHERE sl.StockLineId = @StockLineId
			END
			ELSE
			BEGIN
				DECLARE @CMMID1 BIGINT = 0 
				DECLARE @CMMID2 BIGINT = 0 

				SELECT @CMMID1 = CMMId FROM #tmprCMMIDsDetails WHERE [ID] = 1;
				SELECT @CMMID2 = CMMId FROM #tmprCMMIDsDetails WHERE [ID] = 2;
			
				SELECT 'UNITED STATES' AS Country,  
			  '' AS trackingNo,  
			  le.CompanyName AS OrganizationName,  
			  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,  
			  wo.WorkOrderNum AS InvoiceNo,  
			  '1' AS ItemName,  
			  UPPER(im.PartDescription) AS Description,  
			  UPPER(im.partnumber) AS PartNumber,  
			  wop.CustomerReference AS Reference,  
			  sl.Quantity AS Quantity,  
			  UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN 'NA' ELSE sl.SerialNumber END) AS Batchnumber,  
			  ISNULL(sl.Condition, '') AS [status],  
			  '' as Certifies,   
			  0 AS approved ,  
			  0 AS Nonapproved,  
			  '' AS AuthorisedSign,   
			  UPPER(le.FAALicense) AS AuthorizationNo,  
			  '' as PrintedName,GETDATE() AS [Date],  
			  '' as AuthorisedSign2,  
			  UPPER(le.FAALicense) AS ApprovalCertificate,  
			  '' AS PrintedName2,GETDATE() Date2,  
			  0 AS CFR,  
			  0 AS Otherregulation,  
			  1 AS is8130from ,  
			  sl.ReceivedDate,  
			  sl.ManagementStructureId AS ManagementStructureId,
			  @IsMultiple AS IsMultiple,				
			  --UPPER(wosc.conditionName) AS ConditionName,			  
			  ISNULL(UPPER(sl.Condition), '') AS ConditionName,
			  ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
			  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
			  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,
			  ISNULL(UPPER(pub2.PublicationId),0) AS SecondPublicationId,
			  ISNULL(CONVERT(VARCHAR(20),UPPER(pub2.RevisionNum)),'-') SecondRevisionNum,
			  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub2.revisionDate,106),' ','/'),'-')) SecondRevisionDate,
			  wo.WorkOrderNum,
			  ISNULL(pub.[PublishedById],0) PublishedById,
			  ven.[VendorName],
			  mf.[Name] ManufacturerName,
			  pub.[PublishedByOthers],				  
			  CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END AS IsEasaUKLicenseType,		
			  @EmailBody AS EmailBody,
			  ('<div style = "position:relative;' +CASE WHEN @isATICompany = 1 THEN 'min-height:130px;max-height:140px;' ELSE 'min-height:140px;max-height:150px;' END +  'padding-bottom:35px;  font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">') AS HeaderRemarks,  
  		      (CASE WHEN cwt.Memo IS NOT NULL THEN (CASE WHEN ISNULL(cwt.Memo,'') = '' THEN '' ELSE ISNULL(cwt.Memo,'') END) + '<p>&nbsp;</p>' ELSE '' END) 	
			  + (CASE WHEN @IsEasaLicense = 0 AND @IsEasaUKLicense = 0 THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ +'</div>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)         
			  + '</div>' AS FooterRemarks, 
			  Upper(le.EASALicense) AS EASALicense,
			   0 AS [IsClosed],
			   wop.[islocked],
			   CASE WHEN @IsEasaLicense = 1 THEN 1 ELSE 0 END AS 'IsEASALicense',
			   '8130 Form' as FormType,
			   wo.EmployeeId,
			   0 AS 'ReleaseFromId',
			   ISNULL(SL.[WorkorderId], 0) AS [WorkorderId],
			   ISNULL(wop.ID, 0) AS [workOrderPartNoId],
			   SL.[MasterCompanyId],
			   '' AS 'PDFPath',
			   wop.IsFinishGood
			   ,@VersionNo VersionNo
			   ,0 AS IsVersionIncrease
			   ,@CorrectiveAction CorrectiveAction
		FROM [dbo].[Stockline] sl WITH(NOLOCK)   
			  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = sl.WorkOrderId 
			  LEFT JOIN [dbo].[WorkOrderPartNumber] wop  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId AND wop.ID = @WorkOrderPartNumberId
			  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.WOReleaseFormId = @formTypeId	
			  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId  
			  LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = sl.StockLineId  
			  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
			  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
			  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId 
			  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.[PublicationRecordId] = @CMMID1 
			  LEFT JOIN [dbo].[Publication] pub2 WITH(NOLOCK) ON pub2.[PublicationRecordId] = @CMMID2 
			  --LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON wop.CMMId = pub.PublicationRecordId  
			  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId  
			  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId 
			  LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
		 WHERE sl.StockLineId = @StockLineId

			END
		END
		ELSE
		BEGIN
			SELECT 'UNITED STATES' AS Country,  
			  '' AS trackingNo,  
			  le.CompanyName AS OrganizationName,  
			  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,  
			  wo.WorkOrderNum AS InvoiceNo,  
			  '1' AS ItemName,  
			  UPPER(im.PartDescription) AS Description,  
			  UPPER(im.partnumber) AS PartNumber,  
			  wop.CustomerReference AS Reference,  
			  sl.Quantity AS Quantity,  
			  UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN 'NA' ELSE sl.SerialNumber END) AS Batchnumber,  
			  ISNULL(sl.Condition, '') AS [status],  
			  '' as Certifies,   
			  0 AS approved ,  
			  0 AS Nonapproved,  
			  '' AS AuthorisedSign,   
			  UPPER(le.FAALicense) AS AuthorizationNo,  
			  '' as PrintedName,GETDATE() AS [Date],  
			  '' as AuthorisedSign2,  
			  UPPER(le.FAALicense) AS ApprovalCertificate,  
			  '' AS PrintedName2,GETDATE() Date2,  
			  0 AS CFR,  
			  0 AS Otherregulation,  
			  1 AS is8130from ,  
			  sl.ReceivedDate,  
			  sl.ManagementStructureId AS ManagementStructureId, 
			  @IsMultiple AS IsMultiple,
			  --UPPER(wosc.conditionName) AS ConditionName,
			  ISNULL(UPPER(sl.Condition), '') AS ConditionName,
			  ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
			  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
			  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,	
			  '' SecondPublicationId,
			  '' SecondRevisionNum,
			  '' SecondRevisionDate,		
			  wo.WorkOrderNum,
			  ISNULL(pub.[PublishedById],0) PublishedById,
			  ven.[VendorName],
			  mf.[Name] ManufacturerName,
			  pub.[PublishedByOthers],				  
			  CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END AS IsEasaUKLicenseType,
			  @EmailBody AS EmailBody,
			  ('<div style = "position:relative;' +CASE WHEN @isATICompany = 1 THEN 'min-height:130px;max-height:140px;' ELSE 'min-height:140px;max-height:150px;' END +  'padding-bottom:35px;  font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">') AS HeaderRemarks,  
			  (CASE WHEN cwt.Memo IS NOT NULL THEN (CASE WHEN ISNULL(cwt.Memo,'') = '' THEN '' ELSE ISNULL(cwt.Memo,'') END) + '<p>&nbsp;</p>' ELSE '' END) 
			  + (CASE WHEN @IsEasaLicense = 0 AND @IsEasaUKLicense = 0 THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ +'</div>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,''),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)         
			 + '</div>' AS FooterRemarks,   
			   Upper(le.EASALicense) AS EASALicense,
			   0 AS [IsClosed],
			   wop.[islocked],
			   CASE WHEN @IsEasaLicense = 1 THEN 1 ELSE 0 END AS 'IsEASALicense',
			   '8130 Form' as FormType,
			   wo.EmployeeId,
			   0 AS 'ReleaseFromId',
			   ISNULL(SL.[WorkorderId], 0) AS [WorkorderId],
			   ISNULL(wop.ID, 0) AS [workOrderPartNoId],
			   SL.[MasterCompanyId],
			   '' AS 'PDFPath',
			   wop.IsFinishGood
			   ,@VersionNo VersionNo
			   ,0 AS IsVersionIncrease
			   ,@CorrectiveAction CorrectiveAction
		FROM [dbo].[Stockline] sl WITH(NOLOCK)   
			  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = sl.WorkOrderId 
			  LEFT JOIN [dbo].[WorkOrderPartNumber] wop  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId AND wop.ID = @WorkOrderPartNumberId
			  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.WOReleaseFormId = @formTypeId	
			  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId  
			  LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = sl.StockLineId  
			  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
			  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
			  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
			  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.PublicationRecordId = @CMMIds 
			  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId  
			  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId 
			  LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
		 WHERE sl.StockLineId = @StockLineId

		END
  END TRY      
  BEGIN CATCH        
    IF @@trancount > 0      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetReleaseFromDataByStockLineId'   
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(100))
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