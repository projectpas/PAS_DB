/*********************************************************************************************           
 ** File:   [USP_SaveWorkOrderPackaginSlip]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to save work order packaging slip details
 ** Date:   16-April-2025     
 *********************************************************************************************           
  ** Change History           
 *********************************************************************************************           
 ** PR   Date					Author					Change Description            
 ** --   --------				-------					--------------------------------          
    1    16-April-2025		 	Devendra Shekh			Created
***********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveWorkOrderPackaginSlip]
@tbl_WorkOrderPackaginSlipItemsType WorkOrderPackaginSlipItemsType READONLY,
@WorkOrderId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @PackingSlipCodePrefix INT;
		DECLARE @CurrentNo INT = 0,@PackagingSlipNo VARCHAR(50) = NULL;
		DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50);
		DECLARE @PackagingSlipId BIGINT = 0;
		DECLARE @TotalWOParts INT, @CurrentPartIndex INT, @WOPartNoId BIGINT;
		DECLARE @TotalWOShip INT, @CurrentShipIndex INT, @WorkOrderShippingId BIGINT, @AirwayBill VARCHAR(50);
		DECLARE @Parts_Shipped VARCHAR(200) = 'UNIT SHIPPED';

		IF OBJECT_ID(N'tempdb..#tmpWOPartNumber') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWOPartNumber
		END

		IF OBJECT_ID(N'tempdb..#tmpWorkOrderShipping') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWorkOrderShipping
		END

		CREATE TABLE #tmpWOPartNumber (
			[Id] BIGINT IDENTITY(1, 1) NOT NULL,
			[WOPartNoId] BIGINT NULL
		)

		CREATE TABLE #tmpWorkOrderShipping (
			[RecId] BIGINT IDENTITY(1, 1) NOT NULL,
			[WorkOrderShippingId] BIGINT NULL,
			[AirwayBill] VARCHAR(50) NULL
		)

		-- Code Types Of CodePrefix	
		SELECT @PackingSlipCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Packaging Slip';	
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @PackingSlipCodePrefix AND [MasterCompanyId] = @MasterCompanyId;

		-- Check for current number and increment
		IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
		BEGIN
			SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
			IF @CurrentNo > 0
			BEGIN
				SET @CurrentNo = @CurrentNo + 1;
				UPDATE [dbo].[CodePrefixes] 
				SET [CurrentNummber] = @CurrentNo
				WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
			END
			ELSE
			BEGIN
				SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
				UPDATE [dbo].[CodePrefixes]
				SET [CurrentNummber] = @CurrentNo 
				WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
			END
			-- Generate Number
			SET @PackagingSlipNo = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
		END
		ELSE
		BEGIN
			-- Generate Number
			SET @PackagingSlipNo = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
		END

		-- Saving Packaging Slip Header
		INSERT INTO [dbo].[WorkOrderPackaginSlipHeader] ([PackagingSlipNo], [WorkOrderId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
		VALUES (@PackagingSlipNo, @WorkOrderId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0)

		SET @PackagingSlipId = SCOPE_IDENTITY();

		-- Saving Packaging Slip Items
		INSERT INTO [dbo].[WorkOrderPackaginSlipItems]([PackagingSlipId], [WOPickTicketId], [WOPartNoId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PDFPath])
		SELECT @PackagingSlipId, [WOPickTicketId], [WOPartNoId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PDFPath]
		FROM @tbl_WorkOrderPackaginSlipItemsType

		-- update Parts_Shipped flag of settlment tab : Start
		INSERT INTO #tmpWOPartNumber ([WOPartNoId]) SELECT [WOPartNoId] FROM @tbl_WorkOrderPackaginSlipItemsType

		INSERT INTO #tmpWorkOrderShipping([WorkOrderShippingId], [AirwayBill]) SELECT [WorkOrderShippingId], [AirwayBill] FROM [dbo].[WorkOrderShipping] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

		SELECT @TotalWOParts = COUNT([Id]) FROM #tmpWOPartNumber;
		SELECT @TotalWOShip = COUNT([RecId]) FROM #tmpWorkOrderShipping;

		SET @CurrentPartIndex = 1;

		WHILE(ISNULL(@TotalWOParts, 0) >= ISNULL(@CurrentPartIndex, 0)) AND ((SELECT COUNT(RecId) FROM #tmpWorkOrderShipping) > 0)
		BEGIN

			SELECT @WOPartNoId = [WOPartNoId], @CurrentShipIndex = 1 FROM #tmpWOPartNumber WHERE [Id] = @CurrentPartIndex;

			WHILE(ISNULL(@TotalWOShip, 0) >= ISNULL(@CurrentShipIndex, 0))
			BEGIN

				SELECT @WorkOrderShippingId = [WorkOrderShippingId], @AirwayBill = [AirwayBill] FROM #tmpWorkOrderShipping WHERE [RecId] = @CurrentShipIndex;

				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderShippingItem] WITH(NOLOCK) WHERE [WorkOrderPartNumId] = @WOPartNoId AND [WorkOrderShippingId] = @WorkOrderShippingId) AND TRIM(ISNULL(@AirwayBill, '')) <> ''
				BEGIN

					UPDATE WSD
					SET WSD.IsMastervalue = 1, 
						WSD.Isvalue_NA = 0
					FROM [dbo].[WorkOrderSettlementDetails] WSD WITH(NOLOCK)
					WHERE [WorkOrderId] = @WorkOrderId AND [workOrderPartNoId] = @WOPartNoId 
					AND [WorkOrderSettlementId] = (SELECT [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WS WITH(NOLOCK) WHERE UPPER([WorkOrderSettlementName]) = @Parts_Shipped)

				END

				SET @CurrentShipIndex += 1;
			END
			
			SET @CurrentPartIndex += 1;
		END
		-- update Parts_Shipped flag of settlment tab : End

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH 
		IF @@trancount > 0
        ROLLBACK TRAN;

		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveWorkOrderPackaginSlip'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH
END