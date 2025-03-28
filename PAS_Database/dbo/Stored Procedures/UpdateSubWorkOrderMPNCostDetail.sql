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
    
    DECLARE @overheadCost DECIMAL(18,2) = 0,
            @labourCost DECIMAL(18,2) = 0,
            @revenue DECIMAL(18,2) = 0,
            @partsRevePer DECIMAL(18,2) = 0,
            @laborRevePer DECIMAL(18,2) = 0,
            @overHeadPer DECIMAL(18,2) = 0,
            @otherCost DECIMAL(18,2) = 0,
            @margin DECIMAL(18,2) = 0,
            @marginPer DECIMAL(18,2) = 0,
            @actRevenue DECIMAL(18,2) = 0,
            @actMargin DECIMAL(18,2) = 0,
            @actMarginPer DECIMAL(18,2) = 0,
            @directCostPer DECIMAL(18,2) = 0,
            @partsCost DECIMAL(18,2) = 0,
            @chargesCost DECIMAL(18,2) = 0,
            @freightCost DECIMAL(18,2) = 0;
    
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
    DECLARE @totalCost DECIMAL(18,2) = 0;
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