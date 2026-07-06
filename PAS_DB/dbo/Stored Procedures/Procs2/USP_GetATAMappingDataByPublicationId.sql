/***************************************************************  
 ** File: [USP_GetATAMappingDataByPublicationId]            
 ** Author: Ayushi Patel  
 ** Description: Get ATA Mapping Data by Publication ID
 ** Purpose:   
 ** Date:  02-JUN-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-06-02		  Ayushi Patel				Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	
 ***************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetATAMappingDataByPublicationId]
    @PublicationId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT DISTINCT
            it.ATASubChapterDescription,
            it.ATAChapterCode,
            '' AS ATASubChapterCode,
            im.PartNumber,
            im.PartDescription,
            ISNULL(ig.ItemGroupCode, '') AS ItemGroup,
            ISNULL(ma.Name, '') AS ManufacturerName,
            ATAChapterName = ISNULL(it.Level1, '')
                            + CASE WHEN ISNULL(it.Level2, '') <> '' THEN '-' + it.Level2 ELSE '' END
                            + CASE WHEN ISNULL(it.Level3, '') <> '' THEN '-' + it.Level3 ELSE '' END
        FROM DBO.PublicationItemMasterMapping pim WITH (NOLOCK)
        INNER JOIN DBO.ItemMasterATAMapping it WITH (NOLOCK) ON pim.ItemMasterId = it.ItemMasterId
        INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON it.ItemMasterId = im.ItemMasterId
        LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
        LEFT JOIN DBO.Manufacturer ma WITH (NOLOCK) ON im.ManufacturerId = ma.ManufacturerId
        INNER JOIN DBO.Publication pub WITH (NOLOCK) ON pim.PublicationRecordId = pub.PublicationRecordId
        WHERE ISNULL(pim.IsDeleted,0) = 0
          AND ISNULL(pim.IsActive,0) = 1
          AND pim.PublicationRecordId = @PublicationId
          AND ISNULL(it.IsDeleted,0) = 0
          AND ISNULL(it.IsActive,0) = 1
          AND ISNULL(im.IsActive,0) = 1
          AND ISNULL(im.IsDeleted,0) = 0
     AND ISNULL(im.IsNonStock,0) = 0 END TRY
    BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetATAMappingDataByPublicationId',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH 
END