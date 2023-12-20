/*************************************************************             
 ** File:   [usprpt_GetCapabilitiesReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for Capabilities Report   
 ** Purpose:           
 ** Date:   26-April-2022         
            
 ** PARAMETERS:             
     
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    26-April-2022  Mahesh Sorathiya   Created 
	2    04-SEPT-2023   Ekta Chandegra     Convert text into uppercase
       
EXECUTE   [dbo].[usprpt_GetCapabilitiesReport] '','2',3,'','1','10','0'  
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[usprpt_GetCapabilitiesReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  declare @partnumber varchar(40) = NULL,  
	@isverified int = NULL, 
	@tagtype varchar(50) = NULL,
	@level1 VARCHAR(MAX) = NULL,
	@level2 VARCHAR(MAX) = NULL,
	@level3 VARCHAR(MAX) = NULL,
	@level4 VARCHAR(MAX) = NULL,
	@Level5 VARCHAR(MAX) = NULL,
	@Level6 VARCHAR(MAX) = NULL,
	@Level7 VARCHAR(MAX) = NULL,
	@Level8 VARCHAR(MAX) = NULL,
	@Level9 VARCHAR(MAX) = NULL,
	@Level10 VARCHAR(MAX) = NULL,
	@IsDownload BIT = NULL

  BEGIN TRY 
      
	SELECT 
	@partnumber=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)' 
	then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @partnumber end,
	@isverified=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Verified' 
	then convert(int,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @isverified end,
	@tagtype=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Tag Type' 
	then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @tagtype end,
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
	 
      DECLARE @ModuleID INT = 8; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	   IF ISNULL(@PageSize,0)=0
		BEGIN 
		  SELECT @PageSize=COUNT(*)
		  FROM DBO.ItemMasterCapes IMC WITH (NOLOCK)  
		  INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON IMC.itemmasterid = IM.itemmasterid  
		  INNER JOIN dbo.ItemMasterManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = imc.ItemMasterCapesId
		  LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
		  WHERE IM.ItemMasterId=ISNULL(@partnumber,IM.ItemMasterId)    
		  AND IMC.mastercompanyid = @mastercompanyid 
		  AND (IMC.isverified =  CASE WHEN @isverified = 1 THEN 1 ELSE CASE WHEN @isverified = 2 THEN 0 END  END  OR (@isverified = 3  
		  AND IMC.isverified IS NOT NULL AND IMC.mastercompanyid = @mastercompanyid))
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
		END
	  
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
    
      SELECT COUNT(1) OVER () AS TotalRecordsCount, 
        UPPER(IM.partnumber) 'pn',  
        UPPER(IM.partdescription) 'pndescription',  
		UPPER(IM.ManufacturerName) 'manufacturerName',  
        (STUFF((SELECT DISTINCT ', '+ UPPER(IMAIR.AircraftType) FROM ItemMasterAircraftMapping IMAIR Where  IM.ItemMasterId = IMAIR.ItemMasterId FOR XML PATH('')),1,1,'')) as 'aircraft',
       	(STUFF((SELECT DISTINCT ', '+ UPPER(IMAIR.aircraftmodel) FROM ItemMasterAircraftMapping IMAIR Where IMAIR.aircraftmodel not like '%Unknown%' AND IM.ItemMasterId = IMAIR.ItemMasterId FOR XML PATH('')),1,1,''))as 'model', 
        (STUFF((SELECT DISTINCT ', '+ UPPER(IMAIR.Dashnumber) FROM ItemMasterAircraftMapping IMAIR Where IMAIR.Dashnumber not like '%Unknown%' AND IM.ItemMasterId = IMAIR.ItemMasterId FOR XML PATH('')),1,1,'')) as 'dash', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN (STUFF((SELECT DISTINCT ', '+ (IMAM.Level1 + CASE WHEN ISNULL(IMAM.Level2,'')<> '' THEN '-' + IMAM.Level2 ELSE '' END + 
	    CASE WHEN ISNULL(IMAM.Level3,'')<> '' THEN '-' + IMAM.Level3  ELSE '' END) from ItemMasterATAMapping IMAM where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,'')) ELSE (STUFF((SELECT DISTINCT ', '+ (IMAM.Level1 + CASE WHEN ISNULL(IMAM.Level2,'')<> '' THEN '-' + IMAM.Level2 ELSE '' END + 
	    CASE WHEN ISNULL(IMAM.Level3,'')<> '' THEN '-' + IMAM.Level3  ELSE '' END) from ItemMasterATAMapping IMAM where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,'')) + '' END as 'atachapter',
        UPPER(IMC.CapabilityType) 'capabilitytype',  
        case when Isnull(IMC.isverified,0) = 0 then UPPER('No') else UPPER('Yes')  end   'verified',  
        UPPER(IMC.VerifiedBy) 'Verified BY',  
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(IMC.VerifiedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), IMC.VerifiedDate, 107) END 'dateverified', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(IMC.AddedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), IMC.AddedDate, 107) END 'dateadded', 
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
      FROM DBO.ItemMasterCapes IMC WITH (NOLOCK)  
      INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON IMC.itemmasterid = IM.itemmasterid  
      INNER JOIN dbo.ItemMasterManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = imc.ItemMasterCapesId
	  LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
      WHERE IM.ItemMasterId=ISNULL(@partnumber,IM.ItemMasterId)  
      AND IMC.mastercompanyid = @mastercompanyid 
      AND (IMC.isverified =  CASE WHEN @isverified = 1 THEN 1 ELSE CASE WHEN @isverified = 2 THEN 0 END  END  OR (@isverified = 3  
      AND IMC.isverified IS NOT NULL AND IMC.mastercompanyid = @mastercompanyid))
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
	   ORDER BY IM.partnumber
	   OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;
   
  END TRY  
  
  BEGIN CATCH  

    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetCapabilitiesReport]',  
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