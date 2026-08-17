/*************************************************************             
 ** File:   [USP_CreateReceivingReconciliationPostReadyToPays]             
 ** Author:   
 ** Description: This stored procedure is used to Add  Vendor Payment Details
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		------------------------------- 
    1    unknown                    Created 
	2    09/10/2023   Moin Bloch    Formetted SP 
	3    10/04/2025   Amit Ghediya  Added new field (LastMSLevel,LegalEntityId)
	4    16/02/2026   Amit Ghediya  update to get due date from ReceivingReconciliation duedate (PN-15444)
	5    26/02/2026   HEMANT SALIYA UPDATE TO SET IS Active and IS Delete default values
	6    07/08/2026   Moin Bloch     Fix For Receiving Reconciliation Entry

EXEC [dbo].[USP_CreateReceivingReconciliationPostReadyToPay] 10023,0
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateReceivingReconciliationPostReadyToPay]
@ReceivingReconciliationId bigint,
@BatchId BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

			DECLARE @LastMSLevel VARCHAR(256),
					@LegalEntityId BIGINT,
					@MSModuleID INT = 4,
					@ROMSModuleID INT = 24,
					@IsPOType INT=0;

			SET @IsPOType = (SELECT TOP 1 [Type] FROM [dbo].[ReceivingReconciliationDetails] WITH(NOLOCK) WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId  AND ISNULL([IsManual],0) = 0);

			IF(@IsPOType = 1)
			BEGIN
				SELECT TOP 1 @LastMSLevel = MSD.[Level1Name], @LegalEntityId = MSL.[LegalEntityId]
									FROM [dbo].[ReceivingReconciliationDetails] RRCD WITH(NOLOCK)
										INNER JOIN [dbo].[PurchaseOrder] PUO  WITH (NOLOCK) ON RRCD.[PurchaseOrderId] = PUO.[PurchaseOrderId]
										INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @MSModuleID AND MSD.[ReferenceID] = PUO.[PurchaseOrderId]
										LEFT JOIN  [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON MSL.[Id] = MSd.[Level1Id]
										WHERE RRCD.[ReceivingReconciliationId] = @ReceivingReconciliationId
			END

			IF(@IsPOType = 2)
			BEGIN
				SELECT TOP 1 @LastMSLevel = MSD.[Level1Name], @LegalEntityId = MSL.[LegalEntityId]
									FROM [dbo].[ReceivingReconciliationDetails] RRCD WITH (NOLOCK)
										INNER JOIN [dbo].[RepairOrder] PUO WITH (NOLOCK) ON RRCD.[PurchaseOrderId] = PUO.[RepairOrderId]
										INNER JOIN [dbo].[RepairOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @ROMSModuleID AND MSD.ReferenceID = PUO.[RepairOrderId]
										LEFT JOIN  [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON MSL.[Id] = MSd.[Level1Id]
										WHERE RRCD.[ReceivingReconciliationId] = @ReceivingReconciliationId
			END

			INSERT INTO [dbo].[VendorPaymentDetails]
				       ([ReadyToPayId],
					    [DueDate],
						[VendorId],
						[VendorName],
						[PaymentMethodId],
						[PaymentMethodName],
						[ReceivingReconciliationId],
						[InvoiceNum],
						[CurrencyId],
						[CurrencyName],
						[FXRate],
				        [OriginalAmount],
						[PaymentMade],
						[AmountDue],
						[DaysPastDue],
						[DiscountDate],
						[DiscountAvailable],
						[DiscountToken],
						[OriginalTotal],
						[RRTotal],
						[InvoiceTotal],
						[DIfferenceAmount],
						[TotalAdjustAmount],
						[StatusId],
						[Status],
						[MasterCompanyId],
						[CreatedBy],
						[UpdatedBy],
						[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RemainingAmount],[LastMSLevel],[LegalEntityId])
			     SELECT 0,
				        [DueDate],
				        [VendorId],
						[VendorName],
						0,
						NULL,
						@ReceivingReconciliationId,
						[InvoiceNum],
						[CurrencyId],
						[CurrencyName],
						0,
						[InvoiceTotal],
						0,
						0,
						0,
						NULL,
						0,
						0,
						[OriginalTotal],
						[RRTotal],
						[InvoiceTotal],
						[DIfferenceAmount],
						[TotalAdjustAmount],
			            [StatusId],
						[Status],
						[MasterCompanyId],
						[CreatedBy],
						[UpdatedBy],
						GETUTCDATE(),
						GETUTCDATE(),
						1,
						0,
						[InvoiceTotal],
						@LastMSLevel,
						@LegalEntityId
				   FROM [dbo].[ReceivingReconciliationHeader] WITH(NOLOCK) 
				  WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId;
			
			SET @BatchId = @ReceivingReconciliationId;			
    END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateReceivingReconciliationPostReadyToPay' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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
	END CATCH
END