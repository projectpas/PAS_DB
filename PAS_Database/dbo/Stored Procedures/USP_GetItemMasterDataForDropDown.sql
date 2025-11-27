/*************************************************************           
 ** File:		[dbo].[USP_GetItemMasterDataForDropDown]       
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used for get Data of ItemMasterDataForDropDown
 ** Purpose:          
 ** Date:   26-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 26-09-2025			Nakul Chandigra		Created
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetItemMasterDataForDropDown]
@MasterCompanyId BIGINT,
@type VARCHAR (256)
AS
BEGIN
	SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

    IF LOWER(LTRIM(RTRIM(@Type))) = LOWER('Stock')
    BEGIN
        SELECT DISTINCT
            im.ItemMasterId,
            im.PartNumber,
            im.PartDescription,
            CASE 
                WHEN (SELECT COUNT(*) 
                      FROM ItemMaster im2 
                      WHERE im2.PartNumber = im.PartNumber 
                        AND im2.MasterCompanyId = @MasterCompanyId) > 1
                THEN im.PartNumber + ' - ' + im.ManufacturerName
                ELSE im.PartNumber
            END AS label,
            im.ManufacturerName
        FROM ItemMaster im
        WHERE im.MasterCompanyId = @MasterCompanyId
          AND im.IsActive = 1
          AND im.IsDeleted = 0
          AND im.ItemTypeId = 1 
    END
    ELSE
    BEGIN
        SELECT DISTINCT
            im.MasterPartId AS ItemMasterId,
            im.PartNumber,
            im.PartDescription,
            CASE
                WHEN (SELECT COUNT(*) 
                      FROM ItemMasterNonStock im2
                      WHERE im2.PartNumber = im.PartNumber 
                        AND im2.MasterCompanyId = @MasterCompanyId) > 1
                THEN im.PartNumber + ' - ' + 
                     (SELECT TOP 1 Name 
                      FROM Manufacturer m 
                      WHERE m.ManufacturerId = im.ManufacturerId)
                ELSE im.PartNumber
            END AS label,
            (SELECT TOP 1 Name 
             FROM Manufacturer m 
             WHERE m.ManufacturerId = im.ManufacturerId) AS ManufacturerName
        FROM ItemMasterNonStock im
        WHERE im.MasterCompanyId = @MasterCompanyId
          AND im.IsActive = 1
          AND im.IsDeleted = 0
          AND im.ItemTypeId = 2 
    END	 
	END TRY 
	BEGIN CATCH
		IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetItemMasterDataForDropDown] '
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