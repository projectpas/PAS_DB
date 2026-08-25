/************************************************************************************           
 ** File:   [USP_GetWOAssetInventoryList]           
 ** Author: 
 ** Description: This stored procedure is used to get GetWOAssetInventoryList.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    4-16-2025			Amit Ghediya			Created
	 2    08-18-2025		Abhishek Jirawla		Removed AssetAttributyType

	 EXEC [dbo].[USP_GetWOAssetInventoryList] 162
****************************************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetWOAssetInventoryList]
	@AssetRecordId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

				DECLARE @AssetAvailableStatusId INT;

				SET  @AssetAvailableStatusId = (SELECT [AssetAvailableStatusId] FROM [dbo].[AssetAvailableStatus] WITH(NOLOCK) WHERE [Status] = 'Available');

				SELECT
					AI.[AssetRecordId],
					AI.[AssetInventoryId],
					A.[Name] AS AssetName,
					AI.[AssetId],
					AI.[InventoryNumber],
					AI.[ControlNumber],
					AI.[StklineNumber],
					ISNULL(TC.[TangibleClassName], '') AS AssetType,
					ISNULL(MAN.[Name], '') AS Manufacturer,
					ISNULL(AI.[SerialNo], '') AS serialNo,
					ISNULL(ASL.[Name], '') AS AssetLocation,
					ISNULL(ASS.[Name], '') AS Site,
					ISNULL(ASW.[Name], '') AS Warehouse,
					ISNULL(ASF.[Name], '') AS Shelf,
					ISNULL(ASB.[Name], '') AS Bin,
					ISNULL(AI.[InventoryStatusId],0) AS InventoryStatusId,
					ISNULL(AIS.[Status], AAS.[Status]) AS InventoryStatus,
					ISNULL(CW.[CheckOutById], 0) AS CheckOutById,
					CW.[CheckOutDate],
					ISNULL(CW.[CheckOutEmpId], 0) AS CheckOutEmpId,
					ISNULL(CW.[CheckInById], 0) AS CheckInById,
					ISNULL(CW.[CheckInDate], GETUTCDATE()) AS CheckInDate,
					ISNULL(CW.[CheckInEmpId], 0) AS CheckInEmpId,
					ISNULL(CW.[Notes], '') AS Notes,
					ISNULL(CW.[CheckInCheckOutWorkOrderAssetId], 0) AS CheckInCheckOutWorkOrderAssetId,
					ISNULL(CW.[CheckInQty], 0) AS CheckInQty,
					ISNULL(CW.[CheckOutQty], 0) AS CheckOutQty,
					ISNULL(CW.[Quantity], 0) AS Quantity,
					ISNULL(CIE.[FirstName] + ' ' + CIE.[LastName], '') AS CheckInEmp,
					ISNULL(CIB.[FirstName] + ' ' + CIB.[LastName], '') AS CheckInBy,
					ISNULL(COE.[FirstName] + ' ' + COE.[LastName], '') AS CheckOutEmp,
					ISNULL(COB.[FirstName] + ' ' + COB.[LastName], '') AS CheckOutBy,
					ISNULL(ASST.[Name], '') AS AssetStatus
				FROM [dbo].[AssetInventory] AI WITH(NOLOCK)
				INNER JOIN [dbo].[Asset] A WITH(NOLOCK) ON AI.[AssetRecordId] = A.[AssetRecordId]
				INNER JOIN [dbo].[DeprNonDeprTangibleAssets] AT WITH(NOLOCK) ON A.[DeprNonDeprTangibleAssetsId] = AT.[DeprNonDeprTangibleAssetsId]
				INNER JOIN [dbo].[TangibleClass] TC WITH(NOLOCK) ON AT.[TangibleClassId] = TC.[TangibleClassId]
				LEFT JOIN [dbo].[CheckInCheckOutWorkOrderAsset] CW WITH(NOLOCK) ON AI.[AssetInventoryId] = CW.[AssetInventoryId]
				LEFT JOIN [dbo].[Manufacturer] MAN WITH(NOLOCK) ON A.[ManufacturerId] = MAN.[ManufacturerId]
				LEFT JOIN [dbo].[Site] ASS WITH(NOLOCK) ON AI.[SiteId] = ASS.[SiteId]
				LEFT JOIN [dbo].[Location] ASL WITH(NOLOCK) ON AI.[LocationId] = ASL.[LocationId]
				LEFT JOIN [dbo].[Warehouse] ASW WITH(NOLOCK) ON AI.[WarehouseId] = ASW.[WarehouseId]
				LEFT JOIN [dbo].[Shelf] ASF WITH(NOLOCK) ON AI.[ShelfId] = ASF.[ShelfId]
				LEFT JOIN [dbo].[Bin] ASB WITH(NOLOCK) ON AI.[BinId] = ASB.[BinId]
				LEFT JOIN [dbo].[AssetInventoryStatus] AIS WITH(NOLOCK) ON AI.[InventoryStatusId] = AIS.[AssetInventoryStatusId]
				LEFT JOIN [dbo].[AssetAvailableStatus] AAS WITH(NOLOCK) ON AI.[InventoryStatusId] = AAS.[AssetAvailableStatusId]
				LEFT JOIN [dbo].[Employee] CIE WITH(NOLOCK) ON CW.[CheckInEmpId] = CIE.[EmployeeId]
				LEFT JOIN [dbo].[Employee] CIB WITH(NOLOCK) ON CW.[CheckInById] = CIB.[EmployeeId]
				LEFT JOIN [dbo].[Employee] COE WITH(NOLOCK) ON CW.[CheckOutEmpId] = COE.[EmployeeId]
				LEFT JOIN [dbo].[Employee] COB WITH(NOLOCK) ON CW.[CheckOutById] = COB.[EmployeeId]
				LEFT JOIN [dbo].[AssetStatus] ASST WITH(NOLOCK) ON AI.[AssetStatusId] = ASST.[AssetStatusId]
				WHERE AI.AssetRecordId = @AssetRecordId
				  AND AI.IsDeleted = 0
				  AND AI.IsActive = 1
				  AND AI.InventoryStatusId = @AssetAvailableStatusId; 

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOAssetInventoryList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetRecordId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END