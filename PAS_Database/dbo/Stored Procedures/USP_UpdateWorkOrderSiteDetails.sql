/*************************************************************           
 ** File:   [USP_UpdateWorkOrderSiteDetails]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Update WorkOrder Site Details
 ** Purpose:         
 ** Date:   24-03-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    24-03-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderSiteDetails]
@SubWOPartNoId BIGINT,
@SiteId BIGINT,
@WarehouseId BIGINT,
@LocationId BIGINT,
@ShelfId INT,
@BinId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Retrieve the data from SubWorkOrderPartNumber based on SubWOPartNoId
        DECLARE @WorkOrderId BIGINT,
                @StockLineId BIGINT,
                @SubWorkOrderId BIGINT;

        SELECT TOP 1
            @WorkOrderId = wp.WorkOrderId,
            @StockLineId = wp.StockLineId,
            @SubWorkOrderId = wp.SubWorkOrderId,
            @SubWOPartNoId = wp.SubWOPartNoId
        FROM SubWorkOrderPartNumber wp
        WHERE wp.SubWOPartNoId = @SubWOPartNoId;

        -- Step 2: Retrieve existing StockLine data
        DECLARE @ExistingStockLineId INT;
        SELECT TOP 1 @ExistingStockLineId = StockLineId
        FROM StockLine
        WHERE StockLineId = @StockLineId;

        -- Step 3: Update StockLine with new data
        UPDATE StockLine
        SET 
            SiteId = @SiteId,
            WarehouseId = CASE WHEN @WarehouseId = 0 THEN NULL ELSE @WarehouseId END,
            LocationId = CASE WHEN @LocationId = 0 THEN NULL ELSE @LocationId END,
            ShelfId = CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END,
            BinId = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END
        WHERE StockLineId = @StockLineId;

        -- Step 4: Retrieve existing ReceivingCustomerWork data
        DECLARE @ReceivingCustomerWorkId INT;
        SELECT TOP 1 @ReceivingCustomerWorkId = ReceivingCustomerWorkId
        FROM ReceivingCustomerWork
        WHERE StockLineId = @StockLineId;

        -- Step 5: Update ReceivingCustomerWork if exists
        IF @ReceivingCustomerWorkId IS NOT NULL
        BEGIN
            UPDATE ReceivingCustomerWork
            SET 
                SiteId = @SiteId,
                WarehouseId = CASE WHEN @WarehouseId = 0 THEN NULL ELSE @WarehouseId END,
                LocationId = CASE WHEN @LocationId = 0 THEN NULL ELSE @LocationId END,
                ShelfId = CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END,
                BinId = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END
            WHERE ReceivingCustomerWorkId = @ReceivingCustomerWorkId;
        END

        -- Step 6: Update SubWorkOrderSettlementDetails
        UPDATE SubWorkOrderSettlementDetails
        SET 
            WorkOrderId = @WorkOrderId,
            SubWOPartNoId = @SubWOPartNoId,
            SubWorkOrderId = @SubWorkOrderId,
            WorkOrderSettlementId = (SELECT WorkOrderSettlementId FROM [dbo].WorkOrderSettlement WITH(NOLOCK) WHERE WorkOrderSettlementName='MPN Location Changed'), -- MPN_Location_Changed (Enum value)
            IsMastervalue = 1,
            Isvalue_NA = 0,
            UpdatedDate = GETUTCDATE()
        WHERE WorkOrderId = @WorkOrderId
          AND SubWorkOrderId = @SubWorkOrderId
          AND SubWOPartNoId = @SubWOPartNoId
          AND WorkOrderSettlementId = (SELECT WorkOrderSettlementId FROM [dbo].WorkOrderSettlement WITH(NOLOCK) WHERE WorkOrderSettlementName='MPN Location Changed'); -- MPN_Location_Changed

        -- Step 7: Commit the transaction
        COMMIT TRANSACTION;
    END TRY   
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderSiteDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@SubWOPartNoId, '') + ',
													   @Parameter2 = ' + ISNULL(@SiteId,'') + ', 
													   @Parameter3 = ' + ISNULL(@WarehouseId,'') + ', 
													   @Parameter4 = ' + ISNULL(@LocationId ,'') + ',
													   @Parameter5 = ' + ISNULL(@ShelfId,'') + ', 
													   @Parameter6 = ' + ISNULL(@BinId ,'') +''

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