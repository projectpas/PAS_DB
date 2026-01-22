/*************************************************************           
 ** File:   [usp_GetPubTrackingReport]           
 ** Author:   Swetha  
 ** Description: Get Data for PubTracking Report  
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha Created
	2	        	  Swetha Added Transaction & NO LOCK
     
EXECUTE   [dbo].[usp_GetPubTrackingReport] '2020-06-15','2021-06-15','1'
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetPubTrackingReport] @Fromdate datetime,
@Todate datetime,
@mastercompanyid int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
      SELECT DISTINCT
        (IM.partnumber) 'PN',
        (IM.PartDescription) 'PN Description',
        MNFR.name 'Manufacturer',
        PUB.publicationid 'Pub ID',
        PUB.Description 'Pub Description',
        PUBType.name 'Pub Type',
        WFPUB.Location 'Location',
        WFPUB.Source 'Source',
        Aircraftmodel.ModelName 'Model',
        AT.description 'Aircraft',
        IMATAM.ATAChapterCode + '-' + IMATAM.ATAChapterName 'ATA Chatper',
        PUB.revisionnum 'Revision Num',
        CONVERT(varchar, PUB.revisiondate, 101) 'Revision Date',
        E.firstname + ' ' + E.lastname 'Verified By',
        CONVERT(varchar, PUB.expirationdate, 101) 'Expiration Date',
        CONVERT(varchar, PUB.nextreviewdate, 101) 'Next Review Date'
      FROM DBO.Publication PUB WITH (NOLOCK)
      LEFT JOIN DBO.PublicationItemMasterMapping PIMM WITH (NOLOCK)
        ON PUB.PublicationRecordId = PIMM.PublicationRecordId
        INNER JOIN DBO.Itemmaster IM WITH (NOLOCK)
          ON PIMM.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkflowPublications WFPUB WITH (NOLOCK)
          ON PUB.PublicationRecordId = WFPUB.PublicationId
        LEFT JOIN DBO.Employee E WITH (NOLOCK)
          ON PUB.VerifiedBy = E.EmployeeId
        INNER JOIN DBO.ItemMasterATAMapping IMATAM WITH (NOLOCK)
          ON IM.ItemMasterId = IMATAM.ItemMasterId
        --LEFT JOIN Workflow WF ON WFPUB.WorkflowId=WF.WorkflowId
        LEFT JOIN DBO.WorkOrderPublications WOP WITH (NOLOCK)
          ON PUB.PublicationRecordId = WOP.PublicationId
        INNER JOIN DBO.Manufacturer MNFR WITH (NOLOCK)
          ON IM.ManufacturerId = MNFR.ManufacturerId
        LEFT JOIN DBO.PublicationType PUBType WITH (NOLOCK)
          ON PUB.PublicationTypeId = PUBType.PublicationTypeId
        LEFT JOIN DBO.ItemMasterAircraftMapping IMAM WITH (NOLOCK)
          ON IM.ItemMasterId = IMAM.ItemMasterId
        INNER JOIN DBO.AircraftModel WITH (NOLOCK)
          ON IMAM.AircraftModelId = AircraftModel.AircraftModelId
        LEFT JOIN DBO.aircrafttype AT WITH (NOLOCK)
          ON AircraftModel.aircrafttypeid = AT.aircrafttypeid
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON PUB.MasterCompanyId = MC.MasterCompanyId
      WHERE PUB.entrydate BETWEEN (@Fromdate) AND (@Todate)
      AND PUB.MasterCompanyId = @mastercompanyid
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION
    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetPubTrackingReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR (
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
    , 16
    , 1
    , @ErrorLogID
    )

    RETURN (1);

  END CATCH
  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END