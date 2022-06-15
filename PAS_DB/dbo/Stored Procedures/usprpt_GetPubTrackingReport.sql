
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
				@IsDownload BIT = NULL;
  
  BEGIN TRY  
    
	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Entry Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Entry Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end		
	  FROM
		  @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)

	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END

	  IF ISNULL(@PageSize,0)=0
	  BEGIN 
		  SELECT @PageSize=COUNT(*) 
		  FROM (SELECT PUB.publicationid
		  FROM DBO.Publication PUB WITH (NOLOCK)
			LEFT JOIN DBO.PublicationItemMasterMapping PIMM WITH (NOLOCK) ON PUB.PublicationRecordId = PIMM.PublicationRecordId
			INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON PIMM.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.WorkflowPublications WFPUB WITH (NOLOCK) ON PUB.PublicationRecordId = WFPUB.PublicationId
			LEFT JOIN DBO.Location LC WITH (NOLOCK) ON PUB.LocationId = LC.LocationId
			LEFT JOIN DBO.Employee E WITH (NOLOCK) ON PUB.VerifiedBy = E.EmployeeId
			LEFT JOIN DBO.Manufacturer MNFR WITH (NOLOCK) ON IM.ManufacturerId = MNFR.ManufacturerId
			LEFT JOIN DBO.PublicationType PUBType WITH (NOLOCK) ON PUB.PublicationTypeId = PUBType.PublicationTypeId
			LEFT JOIN DBO.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON IM.ItemMasterId = IMAM.ItemMasterId
			OUTER APPLY (SELECT (STUFF((SELECT DISTINCT ', '+ (IMAM.Level1 + CASE WHEN ISNULL(IMAM.Level2,'')<> '' THEN '-' + IMAM.Level2 ELSE '' END + 
			CASE WHEN ISNULL(IMAM.Level3,'')<> '' THEN '-' + IMAM.Level3 ELSE '' END) from ItemMasterATAMapping IMAM 
			  where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,''))as 'atachapter') T
		  WHERE PUB.entrydate BETWEEN (@Fromdate) AND (@Todate) AND PUB.MasterCompanyId = @mastercompanyid
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
        IMAM.aircraftmodel 'model',
        IMAM.AircraftType 'aircraft',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN T.atachapter ELSE T.atachapter + '&nbsp;' END 'atachapter',
		PUB.revisionnum 'revnum',        
        E.firstname + ' ' + E.lastname 'verifiedby',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.EntryDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.EntryDate, 107) END 'entrydate', 
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.revisiondate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.revisiondate, 107) END 'revdate',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.expirationdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.expirationdate, 107) END 'expdate',
		CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(PUB.nextreviewdate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), PUB.nextreviewdate, 107) END 'nxtrevieweddate'
      FROM DBO.Publication PUB WITH (NOLOCK)
	    LEFT JOIN DBO.PublicationItemMasterMapping PIMM WITH (NOLOCK) ON PUB.PublicationRecordId = PIMM.PublicationRecordId
        INNER JOIN DBO.Itemmaster IM WITH (NOLOCK) ON PIMM.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkflowPublications WFPUB WITH (NOLOCK) ON PUB.PublicationRecordId = WFPUB.PublicationId
		LEFT JOIN DBO.Location LC WITH (NOLOCK) ON PUB.LocationId = LC.LocationId
        LEFT JOIN DBO.Employee E WITH (NOLOCK) ON PUB.VerifiedBy = E.EmployeeId
        LEFT JOIN DBO.Manufacturer MNFR WITH (NOLOCK) ON IM.ManufacturerId = MNFR.ManufacturerId
        LEFT JOIN DBO.PublicationType PUBType WITH (NOLOCK) ON PUB.PublicationTypeId = PUBType.PublicationTypeId
        LEFT JOIN DBO.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON IM.ItemMasterId = IMAM.ItemMasterId
		OUTER APPLY (SELECT (STUFF((SELECT DISTINCT ', '+ (IMAM.Level1 + CASE WHEN ISNULL(IMAM.Level2,'')<> '' THEN '-' + IMAM.Level2 ELSE '' END + 
	    CASE WHEN ISNULL(IMAM.Level3,'')<> '' THEN '-' + IMAM.Level3 ELSE '' END) from ItemMasterATAMapping IMAM 
		  where IM.ItemMasterId = IMAM.ItemMasterId FOR XML PATH('')),1,1,''))as 'atachapter') T
	  WHERE PUB.entrydate BETWEEN (@Fromdate) AND (@Todate) AND PUB.MasterCompanyId = @mastercompanyid
      GROUP BY IM.partnumber, IM.PartDescription, MNFR.name,PUB.publicationid,PUB.Description,PUBType.name, LC.Name, WFPUB.Source, 
			   IMAM.aircraftmodel, IMAM.AircraftType,T.atachapter,PUB.revisionnum,
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