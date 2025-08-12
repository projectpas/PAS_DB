/*************************************************************           
 ** File:   [usp_SaveEmailRFQ]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used save the RFQs Received on Email
 ** Purpose:         
 ** Date:   06 Aug 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    06 Aug 2025	Devendra Shekh		Created
    2    07 Aug 2025	Devendra Shekh		Added Changes for PartDetails Insert and RFQNumber Generate

************************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveEmailRFQ]
	@IntegrationEmailID BIGINT = NULL,
    @tbl_RfqCustomerType dbo.RfqCustomerType READONLY,
    @tbl_RfqPartDetailType dbo.RfqPartDetailType READONLY
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	--BEGIN TRANSACTION;
	BEGIN TRY
	BEGIN
		DECLARE @CustomerRfqId BIGINT;

		IF EXISTS(SELECT 1 FROM @tbl_RfqPartDetailType)
		BEGIN
			DECLARE @CreatedBy VARCHAR(50), @MasterCompanyId INT;
			DECLARE @TotalRow INT, @CurrentRow INT = 1;
			DECLARE @CodeTypeId BIGINT, @CurrentNumber BIGINT = 0, @RFQNumber NVARCHAR(200);

			IF OBJECT_ID(N'tempdb..#tmpCodePrefix') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCodePrefix
			END

			IF OBJECT_ID(N'tempdb..#tmpCustomerRfq') IS NOT NULL
			BEGIN
				DROP TABLE #tmpCustomerRfq
			END

			CREATE TABLE #tmpCustomerRfq
			(
				ID BIGINT NOT NULL IDENTITY, 
				[RfqId] NVARCHAR(200) NULL,
				[RfqCreatedDate] [DATETIME2](7) NULL,
				[IntegrationPortalId] [int] NULL,
				[Type] [VARCHAR](50) NULL,
				[Notes] [VARCHAR](MAX) NULL,
				[BuyerName] [VARCHAR](250) NULL,
				[BuyerCompanyName] [VARCHAR](250) NULL,
				[BuyerAddress] [VARCHAR](250) NULL,
				[BuyerCity] [VARCHAR](50) NULL,
				[BuyerCountry] [VARCHAR](50) NULL,
				[BuyerState] [VARCHAR](50) NULL,
				[BuyerZip] [VARCHAR](50) NULL,
				[LinePartNumber] [VARCHAR](250) NULL,
				[LineDescription] [VARCHAR](500) NULL,
				[CreatedBy] [VARCHAR](50) NOT NULL,
				[CreatedDate] [datetime2](7) NOT NULL,
				[UpdatedBy] [VARCHAR](50) NOT NULL,
				[UpdatedDate] [DATETIME2](7) NOT NULL,
				[IsActive] [BIT] NOT NULL,
				[IsDeleted] [BIT] NOT NULL,
				[AltPartNumber] [VARCHAR](250) NULL,
				[Quantity] [int] NULL,
				[Condition] [varchar](50) NULL,
				[IsMRO] [bit] NULL,
				[IntegrationEmailID] [bigint] NULL
			)
			
			SELECT @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[IntegrationEmail] WITH(NOLOCK) WHERE [IntegrationEmailID] = @IntegrationEmailID;
			SELECT TOP 1 @CodeTypeId = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'CustomerRFQ';
			SELECT TOP 1 * INTO #tmpCodePrefix FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0 AND [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;
			
			-- Determine the current number
			IF EXISTS (SELECT 1 FROM #tmpCodePrefix)
			BEGIN
				IF (SELECT CurrentNummber FROM #tmpCodePrefix) > 0
				BEGIN
					SET @CurrentNumber = (SELECT CurrentNummber FROM #tmpCodePrefix);
				END
				ELSE
				BEGIN
					SET @CurrentNumber = CASE WHEN (SELECT StartsFrom FROM #tmpCodePrefix) > 0 THEN (SELECT StartsFrom FROM #tmpCodePrefix) ELSE (SELECT StartsFrom FROM #tmpCodePrefix) + 1 END;
				END				

				-- Generate CustomerRFQNumber
				SET @RFQNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](@CurrentNumber, (SELECT CodePrefix FROM #tmpCodePrefix), (SELECT CodeSufix FROM #tmpCodePrefix)));
			END
			ELSE
			BEGIN
				-- Generate CustomerRFQNumber without prefix/suffix
				SET @RFQNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](0, '', ''));
			END
			
			-- Saving Part Details to Temp Table
			INSERT INTO #tmpCustomerRfq ([RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity],
			[BuyerCountry], [BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],
			[AltPartNumber], [Quantity], [Condition], [IsMRO], [IntegrationEmailID])
			SELECT	@RFQNumber, GETUTCDATE(), [IntegrationPortalId], [Type], [Notes], '', '', '', '',
					'', '', '', [PartNumber], [PartDescription], @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0,
					[AlternatePart], [Quantity], [Condition], ISNULL([IsMRO], 1), [IntegrationEmailID]
			FROM @tbl_RfqPartDetailType;

			-- Updating Customer/Email Sender Details
			UPDATE TMP
			SET	
				TMP.[BuyerName] = CU.[BuyerName],
				TMP.[BuyerCompanyName] = CU.[CompanyName],
				TMP.[BuyerAddress] = CU.[Address],
				TMP.[BuyerCity] = CU.[City],
				TMP.[BuyerState] = CU.[State],
				TMP.[BuyerZip] = CU.[Zip],
				TMP.[BuyerCountry] = CU.[Country]
			FROM #tmpCustomerRfq TMP
			INNER JOIN @tbl_RfqCustomerType CU ON TMP.[IntegrationEmailID] = CU.[IntegrationEmailID];

			-- Insert into Rfq table
			INSERT INTO [dbo].[CustomerRfq]
			(	[RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], [BuyerState],
				[BuyerZip], [LinePartNumber], [LineDescription], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
				[AltPartNumber], [Quantity], [Condition], [IsMRO])
			SELECT	[RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], [BuyerState],
					[BuyerZip], [LinePartNumber], [LineDescription], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
					[AltPartNumber], [Quantity], [Condition], [IsMRO]
			FROM #tmpCustomerRfq WHERE ID = @CurrentRow;

			SET @CustomerRfqId = SCOPE_IDENTITY();

			IF(ISNULL(@CustomerRfqId, 0) > 0)
			BEGIN
				-- Save CustomerRFQ Part Details
				INSERT INTO [dbo].[CustomerRfqPartMapping] 
				(	[CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]) 
				SELECT	@CustomerRfqId, [Notes], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], @MasterCompanyId, @CreatedBy,  GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
				FROM #tmpCustomerRfq;

				-- Update CodeData with new current number
				UPDATE [dbo].[CodePrefixes]	SET [CurrentNummber] = @CurrentNumber + 1	WHERE [CodePrefixId] = (SELECT CodePrefixId FROM #tmpCodePrefix);
			END
		END

		UPDATE [DBO].[IntegrationEmail] SET [CustomerRfqId] = @CustomerRfqId WHERE IntegrationEmailID = @IntegrationEmailID;
	END		
	--COMMIT
	END TRY	
	BEGIN CATCH      
		--IF @@trancount > 0
		--	ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_AssignEmployeeToRFQs' 
		, @ProcedureParameters VARCHAR(3000) = '@EmployeeId = ''' + CAST(ISNULL(@IntegrationEmailID, '') as varchar(100))
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