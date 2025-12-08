/*************************************************************           
 ** File:   [usp_SaveVendorRFQFromEmail]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used save the Vendor RFQs Received on Email
 ** Purpose:         
 ** Date:   05 Dec 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1	 05 Dec 2025		Devendra Shekh		Created
	2	 08 Dec 2025		Devendra Shekh		Modified to save IntegrationEmailID to [VendorRFQPart] And [ThirdPartyRFQId] to [IntegrationEmail]

************************************************************************/
CREATE   PROCEDURE [dbo].[usp_SaveVendorRFQFromEmail]
	@IntegrationEmailID BIGINT = NULL,
    @tbl_VendorRFQType dbo.VendorRFQType READONLY,
    @tbl_VendorPartRFQType dbo.VendorPartRFQType READONLY,
	@EmployeeId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	--BEGIN TRANSACTION;
	BEGIN TRY
	BEGIN
		IF EXISTS(SELECT 1 FROM @tbl_VendorPartRFQType)
		BEGIN
			DECLARE @CreatedBy VARCHAR(100), @MasterCompanyId INT;
			DECLARE @ILSRFQDetailId BIGINT, @VendorId BIGINT, @ThirdPartyRFQId BIGINT = NULL;

			IF OBJECT_ID(N'tempdb..#tmpVendorRfq') IS NOT NULL
			BEGIN
				DROP TABLE #tmpVendorRfq
			END

			CREATE TABLE #tmpVendorRfq
			(
				[ID] BIGINT NOT NULL IDENTITY, 
				[VendorRFQNumber] VARCHAR(200) NULL,
				[VendorName] VARCHAR(200) NULL,
				[Email] VARCHAR(255) NULL,
				[Phone] VARCHAR(50) NULL,
				[Address1] VARCHAR(500) NULL,
				[Address2] VARCHAR(500) NULL,
				[City] VARCHAR(100) NULL,
				[StateProvince] VARCHAR(100) NULL,
				[PostalCode] VARCHAR(50) NULL,
				[Country] VARCHAR(100) NULL,
				[IntegrationEmailID] BIGINT NULL,
				[ItemId] BIGINT NULL,
				[ItemSupplierPartId] BIGINT NULL,
				[PartNumber] VARCHAR(150) NULL,
				[RfqId] VARCHAR(400) NULL,
				[Description] NVARCHAR(MAX) NULL,
				[AltPartNumber] VARCHAR(150) NULL,
				[ReferenceNumber] VARCHAR(200) NULL,
				[Traceability] VARCHAR(200) NULL,
				[UnitOfMeasure] VARCHAR(100) NULL,
				[Price] DECIMAL(18,4) NULL,
				[PriceType] VARCHAR(100) NULL,
				[LeadTime] VARCHAR(100) NULL,
				[Qty] INT NULL,
				[RequestedQty] INT NULL,
				[MinQuantity] INT NULL,
				[Condition] VARCHAR(50) NULL,
				[Notes] VARCHAR(MAX) NULL
			)
			
			SELECT @CreatedBy = [CreatedBy], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[IntegrationEmail] WITH(NOLOCK) WHERE [IntegrationEmailID] = @IntegrationEmailID;
			
			SELECT @ILSRFQDetailId = RFQD.ILSRFQDetailId, @ThirdPartyRFQId = RFQD.ThirdPartyRFQId FROM [dbo].[ILSRFQDetail] RFQD WITH(NOLOCK)
			INNER JOIN [dbo].[ThirdPartyRFQ] TP WITH(NOLOCK) ON RFQD.ThirdPartyRFQId = TP.ThirdPartyRFQId
			WHERE TP.[RFQId] = (SELECT TOP 1 [VendorRFQNumber] FROM @tbl_VendorRFQType) AND TP.MasterCompanyId = @MasterCompanyId

			IF(ISNULL(@EmployeeId, 0) = 0)
			BEGIN
				IF EXISTS(SELECT 1 FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(EmployeeId, 0) > 0)
				BEGIN
					SET @EmployeeId = (SELECT TOP 1 EmployeeId FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND ISNULL(EmployeeId, 0) > 0)
				END
				ELSE IF EXISTS(SELECT 1 FROM [dbo].[Employee] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND UPPER(TRIM([FirstName])) = 'ADMIN')
				BEGIN
					SET @EmployeeId = (SELECT TOP 1 EmployeeId FROM [dbo].[Employee] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0 AND UPPER(TRIM([FirstName])) = 'ADMIN')
				END
			END

			IF(ISNULL(@EmployeeId, 0) > 0)
			BEGIN
				SELECT @CreatedBy = CONCAT(FirstName, ' ' , LastName) FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId;
			END
			
			-- Saving Part Details to Temp Table
			INSERT INTO #tmpVendorRfq (
				[ItemId], [ItemSupplierPartId], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure],
				[Price], [PriceType], [LeadTime], [Qty], [RequestedQty], [MinQuantity], [Condition], [Notes], [IntegrationEmailID]
			)
			SELECT	[ItemId], [ItemSupplierPartId], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure],
					[Price], [PriceType], [LeadTime], [Qty], [RequestedQty], [MinQuantity], [Condition], [Notes], [IntegrationEmailID]
			FROM @tbl_VendorPartRFQType;

			-- Updating Vendor/Email Sender Details
			UPDATE TMP
			SET	
				TMP.[VendorName] = CU.[VendorName],
				TMP.[Address1] = CU.[Address1],
				TMP.[Address2] = CU.[Address2],
				TMP.[City] = CU.[City],
				TMP.[StateProvince] = CU.[StateProvince],
				TMP.[PostalCode] = CU.[PostalCode],
				TMP.[Country] = CU.[Country],
				TMP.[Email] = CU.[Email],
				TMP.[Phone] = CU.[Phone]
			FROM #tmpVendorRfq TMP
			INNER JOIN @tbl_VendorRFQType CU ON TMP.[IntegrationEmailID] = CU.[IntegrationEmailID];

			SELECT TOP 1 @VendorId = VN.VendorId FROM [dbo].[Vendor] VN WITH(NOLOCK) 
			INNER JOIN @tbl_VendorRFQType TMP ON UPPER(TRIM(TMP.VendorName)) = UPPER(TRIM(VN.VendorName)) AND VN.MasterCompanyId = @MasterCompanyId

			-- Insert into Rfq table
			INSERT INTO [dbo].[VendorRFQPart]
			(	
				[ILSRFQDetailId], [ItemId], [ItemSupplierPartId], [VendorName], [VendorId], [Email], [Phone], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure], [Price], [PriceType], [LeadTime], 
				[Qty], [RequestedQty], [MinQuantity], [Condition], [Address1], [Address2], [City], [Country], [PostalCode], [StateProvince], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsDeleted], [IsActive], [IntegrationEmailID]
			)
			SELECT	@ILSRFQDetailId, [ItemId], [ItemSupplierPartId], [VendorName], @VendorId, [Email], [Phone], [PartNumber], [RfqId], [Description], [AltPartNumber], [ReferenceNumber], [Traceability], [UnitOfMeasure], [Price], [PriceType], [LeadTime], 
					[Qty], [RequestedQty], [MinQuantity], [Condition], [Address1], [Address2], [City], [Country], [PostalCode], [StateProvince], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 0, 1, @IntegrationEmailID
			FROM #tmpVendorRfq;
		END

		UPDATE [DBO].[IntegrationEmail] SET [IsProcessed] = 1, [ThirdPartyRFQId] = @ThirdPartyRFQId WHERE IntegrationEmailID = @IntegrationEmailID;
	END		
	--COMMIT
	END TRY	
	BEGIN CATCH      
		--IF @@trancount > 0
		--	ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_SaveVendorRFQFromEmail' 
		, @ProcedureParameters VARCHAR(3000) = '@IntegrationEmailID = ''' + CAST(ISNULL(@IntegrationEmailID, '') as varchar(100))
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