/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <01/23/2023>  
** Description: <Get Work order Release Form Data>  
  
EXEC [GetSubWorkorderReleaseFromData] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    05/26/2023  HEMANT SALIYA    Updated For WorkOrder Settings
** 2    09/29/2023  HEMANT SALIYA    Updated For Notes in Remarks
** 3    01/01/2024  Devendra Shekh   updated for SerialNumber(Batchnumber)
** 4    02/08/2024  Shrey Chandegara Updated for status (add case condition in status)
** 5    07/29/2024  HEMANT SALIYA    Updated For Get Part Number, Serial NUmber and Condition from Work Order Part table
** 6    10/02/2024  AMIT GHEDIYA     Updated For Get EASA UK Dualreleaselanguage message.
** 7    12/12/2024  Moin Bloch       Updated (Added formTypeId)
** 8    25/12/2024  Devendra Shekh   Resolved Design Issue while Print form
** 9    27/12/2024  Devendra Shekh   Resolved Design Issue while Print form
** 10	31/12/2024  Devendra Shekh   Replace NA with Empty String for BatchNumber
** 11   14/02/2025  Moin Bloch       Updated (Added Publication CMMIds)
** 12   19/02/2025  Moin Bloch       Updated (Changed Logic For Publication CMMIds For MasterCompanyId Wise checked @CMMIds Empty)
** 13   20/02/2025  Moin Bloch       Updated (Checked @CMMIds Empty)
** 14   21/02/2025  Moin Bloch       Updated (Fixed Condition Issue)
** 15   12/09/2025  Vishal Suthar    Fixed the issue with CMM & RSPEC data interchange
** 16   10/10/2025  Moin Bloch       Updated For Get VersionNo & IsVersionIncrease Flag
** 17   13/10/2025  Moin Bloch       Updated to Dynamic VersionNo

 EXEC [dbo].[GetWorkorderReleaseFromData] 8212,7835,1,0,2
**************************************************************/ 

CREATE   PROC [dbo].[GetWorkorderReleaseFromData]  
@WorkorderId bigint,  
@workOrderPartNumberId bigint,  
@IsEasaLicense bit = 0 ,
@IsEasaUKLicense bit = 0,
@formTypeId int
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
		DECLARE @WorkOrderSettlementId INT;  
		DECLARE @CommonTeardownTypeId INT;
		DECLARE @MSModuleId INT;  
		DECLARE @MasterCompanyId INT;  
		DECLARE @MTIMasterCompanyId INT; 
		DECLARE @UkCountryISOCode VARCHAR(100) = 'GB';
		DECLARE @USCountryISOCode VARCHAR(100) = 'US';
		DECLARE @CountryId BIGINT = 0;			
		DECLARE @CMMIds VARCHAR(200) = NULL;			
		DECLARE @IsMultiple BIT = NULL;
		DECLARE @EmailBody NVARCHAR(MAX)=''		
		DECLARE @ECMasterCompanyId INT = 19
		DECLARE @NeoMasterCompanyId INT = 20
		
		SELECT @MasterCompanyId = [MasterCompanyId] FROM [DBO].[WorkOrder] CTT WITH(NOLOCK) WHERE [WorkorderId] = @WorkorderId;

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
		WHERE wop.[WorkOrderId] = @WorkOrderId AND wop.[ID]=@workOrderPartNumberId AND [MasterCompanyId] = @MasterCompanyId

		IF(@CMMIds = '')
		BEGIN
			SET @CMMIds = NULL
		END

		IF(@CMMIds IS NOT NULL)
		BEGIN
			--INSERT INTO #tmprCMMIDsDetails ([CMMId])
			--SELECT [PublicationRecordId] --(SELECT Item FROM DBO.SPLITSTRING(wop.CMMIds, ',')) AS cmmids 
			--FROM [dbo].[Publication] WHERE [PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ','))  
			--ORDER BY PublicationTypeId DESC
			INSERT INTO #tmprCMMIDsDetails ([CMMId])
			SELECT [PublicationRecordId]
			FROM [dbo].[Publication] P INNER JOIN [dbo].[PublicationType] PT ON P.PublicationTypeId = PT.PublicationTypeId
			WHERE P.[PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ','))  
			ORDER BY PT.[Name]
		END			
		
		DECLARE @FAA INT = 1;  
		DECLARE @FAAEASA INT = 2;  
		DECLARE @FAAEASAUK INT = 3;  

		SET @MSModuleId = 12 ; -- For WO PART NUMBER  
		SET @MTIMasterCompanyId = 11; -- For MTI
		SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK)   
		WHERE  WS.WorkOrderSettlementName like '%Cond%' 
	  	  
		SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [DBO].[CommonTeardownType] CTT WITH(NOLOCK) 
		WHERE CTT.[MasterCompanyId] = @MasterCompanyId AND UPPER(CTT.[TearDownCode]) = UPPER('MODIFICATIONSERVICE');
		
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

	    --GET Country code id
		IF(ISNULL(@IsEasaUKLicense, 0) = 1 AND @formTypeId = @FAAEASAUK)
		BEGIN
			SELECT @CountryId = countries_id FROM [DBO].[Countries] WITH(NOLOCK) WHERE countries_iso_code = @UkCountryISOCode AND MasterCompanyId = @MasterCompanyId;	  
		END

		IF(ISNULL(@IsEasaLicense, 0) = 1 AND @formTypeId = @FAAEASA)
		BEGIN
			SELECT @CountryId = countries_id FROM [DBO].[Countries] WITH(NOLOCK) WHERE countries_iso_code = @USCountryISOCode AND MasterCompanyId = @MasterCompanyId;	
		END

		IF(@MasterCompanyId = @ECMasterCompanyId OR @MasterCompanyId = @NeoMasterCompanyId)
		BEGIN
			IF(@IsMultiple IS NULL OR @IsMultiple = 0 )
			BEGIN
				SELECT 'UNITED STATES' AS Country,  
					  '' AS trackingNo,  
					  le.CompanyName AS OrganizationName,  
					  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,  
					  wo.WorkOrderNum AS InvoiceNo,  
					  '1' AS ItemName,  					  
					  wop.RevisedPartDescription AS [Description],
					  wop.RevisedPartNumber AS PartNumber,  
					  wop.CustomerReference AS Reference,  
					  wop.Quantity AS Quantity,  
					  CASE WHEN ISNULL(wop.RevisedSerialNumber , '') = '' THEN UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN '' ELSE sl.SerialNumber END)
								ELSE UPPER(wop.RevisedSerialNumber) END AS Batchnumber,  
					  CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END AS [status],
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
					  0 Otherregulation,  
					  1 AS is8130from ,  
					  wop.ReceivedDate,  
					  wop.ManagementStructureId AS ManagementStructureId, 
					  @IsMultiple AS IsMultiple,				 
					  --UPPER(wosc.conditionName) AS ConditionName,
					  CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END AS ConditionName,
					  ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
					  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
					  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,	
					  '' SecondPublicationId,
					  '' SecondRevisionNum,
					  '' SecondRevisionDate,		
					  wo.[WorkOrderNum],
					  ISNULL(pub.[PublishedById],0) PublishedById,
					  ven.[VendorName],
					  mf.[Name] [ManufacturerName],
					  pub.[PublishedByOthers],
					  wo.[MasterCompanyId],
					  CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END AS IsEasaUKLicenseType,
					  ('<div style = "position:relative; min-height:90px;max-height:100px;  font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">') AS HeaderRemarks,   				
					   --+ (CASE WHEN wop.CMMId is not null and wop.CMMId > 0 THEN   
						--		CASE WHEN wo.MasterCompanyId != @MTIMasterCompanyId THEN '<p>' + ('Publication ID: ' + ISNULL(UPPER(pub.PublicationId),0)) +'</p>'   
						--				+'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + ISNULL(UPPER(ven.VendorName),'-')  
						--							 WHEN pub.PublishedById = 3 THEN 'Published By: ' +  ISNULL(UPPER(mf.Name),'-')  
						--							 WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(UPPER(pub.PublishedByOthers),'-')  
						--						ELSE '' END) + '</p>'   
						--				+ '<p>' +'Revision No: ' + ISNULL(CONVERT(VARCHAR(20),pub.RevisionNum),'-') + '</p>'  
						--				+ '<p>' +'Revision Date: ' + ISNULL(CONVERT(VARCHAR(100),pub.revisionDate,103),'-') + '</p> <p style="height:15px"></p>'  	 
						--		ELSE  '<p>' + ('Unit ' + ISNULL(UPPER(wosc.conditionName),'-')) + ' I/A/W CMM ATA: ' + ISNULL(UPPER(pub.PublicationId),0) + ' REV: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-')  + ' DATED: ' + UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) +'</p>'   
						--				+'<p>No FAA or '+ CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END +' S/B and AD`s complied with at this shop visit.</p>'   
						--				+ '<p>' +'Full details of work carried out held on Work Order: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(wo.WorkOrderNum)),'-') + '</p>  <br/>'  
						--		END ELSE '' END)   	  
							 (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
							+ (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)        
							+ '</div>' FooterRemarks,  
							UPPER(le.EASALicense) AS EASALicense,  
							@EmailBody AS EmailBody
							,@VersionNo VersionNo
					        ,0 AS IsVersionIncrease
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
					  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
					  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.CountriesId = @CountryId
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[ReceivingCustomerWork] rc  WITH(NOLOCK) ON rc.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id  
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
					  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
					  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wosc.RevisedPartId  
					  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.PublicationRecordId = @CMMIds 
					  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
					  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
					 -- LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
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
				  wop.RevisedPartDescription AS [Description],
				  wop.RevisedPartNumber AS PartNumber,  
				  wop.CustomerReference AS Reference,  
				  wop.Quantity AS Quantity,  
				  CASE WHEN ISNULL(wop.RevisedSerialNumber , '') = '' THEN UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN '' ELSE sl.SerialNumber END)
							ELSE UPPER(wop.RevisedSerialNumber) END AS Batchnumber,  
				  CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END AS [status],
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
				  0 Otherregulation,  
				  1 AS is8130from ,  
				  wop.ReceivedDate,  
				  wop.ManagementStructureId AS ManagementStructureId, 	
				  @IsMultiple AS IsMultiple,				
				  --UPPER(wosc.conditionName) AS ConditionName,
				  CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END AS ConditionName,
				  ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
				  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
				  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,
				  ISNULL(UPPER(pub2.PublicationId),0) AS SecondPublicationId,
				  ISNULL(CONVERT(VARCHAR(20),UPPER(pub2.RevisionNum)),'-') SecondRevisionNum,
				  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub2.revisionDate,106),' ','/'),'-')) SecondRevisionDate,
				  wo.[WorkOrderNum],				  				 
				  ISNULL(pub.[PublishedById],0) PublishedById,
				  ven.[VendorName],
				  mf.[Name] ManufacturerName,
				  pub.[PublishedByOthers],	
				  wo.[MasterCompanyId],
				  CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END AS IsEasaUKLicenseType,
				  ('<div style = "position:relative; min-height:90px;max-height:100px;  font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">') AS HeaderRemarks, 
				 -- ('<div style = "position:relative; min-height:90px;max-height:100px;  font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">' 
					--+ (CASE WHEN wop.CMMId is not null and wop.CMMId > 0 THEN   
					--		CASE WHEN wo.MasterCompanyId != @MTIMasterCompanyId THEN '<p>' + ('Publication ID: ' + ISNULL(UPPER(pub.PublicationId),0)) +'</p>'   
					--				+'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + ISNULL(UPPER(ven.VendorName),'-')  
					--							 WHEN pub.PublishedById = 3 THEN 'Published By: ' +  ISNULL(UPPER(mf.Name),'-')  
					--							 WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(UPPER(pub.PublishedByOthers),'-')  
					--						ELSE '' END) + '</p>'   
					--				+ '<p>' +'Revision No: ' + ISNULL(CONVERT(VARCHAR(20),pub.RevisionNum),'-') + '</p>'  
					--				+ '<p>' +'Revision Date: ' + ISNULL(CONVERT(VARCHAR(100),pub.revisionDate,103),'-') + '</p> <p style="height:15px"></p>'  	 
					--		ELSE  '<p>' + ('Unit ' + ISNULL(UPPER(wosc.conditionName),'-')) + ' I/A/W CMM ATA: ' + ISNULL(UPPER(pub.PublicationId),0) + ' REV: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-')  + ' DATED: ' + UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) +'</p>'   
					--				+'<p>No FAA or '+ CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END +' S/B and AD`s complied with at this shop visit.</p>'   
					--				+ '<p>' +'Full details of work carried out held on Work Order: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(wo.WorkOrderNum)),'-') + '</p>  <br/>'  
					--		END ELSE '' END)   	  
					--	+ (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
					--	+ (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)        
					--	+ '</div>') Remarks,  
						 (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
					   + (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)        
					   + '</div>' FooterRemarks,  
						UPPER(le.EASALicense) AS EASALicense,  
						@EmailBody AS EmailBody
					   ,@VersionNo VersionNo
					   ,0 AS IsVersionIncrease
			FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
				  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
				  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.CountriesId = @CountryId
				  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
				  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
				  LEFT JOIN [dbo].[ReceivingCustomerWork] rc  WITH(NOLOCK) ON rc.StockLineId = wop.StockLineId  
				  LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id  
				  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
				  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
				  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
				  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
				  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wosc.RevisedPartId  
				  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.[PublicationRecordId] = @CMMID1 
				  LEFT JOIN [dbo].[Publication] pub2 WITH(NOLOCK) ON pub2.[PublicationRecordId] = @CMMID2 				  
				  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
				  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
				 -- LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
				  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
			 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
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
					  wop.RevisedPartDescription AS [Description],
					  wop.RevisedPartNumber AS PartNumber,  
					  wop.CustomerReference AS Reference,  
					  wop.Quantity AS Quantity,  
					  CASE WHEN ISNULL(wop.RevisedSerialNumber , '') = '' THEN UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN '' ELSE sl.SerialNumber END)
								ELSE UPPER(wop.RevisedSerialNumber) END AS Batchnumber,  
					  CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END AS [status],
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
					  0 Otherregulation,  
					  1 AS is8130from ,  
					  wop.ReceivedDate,  
					  wop.ManagementStructureId AS ManagementStructureId, 
					  @IsMultiple AS IsMultiple,				 					  
					  CASE WHEN ISNULL(wop.[RevisedConditionId],0) > 0 THEN UPPER(C.[Memo]) ELSE UPPER(wosc.[conditionName]) END AS ConditionName,
					  ISNULL(UPPER(pub.PublicationId),0) AS PublicationId,
					  ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-') RevisionNum,
					  UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) RevisionDate,	
					  '' SecondPublicationId,
					  '' SecondRevisionNum,
					  '' SecondRevisionDate,		
					  wo.[WorkOrderNum],
					  ISNULL(pub.[PublishedById],0) PublishedById,
					  ven.[VendorName],
					  mf.[Name] [ManufacturerName],
					  pub.[PublishedByOthers],
					  wo.[MasterCompanyId],
					  CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN 'UK' ELSE 'EASA' END AS IsEasaUKLicenseType,
					  ('<div style = "position:relative; min-height:90px;max-height:100px;  font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:10px">') AS HeaderRemarks,   				
					  (CASE WHEN @IsEasaLicense = 1 AND @formTypeId = @FAAEASA THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.EASALicense +'</div>') ELSE ''  END)        
					+ (CASE WHEN @IsEasaUKLicense = 1 AND @formTypeId = @FAAEASAUK THEN '<div style='+ '"bottom : 0px; position:absolute;font-size: 10px !important;line-height: 12px;"'+'>' + (REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</div>') ELSE ''  END)        
					+ '</div>' FooterRemarks,  
					   UPPER(le.EASALicense) AS EASALicense,  
					   @EmailBody AS EmailBody
					   ,@VersionNo VersionNo
					   ,0 AS IsVersionIncrease
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
					  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
					  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.CountriesId = @CountryId
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[ReceivingCustomerWork] rc  WITH(NOLOCK) ON rc.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id  
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
					  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
					  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wosc.RevisedPartId  
					  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON pub.PublicationRecordId = @CMMIds 
					  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
					  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId 
		END

  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkorderReleaseFromData'                
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