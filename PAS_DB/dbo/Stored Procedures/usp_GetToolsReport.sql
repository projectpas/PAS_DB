
/*************************************************************           
 ** File:   [usp_GetToolsReport]           
 ** Author:   Swetha  
 ** Description: Get Data for Tools Report  
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
     
EXECUTE   [dbo].[usp_GetToolsReport] '2021-07-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetToolsReport] @To datetime,
@mastercompanyid int,
@calibrationrequired int,
@Level1 varchar(max) = NULL,
@Level2 varchar(max) = NULL,
@Level3 varchar(max) = NULL,
@Level4 varchar(max) = NULL
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
        Asset.assetid 'Asset ID',
        IM.PartDescription 'PN Description',
        AI.InventoryNumber 'Inventory Num',
        AI.serialno 'Serial Num',
        asty.AssetAttributeTypeName 'Asset Class',
        CONVERT(varchar, Asset.EntryDate, 101) 'Entry Date',
        AssetStatus.name 'Status',
        case when Isnull(AC.calibrationrequired,0) = 0 then 'No' else 'Yes'  end  'Calibration Required',
        '?' 'Last Calibrated Date',
        VNDR.vendorname 'Last Calibrated By',
        '?' 'Next Calibrated Date',
         case when Isnull(AC.certificationrequired,0) = 0 then 'No' else 'Yes'  end 'Certification Required',
        VNDR1.vendorname 'Last Certified By',
        '?' 'Next Certified Date',
        case when Isnull(AC.inspectionrequired,0) = 0 then 'No' else 'Yes'  end  'Inspection Required',
        case when Isnull(AC.verificationrequired,0) = 0 then 'No' else 'Yes' end  'Verification Required',
        '?' 'Non Calibrated',
        AL.Code + '-' + AL.name 'Location'        
      FROM dbo.asset WITH (NOLOCK)
      LEFT JOIN DBO.Assetinventory AI WITH (NOLOCK)
        ON Asset.assetrecordid = AI.AssetRecordId
        LEFT JOIN DBO.Assetstatus WITH (NOLOCK)
          ON AI.AssetStatusId = AssetStatus.assetstatusid
        LEFT JOIN DBO.AssetLocation AL WITH (NOLOCK)
          ON AI.AssetLocationId = AL.AssetLocationId
        LEFT JOIN DBO.AssetCalibration AC WITH (NOLOCK)
          ON Asset.AssetRecordId = AC.AssetRecordId 
        LEFT JOIN DBO.AssetType WITH (NOLOCK)
          ON Asset.TangibleClassId = AssetType.AssetTypeId
        LEFT JOIN DBO.Vendor VNDR WITH (NOLOCK)
          ON AC.CalibrationDefaultVendorId = VNDR.VendorId
        LEFT JOIN DBO.Vendor VNDR1 WITH (NOLOCK)
          ON AC.CertificationDefaultVendorId = VNDR1.VendorId
        LEFT JOIN DBO.assetcapes ACS WITH (NOLOCK)
          ON Asset.assetrecordid = ACS.assetrecordid
        LEFT JOIN DBO.itemmaster IM WITH (NOLOCK)
          ON ACS.itemmasterId = IM.ItemMasterId
		LEFT JOIN dbo.AssetAttributeType asty WITH(NOLOCK) on asset.TangibleClassId = asty.TangibleClassId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON Asset.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = Asset.ManagementStructureId       
      WHERE asset.mastercompanyid = @mastercompanyid      

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
            @AdhocComments varchar(150) = '[usp_GetToolsReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1= ''' + CAST(ISNULL(@to, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter10 = ''' + CAST(ISNULL(@calibrationrequired, '') AS varchar(100)),
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