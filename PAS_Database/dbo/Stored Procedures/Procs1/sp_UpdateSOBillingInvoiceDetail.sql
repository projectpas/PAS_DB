/*************************************************************           
 ** File:   [sp_UpdateSOBillingInvoiceDetail]
 ** Author: unknown
 ** Description: 
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	02/1/2024		AMIT GHEDIYA	added isperforma Flage for SO

************************************************************************/
CREATE Procedure [dbo].[sp_UpdateSOBillingInvoiceDetail]
	@SOBillingInvoicingId  bigint,
	@ManagementStructureId  bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN

		DECLARE @MSID as bigint
		DECLARE @Level1 as varchar(200)
		DECLARE @Level2 as varchar(200)
		DECLARE @Level3 as varchar(200)
		DECLARE @Level4 as varchar(200)

		IF OBJECT_ID(N'tempdb..#SOBillingInvoicingMSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #SOBillingInvoicingMSDATA
		END
		CREATE TABLE #SOBillingInvoicingMSDATA
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

		INSERT INTO #SOBillingInvoicingMSDATA
					(MSID, Level1,Level2,Level3,Level4)
			  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
		SET @LoopID = @LoopID - 1;
		END 
 
		UPDATE SB SET
		SB.Level1 = PMS.Level1,
		SB.Level2 = PMS.Level2,
		SB.Level3 = PMS.Level3,
		SB.Level4 = PMS.Level4
		FROM dbo.SalesOrderBillingInvoicing SB WITH (NOLOCK)
		LEFT JOIN #SOBillingInvoicingMSDATA PMS ON PMS.MSID = @ManagementStructureId
		WHERE SB.SOBillingInvoicingId = @SOBillingInvoicingId AND ISNULL(SB.IsProforma,0) = 0

		SELECT
		InvoiceNo as value
		FROM dbo.SalesOrderBillingInvoicing SB WITH (NOLOCK) WHERE SOBillingInvoicingId = @SOBillingInvoicingId AND ISNULL(SB.IsProforma,0) = 0
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_UpdateSOBillingInvoiceDetail' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SOBillingInvoicingId, '') + ''
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