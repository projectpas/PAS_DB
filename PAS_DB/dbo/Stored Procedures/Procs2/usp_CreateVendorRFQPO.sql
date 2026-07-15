
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.usp_CreateVendorRFQPO   (source: PAS_DB/dbo/Stored Procedures/Procs2/usp_CreateVendorRFQPO.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [usp_CreateVendorRFQPO]           
 ** Author:  Devendra Shekh
 ** Description: This stored Procedure is used to Create the Vendor RFQ PO
 ** Date:   16-Sept-2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				 Author				 Change Description            
 ** --   --------			---------			--------------------------------          
    1   16-Sept-2025		Devendra Shekh		 Created
	2   08-Dec-2025         Moin Bloch           Added Default Company Address For VRFQ
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

declare @p4 dbo.VendorRFQPOPartType
insert into @p4 values(1,5416,2,96978,N'New',1,2400)

declare @p5 bigint
set @p5=2190
exec dbo.usp_CreateVendorRFQPO @SourceBy=N'ILS',@MarketplaceRef=N'9159021',@QuoteWithinDays=3,@tbl_VendorRFQPOPartType=@p4,@VendorRFQPurchaseOrderId=@p5 output
select @p5    
************************************************************************/
CREATE     PROCEDURE [dbo].[usp_CreateVendorRFQPO]
@SourceBy VARCHAR(50) = NULL,
@MarketplaceRef VARCHAR(50) = NULL,
@QuoteWithinDays INT = NULL,
@tbl_VendorRFQPOPartType [VendorRFQPOPartType] READONLY,
@VendorRFQPurchaseOrderId BIGINT OUTPUT
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @VendorId BIGINT = NULL, @MasterCompanyId INT = NULL, @EmployeeId BIGINT = NULL, @LegalEntityId BIGINT = NULL;
		DECLARE @tbl_VendorRFQPurchaseOrderPartType AS VendorRFQPurchaseOrderPartType;

		SELECT TOP 1 @VendorId = [VendorId], @MasterCompanyId = [MasterCompanyId], @EmployeeId = [EmployeeId] FROM @tbl_VendorRFQPOPartType;

		-- Save Vendor RFQ PO Header Details		: Start
		DECLARE @MSModuleId BIGINT, @PartMSModuleId BIGINT, @MSDetailsId BIGINT;
		DECLARE @Resale BIT, @DeferredReceiver BIT; 
		DECLARE @StatusId BIGINT, @Status VARCHAR(100);
		DECLARE @VendorName VARCHAR(100), @VendorCode VARCHAR(100);
		DECLARE @PriorityId BIGINT, @PriorityDescription VARCHAR(100);
		DECLARE @UserName VARCHAR(256), @ManagementStructureId BIGINT;
		DECLARE @CreditTermsId INT, @Terms VARCHAR(500) = 0, @CreditLimit DECIMAL(18, 2);
		DECLARE @CodeTypeId BIGINT, @CurrentNumber BIGINT = 0, @RFQPONumber NVARCHAR(200);
		DECLARE @Memo NVARCHAR(MAX) = '', @CurrencyId INT, @FXRateValue DECIMAL(18, 2) = 1;
		DECLARE @VendorContactId BIGINT, @VendorContact VARCHAR(150), @VendorContactPhone VARCHAR(50);		
		DECLARE @RFQSentDate DATETIME2;

		IF OBJECT_ID(N'tempdb..#tmpCodePrefix') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefix
		END

		-- Determine the current number
		SELECT TOP 1 @CodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'VendorRFQPurchaseOrder';
		SELECT TOP 1 * INTO #tmpCodePrefix FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0 AND [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;

		IF EXISTS (SELECT 1 FROM #tmpCodePrefix)
		BEGIN
			IF (SELECT CurrentNummber FROM #tmpCodePrefix) > 0
			BEGIN
				SET @CurrentNumber = (SELECT CurrentNummber + 1 FROM #tmpCodePrefix);
			END
			ELSE
			BEGIN
				SET @CurrentNumber = CASE WHEN (SELECT StartsFrom FROM #tmpCodePrefix) > 0 THEN (SELECT StartsFrom FROM #tmpCodePrefix) ELSE (SELECT StartsFrom FROM #tmpCodePrefix) + 1 END;
			END				

			-- Generate VendorRFQPurchaseOrderNumber
			SET @RFQPONumber = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@CurrentNumber, (SELECT CodePrefix FROM #tmpCodePrefix), (SELECT CodeSufix FROM #tmpCodePrefix)));
		END
		ELSE
		BEGIN
			-- Generate VendorRFQPurchaseOrderNumber without prefix/suffix
			SET @RFQPONumber = (SELECT * FROM [dbo].[udfGenerateCodeNumber](0, '', ''));
		END		

		SELECT @UserName = CONCAT([FirstName], ' ', [LastName]), @ManagementStructureId = [ManagementStructureId], @LegalEntityId = [LegalEntityId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId AND [MasterCompanyId] = @MasterCompanyId;
		SELECT TOP 1 @PriorityId = [PriorityId], @PriorityDescription = [Description] FROM [dbo].[Priority] WITH(NOLOCK) WHERE [Description] = 'ROUTINE' AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @VendorName = [VendorName], @VendorCode = [VendorCode], @CreditTermsId = [CreditTermsId], @CreditLimit = [CreditLimit], @CurrencyId = [CurrencyId] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @VendorId AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @Terms = [Name] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId] = @CreditTermsId AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @VendorContactId = [VendorContactId] FROM [dbo].[VendorContact] WITH(NOLOCK) WHERE [VendorId] = @VendorId AND [IsDefaultContact] = 1 AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @VendorContact = CONCAT([FirstName], ' ', [LastName]), @VendorContactPhone = [WorkPhone] FROM [dbo].[Contact] WITH(NOLOCK) WHERE [ContactId] = @VendorContactId AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @StatusId = [VendorRFQStatusId], @Status = [Description] FROM [dbo].[VendorRFQStatus] WITH(NOLOCK) WHERE [Description] = 'OPEN';
		SELECT @Resale = [IsResale], @DeferredReceiver = [IsDeferredReceiver] FROM [dbo].[PurchaseOrderSettingMaster] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPOHeader';
		SELECT @PartMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPOPart';
		SET @RFQSentDate = (SELECT [CreatedDate] FROM [dbo].[ThirdPartyRFQ] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ThirdPartyRFQId] 
						 = (SELECT [ThirdPartyRFQId] FROM [dbo].[ILSRFQDetail] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [ILSRFQDetailId]
						 = (SELECT [ILSRFQDetailId] FROM [dbo].[VendorRFQPart] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [VendorRFQPartId]
						 = (SELECT TOP 1 [VendorRFQPartId] FROM @tbl_VendorRFQPOPartType)
						   )))

		IF(ISNULL(@CurrencyId,0) = 0)
		BEGIN
			SELECT @CurrencyId = CU.CurrencyId 
			FROM [dbo].[LegalEntity] LE WITH(NOLOCK)
			JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.CurrencyId = LE.FunctionalCurrencyId
			WHERE LE.[LegalEntityId] = @LegalEntityId;
		END

		INSERT INTO [dbo].[VendorRFQPurchaseOrder] (
			[VendorRFQPurchaseOrderNumber], [OpenDate], [ClosedDate], [NeedByDate], [PriorityId], [Priority], [VendorId], [VendorName], [VendorCode], [VendorContactId], [VendorContact], [VendorContactPhone], [CreditTermsId],
			[Terms], [CreditLimit], [RequestedBy], [Requisitioner], [StatusId], [Status], [StatusChangeDate], [Resale], [DeferredReceiver], [Memo], [Notes], [ManagementStructureId], [Level1], [Level2], [Level3], [Level4],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PDFPath], [IsFromBulkPO], [FreightBilingMethodId], [TotalFreight], [ChargesBilingMethodId], [TotalCharges],
			[VendorReference], [FunctionalCurrencyId], [ReportCurrencyId], [ForeignExchangeRate], [SourceBy], [MarketplaceRef]
		)
		VALUES ( 
			@RFQPONumber, CAST(ISNULL(@RFQSentDate, GETDATE()) AS DATE), NULL, DATEADD(DAY, ISNULL(@QuoteWithinDays, 0), CAST(ISNULL(@RFQSentDate, GETDATE()) AS DATE)), @PriorityId, @PriorityDescription, @VendorId, @VendorName, @VendorCode, @VendorContactId, @VendorCode, @VendorContactPhone, @CreditTermsId,
			@Terms, @CreditLimit, @EmployeeId, @UserName, @StatusId, @Status, NULL, @Resale, @DeferredReceiver, @Memo, @Memo, @ManagementStructureId, NULL, NULL, NULL, NULL,
			@MasterCompanyId, @UserName, @UserName, ISNULL(@RFQSentDate, GETUTCDATE()), ISNULL(@RFQSentDate, GETUTCDATE()), 1, 0, NULL, 0, NULL, NULL, NULL, NULL,
			NULL, @CurrencyId, @CurrencyId, @FXRateValue, @SourceBy, @MarketplaceRef
		)

		SET @VendorRFQPurchaseOrderId = SCOPE_IDENTITY();

		DECLARE @VRFQModuleId INT=0
		SELECT @VRFQModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder'

		EXEC [dbo].[USP_AddDefaultCompanyAddress] @VendorRFQPurchaseOrderId,@VRFQModuleId,@MasterCompanyId,@UserName
		
		-- Update CodeData with new current number
		UPDATE [dbo].[CodePrefixes]	SET [CurrentNummber] = @CurrentNumber WHERE [CodePrefixId] = (SELECT CodePrefixId FROM #tmpCodePrefix);

		-- Save Header MS Details
		EXEC [dbo].[PROCAddPOMSData] @VendorRFQPurchaseOrderId,@ManagementStructureId,@MasterCompanyId,@UserName,@UserName,@MSModuleId,1,@MSDetailsId OUTPUT;
		
		EXEC [dbo].[PROCUpdateVendorRFQPurchaseOrderDetail] @VendorRFQPurchaseOrderId;

		-- Save Vendor RFQ PO Header Details		: End

		-- Save Vendor RFQ PO Part Details		: Start
		
		DECLARE @TotalPartRow INT, @CurrentPartRowId INT, @VendorRFQPOPartRecordId BIGINT;

		IF OBJECT_ID(N'tempdb..#tmp_RFQPartsResult') IS NOT NULL
		BEGIN
			DROP TABLE #tmp_RFQPartsResult;
		END

		IF OBJECT_ID(N'tempdb..#VendorRFQPOPartType') IS NOT NULL
		BEGIN
			DROP TABLE #VendorRFQPOPartType;
		END	

		CREATE TABLE #VendorRFQPOPartType
		(	
			[RowId] BIGINT IDENTITY(1,1),
			[VendorRFQPurchaseOrderId] BIGINT NULL,
			[ItemMasterId] BIGINT NULL,
			[PartNumber] NVARCHAR(200) NULL,
			[PartDescription] NVARCHAR(500) NULL,
			[StockType] NVARCHAR(50) NULL,
			[ManufacturerId] BIGINT NULL,
			[Manufacturer] NVARCHAR(200) NULL,
			[PriorityId] BIGINT NULL,
			[Priority] NVARCHAR(100) NULL,
			[NeedByDate] DATETIME NULL,
			[PromisedDate] DATETIME NULL,
			[ConditionId] BIGINT NULL,
			[Condition] NVARCHAR(100) NULL,
			[QuantityOrdered] INT NULL,
			[UnitCost] DECIMAL(18,2) NULL,
			[ExtendedCost] DECIMAL(18,2) NULL,
			[WorkOrderId] BIGINT NULL,
			[WorkOrderNo] NVARCHAR(100) NULL,
			[SubWorkOrderId] BIGINT NULL,
			[SubWorkOrderNo] NVARCHAR(100) NULL,
			[SalesOrderId] BIGINT NULL,
			[SalesOrderNo] NVARCHAR(100) NULL,
			[ManagementStructureId] BIGINT NULL,
			[Level1] NVARCHAR(100) NULL,
			[Level2] NVARCHAR(100) NULL,
			[Level3] NVARCHAR(100) NULL,
			[Level4] NVARCHAR(100) NULL,
			[Memo] NVARCHAR(1000) NULL,
			[MasterCompanyId] INT NULL,
			[CreatedBy] NVARCHAR(100) NULL,
			[UpdatedBy] NVARCHAR(100) NULL,
			[CreatedDate] DATETIME NULL,
			[UpdatedDate] DATETIME NULL,
			[IsActive] BIT NULL,
			[IsDeleted] BIT NULL,
			[UOMId] BIGINT NULL,
			[UnitOfMeasure] NVARCHAR(100) NULL,
			[TraceableTo] BIGINT NULL,
			[TraceableToName] NVARCHAR(200) NULL,
			[TraceableToType] INT NULL,
			[TagTypeId] BIGINT NULL,
			[TaggedByType] INT NULL,
			[TaggedBy] BIGINT NULL,
			[TaggedByName] NVARCHAR(200) NULL,
			[TaggedByTypeName] NVARCHAR(200) NULL,
			[TagDate] DATETIME NULL,
			[IsNoQuote] BIT NULL,
			[IsFromVendorRFQ] BIGINT NULL
		)

		INSERT INTO #VendorRFQPOPartType ([MasterCompanyId], [ItemMasterId], [Condition], [QuantityOrdered], [UnitCost], [IsFromVendorRFQ])
		SELECT [MasterCompanyId], [ItemMasterId], [Condition], [Qty], [UnitCost], [VendorRFQPartId]
		FROM @tbl_VendorRFQPOPartType;
		
		UPDATE TMP
		SET 
			TMP.VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId,
			TMP.PartNumber = IM.PartNumber,
			TMP.PartDescription = IM.PartDescription,
			TMP.StockType = CASE WHEN (ISNULL(IM.IsPma, 0) = 1 AND ISNULL(IM.IsDER, 0) = 1) THEN 'PMA&DER' WHEN (ISNULL(IM.IsPma, 0) = 1 AND ISNULL(IM.IsDER, 0) = 0) THEN 'PMA' WHEN (ISNULL(IM.IsPma, 0) = 0 AND ISNULL(IM.IsDER, 0) = 1) THEN 'DER' ELSE 'OEM' END,
			TMP.ManufacturerId = IM.ManufacturerId,
			TMP.Manufacturer = IM.ManufacturerName,
			TMP.PriorityId = IM.PriorityId,
			TMP.Priority = IM.Priority,
			TMP.ExtendedCost = CASE WHEN ISNULL(TMP.QuantityOrdered, 0) > 0 AND ISNULL(TMP.UnitCost, 0) > 0 THEN TMP.QuantityOrdered * TMP.UnitCost ELSE 0 END,
			TMP.ManagementStructureId = @ManagementStructureId,
			TMP.CreatedBy = @UserName,
			TMP.CreatedDate = GETUTCDATE(),
			TMP.UpdatedBy = @UserName,
			TMP.UpdatedDate = GETUTCDATE(),
			TMP.IsActive = 1,
			TMP.IsDeleted = 0,
			TMP.UOMId = IM.PurchaseUnitOfMeasureId,
			TMP.UnitOfMeasure = IM.PurchaseUnitOfMeasure,
			TMP.NeedByDate = DATEADD(DAY, ISNULL(@QuoteWithinDays, 0), CAST(GETDATE() AS DATE)),
			TMP.PromisedDate = DATEADD(DAY, ISNULL(@QuoteWithinDays, 0), CAST(GETDATE() AS DATE)),
			TMP.ConditionId = CD.ConditionId,
			TMP.Condition = CD.Code,
			TMP.IsNoQuote = 0
		FROM #VendorRFQPOPartType TMP
		INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON TMP.[ItemMasterId] = IM.[ItemMasterId] AND TMP.[MasterCompanyId] = IM.[MasterCompanyId]
		LEFT JOIN [dbo].[Condition] CD WITH(NOLOCK) ON (TRIM(TMP.[Condition]) = TRIM(CD.[Code]) OR TRIM(TMP.[Condition]) = TRIM(CD.[Description])) AND TMP.[MasterCompanyId] = CD.[MasterCompanyId]

		-- Table Type Result Insert
		 WHERE ISNULL(IM.IsNonStock,0) = 0
INSERT INTO @tbl_VendorRFQPurchaseOrderPartType (
			[VendorRFQPurchaseOrderId], [ItemMasterId], [PartNumber], [PartDescription], [StockType], [ManufacturerId], [Manufacturer], [PriorityId], [Priority], [NeedByDate], [PromisedDate], [ConditionId], [Condition],
			[QuantityOrdered], [UnitCost], [ExtendedCost], [WorkOrderId], [WorkOrderNo], [SubWorkOrderId], [SubWorkOrderNo], [SalesOrderId], [SalesOrderNo], [ManagementStructureId], [Level1], [Level2], [Level3], [Level4], 
			[Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [UOMId], [UnitOfMeasure], [TraceableTo], [TraceableToName], [TraceableToType], [TagTypeId], [TaggedByType],
			[TaggedBy], [TaggedByName], [TaggedByTypeName], [TagDate], [IsNoQuote], [IsFromVendorRFQ]
			)
		SELECT [VendorRFQPurchaseOrderId], [ItemMasterId], [PartNumber], [PartDescription], [StockType], [ManufacturerId], [Manufacturer], [PriorityId], [Priority], [NeedByDate], [PromisedDate], [ConditionId], [Condition],
			[QuantityOrdered], [UnitCost], [ExtendedCost], [WorkOrderId], [WorkOrderNo], [SubWorkOrderId], [SubWorkOrderNo], [SalesOrderId], [SalesOrderNo], [ManagementStructureId], [Level1], [Level2], [Level3], [Level4], [Memo],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [UOMId], [UnitOfMeasure], [TraceableTo], [TraceableToName], [TraceableToType], [TagTypeId], [TaggedByType], [TaggedBy],
			[TaggedByName], [TaggedByTypeName], [TagDate], [IsNoQuote], [IsFromVendorRFQ] 
		FROM #VendorRFQPOPartType;
		
		EXEC [dbo].[PROCInsertVendorRFQPurchaseOrderPart] @tbl_VendorRFQPurchaseOrderPartType;

		-- Save Parts MS Details
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowId, VendorRFQPOPartRecordId, VendorRFQPurchaseOrderId
		INTO #tmp_RFQPartsResult
		FROM [dbo].[VendorRFQPurchaseOrderPart] WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId;

		SELECT @TotalPartRow = MAX(RowId), @CurrentPartRowId = MIN(RowId) FROM #tmp_RFQPartsResult;

		WHILE(@TotalPartRow >= @CurrentPartRowId) AND ISNULL(@TotalPartRow, 0) > 0
		BEGIN

			SELECT @VendorRFQPOPartRecordId = [VendorRFQPOPartRecordId] FROM #tmp_RFQPartsResult WHERE [RowId] = @CurrentPartRowId;

			EXEC dbo.[PROCAddVendorRFQPOMSData] @VendorRFQPOPartRecordId,@ManagementStructureId,@MasterCompanyId,@UserName,@UserName,@PartMSModuleId,1,@MSDetailsId OUTPUT
			
			SET @CurrentPartRowId += 1;
		END
		
		-- Save Vendor RFQ PO Part Details		: End

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = 'dbo.usp_CreateVendorRFQPO' 
				, @ProcedureParameters VARCHAR(3000) =  '@SourceBy = ' + ''
				, @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName           = @DatabaseName
			, @AdhocComments          = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName        =  @ApplicationName
			, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END