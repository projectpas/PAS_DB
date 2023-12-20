


--EXEC [PROCGetVendorRFQPoEditID] 2
CREATE PROCEDURE [dbo].[PROCGetVendorRFQPoEditID]
@vrfqId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY	

		IF OBJECT_ID(N'tempdb..#VendorRFQPOEditList') IS NOT NULL
		BEGIN
		DROP TABLE #VendorRFQPOEditList
		END
		CREATE TABLE #VendorRFQPOEditList
		(
		 ID bigint NOT NULL IDENTITY,
		 [Value] bigint null,
		 Label varchar(100) null
		)

		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(VendorId,0), 'VENDOR' FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId = @vrfqId;

		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(RequestedBy,0), 'EMPLOYEE' FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId = @vrfqId;
		
		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.VendorRFQPurchaseOrder WITH(NOLOCK) WHERE VendorRFQPurchaseOrderId = @vrfqId;
		
		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) Where VendorRFQPurchaseOrderId = @vrfqId; 

		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(ConditionId,0), 'CONDITION' FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) Where VendorRFQPurchaseOrderId = @vrfqId;			

		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(WorkOrderId,0), 'WONO' FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) Where VendorRFQPurchaseOrderId = @vrfqId AND WorkOrderId > 0

		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(SubWorkOrderId,0), 'SOWONO' FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) Where VendorRFQPurchaseOrderId = @vrfqId AND SubWorkOrderId > 0
				
		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(SalesOrderId,0), 'SONO' FROM dbo.VendorRFQPurchaseOrderPart WITH(NOLOCK) Where VendorRFQPurchaseOrderId = @vrfqId AND SalesOrderId > 0
		
		INSERT INTO #VendorRFQPOEditList ([Value],Label)
		SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.VendorRFQPurchaseOrder PO WITH(NOLOCK)
		INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON PO.ManagementStructureId = MS.ManagementStructureId
		WHERE VendorRFQPurchaseOrderId = @vrfqId; 
		
		SELECT * FROM #VendorRFQPOEditList

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'PROCGetVendorRFQPoEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@vrfqId, '') + ''
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