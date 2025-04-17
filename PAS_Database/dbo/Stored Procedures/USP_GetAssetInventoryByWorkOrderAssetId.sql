/***************************************************************************************          
 ** File:   [USP_GetAssetInventoryByWorkOrderAssetId]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get AssetInventoryByWorkOrderAssetId
 ** Purpose:           
 ** Date:  04-16-2025
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-16-2025    Bhargav Saliya		Created  
	exec [USP_GetAssetInventoryByWorkOrderAssetId]  @WorkOrderAssetId  =164
********************************************************************************/ 
CREATE   PROCEDURE [DBO].[USP_GetAssetInventoryByWorkOrderAssetId]
    @WorkOrderAssetId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

		SELECT 
			AI.AssetRecordId,
			AI.AssetInventoryId,
			A.Name AS AssetName,
			AI.AssetId,
			AI.InventoryNumber,
			ISNULL(AT.AssetAttributeTypeName, '') AS AssetType,
			ISNULL(MAN.Name, '') AS Manufacturer,
			ISNULL(AI.SerialNo, '') AS SerialNo,
			ISNULL(ASL.Name, '') AS AssetLocation,
			AI.InventoryStatusId,
			AIS.Status AS InventoryStatus,
			ISNULL(CW.CheckOutById, 0) AS CheckOutById,
			CASE 
				WHEN CW.CheckOutDate IS NULL 
					THEN CAST(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) AS DATETIME)
				ELSE 
					 CAST(DBO.ConvertUTCtoLocal(CW.CheckOutDate, @CurrntEmpTimeZoneDesc) AS DATETIME)
			END AS CheckOutDate,
			ISNULL(CW.CheckOutEmpId, 0) AS CheckOutEmpId,
			ISNULL(CW.CheckInById, 0) AS CheckInById,
			CASE 
				WHEN CW.CheckInDate IS NULL 
					THEN CAST(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) AS DATETIME)
				ELSE 
					 CAST(DBO.ConvertUTCtoLocal(CW.CheckInDate, @CurrntEmpTimeZoneDesc) AS DATETIME)
			END AS CheckInDate,
			ISNULL(CW.CheckInEmpId, 0) AS CheckInEmpId,
			ISNULL(CW.Notes, '') AS Notes,
			ISNULL(CW.CheckInCheckOutWorkOrderAssetId, 0) AS CheckInCheckOutWorkOrderAssetId,
			ISNULL(CW.CheckInQty, 0) AS CheckInQty,
			ISNULL(CW.CheckOutQty, 0) AS CheckOutQty,
			ISNULL(CW.Quantity, 0) AS Quantity,
			ISNULL(cie.FirstName + ' ' + cie.LastName, '') AS CheckInEmp,
			ISNULL(cib.FirstName + ' ' + cib.LastName, '') AS CheckInBy,
			ISNULL(coe.FirstName + ' ' + coe.LastName, '') AS CheckOutEmp,
			ISNULL(cob.FirstName + ' ' + cob.LastName, '') AS CheckOutBy,
			CW.UpdatedDate,
			CW.CreatedDate
		FROM [DBO].AssetInventory AI WITH(NOLOCK)
		INNER JOIN [DBO].Asset A WITH(NOLOCK) ON AI.AssetRecordId = A.AssetRecordId
		INNER JOIN [DBO].AssetAttributeType AT WITH(NOLOCK) ON A.AssetAcquisitionTypeId = AT.AssetAttributeTypeId
		INNER JOIN [DBO].CheckInCheckOutWorkOrderAssetAudit cw WITH(NOLOCK) ON AI.AssetInventoryId = cw.AssetInventoryId
		LEFT JOIN [DBO].Manufacturer MAN WITH(NOLOCK) ON A.ManufacturerId = MAN.ManufacturerId
		LEFT JOIN [DBO].AssetLocation ASL WITH(NOLOCK) ON AI.AssetLocationId = ASL.AssetLocationId
		LEFT JOIN [DBO].AssetInventoryStatus AIS WITH(NOLOCK) ON AI.InventoryStatusId = AIS.AssetInventoryStatusId
		LEFT JOIN [DBO].Employee cie WITH(NOLOCK) ON CW.CheckInEmpId = cie.EmployeeId
		LEFT JOIN [DBO].Employee cib WITH(NOLOCK) ON CW.CheckInById = cib.EmployeeId
		LEFT JOIN [DBO].Employee coe WITH(NOLOCK) ON CW.CheckOutEmpId = coe.EmployeeId
		LEFT JOIN [DBO].Employee cob WITH(NOLOCK) ON CW.CheckOutById = cob.EmployeeId
		WHERE 
			CW.WorkOrderAssetId = @WorkOrderAssetId
			AND CW.IsQtyCheckOut = 1
			AND ai.IsActive = 1
		ORDER BY CW.UpdatedDate DESC;
	END TRY 
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetAssetInventoryByWorkOrderAssetId',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderAssetId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH 
END