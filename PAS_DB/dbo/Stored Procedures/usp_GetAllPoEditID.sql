
--exec [usp_GetAllPoEditID] 1206
CREATE Procedure [dbo].[usp_GetAllPoEditID]
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
		SELECT ISNULL(POPartSplitUserId,0), 'VENDOR' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND POPartSplitUserTypeId = 2

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(POPartSplitUserId,0), 'COMPANY' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND POPartSplitUserTypeId = 9

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(POPartSplitUserId,0), 'CUSTOMER' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND POPartSplitUserTypeId = 1

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(RequestedBy,0), 'EMPLOYEE' FROM dbo.PurchaseOrder WITH(NOLOCK) Where PurchaseOrderID = @poID

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(ApproverId,0), 'EMPLOYEE' FROM dbo.PurchaseOrder WITH(NOLOCK) Where PurchaseOrderID = @poID

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.PurchaseOrder WITH(NOLOCK) Where PurchaseOrderID = @poID

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(PriorityId,0), 'PRIORITY' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID 

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(ConditionId,0), 'CONDITION' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID 

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(FunctionalCurrencyId,0), 'CURRENCY' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID 

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(ReportCurrencyId,0), 'CURRENCY' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID 

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(WorkOrderId,0), 'WONO' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND WorkOrderId > 0

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(SubWorkOrderId,0), 'SOWONO' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND SubWorkOrderId > 0

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(RepairOrderId,0), 'RONO' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND RepairOrderId > 0

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(SalesOrderId,0), 'SONO' FROM dbo.PurchaseOrderPart WITH(NOLOCK) Where PurchaseOrderID = @poID AND SalesOrderId > 0

		INSERT INTO #POEditList ([Value],Label)
		SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.PurchaseOrder PO WITH(NOLOCK)
		INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON PO.ManagementStructureId = MS.ManagementStructureId
		WHERE PurchaseOrderId = @poID 

		SELECT * FROM #POEditList

	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetAllPoEditID' 
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