
/*************************************************************             
 ** File:   [usprpt_GetPubTrackingReport]             
 ** Author:   Mahesh Sorathiya    
 ** Description: Get Data for Publication Tracking (CMM) Report  
 ** Purpose:           
 ** Date:   06-May-2022         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    06-May-2022  Mahesh Sorathiya   Created  

**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetPubTrackingReport] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
  
		DECLARE @fromdate datetime,  
		        @todate datetime,
				@IsDownload BIT = NULL,
				@level1 VARCHAR(MAX) = NULL,
		        @level2 VARCHAR(MAX) = NULL,
		        @level3 VARCHAR(MAX) = NULL,
		        @level4 VARCHAR(MAX) = NULL,
		        @Level5 VARCHAR(MAX) = NULL,
		        @Level6 VARCHAR(MAX) = NULL,
		        @Level7 VARCHAR(MAX) = NULL,
		        @Level8 VARCHAR(MAX) = NULL,
		        @Level9 VARCHAR(MAX) = NULL,
		        @Level10 VARCHAR(MAX) = NULL;
  
  BEGIN TRY  
    
	   SELECT 
		    @fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Entry Date' 
		    then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		    @todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Entry Date' 
		    then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,	
		
		    @level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,

			@level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,

			@level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,

			@level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,

			@level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,

			@level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,

			@level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,

			@level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,

			@level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,

			@level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10' 
			THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end

	  FROM
		  @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)

	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	  DECLARE @ModuleID INT = 60; -- MS Module ID
	  IF ISNULL(@PageSize,0)=0
	  BEGIN 
		  SELECT @PageSize=COUNT(*) 
		  FROM (SELECT PUB.publicationid
		  FROM DBO.Publication PUB WITH (NOLOCK)
			INNER JOIN DBO.PublicationItemMasterMapping PIMM WITH (NOLOCK) ON PUB.PublicationRecordId = PIMM.PublicationRecordId AND PIMM.IsActive = 1 AND PIMM.IsDeleted = 0
			INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON PIMM.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.WorkflowPublications WFPUB WITH (NOLOCK) ON PUB.PublicationRecordId = WFPUB.PublicationId
			LEFT JOIN DBO.Location LC WITH (NOLOCK) ON PUB.LocationId = LC.LocationId
			LEFT JOIN DBO.Employee E WITH (NOLOCK) ON PUB.VerifiedBy = E.EmployeeId
			LEFT JOIN DBO.Manufacturer MNFR WITH (NOLOCK) ON IM.ManufacturerId = MNFR.ManufacturerId
			LEFT JOIN DBO.PublicationType PUBType WITH (NOLOCK) ON PUB.PublicationTypeId = PUBType.PublicationTypeId
			LEFT JOIN DBO.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON IM.ItemMasterId = IMAM.ItemMasterId
			INNER JOIN dbo.PublicationManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.PublicationRecordId = PUB.PublicationRecordId
			OUTER APPLY (SELECT (STUFF((SELECT DISTINCT ', '+ (IMAM.Level1 + CASE WHEN ISNULL(IMAM.Level2,'')<> '' THEN '-' + IMAM.Level2 ELSE '' END + 
			CASE WHEN ISNULL(IMAM.Level3,'')<> '' THEN '-' + IMAM.Level3 ELSE '' END) from ItemMasterATAMapping IMAM 
			  where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,''))as 'atachapter') T
		  WHERE PUB.entrydate BETWEEN (@Fromdate) AND (@Todate) AND PUB.MasterCompanyId = @mastercompanyid AND PUB.IsActive = 1 AND PUB.IsDeleted = 0
		        AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		  GROUP BY IM.partnumber, IM.PartDescription, MNFR.name,PUB.publicationid,PUB.Description,PUBType.name, LC.Name, WFPUB.Source, 
			   IMAM.aircraftmodel, IMAM.AircraftType,T.atachapter,PUB.revisionnum,FORMAT(PUB.revisiondate, 'MM/dd/yyyy'),FORMAT(PUB.EntryDate, 'MM/dd/yyyy'),
	           E.firstname + ' ' + E.lastname,FORMAT(PUB.expirationdate, 'MM/dd/yyyy'), FORMAT(PUB.nextreviewdate, 'MM/dd/yyyy'),cast(PUB.EntryDate as date)
			) TEMP
	  END

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END

      SELECT COUNT(1) OVER () AS TotalRecordsCount, 
		(IM.partnumber) 'pn',
        (IM.PartDescription) 'pndescription',
        MNFR.name 'manufacturer',
        PUB.publicationid 'pubid',
        PUB.Description 'pubdescription',
        PUBType.name 'pubtype',
        LC.Name 'location',
        WFPUB.Source 'source',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN M.model ELSE M.model + '&nbsp;' END 'model',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN A.aircraft ELSE A.aircraft + '&nbsp;' END 'aircraft',
        --IMAM.aircraftmodel 'model',
        --IMAM.AircraftType 'aircraft',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN T.atachapter ELSE T.atachapter + '&nbsp;' END 'atachapter',
		PUB.revisionnum 'revnum',        
        E.firstname + ' ' + E.lastname 'verifiedby',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.EntryDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.EntryDate, 107) END 'entrydate', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.revisiondate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.revisiondate, 107) END 'revdate',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.expirationdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.expirationdate, 107) END 'expdate',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.nextreviewdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.nextreviewdate, 107) END 'nxtrevieweddate',
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
      FROM DBO.Publication PUB WITH (NOLOCK)
	    INNER JOIN DBO.PublicationItemMasterMapping PIMM WITH (NOLOCK) ON PUB.PublicationRecordId = PIMM.PublicationRecordId AND PIMM.IsActive = 1 AND PIMM.IsDeleted = 0
        INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON PIMM.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkflowPublications WFPUB WITH (NOLOCK) ON PUB.PublicationRecordId = WFPUB.PublicationId
		LEFT JOIN DBO.Location LC WITH (NOLOCK) ON PUB.LocationId = LC.LocationId
        LEFT JOIN DBO.Employee E WITH (NOLOCK) ON PUB.VerifiedBy = E.EmployeeId
        LEFT JOIN DBO.Manufacturer MNFR WITH (NOLOCK) ON IM.ManufacturerId = MNFR.ManufacturerId
        LEFT JOIN DBO.PublicationType PUBType WITH (NOLOCK) ON PUB.PublicationTypeId = PUBType.PublicationTypeId
        --LEFT JOIN DBO.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON IM.ItemMasterId = IMAM.ItemMasterId
		INNER JOIN dbo.PublicationManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.PublicationRecordId = PUB.PublicationRecordId
		OUTER APPLY (SELECT (STUFF((SELECT DISTINCT ', '+ (IMAM.Level1 + CASE WHEN ISNULL(IMAM.Level2,'')<> '' THEN '-' + IMAM.Level2 ELSE '' END + 
	    CASE WHEN ISNULL(IMAM.Level3,'')<> '' THEN '-' + IMAM.Level3 ELSE '' END) from ItemMasterATAMapping IMAM 
		  where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,''))as 'atachapter') T
		OUTER APPLY (SELECT (STUFF((SELECT DISTINCT ', '+ (IMAM.aircraftmodel) from ItemMasterAircraftMapping IMAM 
		  where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,''))as 'model') M
		OUTER APPLY (SELECT (STUFF((SELECT DISTINCT ', '+ (IMAM.AircraftType) from ItemMasterAircraftMapping IMAM 
		  where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,''))as 'aircraft') A
	  WHERE PUB.entrydate BETWEEN (@Fromdate) AND (@Todate) AND PUB.MasterCompanyId = @mastercompanyid AND PUB.IsActive = 1 AND PUB.IsDeleted = 0
	            AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
				AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
				AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
				AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
				AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
				AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
				AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
				AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
				AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
				AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
      GROUP BY IM.partnumber, IM.PartDescription, MNFR.name,PUB.publicationid,PUB.Description,PUBType.name, LC.Name, WFPUB.Source, 
			   T.atachapter,M.model,A.aircraft,PUB.revisionnum,MSD.Level1Name,MSD.Level2Name,MSD.Level3Name,MSD.Level4Name,MSD.Level5Name,MSD.Level6Name,MSD.Level7Name,MSD.Level8Name,MSD.Level9Name,MSD.Level10Name,
			   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.EntryDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.EntryDate, 107) END, 
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.revisiondate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.revisiondate, 107) END ,
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.expirationdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.expirationdate, 107) END ,
				CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.nextreviewdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.nextreviewdate, 107) END ,
	           E.firstname + ' ' + E.lastname,cast(PUB.EntryDate as date)
	  ORDER BY cast(PUB.EntryDate as date) desc
			OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY;  
   
  END TRY  
  
  BEGIN CATCH  
    
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetPubTrackingReport]',  
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
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
   
END