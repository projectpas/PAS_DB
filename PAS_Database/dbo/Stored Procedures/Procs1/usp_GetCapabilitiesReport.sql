
/*************************************************************           
 ** File:   [usp_GetCapabilitiesReport]           
 ** Author:   Swetha  
 ** Description: Get Data for Capabilities Report 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author    Change Description            
 ** --   --------     -------    --------------------------------          
    1                 Swetha	Created
    2                 Swetha	Added Transaction & NO LOCK
     
EXECUTE   [dbo].[usp_GetCapabilitiesReport] '','4',3,'4','0','0','0'
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetCapabilitiesReport] @partnumber varchar(40) = NULL,
@mastercompanyid int,
@isverified int = NULL,
@Level1 varchar(max) = NULL,
@Level2 varchar(max) = NULL,
@Level3 varchar(max) = NULL,
@Level4 varchar(max) = NULL
--@asofdate datetime = NULL

AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
      BEGIN
        DROP TABLE #managmetnstrcture
      END

      CREATE TABLE #managmetnstrcture (
        id bigint NOT NULL IDENTITY,
        managementstructureid bigint NULL,
      )

      IF (ISNULL(@Level4, '0') != '0'
        AND ISNULL(@Level3, '0') != '0'
        AND ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level4, ',')
      END
      ELSE
      IF  (ISNULL(@Level3, '0') != '0'
        AND ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level3, ',')

      END
      ELSE
      IF (ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level2, ',')
      END
      ELSE
      IF ISNULL(@Level1, '0') != '0'
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level1, ',')
      END

      SELECT DISTINCT
        (IM.partnumber) 'PN',
        (IM.partdescription) 'PN Description',
        (select top 1 IMAIR.AircraftType from ItemMasterAircraftMapping IMAIR where IM.ItemMasterId = IMAIR.ItemMasterId) as  'Aircraft',
        (select top 1 IMAIR.aircraftmodel from ItemMasterAircraftMapping IMAIR where IM.ItemMasterId = IMAIR.ItemMasterId) as  'Model',
        (select top 1 IMAIR.Dashnumber from ItemMasterAircraftMapping IMAIR where IM.ItemMasterId = IMAIR.ItemMasterId) 'Dash',
        (select top 1 IMAM.ATAchaptercode from ItemMasterATAMapping IMAM where IM.ItemMasterId = IMAM.ItemMasterId) as 'ATA Cht Code',
        (select top 1 IMAM.ATAChapterName from ItemMasterATAMapping IMAM where IM.ItemMasterId = IMAM.ItemMasterId) as  'ATA Cht Description',
        (select top 1 ATASC.ATASubChaptercode from ItemMasterATAMapping IMAM  Inner JOIN DBO.ATASubChapter ATASC WITH (NOLOCK)
         ON IMAM.ATASubChapterId = ATASC.ATASubChapterId  where IM.ItemMasterId = IMAM.ItemMasterId) as   'ATA Sub-Chpt Code',
         (select top 1 ATASC.Description from ItemMasterATAMapping IMAM  Inner JOIN DBO.ATASubChapter ATASC WITH (NOLOCK)
         ON IMAM.ATASubChapterId = ATASC.ATASubChapterId  where IM.ItemMasterId = IMAM.ItemMasterId) 'ATAT Sub Description',
        IMC.CapabilityType 'Capability Type',
        case when Isnull(IMC.isverified,0) = 0 then 'No' else 'Yes'  end   'isverified',
        IMC.VerifiedBy 'Verified BY',
        CONVERT(varchar, IMC.VerifiedDate, 101) 'Date Verified',
        CONVERT(varchar, IMC.AddedDate, 101) 'Date Added',
		IMC.level1 AS LEVEL1,
		IMC.level2 AS LEVEL2,
		IMC.level3 AS LEVEL3,
		IMC.level4 AS LEVEL4
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level1.code + '-' + level1.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END AS LEVEL1,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END AS LEVEL2,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END AS LEVEL3,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END AS LEVEL4

      FROM DBO.ItemMasterCapes IMC WITH (NOLOCK)
      INNER JOIN DBO.Itemmaster IM WITH (NOLOCK)
        ON IMC.itemmasterid = IM.itemmasterid
        --Inner JOIN DBO.ItemMasterATAMapping IMAM WITH (NOLOCK)
        --  ON IM.ItemMasterId = IMAM.ItemMasterId
        --Inner JOIN DBO.ATASubChapter ATASC WITH (NOLOCK)
        --  ON IMAM.ATASubChapterId = ATASC.ATASubChapterId
        --Inner JOIN DBO.ItemMasterAircraftMapping IMAIR WITH (NOLOCK)
        --  ON IM.ItemMasterId = IMAIR.ItemMasterId
        LEFT  JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON IMC.MasterCompanyId = MC.MasterCompanyId
        Inner JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = IMC.ManagementStructureId
        --LEFT JOIN DBO.ManagementStructure AS level4 WITH (NOLOCK)
        --  ON IMC.ManagementStructureId = level4.ManagementStructureId
        --LEFT OUTER JOIN DBO.ManagementStructure AS level3 WITH (NOLOCK)
        --  ON level4.ParentId = level3.ManagementStructureId
        --LEFT OUTER JOIN DBO.ManagementStructure AS level2 WITH (NOLOCK)
        --  ON level3.ParentId = level2.ManagementStructureId
        --LEFT OUTER JOIN DBO.ManagementStructure AS level1 WITH (NOLOCK)
        --  ON level2.ParentId = level1.ManagementStructureId
      WHERE (IM.partnumber IN (@partnumber)
      OR @partnumber = ' ')
      AND IMC.mastercompanyid = @mastercompanyid
	  --and imc.CreatedDate=@asofdate
      --AND (@isverified <> 3 AND ((@isverified = 1 AND IMC.isverified = 1) OR (@isverified = 2 AND IMC.isverified = 0)))
      AND( IMC.isverified =
                            CASE
                              WHEN @isverified = 1 THEN 1
                              ELSE CASE
                                  WHEN @isverified = 2 THEN 0
                                END
                            END
      OR (@isverified = 3
      AND IMC.isverified IS NOT NULL AND IMC.mastercompanyid = @mastercompanyid))

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[usp_GetCapabilitiesReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@partnumber, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@isverified, '') AS varchar(100)),
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

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END