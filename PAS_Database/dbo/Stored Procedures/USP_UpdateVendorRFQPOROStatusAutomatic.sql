/***************************************************************  
 ** File:   [USP_UpdateVendorRFQPOROStatusAutomatic]             
 ** Author:   Shrey Chandegara
 ** Description: Update VendorRFQPORO Status
 ** Date:  15-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    15-04-2025		Shrey Chandegara		Created  	
		
	exec dbo.USP_UpdateVendorRFQPOROStatusAutomatic
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorRFQPOROStatusAutomatic]
AS BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		DECLARE @VendorRFQPOIDs VARCHAR(MAX);
		DECLARE @VendorRFQROIDs VARCHAR(MAX);
		DECLARE @RFQPODays INT;
		DECLARE @RFQRODays INT;
		DECLARE @CanceledStatus BIGINT;
		DECLARE @ClosedStatus BIGINT;
		DECLARE @NoQuoteStatus BIGINT;
		DECLARE @Status VARCHAR(100);
		SET @ClosedStatus = (SELECT VendorRFQStatusId FROM [dbo].[VendorRFQStatus] WITH(NOLOCK) WHERE Description = 'Closed');
		SET @CanceledStatus = (SELECT VendorRFQStatusId FROM [dbo].[VendorRFQStatus] WITH(NOLOCK) WHERE Description = 'Canceled');
		SET @NoQuoteStatus = (SELECT VendorRFQStatusId FROM [dbo].[VendorRFQStatus] WITH(NOLOCK) WHERE Description = 'No Quote');
		SET @Status = (SELECT Description FROM [dbo].[VendorRFQStatus] WITH(NOLOCK) WHERE VendorRFQStatusId = @NoQuoteStatus)

		DECLARE @MasterCompanyId INT;
		DECLARE db_cursorforRFQ CURSOR FOR
		SELECT [MasterCompanyId] FROM [dbo].[MasterCompany] WITH(NOLOCK)
		OPEN db_cursorforRFQ  
		FETCH NEXT FROM db_cursorforRFQ INTO @MasterCompanyId  
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			
			SET @RFQPODays = (SELECT NoQuoteDays FROM [dbo].[PurchaseOrderSettingMaster] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId);
			SET @RFQRODays = (SELECT NoQuoteDays FROM [dbo].[RepairOrderSettingMaster] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId);

			SET @VendorRFQPOIDs = (
			SELECT 
				STRING_AGG(CAST(VendorRFQPurchaseOrderId AS VARCHAR), ',') 
				FROM [dbo].[VendorRFQPurchaseOrder] WITH(NOLOCK) 
			WHERE IsDeleted = 0 AND IsActive = 1 AND  StatusId NOT IN (@ClosedStatus,@CanceledStatus,@NoQuoteStatus) 
				  AND (SELECT DATEDIFF(DAY, UpdatedDate, GETDATE())) > ISNULL(@RFQPODays,0) AND MasterCompanyId = @MasterCompanyId);

			SET @VendorRFQROIDs = (
			SELECT 
				STRING_AGG(CAST(VendorRFQRepairOrderId AS VARCHAR), ',') 
				FROM [dbo].[VendorRFQRepairOrder] WITH(NOLOCK) 
			WHERE IsDeleted = 0 AND IsActive = 1 AND  StatusId NOT IN (@ClosedStatus,@CanceledStatus,@NoQuoteStatus) 
				  AND (SELECT DATEDIFF(DAY, UpdatedDate, GETDATE())) > ISNULL(@RFQPODays,0) AND MasterCompanyId = @MasterCompanyId);

			UPDATE [dbo].[VendorRFQPurchaseOrder]
			SET StatusId = @NoQuoteStatus,Status = @Status
			WHERE VendorRFQPurchaseOrderId IN (SELECT VALUE FROM STRING_SPLIT(@VendorRFQPOIDs, ',')) AND MasterCompanyId = @MasterCompanyId;

			UPDATE [dbo].[VendorRFQRepairOrder]
			SET StatusId = @NoQuoteStatus,Status = @Status
			WHERE VendorRFQRepairOrderId IN (SELECT VALUE FROM STRING_SPLIT(@VendorRFQROIDs, ',')) AND MasterCompanyId = @MasterCompanyId;

		FETCH NEXT FROM db_cursorforRFQ INTO @MasterCompanyId 
		END
		CLOSE db_cursorforRFQ
		DEALLOCATE db_cursorforRFQ
		
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateVendorRFQPOROStatusAutomatic' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END