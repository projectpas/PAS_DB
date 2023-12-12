---------------------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [GetVendorRFQRepairOrderParts]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to GET vendor RFQ RO Parts List
 ** Purpose:         
 ** Date:   04/01/2022 
 ** PARAMETERS: @VendorRFQRepairOrderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/01/2022   Moin Bloch     Created
	2    06/12/2023   Amit Ghediya   Modify(Added Traceable & Tagged fields)

-- EXEC [GetVendorRFQRepairOrderParts] 1
************************************************************************/
CREATE PROCEDURE [dbo].[GetVendorRFQRepairOrderParts]
@VendorRFQRepairOrderId bigint
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		BEGIN
		SELECT PP.[VendorRFQROPartRecordId]
              ,PP.[VendorRFQRepairOrderId]
              ,PP.[ItemMasterId]
              ,PP.[PartNumber]
              ,PP.[PartDescription]
              ,PP.[AltEquiPartNumberId]
              ,PP.[AltEquiPartNumber]
              ,PP.[AltEquiPartDescription]
              ,PP.[RevisedPartId]
              ,PP.[RevisedPartNumber]
              ,PP.[StockType]
              ,PP.[ManufacturerId]
              ,PP.[Manufacturer]
              ,PP.[PriorityId]
              ,PP.[Priority]
              ,PP.[NeedByDate]
              ,PP.[PromisedDate]
              ,PP.[ConditionId]
              ,PP.[Condition]
              ,PP.[WorkPerformedId]
              ,PP.[WorkPerformed]
              ,PP.[QuantityOrdered]
              ,PP.[UnitCost]
              ,PP.[ExtendedCost]
              ,PP.[WorkOrderId]
              ,PP.[WorkOrderNo]
              ,PP.[SubWorkOrderId]
              ,PP.[SubWorkOrderNo]
              ,PP.[SalesOrderId]
              ,PP.[SalesOrderNo]
              ,PP.[ItemTypeId]
              ,PP.[ItemType]
              ,PP.[UOMId]
              ,PP.[UnitOfMeasure]
              ,PP.[ManagementStructureId]
              ,PP.[Level1]
              ,PP.[Level2]
              ,PP.[Level3]
              ,PP.[Level4]
              ,PP.[Memo]
              ,PP.[MasterCompanyId]
              ,PP.[CreatedBy]
              ,PP.[UpdatedBy]
              ,PP.[CreatedDate]
              ,PP.[UpdatedDate]
              ,PP.[IsActive]
              ,PP.[IsDeleted]
			  ,RO.[RepairOrderId]
			  ,RO.[RepairOrderNumber]
			  ,RO.[CreatedDate] AS ROCreatedDate
			  ,RO.[Status] AS ROStatus
			  ,POMSD.[EntityMSID] AS EntityStructureId
			  ,POMSD.[LastMSLevel] AS LastMSLevel
			  ,POMSD.[AllMSlevels] AS AllMSlevels
			  ,PP.[TraceableTo]
			  ,PP.[TraceableToName]
			  ,PP.[TraceableToType]
			  ,PP.[TagTypeId]
			  ,PP.[TaggedBy]
			  ,PP.[TaggedByType]
			  ,PP.[TaggedByName]
			  ,PP.[TaggedByTypeName]
			  ,PP.[TagDate]
		 FROM [dbo].[VendorRFQRepairOrderPart] PP WITH (NOLOCK)
		 LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON PP.RepairOrderId = RO.RepairOrderId					
		 JOIN [dbo].[RepairOrderManagementStructureDetails] POMSD ON PP.VendorRFQROPartRecordId = POMSD.ReferenceID AND POMSD.ModuleID = 23
		WHERE PP.[VendorRFQRepairOrderId] = @VendorRFQRepairOrderId AND PP.IsDeleted = 0;

	END
	END TRY    
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQRepairOrderParts' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQRepairOrderId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END