/*************************************************************           
 ** File:   [USP_GetRepairOrderbasedOnWorkWorkOrderMaterialsId]           
 ** Author: HEMANT SALIYA
 ** Description: This stored procedure is used to Get repair Order Cost Details for WO Materials.
 ** Purpose:         
 ** Date:   03/23/2026

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    03/23/2026   HEMANT SALIYA		CREATED	
 
EXEC [dbo].[USP_GetRepairOrderbasedOnWorkWorkOrderMaterialsId] 61501 ,10242  
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetRepairOrderbasedOnWorkWorkOrderMaterialsId]
(
	@WorkOrderMaterialsId BIGINT,
	@WorkOrderId BIGINT,
	@EmployeeId BIGINT
)
AS
BEGIN 
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

	BEGIN TRY
		SELECT 
			RO.RepairOrderNumber, 
			RO.OpenDate,
			CASE WHEN CAST(WMR.RORecDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WMR.RORecDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END [ReceivedDate],
			WMR.PartNumber, 
			WMR.PNDescription PartDescription,
			WMR.SerialNum SerialNumber,
			RP.WorkPerformed,
			RP.StockLineNumber,
			RO.VendorName,
			WMR.Quantity,
			WMR.POCost,
			WMR.RepairCost,
			WMR.UnitCost,
			WMR.ExtendedCost
		FROM [dbo].[WorkOrederMaterialsROHistory] WMR WITH(NOLOCK) 
			JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = WMR.RepairOrderId
			JOIN [dbo].[RepairOrderPart] RP WITH(NOLOCK) ON RP.RepairOrderPartRecordId = WMR.RepairOrderPartId
		WHERE RP.WorkOrderMaterialsId = @WorkOrderMaterialsId AND RP.WorkOrderId = @WorkOrderId 
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetRepairOrderbasedOnWorkWorkOrderMaterialsId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END