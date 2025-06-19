/*************************************************************           
 ** File:   [GetExchangeBillingList]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeBillingList
 ** Purpose:         
 ** Date:   06/09/2025      
          
 ** PARAMETERS: @ExchangeSalesOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/09/2025   Ekta Chandegra     Created
    2    06/19/2025   Ekta Chandegra     Get correct billing amount when flat rates are added
     
 EXEC GetExchangeBillingList @ExchangeSalesOrderId=185
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeBillingList]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @ExchangeStatusId INT,@FreightsBillingTypeId INT, @ChargesBillingTypeId INT, @ExchangeFeeId INT, @ChargesDescription NVARCHAR(50), @FreightsDescription NVARCHAR(50), @ExchangeFeeDescription  NVARCHAR(50);
		SELECT @ExchangeStatusId = ExchangeStatusId  FROM [dbo].[ExchangeStatus] WITH(NOLOCK) WHERE Name = 'Cancelled';
		SELECT @ExchangeFeeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'EXCH FEE';
		SELECT @FreightsBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'FREIGHT';
		SELECT @ChargesBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE Description = 'Charges';
		SELECT @ChargesDescription = Description FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE ExchangeBillingTypeId = @ChargesBillingTypeId;
		SELECT @FreightsDescription = Description FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE ExchangeBillingTypeId = @FreightsBillingTypeId;
		SELECT @ExchangeFeeDescription = Description FROM [dbo].[ExchangeBillingType] WITH(NOLOCK) WHERE ExchangeBillingTypeId = @ExchangeFeeId;
		
		DECLARE @ExchangeBillingData TABLE (
        ExchangeSalesOrderScheduleBillingId BIGINT NOT NULL, 
        ExchangeSalesOrderPartId BIGINT NOT NULL,          
        ExchangeSalesOrderId BIGINT NOT NULL,              
        ScheduleBillingDate DATETIME2(7) NULL,            
        PeriodicBillingAmount NUMERIC(9, 2) NOT NULL,       
        Cogs INT NOT NULL,                                 
        CogsAmount NUMERIC(9, 2) NULL,                     
        Qty INT NOT NULL,                                   
        BillingTypeId INT NOT NULL,                         
        UnitOfMeasureId BIGINT NULL,                      
        Notes NVARCHAR(MAX) NULL,                           
        Memo NVARCHAR(MAX) NULL,                            
        Type NVARCHAR(50) NOT NULL,                         
        StatusId INT NOT NULL,                              
        
        BillingType NVARCHAR(255) NULL,                     
        ExchangeSalesOrderShippingId BIGINT NULL,          
        InvoiceStatus NVARCHAR(50) NULL,                   
        SOBillingInvoicingId BIGINT NULL,                   
        InvoiceNumber NVARCHAR(255) NULL,                   
        BillingId BIGINT NULL,                              
        isEditPart BIT NULL,                               
        IsCharge BIT NULL,                                  
        IsChargeFlatRate BIT NULL,                         
        IsFreight BIT NULL,                               
        IsFreightFlatRate BIT NULL,                        
     
        ExchangeSalesOrderChargesId BIGINT NULL,            
        ExchangeSalesOrderFreightId BIGINT NULL,           
        IsPartEntry BIT NOT NULL,                           
        BillingAmount DECIMAL(20, 2) NULL,                 
        MarkupPercentageId BIGINT NULL,                     
        ExtendedCost DECIMAL(20, 2) NULL,                   
        ExchangeSalesOrderMarginSummaryId BIGINT NULL       
    );

    -- 1. Get the ExchangeSalesOrder data first
    DECLARE @eso_IsChargeFlatRate BIT;
    DECLARE @eso_IsChargeFlatRateInsert BIT;
    DECLARE @eso_ChargeFlatRate DECIMAL(18, 4);
    DECLARE @eso_IsFreightFlatRate BIT;
    DECLARE @eso_IsFreightFlatRateInsert BIT;
    DECLARE @eso_FreightFlatRate DECIMAL(18, 4); 

    SELECT TOP 1
        @eso_IsChargeFlatRate = eso.IsChargeFlatRate,
        @eso_IsChargeFlatRateInsert = eso.IsChargeFlatRateInsert,
        @eso_ChargeFlatRate = eso.ChargeFlatRate,
        @eso_IsFreightFlatRate = eso.IsFreightFlatRate,
        @eso_IsFreightFlatRateInsert = eso.IsFreightFlatRateInsert,
        @eso_FreightFlatRate = eso.FreightFlatRate
    FROM [dbo].[ExchangeSalesOrder] eso WITH(NOLOCK)
    WHERE eso.ExchangeSalesOrderId = @ExchangeSalesOrderId;


    -- 2. Translate the main LINQ query (billinglist)
    INSERT INTO @ExchangeBillingData
    (
        ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
        ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
        BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
        BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
        InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
        IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
        ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
        ExtendedCost, ExchangeSalesOrderMarginSummaryId
    )
    SELECT DISTINCT
        sqe.ExchangeSalesOrderScheduleBillingId,
        sqe.ExchangeSalesOrderPartId,
        sqe.ExchangeSalesOrderId,
        sqe.ScheduleBillingDate,
        CAST(sqe.PeriodicBillingAmount AS NUMERIC(9,2)), 
        ISNULL(sqe.Cogs, 0), 
        CAST(sqe.CogsAmount AS NUMERIC(9,2)), 
        ISNULL(sqe.Qty, 0),
        ISNULL(sqe.BillingTypeId, 0),
        ISNULL(sqe.UnitOfMeasureId, um.UnitOfMeasureId) AS UnitOfMeasureId,
        sqe.Notes,
        sqe.Memo,
        ISNULL(sqe.Type, ''), 
        ISNULL(sqe.StatusId, 0), 
        BillingType = ebt.Description,
        ExchangeSalesOrderShippingId = essp.ExchangeSalesOrderShippingId,
        InvoiceStatus = esbi.InvoiceStatus,
        SOBillingInvoicingId = esbi.SOBillingInvoicingId,
        InvoiceNumber = esbi.InvoiceNo,
        BillingId = esbi.BillingId,
        isEditPart = 1, 
        IsCharge = 0,
        IsChargeFlatRate = 0,
        IsFreight = 0,
        IsFreightFlatRate = 0,
        ExchangeSalesOrderChargesId = NULL,
        ExchangeSalesOrderFreightId = NULL,
        ISNULL(sqe.IsPartEntry, 0),
        CAST(ISNULL(sqe.BillingAmount, 0) AS DECIMAL(20,2)), 
        sqe.MarkupPercentageId,
        CAST(sqe.ExtendedCost AS DECIMAL(20,2)),
        ExchangeSalesOrderMarginSummaryId = NULL
    FROM [dbo].[ExchangeSalesOrderScheduleBilling] sqe WITH(NOLOCK)
    LEFT JOIN [dbo].[ExchangeSalesOrderPart] part WITH(NOLOCK) ON sqe.ExchangeSalesOrderPartId = part.ExchangeSalesOrderPartId
    LEFT JOIN [dbo].[ExchangeSalesOrder] eso WITH(NOLOCK) ON part.ExchangeSalesOrderId = eso.ExchangeSalesOrderId 
    INNER JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
    LEFT JOIN [dbo].[ExchangeBillingType] ebt WITH(NOLOCK) ON sqe.BillingTypeId = ebt.ExchangeBillingTypeId
    LEFT JOIN [dbo].[ExchangeSalesOrderShipping] essp WITH(NOLOCK) ON sqe.ExchangeSalesOrderId = essp.ExchangeSalesOrderId
    LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] esbii WITH(NOLOCK) ON sqe.ExchangeSalesOrderScheduleBillingId = esbii.ExchangeSalesOrderScheduleBillingId AND ISNULL(esbii.IsDeleted,0) = 0
    LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] esbi WITH(NOLOCK) ON esbii.SOBillingInvoicingId = esbi.SOBillingInvoicingId
    WHERE sqe.ExchangeSalesOrderId = @ExchangeSalesOrderId AND sqe.StatusId != @ExchangeStatusId
    ORDER BY sqe.ExchangeSalesOrderScheduleBillingId;

    -- 3. Handle conditional logic for "Charge"
    IF (@eso_IsChargeFlatRate = 1 AND ISNULL(@eso_IsChargeFlatRateInsert, 0) = 0)
    BEGIN
        INSERT INTO @ExchangeBillingData
        (
            ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
            ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
            BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
            BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
            InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
            IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
            ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
            ExtendedCost, ExchangeSalesOrderMarginSummaryId
        )
        SELECT
            ExchangeSalesOrderScheduleBillingId = 0,
            ExchangeSalesOrderPartId = 0,
            ExchangeSalesOrderId = @ExchangeSalesOrderId,
            ScheduleBillingDate = GETUTCDATE(),
            PeriodicBillingAmount = CAST(ISNULL(@eso_ChargeFlatRate, 0) AS NUMERIC(9,2)), 
            Cogs = 0,
            CogsAmount = CAST(ISNULL(@eso_ChargeFlatRate, 0) AS NUMERIC(9,2)), 
            Qty = 1,
            BillingTypeId = @ChargesBillingTypeId, 
            UnitOfMeasureId = NULL,
            Notes = '',
            Memo = '',
            Type = @ChargesDescription,
            StatusId = 1,
            BillingType = @ChargesDescription,
            ExchangeSalesOrderShippingId = NULL,
            InvoiceStatus = '',
            SOBillingInvoicingId = NULL,
            InvoiceNumber = '-',
            BillingId = NULL,
            isEditPart = 1,
            IsCharge = 1,
            IsChargeFlatRate = 1,
            IsFreight = 0,
            IsFreightFlatRate = 0,
            ExchangeSalesOrderChargesId = NULL,
            ExchangeSalesOrderFreightId = NULL,
            IsPartEntry = 0, 
            BillingAmount = CAST(ISNULL(@eso_ChargeFlatRate, 0) AS DECIMAL(20,2)),
            MarkupPercentageId = 0,
            ExtendedCost = CAST(ISNULL(@eso_ChargeFlatRate, 0) AS DECIMAL(20,2)),
            ExchangeSalesOrderMarginSummaryId = NULL;
    END
    ELSE
    BEGIN
        -- Local variables for Charges data (adjusted types and nullability based on source table potential)
        DECLARE @exSOChargesData_ExtendedCost DECIMAL(20, 2);
        DECLARE @exSOChargesData_UomId BIGINT;
        DECLARE @exSOChargesData_BillingMethodId INT;
        DECLARE @exSOChargesData_ExchangeSalesOrderId BIGINT;
        DECLARE @exSOChargesData_MarkupPercentageId BIGINT;
        DECLARE @exSOChargesData_BillingAmount DECIMAL(20, 2);
        DECLARE @exSOChargesData_Quantity INT;
        DECLARE @exSOChargesData_BillingRate NUMERIC(9,2); 
        DECLARE @exSOChargesData_Description NVARCHAR(MAX);
        DECLARE @exSOChargesData_ExchangeSalesOrderChargesId BIGINT;

        SELECT TOP 1
            @exSOChargesData_ExtendedCost = esc.ExtendedCost,
            @exSOChargesData_UomId = esc.UomId,
            @exSOChargesData_BillingMethodId = esc.BillingMethodId,
            @exSOChargesData_ExchangeSalesOrderId = esc.ExchangeSalesOrderId,
            @exSOChargesData_MarkupPercentageId = esc.MarkupPercentageId,
            @exSOChargesData_BillingAmount = esc.BillingAmount,
            @exSOChargesData_Quantity = esc.Quantity,
            @exSOChargesData_BillingRate = esc.BillingRate,
            @exSOChargesData_Description = esc.Description,
            @exSOChargesData_ExchangeSalesOrderChargesId = esc.ExchangeSalesOrderChargesId
        FROM [dbo].[ExchangeSalesOrderCharges] esc WITH(NOLOCK)
        WHERE esc.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esc.IsInsert = 0 AND ISNULL(esc.IsDeleted, 0) = 0;

        DECLARE @exSOMarginChargeData_OtherCharges DECIMAL(20, 2);
        DECLARE @exSOMarginChargeData_ExchangeSalesOrderId BIGINT;
        DECLARE @exSOMarginChargeData_IsChargeInsert BIT;
        DECLARE @exSOMarginChargeData_ExchangeSalesOrderMarginSummaryId BIGINT;

        SELECT TOP 1
            @exSOMarginChargeData_OtherCharges = esms.OtherCharges,
            @exSOMarginChargeData_ExchangeSalesOrderId = esms.ExchangeSalesOrderId,
            @exSOMarginChargeData_IsChargeInsert = ISNULL(esms.IsChargeInsert, 0),
            @exSOMarginChargeData_ExchangeSalesOrderMarginSummaryId = esms.ExchangeSalesOrderMarginSummaryId
        FROM [dbo].[ExchangeSalesOrderMarginSummary] esms WITH(NOLOCK)
		WHERE esms.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esms.OtherCharges > 0 AND ISNULL(esms.IsChargeInsert, 0) = 0; 


        IF (@exSOMarginChargeData_ExchangeSalesOrderId IS NOT NULL AND ((@exSOChargesData_BillingMethodId = @FreightsBillingTypeId) OR (@exSOChargesData_ExchangeSalesOrderId IS NOT NULL)))
        BEGIN
            INSERT INTO @ExchangeBillingData
            (
                ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
                ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
                BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
                BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
                InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
                IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
                ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
                ExtendedCost, ExchangeSalesOrderMarginSummaryId
            )
            SELECT
                ExchangeSalesOrderScheduleBillingId = 0,
                ExchangeSalesOrderPartId = 0,
                ExchangeSalesOrderId = @exSOMarginChargeData_ExchangeSalesOrderId,
                ScheduleBillingDate = GETUTCDATE(),
                PeriodicBillingAmount = CAST(ISNULL(@exSOMarginChargeData_OtherCharges, 0) AS NUMERIC(9,2)), 
                Cogs = 0,
                CogsAmount = CAST(ISNULL(@exSOChargesData_ExtendedCost, 0) AS NUMERIC(9,2)), -- Cast
                Qty = 1,
                BillingTypeId = @ChargesBillingTypeId,
                UnitOfMeasureId = @exSOChargesData_UomId,
                Notes = '',
                Memo = '',
                Type = @ChargesDescription,
                StatusId = 1,
                BillingType = @ChargesDescription,
                ExchangeSalesOrderShippingId = NULL,
                InvoiceStatus = '',
                SOBillingInvoicingId = NULL,
                InvoiceNumber = '-',
                BillingId = NULL,
                isEditPart = 1,
                IsCharge = 1,
                IsChargeFlatRate = 0,
                IsFreight = 0,
                IsFreightFlatRate = 0,
                ExchangeSalesOrderChargesId = NULL,
                ExchangeSalesOrderFreightId = NULL,
                IsPartEntry = 0,
                BillingAmount = CAST(ISNULL(@exSOMarginChargeData_OtherCharges, 0) AS DECIMAL(20,2)),
                MarkupPercentageId = ISNULL(@exSOChargesData_MarkupPercentageId, 0),
                ExtendedCost = CAST(ISNULL(@exSOMarginChargeData_OtherCharges, 0) AS DECIMAL(20,2)),
                ExchangeSalesOrderMarginSummaryId = @exSOMarginChargeData_ExchangeSalesOrderMarginSummaryId;
        END
        ELSE
        BEGIN
            INSERT INTO @ExchangeBillingData
            (
                ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
                ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
                BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
                BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
                InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
                IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
                ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
                ExtendedCost, ExchangeSalesOrderMarginSummaryId
            )
            SELECT
                ExchangeSalesOrderScheduleBillingId = 0,
                ExchangeSalesOrderPartId = 0, 
                ExchangeSalesOrderId = cc.ExchangeSalesOrderId,
                ScheduleBillingDate = GETUTCDATE(),
                PeriodicBillingAmount = CAST(ISNULL(cc.BillingRate, 0) AS NUMERIC(9,2)), 
                Cogs = 0,
                CogsAmount = CAST(ISNULL(cc.ExtendedCost, 0) AS NUMERIC(9,2)),
                Qty = ISNULL(cc.Quantity, 0), 
                BillingTypeId = @ChargesBillingTypeId,
                UnitOfMeasureId = cc.UomId,
                Notes = ISNULL(cc.Description, ''),
                Memo = '',
                Type = @ChargesDescription,
                StatusId = 1,
                BillingType = @ChargesDescription,
                ExchangeSalesOrderShippingId = NULL,
                InvoiceStatus = '',
                SOBillingInvoicingId = NULL,
                InvoiceNumber = '-',
                BillingId = NULL,
                isEditPart = 1,
                IsCharge = 1,
                IsChargeFlatRate = CASE WHEN cc.BillingMethodId = @FreightsBillingTypeId THEN 1 ELSE 0 END,
                IsFreight = 0,
                IsFreightFlatRate = 0,
                ExchangeSalesOrderChargesId = cc.ExchangeSalesOrderChargesId,
                ExchangeSalesOrderFreightId = NULL,
                IsPartEntry = 0,
                BillingAmount = CAST(ISNULL(cc.BillingAmount, 0) AS DECIMAL(20,2)), 
                MarkupPercentageId = ISNULL(cc.MarkupPercentageId, 0),
                ExtendedCost = CAST(ISNULL(cc.BillingAmount, 0) AS DECIMAL(20,2)), 
                ExchangeSalesOrderMarginSummaryId = NULL
            FROM [dbo].[ExchangeSalesOrderCharges] cc WITH(NOLOCK)
            WHERE cc.ExchangeSalesOrderId = @ExchangeSalesOrderId AND cc.IsInsert = 0 AND ISNULL(cc.IsDeleted, 0) = 0;
        END;
    END;

    -- 4. Handle conditional logic for "Freight"
    IF (@eso_IsFreightFlatRate = 1 AND ISNULL(@eso_IsFreightFlatRateInsert, 0) = 0)
    BEGIN
        INSERT INTO @ExchangeBillingData
        (
            ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
            ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
            BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
            BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
            InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
            IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
            ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
            ExtendedCost, ExchangeSalesOrderMarginSummaryId
        )
        SELECT
            ExchangeSalesOrderScheduleBillingId = 0,
            ExchangeSalesOrderPartId = 0,
            ExchangeSalesOrderId = @ExchangeSalesOrderId,
            ScheduleBillingDate = GETUTCDATE(),
            PeriodicBillingAmount = CAST(ISNULL(@eso_FreightFlatRate, 0) AS NUMERIC(9,2)), 
            Cogs = 0,
            CogsAmount = CAST(ISNULL(@eso_FreightFlatRate, 0) AS NUMERIC(9,2)), -- Cast
            Qty = 1,
            BillingTypeId = @FreightsBillingTypeId, 
            UnitOfMeasureId = NULL,
            Notes = '',
            Memo = '',
            Type = @FreightsDescription,
            StatusId = 1,
            BillingType = @FreightsDescription,
            ExchangeSalesOrderShippingId = NULL,
            InvoiceStatus = '',
            SOBillingInvoicingId = NULL,
            InvoiceNumber = '-',
            BillingId = NULL,
            isEditPart = 1,
            IsCharge = 0,
            IsChargeFlatRate = 0,
            IsFreight = 1,
            IsFreightFlatRate = 1,
            ExchangeSalesOrderChargesId = NULL,
            ExchangeSalesOrderFreightId = NULL,
            IsPartEntry = 0,
            BillingAmount = CAST(ISNULL(@eso_FreightFlatRate, 0) AS DECIMAL(20,2)), 
            MarkupPercentageId = 0,
            ExtendedCost = CAST(ISNULL(@eso_FreightFlatRate, 0) AS DECIMAL(20,2)), 
            ExchangeSalesOrderMarginSummaryId = NULL;
    END
    ELSE
    BEGIN
        -- Local variables for Freight data
        DECLARE @exSOFreightData_Amount DECIMAL(20, 2);
        DECLARE @exSOFreightData_BillingMethodId INT;
        DECLARE @exSOFreightData_UOMId BIGINT;
        DECLARE @exSOFreightData_ExchangeSalesOrderId BIGINT;
        DECLARE @exSOFreightData_MarkupPercentageId BIGINT;
        DECLARE @exSOFreightData_BillingAmount DECIMAL(20, 2);
        DECLARE @exSOFreightData_Memo NVARCHAR(MAX);
        DECLARE @exSOFreightData_ExchangeSalesOrderFreightId BIGINT;

        SELECT TOP 1
            @exSOFreightData_Amount = esf.Amount,
            @exSOFreightData_BillingMethodId = esf.BillingMethodId,
            @exSOFreightData_UOMId = esf.UOMId,
            @exSOFreightData_ExchangeSalesOrderId = esf.ExchangeSalesOrderId,
            @exSOFreightData_MarkupPercentageId = esf.MarkupPercentageId,
            @exSOFreightData_BillingAmount = esf.BillingAmount,
            @exSOFreightData_Memo = esf.Memo,
            @exSOFreightData_ExchangeSalesOrderFreightId = esf.ExchangeSalesOrderFreightId
        FROM [dbo].[ExchangeSalesOrderFreight] esf WITH(NOLOCK)
        WHERE esf.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esf.IsInsert = 0 AND ISNULL(esf.IsDeleted, 0) = 0;

        DECLARE @exSOMarginData_FreightAmount DECIMAL(20, 2);
        DECLARE @exSOMarginData_ExchangeSalesOrderId BIGINT;
        DECLARE @exSOMarginData_IsFreightInsert BIT; 
        DECLARE @exSOMarginData_ExchangeSalesOrderMarginSummaryId BIGINT;

        SELECT TOP 1
            @exSOMarginData_FreightAmount = esms.FreightAmount,
            @exSOMarginData_ExchangeSalesOrderId = esms.ExchangeSalesOrderId,
            @exSOMarginData_IsFreightInsert = ISNULL(esms.IsFreightInsert, 0), 
            @exSOMarginData_ExchangeSalesOrderMarginSummaryId = esms.ExchangeSalesOrderMarginSummaryId
        FROM [dbo].[ExchangeSalesOrderMarginSummary] esms WITH(NOLOCK)
        WHERE esms.ExchangeSalesOrderId = @ExchangeSalesOrderId AND esms.FreightAmount > 0 AND ISNULL(esms.IsFreightInsert, 0) = 1;


        IF (@exSOMarginData_ExchangeSalesOrderId IS NOT NULL AND ((@exSOFreightData_BillingMethodId = @FreightsBillingTypeId) OR (@exSOFreightData_ExchangeSalesOrderId IS NOT NULL)))
        BEGIN
            INSERT INTO @ExchangeBillingData
            (
                ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
                ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
                BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
                BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
                InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
                IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
                ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
                ExtendedCost, ExchangeSalesOrderMarginSummaryId
            )
            SELECT
                ExchangeSalesOrderScheduleBillingId = 0,
                ExchangeSalesOrderPartId = 0,
                ExchangeSalesOrderId = @exSOMarginData_ExchangeSalesOrderId,
                ScheduleBillingDate = GETUTCDATE(),
                PeriodicBillingAmount = CAST(ISNULL(@exSOMarginData_FreightAmount, 0) AS NUMERIC(9,2)), -- Cast and ensure NOT NULL
                Cogs = 0,
                CogsAmount = CAST(ISNULL(@exSOFreightData_Amount, 0) AS NUMERIC(9,2)), -- Cast
                Qty = 1,
                BillingTypeId = @FreightsBillingTypeId,
                UnitOfMeasureId = @exSOFreightData_UOMId,
                Notes = '',
                Memo = '',
                Type = @FreightsDescription,
                StatusId = 1,
                BillingType = @FreightsDescription,
                ExchangeSalesOrderShippingId = NULL,
                InvoiceStatus = '',
                SOBillingInvoicingId = NULL,
                InvoiceNumber = '-',
                BillingId = NULL,
                isEditPart = 1,
                IsCharge = 0,
                IsChargeFlatRate = 0,
                IsFreight = 1,
                IsFreightFlatRate = 0,
                ExchangeSalesOrderChargesId = NULL,
                ExchangeSalesOrderFreightId = NULL,
                IsPartEntry = 0,
                BillingAmount = CAST(ISNULL(@exSOMarginData_FreightAmount, 0) AS DECIMAL(20,2)), 
                MarkupPercentageId = ISNULL(@exSOFreightData_MarkupPercentageId, 0),
                ExtendedCost = CAST(ISNULL(@exSOMarginData_FreightAmount, 0) AS DECIMAL(20,2)), 
                ExchangeSalesOrderMarginSummaryId = @exSOMarginData_ExchangeSalesOrderMarginSummaryId;
        END
        ELSE
        BEGIN
            INSERT INTO @ExchangeBillingData
            (
                ExchangeSalesOrderScheduleBillingId, ExchangeSalesOrderPartId, ExchangeSalesOrderId,
                ScheduleBillingDate, PeriodicBillingAmount, Cogs, CogsAmount, Qty,
                BillingTypeId, UnitOfMeasureId, Notes, Memo, Type, StatusId,
                BillingType, ExchangeSalesOrderShippingId, InvoiceStatus, SOBillingInvoicingId,
                InvoiceNumber, BillingId, isEditPart, IsCharge, IsChargeFlatRate,
                IsFreight, IsFreightFlatRate, ExchangeSalesOrderChargesId,
                ExchangeSalesOrderFreightId, IsPartEntry, BillingAmount, MarkupPercentageId,
                ExtendedCost, ExchangeSalesOrderMarginSummaryId
            )
            SELECT
                ExchangeSalesOrderScheduleBillingId = 0,
                ExchangeSalesOrderPartId = 0,
                ExchangeSalesOrderId = c.ExchangeSalesOrderId,
                ScheduleBillingDate = GETUTCDATE(),
                PeriodicBillingAmount = CAST(ISNULL(c.BillingAmount, 0) AS NUMERIC(9,2)), 
                Cogs = 0,
                CogsAmount = CAST(ISNULL(c.Amount, 0) AS NUMERIC(9,2)), -- Cast
                Qty = 1,
                BillingTypeId = @FreightsBillingTypeId,
                UnitOfMeasureId = c.UOMId,
                Notes = '',
                Memo = ISNULL(c.Memo, ''),
                Type = @FreightsDescription,
                StatusId = 1,
                BillingType = @FreightsDescription,
                ExchangeSalesOrderShippingId = NULL,
                InvoiceStatus = '',
                SOBillingInvoicingId = NULL,
                InvoiceNumber = '-',
                BillingId = NULL,
                isEditPart = 1,
                IsCharge = 0,
                IsChargeFlatRate = 0,
                IsFreight = 1,
                IsFreightFlatRate = CASE WHEN c.BillingMethodId = @FreightsBillingTypeId THEN 1 ELSE 0 END,
                ExchangeSalesOrderChargesId = NULL,
                ExchangeSalesOrderFreightId = c.ExchangeSalesOrderFreightId,
                IsPartEntry = 0,
                BillingAmount = CAST(ISNULL(c.BillingAmount, 0) AS DECIMAL(20,2)), 
                MarkupPercentageId = ISNULL(c.MarkupPercentageId, 0),
                ExtendedCost = CAST(ISNULL(c.Amount, 0) AS DECIMAL(20,2)), 
                ExchangeSalesOrderMarginSummaryId = NULL
            FROM [dbo].[ExchangeSalesOrderFreight] c WITH(NOLOCK)
            WHERE c.ExchangeSalesOrderId = @ExchangeSalesOrderId AND c.IsInsert = 0 AND ISNULL(c.IsDeleted, 0) = 0 AND c.BillingMethodId != @FreightsBillingTypeId;
        END;
    END;

    -- Final selection from the consolidated table variable
    SELECT *
    FROM @ExchangeBillingData
    ORDER BY ExchangeSalesOrderScheduleBillingId ;

	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeBillingList'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100))
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