 /*************************************************************           
 ** File:   [USP_CreateExchangeSalesOrderShipping]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to CreateExchangeSalesOrderShipping
 ** Purpose:         
 ** Date:   09/11/2025      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1   09/11/2025  Ekta Chandegra     Created
     
	EXEC [dbo].[USP_CreateExchangeSalesOrderShipping] @ExchangeSalesOrderShippingId=0,
	@ExchangeSalesOrderId=146,@IsCustomerShipping=0,@ShipviaId=2,@CustomerDomensticShippingShipViaId=0,
	@CreatedBy=N'roza diaz',@SOShippingStatusId=1,@OpenDate='2025-09-11 00:00:00',@CustomerId=9,
	@ShipDate='2025-09-11 00:00:00',@AirwayBill=N'',@HouseAirwayBill=N'HouseAirwayBill',
	@TrackingNum=N'TrackNum',@Weight=0,@SoldToName=N'SRK AVIATION',@SoldToAddress1=N'3797 CAMBRIDGE COURT',
	@SoldToAddress2=N'',@SoldToCity=N'CLARKSVILLE',@SoldToState=N'ARKANSAS',@SoldToZip=N'72830',
	@SoldToCountryId=1,@ShipToName=N'SRK AVIATION',@ShipToSiteName=N'SRK AVIATION',@ShipToSiteId=3,
	@ShipToAddress1=N'3797 CAMBRIDGE COURT',@ShipToAddress2=N'',@ShipToCity=N'CLARKSVILLE',@ShipToState=N'ARKANSAS',
	@ShipToZip=N'72830',@ShipToCountryId=1,@OriginName=N'CENTRAL US',@OriginAddress1=N'CENTRAL US',
	@OriginAddress2=N'',@OriginCity=N'Orlando',@OriginState=N'FL',@OriginZip=N'324332',@OriginCountryId=1,
	@SoldToSiteId=3,@SoldToSiteName=N'SRK AVIATION',@SoldToCountryName=N'UNITED STATES',@ShipToCustomerId=1,
	@ShipToCountryName=N'UNITED STATES',@OriginCountryName=N'United States',@OriginSiteId=2,@IsSameForShipTo=0,
	@MasterCompanyId=1,@ShipSizeLength=0,@ShipSizeWidth=0,@ShipSizeHeight=0,@ShipWeightUnit=0,@ShipSizeUnitOfMeasureId=0,
	@NoOfContainer=1,@ShippingAccountNo=N'740561073',@NoOfItems=1,@IsManualShipping=0,@ManufactureCountryId=0,@QtyUOM=0,
	@UnitPrice=0,@UnitPriceCurrencyId=1,@PackagingSlipNotes=N'',@ExchangeSalesOrderPartId=139,@QtyShipped=1,
	@SOPickTicketId=97,@PackagingSlipId=0

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateExchangeSalesOrderShipping]
@ExchangeSalesOrderShippingId BIGINT,
@ExchangeSalesOrderId BIGINT,
@IsCustomerShipping BIT,
@ShipviaId BIGINT,
@CustomerDomensticShippingShipViaId BIGINT,
@CreatedBy VARCHAR(256),
@SOShippingStatusId BIGINT,
@OpenDate DATETIME,
@CustomerId BIGINT,
@ShipDate DATETIME2,
@AirwayBill VARCHAR(50),
@HouseAirwayBill VARCHAR(50),
@TrackingNum VARCHAR(50),
@Weight DECIMAL(10,2),
@SoldToName VARCHAR(256),
@SoldToAddress1 VARCHAR(256),
@SoldToAddress2 VARCHAR(256),
@SoldToCity VARCHAR(256),
@SoldToState VARCHAR(256),
@SoldToZip VARCHAR(20),
@SoldToCountryId smallint,
@ShipToName VARCHAR(256),
@ShipToSiteName VARCHAR(256),
@ShipToSiteId BIGINT,
@ShipToAddress1 VARCHAR(256),
@ShipToAddress2 VARCHAR(256),
@ShipToCity VARCHAR(256),
@ShipToState VARCHAR(256),
@ShipToZip VARCHAR(20),
@ShipToCountryId SMALLINT,
@OriginName VARCHAR(256),
@OriginAddress1 VARCHAR(256),
@OriginAddress2 VARCHAR(256),
@OriginCity VARCHAR(256),
@OriginState VARCHAR(256),
@OriginZip VARCHAR(20),
@OriginCountryId smallint,
@SoldToSiteId BIGINT,
@SoldToSiteName VARCHAR(256),
@SoldToCountryName VARCHAR(256),
@ShipToCustomerId BIGINT,
@ShipToCountryName VARCHAR(256),
@OriginCountryName VARCHAR(256),
@OriginSiteId BIGINT,
@IsSameForShipTo BIT,
@MasterCompanyId INT,
@ShipSizeLength DECIMAL(10,2),
@ShipSizeWidth DECIMAL(10,2),
@ShipSizeHeight DECIMAL(10,2),
@ShipWeightUnit BIGINT,
@ShipSizeUnitOfMeasureId BIGINT,
@NoOfContainer INT,
@ShippingAccountNo VARCHAR(150),
@NoOfItems INT,
@IsManualShipping BIT,
@ManufactureCountryId INT,
@QtyUOM BIGINT,
@UnitPrice DECIMAL(20,2),
@UnitPriceCurrencyId INT,
@PackagingSlipNotes NVARCHAR(MAX),
@ExchangeSalesOrderPartId BIGINT,
@QtyShipped INT,
@SOPickTicketId BIGINT,
@PackagingSlipId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
		BEGIN TRY
			BEGIN TRANSACTION;
				DECLARE @IsAdd BIT = 0;
				DECLARE @ExchangeSalesOrderShippingPrefix VARCHAR(10) = 'ExchSOS';
				DECLARE @CurrentNumber BIGINT;
				DECLARE @DistributionMasterId BIGINT;
				DECLARE @DistributionCode VARCHAR(200);
				DECLARE @EXShipment VARCHAR(200) = 'EX-Shipment';

				-- Step 1: Handle Customer Shipping
				IF @IsCustomerShipping = 1
				BEGIN
					SET @CustomerDomensticShippingShipViaId = @ShipViaId;
					SET @ShipViaId = @CustomerDomensticShippingShipViaId;
				END
				ELSE
				BEGIN
					SET @CustomerDomensticShippingShipViaId = 0;
				END

				IF (@ExchangeSalesOrderShippingId > 0)
				BEGIN
					-- Update
					UPDATE [dbo].[ExchangeSalesOrderShipping]
					SET UpdatedDate = GETUTCDATE(),
						ShipviaId = @ShipViaId,
						CustomerDomensticShippingShipViaId = @CustomerDomensticShippingShipViaId,
						UpdatedBy = @CreatedBy
					WHERE ExchangeSalesOrderShippingId = @ExchangeSalesOrderShippingId;

					IF (@PackagingSlipId IS NOT NULL AND @PackagingSlipId > 0)
					BEGIN
						UPDATE [dbo].[ExchangeSalesOrderPackaginSlipItems]
						SET PDFPath = NULL
						WHERE PackagingSlipId = @PackagingSlipId;
					END

					IF(@ExchangeSalesOrderShippingId IS NOT NULL AND @ExchangeSalesOrderShippingId > 0)
					BEGIN
						UPDATE [dbo].[ExchangeSalesOrderShippingItem]
						SET PDFPath = NULL
						WHERE ExchangeSalesOrderShippingId = @ExchangeSalesOrderShippingId
						AND ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId;
					END

				END
				ELSE
				BEGIN
					-- Fetch ExchangeSalesOrderShippingCodeData
					SELECT TOP 1 * INTO #exsoCodeData FROM [dbo].[CodePrefixes] WITH(NOLOCK) 
					WHERE CodePrefix = @ExchangeSalesOrderShippingPrefix 
					AND MasterCompanyId = @MasterCompanyId
					AND ISNULL(IsActive,0) = 1 
					AND ISNULL(IsDeleted,0) = 0;
			
					IF EXISTS (SELECT 1 FROM #exsoCodeData)
					BEGIN
						IF(SELECT CurrentNummber FROM #exsoCodeData) > 0
						BEGIN
							SET @CurrentNumber = (SELECT CurrentNummber FROM #exsoCodeData) + 1;
						END
						ELSE
						BEGIN
							SET @CurrentNumber = (SELECT StartsFrom FROM #exsoCodeData) + 1;
						END

						-- Update soCodeData with new current number
						UPDATE [dbo].[CodePrefixes]
						SET CurrentNummber = @CurrentNumber
						WHERE CodePrefixId = (SELECT CodePrefixId FROM #exsoCodeData);

						-- Generate SalesOrderNumber
						DECLARE @SOShippingNum NVARCHAR(50);
						SET @SOShippingNum = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@CurrentNumber, (SELECT CodePrefix FROM #exsoCodeData), (SELECT CodeSufix FROM #exsoCodeData)));
						END	
						ELSE
						BEGIN
							-- Generate SalesOrderNumber without prefix/suffix
							SET @SOShippingNum = (SELECT * FROM [dbo].udfGenerateCodeNumber(0, '', ''));
						END

					-- ===========================================
					-- INSERT NEW SHIPPING RECORD
					-- ===========================================
					INSERT INTO [dbo].[ExchangeSalesOrderShipping]
					   ([ExchangeSalesOrderId]
					   ,[SOShippingNum]
					   ,[SOShippingStatusId]
					   ,[OpenDate]
					   ,[CustomerId]
					   ,[ShipViaId]
					   ,[ShipDate]
					   ,[AirwayBill]
					   ,[HouseAirwayBill]
					   ,[TrackingNum]
					   ,[Weight]
					   ,[SoldToName]
					   ,[SoldToAddress1]
					   ,[SoldToAddress2]
					   ,[SoldToCity]
					   ,[SoldToState]
					   ,[SoldToZip]
					   ,[SoldToCountryId]
					   ,[ShipToName]
					   ,[ShipToSiteName]
					   ,[ShipToSiteId]
					   ,[ShipToAddress1]
					   ,[ShipToAddress2]
					   ,[ShipToCity]
					   ,[ShipToState]
					   ,[ShipToZip]
					   ,[ShipToCountryId]
					   ,[OriginName]
					   ,[OriginAddress1]
					   ,[OriginAddress2]
					   ,[OriginCity]
					   ,[OriginState]
					   ,[OriginZip]
					   ,[OriginCountryId]
					   ,[Shipment]
					   ,[SoldToSiteId]
					   ,[SoldToSiteName]
					   ,[SoldToCountryName]
					   ,[ShipToCustomerId]
					   ,[ShipToCountryName]
					   ,[OriginCountryName]
					   ,[OriginSiteId]
					   ,[IsSameForShipTo]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[IsActive]
					   ,[IsDeleted]
					   ,[ShipSizeLength]
					   ,[ShipSizeWidth]
					   ,[ShipSizeHeight]
					   ,[ShipWeightUnit]
					   ,[ShipSizeUnitOfMeasureId]
					   ,[ServiceClass]
					   ,[NoOfContainer]
					   ,[ShippingAccountNo]
					   ,[CustomerDomensticShippingShipViaId]
					   ,[NoOfItems]
					   ,[IsCustomerShipping]
					   ,[IsManualShipping]
					   ,[ManufactureCountryId]
					   ,[QtyUOM]
					   ,[UnitPrice]
					   ,[UnitPriceCurrencyId]
					   ,[PackagingSlipNotes]
					   )
				   VALUES
					   (
					    @ExchangeSalesOrderId
					   ,@SOShippingNum
					   ,@SOShippingStatusId
					   ,@OpenDate
					   ,@CustomerId
					   ,@ShipViaId
					   ,@ShipDate
					   ,@AirwayBill
					   ,@HouseAirwayBill
					   ,@TrackingNum
					   ,@Weight
					   ,@SoldToName
					   ,@SoldToAddress1
					   ,@SoldToAddress2
					   ,@SoldToCity
					   ,@SoldToState
					   ,@SoldToZip
					   ,@SoldToCountryId
					   ,@ShipToName
					   ,@ShipToSiteName
					   ,@ShipToSiteId
					   ,@ShipToAddress1
					   ,@ShipToAddress2
					   ,@ShipToCity
					   ,@ShipToState
					   ,@ShipToZip
					   ,@ShipToCountryId
					   ,@OriginName
					   ,@OriginAddress1
					   ,@OriginAddress2
					   ,@OriginCity
					   ,@OriginState
					   ,@OriginZip
					   ,@OriginCountryId
					   ,NULL
					   ,@SoldToSiteId
					   ,@SoldToSiteName
					   ,@SoldToCountryName
					   ,@ShipToCustomerId
					   ,@ShipToCountryName
					   ,@OriginCountryName
					   ,@OriginSiteId
					   ,@IsSameForShipTo
					   ,@MasterCompanyId
					   ,@CreatedBy
					   ,@CreatedBy
					   ,GETUTCDATE()
					   ,GETUTCDATE()
					   ,1
					   ,0
					   ,@ShipSizeLength
					   ,@ShipSizeWidth
					   ,@ShipSizeHeight
					   ,@ShipWeightUnit
					   ,@ShipSizeUnitOfMeasureId
					   ,NULL
					   ,@NoOfContainer
					   ,@ShippingAccountNo
					   ,@CustomerDomensticShippingShipViaId
					   ,@NoOfItems
					   ,@IsCustomerShipping
					   ,@IsManualShipping
					   ,@ManufactureCountryId
					   ,@QtyUOM
					   ,@UnitPrice
					   ,@UnitPriceCurrencyId
					   ,@PackagingSlipNotes
					  )

				   SET @ExchangeSalesOrderShippingId = SCOPE_IDENTITY();
				   SET @IsAdd = 1;

				   INSERT INTO [dbo].[ExchangeSalesOrderShippingItem]
				   ([ExchangeSalesOrderShippingId]
				   ,[ExchangeSalesOrderPartId]
				   ,[QtyShipped]
				   ,[SOPickTicketId]
				   ,[MasterCompanyId]
				   ,[CreatedBy]
				   ,[UpdatedBy]
				   ,[CreatedDate]
				   ,[UpdatedDate]
				   ,[IsActive]
				   ,[IsDeleted]
				   ,[PDFPath]
				   ,[FedexPdfPath])
					VALUES
					(
					 @ExchangeSalesOrderShippingId
					,@ExchangeSalesOrderPartId
					,@QtyShipped
					,@SOPickTicketId
					,@MasterCompanyId
					,@CreatedBy
					,@CreatedBy
					,GETUTCDATE()
					,GETUTCDATE()
					,1
					,0
					,NULL
					,NULL
					)
				END

				-- Step 3: Handle Distribution (simplified trigger logic placeholder)
				IF @IsAdd = 1
				BEGIN
					SELECT TOP 1 @DistributionMasterId = ID ,  @DistributionCode = DistributionCode FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE DistributionCode = @EXShipment;

					DECLARE @validDistribution INT;
					SELECT @validDistribution = COUNT(1)
					FROM [dbo].[DistributionSetup] WITH(NOLOCK)
					WHERE DistributionMasterId = @DistributionMasterId
					  AND MasterCompanyId = @MasterCompanyId
					  AND GlAccountId = 0
					  AND ISNULL(IsManualText,0) = 0;

					   IF (@validDistribution = 0)
						BEGIN
							EXEC dbo.USP_BatchTriggerBasedonEXSOInvoice
								 @DistributionMasterId = @DistributionMasterId,
								 @ReferenceId = @ExchangeSalesOrderId,
								 @ReferencePartId = @ExchangeSalesOrderPartId, -- needs shippingItems TVP to pass correct partId
								 @ReferencePieceId = 0,
								 @InvoiceId = @ExchangeSalesOrderShippingId,
								 @StocklineId = 0,
								 @Qty = 0,
								 @Amount = 0,
								 @ModuleName = 'ExchangeSO',
								 @MasterCompanyId = @MasterCompanyId,
								 @UpdateBy = @CreatedBy;
						END

					-- Call Accounting bypass SP
					DECLARE @IsRestrict BIT = 0, @IsAccountByPass BIT = 0;

					EXEC [dbo].[USP_GetSubLadgerGLAccountRestriction]
					@DistributionCode = @DistributionCode,
					@MasterCompanyId = @MasterCompanyId,
					@AccountingCalendarId = 0,
					@UpdateBy = @CreatedBy,
					@IsRestrict = @IsRestrict OUTPUT,
					@IsAccountByPass = @IsAccountByPass OUTPUT;

				END
				 -- Step 4: Update ShipToCustomer
				SELECT s.*,
				   CASE 
					   WHEN so.IsVendor = 1 
							THEN (SELECT VendorName FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = s.ShipToCustomerId)
					   ELSE (SELECT Name FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = s.ShipToCustomerId)
				   END AS ShipToCustomer,
				   '' AS ShippingSuccess,
				   '' AS FedexSuccess,
				   '' AS FedexError
				FROM [dbo].[ExchangeSalesOrderShipping] s WITH(NOLOCK)
				INNER JOIN [dbo].[ExchangeSalesOrder] so WITH(NOLOCK) ON so.ExchangeSalesOrderId = s.ExchangeSalesOrderId
				WHERE s.ExchangeSalesOrderShippingId = @ExchangeSalesOrderShippingId;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateExchangeSalesOrderShipping'   
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ExchangeSalesOrderShippingId, '') AS varchar(100) ) + ''',
													@Parameter2 = '''+ CAST(ISNULL(@ExchangeSalesOrderId, '') AS varchar(100) ) + ''',
													@Parameter3 = '''+ CAST(ISNULL(@IsCustomerShipping, '') AS varchar(100) ) + ''',
													@Parameter4 = '''+ CAST(ISNULL(@ShipviaId, '') AS varchar(100) ) + ''',
													@Parameter5 = '''+ CAST(ISNULL(@CustomerDomensticShippingShipViaId , '') AS varchar(100) ) + ''',
													@Parameter6 = '''+ CAST(ISNULL(@CreatedBy , '') AS varchar(100) ) + ''',
													@Parameter7 = '''+ CAST(ISNULL(@SOShippingStatusId, '') AS varchar(100) ) + ''',
													@Parameter8 = '''+ CAST(ISNULL(@OpenDate, '') AS varchar(100) ) + ''',
													@Parameter9 = '''+ CAST(ISNULL(@CustomerId, '') AS varchar(100) ) + ''',
													@Parameter10 = '''+ CAST(ISNULL(@ShipDate, '') AS varchar(100) ) + ''',
													@Parameter11 = '''+ CAST(ISNULL(@AirwayBill, '') AS varchar(100) ) + ''',
													@Parameter12 = '''+ CAST(ISNULL(@HouseAirwayBill, '') AS varchar(100) ) + ''',
													@Parameter13 = '''+ CAST(ISNULL(@TrackingNum, '') AS varchar(100) ) + ''',
													@Parameter14 = '''+ CAST(ISNULL(@Weight, '') AS varchar(100) ) + ''',
													@Parameter15 = '''+ CAST(ISNULL(@SoldToName , '') AS varchar(100) ) + ''',
													@Parameter16 = '''+ CAST(ISNULL(@SoldToAddress1, '') AS varchar(100) ) + ''',
													@Parameter17 = '''+ CAST(ISNULL(@SoldToAddress2, '') AS varchar(100) ) + ''',
													@Parameter18 = '''+ CAST(ISNULL(@SoldToCity, '') AS varchar(100) ) + ''',
													@Parameter19 = '''+ CAST(ISNULL(@SoldToState, '') AS varchar(100) ) + ''',
													@Parameter20 = '''+ CAST(ISNULL(@SoldToZip , '') AS varchar(100) ) + ''',
													@Parameter21 = '''+ CAST(ISNULL(@SoldToCountryId , '') AS varchar(100) ) + ''',
													@Parameter22 = '''+ CAST(ISNULL(@ShipToName, '') AS varchar(100) ) + ''',
													@Parameter23 = '''+ CAST(ISNULL(@ShipToSiteName, '') AS varchar(100) ) + ''',
													@Parameter24 = '''+ CAST(ISNULL(@ShipToSiteId , '') AS varchar(100) ) + ''',
													@Parameter25 = '''+ CAST(ISNULL(@ShipToAddress1 , '') AS varchar(100) ) + ''',
													@Parameter26 = '''+ CAST(ISNULL(@ShipToAddress2, '') AS varchar(100) ) + ''',
													@Parameter27 = '''+ CAST(ISNULL(@ShipToCity , '') AS varchar(100) ) + ''',
													@Parameter28 = '''+ CAST(ISNULL(@ShipToState , '') AS varchar(100) ) + ''',
													@Parameter29 = '''+ CAST(ISNULL(@ShipToZip , '') AS varchar(100) ) + ''',
													@Parameter31 = '''+ CAST(ISNULL(@ShipToCountryId, '') AS varchar(100) ) + ''',
													@Parameter32 = '''+ CAST(ISNULL(@OriginName, '') AS varchar(100) ) + ''',
													@Parameter33 = '''+ CAST(ISNULL(@OriginAddress1, '') AS varchar(100) ) + ''', 
													@Parameter34 = '''+ CAST(ISNULL(@OriginAddress2, '') AS varchar(100) ) + ''', 
													@Parameter35 = '''+ CAST(ISNULL(@OriginCity, '') AS varchar(100) ) + ''', 
													@Parameter36 = '''+ CAST(ISNULL(@OriginState, '') AS varchar(100) ) + ''', 
													@Parameter37 = '''+ CAST(ISNULL(@OriginZip, '') AS varchar(100) ) + ''', 
													@Parameter38 = '''+ CAST(ISNULL(@OriginCountryId, '') AS varchar(100) ) + ''', 
													@Parameter39 = '''+ CAST(ISNULL(@SoldToSiteId, '') AS varchar(100) ) + ''', 
													@Parameter40 = '''+ CAST(ISNULL(@SoldToSiteName, '') AS varchar(100) ) + ''',
													@Parameter41 = '''+ CAST(ISNULL(@SoldToCountryName, '') AS varchar(100) ) + ''',
													@Parameter42 = '''+ CAST(ISNULL(@ShipToCustomerId, '') AS varchar(100) ) + ''',
													@Parameter43 = '''+ CAST(ISNULL(@ShipToCountryName, '') AS varchar(100) ) + ''',
													@Parameter44 = '''+ CAST(ISNULL(@OriginCountryName, '') AS varchar(100) ) + ''',
													@Parameter45 = '''+ CAST(ISNULL(@OriginSiteId, '') AS varchar(100) ) + ''',
													@Parameter46 = '''+ CAST(ISNULL(@IsSameForShipTo, '') AS varchar(100) ) + ''',
													@Parameter47 = '''+ CAST(ISNULL(@MasterCompanyId, '') AS varchar(100) ) + ''',
													@Parameter48 = '''+ CAST(ISNULL(@ShipSizeLength, '') AS varchar(100) ) + ''',
													@Parameter49 = '''+ CAST(ISNULL(@ShipSizeWidth, '') AS varchar(100) ) + ''',
													@Parameter50 = '''+ CAST(ISNULL(@ShipSizeHeight, '') AS varchar(100) ) + ''',
													@Parameter51 = '''+ CAST(ISNULL(@ShipWeightUnit, '') AS varchar(100) ) + ''',
													@Parameter52 = '''+ CAST(ISNULL(@ShipSizeUnitOfMeasureId, '') AS varchar(100) ) + ''',
													@Parameter53 = '''+ CAST(ISNULL(@NoOfContainer, '') AS varchar(100) ) + ''',
													@Parameter54 = '''+ CAST(ISNULL(@ShippingAccountNo, '') AS varchar(100) ) + ''',
													@Parameter55 = '''+ CAST(ISNULL(@NoOfItems, '') AS varchar(100) ) + ''',
													@Parameter56 = '''+ CAST(ISNULL(@IsManualShipping, '') AS varchar(100) ) + ''',
													@Parameter57 = '''+ CAST(ISNULL(@ManufactureCountryId, '') AS varchar(100) ) + ''',
													@Parameter58 = '''+ CAST(ISNULL(@QtyUOM, '') AS varchar(100) ) + ''',
													@Parameter59 = '''+ CAST(ISNULL(@UnitPrice, '') AS varchar(100) ) + ''',
													@Parameter60 = '''+ CAST(ISNULL(@UnitPriceCurrencyId, '') AS varchar(100) ) + ''',
													@Parameter61 = '''+ CAST(ISNULL(@PackagingSlipNotes, '') AS varchar(100) ) + ''',
													@Parameter62 = '''+ CAST(ISNULL(@ExchangeSalesOrderPartId, '') AS varchar(100) ) + ''',
													@Parameter63 = '''+ CAST(ISNULL(@QtyShipped, '') AS varchar(100) ) + ''',
													@Parameter64 = '''+ CAST(ISNULL(@SOPickTicketId, '') AS varchar(100) ) + ''

			,@ApplicationName VARCHAR(100) = 'PAS'    
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