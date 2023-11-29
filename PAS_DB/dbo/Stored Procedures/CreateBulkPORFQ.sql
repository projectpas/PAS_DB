
CREATE   PROCEDURE [dbo].[CreateBulkPORFQ]
	@tbl_BulkPORFQDetailType BulkPODetailType READONLY,
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
			DECLARE @TotalDistictRecord int = 0, @TotalRecord int = 0, @MainLoopId int = 0, @LoopVendorId bigint = 0,@ManagementStructureID bigint
			DECLARE @OpenStatusId bigint, @WorkOrderMaterialsIds VARCHAR(MAX),@WorkOrderMaterialsKitIds VARCHAR(MAX);
			DECLARE @PriorityId bigint;
			DECLARE @IsResale bit;
			DECLARE @IsDeferredReceiver bit;
			DECLARE @IsEnforceApproval bit;
			DECLARE @NewPurchaseOrderRFQId BIGINT,@NewPurchaseOrderPartId BIGINT;
			DECLARE @totalPartCount int 
			DECLARE @newPartLoopId int 
			SELECT @PriorityId = PriorityId, @IsResale = IsResale, @IsDeferredReceiver = IsDeferredReceiver FROM DBO.PurchaseOrderSettingMaster WITH (NOLOCK) WHERE MasterCompanyId = 1;
			SELECT @OpenStatusId = POStatusId FROM DBO.POStatus WITH (NOLOCK) WHERE [Status] = 'Open';
			DECLARE @PORFQPartId bigint
			DECLARE @IdCodeTypeId BIGINT;
			DECLARE @CurrentPORFQNumber AS BIGINT;
			DECLARE @PORFQNumber AS VARCHAR(50);

			SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'VendorRFQPurchaseOrder';
			
			IF OBJECT_ID(N'tempdb..#tmpReturnTbl') IS NOT NULL
			BEGIN
				DROP TABLE #tmpReturnTbl
			END

			CREATE TABLE #tmpReturnTbl(
			   [PurchaseOrderId] [bigint] NULL
			)

			IF OBJECT_ID(N'tempdb..#BulkPORFQItemType') IS NOT NULL
			BEGIN
				DROP TABLE #BulkPORFQItemType
			END

			IF OBJECT_ID(N'tempdb..#tempGroupByCount') IS NOT NULL
			BEGIN
				DROP TABLE #tempGroupByCount
			END
			CREATE TABLE #tempGroupByCount(
			   [ID] [bigint] IDENTITY(1,1) NOT NULL,
			   [VendorId] [bigint] NULL
			)
			CREATE TABLE #BulkPORFQItemType
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
					    
			INSERT INTO #BulkPORFQItemType ([ItemMasterId], [StockType], [ManufacturerId], [Manufacturer], [PN], [PNDescription],[PriorityId],[Priority],[ConditionId], [Condition], 
			[Quantity], [UnitCost], [VendorId], [VendorName], [VendorCode], [GlAccountId], [GlAccount], [UOMId], [UnitOfMeasure], [WorkOrderId], [WorkOrderNo],
			[ManagementStructureId], [MasterCompanyId],[NeedBy],[EstReceivedDate],[StatusId],[WorkOrderMaterialsId],[WorkOrderMaterialsKitId])
			SELECT [ItemMasterId], [StockType], [ManufacturerId], [Manufacturer], [PN], [PNDescription],[PriorityId],[Priority], [ConditionId], [Condition], 
			[Quantity], [UnitCost], [VendorId], [VendorName], [VendorCode], [GlAccountId], [GlAccount], [UOMId], [UnitOfMeasure], [WorkOrderId], [WorkOrderNo], 
			[ManagementStructureId], [MasterCompanyId],[NeedBy],[EstReceivedDate],@OpenStatusId,[WorkOrderMaterialsId],[WorkOrderMaterialsKitId] FROM @tbl_BulkPORFQDetailType;
		
			INSERT INTO #tempGroupByCount (VendorId) SELECT VendorId FROM #BulkPORFQItemType GROUP BY VendorId
			Set @TotalRecord = (Select Count(*) from #BulkPORFQItemType)
			Select @TotalDistictRecord = Count(*),@MainLoopId =MIN(Id) from #tempGroupByCount
			SELECT TOP 1 @ManagementStructureID = ManagementStructureId FROM #BulkPORFQItemType
			
			--SELECT @WorkOrderMaterialsIds = STRING_AGG ( WorkOrderMaterialsId, ',') FROM #BulkPORFQItemType;
			--SELECT @WorkOrderMaterialsKitIds = STRING_AGG ( WorkOrderMaterialsKitId, ',') FROM #BulkPORFQItemType;

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
					SELECT @CurrentPORFQNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
								
					SET @PORFQNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(
									@CurrentPORFQNumber,
									(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
									(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
				END
				/*****************End Prefixes*******************/	
				
				set @LoopVendorId = (SELECT VendorId FROM #tempGroupByCount where id = @MainLoopId)
				INSERT INTO [dbo].[VendorRFQPurchaseOrder] 
				([VendorRFQPurchaseOrderNumber], [OpenDate], [ClosedDate], [PriorityId], [Priority], [VendorId], [VendorName], [VendorCode]
	           ,[VendorContactId], [VendorContact], [VendorContactPhone], [CreditTermsId], [Terms], [CreditLimit], [RequestedBy], [Requisitioner], [StatusId], [Status], [StatusChangeDate]
	           ,[Resale], [DeferredReceiver], [Memo], [Notes], [ManagementStructureId], [Level1], [Level2], [Level3], [Level4]
	           ,[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [PDFPath]
				,IsFromBulkPO,NeedByDate)
			    SELECT TOP 1 @PORFQNumber, GETDATE(), NULL, @PriorityId, '', V.VendorId, V.VendorName, V.VendorCode,
			    VC.VendorContactId, 
			    (SELECT (C1.FirstName + ' ' + C1.LastName) FROM [dbo].[VendorContact] VC1 WITH (NOLOCK) INNER JOIN [dbo].[Contact] C1 WITH (NOLOCK) ON VC1.ContactId = C1.ContactId
			    WHERE VC1.VendorId = V.VendorId AND VC1.IsDefaultContact = 1),
			    (SELECT C1.WorkPhone FROM [dbo].[VendorContact] VC1 WITH (NOLOCK) INNER JOIN [dbo].[Contact] C1 WITH (NOLOCK) ON VC1.ContactId = C1.ContactId
			    WHERE VC1.VendorId = V.VendorId AND VC1.IsDefaultContact = 1), 
			    ISNULL(V.CreditTermsId,0), CT.[Name], V.CreditLimit, @employeeId, @loginUserName, @OpenStatusId/* PO.[StatusId] */,'Open' /* (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus WITH (NOLOCK) Where VendorRFQStatusId = PO.StatusId ) */, GETDATE(),
			    @IsResale, @IsDeferredReceiver,'', '', PO.ManagementStructureId, NULL, NULL, NULL, NULL,
			    @MstCompanyId, @updatedByName, @updatedByName, GETDATE(), GETDATE(), 1, 0, NULL,
			    1,PO.NeedBy
			    FROM #BulkPORFQItemType PO
			    INNER JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = PO.VendorId
			    LEFT JOIN [dbo].[VendorContact] VC WITH (NOLOCK) ON VC.VendorId = V.VendorId
			    LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = V.CreditTermsId
			    WHERE PO.VendorId = @LoopVendorId
	print 'Start'
			   SELECT @NewPurchaseOrderRFQId = SCOPE_IDENTITY();
			   print  @NewPurchaseOrderRFQId
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
					INSERT INTO [dbo].[VendorRFQPurchaseOrderPart]
					([VendorRFQPurchaseOrderId], [ItemMasterId], [PartNumber], [PartDescription], [StockType], [ManufacturerId], [Manufacturer],
					[PriorityId], [Priority], [ConditionId], [Condition], [QuantityOrdered],
					[UnitCost], [ExtendedCost], [WorkOrderId], [WorkOrderNo],
				    [UOMId], [UnitOfMeasure],
					[ManagementStructureId],
					[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
					NeedByDate,PromisedDate)
					--OUTPUT INSERTED.PurchaseOrderPartRecordId INTO @NewId(MyNewId)
					SELECT
						@NewPurchaseOrderRFQId, TYP.ItemMasterId,IM.partnumber, IM.PartDescription,
						CASE WHEN (IM.IsPMA = 1 AND IM.IsDER = 1) THEN 'PMA&DER' ELSE 
							CASE WHEN (IM.IsPMA = 1 AND IM.IsDER = 0) THEN 'PMA' ELSE
								CASE WHEN (IM.IsPMA = 0 AND IM.IsDER = 1) THEN 'DER' ELSE 'OEM' END
							END
						END
					,IM.ManufacturerId,IM.ManufacturerName,
					POS.PriorityId,POS.[Priority],TYP.ConditionId, TYP.Condition,ISNULL(TYP.Quantity,0),
					ISNULL(TYP.UnitCost,0),(ISNULL(TYP.Quantity,0) * ISNULL(TYP.UnitCost,0)),TYP.WorkOrderId,TYP.WorkOrderNo,
					IM.PurchaseUnitOfMeasureId,IM.PurchaseUnitOfMeasure,
					TYP.ManagementStructureId,
					TYP.MasterCompanyId,@updatedByName,@updatedByName,GETDATE(),GETDATE(),1,0,
					TYP.NeedBy,TYP.EstReceivedDate
					FROM #BulkPORFQItemType TYP
					INNER JOIN dbo.ItemMaster IM on TYP.ItemMasterId = IM.ItemMasterId
					LEFT JOIN dbo.Currency C on Im.PurchaseCurrencyId = C.CurrencyId
					LEFT JOIN dbo.Manufacturer MF on TYP.ManufacturerId = MF.ManufacturerId
					LEFT JOIN dbo.PurchaseOrderSettingMaster POS on TYP.MasterCompanyId = POS.MasterCompanyId
					LEFT JOIN dbo.ItemMasterPurchaseSale IMP on IM.ItemMasterId = IMP.ItemMasterId AND TYP.ConditionId = IMP.ConditionId
					WHERE Typ.VendorId = @LoopVendorId 
				/************************************************************************/
				EXEC dbo.[PROCAddPOMSData] @NewPurchaseOrderRFQId,@ManagementStructureID,@MstCompanyId,@updatedByName,@updatedByName,20,1,0

					INSERT INTO #tmpVendorParts ([NewId])
					SELECT VendorRFQPOPartRecordId from dbo.VendorRFQPurchaseOrderPart where VendorRFQPurchaseOrderId = @NewPurchaseOrderRFQId			
					
					INSERT INTO #tmpReturnTbl (PurchaseOrderId) Select @NewPurchaseOrderRFQId

					Select @totalPartCount = COUNT(*), @newPartLoopId = MIN(ID) from #tmpVendorParts
					WHILE @totalPartCount >0
					BEGIN
						set @PORFQPartId= (SELECT [NewId] FROM #tmpVendorParts WHERE ID = @newPartLoopId)
						EXEC dbo.[PROCAddVendorRFQPOMSData] @PORFQPartId,@ManagementStructureID,@MstCompanyId,@updatedByName,@updatedByName,21,1,0
						set @totalPartCount = @totalPartCount - 1
						set @newPartLoopId = @newPartLoopId+1
					END
				
				EXEC PROCUpdateVendorRFQPurchaseOrderDetail @NewPurchaseOrderRFQId

			    UPDATE CodePrefixes SET CurrentNummber = @CurrentPORFQNumber WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MstCompanyId;
				set @TotalDistictRecord = @TotalDistictRecord - 1;
				set @MainLoopId = @MainLoopId +1;
				UPDATE [dbo].[VendorRFQPurchaseOrder] set IsFromBulkPO = 1 WHERE VendorRFQPurchaseOrderId = @NewPurchaseOrderRFQId
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
            , @ProcedureParameters VARCHAR(3000)  = '@MstCompanyId = '''+ ISNULL(@MstCompanyId, '') + ''
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