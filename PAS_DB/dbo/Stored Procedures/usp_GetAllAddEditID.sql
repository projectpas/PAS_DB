CREATE Procedure [dbo].[usp_GetAllAddEditID]
@poID  bigint,
@ModuleID int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION 

		IF OBJECT_ID(N'tempdb..#POEditList') IS NOT NULL
		BEGIN
		DROP TABLE #POEditList 
		END
		CREATE TABLE #POEditList 
		(
		 ID bigint NOT NULL IDENTITY,
		 [Value] bigint null,
		 Label varchar(100) null
		)

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(UserType,0), 'SHIP_TYPE' FROM dbo.AllAddress WITH(NOLOCK) Where ReffranceId = @poID AND ModuleId = @ModuleID AND IsShippingAdd = 1

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(UserType,0), 'BILL_TYPE' FROM dbo.AllAddress WITH(NOLOCK) Where ReffranceId = @poID AND ModuleId = @ModuleID AND IsShippingAdd = 0

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(UserId,0), 'BILL_USERID' FROM dbo.AllAddress WITH(NOLOCK) Where ReffranceId = @poID AND ModuleId = @ModuleID AND IsShippingAdd = 0

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(UserId,0), 'SHIP_USERID' FROM dbo.AllAddress WITH(NOLOCK) Where ReffranceId = @poID AND ModuleId = @ModuleID AND IsShippingAdd = 1
		
		IF @ModuleID = 31
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			--SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.VendorRFQPurchaseOrder PO WITH(NOLOCK) INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK)
			--ON PO.ManagementStructureId = MS.ManagementStructureId
			--WHERE PO.VendorRFQPurchaseOrderId = @poID;

			SELECT ISNULL(EMS.LegalEntityId,0), 'MSCOMPANYID' from dbo.VendorRFQPurchaseOrder PO WITH(NOLOCK) 			
			 INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD  WITH (NOLOCK) ON MSD.EntityMSID = PO.ManagementStructureId	AND MSD.ModuleID=20
			 INNER JOIN dbo.ManagementStructureLevel EMS WITH (NOLOCK) ON MSD.Level1Id = EMS.ID
			 WHERE PO.VendorRFQPurchaseOrderId = @poID
		END

		IF @ModuleID = 32
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			--SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.VendorRFQRepairOrder RO WITH(NOLOCK) INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK)
			--ON RO.ManagementStructureId = MS.ManagementStructureId
			--WHERE RO.VendorRFQRepairOrderId = @poID; 

			SELECT ISNULL(EMS.LegalEntityId,0), 'MSCOMPANYID' from dbo.VendorRFQRepairOrder RO WITH(NOLOCK) 			
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD  WITH (NOLOCK) ON MSD.EntityMSID = RO.ManagementStructureId AND MSD.ModuleID=22
			 INNER JOIN dbo.ManagementStructureLevel EMS WITH (NOLOCK) ON MSD.Level1Id = EMS.ID
			 WHERE RO.VendorRFQRepairOrderId = @poID
		END


		IF @ModuleID = 14 
		BEGIN
			--INSERT INTO #POEditList ([Value],Label)
			--SELECT ISNULL(RO.VendorId,0), 'VENDORID' from dbo.RepairOrder RO  WITH(NOLOCK)	
			--WHERE RepairOrderId = @poID 
			  INSERT INTO #POEditList ([Value],Label)
			  --SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.RepairOrder RO  WITH(NOLOCK) INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK)			
			  --ON RO.ManagementStructureId = MS.ManagementStructureId			
			  --WHERE RO.RepairOrderId = @poID 

			 SELECT ISNULL(EMS.LegalEntityId,0), 'MSCOMPANYID' from dbo.RepairOrder RO WITH(NOLOCK) 			
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD  WITH (NOLOCK) ON MSD.EntityMSID = RO.ManagementStructureId AND MSD.ModuleID=24
			 INNER JOIN dbo.ManagementStructureLevel EMS WITH (NOLOCK) ON MSD.Level1Id = EMS.ID
			 WHERE RO.RepairOrderId = @poID
		END

		IF @ModuleID = 13 
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			--SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.PurchaseOrder PO WITH(NOLOCK) INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK)
			--ON PO.ManagementStructureId = MS.ManagementStructureId
			--WHERE PO.PurchaseOrderId = @poID 

			SELECT ISNULL(EMS.LegalEntityId,0), 'MSCOMPANYID' from dbo.PurchaseOrder PO WITH(NOLOCK) 			
			 INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD  WITH (NOLOCK) ON MSD.EntityMSID = PO.ManagementStructureId	AND MSD.ModuleID=4
			 INNER JOIN dbo.ManagementStructureLevel EMS WITH (NOLOCK) ON MSD.Level1Id = EMS.ID
			 WHERE PO.PurchaseOrderId = @poID
		END

		IF @ModuleID = 7
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			SELECT ISNULL(SOQ.CustomerId,0), 'CUST_ADDID' from dbo.SalesOrderQuote SOQ WITH(NOLOCK)
			WHERE SalesOrderQuoteId = @poID
		END
		IF @ModuleID = 10
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			SELECT ISNULL(SO.CustomerId,0), 'CUST_ADDID' from dbo.SalesOrder SO WITH(NOLOCK)
			WHERE SalesOrderId = @poID
		END

		IF @ModuleID = 17
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			SELECT ISNULL(EQ.CustomerId,0), 'CUST_ADDID' from dbo.ExchangeQuote EQ WITH(NOLOCK)
			WHERE ExchangeQuoteId = @poID
		END

		IF @ModuleID = 18
		BEGIN
			INSERT INTO #POEditList ([Value],Label)
			SELECT ISNULL(EcxhSO.CustomerId,0), 'CUST_ADDID' from dbo.ExchangeSalesOrder EcxhSO WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @poID
		END

		select * FROM #POEditList
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetAllAddEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@poID, '') + ''',													   
													@Parameter2 = ' + ISNULL(CAST(@ModuleID AS varchar(10)) ,'') +''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			= @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN
	END CATCH	
END