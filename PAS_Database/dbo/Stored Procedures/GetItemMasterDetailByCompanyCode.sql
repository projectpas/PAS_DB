/*************************************************************             
 ** File:   [GetItemMasterDetailByCompanyCode]            
 ** Author:  RAJESH GAMI
 ** Description: This stored procedure is used to get item master details by company code
 ** Purpose:           
 ** Date:  09 Mar 2026        
            
 ** PARAMETERS: @companyCode VARCHAR(30)  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    09 Mar 2026		RAJESH GAMI	 Created  
**************************************************************
 EXEC GetItemMasterDetailByCompanyCode 'SA'
**************************************************************/
CREATE       PROCEDURE [dbo].[GetItemMasterDetailByCompanyCode] 
 @companyCode VARCHAR(30),
 @ItemMasterId bigint =NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
					DECLARE @MasterCompanyId BIGINT = (SELECT TOP 1  MasterCompanyId FROM Dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyCode = @companyCode)
					SELECT
						iM.ItemMasterId,
						iM.PartNumber AS [Part],
						iM.PartDescription AS [Part Description],
						(ISNULL(im.ManufacturerName,'')) 'Manufacturer',
						(CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
										 WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' 
					                     WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER'
										 WHEN im.IsOEM = 1 THEN 'OEM' 
										 ELSE ''
									END) as  [Stock Type],

						CASE WHEN im.IsSerialized = 1 THEN 'Yes' ELSE 'No' END AS Serialized,
						CASE WHEN im.IsTimeLife = 1 THEN 'Yes' ELSE 'No' END AS IsTimeLife,
						CASE WHEN im.ItemTypeId = 1 THEN 'Stock' ELSE 'NonStock' END [Item Type],	
						im.ItemClassificationName 'Item Classification',
						(ISNULL(im.ItemGroup,'')) 'Item Group',
						Im.PurchaseUnitOfMeasure as [Purchase UOM], 
						COALESCE(iM.PurchaseCurrency, '') AS [Purchase Currency],
						COALESCE(iM.SiteName, '') AS [Site],
						COALESCE(iM.WarehouseName, '') AS [Warehouse],
						COALESCE(iM.LocationName, '') AS [Location],
						COALESCE(iM.ShelfName, '') AS [Shelf],
						COALESCE(iM.BinName, '') AS [Bin],
						COALESCE(iM.Priority, '') AS [Priority],
						iM.Memo,
						COALESCE(iM.AssetAcquistionType, '') AS [AssetAcquistion Type]
			
					FROM dbo.ItemMaster iM WITH(NOLOCK)
					WHERE IM.MasterCompanyId = @MasterCompanyId AND
					(@ItemMasterId IS NULL OR iM.ItemMasterId = @ItemMasterId)
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[GetItemMasterDetailByCompanyCode]',
            @ProcedureParameters varchar(3000) = '@companyCode = ''' + CAST(ISNULL(@companyCode, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END