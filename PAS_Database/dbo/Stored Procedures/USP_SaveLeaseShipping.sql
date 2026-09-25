
/***************************************************************
 ** File:  [USP_SaveLeaseShipping]
 ** Author:   Moin Bloch
 ** Description: Save (insert/update) Lease Shipping header, customs info and item lines
 ** Date:  25-Sep-2026
 ** Change History
 *******************************************************************************************
 ** PR   Date				Author  				Change Description
 ** --   --------			-------				--------------------------------
    1    24-Sep-2026		Moin Bloch			Created
    2    25-Sep-2026		Moin Bloch			Widened CustomsValue/NetMass/VATValue to DECIMAL(20,6) to match LeaseCustomsInfo
    3    25-Sep-2026		Moin Bloch			Added IsBypassShipping passthrough for FedEx/UPS carrier integration

*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveLeaseShipping]
	@LeaseShippingTable dbo.LeaseShippingType READONLY,
	@LeaseCustomsInfoList dbo.LeaseCustomsInfoType READONLY,
	@LeaseShippingId BIGINT = NULL,
	@MasterCompanyId INT = NULL,
	@CreatedBy VARCHAR(256) = NULL,
	@UpdatedBy VARCHAR(256) = NULL,
	@Items dbo.LeaseShippingItemsType READONLY
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @CustomerId BIGINT;
		DECLARE @LeaseHeaderId BIGINT;
		SELECT TOP 1 @LeaseHeaderId = [LeaseHeaderId] FROM @LeaseShippingTable;
		SELECT @CustomerId = [CustomerId] FROM [dbo].[LeaseHeader] WITH (NOLOCK) WHERE [LeaseHeaderId] = @LeaseHeaderId;

		DECLARE @OpenShippingStatusId BIGINT = (SELECT TOP 1 [ShippingStatusId] FROM [dbo].[ShippingStatus] WITH (NOLOCK) WHERE [Status] = 'OPEN');
		DECLARE @ShippedShippingStatusId BIGINT = (SELECT TOP 1 [ShippingStatusId] FROM [dbo].[ShippingStatus] WITH (NOLOCK) WHERE [Status] = 'SHIPPED');
		DECLARE @LeaseShippingNumber VARCHAR(50);

		-- Mirrors USP_SaveWorkOrderShipping: entering a Tracking Ref/Airway Bill while status is
		-- still Open auto-promotes the shipment to Shipped, same as WO does on save.
		DECLARE @IncomingAirwayBill VARCHAR(50), @IncomingStatusId BIGINT;
		SELECT TOP 1 @IncomingAirwayBill = [AirwayBill], @IncomingStatusId = ISNULL([LeaseShippingStatusId], @OpenShippingStatusId) FROM @LeaseShippingTable;
		SET @IncomingStatusId = CASE WHEN @IncomingStatusId = @OpenShippingStatusId
										  AND @IncomingAirwayBill IS NOT NULL AND LTRIM(RTRIM(@IncomingAirwayBill)) <> ''
									 THEN ISNULL(@ShippedShippingStatusId, @IncomingStatusId)
									 ELSE @IncomingStatusId END;
		DECLARE @IsNew BIT = CASE WHEN ISNULL(@LeaseShippingId, 0) <= 0 THEN 1 ELSE 0 END;
		DECLARE @InsertedLeaseShipping TABLE ([LeaseShippingId] BIGINT);

		IF @IsNew = 1
		BEGIN
			DECLARE @CodeTypeId BIGINT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'LeaseShipping');
			DECLARE @CurrentNo BIGINT, @CodePrefix VARCHAR(10), @CodeSuffix VARCHAR(10);
			DECLARE @Generated TABLE (CurrentNummber BIGINT, CodePrefix VARCHAR(10), CodeSufix VARCHAR(10));

			UPDATE [dbo].[CodePrefixes]
			SET [CurrentNummber] = CASE WHEN ISNULL([CurrentNummber], 0) > 0
										THEN ISNULL([CurrentNummber], 0) + 1
										ELSE ISNULL([StartsFrom], 0) + 1
								   END
			OUTPUT inserted.[CurrentNummber], inserted.[CodePrefix], inserted.[CodeSufix] INTO @Generated
			WHERE [CodeTypeId]      = @CodeTypeId
			  AND [MasterCompanyId] = @MasterCompanyId
			  AND [IsActive]        = 1
			  AND [IsDeleted]       = 0;

			IF NOT EXISTS (SELECT 1 FROM @Generated)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT CAST(0 AS BIT) AS [Status], 'Code Prefix is not configured for Lease Shipping.' AS [Message],
				       CAST(0 AS BIGINT) AS LeaseShippingId, CAST('' AS VARCHAR(50)) AS LeaseShippingNumber;
				RETURN;
			END

			SELECT TOP 1 @CurrentNo = [CurrentNummber], @CodePrefix = ISNULL([CodePrefix], ''), @CodeSuffix = ISNULL([CodeSufix], '') FROM @Generated;
			SELECT @LeaseShippingNumber = CAST(gen.StocklineNumber AS VARCHAR(50)) FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNo, @CodePrefix, @CodeSuffix) gen;

			INSERT INTO [dbo].[LeaseShipping]
				([LeaseHeaderId], [LeaseShippingNum], [LeaseShippingStatusId], [OpenDate], [CustomerId], [ShipViaId], [ShipDate],
				 [AirwayBill], [HouseAirwayBill], [TrackingNum], [Weight],
				 [SoldToName], [SoldToAddress1], [SoldToAddress2], [SoldToCity], [SoldToState], [SoldToZip], [SoldToCountryId], [SoldToCountryName], [SoldAttention],
				 [SoldToSiteId], [SoldToSiteName],
				 [ShipToName], [ShipToSiteName], [ShipToSiteId], [ShipToAddress1], [ShipToAddress2], [ShipToCity], [ShipToState], [ShipToZip], [ShipToCountryId], [ShipToCountryName], [ShipAttention],
				 [ShipToCustomerId],
				 [OriginName], [OriginAddress1], [OriginAddress2], [OriginCity], [OriginState], [OriginZip], [OriginCountryId], [OriginCountryName], [OriginSiteId],
				 [IsSameForShipTo], [NoOfContainer], [Notes],
				 [Shipment], [IsCustomerShipping], [ShippingAccountInfo], [IsManualShipping], [isIgnoreAWB],
				 [ShipWeightUnit], [ShipSizeLength], [ShipSizeWidth], [ShipSizeHeight], [ShipSizeUnitOfMeasureId],
				 [NoOfItems], [ManufactureCountryId], [QtyUOM], [UnitPrice], [UnitPriceCurrencyId],
				 [isBypassShipping],
				 [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			OUTPUT INSERTED.[LeaseShippingId] INTO @InsertedLeaseShipping([LeaseShippingId])
			SELECT LST.[LeaseHeaderId], @LeaseShippingNumber, @IncomingStatusId, ISNULL(LST.[OpenDate], LST.[ShipDate]), ISNULL(@CustomerId, 0), LST.[ShipViaId], LST.[ShipDate],
			       LST.[AirwayBill], LST.[HouseAirwayBill], LST.[TrackingNum], LST.[Weight],
			       LST.[SoldToName], LST.[SoldToAddress1], LST.[SoldToAddress2], LST.[SoldToCity], LST.[SoldToState], LST.[SoldToZip], LST.[SoldToCountryId], ISNULL(LST.[SoldToCountryName], ''), LST.[SoldAttention],
			       LST.[SoldToSiteId], ISNULL(LST.[SoldToSiteName], ''),
			       LST.[ShipToName], ISNULL(LST.[ShipToSiteName], ''), LST.[ShipToSiteId], LST.[ShipToAddress1], LST.[ShipToAddress2], LST.[ShipToCity], LST.[ShipToState], LST.[ShipToZip], LST.[ShipToCountryId], ISNULL(LST.[ShipToCountryName], ''), LST.[ShipAttention],
			       LST.[ShipToCustomerId],
			       LST.[OriginName], LST.[OriginAddress1], LST.[OriginAddress2], LST.[OriginCity], LST.[OriginState], LST.[OriginZip], LST.[OriginCountryId], ISNULL(LST.[OriginCountryName], ''), LST.[OriginSiteId],
			       LST.[IsSameForShipTo], LST.[NoOfContainer], LST.[Notes],
			       LST.[Shipment], LST.[IsCustomerShipping], LST.[ShippingAccountInfo], LST.[IsManualShipping], LST.[isIgnoreAWB],
			       LST.[ShipWeightUnit], LST.[ShipSizeLength], LST.[ShipSizeWidth], LST.[ShipSizeHeight], LST.[ShipSizeUnitOfMeasureId],
			       LST.[NoOfItems], LST.[ManufactureCountryId], LST.[QtyUOM], LST.[UnitPrice], LST.[UnitPriceCurrencyId],
			       ISNULL(LST.[IsBypassShipping], 0),
			       LST.[MasterCompanyId], LST.[CreatedBy], LST.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0
			FROM @LeaseShippingTable LST;

			SELECT TOP 1 @LeaseShippingId = [LeaseShippingId] FROM @InsertedLeaseShipping;
		END
		ELSE
		BEGIN
			SELECT @LeaseShippingNumber = [LeaseShippingNum] FROM [dbo].[LeaseShipping] WITH (NOLOCK) WHERE [LeaseShippingId] = @LeaseShippingId;

			UPDATE LS
			SET LS.[LeaseShippingStatusId] = @IncomingStatusId,
				LS.[OpenDate] = ISNULL(src.[OpenDate], LS.[OpenDate]),
				LS.[ShipViaId] = src.[ShipViaId], LS.[ShipDate] = src.[ShipDate],
				LS.[AirwayBill] = src.[AirwayBill], LS.[HouseAirwayBill] = src.[HouseAirwayBill], LS.[TrackingNum] = src.[TrackingNum], LS.[Weight] = src.[Weight],
				LS.[SoldToName] = src.[SoldToName], LS.[SoldToAddress1] = src.[SoldToAddress1], LS.[SoldToAddress2] = src.[SoldToAddress2],
				LS.[SoldToCity] = src.[SoldToCity], LS.[SoldToState] = src.[SoldToState], LS.[SoldToZip] = src.[SoldToZip], LS.[SoldToCountryId] = src.[SoldToCountryId], LS.[SoldToCountryName] = ISNULL(src.[SoldToCountryName], ''),
				LS.[SoldAttention] = src.[SoldAttention],
				LS.[SoldToSiteId] = src.[SoldToSiteId], LS.[SoldToSiteName] = ISNULL(src.[SoldToSiteName], ''),
				LS.[ShipToName] = src.[ShipToName], LS.[ShipToAddress1] = src.[ShipToAddress1], LS.[ShipToAddress2] = src.[ShipToAddress2],
				LS.[ShipToCity] = src.[ShipToCity], LS.[ShipToState] = src.[ShipToState], LS.[ShipToZip] = src.[ShipToZip], LS.[ShipToCountryId] = src.[ShipToCountryId], LS.[ShipToCountryName] = ISNULL(src.[ShipToCountryName], ''),
				LS.[ShipAttention] = src.[ShipAttention],
				LS.[ShipToSiteId] = src.[ShipToSiteId], LS.[ShipToSiteName] = ISNULL(src.[ShipToSiteName], ''), LS.[ShipToCustomerId] = src.[ShipToCustomerId],
				LS.[OriginName] = src.[OriginName], LS.[OriginAddress1] = src.[OriginAddress1], LS.[OriginAddress2] = src.[OriginAddress2],
				LS.[OriginCity] = src.[OriginCity], LS.[OriginState] = src.[OriginState], LS.[OriginZip] = src.[OriginZip], LS.[OriginCountryId] = src.[OriginCountryId], LS.[OriginCountryName] = ISNULL(src.[OriginCountryName], ''),
				LS.[OriginSiteId] = src.[OriginSiteId],
				LS.[IsSameForShipTo] = src.[IsSameForShipTo], LS.[NoOfContainer] = src.[NoOfContainer], LS.[Notes] = src.[Notes],
				LS.[Shipment] = src.[Shipment], LS.[IsCustomerShipping] = src.[IsCustomerShipping], LS.[ShippingAccountInfo] = src.[ShippingAccountInfo],
				LS.[IsManualShipping] = src.[IsManualShipping], LS.[isIgnoreAWB] = src.[isIgnoreAWB],
				LS.[ShipWeightUnit] = src.[ShipWeightUnit], LS.[ShipSizeLength] = src.[ShipSizeLength], LS.[ShipSizeWidth] = src.[ShipSizeWidth],
				LS.[ShipSizeHeight] = src.[ShipSizeHeight], LS.[ShipSizeUnitOfMeasureId] = src.[ShipSizeUnitOfMeasureId],
				LS.[NoOfItems] = src.[NoOfItems], LS.[ManufactureCountryId] = src.[ManufactureCountryId], LS.[QtyUOM] = src.[QtyUOM],
				LS.[UnitPrice] = src.[UnitPrice], LS.[UnitPriceCurrencyId] = src.[UnitPriceCurrencyId],
				LS.[isBypassShipping] = ISNULL(src.[IsBypassShipping], 0),
				LS.[UpdatedBy] = src.[UpdatedBy], LS.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[LeaseShipping] LS
			INNER JOIN @LeaseShippingTable src ON src.[LeaseShippingId] = @LeaseShippingId
			WHERE LS.[LeaseShippingId] = @LeaseShippingId;
		END

		IF EXISTS (SELECT 1 FROM [dbo].[LeaseCustomsInfo] WHERE [LeaseShippingId] = @LeaseShippingId)
		BEGIN
			UPDATE LCI
			SET LCI.[EntryType] = src.[EntryType], LCI.[EntryNumber] = src.[EntryNumber], LCI.[CommodityCode] = src.[CommodityCode],
				LCI.[EPU] = src.[EPU], LCI.[UCR] = src.[UCR], LCI.[MasterUCR] = src.[MasterUCR], LCI.[MovementRefNo] = src.[MovementRefNo],
				LCI.[CustomsValue] = src.[CustomsValue], LCI.[CustomCurrencyId] = src.[CustomCurrencyId], LCI.[NetMass] = src.[NetMass], LCI.[VATValue] = src.[VATValue],
				LCI.[UpdatedBy] = src.[UpdatedBy], LCI.[UpdatedDate] = GETUTCDATE()
			FROM [dbo].[LeaseCustomsInfo] LCI
			CROSS JOIN @LeaseCustomsInfoList src
			WHERE LCI.[LeaseShippingId] = @LeaseShippingId;
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[LeaseCustomsInfo]
				([LeaseShippingId], [EntryType], [EntryNumber], [CommodityCode], [EPU], [UCR], [MasterUCR], [MovementRefNo],
				 [CustomsValue], [CustomCurrencyId], [NetMass], [VATValue],
				 [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT @LeaseShippingId, src.[EntryType], src.[EntryNumber], src.[CommodityCode], src.[EPU], src.[UCR], src.[MasterUCR], src.[MovementRefNo],
			       src.[CustomsValue], src.[CustomCurrencyId], src.[NetMass], src.[VATValue],
			       src.[MasterCompanyId], src.[CreatedBy], src.[UpdatedBy], GETUTCDATE(), GETUTCDATE(), 1, 0
			FROM @LeaseCustomsInfoList src;
		END

		-- Items: validate each against remaining Qty Picked for its Pick Ticket line, then upsert.
		DECLARE @LeasePickTicketId BIGINT, @LeaseShippingItemId BIGINT, @QtyShipped DECIMAL(18,6);
		DECLARE @ItemLeaseStocklineId BIGINT, @ItemStockLineId BIGINT, @ItemLeaseHeaderId BIGINT, @QtyPicked DECIMAL(18,6), @AlreadyShipped DECIMAL(18,6);

		DECLARE item_cursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT [LeaseShippingItemId], [LeasePickTicketId], [QtyShipped] FROM @Items;
		OPEN item_cursor
		FETCH NEXT FROM item_cursor INTO @LeaseShippingItemId, @LeasePickTicketId, @QtyShipped

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @ItemLeaseStocklineId = [LeaseStocklineId], @ItemStockLineId = [StockLineId],
			       @ItemLeaseHeaderId = [LeaseHeaderId], @QtyPicked = ISNULL([QtyPicked], 0)
			FROM [dbo].[LeasePickTicket] WITH (NOLOCK)
			WHERE [LeasePickTicketId] = @LeasePickTicketId;

			IF @ItemLeaseStocklineId IS NULL
			BEGIN
				ROLLBACK TRANSACTION;
				CLOSE item_cursor; DEALLOCATE item_cursor;
				SELECT CAST(0 AS BIT) AS [Status], 'Lease Pick Ticket line not found.' AS [Message],
				       CAST(0 AS BIGINT) AS LeaseShippingId, CAST('' AS VARCHAR(50)) AS LeaseShippingNumber;
				RETURN;
			END

			SELECT @AlreadyShipped = ISNULL(SUM(LSI.[QtyShipped]), 0)
			FROM [dbo].[LeaseShippingItem] LSI WITH (NOLOCK)
			WHERE LSI.[LeasePickTicketId] = @LeasePickTicketId
			  AND LSI.[IsDeleted] = 0
			  AND LSI.[LeaseShippingItemId] <> ISNULL(@LeaseShippingItemId, 0);

			IF (@QtyShipped <= 0 OR (@AlreadyShipped + @QtyShipped) > @QtyPicked)
			BEGIN
				ROLLBACK TRANSACTION;
				CLOSE item_cursor; DEALLOCATE item_cursor;
				SELECT CAST(0 AS BIT) AS [Status], 'Qty to Ship must be greater than zero and cannot exceed the Qty Remaining.' AS [Message],
				       CAST(0 AS BIGINT) AS LeaseShippingId, CAST('' AS VARCHAR(50)) AS LeaseShippingNumber;
				RETURN;
			END

			IF ISNULL(@LeaseShippingItemId, 0) > 0
			BEGIN
				UPDATE [dbo].[LeaseShippingItem]
				SET [QtyShipped] = @QtyShipped, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
				WHERE [LeaseShippingItemId] = @LeaseShippingItemId;
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[LeaseShippingItem]
					([LeaseShippingId], [LeaseHeaderId], [LeaseStocklineId], [StocklineId], [LeasePickTicketId], [QtyShipped],
					 [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES
					(@LeaseShippingId, @ItemLeaseHeaderId, @ItemLeaseStocklineId, @ItemStockLineId, @LeasePickTicketId, @QtyShipped,
					 @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
			END

			FETCH NEXT FROM item_cursor INTO @LeaseShippingItemId, @LeasePickTicketId, @QtyShipped
		END

		CLOSE item_cursor
		DEALLOCATE item_cursor

		COMMIT TRANSACTION

		SELECT CAST(1 AS BIT) AS [Status], 'Success' AS [Message], @LeaseShippingId AS LeaseShippingId, @LeaseShippingNumber AS LeaseShippingNumber;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		IF CURSOR_STATUS('local', 'item_cursor') >= -1
		BEGIN
			CLOSE item_cursor;
			DEALLOCATE item_cursor;
		END

		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_SaveLeaseShipping]',
			@ProcedureParameters VARCHAR(3000) = '@LeaseShippingId = ''' + CAST(ISNULL(@LeaseShippingId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END