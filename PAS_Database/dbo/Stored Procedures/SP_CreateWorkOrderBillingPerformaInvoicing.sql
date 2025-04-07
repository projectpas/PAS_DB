
/*************************************************************           
 ** File:   [SP_CreateWorkOrderBillingPerformaInvoicing]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Create Performa Invoice For WO
 ** Date:   21 MAR 2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date          Author  		 Change Description            
 ** --   --------      -------		 ---------------------------     
    1    21 MAR 2025   Rajesh Gami     Created
 EXEC SP_CreateWorkOrderBillingPerformaInvoicing 246
 **************************************************************/
CREATE     PROCEDURE [dbo].[SP_CreateWorkOrderBillingPerformaInvoicing] 
	@BillingInvoicingIdMain BIGINT = 0,
	@WorkOrderId BIGINT,
	@WorkOrderPartNoId BIGINT,
	@PrintDate DATETIME = NULL,
	@ShipDate DATETIME = NULL,
	@EmployeeId BIGINT,
	@GateStatus NVARCHAR(50),
	@ConditionId INT,
	@CustomerDomensticShippingShipViaId BIGINT,
	@CurrencyId INT,
	@SoldToCustomerId BIGINT,
	@SoldToSiteId BIGINT,
	@ShipToCustomerId BIGINT,
	@ShipToSiteId BIGINT,
	@ManagementStructureId INT,
	@CostPlusType NVARCHAR(50),
	@TotalWorkOrder INT,
	@ShipViaId BIGINT,
	@Tracking NVARCHAR(255),
	@CustomerId BIGINT,
	@WayBillRef NVARCHAR(255),
	@NoOfPieces NVARCHAR(50),
	@IsCustomerShipping BIT,
	@InvoiceNo NVARCHAR(50),
	@InvoiceTime NVARCHAR(5),
	@ShipToAttention NVARCHAR(100),
	@InvoiceTypeId INT,
	@TotalWorkOrderCostPlus DECIMAL(18, 2),
	@GrandTotal DECIMAL(18, 2),
	@AvailableCredit DECIMAL(18, 2),
	@CreatedBy NVARCHAR(100),
	@WorkFlowWorkOrderId BIGINT,
	@MasterCompanyId INT,
	@InvoiceStatus NVARCHAR(50),
	@WorkOrderShippingId BIGINT,
	@IsNewInvoice BIT = 0,
	@IsCreatedFromQuote BIT,
	@ShippingAccountInfo NVARCHAR(255),
	@IsPerformaInvoice BIT,
    @BillingItems dbo.WorkOrderBillingInvoicingType READONLY 
AS
BEGIN
 
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
   SET NOCOUNT ON;
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @ErrorMessage NVARCHAR(MAX) = NULL,@WOPartIds NVARCHAR(MAX) ='',@Result BIT =0, @SalesTaxName VARCHAR(50)='SALES TAX';
		DECLARE @NewVersion NVARCHAR(100) = '',@SelectedBillingInvoicingId BIGINT =0;
		DECLARE @ItemMasterId INT;
		DECLARE @RevisedSerialNumber NVARCHAR(50) = '';
		DECLARE @VersionNo NVARCHAR(100) = '';
		DECLARE @TaxRate DECIMAL(18, 2) = 0;
		DECLARE @SalesTax DECIMAL(18, 2) = 0;
		DECLARE @OtherTax DECIMAL(18, 2) = 0;
		DECLARE @SubTotal DECIMAL(18, 2) = 0, @FinalGrandTotal  DECIMAL(18, 2) = 0;;
		DECLARE @versionCodeTypeId INT = (Select TOP 1 CodeTypeId from DBO.CodeTypes WITH(NOLOCK) Where CodeType ='Version');
		DECLARE @RemainingAmount DECIMAL(18, 2) = 0;
		DECLARE @IsCreateNewInvoice BIT = 0 , @CodeTypeId AS BIGINT = (Select TOP 1 CodeTypeId from DBO.CodeTypes WITH(NOLOCK) Where CodeType ='WOProformaInvoice');
		DECLARE @UnitPrice DECIMAL(18, 2);
		DECLARE @Freight BIT = 0;

		IF OBJECT_ID(N'tempdb..#tmpWorkOrderBillingInvoicingItem') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWorkOrderBillingInvoicingItem
		END
		CREATE TABLE #tmpWorkOrderBillingInvoicingItem (
			Id INT IDENTITY(1,1) PRIMARY KEY,
			VersionNo  VARCHAR(50),
			IsVersionIncrease BIT,
			NoOfPieces INT,
			TaxRate DECIMAL(18,2),
			UnitPrice DECIMAL(18,2),
			Freight DECIMAL(18,2),
			MiscCharges DECIMAL(18,2),
			SalesTax DECIMAL(18,2),
			SubTotal DECIMAL(18,2),
			OtherTax DECIMAL(18,2),
			ItemMasterId BIGINT,
			WorkOrderPartId BIGINT,
			MasterCompanyId BIGINT,
			CreatedBy VARCHAR(256),
			UpdatedBy VARCHAR(256),
			BillingInvoicingId BIGINT,
			CreatedDate DATETIME DEFAULT GETUTCDATE(),
			UpdatedDate DATETIME DEFAULT GETUTCDATE(),
			IsActive BIT DEFAULT 1,
			IsDeleted BIT DEFAULT 0,
			ConditionId BIGINT,
			IsPerformaInvoice BIT DEFAULT 1
		);

		IF EXISTS (SELECT 1 FROM @BillingItems) /****START: IF EXISTS (SELECT 1 FROM @BillingItems)****/
		BEGIN
				IF OBJECT_ID(N'tempdb..#tmpBillingItems') IS NOT NULL
				BEGIN
					DROP TABLE #tmpBillingItems
				END
				CREATE TABLE #tmpBillingItems
				(ID BIGINT NOT NULL IDENTITY, 
				 WorkOrderShippingId BIGINT,
				 NoOfPieces INT,
				 OrderPartId BIGINT,
				 WorkOrderPartId BIGINT,
				 ConditionId BIGINT NULL,
				 BillingInvoicingId BIGINT NULL	)
			
				INSERT INTO #tmpBillingItems (WorkOrderShippingId,NoOfPieces,OrderPartId,WorkOrderPartId,ConditionId,BillingInvoicingId)
					SELECT WorkOrderShippingId,NoOfPieces,OrderPartId,WorkOrderPartId,ConditionId,BillingInvoicingId FROM @BillingItems

				IF OBJECT_ID(N'tempdb..#tmpWorkOrderPartIds') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWorkOrderPartIds
				END
				CREATE TABLE #tmpWorkOrderPartIds
				(ID BIGINT NOT NULL IDENTITY, [WorkOrderPartId] BIGINT NULL	)
			
				INSERT INTO #tmpWorkOrderPartIds (WorkOrderPartId)
				SELECT WorkOrderPartId FROM @BillingItems;

				DECLARE BillingCursor CURSOR FOR
				SELECT WorkOrderPartId, BillingInvoicingId
				FROM @BillingItems;

				OPEN BillingCursor;

				DECLARE @WorkOrderPartId INT, @BillingInvoicingId INT;

				FETCH NEXT FROM BillingCursor INTO @WorkOrderPartId, @BillingInvoicingId;
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SELECT @WOPartIds = STRING_AGG(CAST(WorkOrderPartId AS NVARCHAR(MAX)), ',')	FROM #tmpWorkOrderPartIds;

					EXEC dbo.USP_CheckWOInvoiceExistByWOBillId 	@BillingInvoicingId = @BillingInvoicingId, @WOPartIds = @WOPartIds, @IsProformaInvoice = 1,	@Result = @Result OUTPUT;

					SET @IsNewInvoice = @Result;

					IF @IsNewInvoice = 0
					BEGIN
						SELECT @InvoiceNo = InvoiceNo FROM DBO.WorkOrderBillingInvoicing WITH(NOLOCK) WHERE BillingInvoicingId = @BillingInvoicingId;
					END
					ELSE
					BEGIN
						SET @InvoiceNo = '';
						SET @IsCreateNewInvoice = 1;
					END

					IF @IsCreateNewInvoice = 1
					BEGIN
						SET @InvoiceNo = '';
						SET @IsNewInvoice = 1;
					END

					FETCH NEXT FROM BillingCursor INTO @WorkOrderPartId, @BillingInvoicingId;
				END

				CLOSE BillingCursor;
				DEALLOCATE BillingCursor;
	
		
			IF @IsNewInvoice = 1 OR @InvoiceNo = '' /****Start: IF @IsNewInvoice = 1 OR @InvoiceNo = '' ****/
			BEGIN

				DECLARE @CurrentNumber INT;
				 IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
					DROP TABLE #tmpCodePrefixes
					END
				
					CREATE TABLE #tmpCodePrefixes
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 CodePrefixId BIGINT NULL,
						 CodeTypeId BIGINT NULL,
						 CurrentNumber BIGINT NULL,
						 CodePrefix VARCHAR(50) NULL,
						 CodeSufix VARCHAR(50) NULL,
						 StartsFrom BIGINT NULL,
					)

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
					BEGIN 
						SELECT 
							@CurrentNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
								ELSE CAST(StartsFrom AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

						SET @InvoiceNo = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNumber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					END
					ELSE 
					BEGIN
						ROLLBACK TRAN;
					END
					UPDATE CodePrefixes SET CurrentNummber = @CurrentNumber WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCodePrefixes 
					END
			END /****END: IF @IsNewInvoice = 1 OR @InvoiceNo = '' ****/
		

			/*********START:  WHILE LOOP #tmpBillingItems ***********/
			DECLARE @CurrentId INT =(SELECT MIN(Id) FROM #tmpBillingItems), @TotalCounts INT = 0;
			SELECT @TotalCounts = COUNT(Id) FROM #tmpBillingItems;

			WHILE  @CurrentId<= @TotalCounts
			BEGIN
				SELECT @WorkOrderPartId = WorkOrderPartId FROM #tmpBillingItems WHERE ID = @CurrentId
				 IF(@IsNewInvoice = 1)
				 BEGIN
					IF OBJECT_ID(N'tempdb..#tmpBillingItemsLoop') IS NOT NULL
					BEGIN
						DROP TABLE #tmpBillingItemsLoop
					END
					CREATE TABLE #tmpBillingItemsLoop (BillingInvoicingId BIGINT);
					INSERT INTO #tmpBillingItemsLoop (BillingInvoicingId)	SELECT BillingInvoicingId FROM DBO.WorkOrderBillingInvoicingItem WITH(NOLOCK) WHERE WorkOrderPartId = @WorkOrderPartId  AND ISNULL(IsPerformaInvoice,0) = 1;

					UPDATE wobi
					SET IsVersionIncrease = 1
					FROM dbo.WorkOrderBillingInvoicing wobi
					INNER JOIN #tmpBillingItemsLoop tbi	ON wobi.BillingInvoicingId = tbi.BillingInvoicingId
					WHERE wobi.WorkOrderId = @WorkOrderId  AND wobi.IsVersionIncrease = 0  AND wobi.IsPerformaInvoice = 1;
				 END

				SELECT TOP 1 
					@ItemMasterId = CASE WHEN ISNULL(RevisedItemMasterId,0) > 0 THEN ISNULL(RevisedItemMasterId,0) ELSE ISNULL(ItemMasterId,0) END, 
					@RevisedSerialNumber = ISNULL(RevisedSerialNumber, '')
				FROM DBO.WorkOrderPartNumber WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND ID = @WorkOrderPartId;

				SELECT TOP 1 @VersionNo = ISNULL(VersionNo,'')
				FROM DBO.WorkOrderBillingInvoicingItem WITH(NOLOCK) WHERE WorkOrderPartId = @WorkOrderPartId AND ISNULL(IsVersionIncrease,0) = 0 AND ISNULL(IsPerformaInvoice,0) = 1;
				PRINT '@VersionNo'
				PRINT @VersionNo
				SET @NewVersion = ''
				EXEC dbo.USP_UpdateWOVersionNum @VersionNum = @VersionNo, @CodeTypeId =@versionCodeTypeId ,	@NewVersion = @NewVersion OUTPUT;
			
				/*********START:  @IsCreatedFromQuote = 1 ***********/
				IF @IsCreatedFromQuote = 1
				BEGIN
					DECLARE @QuoteMethod BIT;
					DECLARE @CommonFlatRate DECIMAL(18, 2);
					DECLARE @MaterialFlatBillingAmount DECIMAL(18, 2);
					DECLARE @LaborFlatBillingAmount DECIMAL(18, 2);
					SELECT TOP 1
						@QuoteMethod = QuoteMethod,
						@CommonFlatRate = CommonFlatRate,
						@MaterialFlatBillingAmount = MaterialFlatBillingAmount,
						@LaborFlatBillingAmount = LaborFlatBillingAmount
					FROM DBO.WorkOrderQuoteDetails WITH(NOLOCK)
					WHERE WOPartNoId = @WorkOrderPartId;

					IF @QuoteMethod = 1
					BEGIN
						SET @UnitPrice = @CommonFlatRate;
						SET @Freight = 1;
					END
					ELSE
					BEGIN
						SET @UnitPrice = ISNULL(@MaterialFlatBillingAmount, 0) + ISNULL(@LaborFlatBillingAmount, 0);
					END
				END
				ELSE
				BEGIN
					SET @UnitPrice = 0;
				END
				IF(@BillingInvoicingIdMain > 0)
				BEGIN
				/******START: INSERT INTO : WorkOrderBillingInvoicingItem *******/
					INSERT INTO WorkOrderBillingInvoicingItem (
					VersionNo,		IsVersionIncrease,
					NoOfPieces,		TaxRate,
					UnitPrice,		Freight,
					MiscCharges,	SalesTax,
					SubTotal,		OtherTax,
					ItemMasterId,   WorkOrderPartId,
					MasterCompanyId,CreatedBy,
					UpdatedBy,	BillingInvoicingId,
					CreatedDate,	UpdatedDate,
					IsActive,		IsDeleted,
					ConditionId,	IsPerformaInvoice
					)
					VALUES (
						@NewVersion,0,1,0,@UnitPrice,0,0,0,0,0,@ItemMasterId,@WorkOrderPartId,@MasterCompanyId,@CreatedBy,@CreatedBy,@BillingInvoicingIdMain,GETUTCDATE(), GETUTCDATE(),
						1,0,@ConditionId,1
					);

					UPDATE wobi
					SET UpdatedDate = GETUTCDATE(),UpdatedBy = CASE WHEN ISNULL(@CreatedBy,'') != '' THEN @CreatedBy ELSE UpdatedBy END, InvoiceDate = GETUTCDATE(),Freight= @Freight,InvoiceNo = @InvoiceNo
					FROM dbo.WorkOrderBillingInvoicing wobi
					WHERE BillingInvoicingId = @BillingInvoicingIdMain
			
				/****** END: INSERT INTO : WorkOrderBillingInvoicingItem *******/
				END
				ELSE
				BEGIN
					INSERT INTO #tmpWorkOrderBillingInvoicingItem (
						VersionNo, IsVersionIncrease, NoOfPieces, TaxRate, UnitPrice, Freight,
						MiscCharges, SalesTax, SubTotal, OtherTax, ItemMasterId, WorkOrderPartId,
						MasterCompanyId, CreatedBy, UpdatedBy, BillingInvoicingId, CreatedDate, UpdatedDate,
						IsActive, IsDeleted, ConditionId, IsPerformaInvoice
					)
					VALUES (
						@NewVersion, 0, 1, 0, @UnitPrice, 0, 0, 0, 0, 0, @ItemMasterId, @WorkOrderPartId,
						@MasterCompanyId, @CreatedBy, @CreatedBy, 0, GETUTCDATE(), GETUTCDATE(),
						1, 0, @ConditionId, 1
					);
				END
	
				/*********END:  @IsCreatedFromQuote = 1 ***********/
				SET @CurrentId =@CurrentId + 1
			END
			/*********END:  WHILE LOOP #tmpBillingItems ***********/
		
			IF ISNULL(@BillingInvoicingIdMain,0) = 0 /*------- START :IF ISNULL(@BillingInvoicingIdMain,0) = 0----------*/
			BEGIN
				DECLARE @ExistingBillingInvoicingId INT;
				SELECT TOP 1 @ExistingBillingInvoicingId = BillingInvoicingId, @VersionNo = VersionNo
				FROM dbo.WorkOrderBillingInvoicing WITH(NOLOCK)
				WHERE WorkOrderId = @WorkOrderId  AND IsVersionIncrease = 0  AND InvoiceNo = @InvoiceNo  AND IsPerformaInvoice = 1;

				IF @ExistingBillingInvoicingId IS NOT NULL
				BEGIN
					UPDATE dbo.WorkOrderBillingInvoicing 
					SET IsVersionIncrease = 1
					WHERE BillingInvoicingId = @ExistingBillingInvoicingId;

					UPDATE dbo.WorkOrderBillingInvoicingItem 
					SET IsVersionIncrease = 1
					WHERE BillingInvoicingId = @ExistingBillingInvoicingId;

					SET @NewVersion = ''
					EXEC dbo.USP_UpdateWOVersionNum @VersionNum = @VersionNo, @CodeTypeId =@versionCodeTypeId ,	@NewVersion =  @NewVersion OUTPUT;
				END
				ELSE
				BEGIN
					SET @NewVersion = ''
					EXEC dbo.USP_UpdateWOVersionNum @VersionNum = '', @CodeTypeId =@versionCodeTypeId ,	@NewVersion =  @NewVersion OUTPUT;
				END

				IF @IsCustomerShipping = 1
				BEGIN
					SELECT TOP 1 @ShipViaId = ShipViaId, @ShippingAccountInfo = ShippingAccountInfo
						FROM dbo.CustomerDomensticShippingShipVia WITH(NOLOCK)
						WHERE CustomerDomensticShippingShipViaId = @CustomerDomensticShippingShipViaId;
				END
				ELSE
				BEGIN
					SET @ShipViaId = @CustomerDomensticShippingShipViaId;
					SET @CustomerDomensticShippingShipViaId = NULL;
				END

				SELECT @SalesTax = ISNULL(SUM(CASE WHEN UPPER(t.Code) = @SalesTaxName THEN tr.TaxRate ELSE 0 END), 0),
				   @OtherTax = ISNULL(SUM(CASE WHEN t.Code IS NULL OR UPPER(t.Code) <> @SalesTaxName THEN tr.TaxRate ELSE 0 END), 0)
				FROM dbo.CustomerTaxTypeRateMapping ctt WITH(NOLOCK)
					INNER JOIN dbo.TaxType t WITH(NOLOCK) ON ctt.TaxTypeId = t.TaxTypeId
					INNER JOIN dbo.TaxRate tr WITH(NOLOCK) ON ctt.TaxRateId = tr.TaxRateId
				WHERE ctt.CustomerId = @CustomerId	AND ctt.IsActive = 1 AND ctt.IsDeleted = 0;

				SET @SubTotal = @GrandTotal;
				SET @FinalGrandTotal = @SubTotal + @SalesTax + @OtherTax;
				SET @RemainingAmount = @FinalGrandTotal;
			

				INSERT INTO [dbo].[WorkOrderBillingInvoicing] ([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderPartNoId], [ItemMasterId], [InvoiceTypeId], [InvoiceNo], [CustomerId], [InvoiceDate], 
															 [InvoiceTime], [PrintDate], [ShipDate], [NoofPieces], [EmployeeId], [GateStatus], [SoldToCustomerId], [SoldToSiteId], [ShipToCustomerId], 
															 [ShipToSiteId], [ShipToAttention], [ManagementStructureId], [CostPlusType], [TotalWorkOrder],ShipViaId, [WayBillRef], [Tracking], [MasterCompanyId], 
															 [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [CurrencyId], [AvailableCredit], [TotalWorkOrderCostPlus],  
															 [GrandTotal], [WorkOrderShippingId], [InvoiceStatus], [VersionNo], [IsVersionIncrease],  [Freight], [CustomerDomensticShippingShipViaId], 
															 [ShippingAccountInfo], [RemainingAmount], [TaxRate], [SalesTax], [OtherTax], [SubTotal], [IsCustomerShipping], [ConditionId], [RevisedSerialNumber], 
															 [IsPerformaInvoice], [isCreatedFromQuote]) 
														VALUES (@WorkOrderId, @WorkFlowWorkOrderId, @WorkOrderPartNoId, @ItemMasterId, @InvoiceTypeId, @InvoiceNo, @CustomerId, GETUTCDATE(), 
															@InvoiceTime, @PrintDate, @ShipDate, @NoofPieces, @EmployeeId, @GateStatus, @SoldToCustomerId, @SoldToSiteId, @ShipToCustomerId, 
															@ShipToSiteId, @ShipToAttention, @ManagementStructureId, @CostPlusType, @TotalWorkOrder,  @ShipViaId, @WayBillRef, @Tracking, @MasterCompanyId, 
															@CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @CurrencyId, @AvailableCredit, @TotalWorkOrderCostPlus,
															@FinalGrandTotal, @WorkOrderShippingId, @InvoiceStatus, @NewVersion, 0, @Freight, @CustomerDomensticShippingShipViaId, 
															@ShippingAccountInfo, @RemainingAmount, @TaxRate, @SalesTax, @OtherTax, @SubTotal, @IsCustomerShipping, @ConditionId, @RevisedSerialNumber, 
															1, @isCreatedFromQuote);

				SET @BillingInvoicingIdMain =(SELECT IDENT_CURRENT('WorkOrderBillingInvoicing'))
				INSERT INTO WorkOrderBillingInvoicingItem (
					VersionNo,		IsVersionIncrease,
					NoOfPieces,		TaxRate,
					UnitPrice,		Freight,
					MiscCharges,	SalesTax,
					SubTotal,		OtherTax,
					ItemMasterId,   WorkOrderPartId,
					MasterCompanyId,CreatedBy,
					UpdatedBy,	BillingInvoicingId,
					CreatedDate,	UpdatedDate,
					IsActive,		IsDeleted,
					ConditionId,	IsPerformaInvoice
					)
					SELECT VersionNo,		IsVersionIncrease,
					NoOfPieces,		TaxRate,
					UnitPrice,		Freight,
					MiscCharges,	SalesTax,
					SubTotal,		OtherTax,
					ItemMasterId,   WorkOrderPartId,
					MasterCompanyId,CreatedBy,
					UpdatedBy,	@BillingInvoicingIdMain,
					CreatedDate,	UpdatedDate,
					IsActive,		IsDeleted,
					ConditionId,	IsPerformaInvoice FROM #tmpWorkOrderBillingInvoicingItem
			END /*------- END :IF ISNULL(@BillingInvoicingIdMain,0) = 0----------*/
		

		END  /****END: IF EXISTS (SELECT 1 FROM @BillingItems)****/

		SELECT * FROM DBO.WorkOrderBillingInvoicing WITH (NOLOCK) WHERE BillingInvoicingId = @BillingInvoicingIdMain
		SELECT * FROM DBO.WorkOrderBillingInvoicingItem WITH (NOLOCK) WHERE BillingInvoicingId = @BillingInvoicingIdMain
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			 SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[SP_CreateWorkOrderBillingPerformaInvoicing]',
            @ProcedureParameters varchar(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
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