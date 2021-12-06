﻿
/*************************************************************           
 ** File:   [USP_CreateSOStocklineFromRO]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Crate A Stockline from SO Parts
 ** Purpose:         
 ** Date:   08/25/2021        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author    Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/25/2021   Vishal Suthar Created
     
 EXECUTE USP_CreateSOStocklineFromRO 134

**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateSOStocklineFromRO] 
(
	@RepairOrderId bigint = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
        DECLARE @RowCount int = 0;
        DECLARE @StocklineId bigint;
        DECLARE @Quantity int = 0;
        DECLARE @QtyFulfilled int = 0;
        DECLARE @SalesOrderPartId bigint = 0;
        DECLARE @ExSalesOrderPartId bigint;
        DECLARE @MasterCompanyId int;
        DECLARE @SalesOrderId bigint;
        DECLARE @LoopID AS int;
		DECLARE @MasterLoopID AS INT;
		DECLARE @RepairOrderPartId BIGINT;
		DECLARE @StlQuantity BIGINT;

        IF OBJECT_ID(N'tempdb..#ROStockLineSamePart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineSamePart
        END

        IF OBJECT_ID(N'tempdb..#ROStockLineRevisedPart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineRevisedPart
        END

        CREATE TABLE #ROStockLineSamePart (
          ID bigint NOT NULL IDENTITY,
          ItemMasterId bigint NULL,
          ConditionId bigint NULL,
          StockLineId bigint NULL,
          OldStockLineId bigint NULL,
          SalesOrderId bigint NULL,
          RepairOrderId bigint NULL,
          MasterCompanyId int NULL,
          RepairOrderNumber varchar(500) NULL
        )

        CREATE TABLE #ROStockLineRevisedPart (
          ID bigint NOT NULL IDENTITY,
          ItemMasterId bigint NULL,
          ConditionId bigint NULL,
          StockLineId bigint NULL,
          OldStockLineId bigint NULL,
          SalesOrderId bigint NULL,
          RepairOrderId bigint NULL,
          MasterCompanyId int NULL,
          RepairOrderNumber varchar(500) NULL
        )

		IF OBJECT_ID(N'tempdb..#RepairOrderPartData') IS NOT NULL
        BEGIN
			DROP TABLE #RepairOrderPartData
        END

        CREATE TABLE #RepairOrderPartData (
          ID int IDENTITY,
          RepairOrderPartID bigint
        )

		IF OBJECT_ID(N'tempdb..#SalesOrderPartDetails') IS NOT NULL
        BEGIN
          DROP TABLE #SalesOrderPartDetails
        END

        CREATE TABLE #SalesOrderPartDetails (
          ID bigint NOT NULL IDENTITY,
          SalesOrderPartId bigint NULL
        )

        INSERT INTO #RepairOrderPartData (RepairOrderPartID) SELECT RepairOrderPartRecordId FROM dbo.RepairOrderPart RP WITH (NOLOCK) WHERE RP.RepairOrderId = @RepairOrderId
        
		SELECT @MasterLoopID = MAX(ID) FROM #RepairOrderPartData
        
		WHILE (@MasterLoopID > 0)
        BEGIN
          IF OBJECT_ID(N'tempdb..#StockLine') IS NOT NULL
          BEGIN
            DROP TABLE #StockLine
          END

          IF OBJECT_ID(N'tempdb..#StockLineData') IS NOT NULL
          BEGIN
            DROP TABLE #StockLineData
          END

          CREATE TABLE #StockLineData (
            ID int IDENTITY,
            StockLineID bigint
          )

		  SELECT @RepairOrderPartId = RepairOrderPartID FROM #RepairOrderPartData WHERE ID  = @MasterLoopID
          
		  IF((SELECT COUNT(1) FROM dbo.Stockline SL WITH(NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId  AND IsParent = 1 
		  AND Sl.QuantityAvailable > 0 AND SL.RepairOrderPartRecordId = @RepairOrderPartId) > 0)
		  BEGIN
			SELECT * INTO #StockLine FROM dbo.Stockline SL WITH (NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId
			AND SL.RepairOrderPartRecordId = @RepairOrderPartId
            AND IsParent = 1 AND Sl.QuantityAvailable > 0

			INSERT INTO #StockLineData (StockLineID) SELECT StockLineID FROM #StockLine
		  END

		  SELECT @Quantity = SOP.Qty, @SalesOrderId = SOP.SalesOrderId, @MasterCompanyId = SOP.MasterCompanyId
			FROM dbo.RepairOrderPart RP WITH (NOLOCK)
			JOIN dbo.SalesOrderPart SOP WITH (NOLOCK)
			  ON RP.StockLineId = SOP.StocklineId
			WHERE RP.RepairOrderId = @RepairOrderId
			AND RP.RepairOrderPartRecordId = @RepairOrderPartId

			SET @QtyFulfilled = @Quantity;

          SELECT @LoopID = MAX(ID) FROM #StockLineData
          WHILE (@LoopID > 0)
          BEGIN
            SELECT @StocklineId = StocklineId FROM #StockLineData WHERE ID = @LoopID
            IF (@QtyFulfilled > 0)
            BEGIN
              IF ((SELECT COUNT(1) FROM dbo.RepairOrderPart RP WITH (NOLOCK) JOIN #StockLine SL
                  ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId WHERE ISNULL(RP.RevisedPartId, 0) > 0
                AND SL.StockLineId = @StocklineId) > 0)
              BEGIN
				DELETE FROM #ROStockLineRevisedPart
                --CASE 1 REVISED PART
                INSERT INTO #ROStockLineRevisedPart (ItemMasterId, ConditionId, SalesOrderId, RepairOrderId, RepairOrderNumber, StockLineId, OldStockLineId)
                  SELECT DISTINCT TOP 1
                    RP.ItemMasterId,
                    RP.ConditionId,
                    RP.SalesOrderId,
                    RP.RepairOrderId,
                    RO.RepairOrderNumber,
                    SL.StockLineId,
                    RP.StockLineId
                  FROM dbo.RepairOrderPart RP WITH (NOLOCK)
                  JOIN dbo.ItemMaster IM ON RP.RevisedPartId = IM.ItemMasterId
                  JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
                  JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
                  WHERE SL.StockLineId = @StocklineId

                IF ((SELECT COUNT(1) FROM dbo.SalesOrderPart WITH (NOLOCK) WHERE SalesOrderPartId = ISNULL(@SalesOrderPartId, 0)) = 0)
                BEGIN
                  INSERT INTO dbo.SalesOrderPart (SalesOrderId, ItemMasterId, StockLineId, FxRate, Qty, UnitSalePrice, MarkUpPercentage, SalesBeforeDiscount, Discount,
                  DiscountAmount, NetSales, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsDeleted, UnitCost,
                  MethodType, SalesPriceExtended, MarkupExtended, SalesDiscountExtended, NetSalePriceExtended, UnitCostExtended,
                  MarginAmount, MarginAmountExtended, MarginPercentage, ConditionId, SalesOrderQuoteId, SalesOrderQuotePartId,
                  IsActive, CustomerRequestDate, PromisedDate, EstimatedShipDate, PriorityId, StatusId, CustomerReference, QtyRequested,
                  Notes, CurrencyId, MarkupPerUnit, GrossSalePricePerUnit, GrossSalePrice, TaxType, TaxPercentage, TaxAmount,
                  AltOrEqType, ControlNumber, IdNumber, ItemNo)
                    SELECT DISTINCT
                      ROS.SalesOrderId,
                      SL.ItemMasterId,
                      @StockLineId,
                      1.0000,
                      CASE
                        WHEN SL.QuantityAvailable > @Quantity THEN @Quantity
                        ELSE SL.QuantityAvailable
                      END,
                      SOP.UnitSalePrice,
                      SOP.MarkUpPercentage,
                      SOP.SalesBeforeDiscount,
                      SOP.Discount,
                      SOP.DiscountAmount,
                      SOP.NetSales,
                      SOP.MasterCompanyId,
                      SOP.CreatedBy,
                      GETDATE(),
                      SOP.UpdatedBy,
                      GETDATE(),
                      0,
                      ISNULL(SL.UnitCost, 0),
                      SOP.MethodType,
                      SOP.SalesPriceExtended,
                      SOP.MarkupExtended,
                      SOP.SalesDiscountExtended,
                      SOP.NetSalePriceExtended,
                      -- Update based on Unit Cost
                      SOP.UnitCostExtended,
                      SOP.MarginAmount,
                      SOP.MarginAmountExtended,
                      SOP.MarginPercentage,
                      ROS.ConditionId,
                      NULL,
                      NULL,
                      1,
                      SOP.CustomerRequestDate,
                      SOP.PromisedDate,
                      SOP.EstimatedShipDate,
                      SOP.PriorityId,
                      SOP.StatusId,
                      'Created from RO',
                      @Quantity,
                      NULL,
                      SOP.CurrencyId,
                      SOP.MarkupPerUnit,
                      SOP.GrossSalePricePerUnit,
                      SOP.GrossSalePrice,
                      SOP.TaxType,
                      SOP.TaxPercentage,
                      SOP.TaxAmount,
                      SOP.AltOrEqType,
                      SL.ControlNumber,
                      SL.IdNumber,
                      1
                    FROM #ROStockLineRevisedPart ROS WITH (NOLOCK)
                    JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
                    JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
                    JOIN dbo.SalesOrderPart SOP ON SOP.StockLineId = ROS.OldStockLineId
					AND SL.IsParent = 1 AND SOP.SalesOrderId = @SalesOrderId
                    WHERE SL.StockLineId = @StocklineId;

                  SELECT @SalesOrderPartId = SCOPE_IDENTITY()

				  INSERT INTO #SalesOrderPartDetails (SalesOrderPartId) SELECT @SalesOrderPartId

				  INSERT INTO [dbo].[SalesOrderReserveParts]
								   ([SalesOrderId]
								   ,[StockLineId]
								   ,[ItemMasterId]
								   ,[PartStatusId]
								   ,[IsEquPart]
								   ,[EquPartMasterPartId]
								   ,[IsAltPart]
								   ,[AltPartMasterPartId]
								   ,[QtyToReserve]
								   ,[QtyToIssued]
								   ,[ReservedById]
								   ,[ReservedDate]
								   ,[IssuedById]
								   ,[IssuedDate]
								   ,[CreatedBy]
								   ,[CreatedDate]
								   ,[UpdatedBy]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted]
								   ,[SalesOrderPartId]
								   ,[TotalReserved]
								   ,[TotalIssued]
								   ,[MasterCompanyId])
							 SELECT SOP.SalesOrderId, SOP.StockLineId, SOP.ItemMasterId, 1,
							 0, NULL, 0, NULL, SOP.Qty, 0, 
							 (SELECT TOP 1 EmployeeId FROM DBO.Employee Where MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
							 GETDATE(), NULL, GETDATE(), SOP.CreatedBy, GETDATE(),SOP.UpdatedBy, GETDATE(), 1, 0, @SalesOrderPartId, 
							 SOP.Qty, 0, @MasterCompanyId
							 FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId

					INSERT INTO [dbo].[SalesOrderReservedStock]
								   ([SalesOrderId]
								   ,[SalesOrderPartId]
								   ,[StockLIneId]
								   ,[ConditionId]
								   ,[ItemMasterId]
								   ,[Quantity]
								   ,[AltPartMasterPartId]
								   ,[EquPartMasterPartId]
								   ,[IsAltPart]
								   ,[IsEquPart]
								   ,[ReservedById]
								   ,[ReservedDate]
								   ,[MasterCompanyId]
								   ,[CreatedBy]
								   ,[UpdatedBy]
								   ,[CreatedDate]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted])
							SELECT SOP.SalesOrderId, @SalesOrderPartId, SOP.StockLineId, SOP.ConditionId,
							SOP.ItemMasterId, SOP.Qty, NULL, NULL, 0, 0,
							(SELECT TOP 1 EmployeeId FROM DBO.Employee Where MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
							GETDATE(), @MasterCompanyId, SOP.CreatedBy, SOP.UpdatedBy, GETDATE(), GETDATE(), 1, 0
							FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId

					INSERT INTO [dbo].[SalesOrderStockLine]
									   ([SalesOrderId]
									   ,[SalesOrderPartId]
									   ,[StockLIneId]
									   ,[ItemMasterId]
									   ,[ConditionId]
									   ,[Quantity]
									   ,[QtyReserved]
									   ,[QtyIssued]
									   ,[AltPartMasterPartId]
									   ,[EquPartMasterPartId]
									   ,[IsAltPart]
									   ,[IsEquPart]
									   ,[UnitCost]
									   ,[ExtendedCost]
									   ,[UnitPrice]
									   ,[ExtendedPrice]
									   ,[MasterCompanyId]
									   ,[CreatedBy]
									   ,[UpdatedBy]
									   ,[CreatedDate]
									   ,[UpdatedDate]
									   ,[IsActive]
									   ,[IsDeleted])
									SELECT SOP.SalesOrderId, @SalesOrderPartId, SOP.StockLineId, SOP.ItemMasterId, SOP.ConditionId,
									SOP.Qty, SOP.Qty, 0, NULL, NULL, 0, 0, 0.00, 0.00, 0.00, 0.00, @MasterCompanyId,
									SOP.CreatedBy, SOP.UpdatedBy, GETDATE(), GETDATE(), 1, 0
									FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId

					SELECT @StlQuantity = SOP.Qty FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId
					UPDATE Stockline SET QuantityAvailable = QuantityAvailable - @StlQuantity, QuantityReserved = @StlQuantity WHERE StockLineId = @StocklineId
                END

                UPDATE dbo.SalesOrderPart
                SET UnitCostExtended = ISNULL(UnitCost, 0) * ISNULL(Qty, 0), SalesPriceExtended = ISNULL(UnitSalePrice, 0) * ISNULL(Qty, 0),
				SalesBeforeDiscount = ISNULL(UnitSalePrice, 0) * ISNULL(Qty, 0)
                WHERE SalesOrderPartId = @SalesOrderPartId

                SELECT @QtyFulfilled SET @QtyFulfilled = @QtyFulfilled - (SELECT SUM(ISNULL(Qty,0)) FROM dbo.SalesOrderPart WITH (NOLOCK) 
				WHERE SalesOrderPartId IN (SELECT SalesOrderPartId FROM #SalesOrderPartDetails))

                SELECT @ExSalesOrderPartId = SOP.SalesOrderPartId FROM dbo.SalesOrderPart SOP WITH (NOLOCK)
                JOIN dbo.RepairOrderPart RP WITH (NOLOCK) ON RP.StockLineId = SOP.StocklineId
                WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId
				AND SOP.SalesOrderId = @SalesOrderId

                IF (@QtyFulfilled <= 0)
                BEGIN
                  DELETE SOSTL FROM dbo.SalesOrderStockLine SOSTL WHERE SOSTL.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOA FROM dbo.SalesOrderApproval SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORS FROM dbo.SalesOrderReservedStock SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOPM FROM dbo.SOPartsMapping SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORP FROM dbo.SalesOrderReserveParts SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOURP FROM dbo.SalesOrderUnReservedStock SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOP FROM dbo.SalesOrderPart SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;
                END

                IF ((SELECT COUNT(1) FROM dbo.SalesOrderPart WITH (NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId) = 0)
                BEGIN
                  DELETE SOSTL FROM dbo.SalesOrderStockLine SOSTL WHERE SOSTL.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOA FROM dbo.SalesOrderApproval SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORS FROM dbo.SalesOrderReservedStock SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOPM FROM dbo.SOPartsMapping SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORP FROM dbo.SalesOrderReserveParts SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOURP FROM dbo.SalesOrderUnReservedStock SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOP FROM dbo.SalesOrderPart SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;
                END

              END
              ELSE
              BEGIN
				--PRINT 'Else 1'
                --CASE 2 SAME AS PART
                INSERT INTO #ROStockLineSamePart (ItemMasterId, ConditionId, StockLineId, OldStockLineId, SalesOrderId, RepairOrderId, MasterCompanyId, RepairOrderNumber)
                  SELECT DISTINCT TOP 1
                    RP.ItemMasterId,
                    RP.ConditionId,
                    SL.StockLineId,
                    RP.StockLineId,
                    RP.SalesOrderId,
                    RP.RepairOrderId,
                    RP.MasterCompanyId,
                    RO.RepairOrderNumber
                  FROM dbo.RepairOrderPart RP WITH (NOLOCK)
                  JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
                  JOIN dbo.ItemMaster IM ON RP.ItemMasterId = IM.ItemMasterId AND RP.ConditionId = SL.ConditionId
                  JOIN dbo.RepairOrder RO ON RO.RepairOrderId = RP.RepairOrderId
                  WHERE SL.StockLineId = @StocklineId
				
                IF ((SELECT COUNT(1) FROM #ROStockLineSamePart WITH (NOLOCK) WHERE ISNULL(SalesOrderId, 0) > 0) > 0)
                BEGIN
                  SELECT @ExSalesOrderPartId = SOP.SalesOrderPartId FROM dbo.SalesOrderPart SOP WITH (NOLOCK)
                  JOIN dbo.RepairOrderPart RP WITH (NOLOCK) ON RP.StockLineId = SOP.StocklineId
                  WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId 
				  AND SOP.SalesOrderId = @SalesOrderId

                  INSERT INTO dbo.SalesOrderPart (SalesOrderId, ItemMasterId, StockLineId, FxRate, Qty, UnitSalePrice, MarkUpPercentage, SalesBeforeDiscount, Discount,
                  DiscountAmount, NetSales, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsDeleted, UnitCost,
                  MethodType, SalesPriceExtended, MarkupExtended, SalesDiscountExtended, NetSalePriceExtended, UnitCostExtended,
                  MarginAmount, MarginAmountExtended, MarginPercentage, ConditionId, SalesOrderQuoteId, SalesOrderQuotePartId,
                  IsActive, CustomerRequestDate, PromisedDate, EstimatedShipDate, PriorityId, StatusId, CustomerReference, QtyRequested,
                  Notes, CurrencyId, MarkupPerUnit, GrossSalePricePerUnit, GrossSalePrice, TaxType, TaxPercentage, TaxAmount,
                  AltOrEqType, ControlNumber, IdNumber, ItemNo)
                    SELECT DISTINCT
                      ROS.SalesOrderId,
                      ROS.ItemMasterId,
                      @StockLineId,
                      1.0000,
                      CASE
                        WHEN SL.QuantityAvailable > @Quantity THEN @Quantity
                        ELSE SL.QuantityAvailable
                      END,
                      SOP.UnitSalePrice,
                      SOP.MarkUpPercentage,
                      SOP.SalesBeforeDiscount,
                      SOP.Discount,
                      SOP.DiscountAmount,
                      SOP.NetSales,
                      SOP.MasterCompanyId,
                      SOP.CreatedBy,
                      GETDATE(),
                      SOP.UpdatedBy,
                      GETDATE(),
                      0,
                      ISNULL(SL.UnitCost, 0),
                      SOP.MethodType,
                      SOP.SalesPriceExtended,
                      SOP.MarkupExtended,
                      SOP.SalesDiscountExtended,
                      SOP.NetSalePriceExtended,
                      -- Update based on Unit Cost
                      SOP.UnitCostExtended,
                      SOP.MarginAmount,
                      SOP.MarginAmountExtended,
                      SOP.MarginPercentage,
                      ROS.ConditionId,
                      NULL,
                      NULL,
                      1,
                      SOP.CustomerRequestDate,
                      SOP.PromisedDate,
                      SOP.EstimatedShipDate,
                      SOP.PriorityId,
                      SOP.StatusId,
                      'Created from RO',
                      SOP.QtyRequested,
                      NULL,
                      SOP.CurrencyId,
                      SOP.MarkupPerUnit,
                      SOP.GrossSalePricePerUnit,
                      SOP.GrossSalePrice,
                      SOP.TaxType,
                      SOP.TaxPercentage,
                      SOP.TaxAmount,
                      SOP.AltOrEqType,
                      SL.ControlNumber,
                      SL.IdNumber,
                      1
                    FROM #ROStockLineSamePart ROS WITH (NOLOCK)
                    JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
                    JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId
                    JOIN dbo.SalesOrderPart SOP ON SOP.StockLineId = ROS.OldStockLineId
                        AND SOP.SalesOrderId = @SalesOrderId
                    WHERE SOP.SalesOrderId = @SalesOrderId AND SL.StockLineId = @StocklineId
                    AND SL.StockLineId NOT IN (SELECT StockLineId FROM dbo.SalesOrderPart WITH (NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId);

                  SELECT @SalesOrderPartId = SCOPE_IDENTITY()

				  INSERT INTO #SalesOrderPartDetails (SalesOrderPartId) SELECT @SalesOrderPartId

				  INSERT INTO [dbo].[SalesOrderReserveParts]
								   ([SalesOrderId]
								   ,[StockLineId]
								   ,[ItemMasterId]
								   ,[PartStatusId]
								   ,[IsEquPart]
								   ,[EquPartMasterPartId]
								   ,[IsAltPart]
								   ,[AltPartMasterPartId]
								   ,[QtyToReserve]
								   ,[QtyToIssued]
								   ,[ReservedById]
								   ,[ReservedDate]
								   ,[IssuedById]
								   ,[IssuedDate]
								   ,[CreatedBy]
								   ,[CreatedDate]
								   ,[UpdatedBy]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted]
								   ,[SalesOrderPartId]
								   ,[TotalReserved]
								   ,[TotalIssued]
								   ,[MasterCompanyId])
							 SELECT SOP.SalesOrderId, SOP.StockLineId, SOP.ItemMasterId, 1,
							 0, NULL, 0, NULL, SOP.Qty, 0, 
							 (SELECT TOP 1 EmployeeId FROM DBO.Employee Where MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
							 GETDATE(), NULL, GETDATE(), SOP.CreatedBy, GETDATE(),SOP.UpdatedBy, GETDATE(), 1, 0, @SalesOrderPartId, 
							 SOP.Qty, 0, @MasterCompanyId
							 FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId

					INSERT INTO [dbo].[SalesOrderReservedStock]
								   ([SalesOrderId]
								   ,[SalesOrderPartId]
								   ,[StockLIneId]
								   ,[ConditionId]
								   ,[ItemMasterId]
								   ,[Quantity]
								   ,[AltPartMasterPartId]
								   ,[EquPartMasterPartId]
								   ,[IsAltPart]
								   ,[IsEquPart]
								   ,[ReservedById]
								   ,[ReservedDate]
								   ,[MasterCompanyId]
								   ,[CreatedBy]
								   ,[UpdatedBy]
								   ,[CreatedDate]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted])
							SELECT SOP.SalesOrderId, @SalesOrderPartId, SOP.StockLineId, SOP.ConditionId,
							SOP.ItemMasterId, SOP.Qty, NULL, NULL, 0, 0,
							(SELECT TOP 1 EmployeeId FROM DBO.Employee Where MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
							GETDATE(), @MasterCompanyId, SOP.CreatedBy, SOP.UpdatedBy, GETDATE(), GETDATE(), 1, 0
							FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId

					INSERT INTO [dbo].[SalesOrderStockLine]
									   ([SalesOrderId]
									   ,[SalesOrderPartId]
									   ,[StockLIneId]
									   ,[ItemMasterId]
									   ,[ConditionId]
									   ,[Quantity]
									   ,[QtyReserved]
									   ,[QtyIssued]
									   ,[AltPartMasterPartId]
									   ,[EquPartMasterPartId]
									   ,[IsAltPart]
									   ,[IsEquPart]
									   ,[UnitCost]
									   ,[ExtendedCost]
									   ,[UnitPrice]
									   ,[ExtendedPrice]
									   ,[MasterCompanyId]
									   ,[CreatedBy]
									   ,[UpdatedBy]
									   ,[CreatedDate]
									   ,[UpdatedDate]
									   ,[IsActive]
									   ,[IsDeleted])
									SELECT SOP.SalesOrderId, @SalesOrderPartId, SOP.StockLineId, SOP.ItemMasterId, SOP.ConditionId,
									SOP.Qty, SOP.Qty, 0, NULL, NULL, 0, 0, 0.00, 0.00, 0.00, 0.00, @MasterCompanyId,
									SOP.CreatedBy, SOP.UpdatedBy, GETDATE(), GETDATE(), 1, 0
									FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId
					SELECT @StlQuantity = SOP.Qty FROM dbo.SalesOrderPart SOP Where SOP.SalesOrderPartId = @SalesOrderPartId
					UPDATE Stockline SET QuantityAvailable = QuantityAvailable - @StlQuantity, QuantityReserved = @StlQuantity WHERE StockLineId = @StocklineId

                  UPDATE dbo.SalesOrderPart SET UnitCostExtended = ISNULL(UnitCost, 0) * ISNULL(Qty, 0), SalesPriceExtended = ISNULL(UnitSalePrice, 0) * ISNULL(Qty, 0),
				  SalesBeforeDiscount = ISNULL(UnitSalePrice, 0) * ISNULL(Qty, 0)
                  WHERE SalesOrderPartId = @SalesOrderPartId

				  SELECT @QtyFulfilled SET @QtyFulfilled = @QtyFulfilled - (SELECT SUM(ISNULL(Qty,0)) FROM dbo.SalesOrderPart WITH (NOLOCK) 
				  WHERE SalesOrderPartId IN (SELECT SalesOrderPartId FROM #SalesOrderPartDetails))

                  IF (@QtyFulfilled <= 0)
                  BEGIN
                    DELETE SOSTL FROM dbo.SalesOrderStockLine SOSTL WHERE SOSTL.SalesOrderPartId = @ExSalesOrderPartId;
                    DELETE SOA FROM dbo.SalesOrderApproval SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
                    DELETE SORS FROM dbo.SalesOrderReservedStock SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
                    DELETE SOPM FROM dbo.SOPartsMapping SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
                    DELETE SORP FROM dbo.SalesOrderReserveParts SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
                    DELETE SOURP FROM dbo.SalesOrderUnReservedStock SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
                    DELETE SOP FROM dbo.SalesOrderPart SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;
                  END
                END
              END
			  END

			  SELECT @LoopID SET @LoopID = @LoopID - 1;
          END

          SET @MasterLoopID = @MasterLoopID - 1;
        END
        IF OBJECT_ID(N'tempdb..#ROStockLineSamePart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineSamePart
        END

        IF OBJECT_ID(N'tempdb..#ROStockLineRevisedPart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineRevisedPart
        END

        IF OBJECT_ID(N'tempdb..#StockLine') IS NOT NULL
        BEGIN
          DROP TABLE #StockLine
        END

        IF OBJECT_ID(N'tempdb..#StockLineData') IS NOT NULL
        BEGIN
          DROP TABLE #StockLineData
        END

		IF OBJECT_ID(N'tempdb..#SalesOrderPartDetails') IS NOT NULL
        BEGIN
          DROP TABLE #SalesOrderPartDetails
        END
      END

    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_CreateSOStocklineFromRO'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@RepairOrderId, '') + ''
		,@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END