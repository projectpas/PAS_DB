
/***************************************************************************************************************************************             
  ** Change History             
 ***************************************************************************************************************************************             
 ** PR   Date						 Author							Change Description              
 ** --   --------					 -------						-------------------------------            
    1   	
	2    14/08/2024              MOIN BLOCH                         Converted Error Log Id in Varchar
	3    23/10/2024              RAJESH GAMI                        Change the Local date to UTC date by default
****************************************************************************************************************************************/ 
CREATE   PROCEDURE [dbo].[CreateBulkPO]
	@tbl_BulkPODetailType BulkPODetailType READONLY,
	@loginUserName varchar(50) = NULL,
	@employeeId bigint = NULL,
	@updatedByName varchar(50) = NULL,
	@MstCompanyId bigint = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			DECLARE @TotalDistictRecord int = 0, @TotalRecord int = 0, @MainLoopId int = 0, @LoopVendorId bigint = 0,@ManagementStructureID bigint,@UpdatePOMainLoopId int = 0
			DECLARE @FullfillStatusId bigint, @WorkOrderMaterialsIds VARCHAR(MAX),@WorkOrderMaterialsKitIds VARCHAR(MAX)
			DECLARE @PriorityId bigint;
			DECLARE @IsResale bit;
			DECLARE @IsDeferredReceiver bit;
			DECLARE @IsEnforceApproval bit;
			DECLARE @NewPurchaseOrderId BIGINT,@NewPurchaseOrderPartId BIGINT;
			DECLARE @totalPartCount int; 
			DECLARE @newPartLoopId int; 
			SELECT @PriorityId = PriorityId, @IsResale = IsResale, @IsDeferredReceiver = IsDeferredReceiver, @IsEnforceApproval = IsEnforceApproval FROM DBO.PurchaseOrderSettingMaster WITH (NOLOCK) WHERE MasterCompanyId = 1;
			SELECT TOP 1 @FullfillStatusId = POStatusId FROM DBO.POStatus WITH (NOLOCK) WHERE [Status] like '%Fulfilling%';
			DECLARE @POPartId bigint
			DECLARE @IdCodeTypeId BIGINT;
			DECLARE @CurrentPONumber AS BIGINT;
			DECLARE @PONumber AS VARCHAR(50);
			DECLARE @level1Id bigint = 0, @legalEntityId bigint = 0,@siteIdBill bigint =0, @siteIdShip bigint = 0,@addressIdBill bigint, @addressIdShip bigint
			DECLARE @siteNameBill varchar(200), @siteNameShip varchar(200),@contactId bigint, @contactName varchar(200),@contactNo varchar(20), @addressId bigint
			DECLARE @Address1 varchar(max),@Address2 varchar(max),@Address3 varchar(max),@City varchar(100),@StateOrProvince varchar(100),@PostalCode varchar(max),@CountryId int
			DECLARE @UserTypeName varchar(100),@UserName varchar(100),@Country varchar(100)
			DECLARE @ShipViaId bigint,@ShipVia varchar(200) ,@ShippingViaId bigint ,@VendorModule VARCHAR(100) = 'Vendor',@ReturnCurrencyId INT = 0,@VendorId BIGINT = 0;
			SELECT @UserTypeName= ModuleName FROM dbo.Module WITH (NOLOCK)  WHERE ModuleId = 9;
			
			SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Purchase';
			IF OBJECT_ID(N'tempdb..#tmpReturnTbl') IS NOT NULL
				BEGIN
					DROP TABLE #tmpReturnTbl
				END

			CREATE TABLE #tmpReturnTbl(
			   [PurchaseOrderId] [bigint] NULL
			)

			IF OBJECT_ID(N'tempdb..#BulkPOItemType') IS NOT NULL
			BEGIN
				DROP TABLE #BulkPOItemType
			END

			IF OBJECT_ID(N'tempdb..#tempGroupByCount') IS NOT NULL
			BEGIN
				DROP TABLE #tempGroupByCount
			END
			CREATE TABLE #tempGroupByCount(
			   [ID] [bigint] IDENTITY(1,1) NOT NULL,
			   [VendorId] [bigint] NULL
			)
				
			CREATE TABLE #BulkPOItemType
			(
				[ItemMasterId] [bigint] NOT NULL,
				[StockType] [varchar](50)  NULL,
				[ManufacturerId] [bigint]  NULL,
				[Manufacturer] [varchar](50) NULL,
				[PN] [varchar](250) NULL,
				[PNDescription] [nvarchar](max) NULL,
				[PriorityId] [bigint] NULL,
				[Priority] [nvarchar](max) NULL,
				[ConditionId] [bigint] NULL,
				[Condition] [varchar](256) NULL,
				[Quantity] [int] NULL,
				[UnitCost] [decimal](18,2) NULL,
				[VendorId] [bigint] NULL,
				[VendorName] [varchar](100) NULL,
				[VendorCode] [varchar](100) NULL,
				[GlAccountId] [bigint] NULL,
				[GlAccount] [varchar](250) NULL,
				[UOMId] [bigint] NULL,
				[UnitOfMeasure] [varchar](50) NULL,
				[WorkOrderId] [bigint] NULL,
				[WorkOrderNo] [varchar](250) NULL,
				[ManagementStructureId] [bigint] NULL,
				[MasterCompanyId] [int] NULL,
				[NeedBy] [datetime2](7) NULL,
				[EstReceivedDate] [datetime2](7) NULL,
				[StatusId] [int] NULL,
				[WorkOrderMaterialsId] [bigint] NULL,
				[WorkOrderMaterialsKitId] [bigint] NULL
			)
					    
			INSERT INTO #BulkPOItemType ([ItemMasterId], [StockType], [ManufacturerId], [Manufacturer], [PN], [PNDescription],[PriorityId],[Priority],[ConditionId], [Condition], 
			[Quantity], [UnitCost], [VendorId], [VendorName], [VendorCode], [GlAccountId], [GlAccount], [UOMId], [UnitOfMeasure], [WorkOrderId], [WorkOrderNo],
			[ManagementStructureId], [MasterCompanyId],[NeedBy],[EstReceivedDate],[StatusId],[WorkOrderMaterialsId],[WorkOrderMaterialsKitId])
			SELECT [ItemMasterId], [StockType], [ManufacturerId], [Manufacturer], [PN], [PNDescription],[PriorityId],[Priority], [ConditionId], [Condition], 
			[Quantity], [UnitCost], [VendorId], [VendorName], [VendorCode], [GlAccountId], [GlAccount], [UOMId], [UnitOfMeasure], [WorkOrderId], [WorkOrderNo], 
			[ManagementStructureId], [MasterCompanyId],[NeedBy],[EstReceivedDate],[StatusId],[WorkOrderMaterialsId],[WorkOrderMaterialsKitId] FROM @tbl_BulkPODetailType;
		
			INSERT INTO #tempGroupByCount (VendorId) SELECT VendorId FROM #BulkPOItemType GROUP BY VendorId
			--SELECT * FROM #tempGroupByCount
			Set @TotalRecord = (Select Count(*) from #BulkPOItemType)
			Select @TotalDistictRecord = Count(*),@MainLoopId =MIN(Id) from #tempGroupByCount
			SELECT TOP 1 @ManagementStructureID = ManagementStructureId FROM #BulkPOItemType
			SELECT @level1Id=ISNULL(Level1Id,0) FROM dbo.PurchaseOrderManagementStructureDetails WITH (NOLOCK) WHERE ModuleID = 4 AND EntityMSID = @ManagementStructureID
			SELECT TOP 1 @legalEntityId = LegalEntityId FROM ManagementStructureLevel WITH (NOLOCK) WHERE ID = @level1Id
			SET @VendorId = (SELECT TOP 1 VendorId FROM @tbl_BulkPODetailType)
			SET @ReturnCurrencyId = (SELECT [CurrencyId] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @VendorId)
			IF(ISNULL(@ReturnCurrencyId,0) = 0)
			BEGIN
				SET @ReturnCurrencyId = (SELECT CU.CurrencyId FROM [dbo].[LegalEntity] LE WITH(NOLOCK) JOIN [dbo].[Currency] CU WITH(NOLOCK) 
															  ON CU.CurrencyId = LE.FunctionalCurrencyId  WHERE LE.[LegalEntityId] = @LegalEntityId)
			END

			SELECT @WorkOrderMaterialsIds = STRING_AGG ( WorkOrderMaterialsId, ',') FROM #BulkPOItemType;
			SELECT @WorkOrderMaterialsKitIds = STRING_AGG ( WorkOrderMaterialsKitId, ',') FROM #BulkPOItemType;
			WHILE @TotalDistictRecord >0
			BEGIN
				/*************** Prefixes ***************/		   			
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
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId = @IdCodeTypeId
				AND CP.MasterCompanyId = @MstCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
				BEGIN
					SELECT @CurrentPONumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
								
					SET @PONumber = (SELECT * FROM dbo.udfGenerateCodeNumber(
									@CurrentPONumber,
									(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
									(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
				END
				/*****************End Prefixes*******************/	
				print 'Step 1'
				set @LoopVendorId = (SELECT VendorId FROM #tempGroupByCount where id = @MainLoopId)
				INSERT INTO [dbo].[PurchaseOrder] 
				([PurchaseOrderNumber], [OpenDate], [ClosedDate], [PriorityId], [Priority], [VendorId], [VendorName], [VendorCode]
	           ,[VendorContactId], [VendorContact], [VendorContactPhone], [CreditTermsId], [Terms], [CreditLimit], [RequestedBy], [Requisitioner], [StatusId], [Status], [StatusChangeDate]
	           ,[Resale], [DeferredReceiver], [ApproverId], [ApprovedBy], [DateApproved], [POMemo], [Notes], [ManagementStructureId], [Level1], [Level2], [Level3], [Level4]
	           ,[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsEnforce], [PDFPath]
	           ,[VendorRFQPurchaseOrderId], [FreightBilingMethodId], [TotalFreight], [ChargesBilingMethodId], [TotalCharges],IsFromBulkPO,NeedByDate,FunctionalCurrencyId,ReportCurrencyId,ForeignExchangeRate)
			    SELECT TOP 1 @PONumber, cast(GETUTCDATE() as DATE), NULL, @PriorityId, '', V.VendorId, V.VendorName, V.VendorCode,
			    VC.VendorContactId, 
			    (SELECT (C1.FirstName + ' ' + C1.LastName) FROM [dbo].[VendorContact] VC1 WITH (NOLOCK) INNER JOIN [dbo].[Contact] C1 WITH (NOLOCK) ON VC1.ContactId = C1.ContactId
			    WHERE VC1.VendorId = V.VendorId AND VC1.IsDefaultContact = 1),
			    (SELECT C1.WorkPhone FROM [dbo].[VendorContact] VC1 WITH (NOLOCK) INNER JOIN [dbo].[Contact] C1 WITH (NOLOCK) ON VC1.ContactId = C1.ContactId
			    WHERE VC1.VendorId = V.VendorId AND VC1.IsDefaultContact = 1), 
			    ISNULL(V.CreditTermsId,0), CT.[Name], V.CreditLimit, @employeeId, @loginUserName,PO.[StatusId], (SELECT TOP 1 [Status] FROM dbo.POStatus WITH (NOLOCK) Where POStatusId = PO.StatusId ), GETUTCDATE(),
			    @IsResale, @IsDeferredReceiver, NULL, '', NULL, '', '', PO.ManagementStructureId, NULL, NULL, NULL, NULL,
			    @MstCompanyId, @updatedByName, @updatedByName, GETUTCDATE(), GETUTCDATE(), 1, 0, @IsEnforceApproval, NULL,
			    NULL, NULL, NULL, NULL, NULL,1,cast(PO.NeedBy as DATE),@ReturnCurrencyId,@ReturnCurrencyId,1.00
			    FROM #BulkPOItemType PO
			    INNER JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = PO.VendorId
			    LEFT JOIN [dbo].[VendorContact] VC WITH (NOLOCK) ON VC.VendorId = V.VendorId
			    LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = V.CreditTermsId
			    WHERE PO.VendorId = @LoopVendorId

			   SELECT @NewPurchaseOrderId = SCOPE_IDENTITY();

			   IF OBJECT_ID(N'tempdb..#NewId') IS NOT NULL
				BEGIN
					DROP TABLE #NewId
				END
				IF OBJECT_ID(N'tempdb..#tmpVendorParts') IS NOT NULL
				BEGIN
					DROP TABLE #tmpVendorParts
				END
				declare @NewId table (MyNewId INT) 
				CREATE TABLE #tmpVendorParts(
				   [ID] [bigint] IDENTITY(1,1) NOT NULL,
				   [NewId] [bigint] NULL
				)
			   /************** Insert Data Into Purchase Order Part *******************/
					INSERT INTO [dbo].[PurchaseOrderPart]
					([PurchaseOrderId], [ItemMasterId], [PartNumber], [PartDescription], [AltEquiPartNumberId], [AltEquiPartNumber], [AltEquiPartDescription], [StockType], [ManufacturerId], [Manufacturer],
					[PriorityId], [Priority], [ConditionId], [Condition], [QuantityOrdered], [QuantityBackOrdered], [QuantityRejected], [VendorListPrice], [DiscountPercent], [DiscountPerUnit],
					[DiscountAmount], [UnitCost], [ExtendedCost], [FunctionalCurrencyId], [FunctionalCurrency], [ForeignExchangeRate], [ReportCurrencyId], [ReportCurrency], [WorkOrderId], [WorkOrderNo],
					[SubWorkOrderId], [SubWorkOrderNo], [RepairOrderId], [ReapairOrderNo], [SalesOrderId], [SalesOrderNo], [ItemTypeId], [ItemType], [GlAccountId], [GLAccount], [UOMId], [UnitOfMeasure],
					[ManagementStructureId], [Level1], [Level2], [Level3], [Level4], [ParentId], [isParent], [Memo], [POPartSplitUserTypeId], [POPartSplitUserType], [POPartSplitUserId], [POPartSplitUser],
					[POPartSplitSiteId], [POPartSplitSiteName], [POPartSplitAddressId], [POPartSplitAddress1], [POPartSplitAddress2], [POPartSplitAddress3], [POPartSplitCity], [POPartSplitState],
					[POPartSplitPostalCode], [POPartSplitCountryId], [POPartSplitCountryName], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					[DiscountPercentValue], [ExchangeSalesOrderId], [ExchangeSalesOrderNo], [ManufacturerPN], [AssetModel], [AssetClass],NeedByDate,EstDeliveryDate)
					--OUTPUT INSERTED.PurchaseOrderPartRecordId INTO @NewId(MyNewId)
					SELECT
						@NewPurchaseOrderId, TYP.ItemMasterId,IM.partnumber, IM.PartDescription,NULL,NULL,NULL,
						CASE WHEN (IM.IsPMA = 1 AND IM.IsDER = 1) THEN 'PMA&DER' ELSE 
							CASE WHEN (IM.IsPMA = 1 AND IM.IsDER = 0) THEN 'PMA' ELSE
								CASE WHEN (IM.IsPMA = 0 AND IM.IsDER = 1) THEN 'DER' ELSE 'OEM' END
							END
						END
					,IM.ManufacturerId,IM.ManufacturerName,
					POS.PriorityId,POS.[Priority],TYP.ConditionId, TYP.Condition,ISNULL(TYP.Quantity,0),ISNULL(TYP.Quantity,0),0,ISNULL(IMP.PP_VendorListPrice,0),ISNULL(PP_PurchaseDiscPerc,0),ISNULL(PP_PurchaseDiscAmount,0),
					0,ISNULL(TYP.UnitCost,0),(ISNULL(TYP.UnitCost,0) * ISNULL(TYP.Quantity,0)),Im.PurchaseCurrencyId, C.Code,1.0,Im.PurchaseCurrencyId, C.Code,TYP.WorkOrderId,TYP.WorkOrderNo,
					NULL,NULL,NULL,NULL,NULL,NULL,1,'STOCK',IM.GLAccountId,IM.GLAccount,IM.PurchaseUnitOfMeasureId,IM.PurchaseUnitOfMeasure,
					TYP.ManagementStructureId,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,
					NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
					NULL,NULL,NULL,TYP.MasterCompanyId,@updatedByName,@updatedByName,GETUTCDATE(),GETUTCDATE(),1,0,
					0,NULL,NULL,NULL,NULL,NULL,cast(TYP.NeedBy as DATE),cast(TYP.EstReceivedDate as DATE)
					FROM #BulkPOItemType TYP
					INNER JOIN dbo.ItemMaster IM on TYP.ItemMasterId = IM.ItemMasterId
					LEFT JOIN dbo.Currency C on Im.PurchaseCurrencyId = C.CurrencyId
					LEFT JOIN dbo.Manufacturer MF on TYP.ManufacturerId = MF.ManufacturerId
					LEFT JOIN dbo.PurchaseOrderSettingMaster POS on TYP.MasterCompanyId = POS.MasterCompanyId
					LEFT JOIN dbo.ItemMasterPurchaseSale IMP on IM.ItemMasterId = IMP.ItemMasterId AND TYP.ConditionId = IMP.ConditionId
					WHERE Typ.VendorId = @LoopVendorId 


				EXEC dbo.[PROCAddPOMSData] @NewPurchaseOrderId,@ManagementStructureID,@MstCompanyId,@updatedByName,@updatedByName,4,1,0

					INSERT INTO #tmpVendorParts ([NewId])
					SELECT PurchaseOrderPartRecordId from dbo.PurchaseOrderPart	where PurchaseOrderId = @NewPurchaseOrderId			
					
					INSERT INTO #tmpReturnTbl (PurchaseOrderId) VALUES (@NewPurchaseOrderId)

					Select @totalPartCount = COUNT(*), @newPartLoopId = MIN(ID) from #tmpVendorParts
					WHILE @totalPartCount >0
					BEGIN
						set @POPartId= (SELECT [NewId] FROM #tmpVendorParts WHERE ID = @newPartLoopId)
						EXEC dbo.[PROCAddPOMSData] @POPartId,@ManagementStructureID,@MstCompanyId,@updatedByName,@updatedByName,5,3,0
											   
				 /************ INSERT INTO Purchase Order Approval Table : By Pass the approval process for bulk PO ************/
						IF EXISTS ((SELECT TOP 1 StatusId FROM #BulkPOItemType WHERE StatusId = @FullfillStatusId))
						BEGIN
							INSERT INTO [dbo].[PurchaseOrderApproval]
								   ([PurchaseOrderId] ,[PurchaseOrderPartId] ,[SentDate] ,[ApprovedDate] ,[ApprovedById] ,[ApprovedByName]  ,[StatusId]
								   ,[StatusName] ,[ActionId] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted]
								   ,[InternalSentToId] ,[InternalSentToName] ,[InternalSentById])
							 VALUES
								   (@NewPurchaseOrderId
								   ,@POPartId
								   ,GETUTCDATE()
								   ,GETUTCDATE()
								   ,@employeeId
								   ,@loginUserName
								   ,2
								   ,'Approved'
								   ,5
								   ,@MstCompanyId
								   ,@loginUserName
								   ,@loginUserName
								   ,GETUTCDATE()
								   ,GETUTCDATE()
								   ,1
								   ,0
								   ,@employeeId
								   ,@loginUserName
								   ,@employeeId)

						END

						set @totalPartCount = @totalPartCount - 1
						set @newPartLoopId = @newPartLoopId+1
					END				
			
				/*********** All Address Insert **************/
	
				SELECT TOP 1 @addressId =AddressId,@UserName=[Name] FROM dbo.LegalEntity WITH(NOLOCK) WHERE LegalEntityId = @legalEntityId
				SELECT TOP 1 @siteIdShip = LegalEntityShippingAddressId,@siteNameShip=SiteName,@addressIdShip=AddressId from LegalEntityShippingAddress WITH (NOLOCK) where LegalEntityId = @legalEntityId AND IsPrimary =1
				SELECT TOP 1 @siteIdBill = LegalEntityBillingAddressId,@siteNameBill=SiteName,@addressIdBill=AddressId from LegalEntityBillingAddress WITH (NOLOCK) where LegalEntityId = @legalEntityId AND IsPrimary =1
				SELECT TOP 1 @contactId = ContactId FROM dbo.LegalEntityContact WITH(NOLOCK) WHERE LegalEntityId = @legalEntityId AND ISNULL(IsDefaultContact,0) = 1
				SELECT TOP 1 @contactName = ISNULL(FirstName,'') +' ' +ISNULL(LastName,''),@contactNo= WorkPhone FROM dbo.Contact WITH(NOLOCK) WHERE ContactId = @contactId
				SELECT @Address1 = Line1,@Address2 =Line2,@Address3 = Line3, @City = City, @StateOrProvince = StateOrProvince, @PostalCode = PostalCode,@CountryId = ISNULL(CountryId,0) FROM dbo.Address WITH (NOLOCK) WHERE AddressId = @addressId
				SELECT @Country = countries_name FROM dbo.Countries WITH(NOLOCK) where countries_id = @CountryId
				SELECT TOP 1 @ShipVia= Name, @ShipViaId = ShippingViaId FROM dbo.ShippingVia WHERE Name = 'DHL' AND MasterCompanyId = @MstCompanyId
				INSERT INTO [dbo].[AllAddress]
					   ([ReffranceId],[ModuleId],[UserType],[UserId],[SiteId],[SiteName],[AddressId],[IsModuleOnly],[IsShippingAdd]
					   ,[Memo],[ContactId],[ContactName],ContactPhoneNo,[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId]
					   ,[UserTypeName],[UserName],[Country],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				 VALUES(@NewPurchaseOrderId,13,9,@legalEntityId,@siteIdShip,@siteNameShip,@addressIdShip,0,1,
						'',@ContactId,@contactName,@contactNo,@Address1,@Address2,@Address3,@City,@StateOrProvince,@PostalCode,@CountryId,
						@UserTypeName,@UserName,@Country,@MstCompanyId,@loginUserName,@loginUserName,GETUTCDATE(),GETUTCDATE(),1,0)  

				INSERT INTO [dbo].[AllAddress]
					   ([ReffranceId],[ModuleId],[UserType],[UserId],[SiteId],[SiteName],[AddressId],[IsModuleOnly],[IsShippingAdd]
					   ,[Memo],[ContactId],[ContactName],ContactPhoneNo,[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId]
					   ,[UserTypeName],[UserName],[Country],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				 VALUES(@NewPurchaseOrderId,13,9,@legalEntityId,@siteIdBill,@siteNameBill,@addressIdBill,0,0,
						'',@ContactId,@contactName,@contactNo,@Address1,@Address2,@Address3,@City,@StateOrProvince,@PostalCode,@CountryId,
						@UserTypeName,@UserName,@Country,@MstCompanyId,@loginUserName,@loginUserName,GETUTCDATE(),GETUTCDATE(),1,0)  
				
				INSERT INTO [dbo].[AllShipVia]
					   ([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],[ShippingAccountNo],[ShipVia]
					   ,[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				 VALUES(@NewPurchaseOrderId,13,9,@ShipViaId,0.000,0.000,0,'',@ShipVia,
						@ShippingViaId,@MstCompanyId,@loginUserName,@loginUserName,GETUTCDATE(),GETUTCDATE(),1,0)  
				/************************************************************************/

				EXEC sp_UpdatePurchaseOrderDetail_BulkPO @NewPurchaseOrderId, @WorkOrderMaterialsIds, @WorkOrderMaterialsKitIds

			    UPDATE CodePrefixes SET CurrentNummber = @CurrentPONumber WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MstCompanyId;
				set @TotalDistictRecord = @TotalDistictRecord - 1;
				set @MainLoopId = @MainLoopId +1;
				UPDATE [dbo].[PurchaseOrder] set IsFromBulkPO = 1 WHERE PurchaseOrderId = @NewPurchaseOrderId
			END

			SELECT * FROM #tmpReturnTbl
		END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'CreateBulkPO'             
			, @ProcedureParameters VARCHAR(3000) = '@MstCompanyId = ''' + CAST(ISNULL(@MstCompanyId, '') AS VARCHAR(100)) 
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END