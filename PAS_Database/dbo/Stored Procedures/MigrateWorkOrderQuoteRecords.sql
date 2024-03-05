/*************************************************************             
 ** File:   [MigrateWorkOrderQuoteRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Work Order Header Records
 ** Purpose:           
 ** Date:   12/18/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    02/28/2024   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateWorkOrderQuoteRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateWorkOrderQuoteRecords]
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

		IF OBJECT_ID(N'tempdb..#TempWOQ') IS NOT NULL
		BEGIN
			DROP TABLE #TempWOQ
		END

		CREATE TABLE #TempWOQ
		(
			ID bigint NOT NULL IDENTITY,
			[WOQHeaderId] [bigint] NOT NULL,
			[WOQHeaderNumber] [varchar](100) NULL,
			[QuoteVersion] [varchar](10) NULL,
			[CustomerId] [bigint] NULL,
			[EntryDate] [datetime2](7) NULL,
			[CurrencyId] [bigint] NULL,
			[Notes] [varchar](max) NULL,
			[WqsId] [bigint] NULL,
			[ExpireDate] [datetime2](7) NULL,
			[SentDate] [datetime2](7) NULL,
			[ApprovedDate] [datetime2](7) NULL,
			[WOQDetailId] [bigint] NOT NULL,
			[WOQDetailParentId] [bigint] NULL,
			[WorkOrderRefId] [bigint] NULL,
			[WOTaskRefId] [bigint] NULL,
			[WOMaterialRefId] [bigint] NULL,
			[WOTaskLaborRefId] [bigint] NULL,
			[STIRefId] [bigint] NULL,
			[WOTaskSkillRefId] [bigint] NULL,
			[WOChargeRefId] [bigint] NULL,
			[Description] [varchar](max) NULL,
			[ItemType] [varchar](50) NULL,
			[Qty] [bigint] NULL,
			[UnitPrice] [decimal](18, 2) NULL,
			[ListPrice] [decimal](18, 2) NULL,
			[BaseCost] [decimal](18, 2) NULL,
			[Notes_Detail] [varchar](max) NULL,
			[EntryDate_Detail] [datetime2](7) NULL,
			[SysUserId] [bigint] NULL,
			[DiscountCodeId] [bigint] NULL,
			[WOK_WorkOrderTaskId_Ref] [bigint] NULL,
			[WOK_WorkOrderId_Ref] [bigint] NULL,
			[DueDate] [datetime2](7) NULL,
			[Freight] [decimal](18, 2) NULL,
			[Discount] [decimal](18, 2) NULL,
			[Markup] [decimal](18, 2) NULL,
			[TaxAmount] [decimal](18, 2) NULL,
			[InvoiceHeaderId] [bigint] NULL,
			[VersionNumber] [varchar](100) NULL,
			[VersionDate] [datetime2](7) NULL,
			[ApprovalDate] [datetime2](7) NULL,
			[DateCreated] [datetime2](7) NULL,
			[MasterCompanyId] [bigint] NULL,
			[Migrated_Id] [bigint] NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempWOQ ([WOQHeaderId],[WOQHeaderNumber],[QuoteVersion],[CustomerId],[EntryDate],[CurrencyId],[Notes],[WqsId],[ExpireDate],[SentDate],[ApprovedDate],[WOQDetailId],
		[WOQDetailParentId],[WorkOrderRefId],[WOTaskRefId],[WOMaterialRefId],[WOTaskLaborRefId],[STIRefId],[WOTaskSkillRefId],[WOChargeRefId],[Description],[ItemType],[Qty],[UnitPrice],
		[ListPrice],[BaseCost],[Notes_Detail],[EntryDate_Detail],[SysUserId],[DiscountCodeId],[WOK_WorkOrderTaskId_Ref],[WOK_WorkOrderId_Ref],[DueDate],[Freight],[Discount],[Markup],[TaxAmount],[InvoiceHeaderId],[VersionNumber],
		[VersionDate],[ApprovalDate],[DateCreated],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT WOQH.[WOQHeaderId],[WOQHeaderNumber],[QuoteVersion],[CustomerId],WOQH.[EntryDate],[CurrencyId],WOQH.[Notes],[WqsId],[ExpireDate],[SentDate],[ApprovedDate],[WOQDetailId],
		[WOQDetailParentId],[WorkOrderRefId],[WOTaskRefId],[WOMaterialRefId],[WOTaskLaborRefId],[STIRefId],[WOTaskSkillRefId],[WOChargeRefId],[Description],[ItemType],[Qty],[UnitPrice],
		[ListPrice],[BaseCost],WOQD.[Notes],WOQD.[EntryDate],[SysUserId],[DiscountCodeId],[WOK_WorkOrderTaskId_Ref],[WOK_WorkOrderId_Ref],[DueDate],[Freight],[Discount],[Markup],[TaxAmount],[InvoiceHeaderId],[VersionNumber],
		[VersionDate],[ApprovalDate],WOQH.[DateCreated],WOQH.[MasterCompanyId],WOQH.[Migrated_Id],WOQH.[SuccessMsg],WOQH.[ErrorMsg]
		FROM Quantum_Staging.dbo.WorkOrderQuoteHeaders WOQH
			INNER JOIN Quantum_Staging.dbo.WorkOrderQuoteDetails WOQD ON WOQH.WOQHeaderId = WOQD.WOQHeaderId
			AND WOQD.WOQDetailId = (SELECT MAX(z.WQD_AUTO_KEY) 
        FROM [Quantum].QCTL_NEW_3.WO_QUOTE_DETAIL z WHERE z.WQH_AUTO_KEY = WOQD.WOQHeaderId)
		WHERE WOQH.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempWOQ;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @Inserted_WorkOrderQuoteId BIGINT = NULL;
			DECLARE @Inserted_WorkOrderQuoteDetailsId BIGINT = NULL;
			DECLARE @DefaultEmployeeId AS BIGINT;
			DECLARE @WOO_AUTO_KEY BIGINT = NULL;
			DECLARE @CMP_AUTO_KEY BIGINT = NULL;
			DECLARE @WOO_REF BIGINT = NULL;
			DECLARE @WO_Num VARCHAR(100);
			DECLARE @WorkOrder_Id_In_PAS BIGINT = NULL;
			DECLARE @CustomerId BIGINT;
			DECLARE @ContactId BIGINT;
			DECLARE @CustomerName VARCHAR(200);
			DECLARE @CustomerContactName VARCHAR(200);
			DECLARE @SalesPersonId BIGINT;
			DECLARE @CreditLimit DECIMAL(18, 2);
			DECLARE @CreditTermsId BIGINT;
			DECLARE @TemrsName VARCHAR(200);
			DECLARE @CurrentWorkOrderQuoteHeaderId BIGINT = 0;

			SELECT @DefaultEmployeeId = U.[EmployeeId] FROM [dbo].[AspNetUsers] U WITH(NOLOCK) WHERE [UserName] LIKE 'MIG-ADMIN' AND [MasterCompanyId] = @FromMasterComanyID;
			
			SELECT @CurrentWorkOrderQuoteHeaderId = T.WOQHeaderId, @WOO_AUTO_KEY = WOK_WOO_REF, @WOO_REF = T.WorkOrderRefId, @CMP_AUTO_KEY = CustomerId FROM #TempWOQ AS T WHERE ID = @LoopID;
			
			SELECT @WO_Num = WO.SI_NUMBER FROM [Quantum].QCTL_NEW_3.WO_OPERATION AS WO WHERE WOO_AUTO_KEY = ISNULL(@WOO_AUTO_KEY, @WOO_REF);
			SELECT @WorkOrder_Id_In_PAS = ISNULL(WO.WorkOrderId, 0) FROM [dbo].[WorkOrder] AS WO WHERE UPPER(WO.WorkOrderNum) = UPPER(@WO_Num) AND [MasterCompanyId] = @FromMasterComanyID;
	
			SELECT @CustomerId = C.[CustomerId], @CustomerName = C.[Name] FROM [dbo].[Customer] C WITH(NOLOCK) WHERE UPPER(C.[CustomerCode]) IN (SELECT UPPER(CMP.[COMPANY_CODE]) FROM [Quantum].QCTL_NEW_3.COMPANIES CMP WHERE CMP.CMP_AUTO_KEY = @CMP_AUTO_KEY) AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @SalesPersonId = CS.[PrimarySalesPersonId] FROM [dbo].[CustomerSales] CS WITH(NOLOCK) WHERE CS.[CustomerId] = @CustomerId AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @ContactId = C.[ContactId] FROM [dbo].[CustomerContact] C WITH(NOLOCK) WHERE C.[CustomerId] = @CustomerId AND C.[IsDefaultContact] = 1 AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @CustomerContactName = (C.[FirstName] + ' ' + C.[LastName]) FROM DBO.[Contact] C WITH(NOLOCK) WHERE C.[ContactId] = @ContactId AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @CreditLimit = CF.[CreditLimit], @CreditTermsId = CF.[CreditTermsId] FROM [dbo].[CustomerFinancial] CF WITH(NOLOCK) WHERE [CustomerId] = @CustomerId AND [MasterCompanyId] = @FromMasterComanyID; 
			SELECT @TemrsName = CT.[Name] FROM dbo.[CreditTerms] CT WITH(NOLOCK) WHERE [CreditTermsId] = @CreditTermsId AND [MasterCompanyId] = @FromMasterComanyID;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';

			IF (ISNULL(@WorkOrder_Id_In_PAS, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Work Order Id not found</p>'
			END
			IF (ISNULL(@CustomerId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Customer not found</p>'
			END
			IF (ISNULL(@ContactId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Customer Contact not found</p>'
			END
			IF (ISNULL(@CreditLimit, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Credit Limit is missing OR zero</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE WOH
				SET WOH.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.WorkOrderQuoteHeaders WOH WHERE WOH.WOQHeaderId = @CurrentWorkOrderQuoteHeaderId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedWorkOrderId BIGINT;

			IF (@FoundError = 0)
			BEGIN
				DECLARE @ItemMasterId BIGINT;
				DECLARE @PartId BIGINT;
				DECLARE @WOWFId BIGINT;
				DECLARE @QUoteNumber VARCHAR(100);

				SELECT @ItemMasterId = WOP.[ItemMasterId], @PartId = [ID] FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrder_Id_In_PAS AND [MasterCompanyId] = @FromMasterComanyID;
				SELECT @WOWFId = WOWF.[WorkFlowWorkOrderId] FROM dbo.[WorkOrderWorkFlow] WOWF WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrder_Id_In_PAS AND WOWF.WorkOrderPartNoId = @PartId AND [MasterCompanyId] = @FromMasterComanyID;
				SELECT @QUoteNumber = WOQ.WOQHeaderNumber FROM #TempWOQ WOQ WHERE ID = @LoopID;

				IF NOT EXISTS(SELECT TOP 1 1 FROM [DBO].[WorkOrderQuote] WHERE [QuoteNumber] = @QUoteNumber AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					INSERT INTO [DBO].[WorkOrderQuote] ([WorkOrderId],[QuoteNumber],[OpenDate],[QuoteDueDate],[ValidForDays],[ExpirationDate],[QuoteStatusId],[CustomerId],[CurrencyId],[DSO],
					[AccountsReceivableBalance],[SalesPersonId],[EmployeeId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Memo],[Warnings],
					[SentDate],[ApprovedDate],[VersionNo],[IsApprovalBypass],[QuoteParentId],[IsVersionIncrease],[Notes],[CustomerName],[CustomerContact],[CreditLimit],[CreditTerms])
					SELECT @WorkOrder_Id_In_PAS, WOQ.WOQHeaderNumber, WOQ.EntryDate, ISNULL(WOQ.DueDate, '0001-01-01 00:00:00.0000000'), 90, DATEADD(day, 90, WOQ.EntryDate), (SELECT TOP 1 WorkOrderQuoteStatusId FROM [DBO].[WorkOrderQuoteStatus] WHERE UPPER(Description) = 'OPEN'), @CustomerId, (SELECT ISNULL(CurrencyId, 1) FROM [DBO].[CustomerFinancial] WHERE CustomerId = @CustomerId), NULL,
					0, @SalesPersonId, @DefaultEmployeeId, @FromMasterComanyID, @UserName, @UserName, WOQ.EntryDate, GETDATE(), 1, 0, NULL, NULL,
					WOQ.SentDate, WOQ.ApprovedDate, 'VER-000001', 1, NULL, 0, WOQ.[DESCRIPTION], @CustomerName, @CustomerContactName, @CreditLimit, @TemrsName
					FROM #TempWOQ WOQ WHERE ID = @LoopID;

					SELECT @Inserted_WorkOrderQuoteId = SCOPE_IDENTITY();

					INSERT INTO [DBO].[WorkOrderQuoteDetails] ([WorkOrderQuoteId],[ItemMasterId],[BuildMethodId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
					[WorkflowWorkOrderId],[WOPartNoId],[MaterialCost],[MaterialBilling],[MaterialRevenuePercentage],[MaterialMargin],[LaborHours],[LaborCost],[LaborBilling],[LaborRevenuePercentage],
					[LaborMargin],[ChargesCost],[ChargesBilling],[ChargesRevenuePercentage],[ChargesMargin],[ExclusionsCost],[ExclusionsBilling],[ExclusionsRevenuePercentage],[ExclusionsMargin],[FreightCost],
					[FreightBilling],[FreightRevenuePercentage],[FreightMargin],[MaterialMarginPer],[LaborMarginPer],[ChargesMarginPer],[ExclusionsMarginPer],[FreightMarginPer],[OverHeadCost],[AdjustmentHours],
					[AdjustedHours],[LaborFlatBillingAmount],[MaterialFlatBillingAmount],[ChargesFlatBillingAmount],[FreightFlatBillingAmount],[MaterialBuildMethod],[LaborBuildMethod],[ChargesBuildMethod],
					[FreightBuildMethod],[ExclusionsBuildMethod],[MaterialMarkupId],[LaborMarkupId],[ChargesMarkupId],[FreightMarkupId],[ExclusionsMarkupId],[FreightRevenue],[LaborRevenue],[MaterialRevenue],
					[ExclusionsRevenue],[ChargesRevenue],[OverHeadCostRevenuePercentage],[QuoteParentId],[IsVersionIncrease],[QuoteMethod],[CommonFlatRate],[EvalFees])
					SELECT @Inserted_WorkOrderQuoteId, @ItemMasterId, 3, @FromMasterComanyID, @UserName, @UserName, WOQ.EntryDate, GETDATE(), 1, 0,
					@WOWFId, @PartId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
					NULL, NULL, NULL, NULL, 0, 1, WOQ.BaseCost, NULL
					FROM #TempWOQ WOQ WHERE ID = @LoopID;

					SELECT @Inserted_WorkOrderQuoteDetailsId = SCOPE_IDENTITY();

					/* WOQ Parts */
					IF OBJECT_ID(N'tempdb..#TempWOQDetails') IS NOT NULL
					BEGIN
						DROP TABLE #TempWOQDetails
					END

					CREATE TABLE #TempWOQDetails
					(
						ID bigint NOT NULL IDENTITY,
						[WOQDetailId] [bigint] NOT NULL,
						[WOQDetailParentId] [bigint] NULL,
						[WOQHeaderId] [bigint] NULL,
						[WorkOrderRefId] [bigint] NULL,
						[WOTaskRefId] [bigint] NULL,
						[WOMaterialRefId] [bigint] NULL,
						[WOTaskLaborRefId] [bigint] NULL,
						[STIRefId] [bigint] NULL,
						[WOTaskSkillRefId] [bigint] NULL,
						[WOChargeRefId] [bigint] NULL,
						[Description] [varchar](max) NULL,
						[ItemType] [varchar](50) NULL,
						[Qty] [bigint] NULL,
						[UnitPrice] [decimal](18, 2) NULL,
						[ListPrice] [decimal](18, 2) NULL,
						[BaseCost] [decimal](18, 2) NULL,
						[Notes] [varchar](max) NULL,
						[EntryDate] [datetime2](7) NULL,
						[SysUserId] [bigint] NULL,
						[DiscountCodeId] [bigint] NULL,
						[WOK_WorkOrderTaskId_Ref] [bigint] NULL,
						[WOK_WorkOrderId_Ref] [bigint] NULL,
						[DueDate] [datetime2](7) NULL,
						[Freight] [decimal](18, 2) NULL,
						[Discount] [decimal](18, 2) NULL,
						[Markup] [decimal](18, 2) NULL,
						[TaxAmount] [decimal](18, 2) NULL,
						[InvoiceHeaderId] [bigint] NULL,
						[VersionNumber] [varchar](100) NULL,
						[VersionDate] [datetime2](7) NULL,
						[ApprovalDate] [datetime2](7) NULL,
						[DateCreated] [datetime2](7) NULL,
						[MasterCompanyId] [bigint] NULL,
						[Migrated_Id] [bigint] NULL,
						[SuccessMsg] [varchar](500) NULL,
						[ErrorMsg] [varchar](500) NULL
					)

					INSERT INTO #TempWOQDetails ([WOQDetailId],[WOQDetailParentId],[WOQHeaderId],[WorkOrderRefId],[WOTaskRefId],[WOMaterialRefId],[WOTaskLaborRefId],[STIRefId],
						[WOTaskSkillRefId],[WOChargeRefId],[Description],[ItemType],[Qty],[UnitPrice],[ListPrice],[BaseCost],[Notes],[EntryDate],[SysUserId],[DiscountCodeId],[WOK_WorkOrderTaskId_Ref],
						[WOK_WorkOrderId_Ref],[DueDate],[Freight],[Discount],[Markup],[TaxAmount],[InvoiceHeaderId],[VersionNumber],[VersionDate],[ApprovalDate],[DateCreated],[MasterCompanyId],
						[Migrated_Id],[SuccessMsg],[ErrorMsg])
					SELECT [WOQDetailId],[WOQDetailParentId],[WOQHeaderId],[WorkOrderRefId],[WOTaskRefId],[WOMaterialRefId],[WOTaskLaborRefId],[STIRefId],
						[WOTaskSkillRefId],[WOChargeRefId],[Description],[ItemType],[Qty],[UnitPrice],[ListPrice],[BaseCost],[Notes],[EntryDate],[SysUserId],[DiscountCodeId],[WOK_WorkOrderTaskId_Ref],
						[WOK_WorkOrderId_Ref],[DueDate],[Freight],[Discount],[Markup],[TaxAmount],[InvoiceHeaderId],[VersionNumber],[VersionDate],[ApprovalDate],[DateCreated],[MasterCompanyId],
						[Migrated_Id],[SuccessMsg],[ErrorMsg]
					FROM Quantum_Staging.dbo.WorkOrderQuoteDetails WOQD
					WHERE WOQD.WOQHeaderId = @CurrentWorkOrderQuoteHeaderId AND UPPER(WOQD.ItemType) = 'PART';

					DECLARE @PartCount AS INT;
					DECLARE @PartLoopID AS INT;

					SELECT @PartCount = COUNT(*), @PartLoopID = MIN(ID) FROM #TempWOQDetails;

					WHILE (@PartLoopID <= @PartCount)
					BEGIN
						DECLARE @WOB_REF BIGINT = NULL;
						DECLARE @MaterialItemMasterId BIGINT = NULL;
						DECLARE @MaterialConditionId BIGINT = NULL;
						DECLARE @ItemMaster_Id BIGINT = NULL;
						DECLARE @ConditionCodeId BIGINT = NULL, @PTC_AUTO_KEY BIGINT = NULL, @ItemClassificationId BIGINT = NULL, @UOM_AUTO_KEY BIGINT = NULL;
						DECLARE @Part_NUMBER VARCHAR(50) = NULL, @Part_Desc NVARCHAR(MAX) = NULL, @TaskId BIGINT = NULL, @ProvisionId BIGINT = NULL;
						DECLARE @UOMId BIGINT;

						SELECT @WOB_REF = T.WOMaterialRefId FROM #TempWOQDetails AS T WHERE ID = @PartLoopID;

						IF (ISNULL(@WOB_REF, 0) <> 0)
						BEGIN
							SELECT @MaterialItemMasterId = WOM.ItemMasterId, @MaterialConditionId = WOM.PartConditionCodeId FROM Quantum_Staging.dbo.WorkOrderMaterials AS WOM WHERE WOM.WorkOrderMaterialId = @WOB_REF;

							SELECT @PTC_AUTO_KEY = IM.ItemClassificationId, @Part_NUMBER = IM.PartNumber, @Part_Desc = IM.PartDescription, @UOM_AUTO_KEY = UnitOfMeasureId FROM Quantum_Staging.dbo.ItemMasters IM WHERE ItemMasterId = @MaterialItemMasterId;

							SELECT @ItemMaster_Id  = ItemMasterId FROM dbo.[ItemMaster] WHERE UPPER(partnumber) = UPPER(@Part_NUMBER) AND UPPER(PartDescription) = UPPER(@Part_Desc) AND MasterCompanyId = @FromMasterComanyID;
							SELECT @ConditionCodeId = ConditionId FROM DBO.[Condition] C WHERE UPPER(C.Code) IN (SELECT UPPER(CC.CONDITION_CODE) FROM [Quantum].QCTL_NEW_3.PART_CONDITION_CODES CC Where CC.PCC_AUTO_KEY = @MaterialConditionId) AND MasterCompanyId = @FromMasterComanyID;
							SELECT @ItemClassificationId = ItemClassificationId FROM DBO.ItemClassification IC WHERE UPPER(IC.Description) IN (SELECT UPPER(DESCRIPTION) FROM [Quantum].QCTL_NEW_3.PN_TYPE_CODES Where PTC_AUTO_KEY = @PTC_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
							SELECT @UOMId = UnitOfMeasureId FROM DBO.UnitOfMeasure MF WHERE UPPER(MF.ShortName) IN (SELECT UPPER(UOM_CODE) FROM [Quantum].QCTL_NEW_3.UOM_CODES Where UOM_AUTO_KEY = @UOM_AUTO_KEY) AND MasterCompanyId = @FromMasterComanyID;
							SELECT @TaskId = T.TaskId FROM DBO.Task T WHERE UPPER(T.[Description]) = UPPER('Assemble') AND MasterCompanyId = @FromMasterComanyID;
							SELECT @ProvisionId = P.ProvisionId FROM DBO.Provision P WHERE UPPER(P.StatusCode) = UPPER('REPLACE');

							INSERT INTO DBO.WorkOrderQuoteMaterial ([WorkOrderQuoteDetailsId],[ItemMasterId],[ConditionCodeId],[ItemClassificationId],
								[Quantity],[UnitOfMeasureId],[UnitCost],[ExtendedCost],[Memo],[IsDefered],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
								[IsDeleted],[MarkupPercentageId],[TaskId],[MarkupFixedPrice],[BillingAmount],[BillingRate],[HeaderMarkupId],[ProvisionId],[MaterialMandatoriesId],
								[BillingMethodId],[TaskName],[PartNumber],[PartDescription],[Provision],[UomName],[Conditiontype],[Stocktype],[BillingName],[MarkUp])
							SELECT @Inserted_WorkOrderQuoteDetailsId,@ItemMaster_Id,@ConditionCodeId,@ItemClassificationId,
								WOQ.Qty,@UOMId,WOQ.BaseCost,(WOQ.BaseCost * WOQ.Qty),WOQ.Notes,NULL,@FromMasterComanyID,@UserName,@UserName,WOQ.EntryDate,WOQ.EntryDate,1,
								0,NULL,@TaskId,2,(WOQ.BaseCost * WOQ.Qty),WOQ.BaseCost,NULL,@ProvisionId,NULL,
								2,'ASSEMBLE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
							FROM #TempWOQDetails WOQ WHERE ID = @PartLoopID;
						END

						SET @PartLoopID = @PartLoopID + 1;
					END

					UPDATE WOQ
					SET WOQ.Migrated_Id = @Inserted_WorkOrderQuoteId,
					WOQ.SuccessMsg = 'Record migrated successfully'
					FROM [Quantum_Staging].DBO.WorkOrderQuoteHeaders WOQ WHERE WOQ.WOQHeaderId = @CurrentWorkOrderQuoteHeaderId;

					SET @MigratedRecords = @MigratedRecords + 1;
				END
				ELSE
				BEGIN
					UPDATE WOQ
					SET WOQ.ErrorMsg = ISNULL(ErrorMsg, '') + '<p>Work Order Quote Header record already exists</p>'
					FROM [Quantum_Staging].DBO.WorkOrderQuoteHeaders WOQ WHERE WOQ.WOQHeaderId = @CurrentWorkOrderQuoteHeaderId;

					SET @RecordExits = @RecordExits + 1;
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
	  ,@AdhocComments varchar(150) = 'MigrateWorkOrderQuoteRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END