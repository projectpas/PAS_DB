
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetPublicationPNMappingData   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetPublicationPNMappingData.sql)
-- ---------------------------------------------------------------------------------------------------
/***************************************************************  
 ** File:  [USP_GetPublicationPNMappingData]            
 ** Author: Ayushi Patel  
 ** Description: Get part number mapping data by comma-separated PublicationRecordIds
 ** Purpose:   
 ** Date:  02-JUN-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-06-02		  Ayushi Patel				Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	
 ***************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetPublicationPNMappingData]
    @PublicationRecordIds VARCHAR(MAX),
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            pim.ItemMasterId,
            pub.PublicationId,
            im.PartNumber,
            im.PartDescription,
            ISNULL(ic.ItemClassificationCode, '') AS ItemClassification,
            im.ManufacturerId,
            ISNULL(ma.Name, '') AS ManufacturerName,
            im.ItemClassificationId,
            im.ItemGroupId,
            ISNULL(ig.ItemGroupCode, '') AS ItemGroup,
            pim.PublicationItemMasterMappingId,
            pub.PublicationRecordId,
            pim.MasterCompanyId,
            ISNULL(pim.IsActive,0) AS IsActive,
            ISNULL(pim.IsDeleted,0) AS IsDeleted,
			pim.[Notes]
        FROM dbo.PublicationItemMasterMapping pim WITH (NOLOCK)
        INNER JOIN dbo.Publication pub WITH (NOLOCK) ON pim.PublicationRecordId = pub.PublicationRecordId
        INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON pim.ItemMasterId = im.ItemMasterId
        INNER JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
        LEFT JOIN dbo.Itemgroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
        LEFT JOIN dbo.Manufacturer ma WITH (NOLOCK) ON im.ManufacturerId = ma.ManufacturerId
        WHERE EXISTS (
            SELECT 1 
            FROM STRING_SPLIT(@PublicationRecordIds, ',') AS split
            WHERE TRY_CAST(split.[value] AS BIGINT) = pim.PublicationRecordId
        )
        AND ISNULL(pim.IsDeleted,0) = @IsDeleted
        AND ISNULL(pim.IsActive,0) = 1
        AND ISNULL(im.IsActive,0) = 1
     AND ISNULL(im.IsNonStock,0) = 0
         END TRY
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
                @AdhocComments VARCHAR(150) = 'USP_GetPublicationPNMappingData',
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