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
   
  
*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderCustomerDetails] 	
@WorkOrderId BIGINT = NULL,  
@WorkOrderPartNoId BIGINT = NULL,
@CustomerId BIGINT = NULL,  
@ItemMasterId BIGINT = NULL, 
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
		DECLARE @CustomerCode VARCHAR(30) = NULL;
		DECLARE @CustomerType VARCHAR(30) = NULL;
		DECLARE @IsFinishedGood BIT = NULL;
		DECLARE @IsClosed BIT = NULL;
		DECLARE @WorkOrderSettlementId BIGINT = 9; --Fixed for Final Condition Changed
		DECLARE @ModuleId BIGINT, @RefferenceId BIGINT, @SubModuleId BIGINT, @SubRefferenceId BIGINT, @OldValue VARCHAR(MAX) = NULL, 
				@NewValue VARCHAR(MAX), @HistoryText VARCHAR(MAX), @StatusCode VARCHAR(100), @MasterCompanyId INT;

		SET @ModuleId = 15; --Fixed for Work Order
		SET @SubModuleId = 43; --Fixed for Work Order MPM
		
		

		SELECT @WorkOrderId = WorkOrderId, @IsFinishedGood = IsFinishGood, @IsClosed = IsClosed FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId

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

		IF(ISNULL(@CustomerId, 0) > 0)
		BEGIN
			SET @StatusCode = 'CUSTOMERCHANGE';

			UPDATE dbo.WorkOrder SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId
			UPDATE dbo.WorkOrderQuote SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId
			UPDATE dbo.WorkOrder SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId
			UPDATE dbo.Stockline SET ExistingCustomerId = SL.CustomerId 
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WO.WorkOrderId = @WorkOrderId

			UPDATE dbo.Stockline SET CustomerId =  @CustomerId , Memo = SL.Memo + 'Updated Customer from WO : ' + WO.WorkOrderNum
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

			UPDATE ReceivingCustomerWork
				SET CustomerId = @CustomerId, CustomerContactId = CC.CustomerContactId ,
					CustomerName = C.[Name], CustomerCode = C.CustomerCode
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = RC.WorkOrderId
				JOIN dbo.Customer C WITH(NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
			WHERE RC.WorkOrderId = @WorkOrderId

			EXEC USP_History @ModuleId = @ModuleId,@RefferenceId = @RefferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubRefferenceId, @OldValue = @OldValue, @NewValue = @NewValue, @HistoryText = @HistoryText, @StatusCode = @StatusCode, @MasterCompanyId = @MasterCompanyId, @CreatedBy = @UpdatedBy, @CreatedDate = GETUTCDATE, @UpdatedBy = @UpdatedBy, @UpdatedDate = GETUTCDATE

		END

		IF(ISNULL(@ItemMasterId, 0) > 0)
		BEGIN
			SET @StatusCode = 'PARTNUMBERCHANGE';

			UPDATE WorkOrderPartNumber SET ItemMasterId = @ItemMasterId, RevisedItemmasterid = @ItemMasterId, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE WorkOrderPartNumber SET RevisedPartNumber = IM.PartNumber, RevisedPartDescription = IM.PartDescription, IsPMA = IM.IsPma, IsDER = IM.IsDER
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				LEFT JOIN ItemMaster IM ON IM.ItemMasterId = WOP.RevisedItemmasterid
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE WorkOrderSettlementDetails SET RevisedPartId = @ItemMasterId, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),
				IsMastervalue = 1, Isvalue_NA = 0
			FROM dbo.WorkOrderSettlementDetails WSD WITH(NOLOCK)
			WHERE WSD.WorkOrderId = @WorkOrderId AND WSD.workOrderPartNoId =  @WorkOrderPartNoId AND WSD.WorkOrderSettlementId = @WorkOrderSettlementId
			
			UPDATE dbo.Stockline SET ItemMasterId =  @ItemMasterId , Memo = SL.Memo + 'Updated Part Number from WO : ' + WO.WorkOrderNum
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE dbo.Stockline SET PartNumber = IM.partnumber, PNDescription = IM.PartDescription ,ManufacturerId = IM.ManufacturerId, Manufacturer = IM.ManufacturerName, IsHazardousMaterial = IM.IsHazardousMaterial,
					IsPMA = IM.IsPma, IsDER = IM.IsDER, isSerialized = IM.isSerialized, PurchaseUnitOfMeasureId = IM.PurchaseUnitOfMeasureId, UnitOfMeasure = IM.PurchaseUnitOfMeasure,
					RevicedPNId = IM.RevisedPartId, RevicedPNNumber = IM.RevisedPart
			FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
				JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
				JOIN ItemMaster IM ON IM.ItemMasterId = WOP.ItemMasterId
			WHERE WOP.ID = @WorkOrderPartNoId

			UPDATE ReceivingCustomerWork
				SET ItemMasterId = @ItemMasterId, IsSerialized = im.isSerialized, ManufacturerName = IM.ManufacturerName, PartNumber = IM.partnumber
			FROM dbo.ReceivingCustomerWork RC WITH(NOLOCK) 
				JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.StockLineId = RC.StockLineId
				JOIN ItemMaster IM ON IM.ItemMasterId = WOP.ItemMasterId
			WHERE WOP.ID = @WorkOrderPartNoId

			EXEC USP_History @ModuleId = @ModuleId,@RefferenceId = @RefferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubRefferenceId, @OldValue = @OldValue, @NewValue = @NewValue, @HistoryText = @HistoryText, @StatusCode = @StatusCode, @MasterCompanyId = @MasterCompanyId, @CreatedBy = @UpdatedBy, @CreatedDate = GETUTCDATE, @UpdatedBy = @UpdatedBy, @UpdatedDate = GETUTCDATE

		END


  
 END TRY      
 BEGIN CATCH  
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