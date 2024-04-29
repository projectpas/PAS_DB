 /*************************************************************           
 ** File:   [USP_CheckLegalEntity_Exist]          
 ** Author:   Bhargav Saliya
 ** Description: This stored procedure is used to get Time Zone  
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:          

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1   28/07/2023 Bhargav Saliya   This stored procedure is used to get Time Zone
	2   22/04/2024 Abhishek Jirawla Adding asset module to the list
     
**************************************************************/

 --EXEC [USP_CheckLegalEntity_Exist] 15,3685
CREATE   PROCEDURE [dbo].[USP_CheckLegalEntity_Exist]
--@LegalEntiryId bigint,
@ModuleId bigint,
@ReferenceId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			  BEGIN 
			   IF @ModuleId = (SELECT ModuleId FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'Asset')
			  BEGIN

				  SELECT  ts.Description AS 'TimeZoneName', ai.ManagementStructureId, le.LegalEntityId,
				  ai.AssetInventoryId AS ReferenceId,le.TimeZoneId
				  FROM AssetInventory ai WITH(NOLOCK)
				  LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON ai.ManagementStructureId = ESS.EntityStructureId
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone ts WITH(NOLOCK) ON le.TimeZoneId = ts.TimeZoneId
				  WHERE ai.AssetInventoryId = @ReferenceId
			  END

			  IF @ModuleId = (SELECT ModuleId FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder')
			  BEGIN

				  SELECT  ts.Description AS 'TimeZoneName', wpn.ManagementStructureId, le.LegalEntityId,
				  wpn.WorkOrderId AS ReferenceId,le.TimeZoneId
				  FROM WorkOrderPartNumber wpn WITH(NOLOCK)
				  LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON wpn.ManagementStructureId = ESS.EntityStructureId
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone ts WITH(NOLOCK) ON le.TimeZoneId = ts.TimeZoneId
				  WHERE wpn.WorkOrderId = @ReferenceId
			  END

			  ELSE IF @ModuleId = (SELECT ModuleId  FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'WOQuote')
			  BEGIN

				  SELECT  TZ.Description AS 'TimeZoneName', LE.LegalEntityId,
				  WQ.WorkOrderQuoteId AS ReferenceId,le.TimeZoneId
				  FROM WorkOrderQuote WQ WITH(NOLOCK)
				  LEFT JOIN [dbo].Employee EL WITH(NOLOCK) ON WQ.EmployeeId = EL.EmployeeId
				  LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = EL.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
				  WHERE WQ.WorkOrderQuoteId = @ReferenceId
			  END

			   ELSE IF @ModuleId = (SELECT ModuleId  FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
			  BEGIN

				  SELECT  TZ.Description AS 'TimeZoneName', LE.LegalEntityId,
				  SO.SalesOrderId AS ReferenceId,le.TimeZoneId
				  FROM SalesOrder SO WITH(NOLOCK)
				  LEFT JOIN [dbo].Employee EL WITH(NOLOCK) ON SO.EmployeeId = EL.EmployeeId
				  LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = EL.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
				  WHERE SO.SalesOrderId = @ReferenceId
			  END

			  ELSE IF @ModuleId = (SELECT ModuleId  FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'SalesQuote')
			  BEGIN

				  SELECT  TZ.Description AS 'TimeZoneName', LE.LegalEntityId,
				  SOQ.SalesOrderQuoteId AS ReferenceId,le.TimeZoneId
				  FROM SalesOrderQuote SOQ WITH(NOLOCK)
				  LEFT JOIN [dbo].Employee EL WITH(NOLOCK) ON SOQ.EmployeeId = EL.EmployeeId
				  LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = EL.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
				  WHERE SOQ.SalesOrderQuoteId = @ReferenceId
			  END

			  IF @ModuleId = (SELECT ModuleId FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'RepairOrder')
			  BEGIN

				  SELECT  ts.Description AS 'TimeZoneName', ROP.ManagementStructureId, le.LegalEntityId,
				  ROP.RepairOrderId AS ReferenceId,le.TimeZoneId
				  FROM RepairOrderPart ROP WITH(NOLOCK)
				  LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON ROP.ManagementStructureId = ESS.EntityStructureId
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone ts WITH(NOLOCK) ON le.TimeZoneId = ts.TimeZoneId
				  WHERE ROP.RepairOrderId = @ReferenceId
			  END

			  IF @ModuleId = (SELECT ModuleId FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'ReceivingRepairOrder')
			  BEGIN

				  SELECT  ts.Description AS 'TimeZoneName', ROP.ManagementStructureId, le.LegalEntityId,
				  RO.RepairOrderId AS ReferenceId,le.TimeZoneId
				  FROM RepairOrder RO WITH(NOLOCK)
				  LEFT JOIN [dbo].RepairOrderPart ROP WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
				  LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON ROP.ManagementStructureId = ESS.EntityStructureId
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone ts WITH(NOLOCK) ON le.TimeZoneId = ts.TimeZoneId
				  WHERE RO.RepairOrderId = @ReferenceId
			  END

			  IF @ModuleId = (SELECT ModuleId FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'ReceivingPurchaseOrder')
			  BEGIN

				  SELECT  ts.Description AS 'TimeZoneName', POP.ManagementStructureId, le.LegalEntityId,
				  PO.PurchaseOrderId AS ReferenceId,le.TimeZoneId
				  FROM PurchaseOrder PO WITH(NOLOCK)
				  LEFT JOIN [dbo].PurchaseOrderPart POP WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
				  LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON POP.ManagementStructureId = ESS.EntityStructureId
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone ts WITH(NOLOCK) ON le.TimeZoneId = ts.TimeZoneId
				  WHERE PO.PurchaseOrderId = @ReferenceId
			  END

			  IF @ModuleId = (SELECT ModuleId FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrder')
			  BEGIN

				  SELECT  ts.Description AS 'TimeZoneName', WOP.ManagementStructureId, le.LegalEntityId,
				  SWP.SubWorkOrderId AS ReferenceId,le.TimeZoneId
				  FROM SubWorkOrderPartNumber SWP WITH(NOLOCK)
				  LEFT JOIN [dbo].WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.WorkOrderId = SWP.WorkOrderId
				  LEFT JOIN [dbo].EntityStructureSetup ESS WITH(NOLOCK) ON WOP.ManagementStructureId = ESS.EntityStructureId
				  LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				  LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
				  LEFT JOIN [dbo].TimeZone ts WITH(NOLOCK) ON le.TimeZoneId = ts.TimeZoneId
				  WHERE SWP.SubWorkOrderId = @ReferenceId
			  END

			  ELSE IF @ModuleId = (SELECT ModuleId  FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder')
			  BEGIN

				  SELECT  TZ.Description AS 'TimeZoneName', LE.LegalEntityId,
				  ESO.ExchangeSalesOrderId AS ReferenceId,le.TimeZoneId
				  FROM ExchangeSalesOrder ESO WITH(NOLOCK)
				  LEFT JOIN [dbo].Employee EL WITH(NOLOCK) ON ESO.EmployeeId = EL.EmployeeId
				  LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = EL.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
				  WHERE ESO.ExchangeSalesOrderId = @ReferenceId
			  END

			  ELSE IF @ModuleId = (SELECT ModuleId  FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'SpeedQuote')
			  BEGIN

				  SELECT  TZ.Description AS 'TimeZoneName', LE.LegalEntityId,
				  SQ.SpeedQuoteId AS ReferenceId,le.TimeZoneId
				  FROM SpeedQuote SQ WITH(NOLOCK)
				  LEFT JOIN [dbo].Employee EL WITH(NOLOCK) ON SQ.EmployeeId = EL.EmployeeId
				  LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = EL.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
				  WHERE SQ.SpeedQuoteId = @ReferenceId
			  END

			  ELSE IF @ModuleId = (SELECT ModuleId  FROM [DBO].Module WITH(NOLOCK) WHERE ModuleName = 'ExchangeQuote')
			  BEGIN

				  SELECT  TZ.Description AS 'TimeZoneName', LE.LegalEntityId,
				  EQ.ExchangeQuoteId AS ReferenceId,le.TimeZoneId
				  FROM ExchangeQuote EQ WITH(NOLOCK)
				  LEFT JOIN [dbo].Employee EL WITH(NOLOCK) ON EQ.EmployeeId = EL.EmployeeId
				  LEFT JOIN [dbo].LegalEntity LE WITH(NOLOCK) ON LE.LegalEntityId = EL.LegalEntityId
				  LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
				  WHERE EQ.ExchangeQuoteId = @ReferenceId
			  END
			  
			  END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckLegalEntity_Exist' 
              , @ProcedureParameters VARCHAR(3000)  = '@ModuleId = '''+ ISNULL(@ModuleId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END