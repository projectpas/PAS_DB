/*************************************************************           
 ** File:   [SP_SaveSOPorformaInvoicingIsBill]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to update isbilling flag after standard proforma invoice flag to isbiiling.
 ** Purpose:         
 ** Date:  15/02/2024   
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    15/02/2024   AMIT GHEDIYA		 Created
     
************************************************************************/

CREATE     PROCEDURE [dbo].[SP_SaveSOPorformaInvoicingIsBill]
@sobillingInvoicingId bigint NULL= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN 
		IF(@sobillingInvoicingId > 0)
		BEGIN

			DECLARE @sobillngId BIGINT,
					@isProforma BIT,
					@soPartID BIGINT,
					@SalesOrderPartId BIGINT,
					@SOBillingInvoicingIds BIGINT,
					@COUNT AS INT = 0,
					@SalesOrderId BIGINT = 0,
					@DepositAmt DECIMAL(18,2) = 0,
					@TotalSalesOrderCostPlus DECIMAL(18,2) = 0,
					@UsedDepositAmt DECIMAL(18,2) = 0,
					@SOProFormaBillingInvoicingId BIGINT = 0,
					@SOisProforma BIT;

		------------- Update Remaining Deposit -------------------------------------
			
			SELECT @SalesOrderId = [SalesOrderId], @TotalSalesOrderCostPlus = [GrandTotal], @SOisProforma = [IsProforma]
			FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;

			IF(@SOisProforma != 1)
			BEGIN
				--Get deposit from invoiced.
				SELECT @DepositAmt = SUM(ISNULL([DepositAmount], 0)) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
				WHERE [SalesOrderId] = @SalesOrderId AND IsVersionIncrease = 0 AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

				--Update Remaining balace
				IF(@DepositAmt > 0)
				BEGIN
					UPDATE [dbo].[SalesOrderBillingInvoicing] SET RemainingAmount = ISNULL(RemainingAmount ,0) - @DepositAmt  WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
				END

				SET @UsedDepositAmt = CASE WHEN ISNULL(@TotalSalesOrderCostPlus ,0) > ISNULL(@DepositAmt,0) THEN ISNULL(@DepositAmt,0) ELSE ISNULL(@TotalSalesOrderCostPlus ,0) END

				SELECT TOP 1 @SOProFormaBillingInvoicingId = SOBillingInvoicingId FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
				WHERE [SalesOrderId] = @SalesOrderId AND IsVersionIncrease = 0 AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

				IF(ISNULL(@SOProFormaBillingInvoicingId, 0) > 0)
				BEGIN
					UPDATE [dbo].[SalesOrderBillingInvoicing]
					SET [UsedDeposit] = ISNULL(UsedDeposit, 0) + @UsedDepositAmt
					WHERE [SOBillingInvoicingId] = @SOProFormaBillingInvoicingId
				END
			END

		-------------End Update Remaining Deposit -------------------------------------


			--Create Temp Table 
			IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoiceList') IS NOT NULL
			BEGIN
				DROP TABLE #SalesOrderBillingInvoiceList
			END

			CREATE TABLE #SalesOrderBillingInvoiceList(
				ID BIGINT NOT NULL IDENTITY (1, 1),
				SalesOrderPartId [BIGINT]  NULL,
				SOBillingInvoicingId [BIGINT]  NULL
			);

			SELECT @sobillngId = SOBillingInvoicingId , @soPartID = SalesOrderPartId , @isProforma = IsProforma FROM DBO.SalesOrderBillingInvoicingItem WITH(NOLOCK) WHERE SOBillingInvoicingId = @sobillingInvoicingId;
			IF(ISNULL(@sobillngId,0) > 0 AND @isProforma = 0)
			BEGIN
				IF(ISNULL(@soPartID,0) > 0)
				BEGIN
					INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderPartId,SOBillingInvoicingId)
					(SELECT SalesOrderPartId,SOBillingInvoicingId 
					FROM SalesOrderBillingInvoicingItem WHERE SalesOrderPartId = @soPartID AND IsProforma = 1)

					SELECT @COUNT = MAX(ID) FROM #SalesOrderBillingInvoiceList 

					WHILE(@COUNT > 0)
					BEGIN
						SELECT @SalesOrderPartId = SalesOrderPartId, @SOBillingInvoicingIds = SOBillingInvoicingId, @SalesOrderPartId = SalesOrderPartId 
						FROM #SalesOrderBillingInvoiceList WITH(NOLOCK) WHERE ID = @COUNT;

						--Update isbiiling after standdard invoiced post
						UPDATE DBO.SalesOrderBillingInvoicingItem SET IsBilling = 1 WHERE SalesOrderPartId = @SalesOrderPartId AND IsProforma = 1;
						UPDATE DBO.SalesOrderBillingInvoicing SET IsBilling = 1 WHERE SOBillingInvoicingId = @SOBillingInvoicingIds AND IsProforma = 1;

						SET @COUNT = @COUNT - 1
					END
					
				END
			END
		END
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SP_SaveSOPorformaInvoicingIsBill' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@sobillingInvoicingId, '') AS varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END