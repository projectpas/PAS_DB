/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <02/13/2025>  
** Description: <Save Sub Work Order Materials Issue Stockline Details>  
  
EXEC [usp_IssueSubWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    02/13/2025  HEMANT SALIYA    Update Sub WO MPN Cost Details
** 2    03/28/2025  Moin Bloch       Fixed For Issue Sub WorkOrder And Format SP
** 3    16-Mar-2025	Rajesh Gami		 UOM Changes [PN-15714]       
**************************************************************/ 
CREATE   PROCEDURE [dbo].[UpdateSubWorkOrderMPNCostDetail]
    @workOrderId BIGINT,
    @subWorkOrderId BIGINT,
    @subWOPartNoId BIGINT,
    @updatedBy VARCHAR(100),
    @masterCompanyId INT
AS
BEGIN
   SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
    
    DECLARE @overheadCost [decimal](18,6) = 0,
            @labourCost [decimal](18,6) = 0,
            @revenue [decimal](18,6) = 0,
            @partsRevePer [decimal](18,6) = 0,
            @laborRevePer [decimal](18,6) = 0,
            @overHeadPer [decimal](18,6) = 0,
            @otherCost [decimal](18,6) = 0,
            @margin [decimal](18,6) = 0,
            @marginPer [decimal](18,6) = 0,
            @actRevenue [decimal](18,6) = 0,
            @actMargin [decimal](18,6) = 0,
            @actMarginPer [decimal](18,6) = 0,
            @directCostPer [decimal](18,6) = 0,
            @partsCost [decimal](18,6) = 0,
            @chargesCost [decimal](18,6) = 0,
            @freightCost [decimal](18,6) = 0;
    
    -- Calculate Parts Cost
    SELECT @partsCost = SUM(ISNULL(wms.[UnitCost] * wms.[QtyIssued], 0))
    FROM [dbo].[SubWorkOrderMaterials] wm WITH(NOLOCK)
    JOIN [dbo].[SubWorkOrderMaterialStockLine] wms WITH(NOLOCK) ON wm.[SubWorkOrderMaterialsId] = wms.[SubWorkOrderMaterialsId]
    WHERE wm.[SubWOPartNoId] = @subWOPartNoId AND wm.[IsDeleted] = 0 AND wms.[QtyIssued] > 0;
    
    -- Calculate Charges Cost
    SELECT @chargesCost = SUM(ISNULL([UnitCost] * [Quantity], 0))
    FROM [dbo].[SubWorkOrderCharges] WITH(NOLOCK)
    WHERE [SubWOPartNoId] = @subWOPartNoId AND [IsDeleted] = 0;
    
    -- Calculate Freight Cost
    SELECT @freightCost = SUM(ISNULL([Amount], 0))
    FROM [dbo].[SubWorkOrderFreight] WITH(NOLOCK)
    WHERE [SubWOPartNoId] = @subWOPartNoId AND [IsDeleted] = 0;
    
    -- Calculate Labor Cost and Overhead Cost
    DECLARE @labourHeaderId BIGINT;
    SELECT @labourHeaderId = [SubWorkOrderLaborHeaderId]
    FROM [dbo].[SubWorkOrderLaborHeader] WITH(NOLOCK)
    WHERE [SubWOPartNoId] = @subWOPartNoId AND [IsDeleted] = 0;
    
    IF @labourHeaderId IS NOT NULL
    BEGIN
        SELECT @labourCost = SUM(ISNULL([TotalCost], 0)),
               @overheadCost = SUM(ISNULL([DirectLaborOHCost], 0))
        FROM [dbo].[SubWorkOrderLabor] WITH(NOLOCK)
        WHERE [SubWorkOrderLaborHeaderId] = @labourHeaderId AND [BillableId] = 1 AND [IsActive] = 1 AND [IsDeleted] = 0;
    END   
    -- Calculate Total Cost
    DECLARE @totalCost [decimal](18,6) = 0;
    SET @totalCost = @partsCost + @chargesCost + @freightCost + @labourCost;
    SET @revenue = @partsCost + @labourCost + @otherCost;
    SET @margin = @revenue - (@partsCost + @labourCost + @otherCost);
    
    -- Revenue Percentages
    SET @partsRevePer = CASE WHEN @revenue = 0 THEN 0 ELSE (@partsCost / @revenue) * 100 END;
    SET @laborRevePer = CASE WHEN @revenue = 0 THEN 0 ELSE (@labourCost / @revenue) * 100 END;
    SET @overHeadPer = CASE WHEN @revenue = 0 THEN 0 ELSE (@overheadCost / @revenue) * 100 END;
    SET @marginPer = CASE WHEN @revenue = 0 THEN 0 ELSE (@margin / @revenue) * 100 END;
    SET @directCostPer = CASE WHEN @revenue = 0 THEN 0 ELSE ((@partsCost + @labourCost + @otherCost) / @revenue) * 100 END;    
    -- Update or Insert Work Order Cost Details
    IF EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderMPNCostDetail] WITH(NOLOCK) WHERE [WorkOrderId] = @workOrderId AND [SubWOPartNoId] = @subWOPartNoId)
    BEGIN		
        UPDATE [dbo].[SubWorkOrderMPNCostDetail]
        SET [ActualMargin] = @actMargin,
            [ActualMarginPercentage] = @actMarginPer,
            [ActualRevenue] = @actRevenue,
            [ChargesCost] = @chargesCost,
            [DirectCost] = (@partsCost + @labourCost + @otherCost),
            [DirectCostPercentage] = @directCostPer,
            [FreightCost] = @freightCost,
            [LaborCost] = @labourCost,
            [LaborRevPercentage] = @laborRevePer,
            [Margin] = @margin,
            [MarginPercentage] = @marginPer,
            [OtherCost] = @otherCost,
            [OverHeadCost] = @overheadCost,
            [OverHeadPercentage] = @overHeadPer,
            [PartsCost] = @partsCost,
            [PartsRevPercentage] = @partsRevePer,
            [Revenue] = @revenue,
            [TotalCost] = @totalCost,
            [UpdatedBy] = @updatedBy,
            [UpdatedDate] = GETUTCDATE()
        WHERE [WorkOrderId] = @workOrderId AND [SubWOPartNoId] = @subWOPartNoId;
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[SubWorkOrderMPNCostDetail] (
            [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [ChargesCost], [DirectCost], [DirectCostPercentage],
            [ActualMargin], [ActualMarginPercentage],[ActualRevenue], [FreightCost], [LaborCost], [LaborRevPercentage], [Margin], [MarginPercentage], [OtherCost], [OverHeadCost],
            [OverHeadPercentage], [PartsCost], [PartsRevPercentage], [Revenue], [TotalCost], [CreatedBy], [CreatedDate],
            [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [MasterCompanyId]
        )
        VALUES (
            @workOrderId, @subWorkOrderId, @subWOPartNoId, @chargesCost, (@partsCost + @labourCost + @otherCost), @directCostPer,
            @actMargin, @actMarginPer, @actRevenue, @freightCost, @labourCost, @laborRevePer, @margin, @marginPer, @otherCost, @overheadCost,
            @overHeadPer, @partsCost, @partsRevePer, @revenue, @totalCost, @updatedBy, GETUTCDATE(),
            @updatedBy, GETUTCDATE(), 1, 0, IIF(@masterCompanyId = 0, 1, @masterCompanyId)
        );

		EXEC [dbo].[usp_CalculateSubWorkOrderCostsDetail] @WorkOrderId = @workOrderId, @SubWorkOrderId = @subWorkOrderId, @SubWOPartNoId = @subWOPartNoId, @UpdatedBy = @updatedBy, @MasterCompanyId = @masterCompanyId
    END

	END
	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateSubWorkOrderMPNCostDetail' 
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@workOrderId, '') AS VARCHAR(100))
			                                      + '@Parameter2 = ''' + CAST(ISNULL(@subWorkOrderId, '') AS VARCHAR(100)) 
												  + '@Parameter3 = ''' + CAST(ISNULL(@subWOPartNoId, '') AS VARCHAR(100)) 
												  + '@Parameter4 = ''' + CAST(ISNULL(@updatedBy, '') AS VARCHAR(100)) 
												  + '@Parameter5 = ''' + CAST(ISNULL(@masterCompanyId, '') AS VARCHAR(100))               
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END