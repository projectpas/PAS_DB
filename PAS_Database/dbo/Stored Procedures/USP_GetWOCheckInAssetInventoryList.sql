/************************************************************************************           
 ** File:   [USP_GetWOCheckInAssetInventoryList]           
 ** Author: 
 ** Description: This stored procedure is used to get GetWOCheckInAssetInventoryList.
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

	 EXEC [dbo].[USP_GetWOCheckInAssetInventoryList] 167,225
****************************************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetWOCheckInAssetInventoryList]
	@WorkOrderAssetId BIGINT,
	@EmployeeId BIGINT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

				DECLARE @UnavailableInUseStatusId INT,
						@CurrntEmpTimeZoneDesc VARCHAR(100) = '';

				SET  @UnavailableInUseStatusId = (SELECT [AssetAvailableStatusId] FROM [dbo].[AssetAvailableStatus] WITH(NOLOCK) WHERE [Status] = 'Unavailable - In Use');

				--Get Employee wise timezone
				SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE E.EmployeeId = @EmployeeId; 

				SELECT 
					AI.assetRecordId,
					AI.assetInventoryId,
					A.Name AS assetName,
					AI.assetId,
					AI.inventoryNumber,
					AI.stklineNumber,
					AI.controlNumber,
					ISNULL(TC.TangibleClassName, '') AS assetType,
					ISNULL(MAN.Name, '') AS manufacturer,
					ISNULL(AI.SerialNo, '') AS serialNo,
					ISNULL(ASL.Name, '') AS assetLocation,
					ISNULL(ASS.Name, '') AS site,
					ISNULL(ASW.Name, '') AS warehouse,
					ISNULL(ASF.Name, '') AS shelf,
					ISNULL(ASB.Name, '') AS bin,
					AI.inventoryStatusId,
					ISNULL(AIS.Status, AAS.Status) AS inventoryStatus,
					ISNULL(CW.CheckOutById, 0) AS checkOutById,
					ISNULL(CW.CheckOutDate, GETUTCDATE()) AS checkOutDate,
					ISNULL(CW.CheckOutEmpId, 0) AS checkOutEmpId,
					ISNULL(CW.CheckInById, 0) AS checkInById,
					CASE WHEN CAST(CW.CheckInDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(CW.CheckInDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END checkInDate,
					ISNULL(CW.CheckInEmpId, 0) AS checkInEmpId,
					ISNULL(CW.Notes, '') AS notes,
					ISNULL(CW.MasterCompanyId, 0) AS masterCompanyId,
					ISNULL(CW.CreatedDate, GETUTCDATE()) AS createdDate,
					ISNULL(CW.CreatedBy, '') AS createdBy,
					ISNULL(CW.IsActive, 1) AS isActive,
					ISNULL(CW.IsDeleted, 0) AS isDeleted,
					ISNULL(CW.CheckInCheckOutWorkOrderAssetId, 0) AS checkInCheckOutWorkOrderAssetId,
					ISNULL(CW.CheckInQty, 0) AS checkInQty,
					ISNULL(CW.CheckOutQty, 0) AS checkOutQty,
					ISNULL(CW.Quantity, 0) AS quantity,
					ISNULL(CIE.FirstName + ' ' + CIE.LastName, '') AS checkInEmp,
					ISNULL(CIB.FirstName + ' ' + CIB.LastName, '') AS checkInBy,
					ISNULL(COE.FirstName + ' ' + COE.LastName, '') AS checkOutEmp,
					ISNULL(COB.FirstName + ' ' + COB.LastName, '') AS checkOutBy,
					ISNULL(CW.WorkOrderId, 0) AS workOrderId,
					ISNULL(CW.WorkOrderAssetId, 0) AS workOrderAssetId,
					ISNULL(CW.WorkOrderPartNoId, 0) AS workOrderPartNoId,
					ISNULL(ASST.Name, '') AS assetStatus
				FROM [dbo].[AssetInventory] AI WITH(NOLOCK)
				INNER JOIN [dbo].[Asset] A WITH(NOLOCK) ON AI.AssetRecordId = A.AssetRecordId
				INNER JOIN [dbo].[AssetAttributeType] AT WITH(NOLOCK) ON A.AssetAttributeTypeId = AT.AssetAttributeTypeId
				INNER JOIN [dbo].[TangibleClass] TC WITH(NOLOCK) ON AT.TangibleClassId = TC.TangibleClassId
				INNER JOIN [dbo].[CheckInCheckOutWorkOrderAsset] CW WITH(NOLOCK) ON AI.AssetInventoryId = CW.AssetInventoryId
				LEFT JOIN [dbo].[Manufacturer] MAN WITH(NOLOCK) ON A.ManufacturerId = MAN.ManufacturerId
				LEFT JOIN [dbo].[Site] ASS WITH(NOLOCK) ON AI.SiteId = ASS.SiteId
				LEFT JOIN [dbo].[Location] ASL WITH(NOLOCK) ON AI.LocationId = ASL.LocationId
				LEFT JOIN [dbo].[Warehouse] ASW WITH(NOLOCK) ON AI.WarehouseId = ASW.WarehouseId
				LEFT JOIN [dbo].[Shelf] ASF WITH(NOLOCK) ON AI.ShelfId = ASF.ShelfId
				LEFT JOIN [dbo].[Bin] ASB WITH(NOLOCK) ON AI.BinId = ASB.BinId
				LEFT JOIN [dbo].[AssetInventoryStatus] AIS WITH(NOLOCK) ON AI.InventoryStatusId = AIS.AssetInventoryStatusId
				LEFT JOIN [dbo].[AssetAvailableStatus] AAS WITH(NOLOCK) ON AI.InventoryStatusId = AAS.AssetAvailableStatusId
				LEFT JOIN [dbo].[Employee] CIE WITH(NOLOCK) ON CW.CheckInEmpId = CIE.EmployeeId
				LEFT JOIN [dbo].[Employee] CIB WITH(NOLOCK) ON CW.CheckInById = CIB.EmployeeId
				LEFT JOIN [dbo].[Employee] COE WITH(NOLOCK) ON CW.CheckOutEmpId = COE.EmployeeId
				LEFT JOIN [dbo].[Employee] COB WITH(NOLOCK) ON CW.CheckOutById = COB.EmployeeId
				LEFT JOIN [dbo].[AssetStatus] ASST WITH(NOLOCK)ON AI.AssetStatusId = ASST.AssetStatusId
				WHERE CW.WorkOrderAssetId = @WorkOrderAssetId
				  AND CW.InventoryStatusId = @UnavailableInUseStatusId
				  AND AI.IsActive = 1; 

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOCheckInAssetInventoryList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderAssetId, '')
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