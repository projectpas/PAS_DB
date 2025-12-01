/*************************************************************               
 ** File:  [USP_SaveWorkOrderShipping]               
 ** Author:  Priyansh Patel
 ** Description: This stored procedure is used to Insert WorkOrder Shipping records.    
 ** Purpose:             
 ** Date:   03-Nov-2025          
              
             
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    03-Nov-2025   Priyansh Patel		Created  
	2    25-Nov-2025   Moin Bloch		    Format SP & Fix ShippingStatus
************************************************************************/  

CREATE   PROCEDURE [dbo].[USP_SaveWorkOrderShipping]
	@WorkOrderShippingTable WorkOrderShippingType READONLY,
	@WorkOrderCustomsInfoList WorkOrderCustomsInfoType READONLY,
    @WorkOrderShippingId BIGINT = NULL,
    @WorkOrderPartNoId BIGINT = NULL,
    @WOShippingStatusId BIGINT = NULL,
    @AirwayBill NVARCHAR(100) = NULL,
    @IsCustomerShipping BIT = NULL,
    @CustomerDomensticShippingShipViaId BIGINT = NULL,
    @ShipviaId BIGINT = NULL,
    @CreatedBy NVARCHAR(100) = NULL,
    @UpdatedBy NVARCHAR(100) = NULL,
    @MasterCompanyId BIGINT = NULL,
	@NPMStockQTY INT  = NULL,
	@ModuleId BIGINT = NULL,
	@SubModuleId BIGINT = NULL,
	@ActionId INT = NULL,
	@WorkOrderId  BIGINT  = NULL,
	@WoPartNoId BIGINT  = NULL,
    @ShippingName VARCHAR(100)  = NULL,
    @ShipToCustomerId BIGINT = NULL,
	@Isadd [BIT]= NULL,
	@DistributionCode NVARCHAR(50) = NULL,
	@ValidBatchDetails BIT = 1,
	@HistorySubModuleId INT = NULL,
	@HistoryStatusCode NVARCHAR(50),
    @ShippingItems dbo.WorkOrderShippingItemListType READONLY,
    @WorkOrderShippingItems dbo.WorkOrderShippingItemsType READONLY
AS
BEGIN
	SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @InsertedWorkOrderShipping TABLE ([WorkOrderShippingId] BIGINT);
		DECLARE @CurrentUtcDate DATETIME = GETUTCDATE();
		DECLARE @OpenShippingStatus INT = 1
		DECLARE @ShippedShippingStatus INT = 2
				
		DECLARE	@ItemMasterId BIGINT = NULL, @MPNPartNumber NVARCHAR(100) = NULL, @ShippingViaName NVARCHAR(100) = NULL,
				@TemplatedBody NVARCHAR(MAX) = NULL,@ShipToCustomer NVARCHAR(200) = NULL, @WorkOrderTypeId BIGINT = NULL;

		DECLARE @WorkOrderShippingItemList [dbo].[WorkOrderShippingItemType];

		DECLARE @CreatedDate DATETIME2(7) = GETUTCDATE();
		DECLARE @UpdatedDate DATETIME2(7) = GETUTCDATE();

		SET @WOShippingStatusId = CASE WHEN @WOShippingStatusId = @OpenShippingStatus AND @AirwayBill IS NOT NULL AND LTRIM(RTRIM(@AirwayBill)) <> '' THEN @ShippedShippingStatus ELSE @WOShippingStatusId END;
		
		IF (ISNULL(@IsCustomerShipping, 0) = 0)
			SET @CustomerDomensticShippingShipViaId = NULL;

		IF (ISNULL(@WorkOrderShippingId, 0) > 0)
		BEGIN
			UPDATE WOS 
			   SET WOS.[WorkOrderId] = src.[WorkOrderId], 
				   WOS.[WorkOrderPartNoId] = src.[WorkOrderPartNoId], 
				   WOS.[WorkflowWorkOrderId] = src.[WorkflowWorkOrderId], 
				   WOS.[WOShippingNum] = src.[WOShippingNum], 
				   WOS.[WOShippingStatusId] = @WOShippingStatusId, 
				   WOS.[OpenDate] = src.[OpenDate], 
				   WOS.[CustomerId] = src.[CustomerId], 
				   WOS.[ShipViaId] = src.[ShipViaId], 
				   WOS.[ShipDate] = src.[ShipDate], 
				   WOS.[AirwayBill] = src.[AirwayBill], 
				   WOS.[HouseAirwayBill] = src.[HouseAirwayBill], 
				   WOS.[TrackingNum] = src.[TrackingNum], 
				   WOS.[Weight] = src.[Weight], 
				   WOS.[SoldToName] = src.[SoldToName], 
				   WOS.[SoldToAddress1] = src.[SoldToAddress1], 
				   WOS.[SoldToAddress2] = src.[SoldToAddress2], 
				   WOS.[SoldToCity] = src.[SoldToCity], 
				   WOS.[SoldToState] = src.[SoldToState], 
				   WOS.[SoldToZip] = src.[SoldToZip], 
				   WOS.[SoldToCountryId] = src.[SoldToCountryId], 
				   WOS.[ShipToName] = src.[ShipToName], 
				   WOS.[ShipToSiteName] = src.[ShipToSiteName], 
				   WOS.[ShipToSiteId] = src.[ShipToSiteId], 
				   WOS.[ShipToAddress1] = src.[ShipToAddress1], 
				   WOS.[ShipToAddress2] = src.[ShipToAddress2], 
				   WOS.[ShipToCity] = src.[ShipToCity], 
				   WOS.[ShipToState] = src.[ShipToState], 
				   WOS.[ShipToZip] = src.[ShipToZip], 
				   WOS.[ShipToCountryId] = src.[ShipToCountryId], 
				   WOS.[OriginName] = src.[OriginName], 
				   WOS.[OriginAddress1] = src.[OriginAddress1], 
				   WOS.[OriginAddress2] = src.[OriginAddress2], 
				   WOS.[OriginCity] = src.[OriginCity], 
				   WOS.[OriginState] = src.[OriginState],
				   WOS.[OriginZip] = src.[OriginZip], 
				   WOS.[OriginCountryId] = src.[OriginCountryId], 
				   WOS.[MasterCompanyId] = src.[MasterCompanyId], 
				   WOS.[UpdatedBy] = src.[UpdatedBy], 
				   WOS.[UpdatedDate] = @UpdatedDate,			  
				   WOS.[Shipment] = src.[Shipment], 
				   WOS.[SoldToSiteId] = src.[SoldToSiteId], 
				   WOS.[SoldToSiteName] = src.[SoldToSiteName], 
				   WOS.[SoldToCountryName] = src.[SoldToCountryName], 
				   WOS.[ShipToCustomerId] = src.[ShipToCustomerId], 
				   WOS.[ShipToCountryName] = src.[ShipToCountryName], 
				   WOS.[OriginCountryName] = src.[OriginCountryName], 
				   WOS.[OriginSiteId] = src.[OriginSiteId],
				   WOS.[IsSameForShipTo] = src.[IsSameForShipTo], 
				   WOS.[ShipSizeLength] = src.[ShipSizeLength], 
				   WOS.[ShipSizeWidth] = src.[ShipSizeWidth], 
				   WOS.[ShipSizeHeight] = src.[ShipSizeHeight], 
				   WOS.[ShipWeightUnit] = src.[ShipWeightUnit], 
				   WOS.[ShipSizeUnitOfMeasureId] = src.[ShipSizeUnitOfMeasureId], 
				   WOS.[PickTicketId] = src.[PickTicketId], 
				   WOS.[NoOfContainer] = src.[NoOfContainer], 
				   WOS.[ShipAttention] = src.[shipAttention], 
				   WOS.[SoldAttention] = src.[soldAttention], 
				   WOS.[CustomerDomensticShippingShipViaId] = src.[CustomerDomensticShippingShipViaId], 
				   WOS.[ShippingAccountInfo] = src.[ShippingAccountInfo], 
				   WOS.[NoOfItems] = src.[NoOfItems], 
				   WOS.[IsCustomerShipping] = src.[IsCustomerShipping], 
				   WOS.[IsManualShipping] = src.[IsManualShipping], 
				   WOS.[ManufactureCountryId] = src.[ManufactureCountryId], 
				   WOS.[QtyUOM] = src.[QtyUOM], 
				   WOS.[UnitPrice] = src.[UnitPrice], 
				   WOS.[UnitPriceCurrencyId] = src.[UnitPriceCurrencyId], 
				   WOS.[Notes] = src.[Notes], 
				   WOS.[isIgnoreAWB] = src.[isIgnoreAWB], 
				   WOS.[isBypassShipping] = src.[isBypassShipping] 
				--OUTPUT INSERTED.WorkOrderShippingId INTO @UpdatedIds 
				FROM [dbo].[WorkOrderShipping] WOS
				INNER JOIN @WorkOrderShippingTable src ON WOS.[WorkOrderShippingId] = src.[WorkOrderShippingId]
				INNER JOIN [dbo].[MasterCompany] AS MC WITH (NOLOCK) ON MC.[MasterCompanyId] = src.[MasterCompanyId]
				WHERE WOS.[WorkOrderShippingId] = @WorkOrderShippingId AND src.[MasterCompanyId] = @MasterCompanyId;

			--  Update Packaging Slip items 
			UPDATE psi
			 SET psi.[PDFPath] = NULL
			FROM [dbo].[WorkOrderPackaginSlipItems] psi 
			INNER JOIN @ShippingItems s ON psi.[PackagingSlipId] = s.[PackagingSlipId]
			WHERE s.[PackagingSlipId] IS NOT NULL AND s.[PackagingSlipId] <> 0	AND PSI.[MasterCompanyId] = @MasterCompanyId;

			-- Update Shipping items (PDFPath = NULL)
			UPDATE wsi
			 SET wsi.[PDFPath] = NULL
			FROM [dbo].[WorkOrderShippingItem] wsi
			INNER JOIN @ShippingItems s ON wsi.[WorkOrderShippingId] = s.[WorkOrderShippingId]	AND wsi.[WorkOrderPartNumId] = s.[WorkOrderPartId]
			WHERE s.[WorkOrderShippingId] IS NOT NULL AND s.[WorkOrderShippingId] <> 0 AND WSI.[MasterCompanyId] = @MasterCompanyId;

			INSERT INTO @WorkOrderShippingItemList([WorkOrderShippingId],[WorkOrderPartNumId],[QtyShipped],[WOPickTicketId],[CreatedBy],[UpdatedBy],[MasterCompanyId])
			SELECT @WorkOrderShippingId,SI.[workOrderPartId],SI.[currQtyToShip],SI.[WOPickTicketId],@CreatedBy,@UpdatedBy,@MasterCompanyId FROM @ShippingItems SI
			--WHERE ISNULL(SI.currQtyToShip, 0) > 0;

			--  Update WorkOrderShippingItem records
			UPDATE WOI
				SET WOI.[WorkOrderShippingId] = @WorkOrderShippingId,  
					WOI.[WorkOrderPartNumId] = src.WorkOrderPartNumId,
					WOI.[QtyShipped] = src.QtyShipped,
					WOI.[WOPickTicketId] = src.WOPickTicketId,
					WOI.[UpdatedBy] = src.UpdatedBy,
					WOI.[UpdatedDate] = @UpdatedDate,
					WOI.[MasterCompanyId] = src.MasterCompanyId
				FROM [dbo].[WorkOrderShippingItem] WOI
				INNER JOIN @WorkOrderShippingItems src ON WOI.[WorkOrderShippingItemId] = src.[WorkOrderShippingItemId]
				INNER JOIN [dbo].[MasterCompany] MC WITH (NOLOCK) ON MC.[MasterCompanyId] = WOI.[MasterCompanyId]
				WHERE WOI.[MasterCompanyId] = @MasterCompanyId AND WOI.[WorkOrderShippingId] = @WorkOrderShippingId;
									
			--  Update WorkOrderCustomsInfo records
			UPDATE WCI
			SET WCI.[WorkOrderShippingId] = src.[WorkOrderShippingId],   
				WCI.[EntryType] = src.[EntryType],
				WCI.[EPU] = src.[EPU],
				WCI.[CustomsValue] = src.[CustomsValue],
				WCI.[NetMass] = src.[NetMass],
				WCI.[EntryStatus] = src.[EntryStatus],
				WCI.[EntryNumber] = src.[EntryNumber],
				WCI.[VATValue] = src.[VATValue],
				WCI.[UCR] = src.[UCR],
				WCI.[MasterUCR] = src.[MasterUCR],
				WCI.[MovementRefNo] = src.[MovementRefNo],
				WCI.[CommodityCode] = src.[CommodityCode],
				WCI.[CustomCurrencyId] = src.[CustomCurrencyId],
				WCI.[MasterCompanyId] = src.[MasterCompanyId],
				WCI.[UpdatedBy] = src.[UpdatedBy],
				WCI.[UpdatedDate] = @UpdatedDate				
			FROM [dbo].[WorkOrderCustomsInfo] WCI
			INNER JOIN @WorkOrderCustomsInfoList src ON WCI.WorkOrderShippingId = src.WorkOrderShippingId
			INNER JOIN [dbo].[MasterCompany] MC WITH (NOLOCK) ON MC.MasterCompanyId = WCI.MasterCompanyId
			WHERE WCI.MasterCompanyId = @MasterCompanyId  AND WCI.WorkOrderShippingId = @WorkOrderShippingId;

		END
		ELSE
		BEGIN		   
			-- Insert Work Order Shipping  // WorkOrderPartNoId  = null or not ??
			INSERT INTO [dbo].[WorkOrderShipping]
			(
				[WorkOrderId], 
				[WorkOrderPartNoId], 
				[WorkflowWorkOrderId],
				[WOShippingNum], 
				[WOShippingStatusId], 
				[OpenDate], 
				[CustomerId], 
				[ShipViaId], 
				[ShipDate], 
				[AirwayBill], 
				[HouseAirwayBill],
				[TrackingNum], 
				[Weight],
				[SoldToName], 
				[SoldToAddress1], 
				[SoldToAddress2], 
				[SoldToCity], 
				[SoldToState], 
				[SoldToZip], 
				[SoldToCountryId],
				[ShipToName], 
				[ShipToSiteName], 
				[ShipToSiteId],
				[ShipToAddress1], 
				[ShipToAddress2], 
				[ShipToCity], 
				[ShipToState], 
				[ShipToZip], 
				[ShipToCountryId], 
				[OriginName], 
				[OriginAddress1], 
				[OriginAddress2],
				[OriginCity], 
				[OriginState], 
				[OriginZip], 
				[OriginCountryId], 
				[MasterCompanyId],
				[CreatedBy], 
				[UpdatedBy], 
				[CreatedDate], 
				[UpdatedDate], 
				[IsActive], 
				[IsDeleted], 
				[Shipment],
				[SoldToSiteId], 
				[SoldToSiteName], 
				[SoldToCountryName], 
				[ShipToCustomerId], 
				[ShipToCountryName],
				[OriginCountryName], 
				[OriginSiteId], 
				[IsSameForShipTo], 
				[ShipSizeLength], 
				[ShipSizeWidth], 
				[ShipSizeHeight], 
				[ShipWeightUnit], 
				[ShipSizeUnitOfMeasureId], 
				[PickTicketId], 
				[NoOfContainer], 
				[ShipAttention], 
				[SoldAttention], 
				[CustomerDomensticShippingShipViaId], 
				[ShippingAccountInfo], 
				[NoOfItems], 
				[IsCustomerShipping], 
				[IsManualShipping], 
				[ManufactureCountryId], 
				[QtyUOM], 
				[UnitPrice], 
				[UnitPriceCurrencyId], 
				[Notes], 
				[isIgnoreAWB], 
				[isBypassShipping]
			)
			OUTPUT INSERTED.[WorkOrderShippingId] INTO @InsertedWorkOrderShipping([WorkOrderShippingId])
			SELECT WOS.[WorkOrderId],
			       NULL, 
				   WOS.[WorkflowWorkOrderId], 
				   WOS.[WOShippingNum], 
				   @WOShippingStatusId, 
				   WOS.[OpenDate], 
				   WOS.[CustomerId], 
				   WOS.[ShipViaId], 
				   WOS.[ShipDate], 
				   WOS.[AirwayBill], 
				   WOS.[HouseAirwayBill], 
				   WOS.[TrackingNum], 
				   WOS.[Weight], 
				   WOS.[SoldToName], 
				   WOS.[SoldToAddress1], 
				   WOS.[SoldToAddress2], 
				   WOS.[SoldToCity], 
				   WOS.[SoldToState], 
				   WOS.[SoldToZip], 
				   WOS.[SoldToCountryId],
				   WOS.[ShipToName], 
				   WOS.[ShipToSiteName], 
				   WOS.[ShipToSiteId], 
				   WOS.[ShipToAddress1], 
				   WOS.[ShipToAddress2], 
				   WOS.[ShipToCity], 
				   WOS.[ShipToState], 
				   WOS.[ShipToZip], 
				   WOS.[ShipToCountryId], 
				   WOS.[OriginName], 
				   WOS.[OriginAddress1], 
				   WOS.[OriginAddress2], 
				   WOS.[OriginCity], 
				   WOS.[OriginState], 
				   WOS.[OriginZip], 
				   WOS.[OriginCountryId], 
				   WOS.[MasterCompanyId], 
				   WOS.[CreatedBy], 
				   WOS.[UpdatedBy], 
				   @CreatedDate, 
				   @UpdatedDate,
				   1, 
				   0, 
				   WOS.[Shipment], 
				   WOS.[SoldToSiteId], 
				   WOS.[SoldToSiteName], 
				   WOS.[SoldToCountryName], 
				   WOS.[ShipToCustomerId], 
				   WOS.[ShipToCountryName], 
				   WOS.[OriginCountryName], 
				   WOS.[OriginSiteId], 
				   WOS.[IsSameForShipTo], 
				   WOS.[ShipSizeLength], 
				   WOS.[ShipSizeWidth], 
				   WOS.[ShipSizeHeight], 
				   WOS.[ShipWeightUnit], 
				   WOS.[ShipSizeUnitOfMeasureId], 
				   WOS.[PickTicketId], 
				   WOS.[NoOfContainer], 
				   WOS.[ShipAttention], 
				   WOS.[SoldAttention], 
				   WOS.[CustomerDomensticShippingShipViaId], 
				   WOS.[ShippingAccountInfo], 
				   WOS.[NoOfItems], 
				   WOS.[IsCustomerShipping], 
				   WOS.[IsManualShipping], 
				   WOS.[ManufactureCountryId], 
				   WOS.[QtyUOM], 
				   WOS.[UnitPrice], 
				   WOS.[UnitPriceCurrencyId], 
				   WOS.[Notes], 
				   WOS.[isIgnoreAWB], 
				   WOS.[isBypassShipping]
			FROM @WorkOrderShippingTable AS WOS
			INNER JOIN [dbo].[MasterCompany] AS MC WITH(NOLOCK) ON MC.[MasterCompanyId] = WOS.[MasterCompanyId];

			SELECT TOP 1 @WorkOrderShippingId = [WorkOrderShippingId] FROM @InsertedWorkOrderShipping;

			UPDATE [dbo].[WorkOrderShipping] 
			  SET  [WOShippingNum] = 'WOS' + CAST([WorkOrderShippingId] AS VARCHAR(20))
			 WHERE [WorkOrderShippingId] = @WorkOrderShippingId
			 AND ISNULL(MasterCompanyId, 0) = ISNULL(@MasterCompanyId, 0);

			INSERT INTO @WorkOrderShippingItemList
			(
				[WorkOrderShippingId],
				[WorkOrderPartNumId],
				[QtyShipped],
				[WOPickTicketId],
				[CreatedBy],
				[UpdatedBy],
				[MasterCompanyId]
			)
			SELECT
				@WorkOrderShippingId,
				SI.workOrderPartId,
				SI.currQtyToShip,
				SI.WOPickTicketId,
				@CreatedBy,
				@UpdatedBy,
				@MasterCompanyId
			FROM @ShippingItems SI
			WHERE ISNULL(SI.[currQtyToShip], 0) > 0;

			--  insert into WorkOrderShippingItem
			INSERT INTO dbo.WorkOrderShippingItem
			(
				[WorkOrderShippingId],
				[WorkOrderPartNumId],
				[QtyShipped],
				[WOPickTicketId],
				[CreatedBy],
				[UpdatedBy],
				[MasterCompanyId],
				[CreatedDate], 
				[UpdatedDate]
			)
			SELECT [WorkOrderShippingId],
				   [WorkOrderPartNumId],
				   [QtyShipped],
				   [WOPickTicketId],
				   [CreatedBy],
				   [UpdatedBy],
				   [MasterCompanyId],
				   @CreatedDate,
				   @UpdatedDate
			FROM @WorkOrderShippingItemList;

			-- Customs Info insert
			INSERT INTO dbo.WorkOrderCustomsInfo
			(
				[WorkOrderShippingId],
				[EntryType], 
				[EPU], 
				[CustomsValue], 
				[NetMass],
				[EntryStatus], 
				[EntryNumber], 
				[VATValue], 
				[UCR], 
				[MasterUCR],
				[MovementRefNo], 
				[CommodityCode], 
				[CustomCurrencyId],
				[MasterCompanyId], 
				[CreatedBy], 
				[UpdatedBy], 
				[CreatedDate], 
				[UpdatedDate], 
				[IsActive],
				[IsDeleted]
			)
			SELECT @WorkOrderShippingId,  
				WC.[EntryType], 
				WC.[EPU], 
				WC.[CustomsValue], 
				WC.[NetMass],
				WC.[EntryStatus], 
				WC.[EntryNumber], 
				WC.[VATValue], 
				WC.[UCR], 
				WC.[MasterUCR],
				WC.[MovementRefNo],
				WC.[CommodityCode],
				WC.[CustomCurrencyId],
				WC.[MasterCompanyId], 
				WC.[CreatedBy], 
				WC.[UpdatedBy], 
				@CreatedDate,
				@UpdatedDate,
				1, 
				0
			FROM @WorkOrderCustomsInfoList AS WC;

			------ UpdateStockLine ----------------
				--  Drop if exists
			IF OBJECT_ID('tempdb..#tmpWithRowNum') IS NOT NULL
				DROP TABLE #tmpWithRowNum;

			CREATE TABLE #tmpWithRowNum
			(
				[PKID] BIGINT IDENTITY(1,1) NOT NULL,
				[WorkOrderPartId] BIGINT,
				[QtyToShip] INT,
				[WorkOrderShippingId] BIGINT
			);

			INSERT INTO #tmpWithRowNum ([WorkOrderPartId], [QtyToShip], [WorkOrderShippingId])
			SELECT	SI.[workOrderPartId],SI.[currQtyToShip],@WorkOrderShippingId FROM @ShippingItems SI WHERE ISNULL(SI.[currQtyToShip], 0) > 0;

			DECLARE @MinId BIGINT, @MaxId BIGINT;
			DECLARE @WorkOrderPartId BIGINT, @QtyToShip INT;

			SELECT @MinId = MIN(PKID), @MaxId = MAX(PKID) FROM #tmpWithRowNum;

			-- Loop through temp table
			WHILE @MinId IS NOT NULL AND @MinId <= @MaxId
			BEGIN
				SELECT @WorkOrderPartId = [WorkOrderPartId],
					   @QtyToShip = [QtyToShip],
					   @WorkOrderShippingId = [WorkOrderShippingId]
				  FROM #tmpWithRowNum
				  WHERE [PKID] = @MinId;

				--  Call another stored procedure for each record
				EXEC dbo.USP_UpdateStockLineWorkOrderPart
						 @WorkOrderPartNoId = @WorkOrderPartId,
						 @UpdatedBy = @UpdatedBy,
						 @NPMStockQTY = @NPMStockQTY, 
						 @ModuleId = @ModuleId, 
						 @SubModuleId = @SubModuleId,
						 @SubRefferenceId = @WorkOrderShippingId,
						 @ActionId = @ActionId, 
						 @Qty = @QtyToShip,
						 @MasterCompanyId = @MasterCompanyId;

					SET @MinId += 1;  
			END;
			DROP TABLE #tmpWithRowNum;
		END;

		-- Create a temp table for Shipping Details
		IF OBJECT_ID('tempdb..#ShippingDetails') IS NOT NULL
			DROP TABLE #ShippingDetails;

		CREATE TABLE #ShippingDetails
		(
			[ItemMasterId] BIGINT NULL,
			[MPNPartNumber] NVARCHAR(100) NULL,
			[ShippingViaName] NVARCHAR(100) NULL,
			[TemplatedBody] NVARCHAR(MAX) NULL,
			[ShipToCustomer] NVARCHAR(200) NULL,
			[WorkOrderTypeId] BIGINT NULL
		);

		INSERT INTO #ShippingDetails
		EXEC [dbo].[USP_GetWorkOrderTypeIdAndShippingName]
		 	 @WoPartNoId = @WorkOrderPartNoId,
			 @ShipviaId = @ShipviaId,
			 @ShippingName = @ShippingName,
			 @ShipToCustomerId = @ShipToCustomerId,
			 @WorkOrderId = @WorkOrderId,
			 @MasterCompanyId = @MasterCompanyId;

		-- Assign values from the temp table to variables
		SELECT @ItemMasterId = [ItemMasterId],
			   @MPNPartNumber = [MPNPartNumber],
			   @ShippingViaName = [ShippingViaName],
			   @TemplatedBody = [TemplatedBody],
			   @ShipToCustomer = [ShipToCustomer],
			   @WorkOrderTypeId = [WorkOrderTypeId]
		  FROM #ShippingDetails;

		IF (@IsAdd = 1)
		BEGIN
			DECLARE @ValidDistributionCount INT = 0;
			DECLARE @DistributionMasterId BIGINT = NULL;
			DECLARE @DistributionMasterCode NVARCHAR(100);

 			SELECT TOP 1 @DistributionMasterId = DM.ID FROM [dbo].[DistributionMaster] AS DM WITH(NOLOCK) WHERE ISNULL(DM.DistributionCode, '') = ISNULL(@DistributionCode, '');

			-- Get count from DistributionSetup using the variable
			SELECT @ValidDistributionCount = COUNT(1),
			       @DistributionMasterCode = @DistributionCode
			FROM [dbo].[DistributionSetup] DS WITH (NOLOCK)
			WHERE DS.[DistributionMasterId] = @DistributionMasterId
				AND DS.[MasterCompanyId] = @MasterCompanyId
				AND ISNULL(DS.[GlAccountId], 0) = 0
				AND ISNULL(DS.[IsManualText], 0) = 0;
      
			IF (@ValidDistributionCount > 0)
			BEGIN
				SET @ValidBatchDetails = 0;
			END

			IF (@ValidBatchDetails = 1)
			BEGIN
			   --  BatchTriggerBasedonDistribution LOGIC COMMENTED FOR NOW
			   PRINT 'BatchTriggerBasedonDistribution LOGIC COMMENTED FOR NOW';
			END
		END						
			-- Add Entry in History Table
		DECLARE @OldValue NVARCHAR(50) = 'False',
				@NewValue NVARCHAR(50) = 'True',
				@ReplaceContent NVARCHAR(MAX)='';

		IF @MPNPartNumber IS NOT NULL
		BEGIN
			SET @ReplaceContent = ISNULL(@TemplatedBody, '');
			SET @ReplaceContent = REPLACE(@ReplaceContent, '##WoMPN##', ISNULL(@MPNPartNumber, ''));
			SET @ReplaceContent = REPLACE(@ReplaceContent, '##ShippViaName##', ISNULL(@ShippingViaName, ''));

			EXEC [dbo].[USP_History]
				 @ModuleId = @ModuleId,
				 @RefferenceId = @WorkOrderId,
				 @SubModuleId = @HistorySubModuleId,
				 @SubRefferenceId = @WorkOrderPartNoId,
				 @OldValue = @OldValue,
				 @NewValue = @NewValue,
				 @HistoryText = @ReplaceContent,
				 @StatusCode = @HistoryStatusCode,
				 @MasterCompanyId = 0,
				 @CreatedBy = @UpdatedBy,
				 @CreatedDate = @CurrentUtcDate,
				 @UpdatedBy = @UpdatedBy,
				 @UpdatedDate = @CurrentUtcDate
		END

		SET @ShipToCustomer = ISNULL(@ShipToCustomer, '');

		-- return fields
		SELECT WO.*,
		       @WorkOrderShippingId AS WorkOrderShippingId,
			   WO.WOShippingNum AS WOShippingNum,
			   @ShipToCustomer AS ShipToCustomer,
			   CAST('' AS NVARCHAR(200)) AS ShippingSuccess,
			   CAST('' AS NVARCHAR(200)) AS FedexSuccess,
			   CAST('' AS NVARCHAR(200)) AS FedexError,
			-- Serialize the TVP as JSON
			 (SELECT * FROM @WorkOrderShippingItemList WSI
			    WHERE WSI.WorkOrderShippingId = WO.WorkOrderShippingId
					 FOR JSON PATH) AS workOrderShippingItems
				FROM [dbo].[WorkOrderShipping] WO WITH (NOLOCK)
				WHERE WO.[WorkOrderShippingId] = @WorkOrderShippingId;
	
	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
		ROLLBACK TRAN;

		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
					,@AdhocComments     VARCHAR(150)    = 'USP_SaveWorkOrderShipping'     
					,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderShippingId, '') AS VARCHAR(100))
														+ '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderPartNoId, '') AS VARCHAR(100)) 
					,@ApplicationName VARCHAR(100) = 'PAS'    
			-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
		EXEC spLogException @DatabaseName = @DatabaseName
		,@AdhocComments			= @AdhocComments    
		,@ProcedureParameters   = @ProcedureParameters    
		,@ApplicationName       =  @ApplicationName    
		,@ErrorLogID			= @ErrorLogID OUTPUT ;    
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
		RETURN(1); 
		END CATCH
END