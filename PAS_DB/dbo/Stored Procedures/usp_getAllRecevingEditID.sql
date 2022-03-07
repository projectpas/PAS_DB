


  
CREATE Procedure [dbo].[usp_getAllRecevingEditID]  
	@poID  bigint  
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

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
		SELECT ISNULL(VendorId,0), 'VENDOR' FROM dbo.PurchaseOrder WITH(NOLOCK) Where PurchaseOrderID = @poID    

		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(ShippingViaId,0), 'SHIPPINGVIA' FROM dbo.StocklineDraft WITH(NOLOCK) Where PurchaseOrderId = @poID    
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SiteId,0), 'SITEID' FROM dbo.StocklineDraft WITH(NOLOCK) Where PurchaseOrderId = @poID    
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(POP.ConditionId,0), 'CONDITIONID' FROM dbo.PurchaseOrderPart POP  WITH(NOLOCK)  
		INNER JOIN dbo.StocklineDraft SLD WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = SLD.PurchaseOrderPartRecordId   Where POP.PurchaseOrderId = @poID  
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(POP.ManufacturerId,0), 'MANUFACTURER' FROM dbo.PurchaseOrderPart POP  WITH(NOLOCK)  
		INNER JOIN dbo.StocklineDraft SLD WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = SLD.PurchaseOrderPartRecordId   Where POP.PurchaseOrderId = @poID 
		
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.AssetAcquisitionTypeId,0), 'ACQUISITIONTYPE' FROM dbo.PurchaseOrderPart POP  WITH(NOLOCK)  
		INNER JOIN dbo.AssetInventoryDraft SLD WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = SLD.PurchaseOrderPartRecordId Where POP.PurchaseOrderId = @poID
				  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.ManufacturerId,0), 'MANUFACTURER' FROM dbo.StocklineDraft SLD WITH(NOLOCK) Where SLD.PurchaseOrderId = @poID   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.ConditionId,0), 'CONDITIONID' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID    
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.ObtainFrom,0), 'CUSTOMER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID  AND SLD.ObtainFromType = 1   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.ObtainFrom,0), 'VENDOR' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID  AND SLD.ObtainFromType = 2   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.ObtainFrom,0), 'COMPANY' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID    AND SLD.ObtainFromType = 9  
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.OwnerType,0), 'CUSTOMER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID  AND SLD.OwnerType = 1   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.OwnerType,0), 'VENDOR' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID  AND SLD.OwnerType = 2   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.OwnerType,0), 'COMPANY' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID    AND SLD.OwnerType = 9  
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.TraceableToType,0), 'CUSTOMER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID  AND SLD.OwnerType = 1   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.TraceableToType,0), 'VENDOR' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID  AND SLD.OwnerType = 2   
  
		INSERT INTO #POEditList ([Value],Label)  
		SELECT ISNULL(SLD.TraceableToType,0), 'COMPANY' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.PurchaseOrderId = @poID    AND SLD.OwnerType = 9  
  
         

  

		SELECT * FROM #POEditList  

    COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_getAllRecevingEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@poID, '') + ''
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