--exec GeSOWOtInvoiceDate '66,61,60'
CREATE PROCEDURE [dbo].[GeSOWOtInvoiceDate]
@CustomerIDS nvarchar(100) = null
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY
		DECLARE @SOSTDT datetime2(7)=null;
		DECLARE @WOSTDT datetime2(7)=null;
		DECLARE @StartDate datetime2(7)=null;
		SELECT @SOSTDT = MIN(sb.InvoiceDate) FROM SalesOrderBillingInvoicing sb WITH(NOLOCK)WHERE sb.RemainingAmount > 0 AND sb.InvoiceStatus = 'Invoiced' AND sb.CustomerId IN((SELECT Item FROM DBO.SPLITSTRING(@CustomerIDS,',')));		
		SELECT @WOSTDT = MIN(wb.InvoiceDate) FROM WorkOrderBillingInvoicing wb WITH(NOLOCK) WHERE wb.RemainingAmount > 0 AND wb.InvoiceStatus = 'Invoiced' AND wb.CustomerId IN((SELECT Item FROM DBO.SPLITSTRING(@CustomerIDS,',')));		
		IF(@SOSTDT is null or @SOSTDT = '')
		BEGIN
			SET @StartDate = @WOSTDT; 
		END
		ELSE
		BEGIN
			IF(@WOSTDT is null or @WOSTDT = '')
			BEGIN					
				SET @StartDate = @SOSTDT;
			END
			ELSE
			BEGIN
				IF(@SOSTDT < @WOSTDT)
				BEGIN
					SET @StartDate = @SOSTDT;
				END
				ELSE
				BEGIN
					SET @StartDate = @WOSTDT; 
				END
			END
		END
		select CAST(@StartDate AS date) as InvoiceDate
			--COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			--PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;
            -- temp table drop
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GeSOWOtInvoiceDate'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerIDS, '') AS varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END