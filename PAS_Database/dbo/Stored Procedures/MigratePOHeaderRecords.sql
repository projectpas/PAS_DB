/*************************************************************             
 ** File:   [MigratePOHeaderRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate KIT Item Master Records
 ** Purpose:           
 ** Date:   12/12/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    12/12/2023   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigratePOHeaderRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigratePOHeaderRecords]
(
	@FromMasterComanyID INT = NULL,
	@UserName VARCHAR(100) NULL,
	@Processed INT OUTPUT,
	@Migrated INT OUTPUT,
	@Failed INT OUTPUT,
	@Exists INT OUTPUT
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @LoopID AS INT;

		IF OBJECT_ID(N'tempdb..#TempPOHeader') IS NOT NULL
		BEGIN
			DROP TABLE #TempPOHeader
		END

		CREATE TABLE #TempPOHeader
		(
			ID bigint NOT NULL IDENTITY,
			[POHeaderId] [bigint] NOT NULL,
			[PONumber] VARCHAR(100) NULL,
			[VendorId] [bigint] NULL,
			[CurrencyId] [bigint] NULL,
			[ShipViaCodeId] [bigint] NULL,
			[TermsCondtionId] [bigint] NULL,
			[UserId] [bigint] NULL,
			[Attention] VARCHAR(250) NULL,
			[CompanyRefNumber] VARCHAR(250) NULL,
			[EntryDate] Datetime2(7) NULL,
			[FaxNumber] VARCHAR(100) NULL,
			[HistoricalFlag] VARCHAR(10) NULL,
			[Notes] VARCHAR(500) NULL,
			[TotalCost] decimal(18, 2) NULL,
			[OpenFlag] VARCHAR(100) NULL,
			[PhoneNumber] VARCHAR(100) NULL,
			[RecDate] Datetime2(7) NULL,
			[Remarks] VARCHAR(250) NULL,
			[ResaleFlag] VARCHAR(10) NULL,
			[VendorAddress1] VARCHAR(250) NULL,
			[VendorAddress2] VARCHAR(250) NULL,
			[VendorAddress3] VARCHAR(250) NULL,
			[VendorAddress4] VARCHAR(250) NULL,
			[VendorAddress5] VARCHAR(250) NULL,
			[ShipAddress1] VARCHAR(250) NULL,
			[ShipAddress2] VARCHAR(250) NULL,
			[ShipAddress3] VARCHAR(250) NULL,
			[ShipAddress4] VARCHAR(250) NULL,
			[ShipAddress5] VARCHAR(250) NULL,
			[ShipDate] Datetime2(7) NULL,
			[FOB] VARCHAR(100) NULL,
			[EmailAddress] VARCHAR(100) NULL,
			[PoShipDate] Datetime2(7) NULL,
			[DeferredRec] VARCHAR(100) NULL,
			[DATE_CREATED] Datetime2(7) NULL,
			[Date_Modified] Datetime2(7) NULL,
			[Priority] INT NULL,
			[MasterCompanyId] BIGINT NULL,
			[Migrated_Id] BIGINT NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempPOHeader ([POHeaderId],[PONumber],[VendorId],[CurrencyId],[ShipViaCodeId],[TermsCondtionId],[UserId],[Attention],[CompanyRefNumber],[EntryDate],[FaxNumber],[HistoricalFlag],
		[Notes],[TotalCost],[OpenFlag],[PhoneNumber],[RecDate],[Remarks],[ResaleFlag],[VendorAddress1],[VendorAddress2],[VendorAddress3],[VendorAddress4],[VendorAddress5],[ShipAddress1],[ShipAddress2],
		[ShipAddress3],[ShipAddress4],[ShipAddress5],[ShipDate],[FOB],[EmailAddress],[PoShipDate],[DeferredRec],[DATE_CREATED],[Date_Modified],[Priority],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [POHeaderId],[PONumber],[VendorId],[CurrencyId],[ShipViaCodeId],[TermsCondtionId],[UserId],[Attention],[CompanyRefNumber],[EntryDate],[FaxNumber],[HistoricalFlag],
		[Notes],[TotalCost],[OpenFlag],[PhoneNumber],[RecDate],[Remarks],[ResaleFlag],[VendorAddress1],[VendorAddress2],[VendorAddress3],[VendorAddress4],[VendorAddress5],[ShipAddress1],[ShipAddress2],
		[ShipAddress3],[ShipAddress4],[ShipAddress5],[ShipDate],[FOB],[EmailAddress],[PoShipDate],[DeferredRec],[DATE_CREATED],[Date_Modified],[Priority],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[PurchaseOrderHeaders] POH WITH (NOLOCK) WHERE POH.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempPOHeader;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @SVC_AUTO_KEY BIGINT = 0;
			DECLARE @TMC_AUTO_KEY BIGINT = 0;
			DECLARE @CMP_AUTO_KEY BIGINT = 0;
			DECLARE @POModuleId BIGINT = 0;	
			DECLARE @VendorModuleId INT = 0;
			DECLARE @countries_id BIGINT = 0;
			DECLARE @VendorId BIGINT = 0;
			DECLARE @VendorName VARCHAR(200) = '';
			DECLARE @VendorCode VARCHAR(200) = '';
			DECLARE @CreditLimit DECIMAL(18, 2) = 0;
			DECLARE @VendorContactId BIGINT = 0;
			DECLARE @ContactId BIGINT = 0;
			DECLARE @VendorContactName VARCHAR(200) = '';
			DECLARE @VendorContactPhone VARCHAR(200) = '';
			DECLARE @CreditTermsId BIGINT = 0;
			DECLARE @TemrsName VARCHAR(200) = '';
			DECLARE @StatusId BIGINT = 0;
			DECLARE @ManagementStructureId BIGINT = 0;
			DECLARE @ManagementStructureTypeId BIGINT = 0;
			DECLARE @DefaultUserId AS BIGINT = 0;
			DECLARE @Level1 VARCHAR(100) = '';
			DECLARE @POMSModuleId BIGINT;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';
			DECLARE @CurrentPurchaseOrderHeaderId BIGINT = 0;

			SELECT @CurrentPurchaseOrderHeaderId = POHeaderId, @SVC_AUTO_KEY = ShipViaCodeId, @TMC_AUTO_KEY = TermsCondtionId, @CMP_AUTO_KEY = VendorId FROM #TempPOHeader WHERE ID = @LoopID;
			SELECT @POModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';
			SELECT @VendorModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Vendor';			
			SELECT @countries_id = [countries_id] FROM [dbo].[Countries] WITH(NOLOCK) WHERE [MasterCompanyId] = @FromMasterComanyID AND [countries_name] = 'UNITED STATES';
			SELECT @DefaultUserId = U.EmployeeId FROM DBO.AspNetUsers U WHERE UserName like 'MIG-ADMIN' AND MasterCompanyId = @FromMasterComanyID;
			SELECT TOP 1 @ManagementStructureId = MS.ManagementStructureId FROM DBO.ManagementStructure MS WHERE [MasterCompanyId] = @FromMasterComanyID;
			SELECT @ManagementStructureTypeId = MST.TypeID FROM DBO.ManagementStructureType MST WHERE MST.[Description] = 'LE' AND MST.[MasterCompanyId] = @FromMasterComanyID;
			SELECT @Level1 = (MSL.Code + ' - ' + MSL.[Description]) FROM DBO.ManagementStructureLevel MSL WHERE MSL.TypeID = @ManagementStructureTypeId AND MSL.[MasterCompanyId] = @FromMasterComanyID;

			SELECT @VendorId = VendorId, @VendorName = VendorName, @VendorCode = V.VendorCode, @CreditLimit = V.CreditLimit FROM DBO.Vendor V WHERE UPPER(V.VendorCode) IN (SELECT UPPER(CMP.COMPANY_CODE) FROM [Quantum].QCTL_NEW_3.COMPANIES CMP Where CMP.CMP_AUTO_KEY = @CMP_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
			SELECT @VendorContactId = V.VendorContactId, @ContactId = V.ContactId FROM DBO.VendorContact V WHERE V.VendorId = @VendorId AND V.IsDefaultContact = 1 AND MasterCompanyId = @FromMasterComanyID;
			SELECT @VendorContactName = (C.FirstName + ' ' + C.LastName), @VendorContactPhone = C.WorkPhone FROM DBO.Contact C WHERE C.ContactId = @ContactId AND MasterCompanyId = @FromMasterComanyID;

			IF (ISNULL(@ManagementStructureId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Management Structure Id not found</p>'
			END
			IF (ISNULL(@Level1, '') = '')
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Level1 not found</p>'
			END
			IF (ISNULL(@DefaultUserId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Default User Id not found</p>'
			END
			IF (ISNULL(@VendorId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Vendor Id not found</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE POH
				SET POH.ErrorMsg = ErrorMsg
				FROM [Quantum_Staging].DBO.PurchaseOrderHeaders POH WHERE POH.POHeaderId = @CurrentPurchaseOrderHeaderId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedPurchaseOrderId BIGINT;

			IF (@FoundError = 0)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM [dbo].[PurchaseOrder] WITH(NOLOCK) WHERE PurchaseOrderNumber = (SELECT PO.PONumber FROM #TempPOHeader PO WHERE PO.ID = @LoopID) AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					SELECT @CreditTermsId = CreditTermsId, @TemrsName = [Name] FROM DBO.CreditTerms CT WHERE UPPER(CT.Name) IN (SELECT UPPER(T.TERM_CODE) FROM [Quantum].QCTL_NEW_3.TERM_CODES T Where T.TMC_AUTO_KEY = @TMC_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
					SELECT @StatusId = PS.POStatusId FROM DBO.POStatus PS WHERE UPPER(PS.Status) = 'Open';
					SELECT @ManagementStructureId = 30;

					INSERT INTO DBO.PurchaseOrder
					([PurchaseOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],[VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],
					[CreditTermsId],[Terms],[CreditLimit],[RequestedBy],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],[ApproverId],[ApprovedBy],[DateApproved],
					[POMemo],[Notes],[ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsEnforce],
					[PDFPath],[VendorRFQPurchaseOrderId],[FreightBilingMethodId],[TotalFreight],[ChargesBilingMethodId],[TotalCharges])
					SELECT PO.PONumber, CASE WHEN PO.EntryDate IS NOT NULL THEN CAST(PO.EntryDate AS datetime2) ELSE NULL END, NULL, CASE WHEN PO.PoShipDate IS NOT NULL THEN CAST(PO.PoShipDate AS datetime2) ELSE GETDATE() END, CASE WHEN PO.[PRIORITY] = 0 THEN (SELECT PriorityId FROM DBO.[Priority] WITH (NOLOCK) WHERE MasterCompanyId = @FromMasterComanyID AND UPPER([Description]) = 'ROUTINE') WHEN PO.[PRIORITY] = 1 THEN (SELECT PriorityId FROM DBO.[Priority] WITH (NOLOCK) WHERE MasterCompanyId = @FromMasterComanyID AND UPPER([Description]) = 'HIGH') END, CASE WHEN PO.[PRIORITY] = 1 THEN 'ROUTINE' WHEN PO.[PRIORITY] = 1 THEN 'HIGH' ELSE '' END, @VendorId, @VendorName, @VendorCode, @VendorContactId, @VendorContactName, @VendorContactPhone,
					@CreditTermsId, @TemrsName, @CreditLimit, @DefaultUserId, @UserName, @StatusId, 'Open', CASE WHEN PO.DATE_CREATED IS NOT NULL THEN CAST(PO.DATE_CREATED AS datetime2) ELSE NULL END, (CASE WHEN ISNULL(PO.ResaleFlag, 'F') = 'T' THEN 1 ELSE 0 END), (CASE WHEN ISNULL(PO.DeferredRec, 'F') = 'T' THEN 1 ELSE 0 END), NULL, NULL, NULL,
					NULL, PO.NOTES, @ManagementStructureId, @Level1, NULL, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0, 0,
					NULL, NULL, NULL, NULL, NULL, NULL
					FROM #TempPOHeader AS PO WHERE ID = @LoopID;

					SELECT @InsertedPurchaseOrderId = SCOPE_IDENTITY();

					SELECT @POMSModuleId = ManagementStructureModuleId FROM dbo.[ManagementStructureModule] WHERE ModuleName = 'POHeader';

					EXEC [dbo].[PROCAddPOMSData] @InsertedPurchaseOrderId, @ManagementStructureId, @FromMasterComanyID, @UserName, @UserName, @POMSModuleId, 1, 0;

					DECLARE @SHIP_ADDRESS1 NVARCHAR(MAX) = '';
					DECLARE @City NVARCHAR(100)='';
					DECLARE @StateAndPinCode NVARCHAR(100)='';
					DECLARE @State NVARCHAR(50)='';
					DECLARE @PostalCode NVARCHAR(50)='';
					DECLARE @ShippingAddressId BIGINT = 0;
					DECLARE @VendorShippingAddressId BIGINT;
					DECLARE @INSVendorShippingAddressId BIGINT;
					DECLARE @SiteName NVARCHAR(100) = '';
					DECLARE @VSAddressId BIGINT;
					DECLARE @VSContactId BIGINT;
					DECLARE @VSContactName VARCHAR(100) = '';
					DECLARE @VSLine1 NVARCHAR(MAX)='';
					DECLARE @VSLine2 NVARCHAR(MAX)='';
					DECLARE	@VSLine3 NVARCHAR(MAX)='';
					DECLARE	@VSCity VARCHAR(100)='';	
					DECLARE	@VSStateOrProvince VARCHAR(100)='';
					DECLARE @VSWorkPhone VARCHAR(100)='';
					DECLARE	@VSPostalCode VARCHAR(20)='';	
					DECLARE	@VSCountryId  BIGINT = 0
					DECLARE @VSCountryName VARCHAR(50)='';

					SELECT @SHIP_ADDRESS1 = PO.ShipAddress4 FROM #TempPOHeader AS PO WHERE ID = @LoopID;

					IF (@SHIP_ADDRESS1 IS NOT NULL)
					BEGIN
						SELECT @City = SUBSTRING(@SHIP_ADDRESS1,0,CHARINDEX(',',@SHIP_ADDRESS1,0)),@StateAndPinCode = SUBSTRING(@SHIP_ADDRESS1,CHARINDEX(',',@SHIP_ADDRESS1,0)+1,LEN(@SHIP_ADDRESS1));
						SELECT @StateAndPinCode = TRIM(@StateAndPinCode);
						SELECT @State = SUBSTRING(@StateAndPinCode, 0, CHARINDEX(' ', @StateAndPinCode, 0)), @PostalCode = SUBSTRING(@StateAndPinCode, CHARINDEX(' ', @StateAndPinCode, 0) + 1, LEN(@StateAndPinCode));
						
						INSERT INTO [dbo].[Address]([POBox],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Latitude],[Longitude],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						SELECT  NULL, PO.ShipAddress1, PO.ShipAddress2, PO.ShipAddress3, @City, @State, @PostalCode, @countries_id, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(),GETDATE(),1,0  FROM #TempPOHeader AS PO WHERE ID = @LoopID;
						
						SELECT @ShippingAddressId = IDENT_CURRENT('Address');
						
						INSERT INTO [dbo].[VendorShippingAddress]([VendorId],[AddressId],[IsPrimary],[SiteName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ContactTagId],[Attention])
						VALUES (@VendorId,@ShippingAddressId,0,@VendorName,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,NULL,NULL);
						
						SELECT @INSVendorShippingAddressId = IDENT_CURRENT('VendorShippingAddress');
						
						SELECT @VendorShippingAddressId = [VendorShippingAddressId], @SiteName = [SiteName], @VSAddressId = [AddressId] 
						FROM [dbo].[VendorShippingAddress] WITH(NOLOCK) WHERE [VendorShippingAddressId] = @INSVendorShippingAddressId;
						
						SELECT @VSContactId = VC.[ContactId], @VSContactName = (C.[FirstName] + ' ' + C.[LastName]), @VSWorkPhone = C.[WorkPhone] 
						FROM [dbo].[VendorContact] VC WITH(NOLOCK) INNER JOIN [dbo].[Contact] C WITH(NOLOCK) ON VC.ContactId = C.ContactId	
						WHERE VC.[VendorId] = @VendorId AND VC.[IsDefaultContact] = 1;
						
						SELECT @VSLine1 = AD.Line1, @VSLine2 = AD.Line2, @VSLine3 = AD.Line3, @VSCity = AD.City, @VSStateOrProvince = AD.StateOrProvince,
						@VSPostalCode = AD.PostalCode, @VSCountryId = AD.CountryId, @VSCountryName = CO.countries_name 
						FROM [dbo].[Address] AD WITH(NOLOCK) INNER JOIN [dbo].[Countries] CO WITH(NOLOCK) ON AD.[CountryId] = CO.[countries_id]
						WHERE [AddressId] = @ShippingAddressId;
						
						INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],[AddressId],[IsModuleOnly],
						[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],
						[CountryId],[Country],[MasterCompanyId],[CreatedBy] ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])
						VALUES(@InsertedPurchaseOrderId,@POModuleId,@VendorModuleId,'Vendor',@VendorId,@VendorName,@VendorShippingAddressId,@SiteName,@VSAddressId,0,
						1,NULL,'',@VSContactId,@VSContactName,@VSWorkPhone,@VSLine1,@VSLine2,@VSLine3,@VSCity,@VSStateOrProvince,@VSPostalCode,
						@VSCountryId,@VSCountryName,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,0);		

					END

					----------------------------------BILL TO ADDRESS-------------------------------------------------------------------------------- 

					DECLARE @BILL_ADDRESS1 NVARCHAR(MAX)='';	  
					DECLARE @BTCity NVARCHAR(100)='';
					DECLARE @BTStateAndPinCode NVARCHAR(100)='';
					DECLARE @BTState NVARCHAR(50)='';
					DECLARE @BTPostalCode NVARCHAR(50)='';
					DECLARE @BillingAddressId BIGINT;
					DECLARE @BTVendorBillingAddressId BIGINT;
					DECLARE @VendorBillingAddressId BIGINT;
					DECLARE @BTSiteName NVARCHAR(50)='';
					DECLARE @BTAddressId BIGINT;
					DECLARE @BTOLine1 NVARCHAR(MAX)='';
					DECLARE @BTOLine2 NVARCHAR(MAX)='';
					DECLARE	@BTOLine3 NVARCHAR(MAX)='';
					DECLARE	@BTOCity VARCHAR(100)='';	
					DECLARE	@BTOStateOrProvince VARCHAR(100)='';
					DECLARE	@BTOPostalCode VARCHAR(20)='';	
					DECLARE	@BTOCountryId  BIGINT = 0
					DECLARE @BTOCountryName VARCHAR(50)='';

					SELECT @BILL_ADDRESS1 = PO.VendorAddress4 FROM #TempPOHeader AS PO WHERE ID = @LoopID;

					IF (@BILL_ADDRESS1 IS NOT NULL)
					BEGIN
						SELECT @BTCity = SUBSTRING(@BILL_ADDRESS1,0,CHARINDEX(',',@BILL_ADDRESS1,0)), @BTStateAndPinCode = SUBSTRING(@BILL_ADDRESS1,CHARINDEX(',',@BILL_ADDRESS1,0)+1,LEN(@BILL_ADDRESS1));

						SELECT @BTStateAndPinCode = TRIM(@BTStateAndPinCode);

						SELECT @BTState = SUBSTRING(@BTStateAndPinCode,0,CHARINDEX(' ',@BTStateAndPinCode,0)), @BTPostalCode = SUBSTRING(@BTStateAndPinCode,CHARINDEX(' ',@BTStateAndPinCode,0)+1,LEN(@BTStateAndPinCode));
						
						INSERT INTO [dbo].[Address]([POBox],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Latitude],[Longitude],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						SELECT  NULL,PO.VendorAddress1, PO.VendorAddress2, PO.VendorAddress3, @BTCity, @BTState, @BTPostalCode, @countries_id, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0  FROM #TempPOHeader AS PO WHERE ID = @LoopID;

						SELECT @BillingAddressId = IDENT_CURRENT('Address');

						INSERT INTO [dbo].[VendorBillingAddress]([VendorId],[AddressId],[IsPrimary],[SiteName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsAddressForPayment],[ContactTagId],[Attention])
						VALUES(@VendorId, @BillingAddressId, 0, @VendorName, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0, 0, NULL, NULL)

						SELECT @BTVendorBillingAddressId = IDENT_CURRENT('VendorBillingAddress');
								   		
						SELECT @VendorBillingAddressId = [VendorBillingAddressId],@BTSiteName = [SiteName],@BTAddressId = [AddressId]
						FROM [dbo].[VendorBillingAddress] WITH(NOLOCK) WHERE [VendorBillingAddressId] = @BTVendorBillingAddressId 
			  
						SELECT  @BTOLine1 = AD.Line1,@BTOLine2 = AD.Line2,@BTOLine3 = AD.Line3,@BTOCity = AD.City,@BTOStateOrProvince = AD.StateOrProvince,@BTOPostalCode = AD.PostalCode,
						@BTOCountryId = AD.CountryId, @BTOCountryName = CO.countries_name 
						FROM [dbo].[Address] AD WITH(NOLOCK) INNER JOIN [dbo].[Countries] CO WITH(NOLOCK) ON AD.[CountryId] = CO.[countries_id]
						WHERE [AddressId] = @BillingAddressId;

						INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName]
							,[AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo]
							,[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId]
							,[CreatedBy] ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])
						VALUES(@InsertedPurchaseOrderId,@POModuleId,@VendorModuleId,'Vendor',@VendorId,@VendorName,@VendorBillingAddressId,@BTSiteName 
							,@BTAddressId,0,0,NULL,'',@VSContactId,@VSContactName,@VSWorkPhone
							,@BTOLine1,@BTOLine2,@BTOLine3,@BTOCity,@BTOStateOrProvince,@BTOPostalCode,@BTOCountryId,@BTOCountryName,@FromMasterComanyID
							,@UserName,@UserName,GETDATE(),GETDATE(),1,0,0);
					END

					UPDATE POH
					SET POH.Migrated_Id = @InsertedPurchaseOrderId,
					POH.SuccessMsg = 'Record migrated successfully'
					FROM [Quantum_Staging].DBO.PurchaseOrderHeaders POH WHERE POH.POHeaderId = @CurrentPurchaseOrderHeaderId;

					SET @MigratedRecords = @MigratedRecords + 1;
				END
				ELSE
				BEGIN
					UPDATE IMs
					SET IMs.ErrorMsg = ISNULL(ErrorMsg, '') + '<p>Purchase Order Header record already exists</p>'
					FROM [Quantum_Staging].DBO.ItemMasters IMs WHERE IMs.ItemMasterId = @CurrentPurchaseOrderHeaderId;

					SET @RecordExits = @RecordExits + 1;

					SELECT @InsertedPurchaseOrderId = (SELECT [PurchaseOrderId] FROM [dbo].[PurchaseOrder] WITH(NOLOCK) WHERE [PurchaseOrderNumber] = (SELECT PONumber FROM #TempPOHeader PO WHERE PO.ID = @LoopID) AND [MasterCompanyId] = @FromMasterComanyID)
					
					IF NOT EXISTS(SELECT 1 FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @InsertedPurchaseOrderId AND [ModuleId] = @POModuleId AND [MasterCompanyId] = @FromMasterComanyID)
					BEGIN
						SELECT @VendorId = VendorId, @VendorName = VendorName, @VendorCode = V.VendorCode, @CreditLimit = V.CreditLimit FROM DBO.Vendor V WHERE UPPER(V.VendorCode) IN (SELECT UPPER(CMP.COMPANY_CODE) FROM [Quantum].QCTL_NEW_3.COMPANIES CMP Where CMP.CMP_AUTO_KEY = @CMP_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
						SELECT @VendorContactId = V.VendorContactId, @ContactId = V.ContactId FROM DBO.VendorContact V WHERE V.VendorId = @VendorId AND V.IsDefaultContact = 1 AND MasterCompanyId = @FromMasterComanyID;
						SELECT @VendorContactName = (C.FirstName + ' ' + C.LastName), @VendorContactPhone = C.WorkPhone FROM DBO.Contact C WHERE C.ContactId = @ContactId AND MasterCompanyId = @FromMasterComanyID;
		
						SELECT @SHIP_ADDRESS1 = PO.ShipAddress4 FROM #TempPOHeader AS PO WHERE ID = @LoopID;
						IF (@SHIP_ADDRESS1 IS NOT NULL)
						BEGIN
							SELECT @City = SUBSTRING(@SHIP_ADDRESS1,0,CHARINDEX(',',@SHIP_ADDRESS1,0)), @StateAndPinCode = SUBSTRING(@SHIP_ADDRESS1,CHARINDEX(',',@SHIP_ADDRESS1,0)+1,LEN(@SHIP_ADDRESS1));						
							SELECT @StateAndPinCode = TRIM(@StateAndPinCode);
							SELECT @State= SUBSTRING(@StateAndPinCode,0,CHARINDEX(' ',@StateAndPinCode,0)), @PostalCode = SUBSTRING(@StateAndPinCode,CHARINDEX(' ',@StateAndPinCode,0)+1,LEN(@StateAndPinCode)); 
					
							INSERT INTO [dbo].[Address]([POBox],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Latitude],[Longitude],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])			
							SELECT NULL, PO.ShipAddress1, PO.ShipAddress2, PO.ShipAddress3, @City, @State, @PostalCode, @countries_id, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0  FROM #TempPOHeader AS PO WHERE ID = @LoopID;
							
							SELECT @ShippingAddressId = IDENT_CURRENT('Address')
							
							INSERT INTO [dbo].[VendorShippingAddress]([VendorId],[AddressId],[IsPrimary],[SiteName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ContactTagId],[Attention])
							VALUES (@VendorId,@ShippingAddressId,0,@VendorName,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,NULL,NULL);
							
							SELECT @INSVendorShippingAddressId = IDENT_CURRENT('VendorShippingAddress');
							
							SELECT @VendorShippingAddressId = [VendorShippingAddressId],@SiteName = [SiteName],@VSAddressId = [AddressId] FROM [dbo].[VendorShippingAddress] WITH(NOLOCK) WHERE [VendorShippingAddressId] = @INSVendorShippingAddressId;
							
							SELECT @VSContactId = VC.[ContactId], @VSContactName = (C.[FirstName] + ' ' + C.[LastName]), @VSWorkPhone = C.[WorkPhone]
							FROM [dbo].[VendorContact] VC WITH(NOLOCK) INNER JOIN [dbo].[Contact] C WITH(NOLOCK) ON VC.ContactId = C.ContactId	
							WHERE VC.[VendorId] = @VendorId AND VC.[IsDefaultContact] = 1;
							
							SELECT  @VSLine1 = AD.Line1, @VSLine2 = AD.Line2, @VSLine3 = AD.Line3, @VSCity = AD.City, @VSStateOrProvince = AD.StateOrProvince, @VSPostalCode = AD.PostalCode, 
							@VSCountryId = AD.CountryId, @VSCountryName = CO.countries_name 
							FROM [dbo].[Address] AD WITH(NOLOCK) INNER JOIN [dbo].[Countries] CO WITH(NOLOCK) ON AD.[CountryId] = CO.[countries_id]
							WHERE [AddressId] = @ShippingAddressId;
							
							INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],[AddressId],[IsModuleOnly],
							[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],
							[CountryId],[Country],[MasterCompanyId],[CreatedBy] ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])
							VALUES(@InsertedPurchaseOrderId,@POModuleId,@VendorModuleId,'Vendor',@VendorId,@VendorName,@VendorShippingAddressId,@SiteName ,@VSAddressId,0,
							1,NULL,'',@VSContactId,@VSContactName,@VSWorkPhone,@VSLine1,@VSLine2,@VSLine3,@VSCity,@VSStateOrProvince,@VSPostalCode,
							@VSCountryId,@VSCountryName,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,0);		
						END
									    
						SELECT @BILL_ADDRESS1 = PO.VendorAddress4 FROM #TempPOHeader AS PO WHERE ID = @LoopID;

						IF (@BILL_ADDRESS1 IS NOT NULL)
						BEGIN
							SELECT @BTCity = SUBSTRING(@BILL_ADDRESS1,0,CHARINDEX(',',@BILL_ADDRESS1,0)),@BTStateAndPinCode = SUBSTRING(@BILL_ADDRESS1,CHARINDEX(',',@BILL_ADDRESS1,0)+1,LEN(@BILL_ADDRESS1));						
							SELECT @BTStateAndPinCode = TRIM(@BTStateAndPinCode);
							SELECT @BTState = SUBSTRING(@BTStateAndPinCode,0,CHARINDEX(' ',@BTStateAndPinCode,0)),@BTPostalCode = SUBSTRING(@BTStateAndPinCode,CHARINDEX(' ',@BTStateAndPinCode,0)+1,LEN(@BTStateAndPinCode)); 
						
							INSERT INTO [dbo].[Address]([POBox],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Latitude],[Longitude],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
							SELECT  NULL,PO.VendorAddress1, PO.VendorAddress2, PO.VendorAddress3, @BTCity, @BTState, @BTPostalCode, @countries_id, NULL, NULL, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0
							FROM #TempPOHeader AS PO WHERE ID = @LoopID;

							SELECT @BillingAddressId = IDENT_CURRENT('Address');

							INSERT INTO [dbo].[VendorBillingAddress]([VendorId],[AddressId],[IsPrimary],[SiteName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsAddressForPayment],[ContactTagId],[Attention])
							VALUES (@VendorId, @BillingAddressId, 0, @VendorName, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0, 0, NULL, NULL)

							SELECT @BTVendorBillingAddressId = IDENT_CURRENT('VendorBillingAddress');
								   		
							SELECT @VendorBillingAddressId = [VendorBillingAddressId], @BTSiteName = [SiteName], @BTAddressId = [AddressId]
							FROM [dbo].[VendorBillingAddress] WITH(NOLOCK) WHERE [VendorBillingAddressId] = @BTVendorBillingAddressId 
			  
							SELECT  @BTOLine1 = AD.Line1, @BTOLine2 = AD.Line2, @BTOLine3 = AD.Line3, @BTOCity = AD.City, @BTOStateOrProvince = AD.StateOrProvince, @BTOPostalCode = AD.PostalCode,
							@BTOCountryId = AD.CountryId, @BTOCountryName = CO.countries_name 
							FROM [dbo].[Address] AD WITH(NOLOCK) INNER JOIN [dbo].[Countries] CO WITH(NOLOCK) ON AD.[CountryId] = CO.[countries_id]
							WHERE [AddressId] = @BillingAddressId;

							INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],[AddressId],[IsModuleOnly],
							[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],
							[CountryId],[Country],[MasterCompanyId],[CreatedBy] ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])
							VALUES(@InsertedPurchaseOrderId,@POModuleId,@VendorModuleId,'Vendor',@VendorId,@VendorName,@VendorBillingAddressId,@BTSiteName ,@BTAddressId,0,
							0,NULL,'',@VSContactId,@VSContactName,@VSWorkPhone,@BTOLine1,@BTOLine2,@BTOLine3,@BTOCity,@BTOStateOrProvince,@BTOPostalCode,
							@BTOCountryId,@BTOCountryName,@FromMasterComanyID,@UserName,@UserName,GETDATE(),GETDATE(),1,0,0);						  
						END	
					END
				END
			END

			SET @LoopID = @LoopID + 1;
		END
	END

	COMMIT TRANSACTION

	SET @Processed = @ProcessedRecords;
	SET @Migrated = @MigratedRecords;
	SET @Failed = @RecordsWithError;
	SET @Exists = @RecordExits;

	SELECT @Processed, @Migrated, @Failed, @Exists;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
	  ROLLBACK TRAN;
	  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	  DECLARE @ErrorLogID int
	  ,@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
	  ,@AdhocComments varchar(150) = 'MigrateKitItemMasterRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END