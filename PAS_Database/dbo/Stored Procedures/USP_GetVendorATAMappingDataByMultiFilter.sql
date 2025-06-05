/***********************************************************
** File:   [USP_GetVendorATAMappingDataByMultiFilter]
** Author: Ayushi Patel
** Description: Get Vendor ATA Mapping Data by multiple filters  
** Purpose:  Replacement of EF method searchgetVendorATAMappingDataByMultiTypeIdATAIDATASUBID  
** Date:   2025-05-22
        
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 22-MAY-2025   AYUSHI PATEL 		Created
***************************************************************/
CREATE PROCEDURE USP_GetVendorATAMappingDataByMultiFilter 
    @VendorId BIGINT,
    @ATAChapterIdList VARCHAR(MAX) = NULL,
    @ATASubChapterIdList VARCHAR(MAX) = NULL,
    @ContactIdList VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		IF OBJECT_ID(N'tempdb..#ATAChapterTemp') IS NOT NULL
		BEGIN
			DROP TABLE #ATAChapterTemp
		END
		IF OBJECT_ID(N'tempdb..#ATASubChapterTemp') IS NOT NULL
		BEGIN
			DROP TABLE #ATASubChapterTemp
		END
		IF OBJECT_ID(N'tempdb..#ContactTemp') IS NOT NULL
		BEGIN
			DROP TABLE #ContactTemp
		END

        CREATE TABLE #ATAChapterTemp (Id BIGINT);
        CREATE TABLE #ATASubChapterTemp (Id BIGINT);
        CREATE TABLE #ContactTemp (Id BIGINT);

        IF ISNULL(@ATAChapterIdList, '') <> ''
        BEGIN
            INSERT INTO #ATAChapterTemp (Id)
            SELECT CAST(Value AS BIGINT)
            FROM STRING_SPLIT(@ATAChapterIdList, ',')
            WHERE RTRIM(LTRIM(Value)) <> '';
        END

        IF ISNULL(@ATASubChapterIdList, '') <> ''
        BEGIN
            INSERT INTO #ATASubChapterTemp (Id)
            SELECT CAST(Value AS BIGINT)
            FROM STRING_SPLIT(@ATASubChapterIdList, ',')
            WHERE RTRIM(LTRIM(Value)) <> '';
        END

        IF ISNULL(@ContactIdList, '') <> ''
        BEGIN
            INSERT INTO #ContactTemp (Id)
            SELECT CAST(Value AS BIGINT)
            FROM STRING_SPLIT(@ContactIdList, ',')
            WHERE RTRIM(LTRIM(Value)) <> '';
        END

        SELECT
            ca.VendorContactATAMappingId,
            ca.VendorId,
            ca.ATAChapterId,
            ata.ATAChapterCode,
            ATAChapterName = ISNULL(ata.ATAChapterCode, '') + ' - ' + ISNULL(ata.ATAChapterName, ''),
            ca.ATASubChapterId,
            ATASubChapterDescription = ISNULL(atasub.ATASubChapterCode, '') + ' - ' + ISNULL(atasub.Description, ''),
            FirstName = ISNULL(ct.FirstName + ' ' + ct.LastName, ''),
            ct.ContactId,
            ca.CreatedBy,
            ca.CreatedDate,
            ca.UpdatedBy,
            ca.UpdatedDate
        FROM VendorContactATAMapping ca WITH (NOLOCK)
        INNER JOIN VendorContact vc WITH (NOLOCK) ON ca.VendorContactId = vc.VendorContactId
        LEFT JOIN Contact ct WITH (NOLOCK) ON vc.ContactId = ct.ContactId
        LEFT JOIN ATAChapter ata WITH (NOLOCK) ON ca.ATAChapterId = ata.ATAChapterId
        LEFT JOIN ATASubChapter atasub WITH (NOLOCK) ON ca.ATASubChapterId = atasub.ATASubChapterId
        WHERE 
            ca.VendorId = @VendorId
            AND ISNULL(ca.IsDeleted,0) = 0
            AND (
                NOT EXISTS (SELECT 1 FROM #ATAChapterTemp) OR ca.ATAChapterId IN (SELECT Id FROM #ATAChapterTemp)
            )
            AND (
                NOT EXISTS (SELECT 1 FROM #ATASubChapterTemp) OR ca.ATASubChapterId IN (SELECT Id FROM #ATASubChapterTemp)
            )
            AND (
                NOT EXISTS (SELECT 1 FROM #ContactTemp) OR vc.ContactId IN (SELECT Id FROM #ContactTemp)
            );


    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetVendorATAMappingDataByMultiFilter'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END