
CREATE Procedure [dbo].[usp_getAllRecevingROEditID]
@roID  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		IF OBJECT_ID(N'tempdb..#ROEditList') IS NOT NULL
		BEGIN
		DROP TABLE #ROEditList 
		END
		CREATE TABLE #ROEditList 
		(
		 ID bigint NOT NULL IDENTITY,
		 [Value] bigint null,
		 Label varchar(100) null
		)

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(ShippingViaId,0), 'SHIPPINGVIA' FROM dbo.StocklineDraft WITH(NOLOCK) Where RepairOrderId = @roID  

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SiteId,0), 'SITEID' FROM dbo.StocklineDraft WITH(NOLOCK) Where RepairOrderId = @roID  

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(ROP.ManufacturerId,0), 'MANUFACTURER' FROM dbo.RepairOrderPart ROP  WITH(NOLOCK)
		INNER JOIN dbo.StocklineDraft SLD WITH(NOLOCK) ON ROP.RepairOrderPartRecordId = SLD.RepairOrderPartRecordId   Where ROP.RepairOrderId = @roID  

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.ManufacturerId,0), 'MANUFACTURER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(ROP.ConditionId,0), 'CONDITIONID' FROM dbo.RepairOrderPart ROP  WITH(NOLOCK)
		INNER JOIN dbo.StocklineDraft SLD WITH(NOLOCK) ON ROP.RepairOrderPartRecordId = SLD.RepairOrderPartRecordId   Where ROP.RepairOrderId = @roID  

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.ConditionId,0), 'CONDITIONID' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.ObtainFrom,0), 'CUSTOMER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID  AND SLD.ObtainFromType = 1 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.ObtainFrom,0), 'VENDOR' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID  AND SLD.ObtainFromType = 2 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.ObtainFrom,0), 'COMPANY' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID    AND SLD.ObtainFromType = 9

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.OwnerType,0), 'CUSTOMER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID  AND SLD.OwnerType = 1 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.OwnerType,0), 'VENDOR' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID  AND SLD.OwnerType = 2 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.OwnerType,0), 'COMPANY' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID    AND SLD.OwnerType = 9

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.TraceableToType,0), 'CUSTOMER' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID  AND SLD.OwnerType = 1 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.TraceableToType,0), 'VENDOR' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID  AND SLD.OwnerType = 2 

		INSERT INTO #ROEditList ([Value],Label)
		SELECT ISNULL(SLD.TraceableToType,0), 'COMPANY' FROM  dbo.StocklineDraft SLD WITH(NOLOCK)  Where SLD.RepairOrderId = @roID    AND SLD.OwnerType = 9


		SELECT * FROM #ROEditList
	
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_getAllRecevingROEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@roID, '') + ''
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