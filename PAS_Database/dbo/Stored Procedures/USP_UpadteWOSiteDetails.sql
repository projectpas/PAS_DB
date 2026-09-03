/***************************************************************
 ** File:   [USP_UpadteWOSiteDetails]
 ** Author:   Shrey Chandegara
 ** Description: Update WorkOrder Site Details
 ** Date:  01-04-2025

  ** Change
 **************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    01-04-2025		Shrey Chandegara		Created
    2    02-09-2026        Ayushi Patel            Added @UpdatedBy - the WorkOrderSettlementDetails UPDATE
                                                    never set UpdatedBy, so every "Location Change" confirm
                                                    left the settlement row attributed to whoever last
                                                    touched it, not the person who actually confirmed the
                                                    location change (PN-14788 - found via settlement history)

	exec dbo.USP_UpadteWOSiteDetails 5837
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpadteWOSiteDetails]
@WorkFlowWorkOrderId BIGINT,
@SiteId BIGINT,
@WarehouseId BIGINT = 0,
@LocationId BIGINT = 0,
@ShelfId BIGINT = 0,
@BinId BIGINT = 0,
@UpdatedBy VARCHAR(256) = NULL

AS BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			
			DECLARE @WorkOrderId BIGINT =  0,@StocklineId BIGINT =  0,@WorkOrderPartId BIGINT =  0;
			DECLARE @ExistingStockLineId BIGINT = 0;
			DECLARE @ReceivingCustomerWorkId BIGINT = 0;
			DECLARE @MPN_Location_Changed BIGINT = (SELECT WorkOrderSettlementId FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE WorkOrderSettlementName = 'MPN Location Changed');

			SELECT TOP 1 
				@WorkOrderId = wowf.WorkOrderId, 
				@StockLineId = wp.StockLineId, 
				@WorkOrderPartId = wp.ID
			FROM [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrderPartNumber] wp WITH(NOLOCK) ON wowf.WorkOrderPartNoId = wp.ID
			WHERE wowf.WorkFlowWorkOrderId = @workFlowWorkOrderId;

			SET @ExistingStockLineId = (SELECT TOP 1 StockLineId FROM [dbo].[StockLine] WITH(NOLOCK) WHERE StockLineId = @StockLineId);
			SET @ReceivingCustomerWorkId = (SELECT TOP 1 ReceivingCustomerWorkId FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE StockLineId = @StockLineId);

			IF (@ExistingStockLineId > 0)
			BEGIN
				UPDATE SL
				SET 
					SL.SiteId = @SiteId,
					SL.WarehouseId = CASE WHEN @WarehouseId = 0 THEN NULL ELSE @WarehouseId END,
					SL.LocationId = CASE WHEN @LocationId = 0 THEN NULL ELSE @LocationId END,
					SL.ShelfId = CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END,
					SL.BinId = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END
				FROM [dbo].[StockLine] SL WITH(NOLOCK)
				WHERE SL.StockLineId = @ExistingStockLineId;
			END

			IF (@ReceivingCustomerWorkId > 0)
			BEGIN
				UPDATE RCW
				SET 
					RCW.SiteId = @SiteId,
					RCW.WarehouseId = CASE WHEN @WarehouseId = 0 THEN NULL ELSE @WarehouseId END,
					RCW.LocationId = CASE WHEN @LocationId = 0 THEN NULL ELSE @LocationId END,
					RCW.ShelfId = CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END,
					RCW.BinId = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END
				FROM [dbo].[ReceivingCustomerWork] RCW
				WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId;
			END

			UPDATE WSD
			SET
				WSD.WorkOrderId = @WorkOrderId,
				WSD.workOrderPartNoId = @WorkOrderPartId,
				WSD.WorkFlowWorkOrderId = @workFlowWorkOrderId,
				WSD.WorkOrderSettlementId = @MPN_Location_Changed,
				WSD.IsMastervalue = 1,
				WSD.Isvalue_NA = 0,
				WSD.UpdatedBy = ISNULL(@UpdatedBy, WSD.UpdatedBy),
				WSD.UpdatedDate = GETUTCDATE(),
				WSD.sattlement_DateTime = GETUTCDATE()
			FROM [dbo].[WorkOrderSettlementDetails] WSD
			WHERE WorkOrderId = @WorkOrderId 
			AND WorkFlowWorkOrderId = @workFlowWorkOrderId
			AND workOrderPartNoId = @WorkOrderPartId
			AND WorkOrderSettlementId = @MPN_Location_Changed;

			IF (@ExistingStockLineId > 0)
			BEGIN
				EXEC UpdateStocklineColumnsWithId @ExistingStockLineId;
			END
			
			IF (@ReceivingCustomerWorkId > 0)
			BEGIN
				EXEC UpdateReceivingCustomerColumnsWithId @ReceivingCustomerWorkId;
			END

		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpadteWOSiteDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '')
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