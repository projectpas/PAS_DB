
/*************************************************************           
 ** File:   [USP_CreateExchangeFromPO]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Create Exchange from the PO(Where we have used EXCHANGE provision material)
 ** Date:   13/10/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    13/10/2023   Rajesh Gami     Created
**************************************************************
--EXEC  [dbo].[USP_CreateExchangeFromPO] 0,1936,15539
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateExchangeFromPO] 
@ExchangeId bigint OUTPUT,
@POId bigint NULL=0,
@WorkOrderMaterialsId bigint NULL=0,
@CoreDueDate datetime2 NULL,
@IsCreateExchange bit = 1
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		SET @ExchangeId = 0;
		DECLARE @CurrentUTCDate datetime2 = GETUTCDATE(), @MasterCompanyId bigint = 0;
		DECLARE @CodeTypeId BIGINT = (SELECT TOP 1 CodeTypeId FROM DBO.CodeTypes WITH(NOLOCK) WHERE CodeType = 'ExchangeSalesOrder')
		DECLARE @CurrentIdNumber BIGINT =0, @ExchangeNumber varchar(50),@ManagementStrucName  VARCHAR(MAX)='', @VersioNum varchar(30) ='VER-0001';
		DECLARE @PoNumber varchar(100), @ManagementStructureId BIGINT = 0 ,@CreatedBy varchar(200) = '' ,@firstDate datetime2 = CONVERT(DATETIME2,'0001-01-01');
		DECLARE @VendorWarnlingListId INT = (SELECT TOP 1 VendorWarningListId FROM dbo.VendorWarningList WITH(NOLOCK) Where Name = 'Create Exchange');
		DECLARE @VendorWarningId BIGINT = 0;
		IF(@POId >0)
		BEGIN
			SELECT * INTO #TempPOTable FROM (SELECT * FROM dbo.PurchaseOrder WITH(NOLOCK) WHERE PurchaseOrderId = @POId) AS HEADER
			SELECT * INTO #TempPOPartTable FROM  (SELECT * FROM dbo.PurchaseOrderPart WITH(NOLOCK) WHERE PurchaseOrderId = @POId AND WorkOrderMaterialsId = @WorkOrderMaterialsId) AS PART
			SELECT * INTO #TempStockline FROM (SELECT TOP 1 * FROM dbo.Stockline WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId ORDER BY 1 DESC) AS STK
			SELECT * INTO #TempMaterial FROM (SELECT * FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId ) AS Material
			SELECT TOP 1 @MasterCompanyId = MasterCompanyId ,@CreatedBy = CreatedBy FROM #TempPOTable
			SELECT * INTO #TempCodePrefix FROM(SELECT TOP 1 * FROM dbo.CodePrefixes WITH(NOLOCK) WHERE MasterCompanyId =@MasterCompanyId AND CodeTypeId = @CodeTypeId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0) AS A
			SELECT @VendorWarningId = VendorWarningId FROM dbo.VendorWarning WITH(NOLOCK) where VendorWarningListId = @VendorWarnlingListId and VendorId = (SELECT TOP 1 VendorId FROM #TempPOTable) AND MasterCompanyId = @MasterCompanyId;
			Set @PoNumber = (SELECT TOP 1 PurchaseOrderNumber FROM #TempPOTable)
			SELECT @CurrentIdNumber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END	FROM #TempCodePrefix WHERE CodeTypeId = @CodeTypeId
			SET @ExchangeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentIdNumber, (SELECT CodePrefix FROM #TempCodePrefix WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #TempCodePrefix WHERE CodeTypeId = @CodeTypeId)))
			SELECT @ManagementStrucName = [Name],@ManagementStructureId = ManagementStructureId FROM dbo.ManagementStructure WITH(NOLOCK) WHERE ManagementStructureId = (SELECT TOP 1 ManagementStructureId FROM #TempPOTable) 
			If(@IsCreateExchange = 1)
			BEGIN
			INSERT INTO [dbo].[ExchangeSalesOrder]
						   ([Version] ,[TypeId],[OpenDate],[NumberOfItems],[CustomerId],[CustomerContactId],[CustomerReference],[CurrencyId]
						   ,[TotalSalesAmount],[CustomerHold],[DepositAmount],[BalanceDue],[SalesPersonId],[AgentId],[CustomerSeviceRepId],[EmployeeId],[ApprovedById],[ApprovedDate]
						   ,[Memo],[StatusId],[StatusChangeDate],[Notes],[RestrictPMA],[RestrictDER],[ManagementStructureId],[CustomerWarningId],[CreatedBy],[CreatedDate]
						   ,[UpdatedBy],[UpdatedDate],[MasterCompanyId],[IsDeleted],[ExchangeQuoteId],[QtyRequested],[QtyToBeQuoted],[ExchangeSalesOrderNumber],[IsActive],[ContractReference]
						   ,[TypeName],[AccountTypeName],[CustomerName],[CustomerCode],[SalesPersonName],[CustomerServiceRepName],[EmployeeName],[CurrencyName],[CustomerWarningName],[ManagementStructureName]
						   ,[CreditLimit],[CreditTermId],[CreditLimitName],[CreditTermName],[VersionNumber],[ExchangeQuoteNumber],[IsApproved],[CoreAccepted],[IsVendor])
				(SELECT    1,1,po.OpenDate,0,po.VendorId,po.VendorContactId,po.PurchaseOrderNumber,NULL
						   , 0.00, 0.00, 0.00, 0.00,NULL,NULL,NULL,RequestedBy,NULL,NULL
						   ,'Exchange from '+PurchaseOrderNumber,1,@CurrentUTCDate,Notes,0,0,ManagementStructureId,@VendorWarningId,CreatedBy,@CurrentUTCDate
						   ,UpdatedBy, @CurrentUTCDate,MasterCompanyId,0,NULL,0,0,@ExchangeNumber,1,NULL
						   ,'Exchange',NULL,VendorName,VendorCode,NULL,NULL,Requisitioner,NULL,NULL,@ManagementStrucName
						   ,CreditLimit, CASE WHEN CreditTermsId = 0 THEN NULL ELSE CreditTermsId END,NULL,Terms,@VersioNum,NULL,0,0,1 FROM #TempPOTable po)

				SET @ExchangeId = SCOPE_IDENTITY();
				EXEC dbo.[PROCAddExchangeMSData] @ExchangeId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@CreatedBy,19,1,1
				INSERT INTO [dbo].[ExchangeSalesOrderPart]
						   ([ExchangeSalesOrderId],[ExchangeQuotePartId],[ExchangeQuoteId],[ItemMasterId],[StockLineId],[ExchangeCurrencyId],[LoanCurrencyId],[ExchangeListPrice]
						   ,[EntryDate],[ExchangeOverhaulPrice],[ExchangeCorePrice] ,[EstOfFeeBilling],[BillingStartDate],[ExchangeOutrightPrice],[DaysForCoreReturn],[BillingIntervalDays]
						   ,[CurrencyId],[Currency],[DepositeAmount],[CoreDueDate],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[IsActive]
						   ,[ConditionId],[StockLineName],[PartNumber],[PartDescription],[ConditionName],[IsRemark],[RemarkText],[ExchangeOverhaulCost],[QtyQuoted],[MethodType],[IsConvertedToSalesOrder]
						   ,[CustomerRequestDate],[PromisedDate] ,[EstimatedShipDate],[ExpectedCoreSN],[StatusId],[StatusName],[FxRate],[UnitCost],[PriorityId],[Qty],[QtyRequested]
						   ,[ControlNumber],[IdNumber],[Notes],[ExpecedCoreCond],[ExpectedCoreRetDate],[CoreRetDate] ,[CoreRetNum],[CoreStatusId],[LetterSentDate],[LetterTypeId]
						   ,[Memo],[ExpdCoreSN],[POId],[PONumber],[PONextDlvrDate],[IsExpCoreSN],[CoreAccepted],[ReceivedDate])
				(SELECT @ExchangeId,NULL,NULL,ItemMasterId,(SELECT top 1 StockLineId FROM #TempStockline),FunctionalCurrencyId,NULL,VendorListPrice
				,@CurrentUTCDate,0.00,0.00,0,@CurrentUTCDate,0.00,0,0
				,FunctionalCurrencyId,FunctionalCurrency,0.00,@CoreDueDate,MasterCompanyId,CreatedBy,@CurrentUTCDate,UpdatedBy,@CurrentUTCDate,0,1
				,(SELECT TOP 1 ConditionId FROM #TempStockline),(SELECT top 1 StockLineNumber FROM #TempStockline),PartNumber,PartDescription,Condition,0,NULL,0.00,1,'I',0
				,@firstDate,@firstDate,EstDeliveryDate,(SELECT top 1 ExpectedSerialNumber FROM #TempMaterial),NULL,NULL,0,UnitCost,PriorityId,QuantityOrdered,QuantityOrdered
				,(SELECT top 1 ControlNumber FROM #TempStockline),(SELECT top 1 IdNumber FROM #TempStockline),NULL,ConditionId,NULL,NULL,NULL,1,NULL,NULL
				,NULL,NULL,@POId,@PoNumber,EstDeliveryDate,0,0,NULL FROM #TempPOPartTable)

				Update dbo.CodePrefixes SET CurrentNummber = ISNULL(CurrentNummber,0) +1 WHERE CodePrefixId = (SELECT top 1 CodePrefixId FROM #TempCodePrefix)	
			END				
	
			 /************** Map the Workorder with PO  ************/
			 INSERT INTO [dbo].[PurchaseOrderPartReference]
		     	   ([PurchaseOrderId],[PurchaseOrderPartId],[ModuleId],[ReferenceId],[Qty],[RequestedQty],[MasterCompanyId],[CreatedBy]
			 	   ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			 (Select @POId, PurchaseOrderPartRecordId, 1,(SELECT TOP 1 WorkOrderId FROM #TempMaterial),QuantityOrdered,QuantityOrdered,@MasterCompanyId,CreatedBy,UpdatedBy,@CurrentUTCDate,@CurrentUTCDate,1,0 FROM #TempPOPartTable)

		END -- END @POId >0

		Select @ExchangeId AS ExchangeId 
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
          SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_CreateExchangeFromPO]',
            @ProcedureParameters varchar(3000) = '@POId = ''' + CAST(ISNULL(@ExchangeId, '') AS varchar(100))
            + '@POId = ''' + CAST(ISNULL(@POId, '') AS varchar(100))
            + '@WorkOrderMaterialsId = ''' + CAST(ISNULL(@WorkOrderMaterialsId, '') AS varchar(100)),
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