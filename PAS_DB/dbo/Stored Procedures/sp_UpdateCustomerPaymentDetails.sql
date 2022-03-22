CREATE Procedure [dbo].[sp_UpdateCustomerPaymentDetails]
	@ReceiptId bigint,
	@ManagementStructureId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	
	BEGIN TRY
	BEGIN TRANSACTION
	
		DECLARE @MSID as bigint
		DECLARE @Level1 as varchar(200)
		DECLARE @Level2 as varchar(200)
		DECLARE @Level3 as varchar(200)
		DECLARE @Level4 as varchar(200)

		IF OBJECT_ID(N'tempdb..#CustomerPaymentMSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #CustomerPaymentMSDATA
		END
		CREATE TABLE #CustomerPaymentMSDATA
		(
		 MSID bigint,
		 Level1 varchar(200) NULL,
		 Level2 varchar(200) NULL,
		 Level3 varchar(200) NULL,
		 Level4 varchar(200) NULL 
		)

		IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #MSDATA 
		END
		CREATE TABLE #MSDATA
		(
			ID int IDENTITY, 
			MSID bigint 
		)
		INSERT INTO #MSDATA (MSID)
		  SELECT @ManagementStructureId

		DECLARE @LoopID as int 
		SELECT  @LoopID = MAX(ID) FROM #MSDATA
		WHILE(@LoopID > 0)
		BEGIN
		SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

		EXEC dbo.GetMSNameandCode @MSID,
		 @Level1 = @Level1 OUTPUT,
		 @Level2 = @Level2 OUTPUT,
		 @Level3 = @Level3 OUTPUT,
		 @Level4 = @Level4 OUTPUT

		INSERT INTO #CustomerPaymentMSDATA
					(MSID, Level1,Level2,Level3,Level4)
			  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
		SET @LoopID = @LoopID - 1;
		END 
 
		UPDATE CP SET
		CP.LEVEL1 = PMS.Level1,
		CP.LEVEL2 = PMS.Level2,
		CP.LEVEL3 = PMS.Level3,
		CP.LEVEL4 = PMS.Level4
		FROM dbo.CustomerPayments CP WITH (NOLOCK)
		LEFT JOIN #CustomerPaymentMSDATA PMS ON PMS.MSID = @ManagementStructureId
		WHERE CP.ReceiptId = @ReceiptId

		SELECT
		ReceiptNo as value
		FROM dbo.CustomerPayments CP WITH (NOLOCK) WHERE ReceiptId = @ReceiptId

	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'sp_UpdateCustomerPaymentDetails' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReceiptId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@ManagementStructureId, '') as Varchar(100)) 	
	  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  exec spLogException 
			   @DatabaseName           = @DatabaseName
			 , @AdhocComments          = @AdhocComments
			 , @ProcedureParameters    = @ProcedureParameters
			 , @ApplicationName        =  @ApplicationName
			 , @ErrorLogID             = @ErrorLogID OUTPUT ;
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
	  RETURN(1);
	END CATCH
END