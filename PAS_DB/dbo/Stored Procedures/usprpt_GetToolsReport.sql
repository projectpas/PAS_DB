
/*************************************************************             
 ** File:   [usprpt_GetToolsReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for Tools Report    
 ** Purpose:           
 ** Date:   25-Apr-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    25-April-2022  Mahesh Sorathiya   Created 
       
EXECUTE   [dbo].[usprpt_GetToolsReport] '2022-04-25','2','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'  
**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetToolsReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
	DECLARE @tagtype varchar(50) = NULL,
	@certifytype varchar(100) = NULL,
	@level1 VARCHAR(MAX) = NULL,
	@level2 VARCHAR(MAX) = NULL,
	@level3 VARCHAR(MAX) = NULL,
	@level4 VARCHAR(MAX) = NULL,
	@Level5 VARCHAR(MAX) = NULL,
	@Level6 VARCHAR(MAX) = NULL,
	@Level7 VARCHAR(MAX) = NULL,
	@Level8 VARCHAR(MAX) = NULL,
	@Level9 VARCHAR(MAX) = NULL,
	@Level10 VARCHAR(MAX) = NULL 

  BEGIN TRY  
      
	  DECLARE @ModuleID varchar(500) ='40,41'; -- MS Module ID

	  SELECT 
		@tagtype=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @tagtype end,
		@certifytype=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Certify Type' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @certifytype end,
		@level1=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level1 end,
		@level2=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level2 end,
		@level3=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level3 end,
		@level4=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level4 end,
		@level5=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level5 end,
		@level6=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level6 end,
		@level7=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level7 end,
		@level8=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level8 end,
		@level9=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level9 end,
		@level10=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level10 end
	  FROM
		  @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)


		declare @isCalb bit=null;
		declare @isCert bit=null;
		declare @isVerf bit=null;
		declare @isIns bit=null;
		IF ISNULL(@certifytype,'')<>''
		BEGIN
			if exists(SELECT value FROM String_split(ISNULL(@certifytype,''), ',') where value=1)
			  SET @isCalb =1;
			if exists(SELECT value FROM String_split(ISNULL(@certifytype,''), ',') where value=2)
			  SET @isCert =1;
			if exists(SELECT value FROM String_split(ISNULL(@certifytype,''), ',') where value=3)
			  SET @isIns =1;
			if exists(SELECT value FROM String_split(ISNULL(@certifytype,''), ',') where value=4)
			  SET @isVerf =1;
		END

	   IF ISNULL(@PageSize,0)=0
		BEGIN 
			  SELECT @PageSize=COUNT(*) 
			  FROM (SELECT Asset.assetid
			  FROM dbo.asset WITH (NOLOCK) 
				LEFT JOIN DBO.Assetinventory AI WITH (NOLOCK) ON Asset.assetrecordid = AI.AssetRecordId
				INNER JOIN dbo.AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = asset.AssetRecordId
				LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
				LEFT JOIN DBO.Assetstatus WITH (NOLOCK) ON AI.AssetStatusId = AssetStatus.assetstatusid  
				LEFT JOIN DBO.AssetLocation AL WITH (NOLOCK) ON AI.AssetLocationId = AL.AssetLocationId  
				LEFT JOIN DBO.AssetCalibration AC WITH (NOLOCK)  ON Asset.AssetRecordId = AC.AssetRecordId   
				--LEFT JOIN DBO.AssetType WITH (NOLOCK) ON Asset.TangibleClassId = AssetType.AssetTypeId  
				LEFT JOIN DBO.Vendor VNDR WITH (NOLOCK) ON AC.CalibrationDefaultVendorId = VNDR.VendorId  
				LEFT JOIN DBO.Vendor VNDR1 WITH (NOLOCK) ON AC.CertificationDefaultVendorId = VNDR1.VendorId  
				LEFT JOIN DBO.assetcapes ACS WITH (NOLOCK) ON Asset.assetrecordid = ACS.assetrecordid  
				--LEFT JOIN DBO.itemmaster IM WITH (NOLOCK) ON ACS.itemmasterId = IM.ItemMasterId  
				LEFT JOIN dbo.AssetAttributeType asty WITH(NOLOCK) on asset.TangibleClassId = asty.TangibleClassId  
				OUTER APPLY(select TOP 1 LastCalibrationDate,NextCalibrationDate,LastCalibrationBy,CalibrationDate FROM dbo.CalibrationManagment cm WITH(NOLOCK) 
				WHERE cm.AssetInventoryId = AI.AssetInventoryId AND CertifyType='Calibration') cb
				OUTER APPLY(select TOP 1 LastCalibrationDate,NextCalibrationDate,LastCalibrationBy,CalibrationDate FROM dbo.CalibrationManagment cm WITH(NOLOCK) 
				WHERE cm.AssetInventoryId = AI.AssetInventoryId AND CertifyType='Certification') cf 
			  WHERE asset.mastercompanyid = @mastercompanyid 
				AND ((ISNULL(@certifytype,'')='') OR (ISNULL(@certifytype,'')<>'' AND (@isCalb IS NOT NULL AND AC.CalibrationRequired= 1) OR (@isCert IS NOT NULL AND AC.CertificationRequired= 1)
				OR (@isIns IS NOT NULL AND AC.InspectionRequired= 1) OR (@isVerf IS NOT NULL AND AC.VerificationRequired= 1))) 
			  AND  
				(ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
				AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
			GROUP BY Asset.assetid,AI.PartNumber,AI.InventoryNumber,AI.serialno,asty.AssetAttributeTypeName,FORMAT(Asset.EntryDate, 'MM/dd/yyyy'),
				AssetStatus.name,AC.calibrationrequired,
				AC.certificationrequired,AC.inspectionrequired,AC.verificationrequired,VNDR.vendorname,VNDR1.vendorname,UPPER(AL.Code + '-' + AL.name),
				FORMAT(cb.LastCalibrationDate, 'MM/dd/yyyy'),cb.LastCalibrationBy, cf.LastCalibrationBy,CASE WHEN ISNULL(cb.LastCalibrationBy,'')<>'' THEN
				FORMAT(DATEADD(DAY, ISNULL(AC.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(AC.CalibrationFrequencyMonths,0),getdate())), 'MM/dd/yyyy') END,
				CASE WHEN ISNULL(cf.LastCalibrationBy,'')<>'' THEN
				FORMAT(DATEADD(DAY, ISNULL(AC.CertificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(AC.CertificationFrequencyMonths,0),getdate())), 'MM/dd/yyyy') END,
				MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name
				) TEMP
	 		
		END
	  
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

      SELECT COUNT(1) OVER () AS TotalRecordsCount,  
        UPPER(Asset.assetid) 'assetid',		
        UPPER(AI.PartNumber) 'pn',  
        UPPER(AI.InventoryNumber) 'invnum',  
        UPPER(AI.serialno) 'sernum',  
        UPPER(asty.AssetAttributeTypeName) 'assetclass',  
        FORMAT(Asset.EntryDate, 'MM/dd/yyyy') 'entrydate',  
        UPPER(AssetStatus.name) 'status',  
        case when Isnull(AC.calibrationrequired,0) = 0 then 'NO' else 'YES'  end  'calreq',  
        FORMAT(cb.LastCalibrationDate, 'MM/dd/yyyy') 'lstcaldate',  
        UPPER(cb.LastCalibrationBy) 'lstcalby',  
		CASE WHEN ISNULL(cb.LastCalibrationBy,'')<>'' THEN
        FORMAT(DATEADD(DAY, ISNULL(AC.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(AC.CalibrationFrequencyMonths,0),getdate())), 'MM/dd/yyyy') END  'nxtcaldate',  
        case when Isnull(AC.certificationrequired,0) = 0 then 'NO' else 'YES'  end 'certreq',  
        UPPER(cf.LastCalibrationBy) 'lstcertby',  
        CASE WHEN ISNULL(cf.LastCalibrationBy,'')<>'' THEN
		FORMAT(DATEADD(DAY, ISNULL(AC.CertificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(AC.CertificationFrequencyMonths,0),getdate())), 'MM/dd/yyyy') END 'nxtcertdate',  
        case when Isnull(AC.inspectionrequired,0) = 0 then 'NO' else 'YES'  end  'insreq',  
        case when Isnull(AC.verificationrequired,0) = 0 then 'NO' else 'YES' end  'verreq',  
        'N/A' 'noncal',  
        UPPER(AL.Code + '-' + AL.name) 'location',
		UPPER(MSD.Level1Name) AS level1,  
		UPPER(MSD.Level2Name) AS level2, 
		UPPER(MSD.Level3Name) AS level3, 
		UPPER(MSD.Level4Name) AS level4, 
		UPPER(MSD.Level5Name) AS level5, 
		UPPER(MSD.Level6Name) AS level6, 
		UPPER(MSD.Level7Name) AS level7, 
		UPPER(MSD.Level8Name) AS level8, 
		UPPER(MSD.Level9Name) AS level9, 
		UPPER(MSD.Level10Name) AS level10      
      FROM dbo.asset WITH (NOLOCK) 
	    LEFT JOIN DBO.Assetinventory AI WITH (NOLOCK) ON Asset.assetrecordid = AI.AssetRecordId
	    INNER JOIN dbo.AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING('40,41',',')) AND MSD.ReferenceID = asset.AssetRecordId
		LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
        LEFT JOIN DBO.Assetstatus WITH (NOLOCK) ON AI.AssetStatusId = AssetStatus.assetstatusid  
        LEFT JOIN DBO.AssetLocation AL WITH (NOLOCK) ON AI.AssetLocationId = AL.AssetLocationId  
        LEFT JOIN DBO.AssetCalibration AC WITH (NOLOCK)  ON Asset.AssetRecordId = AC.AssetRecordId   
        --LEFT JOIN DBO.AssetType WITH (NOLOCK) ON Asset.TangibleClassId = AssetType.AssetTypeId  
        LEFT JOIN DBO.Vendor VNDR WITH (NOLOCK) ON AC.CalibrationDefaultVendorId = VNDR.VendorId  
        LEFT JOIN DBO.Vendor VNDR1 WITH (NOLOCK) ON AC.CertificationDefaultVendorId = VNDR1.VendorId  
        LEFT JOIN DBO.assetcapes ACS WITH (NOLOCK) ON Asset.assetrecordid = ACS.assetrecordid  
        --LEFT JOIN DBO.itemmaster IM WITH (NOLOCK) ON ACS.itemmasterId = IM.ItemMasterId  
        LEFT JOIN dbo.AssetAttributeType asty WITH(NOLOCK) on asset.TangibleClassId = asty.TangibleClassId  
		OUTER APPLY(select TOP 1 LastCalibrationDate,NextCalibrationDate,LastCalibrationBy,CalibrationDate FROM dbo.CalibrationManagment cm WITH(NOLOCK) 
		WHERE cm.AssetInventoryId = AI.AssetInventoryId AND CertifyType='Calibration') cb
		OUTER APPLY(select TOP 1 LastCalibrationDate,NextCalibrationDate,LastCalibrationBy,CalibrationDate FROM dbo.CalibrationManagment cm WITH(NOLOCK) 
		WHERE cm.AssetInventoryId = AI.AssetInventoryId AND CertifyType='Certification') cf 
	  WHERE asset.mastercompanyid = @mastercompanyid 
		AND ((ISNULL(@certifytype,'')='') OR (ISNULL(@certifytype,'')<>'' AND (@isCalb IS NOT NULL AND AC.CalibrationRequired= 1) OR (@isCert IS NOT NULL AND AC.CertificationRequired= 1)
		OR (@isIns IS NOT NULL AND AC.InspectionRequired= 1) OR (@isVerf IS NOT NULL AND AC.VerificationRequired= 1))) 
	  AND  
			(ISNULL(@tagtype,'')='' OR ES.OrganizationTagTypeId IN(SELECT value FROM String_split(ISNULL(@tagtype,''), ',')))
			AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
	  GROUP BY Asset.assetid,AI.PartNumber,AI.InventoryNumber,AI.serialno,asty.AssetAttributeTypeName,FORMAT(Asset.EntryDate, 'MM/dd/yyyy'),
	    AssetStatus.name,AC.calibrationrequired,
	    AC.certificationrequired,AC.inspectionrequired,AC.verificationrequired,VNDR.vendorname,VNDR1.vendorname,UPPER(AL.Code + '-' + AL.name),
		FORMAT(cb.LastCalibrationDate, 'MM/dd/yyyy'),cb.LastCalibrationBy, cf.LastCalibrationBy,CASE WHEN ISNULL(cb.LastCalibrationBy,'')<>'' THEN
        FORMAT(DATEADD(DAY, ISNULL(AC.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(AC.CalibrationFrequencyMonths,0),getdate())), 'MM/dd/yyyy') END,
		CASE WHEN ISNULL(cf.LastCalibrationBy,'')<>'' THEN
		FORMAT(DATEADD(DAY, ISNULL(AC.CertificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(AC.CertificationFrequencyMonths,0),getdate())), 'MM/dd/yyyy') END,
		MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name
	  ORDER BY Asset.assetid
	  OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
  END TRY  
  
  BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usprpt_GetToolsReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
    
END