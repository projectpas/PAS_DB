/*************************************************************               
 ** File:  [USP_InsertWorkOrederMaterialsROHistory]     
 ** Author:  HEMANT SALIYA
 ** Description: This stored procedure is used to save [WorkOrederMaterialsROHistory].    
 ** Purpose:             
 ** Date:   24-Mar-2026        
             
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    24-Mar-2026  HEMANT SALIYA		Created    
    2    24-Mar-2026  Bhargav Saliya	Modified    
    3    09/July/2026  RAJESH GAMI	[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
   
************************************************************************/   
CREATE   PROCEDURE [dbo].[USP_SaveWorkOrederMaterialsROHistory]
(
    @WorkOrderId            BIGINT,
    @WorkOrderMaterialsId   BIGINT,
    @RepairOrderId          BIGINT,
    @RepairOrderPartId      BIGINT,
    @StocklineId            BIGINT,
    @MasterCompanyId        INT,    
    @UpdatedBy              VARCHAR(256)   
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO [dbo].[WorkOrederMaterialsROHistory]
        (
            WorkOrderId, WorkOrderMaterialsId, RepairOrderId, RepairOrderPartId,
            StocklineId, VendorId, PartNumber, PNDescription, SerialNum,
            Quantity, POCost, RepairCost, UnitCost, ExtendedCost,
            RODate, RORecDate, MasterCompanyId,
            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
        )
        SELECT
            @WorkOrderId, @WorkOrderMaterialsId, @RepairOrderId, @RepairOrderPartId,
            @StocklineId,RO.VendorId, SL.PartNumber, SL.PNDescription,SL.SerialNumber,
            RP.QuantityOrdered, SL.PurchaseOrderUnitCost, RP.UnitCost, SL.UnitCost,
			(ISNULL(SL.UnitCost, 0) + ISNULL(RP.UnitCost, 0)) * RP.QuantityOrdered AS TotalCost	,
            RO.OpenDate, SL.ReceivedDate, @MasterCompanyId,
            @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
        
		FROM [dbo].[RepairOrderPart] RP WITH(NOLOCK) 
			JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = RP.RepairOrderId
			JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = RP.StockLineId
		WHERE RP.RepairOrderPartRecordId = @RepairOrderPartId AND RP.WorkOrderId = @WorkOrderId AND RP.WorkOrderMaterialsId = @WorkOrderMaterialsId AND ISNULL(SL.IsNonStock,0) = 0

        SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS WOMROHistorId;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
                @AdhocComments VARCHAR(150) = 'USP_InsertWorkOrederMaterialsROHistory',
                @ProcedureParameters VARCHAR(3000) =
                    '@WorkOrderId=' + CAST(@WorkOrderId AS VARCHAR(20)) +
                    ', @WorkOrderMaterialsId=' + CAST(@WorkOrderMaterialsId AS VARCHAR(20)) +
                    ', @RepairOrderId=' + CAST(@RepairOrderId AS VARCHAR(20)) +
                    ', @RepairOrderPartId=' + CAST(@RepairOrderPartId AS VARCHAR(20)) +
                    ', @StocklineId=' + CAST(@StocklineId AS VARCHAR(20)) +
                    ', @MasterCompanyId=' + CAST(@MasterCompanyId AS VARCHAR(20)) +
                    ', @UpdatedBy=' + ISNULL(@UpdatedBy, 'NULL'),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------- 
        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16, 1, @ErrorLogID);

        RETURN(1);
    END CATCH
END