/*************************************************************           
 ** File:		[dbo].[USP_GetATAMappedByItemMasterId]      
 ** Author:		 Nakul Chandigra
 ** Description: This stored procedure retrieves part details for the Add Multiple Part search in a PO, filtered by MasterCompanyId.
 ** Purpose:         
 ** Date:   16-12-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	-------------------         
	1	 16-12-2025         Nakul Chandigra     Created 
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetATAMappedByItemMasterId]
@ItemMasterId BIGINT,
@IsDeleted BIT,
@EmployeeId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

	SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc;

	SELECT 
		iM.ItemMasterATAMappingId,
		iM.ItemMasterId,
        iM.ATAChapterId,
        iM.PartNumber,
        item.PartDescription,
        ATASubChapterId = ISNULL(iM.ATASubChapterId, 0),
		'' AS ATASubChapterDescription,
        '' AS ATASubChapterCode, 
        iM.CreatedBy,
        iM.UpdatedBy,
		CASE WHEN CAST(iM.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, iM.CreatedDate)) END CreatedDate,
		CASE WHEN CAST(iM.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, iM.UpdatedDate)) END UpdatedDate,
        iM.IsDeleted,
        iM.IsActive,
        iM.Level1,
        iM.Level2,
        iM.Level3,
		ATAChapterName = CASE WHEN iM.Level1 IS NOT NULL AND LTRIM(RTRIM(iM.Level1)) <> '' THEN '-' + iM.Level1 ELSE '' END + 
		                 CASE WHEN iM.Level2 IS NOT NULL AND LTRIM(RTRIM(iM.Level2)) <> '' THEN '-' + iM.Level2 ELSE '' END + 
						 CASE WHEN iM.Level3 IS NOT NULL AND LTRIM(RTRIM(iM.Level3)) <> '' THEN '-' + iM.Level3 ELSE '' END 						
	FROM [DBO].ItemMasterATAMapping iM WITH (NOLOCK)
	JOIN [DBO].ItemMaster item WITH (NOLOCK) ON iM.ItemMasterId = item.ItemMasterId
	WHERE  iM.ItemMasterId = @ItemMasterId AND iM.IsActive = 1 AND iM.IsDeleted = @IsDeleted

	 AND ISNULL(item.IsNonStock,0) = 0 END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetATAMappedByItemMasterId]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1); 
	END CATCH
END