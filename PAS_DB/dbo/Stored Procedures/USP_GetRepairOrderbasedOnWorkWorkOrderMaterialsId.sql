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
			RO.VendorCode,
			RO.VendorName,
			RO.OpenDate,
			CASE WHEN CAST(SL.ReceivedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(SL.ReceivedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END [ReceivedDate],
			RP.PartNumber, 
			RP.PartDescription,
			RP.SerialNumber,
			RP.WorkPerformed,
			RP.StockLineNumber,
			RP.ControlNumber,
			0 as UnitCost,
			--SL.UnitCost,
			RP.UnitCost AS ROCost,
			RP.QuantityOrdered,
			RP.ExtendedCost ExtendedRepairCost,
			(ISNULL(SL.UnitCost, 0) + ISNULL(RP.UnitCost, 0)) * RP.QuantityOrdered AS TotalCost		
		FROM [dbo].[RepairOrderPart] RP WITH(NOLOCK) 
			JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = RP.RepairOrderId
			JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = RP.StockLineId
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