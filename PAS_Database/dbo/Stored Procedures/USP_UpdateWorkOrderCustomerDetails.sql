/*********************             
 ** File:   UPDATE CUSTOMER IN WO           
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Update Customer from WO
 ** Purpose:           
 ** Date:   14-APRIL-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    04/16/2024   HEMANT SALIYA      Created  
   
exec dbo.USP_UpdateWorkOrderCustomerDetails @WorkOrderId=3890,@WorkOrderPartNoId=3403,@CustomerId=49,
@ItemMasterId=41195,@customerReference=N'RO -99999',@SerialNumber=N'999999',@Memo=default,@UpdatedBy=N'ADMIN User'
*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderCustomerDetails] 	
@WorkOrderId BIGINT = NULL,  
@WorkOrderPartNoId BIGINT = NULL,
@CustomerId BIGINT = NULL,  
@ItemMasterId BIGINT = NULL, 
@CustomerReference VARCHAR(500) = NULL, 
@SerialNumber VARCHAR(100) = NULL, 
@Memo NVARCHAR(MAX) = NULL, 
@UpdatedBy VARCHAR(100) = NULL
	
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
		--DECLARE @WorkOrderId BIGINT = NULL;
		DECLARE @CustomerContactId BIGINT = NULL;
		DECLARE @SalesPersonId BIGINT = NULL;
		DECLARE @CSRId BIGINT = NULL;
		DECLARE @ContactNumber VARCHAR(30) = NULL;
		DECLARE @CustomerName VARCHAR(30) = NULL;
		DECLARE @ExistingCustomerId BIGINT = NULL;
		DECLARE @ExistingItemMasterId BIGINT = NULL;
		DECLARE @ExistingCustomerReference VARCHAR(200) = NULL;
		DECLARE @ExistingSerialNumber VARCHAR(100) = NULL;
		DECLARE @CustomerCode VARCHAR(30) = NULL;
		DECLARE @CustomerType VARCHAR(30) = NULL;
		DECLARE @WorkOrderNum VARCHAR(30) = NULL;
		DECLARE @IsFinishedGood BIT = NULL;
		DECLARE @IsClosed BIT = NULL;
		DECLARE @WorkOrderSettlementId BIGINT = 9; --Fixed for Final Condition Changed
		DECLARE @8130WorkOrderSettlementId BIGINT; --Fixed for Final Condition Changed
		DECLARE @ModuleId BIGINT, @RefferenceId BIGINT, @SubModuleId BIGINT, @SubRefferenceId BIGINT, @ExistingValue VARCHAR(MAX) = NULL, 
				@NewValue VARCHAR(MAX), @TemplateBody VARCHAR(MAX), @HistoryText VARCHAR(MAX), @StatusCode VARCHAR(100), @MasterCompanyId INT;

		SET @ModuleId = 15; --Fixed for Work Order
		SET @SubModuleId = 43; --Fixed for Work Order MPM
		SET @SubRefferenceId = @WorkOrderPartNoId; 

		SELECT @8130WorkOrderSettlementId = WorkOrderSettlementId FROM WorkOrderSettlement WHERE UPPER(WorkOrderSettlementName) = 'RELEASE CERTS (E.G. 8130) REVIEWED'

		PRINT '1'
		
		SELECT @WorkOrderId = WorkOrderId, @RefferenceId = WorkOrderId, @ExistingItemMasterId = ItemMasterId,  @IsFinishedGood = ISNULL(IsFinishGood, 0), 
			   @IsClosed = ISNULL(IsClosed, 0) , @ExistingCustomerReference = CustomerReference, 
			   @ExistingSerialNumber = RevisedSerialNumber
		FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId

		SELECT	@CustomerName = C.[Name], @CustomerCode = C.CustomerCode, @CustomerType = CT.CustomerTypeName,
				@CustomerContactId = CC.CustomerContactId, 
				@ContactNumber = CASE WHEN ISNULL(CO.WorkPhone, '') != '' THEN CO.WorkPhone ELSE CO.MobilePhone END  
		FROM dbo.Customer C WITH(NOLOCK) 
			JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
			JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
			JOIN dbo.CustomerType CT WITH(NOLOCK) ON CT.CustomerTypeId = C.CustomerTypeId 
			LEFT JOIN dbo.CustomerFinancial CF WITH(NOLOCK) ON CF.CustomerId = C.CustomerId 
			LEFT JOIN dbo.CreditTerms CTs WITH(NOLOCK) ON CF.CreditTermsId = CTs.CreditTermsId 
		WHERE C.CustomerId = @CustomerId

		SELECT @ExistingCustomerId = CustomerId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
		PRINT '2'
		--SELECT @CustomerId As CustomerId, @ExistingCustomerId As ExistingCustomerId
		--CASE-1  UPDATE CUSTOMER DETAILS
		IF(ISNULL(@CustomerId, 0) > 0 AND ISNULL(@CustomerId, 0) != ISNULL(@ExistingCustomerId, 0))
		BEGIN
			PRINT 'UPDATE CUSTOMER DETAILS'
			SET @StatusCode = 'CUSTOMERCHANGE';

			SELECT @ExistingValue = CustomerName, @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId

			UPDATE dbo.WorkOrder SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId
			UPDATE dbo.WorkOrderQuote SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId
			UPDATE dbo.WorkOrder SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId
			UPDATE dbo.Stockline SET ExistingCustomerId = SL.CustomerId , ExistingCustomer = WO.CustomerName
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WO.WorkOrderId = @WorkOrderId

			UPDATE dbo.Stockline SET CustomerId =  @CustomerId , 
				--Memo = REPLACE(SL.Memo, '</p>','<br>') + 'Updated Customer from WO : ' + WO.WorkOrderNum + ' </p>'	,
				Memo = CASE WHEN ISNULL(SL.Memo,'') = '' THEN '</p>Updated Customer ' + @ExistingValue + ' to ' + @CustomerName + 'From Work Order : ' + WO.WorkOrderNum + ' </p>' ELSE REPLACE(SL.Memo, '</p>','<br>') + 'Updated Customer ' + @ExistingValue + ' to ' + @CustomerName + 'From Work Order : ' + WO.WorkOrderNum + ' </p>' END
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WO.WorkOrderId = @WorkOrderId

			UPDATE WorkOrder
				SET CustomerName = C.[Name], CustomerContactId = CC.CustomerContactId ,
					CreditTerms = CTs.[Name] , CreditTermId = CF.CreditTermsId ,
					[Days] = CTs.[Days], CustomerType = CT.CustomerTypeName, NetDays = CTs.NetDays,
					PercentId = CTs.PercentId , SalesPersonId = CS.PrimarySalesPersonId, CSRId = CS.CsrId, 
					CreditLimit = CF.CreditLimit
			FROM dbo.Customer C WITH(NOLOCK) 
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
				LEFT JOIN dbo.CustomerType CT WITH(NOLOCK) ON CT.CustomerTypeId = C.CustomerTypeId 
				LEFT JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
				LEFT JOIN dbo.CustomerFinancial CF WITH(NOLOCK) ON CF.CustomerId = C.CustomerId 
				LEFT JOIN dbo.CreditTerms CTs WITH(NOLOCK) ON CF.CreditTermsId = CTs.CreditTermsId 
				LEFT JOIN dbo.CustomerSales CS WITH(NOLOCK) ON CS.CustomerId = C.CustomerId 
			WHERE WorkOrderId = @WorkOrderId AND C.CustomerId = WO.CustomerId

			UPDATE WorkOrderQuote
				SET CustomerName = C.[Name], CustomerContact = CO.FirstName + ' ' + CO.LastName ,
					CreditTerms = CTs.[Name] , SalesPersonId = CS.PrimarySalesPersonId, 
					CreditLimit = CF.CreditLimit
			FROM dbo.Customer C WITH(NOLOCK) 
				JOIN dbo.WorkOrderQuote WOQ WITH(NOLOCK) ON WOQ.CustomerId = C.CustomerId
				LEFT JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
				LEFT JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
				LEFT JOIN dbo.CustomerFinancial CF WITH(NOLOCK) ON CF.CustomerId = C.CustomerId 
				LEFT JOIN dbo.CreditTerms CTs WITH(NOLOCK) ON CF.CreditTermsId = CTs.CreditTermsId 
				LEFT JOIN dbo.CustomerSales CS WITH(NOLOCK) ON CS.CustomerId = C.CustomerId 
			WHERE WorkOrderId = @WorkOrderId AND C.CustomerId = WOQ.CustomerId

			UPDATE WorkOrderBillingInvoicing SET CustomerId = @CustomerId, InvoiceFilePath = NULL , InvoiceStatus = 'Billed'
			FROM dbo.WorkOrderBillingInvoicing WOBI WITH(NOLOCK) 
				JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ID = WOBII.WorkOrderPartId
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
			WHERE WO.WorkOrderId = @WorkOrderId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0

			UPDATE ReceivingCustomerWork
				SET CustomerId = @CustomerId, CustomerContactId = CC.CustomerContactId ,
					CustomerName = C.[Name], CustomerCode = C.CustomerCode
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = RC.WorkOrderId
				JOIN dbo.Customer C WITH(NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
			WHERE RC.WorkOrderId = @WorkOrderId

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

			SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', ISNULL(@WorkOrderNum,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', ISNULL(@ExistingValue,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', ISNULL(@CustomerName,''));

			PRINT 'UPDATE CUSTOMER History'
			EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, @ExistingValue, @CustomerName, @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy,  NULL , @UpdatedBy, NULL
			PRINT 'END UPDATE CUSTOMER DETAILS'
		END

		--CASE-2  UPDATE PART NUMBER DETAILS
		--SELECT  @ItemMasterId AS ItemMasterId, @ExistingItemMasterId AS ExistingItemMasterId
		IF(ISNULL(@ItemMasterId, 0) > 0 AND ISNULL(@ItemMasterId, 0) != ISNULL(@ExistingItemMasterId, 0))
		BEGIN
			PRINT 'PART NUMBER DETAILS'
			SET @StatusCode = 'PARTNUMBERCHANGE';
			
			SELECT @ExistingValue = IM.partnumber FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN ItemMaster IM ON IM.ItemMasterId = WOP.ItemMasterId
			WHERE WOP.ID = @WorkOrderPartNoId

			SELECT @NewValue = partnumber FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId

			UPDATE WorkOrderPartNumber SET ItemMasterId = @ItemMasterId, RevisedItemmasterid = @ItemMasterId, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE WorkOrderPartNumber SET RevisedPartNumber = IM.PartNumber, RevisedPartDescription = IM.PartDescription, IsPMA = IM.IsPma, IsDER = IM.IsDER,
				   IsFinishGood = CASE WHEN ISNULL(IsFinishGood, 0) > 0 THEN 0 ELSE IsFinishGood END,
				   IsClosed = CASE WHEN ISNULL(IsClosed, 0) > 0 THEN 0 ELSE IsClosed END,
				   ClosedDate = NULL
				   --WorkOrderStageId = NULL,
				   --WorkOrderStatusId = NULL
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				LEFT JOIN ItemMaster IM ON IM.ItemMasterId = WOP.RevisedItemmasterid
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE WorkOrderSettlementDetails SET RevisedPartId = @ItemMasterId, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),
				IsMastervalue = 1, Isvalue_NA = 0
			FROM dbo.WorkOrderSettlementDetails WSD WITH(NOLOCK)
			WHERE WSD.WorkOrderId = @WorkOrderId AND WSD.workOrderPartNoId =  @WorkOrderPartNoId AND WSD.WorkOrderSettlementId = @WorkOrderSettlementId

			UPDATE dbo.Stockline SET ItemMasterId =  @ItemMasterId , 
					Memo = CASE WHEN ISNULL(SL.Memo,'') = '' THEN '</p>Updated Part Number ' + @ExistingValue + ' to ' + @NewValue + 'From Work Order : ' + WO.WorkOrderNum + ' </p>' ELSE REPLACE(SL.Memo, '</p>','<br>') + 'Updated Part Number ' + @ExistingValue + ' to ' + @NewValue + 'From Work Order : ' + WO.WorkOrderNum + ' </p>' END
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE dbo.Stockline SET PartNumber = IM.partnumber, PNDescription = IM.PartDescription ,ManufacturerId = IM.ManufacturerId, Manufacturer = IM.ManufacturerName, IsHazardousMaterial = IM.IsHazardousMaterial,
					IsPMA = IM.IsPma, IsDER = IM.IsDER, isSerialized = IM.isSerialized, PurchaseUnitOfMeasureId = IM.PurchaseUnitOfMeasureId, UnitOfMeasure = IM.PurchaseUnitOfMeasure,
					RevicedPNId = IM.RevisedPartId, RevicedPNNumber = IM.RevisedPart, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
				JOIN ItemMaster IM ON IM.ItemMasterId = WOP.ItemMasterId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE ReceivingCustomerWork
				SET ItemMasterId = @ItemMasterId, IsSerialized = im.isSerialized, ManufacturerName = IM.ManufacturerName, PartNumber = IM.partnumber,
					RevisePartId = IM.RevisedPartId, IsTimeLife = IM.isTimeLife, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),
					Memo = CASE WHEN ISNULL(RC.Memo,'') = '' THEN '</p>Updated Part Number ' + @ExistingValue + ' to ' + @NewValue + 'From Work Order : ' + WO.WorkOrderNum + ' </p>' ELSE REPLACE(RC.Memo, '</p>','<br>') + 'Updated Part Number ' + @ExistingValue + ' to ' + @NewValue + 'From Work Order : ' + WO.WorkOrderNum + ' </p>' END
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ReceivingCustomerWorkId = RC.ReceivingCustomerWorkId
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
				JOIN ItemMaster IM ON IM.ItemMasterId = WOP.ItemMasterId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE WorkOrderBillingInvoicingItem SET ItemMasterId = WOP.ItemMasterId, PDFPath = NULL , UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
			FROM dbo.WorkOrderBillingInvoicingItem WOBII WITH(NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ID = WOBII.WorkOrderPartId
			WHERE WOP.ID = @WorkOrderPartNoId AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 AND ISNULL(WOBII.IsPerformaInvoice, 0) = 0

			UPDATE WorkOrderBillingInvoicing SET ItemMasterId = WOP.ItemMasterId, InvoiceFilePath = NULL , InvoiceStatus = 'Billed'
			FROM dbo.WorkOrderBillingInvoicing WOBI WITH(NOLOCK) 
				JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ID = WOBII.WorkOrderPartId
			WHERE WOP.ID = @WorkOrderPartNoId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0

			UPDATE WorkOrderQuoteDetails SET ItemMasterId = @ItemMasterId, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()				
			FROM dbo.WorkOrderQuoteDetails WOQD WITH(NOLOCK)
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ID = WOQD.WOPartNoId
			WHERE WOP.WorkOrderId = @WorkOrderId 

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

			SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', ISNULL(@WorkOrderNum,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', ISNULL(@ExistingValue,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', ISNULL(@NewValue,''));

			EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, @ExistingValue, @NewValue, @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy,  NULL, @UpdatedBy, NULL

			PRINT 'END PART NUMBER DETAILS'
			
		END

		--CASE - 3 UPDATE CUST REFERENCE
		IF(ISNULL(@CustomerReference, '') != '' AND ISNULL(@ExistingCustomerReference, '') != ISNULL(@CustomerReference, ''))
		BEGIN
			PRINT 'UPDATE CUST REFERENCE'
			SET @StatusCode = 'CUSTREFCHANGE';

			SELECT @ExistingValue = WOP.CustomerReference FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE WorkOrderPartNumber SET CustomerReference = @CustomerReference, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE dbo.Stockline SET RepairOrderNumber =  @CustomerReference, RepairOrderId =  NULL 
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE ReceivingCustomerWork
				SET Reference = @CustomerReference 
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ReceivingCustomerWorkId = RC.ReceivingCustomerWorkId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE Work_ReleaseFrom_8130
				SET Reference = @CustomerReference
			FROM [dbo].[Work_ReleaseFrom_8130] WRO WITH(NOLOCK)
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) on WRO.workOrderPartNoId = WOP.Id
			WHERE WOP.ID = @WorkOrderPartNoId 

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

			SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', ISNULL(@WorkOrderNum,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', ISNULL(@ExistingValue,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', ISNULL(@CustomerReference,''));

			EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, @ExistingValue, @NewValue, @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy,  NULL, @UpdatedBy, NULL
			PRINT 'UPDATE CUST REFERENCE COMPLETE'
		END

		--CASE - 4 UPDATE SERIAL NUMBER
		IF(ISNULL(@SerialNumber, '') != '' AND ISNULL(@ExistingSerialNumber, '') != ISNULL(@SerialNumber, ''))
		BEGIN
			SET @StatusCode = 'SERNUMCHANGE';

			SELECT @ExistingValue = WOP.RevisedSerialNumber FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) WHERE WOP.ID = @WorkOrderPartNoId

			PRINT 'UPDATE SERIAL NUMBER'
			UPDATE WorkOrderPartNumber SET RevisedSerialNumber = @SerialNumber, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
			WHERE WOP.ID = @WorkOrderPartNoId

			PRINT '4.1'
			UPDATE dbo.Stockline SET SerialNumber = @SerialNumber, isSerialized =  1 
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WOP.ID = @WorkOrderPartNoId

			PRINT '4.2'
			UPDATE ReceivingCustomerWork
				SET SerialNumber = @SerialNumber, isSerialized =  1, IsSkipSerialNo = 0 
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ReceivingCustomerWorkId = RC.ReceivingCustomerWorkId
			WHERE WOP.ID = @WorkOrderPartNoId
			PRINT '4.0'

			SELECT @TemplateBody = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = @StatusCode

			SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', ISNULL(@WorkOrderNum,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', ISNULL(@ExistingValue,''));
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', ISNULL(@SerialNumber,''));

			EXEC USP_History @ModuleId, @WorkOrderId, @SubModuleId, @WorkOrderPartNoId, @ExistingValue, @NewValue, @TemplateBody, @StatusCode, @MasterCompanyId, @UpdatedBy,  NULL, @UpdatedBy, NULL
			PRINT 'UPDATE SERIAL NUMBER COMPLETE'
		END

		--CASE - 5 UPDATE MEMO
		IF(ISNULL(@Memo, '') != '')
		BEGIN
			PRINT 'UPDATE MEMO'
			UPDATE dbo.Stockline SET Memo = CASE WHEN ISNULL(SL.Memo,'') = '' THEN @Memo ELSE REPLACE(SL.Memo, '</p>','<br>') + @Memo + ' </p>' END
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE ReceivingCustomerWork
				SET Memo = CASE WHEN ISNULL(Memo,'') = '' THEN @Memo ELSE REPLACE(Memo, '</p>','<br>') + @Memo + ' </p>' END
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ReceivingCustomerWorkId = RC.ReceivingCustomerWorkId
			WHERE WOP.ID = @WorkOrderPartNoId
		END

		IF(ISNULL(@IsClosed, 0) = 1)
		BEGIN
			EXEC USP_ReOpenClosedWorkOrder @WorkOrderPartNoId, @UpdatedBy
		END
		ELSE IF(ISNULL(@IsFinishedGood, 0) = 1)
		BEGIN
			EXEC USP_ReOpen_FinishGood_WorkOrder @WorkOrderPartNoId, @UpdatedBy
		END
		ELSE
		BEGIN
			UPDATE dbo.WorkOrderSettlementDetails SET IsMasterValue = 0, Isvalue_NA = 0 
			WHERE WorkOrderId = @WorkOrderId AND workOrderPartNoId = @workOrderPartNoId AND WorkOrderSettlementId = @8130WorkOrderSettlementId;

			UPDATE WorkOrderPartNumber SET 
				   isLocked = CASE WHEN ISNULL(isLocked, 0) > 0 THEN 0 ELSE isLocked END
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				LEFT JOIN ItemMaster IM ON IM.ItemMasterId = WOP.RevisedItemmasterid
			WHERE WOP.ID = @WorkOrderPartNoId

		END
  
 END TRY      
 BEGIN CATCH  
	--SELECT
 --   ERROR_NUMBER() AS ErrorNumber,
 --   ERROR_STATE() AS ErrorState,
 --   ERROR_SEVERITY() AS ErrorSeverity,
 --   ERROR_PROCEDURE() AS ErrorProcedure,
 --   ERROR_LINE() AS ErrorLine,
 --   ERROR_MESSAGE() AS ErrorMessage;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderCustomerDetails'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderPartNoId, '') AS varchar(100))   
        , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        exec spLogException   
                @DatabaseName           = @DatabaseName  
                , @AdhocComments          = @AdhocComments  
                , @ProcedureParameters = @ProcedureParameters  
                , @ApplicationName        =  @ApplicationName  
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
        RETURN(1);  
 END CATCH  
END