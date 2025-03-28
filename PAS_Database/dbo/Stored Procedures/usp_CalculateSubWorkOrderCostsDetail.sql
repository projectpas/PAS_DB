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

CREATE   PROCEDURE [dbo].[usp_CalculateSubWorkOrderCostsDetail]
    @WorkOrderId BIGINT,
    @SubWorkOrderId BIGINT,
    @SubWOPartNoId BIGINT,
    @UpdatedBy VARCHAR(256),
    @MasterCompanyId BIGINT
AS
BEGIN
   SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN

    DECLARE 
        @OverheadCost DECIMAL(18,2) = 0,
        @LabourCost DECIMAL(18,2) = 0,
        @Revenue DECIMAL(18,2) = 0,
        @PartsRevePer DECIMAL(18,2) = 0,
        @LaborRevePer DECIMAL(18,2) = 0,
        @OverHeadPer DECIMAL(18,2) = 0,
        @OtherCost DECIMAL(18,2) = 0,
        @Margin DECIMAL(18,2) = 0,
        @MarginPer DECIMAL(18,2) = 0,
        @ActRevenue DECIMAL(18,2) = 0,
        @ActMargin DECIMAL(18,2) = 0,
        @ActMarginPer DECIMAL(18,2) = 0,
        @DirectCostPer DECIMAL(18,2) = 0,
        @TotalCost DECIMAL(18,2) = 0,
        @DirectCost DECIMAL(18,2) = 0,
        @FreightCost DECIMAL(18,2) = 0,
        @ChargesCost DECIMAL(18,2) = 0,
        @PartsCost DECIMAL(18,2) = 0,
        @SubWOCostDetailsId BIGINT = NULL;

    -- Get Work Order Cost Details
    SELECT @SubWOCostDetailsId = [SubWOCostDetailsId], @MasterCompanyId = [MasterCompanyId]
    FROM [dbo].[SubWorkOrderCostDetails] WITH(NOLOCK)
    WHERE [WorkOrderId] = @WorkOrderId AND [SubWorkOrderId] = @SubWorkOrderId;

    -- Get Parts Cost
    SELECT @PartsCost = ISNULL(SUM([UnitCost] * [TotalIssued]), 0)
    FROM [dbo].[SubWorkOrderMaterials] WITH(NOLOCK)
    WHERE [WorkOrderId] = @WorkOrderId AND [SubWorkOrderId] = @SubWorkOrderId AND ISNULL([TotalIssued], 0) > 0 AND [IsDeleted] = 0;

    -- Get Charges Cost
    SELECT @ChargesCost = ISNULL(SUM([UnitCost] * [Quantity]), 0)
    FROM [dbo].[SubWorkOrderCharges] WITH(NOLOCK)
    WHERE [WorkOrderId] = @WorkOrderId AND [SubWorkOrderId] = @SubWorkOrderId AND [IsDeleted] = 0;

    -- Get Freight Cost
    SELECT @FreightCost = ISNULL(SUM([Amount]), 0)
    FROM [dbo].[SubWorkOrderFreight] WITH(NOLOCK)
    WHERE [WorkOrderId] = @WorkOrderId AND [SubWorkOrderId] = @SubWorkOrderId AND IsDeleted = 0;

    -- Get Labour Costs
    DECLARE @LabourHeaderId BIGINT;
    SELECT @LabourHeaderId = [SubWorkOrderLaborHeaderId]
    FROM [dbo].[SubWorkOrderLaborHeader] WITH(NOLOCK)
    WHERE [SubWOPartNoId] = @SubWOPartNoId AND [IsDeleted] = 0;

    IF @LabourHeaderId IS NOT NULL
    BEGIN
        SELECT 
            @LabourCost = ISNULL(SUM([TotalCost]), 0),
            @OverheadCost = ISNULL(SUM([DirectLaborOHCost]), 0)
        FROM [dbo].[SubWorkOrderLabor] WITH(NOLOCK)
        WHERE [SubWorkOrderLaborHeaderId] = @LabourHeaderId AND [BillableId] = 1 AND [IsActive] = 1 AND [IsDeleted] = 0;
    END;

    -- Calculate Totals
    SET @TotalCost = @PartsCost + @ChargesCost + @FreightCost + @LabourCost;
    SET @Revenue = @PartsCost + @LabourCost + @OtherCost;
    SET @DirectCost = @PartsCost + @LabourCost + @OtherCost;
    SET @Margin = @Revenue - @DirectCost;

    -- Calculate Percentages
    SET @PartsRevePer = CASE WHEN @Revenue = 0 THEN 0 ELSE (@PartsCost / @Revenue) * 100 END;
    SET @LaborRevePer = CASE WHEN @Revenue = 0 THEN 0 ELSE (@LabourCost / @Revenue) * 100 END;
    SET @OverHeadPer = CASE WHEN @Revenue = 0 THEN 0 ELSE (@OverheadCost / @Revenue) * 100 END;
    SET @MarginPer = CASE WHEN @Revenue = 0 THEN 0 ELSE (@Margin / @Revenue) * 100 END;
    SET @DirectCostPer = CASE WHEN @Revenue = 0 THEN 0 ELSE (@DirectCost / @Revenue) * 100 END;

    -- Update or Insert into SubWorkOrderCostDetails
    IF @SubWOCostDetailsId IS NOT NULL
    BEGIN
        UPDATE [dbo].[SubWorkOrderCostDetails]
        SET 
            [ActualMargin] = @ActMargin,
            [ActualMarginPercentage] = @ActMarginPer,
            [ActualRevenue] = @ActRevenue,
            [ChargesCost] = @ChargesCost,
            [DirectCost] = @DirectCost,
            [DirectCostPercentage] = @DirectCostPer,
            [FreightCost] = @FreightCost,
            [LaborCost] = @LabourCost,
            [LaborRevPercentage] = @LaborRevePer,
            [Margin] = @Margin,
            [MarginPercentage] = @MarginPer,
            [OtherCost] = @OtherCost,
            [OverHeadCost] = @OverheadCost,
            [OverHeadPercentage] = @OverHeadPer,
            [PartsCost] = @PartsCost,
            [PartsRevPercentage] = @PartsRevePer,
            [Revenue] = @Revenue,
            [TotalCost] = @TotalCost,
            [SubWorkOrderId] = @SubWorkOrderId,
            [SubWOPartNoId] = @SubWOPartNoId,
            [UpdatedBy] = @UpdatedBy,
            [UpdatedDate] = GETUTCDATE()
        WHERE [SubWOCostDetailsId] = @SubWOCostDetailsId;
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[SubWorkOrderCostDetails] 
        (
            [ActualMargin], [ActualMarginPercentage], [ActualRevenue], [ChargesCost], [CreatedBy], [CreatedDate],
            [DirectCost], [DirectCostPercentage], [FreightCost], [IsActive], [IsDeleted], [LaborCost], [LaborRevPercentage],
            [Margin], [MarginPercentage], [MasterCompanyId], [OtherCost], [OverHeadCost], [OverHeadPercentage], [PartsCost],
            [PartsRevPercentage], [Revenue], [TotalCost], [SubWorkOrderId], [SubWOPartNoId], [WorkOrderId], [UpdatedBy], [UpdatedDate]
        )
        VALUES 
        (
            @ActMargin, @ActMarginPer, @ActRevenue, @ChargesCost, @UpdatedBy, GETUTCDATE(),
            @DirectCost, @DirectCostPer, @FreightCost, 1, 0, @LabourCost, @LaborRevePer,
            @Margin, @MarginPer, @MasterCompanyId, @OtherCost, 
            @OverheadCost, @OverHeadPer, @PartsCost, @PartsRevePer, @Revenue, @TotalCost, 
            @SubWorkOrderId, @SubWOPartNoId, @WorkOrderId, @UpdatedBy, GETUTCDATE()
        );
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
              , @AdhocComments     VARCHAR(150)    = 'usp_CalculateSubWorkOrderCostsDetail' 
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